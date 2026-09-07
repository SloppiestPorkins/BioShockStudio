"""Disable collision on semantic exterior/backdrop geometry in the playable slice.

The source level's Region/zone number is visibility topology, not an interior/exterior semantic,
and imported actor labels are mostly generic StaticMeshActor names. Classification therefore uses
anchored asset-name tokens authored for backdrop content; it deliberately does not use location or
the broad word "counter", which would catch interior furniture.

Env:
  BIOSHOCK_EXTERIOR_MAPS  comma-separated maps (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_EXTERIOR_DRY   "1" to report without changing the map
"""
from __future__ import annotations

import json
import os
import re

import unreal

MAPS = [value.strip() for value in os.environ.get(
    "BIOSHOCK_EXTERIOR_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if value.strip()]
DRY = os.environ.get("BIOSHOCK_EXTERIOR_DRY", "0") == "1"
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_exterior_collision.json")

_EXTERIOR = re.compile(
    r"(^skybox(?:_|$)|(?:^|_)outside(?:_|$)|(?:^|_)exterior(?:_|$)|"
    r"(?:^|_)cityscape(?:_|$)|(?:^|_)seabed(?:_|$)|(?:^|_)ocean(?:_|$)|"
    r"(?:^|_)distant(?:_|$)|(?:^|_)kelp(?:_|$)|(?:^|_)ext(?:_|$))",
    re.IGNORECASE,
)


def is_exterior_name(name):
    return bool(_EXTERIOR.search(name or ""))


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    report = {"dryRun": DRY, "maps": [], "failures": []}

    for map_path in MAPS:
        entry = {"map": map_path, "matched": [], "changed": 0}
        if not level.load_level(map_path):
            entry["error"] = "could not load"
            report["failures"].append("could not load %s" % map_path)
            report["maps"].append(entry)
            continue

        for actor in actors.get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None or not is_exterior_name(mesh.get_name()):
                continue
            before = str(comp.get_collision_enabled())
            item = {
                "actor": actor.get_actor_label(),
                "mesh": mesh.get_name(),
                "before": before,
            }
            if "NO_COLLISION" in before:
                item["status"] = "already_disabled"
            elif DRY:
                item["status"] = "would_disable"
            else:
                actor.modify()
                comp.modify()
                comp.set_collision_profile_name("NoCollision")
                comp.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
                after = str(comp.get_collision_enabled())
                item["after"] = after
                item["status"] = "disabled" if "NO_COLLISION" in after else "failed"
                if item["status"] == "disabled":
                    entry["changed"] += 1
                else:
                    report["failures"].append(
                        "%s/%s collision stayed %s" % (
                            map_path, actor.get_actor_label(), after))
            entry["matched"].append(item)

        if not DRY and entry["changed"]:
            level.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"]:
        raise RuntimeError("exterior collision:\n- " + "\n- ".join(report["failures"]))
    unreal.log("[exterior-collision] wrote %s" % OUT)
    return report


if __name__ == "__main__":
    main()
