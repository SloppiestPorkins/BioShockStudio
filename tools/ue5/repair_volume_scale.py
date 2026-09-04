"""Repair BioShock-imported volumes that were scaled by raw half-extent uu.

import_level._import_region_volumes used to call set_actor_scale3d(half_extent) when the
spawned class had no set_box_extent API (BlockingVolume / PhysicsVolume). UE's default volume
brush is a 200uu cube (local half-extent 100), so a room that should be scale≈1.12 became
scale=112 and extent≈11200 — solid blockers tens of thousands of uu across.

Symptom (measured 4 Sept 2026, 1-Medical MedicalStart): ShockPlayer stuck in MOVE_Falling with
vel=(0,0,0) for seconds despite gravityZ=-980. CMC works in clear air with capsule collision
off; with collision on, 28 overlaps include giant BlockingVolumes (extent 11k–44k uu).

This divides any BioShock-tagged Volume whose scale looks like raw uu (|component| > 10) by 100
and saves the map. Idempotent once scales are sane.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_volume_scale.py \\
    -unattended -nopause -nosplash
Env: BIOSHOCK_VOLSCALE_MAP (default /Game/BioShockSlice/1-Medical)
     BIOSHOCK_VOLSCALE_DRY=1 to report without saving
"""

from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_VOLSCALE_MAP", "/Game/BioShockSlice/1-Medical")
DRY = os.environ.get("BIOSHOCK_VOLSCALE_DRY", "0") == "1"
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_volume_scale.json")
DEFAULT_BRUSH_HALF = 100.0
# Real post-fix scales are small (room half-extent / 100). Raw-uu bug leaves components >> 10.
RAW_UU_SCALE_THRESHOLD = 10.0


def _is_bioshock_volume(actor):
    if not isinstance(actor, unreal.Volume):
        return False
    for tag in actor.tags:
        text = str(tag)
        if text.startswith("BioShockKey=") or text.startswith("BioShockClass="):
            return True
    return False


def _looks_like_raw_uu_scale(scale):
    return (
        abs(scale.x) > RAW_UU_SCALE_THRESHOLD
        or abs(scale.y) > RAW_UU_SCALE_THRESHOLD
        or abs(scale.z) > RAW_UU_SCALE_THRESHOLD
    )


def main():
    report = {
        "map": MAP,
        "dryRun": DRY,
        "error": None,
        "scanned": 0,
        "fixed": 0,
        "skipped": 0,
        "actors": [],
    }
    if not unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(MAP):
        report["error"] = "could not load %s" % MAP
        _write(report)
        raise RuntimeError(report["error"])

    for actor in unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors():
        if not _is_bioshock_volume(actor):
            continue
        report["scanned"] += 1
        scale = actor.get_actor_scale3d()
        entry = {
            "label": actor.get_actor_label(),
            "class": type(actor).__name__,
            "scaleBefore": [scale.x, scale.y, scale.z],
        }
        if not _looks_like_raw_uu_scale(scale):
            entry["action"] = "skip_sane_scale"
            report["skipped"] += 1
            report["actors"].append(entry)
            continue
        new_scale = unreal.Vector(
            scale.x / DEFAULT_BRUSH_HALF,
            scale.y / DEFAULT_BRUSH_HALF,
            scale.z / DEFAULT_BRUSH_HALF,
        )
        entry["scaleAfter"] = [new_scale.x, new_scale.y, new_scale.z]
        if DRY:
            entry["action"] = "would_fix"
        else:
            actor.set_actor_scale3d(new_scale)
            entry["action"] = "fixed"
            report["fixed"] += 1
        report["actors"].append(entry)

    if not DRY and report["fixed"]:
        world = unreal.EditorLevelLibrary.get_editor_world()
        if not unreal.EditorLoadingAndSavingUtils.save_map(world, MAP):
            report["error"] = "save_map failed"
            _write(report)
            raise RuntimeError(report["error"])
        report["saved"] = True

    _write(report)
    unreal.log(
        "[volscale] scanned=%d fixed=%d skipped=%d"
        % (report["scanned"], report["fixed"], report["skipped"])
    )
    return report


def _write(report):
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
