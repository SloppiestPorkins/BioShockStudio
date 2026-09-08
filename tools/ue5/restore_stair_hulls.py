"""Regenerate a walkable convex hull for stair / ramp meshes and set CTF_USE_DEFAULT.

fix_all_complex_collision.py forces every prop to per-poly collision. Stairs are the one
exception: per-poly on a staircase catches the character-movement capsule on every riser and
the player cannot climb (verified — the Medical Pavilion sign stairs go un-climbable). A single
auto-generated convex hull is a smooth walkable wedge instead.

UE5.7's headless collision-generation APIs produce nothing, BUT re-importing the mesh's OBJ
regenerates the single hull and keeps material-slot assignments (matched by name). This
re-imports every stair/ramp mesh placed in the slice and clears the trace flag back to DEFAULT.

Env:
  BIOSHOCK_STAIR_MAPS     comma-separated maps (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_STAIR_OBJ_DIR  OBJ export dir (default the slice 1-Medical Meshes export)
"""
from __future__ import annotations

import json
import os
import re

import unreal

MAPS = [v.strip() for v in os.environ.get(
    "BIOSHOCK_STAIR_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if v.strip()]
OBJ_DIRS = [
    os.environ.get(
        "BIOSHOCK_STAIR_OBJ_DIR",
        r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/Meshes"),
    r"C:/Users/Jack/Documents/BioShockUE5/Exports/1-Medical/1-Medical/Meshes",
]
MESH_DEST = "/Game/BioShockSlice/Content/Meshes"
OUT = os.path.join(os.environ.get("TEMP", "."), "restore_stair_hulls.json")
_STAIR = re.compile(r"(stairs?|ramp|broken_stairs)", re.IGNORECASE)


def _obj_for(stem):
    for base in OBJ_DIRS:
        path = os.path.join(base, stem + ".obj")
        if os.path.isfile(path):
            return path
    return None


def _reimport(stem):
    obj = _obj_for(stem)
    if obj is None:
        return "no_obj"
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", obj)
    task.set_editor_property("destination_path", MESH_DEST)
    task.set_editor_property("destination_name", stem)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", True)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    mesh = next((o for o in task.get_objects() if isinstance(o, unreal.StaticMesh)), None)
    mesh = mesh or unreal.EditorAssetLibrary.load_asset("%s/%s" % (MESH_DEST, stem))
    if mesh is None:
        return "import_failed"
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return "no_body"
    body.set_editor_property(
        "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_DEFAULT)
    agg = body.get_editor_property("agg_geom")
    hulls = len(agg.get_editor_property("convex_elems") or []) + \
        len(agg.get_editor_property("box_elems") or [])
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return "ok:%d" % hulls


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    result = {"maps": [], "reimport": {}}

    stems = set()
    for map_path in MAPS:
        entry = {"map": map_path, "actorsEnabled": 0}
        if not level.load_level(map_path):
            entry["error"] = "could not load"
            result["maps"].append(entry)
            continue
        for actor in actors.get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None or not _STAIR.search(mesh.get_name()):
                continue
            stems.add(mesh.get_name())
            comp.set_collision_profile_name("BlockAll")
            comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
            entry["actorsEnabled"] += 1

        for stem in sorted(stems):
            if stem not in result["reimport"]:
                result["reimport"][stem] = _reimport(stem)

        level.save_current_level()
        result["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    unreal.log("[stair-hulls] %s" % json.dumps(result))
    return result


if __name__ == "__main__":
    main()
