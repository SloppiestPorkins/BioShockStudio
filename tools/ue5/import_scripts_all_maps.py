"""Batch Script import across shipped maps — Phase 2.3 tail / FULL_GAME_CONVERSION B1.

For each map: load its ue5-level.json + export-script-actions sidecar, open a scratch
level (never Medical), run import_scripts, and record nested_unmapped / unmapped_classes.

Does **not** invent stubs for unmapped classes — gaps are reported by name and count.

Configure via environment (headless -run=pythonscript has no reliable argv):
  BIOSHOCK_SCRIPT_IMPORT_MAPS     comma-separated subset; default = all except 1-Medical
  BIOSHOCK_SCRIPT_IMPORT_INCLUDE_MEDICAL=1   also run Medical (default: skip; prior-verified)
  BIOSHOCK_SCRIPT_IMPORT_OUT      aggregate report JSON
  BIOSHOCK_SCRIPT_IMPORT_ROOT     prep dir (default %TEMP%/bioshock-script-import-all-maps)
  BIOSHOCK_SCRIPT_IMPORT_STOP_ON_ERROR=0     continue after a map failure (default: stop)
  BIOSHOCK_SCHEMA_DIR             schema JSON directory
"""

from __future__ import annotations

import json
import os
import time

import unreal

import import_scripts

CONTENT_ROOT = "/Game/BioShockScriptImport"
SCRATCH_MAP = "/Game/BioShockScriptImport/_Scratch"

# 21 non-localised shipped map packages (same list as import_all_levels.py).
SHIPPED_MAPS = [
    "0-Lighthouse",
    "1-Medical",
    "1-Welcome",
    "2-Fisheries",
    "2-SubBay",
    "3-Arcadia",
    "3-Market",
    "4-Recreation",
    "5-Hephaestus",
    "5-Ryan",
    "6-Resi",
    "6-Slums",
    "7-BossFight",
    "7-Gauntlet",
    "7-Science",
    "Autoplay",
    "Entry",
    "museum",
    "ChallengeRoomCombat",
    "ChallengeRoomDecoy",
    "ChallengeRoomElectric",
]

# Documented Medical baseline (27 Aug 2026 live import) — not re-run by default.
MEDICAL_BASELINE = {
    "map": "1-Medical",
    "skipped_reimport": True,
    "source": "prior_verification_27_Aug_2026",
    "scripts_imported": 300,
    "actions_mapped": 1463,
    "actions_unmapped": 0,
    "nested_unmapped": 0,
    "unmapped_classes": {},
    "nested_unmapped_classes": {},
    "nested_true": 331,
    "nested_else": 37,
    "nested_loop": 10,
    "nested_for": 3,
    "nested_tests": 114,
}


def _log(message):
    unreal.log("[bioshock-script-import-all] %s" % message)


def _temp_root():
    return os.environ.get(
        "BIOSHOCK_SCRIPT_IMPORT_ROOT",
        os.path.join(os.environ.get("TEMP", "."), "bioshock-script-import-all-maps"),
    )


def _default_out():
    return os.environ.get(
        "BIOSHOCK_SCRIPT_IMPORT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "bioshock_import_scripts_all_maps.json"),
    )


def _maps_to_run():
    raw = os.environ.get("BIOSHOCK_SCRIPT_IMPORT_MAPS", "").strip()
    if raw:
        return [m.strip() for m in raw.split(",") if m.strip()]
    maps = list(SHIPPED_MAPS)
    if os.environ.get("BIOSHOCK_SCRIPT_IMPORT_INCLUDE_MEDICAL") != "1":
        maps = [m for m in maps if m != "1-Medical"]
    return maps


def _stop_on_error():
    return os.environ.get("BIOSHOCK_SCRIPT_IMPORT_STOP_ON_ERROR", "1") != "0"


def _sidecar_path(map_name):
    return os.path.join(_temp_root(), "%s.script-actions.json" % map_name)


def _manifest_path(map_name):
    root = _temp_root()
    candidates = [
        os.path.join(root, map_name, "%s.ue5-level.json" % map_name),
        os.path.join(root, map_name, map_name, "%s.ue5-level.json" % map_name),
    ]
    # Reuse a21 / a14 prep trees when present under %TEMP%.
    temp = os.environ.get("TEMP", "")
    for prior in ("a21-importer-reverify", "a14-import-verify"):
        candidates.append(
            os.path.join(temp, prior, map_name, map_name, "%s.ue5-level.json" % map_name)
        )
    if map_name == "1-Medical":
        candidates.append(
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json"
        )
    for path in candidates:
        if path and os.path.isfile(path):
            return path
    return candidates[0]


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _ensure_content_folder(path):
    if unreal.EditorAssetLibrary.does_directory_exist(path):
        return
    if not unreal.EditorAssetLibrary.make_directory(path):
        raise RuntimeError("could not create content folder %s" % path)


def _open_scratch():
    """Import into an ephemeral scratch level — never open Medical / saved slice maps."""
    _ensure_content_folder(CONTENT_ROOT)
    level = _level_subsystem()
    if unreal.EditorAssetLibrary.does_asset_exist(SCRATCH_MAP):
        if not level.load_level(SCRATCH_MAP):
            raise RuntimeError("scratch level %s did not load" % SCRATCH_MAP)
        return
    if not level.new_level(SCRATCH_MAP):
        raise RuntimeError("could not create scratch level %s" % SCRATCH_MAP)


def _summarize(map_name, imported):
    return {
        "map": map_name,
        "manifest": imported.get("manifest"),
        "props_path": imported.get("props_path"),
        "props_loaded": imported.get("props_loaded"),
        "scripts_imported": imported.get("created"),
        "scripts_in_manifest": imported.get("scripts_in_manifest"),
        "actions_mapped": imported.get("actions_mapped"),
        "actions_unmapped": imported.get("actions_unmapped"),
        "unmapped_classes": imported.get("unmapped_classes") or {},
        "nested_unmapped": imported.get("nested_unmapped"),
        "nested_unmapped_classes": imported.get("nested_unmapped_classes") or {},
        "nested_true": imported.get("nested_true"),
        "nested_else": imported.get("nested_else"),
        "nested_loop": imported.get("nested_loop"),
        "nested_for": imported.get("nested_for"),
        "nested_tests": imported.get("nested_tests"),
        "nested_test_cast_fail": imported.get("nested_test_cast_fail"),
        "schema_applied": imported.get("schema_applied"),
        "instance_applied": imported.get("instance_applied"),
        "registry_num": imported.get("registry_num"),
    }


def _gap_classes_closed(summary):
    """Confirm the Phase 2.3 tail-1 four classes are absent from both unmapped buckets."""
    targets = (
        "OrStatement",
        "HideNeedleElement",
        "ShowNeedleElement",
        "TrainingCondition",
    )
    hits = {}
    nested = summary.get("nested_unmapped_classes") or {}
    top = summary.get("unmapped_classes") or {}
    for name in targets:
        count = int(nested.get(name, 0)) + int(top.get(name, 0))
        if count:
            hits[name] = count
    return hits


def import_one_map(map_name):
    manifest = _manifest_path(map_name)
    sidecar = _sidecar_path(map_name)
    # Fall back to prior TEMP sidecars when the prep root does not have one yet.
    if not os.path.isfile(sidecar):
        temp = os.environ.get("TEMP", "")
        for prior in ("a21-importer-reverify", "a14-import-verify"):
            alt = os.path.join(temp, prior, "%s.script-actions.json" % map_name)
            if os.path.isfile(alt):
                sidecar = alt
                break
        if map_name == "1-Medical":
            med = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical.script-actions.json"
            if os.path.isfile(med):
                sidecar = med

    if not os.path.isfile(manifest):
        raise RuntimeError("missing manifest %s — run prepare_script_import_exports.py first" % manifest)
    if not os.path.isfile(sidecar):
        raise RuntimeError("missing sidecar %s — run prepare_script_import_exports.py first" % sidecar)

    _open_scratch()
    imported = import_scripts.import_scripts(
        manifest,
        limit=None,
        props_path=sidecar,
    )
    return _summarize(map_name, imported)


def main(out=None):
    out = out or _default_out()
    maps = _maps_to_run()
    report = {
        "started": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "scratch_map": SCRATCH_MAP,
        "maps_requested": maps,
        "maps": {},
        "medical_baseline": MEDICAL_BASELINE,
        "tail1_target_hits": {},
        "aggregate_unmapped_classes": {},
        "aggregate_nested_unmapped_classes": {},
        "failures": [],
        "stopped_at": None,
    }

    if "1-Medical" not in maps:
        report["maps"]["1-Medical"] = dict(MEDICAL_BASELINE)

    for map_name in maps:
        _log("=== %s ===" % map_name)
        t0 = time.time()
        try:
            summary = import_one_map(map_name)
            summary["elapsed_s"] = round(time.time() - t0, 2)
            hits = _gap_classes_closed(summary)
            summary["tail1_target_hits"] = hits
            report["maps"][map_name] = summary
            if hits:
                report["tail1_target_hits"][map_name] = hits
                report["failures"].append("%s still unmapped %s" % (map_name, hits))
            for bucket_key, agg_key in (
                ("unmapped_classes", "aggregate_unmapped_classes"),
                ("nested_unmapped_classes", "aggregate_nested_unmapped_classes"),
            ):
                for cls, count in (summary.get(bucket_key) or {}).items():
                    report[agg_key][cls] = report[agg_key].get(cls, 0) + int(count)
            _log(
                "%s scripts=%s mapped=%s nested_unmapped=%s unmapped=%s"
                % (
                    map_name,
                    summary.get("scripts_imported"),
                    summary.get("actions_mapped"),
                    summary.get("nested_unmapped"),
                    summary.get("unmapped_classes"),
                )
            )
            # Persist after each map so a later crash still leaves partial evidence.
            os.makedirs(os.path.dirname(os.path.abspath(out)) or ".", exist_ok=True)
            with open(out, "w", encoding="utf-8") as handle:
                json.dump(report, handle, indent=2)
        except Exception as exc:  # noqa: BLE001 — stop/report rather than paper over
            report["failures"].append("%s: %s" % (map_name, exc))
            report["stopped_at"] = map_name
            report["maps"][map_name] = {"map": map_name, "error": str(exc)}
            _log("FAILED %s: %s" % (map_name, exc))
            os.makedirs(os.path.dirname(os.path.abspath(out)) or ".", exist_ok=True)
            with open(out, "w", encoding="utf-8") as handle:
                json.dump(report, handle, indent=2)
            if _stop_on_error():
                raise

    report["finished"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    report["ok"] = not report["failures"]
    os.makedirs(os.path.dirname(os.path.abspath(out)) or ".", exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    _log("done ok=%s failures=%s out=%s" % (report["ok"], report["failures"], out))
    return report
