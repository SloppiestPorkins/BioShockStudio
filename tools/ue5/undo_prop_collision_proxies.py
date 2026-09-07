"""Replace v4's fix_prop_collision invisible-proxy scheme with per-poly collision on the
visible render mesh.

v4 spawned an invisible Static CTF_USE_COMPLEX_AS_SIMPLE proxy beside each proxied prop and
disabled collision on the render actor. Those proxies acted as invisible walls - the player hit
one at the top of the Medical Pavilion sign stairs. (A mis-placed / duplicated invisible collider
is a blocker with no visual cue; per-poly collision on the mesh you can actually see is not.)

This script, driven by TEMP/fix_prop_collision.json:
  * destroys every BioShockPropCollisionProxy actor;
  * sets CTF_USE_COMPLEX_AS_SIMPLE directly on each proxied mesh asset (works on Movable for
    query/sweep collision - the h11 "Static required" caveat is about the giant compiled-world
    shell and physics simulation, not prop query collision);
  * re-enables BlockAll / QueryAndPhysics on the render actors.

`no_collision`-policy meshes (exterior / pickups / flat surface FX) are left disabled - that part
of v4 was correct.

Prop-collision fidelity is being redone properly under tasks/v5-*; this is the safe interim.

Env:
  BIOSHOCK_PROP_MAPS    comma-separated maps (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_PROP_REPORT  fix_prop_collision.json (default TEMP/fix_prop_collision.json)
"""
from __future__ import annotations

import json
import os

import unreal

MAPS = [v.strip() for v in os.environ.get(
    "BIOSHOCK_PROP_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if v.strip()]
REPORT = os.environ.get(
    "BIOSHOCK_PROP_REPORT",
    os.path.join(os.environ.get("TEMP", "."), "fix_prop_collision.json"))
OUT = os.path.join(os.environ.get("TEMP", "."), "undo_prop_collision_proxies.json")
_PROXY_TAG = "BioShockPropCollisionProxy"


def main():
    with open(REPORT, "r", encoding="utf-8") as handle:
        report = json.load(handle)

    proxied = {
        actor["mesh"]
        for entry in report.get("maps", [])
        for actor in entry.get("actors", [])
        if actor.get("policy") == "static_complex_proxy" and actor.get("mesh")
    }

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    result = {"proxiedMeshes": len(proxied), "maps": []}

    for map_path in MAPS:
        entry = {"map": map_path, "proxiesDestroyed": 0, "rendersRestored": 0, "meshesComplex": 0}
        if not level.load_level(map_path):
            entry["error"] = "could not load"
            result["maps"].append(entry)
            continue

        done = set()
        for actor in list(actors.get_all_level_actors()):
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            if _PROXY_TAG in {str(t) for t in actor.tags}:
                actors.destroy_actor(actor)
                entry["proxiesDestroyed"] += 1
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None or mesh.get_name() not in proxied:
                continue
            comp.set_collision_profile_name("BlockAll")
            comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
            entry["rendersRestored"] += 1
            name = mesh.get_name()
            if name in done:
                continue
            done.add(name)
            body = mesh.get_editor_property("body_setup")
            if body is not None:
                body.set_editor_property(
                    "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
                unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                entry["meshesComplex"] += 1

        level.save_current_level()
        result["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    unreal.log("[undo-prop-proxies] %s" % json.dumps(result))
    return result


if __name__ == "__main__":
    main()
