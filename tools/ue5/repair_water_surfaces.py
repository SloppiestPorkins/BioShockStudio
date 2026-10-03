"""Replace imported PhysicsVolume water brushes with AShockWaterVolume + surface.

Prior imports spawned FluidVolume / CascadingWaterVolume / TunnelCollapseWaterVolume as
PhysicsVolume and hid the green brush. This repairs maps already on disk without a full
level re-import: destroy the old volume, spawn AShockWaterVolume at the same transform /
bounds, configure the top-face surface.

Run headless (editor CLOSED):
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_water_surfaces.py \\
    -unattended -nopause -nosplash
Env: BIOSHOCK_WATER_MAP (default /Game/BioShockSlice/1-Medical)
     BIOSHOCK_WATER_DRY=1 to report without saving
     BIOSHOCK_ACTION_OUT (JSON report; default %TEMP%/repair_water_surfaces.json)

Pipeline: one-off -- import_level now spawns AShockWaterVolume directly; this converted maps
imported before that.
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

MAP = os.environ.get("BIOSHOCK_WATER_MAP", "/Game/BioShockSlice/1-Medical")
DRY = os.environ.get("BIOSHOCK_WATER_DRY", "0") == "1"
OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "repair_water_surfaces.json"),
)

_WATER_TAGS = (
    "BioShockClass=FluidVolume",
    "BioShockClass=CascadingWaterVolume",
    "BioShockClass=TunnelCollapseWaterVolume",
)


def _log(message):
    unreal.log("[bioshock-water] %s" % message)


def _write(report):
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _bio_class(actor):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith("BioShockClass="):
            return text[len("BioShockClass=") :]
    return ""


def _key_tag(actor):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith("BioShockKey="):
            return text
    return None


def main():
    report = {
        "map": MAP,
        "dryRun": DRY,
        "error": None,
        "replaced": 0,
        "refreshed": 0,
        "skipped": 0,
        "actors": [],
    }

    import author_water_material

    mat_report = {"failures": [], "assets": {}}
    author_water_material.ensure_water_materials(mat_report)
    report["materials"] = mat_report.get("assets") or {}
    if mat_report.get("failures"):
        report["error"] = "material authoring failed: %s" % mat_report["failures"]
        _write(report)
        raise RuntimeError(report["error"])

    if not unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(MAP):
        report["error"] = "could not load %s" % MAP
        _write(report)
        raise RuntimeError(report["error"])

    water_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWaterVolume")
    if not water_cls:
        report["error"] = "ShockWaterVolume class missing — rebuild BioShockRuntime"
        _write(report)
        raise RuntimeError(report["error"])

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    candidates = []
    for actor in subsystem.get_all_level_actors():
        bio = _bio_class(actor)
        if bio not in (
            "FluidVolume",
            "CascadingWaterVolume",
            "TunnelCollapseWaterVolume",
        ):
            continue
        candidates.append(actor)

    for actor in candidates:
        bio = _bio_class(actor)
        cascading = bio == "CascadingWaterVolume"
        label = actor.get_actor_label()
        loc = actor.get_actor_location()
        rot = actor.get_actor_rotation()
        tags = list(actor.tags)
        entry = {"label": label, "class": bio, "action": None}

        # Half-extent from actor bounds (world) — axis-aligned approximation.
        origin, extent = actor.get_actor_bounds(False)
        half = unreal.Vector(abs(extent.x), abs(extent.y), abs(extent.z))
        # Prefer the volume box if already a ShockWaterVolume. water_cls is a unreal.Class
        # (not a Python type), so compare via get_class / class_is_child_of, not isinstance.
        actor_cls = actor.get_class()
        already = actor_cls == water_cls or unreal.MathLibrary.class_is_child_of(actor_cls, water_cls)

        if already:
            if DRY:
                entry["action"] = "would_refresh"
                report["refreshed"] += 1
            else:
                actor.configure_from_half_extent(half, cascading)
                # Keep surface visible after any prior hide-volume pass.
                surface = getattr(actor, "surface", None)
                if surface is not None:
                    surface.set_editor_property("hidden_in_game", False)
                    surface.set_editor_property("visible", True)
                entry["action"] = "refreshed"
                report["refreshed"] += 1
            report["actors"].append(entry)
            continue

        if DRY:
            entry["action"] = "would_replace"
            entry["halfExtent"] = [half.x, half.y, half.z]
            report["replaced"] += 1
            report["actors"].append(entry)
            continue

        new_actor = subsystem.spawn_actor_from_class(water_cls, loc, rot)
        if new_actor is None:
            entry["action"] = "spawn_failed"
            report["skipped"] += 1
            report["actors"].append(entry)
            continue

        new_actor.set_actor_label(label)
        new_actor.tags = tags
        # Center on the old volume's bounds center (brush actors may have offset pivots).
        new_actor.set_actor_location(origin, False, False)
        new_actor.configure_from_half_extent(half, cascading)
        subsystem.destroy_actor(actor)
        entry["action"] = "replaced"
        entry["halfExtent"] = [half.x, half.y, half.z]
        report["replaced"] += 1
        report["actors"].append(entry)

    if not DRY and (report["replaced"] or report["refreshed"]):
        world = unreal.EditorLevelLibrary.get_editor_world()
        if not unreal.EditorLoadingAndSavingUtils.save_map(world, MAP):
            report["error"] = "save_map failed"
            _write(report)
            raise RuntimeError(report["error"])
        report["saved"] = True

    _write(report)
    _log(
        "replaced=%d refreshed=%d skipped=%d -> %s"
        % (report["replaced"], report["refreshed"], report["skipped"], OUT)
    )
    return report


if __name__ == "__main__":
    main()
