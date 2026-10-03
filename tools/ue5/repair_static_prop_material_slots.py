"""Reimport multi-material static props whose LOD section count is below the manifest.

Why this exists: `_assign_asset_material` wrote N material slots onto meshes that still had a
single render section from a pre-`usemtl` OBJ import. Every triangle sampled slot 0, so windows
and ad frames showed the first texture on every slot. Slot assignment cannot invent sections —
the OBJ must be reimported so Interchange/legacy import rebuilds one section per `usemtl` group.
`import_level._import_asset_meshes` now does that automatically for future level imports; this
script repairs already-imported Content without a full level reimport.

What it does:
  1. Read the map's `.ue5-level.json`.
  2. For each `StaticMesh` / `SkeletalMesh` asset with 2+ manifest sections (skips source
     `Brush` OBJs — not placed; geometry lives in BuiltWorld — and skips `BuiltWorld` itself,
     which has its own collision-sensitive reimport path):
     if the on-disk mesh is missing or `get_num_sections(0) < len(sections)`, reimport its OBJ
     with replace_existing and re-bind materials via `_assign_asset_material`.
  3. Save each touched mesh asset. Does **not** load or save any map.

What it does **not** touch:
  - Placed actors, levels, lights, skeletal meshes, textures, material instances.
  - Compiled-world / BuiltWorld meshes (collision regression risk — use
    `reimport_compiled_world_only.py` + complex-as-simple for those).
  - Single-section props (unaffected by the bug even when MaterialIndex is trivially 0).

Run headless (editor must not have the project exclusively locked if replace_existing fights
it; prefer `-nullrhi` with the editor closed):
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_static_prop_material_slots.py \
    -unattended -nopause -nosplash -nullrhi
Env:
  BIOSHOCK_PROP_REPAIR_MANIFEST   path to <map>.ue5-level.json (required)
  BIOSHOCK_PROP_REPAIR_CONTENT    content root (default /Game/BioShockSlice/Content)
  BIOSHOCK_PROP_REPAIR_DRY        "1" to report mismatches and change nothing
  BIOSHOCK_PROP_REPAIR_LIMIT      max assets to reimport (0 = no limit; useful for a smoke pass)

Pipeline: one-off -- import_level now detects and reimports section-count mismatches itself
(_mesh_section_count_mismatch).
"""

from __future__ import annotations

import json
import os
import sys
import traceback

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_bioshock  # noqa: E402
import import_level  # noqa: E402

MANIFEST = os.environ.get("BIOSHOCK_PROP_REPAIR_MANIFEST", "")
CONTENT_ROOT = os.environ.get("BIOSHOCK_PROP_REPAIR_CONTENT", "/Game/BioShockSlice/Content")
DRY = os.environ.get("BIOSHOCK_PROP_REPAIR_DRY", "0") == "1"
LIMIT = int(os.environ.get("BIOSHOCK_PROP_REPAIR_LIMIT", "0") or "0")
OUT = os.environ.get(
    "BIOSHOCK_PROP_REPAIR_OUT",
    os.path.join(os.environ.get("TEMP", "."), "repair_static_prop_material_slots.json"),
)


def _materials_by_key(manifest, content_root):
    package = manifest.get("package") or "Level"
    destinations = ["%s/%s" % (content_root, package), content_root]
    by_key = {}
    for material in manifest.get("materials") or []:
        stem = import_bioshock._safe_name(material.get("name") or "")
        for dest in destinations:
            path = "%s/Materials/MI_%s" % (dest, stem)
            if unreal.EditorAssetLibrary.does_asset_exist(path):
                mi = unreal.EditorAssetLibrary.load_asset(path)
                if mi is not None:
                    by_key[material["key"]] = mi
                    break
    return by_key


def _is_architecture_shell(asset):
    """Compiled-CSG world geometry — out of scope here (collision-sensitive reimport)."""
    return (asset.get("kind") or "").strip() == "BuiltWorld"


def _is_prop_mesh(asset):
    """Placed prop meshes only — skip source CSG `Brush` OBJs (not drawn; geometry is in BuiltWorld)."""
    return (asset.get("kind") or "").strip() in ("StaticMesh", "SkeletalMesh")


def main():
    report = {
        "contentRoot": CONTENT_ROOT,
        "dryRun": DRY,
        "limit": LIMIT,
        "candidates": 0,
        "alreadyOk": 0,
        "missingObj": 0,
        "reimported": 0,
        "failed": 0,
        "assets": [],
        "error": None,
    }
    if not MANIFEST:
        report["error"] = "BIOSHOCK_PROP_REPAIR_MANIFEST is required"
        _write(report)
        raise RuntimeError(report["error"])

    with open(MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    manifest_dir = os.path.dirname(MANIFEST)
    materials_by_key = {} if DRY else _materials_by_key(manifest, CONTENT_ROOT)
    report["materialsResolved"] = len(materials_by_key)

    for asset in manifest.get("assets") or []:
        sections = asset.get("sections") or []
        if len(sections) < 2:
            continue
        if _is_architecture_shell(asset) or not _is_prop_mesh(asset):
            continue
        if not asset.get("file"):
            continue

        report["candidates"] += 1
        source = os.path.join(manifest_dir, asset["file"].replace("/", os.sep))
        stem = os.path.splitext(os.path.basename(source))[0]
        asset_path = "%s/Meshes/%s" % (CONTENT_ROOT, stem)
        entry = {
            "key": asset.get("key"),
            "name": asset.get("name"),
            "stem": stem,
            "manifestSections": len(sections),
        }

        if not os.path.isfile(source):
            entry["status"] = "obj missing"
            report["missingObj"] += 1
            report["assets"].append(entry)
            continue

        mesh = None
        if unreal.EditorAssetLibrary.does_asset_exist(asset_path):
            mesh = unreal.EditorAssetLibrary.load_asset(asset_path)
            if isinstance(mesh, unreal.StaticMesh):
                entry["sectionsBefore"] = mesh.get_num_sections(0)
                if not import_level._mesh_section_count_mismatch(mesh, asset):
                    entry["status"] = "already ok"
                    report["alreadyOk"] += 1
                    report["assets"].append(entry)
                    continue
            else:
                mesh = None
                entry["sectionsBefore"] = None
        else:
            entry["sectionsBefore"] = None

        if DRY:
            entry["status"] = "would reimport"
            report["wouldReimport"] = report.get("wouldReimport", 0) + 1
            report["assets"].append(entry)
            if LIMIT and report["wouldReimport"] >= LIMIT:
                break
            continue

        if LIMIT and report["reimported"] >= LIMIT:
            entry["status"] = "skipped (limit)"
            report["assets"].append(entry)
            break

        mesh = import_level._import_static_mesh_obj(source, "%s/Meshes" % CONTENT_ROOT, stem)
        if mesh is None:
            entry["status"] = "reimport failed"
            report["failed"] += 1
            report["assets"].append(entry)
            continue

        entry["sectionsAfter"] = mesh.get_num_sections(0)
        assign_report = {}
        import_level._assign_asset_material(mesh, asset, materials_by_key, assign_report)
        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        entry["assign"] = assign_report
        if entry["sectionsAfter"] < len(sections):
            entry["status"] = "still mismatched after reimport"
            report["failed"] += 1
        else:
            entry["status"] = "reimported"
            report["reimported"] += 1
        report["assets"].append(entry)

    _write(report)
    unreal.log("[repair-prop-mats] %s" % json.dumps(
        {k: report[k] for k in (
            "candidates", "alreadyOk", "reimported", "failed", "missingObj", "dryRun", "error")
         if k in report},
        default=str))
    return report


def _write(report):
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, default=str)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # noqa: BLE001
        payload = {"error": str(exc), "traceback": traceback.format_exc()}
        _write(payload)
        raise
