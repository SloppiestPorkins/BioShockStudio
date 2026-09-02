"""Promote imported PlayerStart placeholders to real APlayerStart actors.

`import_level.py` used to place every non-geometry actor as a positioned TargetPoint, PlayerStarts
included. A TargetPoint is invisible to AGameModeBase::ChoosePlayerStart, so a map imported that way
spawns the pawn at world origin — outside the level. The first render this project ever captured of
/Game/BioShockLevel/1-Medical showed exactly that: the player in the void, looking at open sky.

import_level.py now spawns the right class (see _PLACED_ACTOR_CLASSES), but that only helps a fresh
import. This repairs the maps already on disk, in place, without re-importing 15 levels: every
placeholder carries a `BioShockClass=<name>` tag from `_place`, so the PlayerStarts are findable.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_player_starts.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_PS_MAPS   comma-separated /Game map paths (default: /Game/BioShockLevel/1-Medical)
  BIOSHOCK_PS_DRY    "1" to report without changing anything
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

MAPS = [m.strip() for m in os.environ.get(
    "BIOSHOCK_PS_MAPS", "/Game/BioShockLevel/1-Medical").split(",") if m.strip()]
DRY = os.environ.get("BIOSHOCK_PS_DRY", "0") == "1"
CLASS_TAG = "BioShockClass=PlayerStart"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_reports", "repair_player_starts.json")


def _lvl():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _repair_map(map_path):
    entry = {"map": map_path, "found": 0, "promoted": 0, "alreadyCorrect": 0, "saved": False}
    if not _lvl().load_level(map_path):
        entry["error"] = "could not load"
        return entry

    # Snapshot first: spawning while iterating the live actor list is asking for trouble.
    targets = []
    for actor in _actors().get_all_level_actors():
        if not any(str(t) == CLASS_TAG for t in actor.tags):
            continue
        entry["found"] += 1
        if isinstance(actor, unreal.PlayerStart):
            entry["alreadyCorrect"] += 1
            continue
        targets.append(actor)

    if DRY or not targets:
        return entry

    for old in targets:
        loc = old.get_actor_location()
        rot = old.get_actor_rotation()
        label = old.get_actor_label()
        tags = list(old.tags)

        start = _actors().spawn_actor_from_class(unreal.PlayerStart, loc, rot)
        if start is None:
            continue
        start.set_actor_label(label)
        # Carry the identity tags across so a re-import still recognises this actor as its own,
        # rather than placing a second one beside it.
        start.tags = tags
        _actors().destroy_actor(old)
        entry["promoted"] += 1

    if entry["promoted"]:
        world = unreal.EditorLevelLibrary.get_editor_world()
        try:
            entry["saved"] = bool(unreal.EditorLoadingAndSavingUtils.save_map(world, map_path))
        except Exception as exc:  # noqa: BLE001
            entry["error"] = "save_map: %s" % exc
    return entry


def main():
    report = {"dryRun": DRY, "maps": []}
    for m in MAPS:
        result = _repair_map(m)
        report["maps"].append(result)
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        with open(OUT, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)
    unreal.log("[player-starts] %s" % json.dumps(report))
    return report


if __name__ == "__main__":
    main()
