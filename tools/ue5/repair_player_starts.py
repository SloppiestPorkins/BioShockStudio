"""Promote imported PlayerStart placeholders to real APlayerStart actors.

`import_level.py` used to place every non-geometry actor as a positioned TargetPoint, PlayerStarts
included. A TargetPoint is invisible to AGameModeBase::ChoosePlayerStart, so a map imported that way
spawns the pawn at world origin — outside the level. The first render this project ever captured of
/Game/BioShockLevel/1-Medical showed exactly that: the player in the void, looking at open sky.

import_level.py now spawns the right class (see _PLACED_ACTOR_CLASSES), but that only helps a fresh
import. This repairs the maps already on disk, in place, without re-importing 15 levels: every
placeholder carries a `BioShockClass=<name>` tag from `_place`, so the PlayerStarts are findable.

It also snaps any PlayerStart that lands buried or floating (more than BIOSHOCK_PS_SNAP_THRESHOLD
uu from every imported AI path node) onto the nearest walkable node — 1-Welcome's second start
sat 810 uu away and 655 uu below the floor, so ChoosePlayerStart could drop the pawn into the
void. The path nodes are the game's own walkable markers; no physics trace is used (they do not
work reliably in a -run=pythonscript commandlet).

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_player_starts.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_PS_MAPS             comma-separated /Game map paths (default: /Game/BioShockLevel/1-Medical)
  BIOSHOCK_PS_DRY              "1" to report without changing anything
  BIOSHOCK_PS_SNAP_THRESHOLD   uu; a start further than this from any path node is snapped (default 180)

Pipeline: one-off -- import_level now places real PlayerStart actors; this promoted TargetPoint
placeholders in older imports.
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

# A PlayerStart within this distance of a walkable AI path node is trusted as-is; further than
# this it is treated as buried/floating and snapped onto the nearest node. Measured on 1-Welcome:
# start 0 sat 21 uu from a PathNode (fine), start 1 sat 810 uu away and 655 uu below the floor.
NODE_SNAP_THRESHOLD = float(os.environ.get("BIOSHOCK_PS_SNAP_THRESHOLD", "180"))
# Half the player capsule (ShockPlayer sets 88) plus a margin, so the snapped start is standing
# on the node, not clipping through it.
NODE_SNAP_LIFT = 96.0
# Nodes the game placed on walkable ground. Flying/ceiling nodes are excluded on purpose.
WALKABLE_NODE_CLASSES = {"PlayerPathNode", "PathNode", "FloorPoint", "PatrolPoint"}


def _lvl():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _actor_class_tag(actor):
    for t in actor.tags:
        s = str(t)
        if s.startswith("BioShockClass="):
            return s.split("=", 1)[1]
    return None


def _walkable_node_locations():
    """World locations of every imported AI path node the game placed on walkable ground."""
    locs = []
    for actor in _actors().get_all_level_actors():
        if _actor_class_tag(actor) in WALKABLE_NODE_CLASSES:
            v = actor.get_actor_location()
            locs.append((v.x, v.y, v.z))
    return locs


def _snap_starts_to_floor(entry):
    """Move any PlayerStart that is far from every path node onto the nearest one.

    Imported story maps carry PlayerStarts straight from the manifest; some land buried below
    the floor or embedded in a wall (1-Welcome start 1 was 655 uu under the geometry). The AI
    path nodes are authoritative walkable points, so snapping a stray start to the closest one
    gives a spawn the player can actually stand on — no physics trace, which does not work
    reliably in a -run=pythonscript commandlet anyway.
    """
    nodes = _walkable_node_locations()
    entry["walkableNodes"] = len(nodes)
    if not nodes:
        return
    for start in _actors().get_all_level_actors():
        if not isinstance(start, unreal.PlayerStart):
            continue
        if not any(str(t) == CLASS_TAG for t in start.tags):
            continue
        loc = start.get_actor_location()
        best = None
        best_d2 = None
        for nx, ny, nz in nodes:
            d2 = (nx - loc.x) ** 2 + (ny - loc.y) ** 2 + (nz - loc.z) ** 2
            if best_d2 is None or d2 < best_d2:
                best_d2 = d2
                best = (nx, ny, nz)
        dist = best_d2 ** 0.5
        rec = {"label": start.get_actor_label(),
               "was": [round(loc.x), round(loc.y), round(loc.z)],
               "nearestNodeDist": round(dist)}
        if dist > NODE_SNAP_THRESHOLD and not DRY:
            start.set_actor_location(
                unreal.Vector(best[0], best[1], best[2] + NODE_SNAP_LIFT), False, False)
            rec["snappedTo"] = [round(best[0]), round(best[1]), round(best[2] + NODE_SNAP_LIFT)]
            entry["snapped"] = entry.get("snapped", 0) + 1
        entry.setdefault("startAudit", []).append(rec)


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

    if not targets:
        _snap_starts_to_floor(entry)
        if entry.get("snapped") and not DRY:
            world = unreal.EditorLevelLibrary.get_editor_world()
            try:
                entry["saved"] = bool(unreal.EditorLoadingAndSavingUtils.save_map(world, map_path))
            except Exception as exc:  # noqa: BLE001
                entry["error"] = "save_map: %s" % exc
        return entry
    if DRY:
        _snap_starts_to_floor(entry)
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

    _snap_starts_to_floor(entry)

    if entry["promoted"] or entry.get("snapped"):
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
