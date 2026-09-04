"""Batch level conversion: export-level + import_level for every shipped map.

Phase A1 of docs/FULL_GAME_CONVERSION.md. For each map:
  1. Run `export-level <map> <tempdir>` (subprocess, real shipped bytes).
  2. Open or create `/Game/BioShockLevel/<map>` and call `import_level.main(manifest)`.
  3. Optionally apply the dynamic directional + sky fill lighting stopgap.
  4. Save the level and record created / updated / skipped / unsupported counts.

Idempotent: skips a map whose BioShockKey-tagged actor count already matches the freshly
exported manifest's expected count, unless `--force` (BIOSHOCK_IMPORT_FORCE=1).

Configure via environment (headless drivers cannot rely on argv under -run=pythonscript):
  BIOSHOCK_IMPORT_MAPS          comma-separated subset; default all 21 shipped maps
  BIOSHOCK_IMPORT_FORCE=1       re-import even when key count matches
  BIOSHOCK_IMPORT_LIGHTING_STOPGAP=0   disable dynamic fill (default on)
  BIOSHOCK_IMPORT_OUT           report JSON path (default %TEMP%/bioshock_import_all_levels.json)
  BIOSHOCK_IMPORT_KEEP_EXPORTS=1  keep each map's %TEMP%/bioshock-import-all-levels/<map>/ export
                               tree after its import (default: delete it once the map is done, so a
                               multi-map run does not accumulate every map's FBX/textures in %TEMP%)
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import time

import unreal

import import_level

CONTENT_ROOT = "/Game/BioShockLevel"
SCRATCH_MAP = "/Game/BioShockLevel/_Scratch"
FILL_TAG = "BioShockSliceFill"

# 21 non-localised shipped map packages (docs/research/remastered.md).
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


def _log(message):
    unreal.log("[bioshock-import-all-levels] %s" % message)


def _repo_root():
    here = os.path.abspath(os.path.dirname(__file__))
    return os.path.abspath(os.path.join(here, "..", ".."))


def _default_game_root():
    override = os.environ.get("BIOSHOCK_REMASTERED_PATH")
    if override and os.path.isdir(os.path.join(override, "ContentBaked", "pc", "Maps")):
        return override
    return (
        r"G:\SteamLibrary\steamapps\common\BioShock Remastered"
    )


def _package_bsm(map_name):
    maps_dir = os.path.join(_default_game_root(), "ContentBaked", "pc", "Maps")
    path = os.path.join(maps_dir, map_name + ".bsm")
    if os.path.isfile(path):
        return path
    raise RuntimeError("map package not found: %s (set BIOSHOCK_REMASTERED_PATH)" % path)


def _export_root():
    return os.path.join(os.environ.get("TEMP", "."), "bioshock-import-all-levels")


def _map_export_dir(map_name):
    return os.path.join(_export_root(), map_name)


def _keep_exports():
    return os.environ.get("BIOSHOCK_IMPORT_KEEP_EXPORTS") == "1"


def _cleanup_map_exports(map_name):
    """Delete one map's re-exported manifest/FBX/texture tree once its import is finished.

    A multi-map run otherwise leaves every map's export under %TEMP%: this reached 44 GB over the
    21-map run on 1 Sept 2026, filled the C: drive, and killed the run at map 16. The per-map JSON
    report is written to BIOSHOCK_IMPORT_OUT, not into this tree, so it is untouched. Opt out with
    BIOSHOCK_IMPORT_KEEP_EXPORTS=1 when debugging an export.
    """
    if _keep_exports():
        return
    path = _map_export_dir(map_name)
    if not os.path.isdir(path):
        return
    failed = []
    shutil.rmtree(path, onerror=lambda _f, p, _e: failed.append(p))
    if failed:
        _log("export dir not fully removed: %s (%d paths left)" % (path, len(failed)))
    else:
        _log("removed export dir %s" % path)


def _export_manifest_to_temp(map_name):
    """Run export-level into %TEMP%; return manifest path."""
    out_dir = _map_export_dir(map_name)
    os.makedirs(out_dir, exist_ok=True)
    package_bsm = _package_bsm(map_name)
    cli = os.path.join(_repo_root(), "src", "BioShockStudio.Cli")
    cmd = [
        "dotnet",
        "run",
        "--project",
        cli,
        "--",
        "export-level",
        package_bsm,
        out_dir,
    ]
    subprocess.run(cmd, check=True, cwd=_repo_root())
    manifest = os.path.join(out_dir, map_name, map_name + ".ue5-level.json")
    if not os.path.isfile(manifest):
        raise RuntimeError("export-level did not write %s" % manifest)
    return manifest


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _ensure_content_folder(path):
    if unreal.EditorAssetLibrary.does_directory_exist(path):
        return
    if not unreal.EditorAssetLibrary.make_directory(path):
        raise RuntimeError("could not create content folder %s" % path)


def _open_level(map_path):
    """Load an existing BioShockLevel map or create a fresh one."""
    _ensure_content_folder(CONTENT_ROOT)
    level = _level_subsystem()
    if unreal.EditorAssetLibrary.does_asset_exist(map_path):
        if not level.load_level(map_path):
            raise RuntimeError("existing level %s did not load" % map_path)
        return
    if not level.new_level(map_path):
        raise RuntimeError("could not create level %s" % map_path)


def _disable_interchange():
    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag)


def _expected_bioshock_key_count(manifest):
    """Keys import_level would tag — mirrors its handled-set walk without spawning."""
    handled = set()
    count = 0

    for light in manifest.get("lights") or []:
        radius = light.get("radius")
        if radius is not None and float(radius) > 0:
            handled.add(light["key"])
            count += 1

    for entry in manifest.get("actors") or []:
        if entry.get("className") == "CubemapProbe":
            handled.add(entry["key"])
            count += 1

    actor_classes = import_level._manifest_actor_classes(manifest)
    asset_kinds = import_level._manifest_asset_kinds(manifest)
    for instance in manifest.get("instances") or []:
        key = "instance:" + instance["actorKey"] + ":" + instance["asset"]
        if key in handled:
            continue
        actor_class = actor_classes.get(instance["actorKey"], "")
        asset_kind = asset_kinds.get(instance["asset"], "")
        if import_level._should_place_mesh_instance(actor_class, asset_kind):
            count += 1

    assets = import_level._manifest_assets_by_key(manifest)
    instances_by = import_level._instances_by_actor_key(manifest)
    for entry in manifest.get("actors") or []:
        class_name = entry.get("className") or ""
        if not import_level._is_non_drawn_volume(class_name) or class_name.endswith("ZoneInfo"):
            continue
        key = entry["key"]
        if key in handled:
            continue
        handled.add(key)
        brush_instances = [
            inst for inst in instances_by.get(key, [])
            if assets.get(inst.get("asset"), {}).get("kind") == "Brush"]
        if brush_instances and import_level._resolve_volume_class(class_name):
            count += 1

    for entry in manifest.get("actors") or []:
        key = entry["key"]
        if key in handled:
            continue
        count += 1

    return count


def _count_bioshock_keys():
    return len(import_level._existing_by_key())


def _unsupported_classes():
    classes = set()
    for actor in import_level._actor_subsystem().get_all_level_actors():
        if not isinstance(actor, unreal.TargetPoint):
            continue
        if not any(str(tag).startswith(import_level.KEY_TAG_PREFIX) for tag in actor.tags):
            continue
        for tag in actor.tags:
            text = str(tag)
            if text.startswith("BioShockClass="):
                cls = text[len("BioShockClass="):]
                if cls not in ("LevelInfo", "ZoneInfo"):
                    classes.add(cls)
                break
    return sorted(classes)


def _has_fill_light():
    for actor in import_level._actor_subsystem().get_all_level_actors():
        if not isinstance(actor, unreal.DirectionalLight):
            continue
        if any(str(tag) == FILL_TAG for tag in actor.tags):
            return True
    return False


def _enable_dynamic_lighting():
    """Same stopgap as ShockGameMode::EnableDynamicLighting — movable meshes + fill sun/sky."""
    world = unreal.EditorLevelLibrary.get_editor_world()
    if world is None:
        return {"movableMeshes": 0, "fillAdded": False}

    settings = world.get_world_settings()
    if settings is not None:
        settings.set_editor_property("force_no_precomputed_lighting", True)

    movable = 0
    for actor in import_level._actor_subsystem().get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        mesh = actor.static_mesh_component
        if mesh.get_editor_property("mobility") == unreal.ComponentMobility.STATIC:
            mesh.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
            movable += 1

    fill_added = False
    if not _has_fill_light():
        sun = import_level._actor_subsystem().spawn_actor_from_class(
            unreal.DirectionalLight,
            unreal.Vector(0.0, 0.0, 0.0),
            unreal.Rotator(-46.0, -35.0, 0.0))
        if sun is not None:
            sun.tags = [unreal.Name(FILL_TAG)]
            component = sun.get_editor_property("directional_light_component")
            if component is not None:
                component.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
                component.set_intensity(12.0)

        sky = import_level._actor_subsystem().spawn_actor_from_class(
            unreal.SkyLight,
            unreal.Vector(0.0, 0.0, 0.0),
            unreal.Rotator(0.0, 0.0, 0.0))
        if sky is not None:
            sky.tags = [unreal.Name(FILL_TAG)]
            sky_comp = sky.get_editor_property("light_component")
            if sky_comp is not None:
                sky_comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
                sky_comp.set_intensity(1.0)
                sky_comp.set_editor_property("real_time_capture", True)
                sky_comp.recapture_sky()
        fill_added = True

    _log("dynamic lighting: movable=%d fill=%s" % (movable, "added" if fill_added else "existing"))
    return {"movableMeshes": movable, "fillAdded": fill_added}


def _parse_maps():
    raw = os.environ.get("BIOSHOCK_IMPORT_MAPS", "").strip()
    if not raw:
        return list(SHIPPED_MAPS)
    return [name.strip() for name in raw.split(",") if name.strip()]


def _parse_rig_names():
    """Which character rigs to import. A1 batch defaults to geometry-only (corpses still unioned in).

    BIOSHOCK_IMPORT_RIGS=all  — every rig the level places (slow; can crash UE on large anims)
    BIOSHOCK_IMPORT_RIGS=none — explicit empty filter (same as unset)
    BIOSHOCK_IMPORT_RIGS=Agg_BabyJane,TommyGun — named subset
    """
    raw = os.environ.get("BIOSHOCK_IMPORT_RIGS", "none").strip().lower()
    if raw in ("", "none"):
        return set()
    if raw == "all":
        return None
    return {name.strip() for name in raw.split(",") if name.strip()}


def _import_level(manifest_path, rig_names):
    """Call import_level.main, optionally skipping every skeletal rig (A1 geometry-only default)."""
    if rig_names is not None and len(rig_names) == 0:
        original = import_level._effective_rig_names

        def _geometry_only(manifest, _rig_names):
            return set()

        import_level._effective_rig_names = _geometry_only
        try:
            return import_level.main(
                manifest_path, content_root=CONTENT_ROOT, rig_names=rig_names)
        finally:
            import_level._effective_rig_names = original
    return import_level.main(manifest_path, content_root=CONTENT_ROOT, rig_names=rig_names)


def _write_report(report, report_path):
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _import_one(map_name, force=False, lighting_stopgap=True, rig_names=None, prior_entry=None):
    started = time.monotonic()
    entry = {
        "map": map_name,
        "imported": False,
        "skipped_idempotent": False,
        "created": 0,
        "updated": 0,
        "skipped": 0,
        "unsupported": 0,
        "unsupported_classes": [],
        "bioshock_key_count": 0,
        "expected_key_count": 0,
        "manifest": None,
        "level": "%s/%s" % (CONTENT_ROOT, map_name),
        "elapsed_seconds": 0.0,
        "error": None,
    }

    try:
        manifest_path = _export_manifest_to_temp(map_name)
        entry["manifest"] = manifest_path
        with open(manifest_path, "r", encoding="utf-8") as handle:
            manifest = json.load(handle)

        expected_keys = _expected_bioshock_key_count(manifest)
        entry["expected_key_count"] = expected_keys

        map_path = "%s/%s" % (CONTENT_ROOT, map_name)
        _open_level(map_path)
        existing_keys = _count_bioshock_keys()
        entry["bioshock_key_count"] = existing_keys

        if not force and existing_keys > 0 and prior_entry:
            prior_keys = prior_entry.get("bioshock_key_count") or 0
            if prior_entry.get("imported") and prior_keys == existing_keys:
                entry["skipped_idempotent"] = True
                entry["imported"] = True
                entry["created"] = prior_entry.get("created", 0)
                entry["updated"] = prior_entry.get("updated", 0)
                entry["skipped"] = prior_entry.get("skipped", 0)
                entry["unsupported"] = prior_entry.get("unsupported", 0)
                entry["unsupported_classes"] = prior_entry.get("unsupported_classes") or []
                if lighting_stopgap:
                    try:
                        entry["lighting"] = _enable_dynamic_lighting()
                    except Exception as exc:  # noqa: BLE001
                        entry["lighting_error"] = str(exc)
                    level = _level_subsystem()
                    if not level.save_current_level():
                        _log("warning: idempotent save failed for %s" % map_path)
                _log("%s: idempotent skip (%d keys match prior run)" % (map_name, existing_keys))
                entry["elapsed_seconds"] = round(time.monotonic() - started, 2)
                return entry

        if not force and existing_keys == expected_keys and expected_keys > 0:
            entry["skipped_idempotent"] = True
            entry["imported"] = True
            entry["unsupported_classes"] = _unsupported_classes()
            if lighting_stopgap:
                try:
                    entry["lighting"] = _enable_dynamic_lighting()
                except Exception as exc:  # noqa: BLE001
                    entry["lighting_error"] = str(exc)
                level = _level_subsystem()
                if not level.save_current_level():
                    _log("warning: idempotent save failed for %s" % map_path)
            _log("%s: idempotent skip (%d keys match expected)" % (map_name, existing_keys))
            entry["elapsed_seconds"] = round(time.monotonic() - started, 2)
            return entry

        import_report = _import_level(manifest_path, rig_names)
        entry["rigs_requested"] = (
            "all" if rig_names is None else sorted(rig_names) if rig_names else "none")
        entry["created"] = import_report.get("created", 0)
        entry["updated"] = import_report.get("updated", 0)
        entry["skipped"] = import_report.get("skipped", 0)
        entry["unsupported"] = import_report.get("unsupported", 0)
        entry["bioshock_key_count"] = _count_bioshock_keys()
        entry["unsupported_classes"] = _unsupported_classes()

        if lighting_stopgap:
            try:
                entry["lighting"] = _enable_dynamic_lighting()
            except Exception as exc:  # noqa: BLE001
                entry["lighting_error"] = str(exc)

        level = _level_subsystem()
        if not level.save_current_level():
            raise RuntimeError("save_current_level() failed for %s" % map_path)

        entry["imported"] = True
        _log("%s: import complete (%d created, %d updated, %d unsupported, %d keys)"
             % (map_name, entry["created"], entry["updated"],
                entry["unsupported"], entry["bioshock_key_count"]))
    except Exception as exc:  # noqa: BLE001 -- one map failing must not abort the batch
        entry["error"] = str(exc)
        _log("%s: FAILED — %s" % (map_name, exc))
    finally:
        _cleanup_map_exports(map_name)

    entry["elapsed_seconds"] = round(time.monotonic() - started, 2)
    return entry


def main(report_path=None, maps=None, force=None, lighting_stopgap=None, rig_names=None):
    """Run the batch import. Returns the full report dict."""
    report_path = report_path or os.environ.get(
        "BIOSHOCK_IMPORT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "bioshock_import_all_levels.json"),
    )
    maps = maps if maps is not None else _parse_maps()
    force = force if force is not None else os.environ.get("BIOSHOCK_IMPORT_FORCE") == "1"
    if lighting_stopgap is None:
        lighting_stopgap = os.environ.get("BIOSHOCK_IMPORT_LIGHTING_STOPGAP", "1") != "0"
    if rig_names is None:
        rig_names = _parse_rig_names()

    _disable_interchange()

    report = {
        "content_root": CONTENT_ROOT,
        "maps_requested": maps,
        "force": force,
        "lighting_stopgap": lighting_stopgap,
        "rig_names": "all" if rig_names is None else sorted(rig_names) if rig_names else "none",
        "results": {},
        "summary": {
            "total": 0,
            "imported": 0,
            "skipped_idempotent": 0,
            "failed": 0,
        },
        "error": None,
    }
    if os.path.isfile(report_path):
        try:
            with open(report_path, "r", encoding="utf-8") as handle:
                prior = json.load(handle)
            report["results"] = dict(prior.get("results") or {})
        except (json.JSONDecodeError, OSError):
            pass

    for map_name in maps:
        _log("=== %s ===" % map_name)
        entry = _import_one(
            map_name,
            force=force,
            lighting_stopgap=lighting_stopgap,
            rig_names=rig_names,
            prior_entry=report["results"].get(map_name),
        )
        report["results"][map_name] = entry
        _write_report(report, report_path)

    if not _keep_exports():
        try:
            os.rmdir(_export_root())  # only succeeds once every map's dir is cleaned up
        except OSError:
            pass

    report["summary"]["total"] = len(report["results"])
    report["summary"]["imported"] = sum(
        1 for entry in report["results"].values() if entry.get("imported"))
    report["summary"]["skipped_idempotent"] = sum(
        1 for entry in report["results"].values() if entry.get("skipped_idempotent"))
    report["summary"]["failed"] = sum(
        1 for entry in report["results"].values() if entry.get("error"))
    _write_report(report, report_path)

    report["report_path"] = report_path
    _log("report written to %s (%d imported, %d idempotent, %d failed)"
         % (report_path, report["summary"]["imported"],
            report["summary"]["skipped_idempotent"], report["summary"]["failed"]))
    return report
