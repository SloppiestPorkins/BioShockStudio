"""Give floor-type prop meshes a walkable convex hull, not per-poly.

`CTF_USE_COMPLEX_AS_SIMPLE` on a Movable mesh does not register with CharacterMovement's
`FindFloor` capsule sweep in Chaos (h11) — an AI or the player standing on a per-poly prop
FLOOR (catwalk, deck, platform, grate, stair, CWS platform, light-floor) falls straight
through it. The compiled-world BSP shell is Static so it is unaffected; this is only the
props the level uses as walkable surfaces.

Re-importing the OBJ regenerates the single auto convex hull (a walkable wedge) and keeps the
material slots (matched by name). Every other prop keeps whatever fix_all_complex_collision
gave it — you can walk through a couch, but you never fall through the ground.

Env:
  BIOSHOCK_FLOORPROP_MAPS  comma-separated maps (default /Game/BioShockSlice/1-Medical)
"""
from __future__ import annotations

import json
import os
import re

import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fix_all_complex_collision import _KEEP_NO_COLLISION

MAPS = [v.strip() for v in os.environ.get(
    "BIOSHOCK_FLOORPROP_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if v.strip()]
OBJ_DIRS = [
    r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/Meshes",
    r"C:/Users/Jack/Documents/BioShockUE5/Exports/1-Medical/1-Medical/Meshes",
]
MESH_DEST = "/Game/BioShockSlice/Content/Meshes"
OUT = os.path.join(os.environ.get("TEMP", "."), "restore_floor_prop_hulls.json")

_FLOOR = re.compile(
    r"stairs?|ramp|broken_stairs"
    r"|catwalk|deck_|deckplate|diamondplate_panel|grate|grating"
    r"|platform|cws_platform|walkway|bridge_|gangway"
    r"|light_floor|floor_metal|metal_floor|floorpanel|floor_panel"
    r"|elevator_floor|lift_floor|tunnel_floor",
    re.IGNORECASE)


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
    # A staircase is one material; fill any WorldGridMaterial slot from the first real one.
    slots = list(mesh.get_editor_property("static_materials"))
    real = next((s.get_editor_property("material_interface") for s in slots
                 if s.get_editor_property("material_interface")
                 and "WorldGrid" not in s.get_editor_property("material_interface").get_name()),
                None)
    if real is not None:
        touched = False
        for s in slots:
            cur = s.get_editor_property("material_interface")
            if cur is None or "WorldGrid" in cur.get_name():
                s.set_editor_property("material_interface", real)
                touched = True
        if touched:
            mesh.set_editor_property("static_materials", slots)
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return "ok:%d" % hulls


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    result = {"reimport": {}, "maps": []}

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
            if mesh is None or not _FLOOR.search(mesh.get_name()):
                continue
            # A liquid FX sheet (FX_StairWater) matches _FLOOR via "stair" but is a cosmetic
            # overlay — leave it non-colliding.
            if _KEEP_NO_COLLISION.search(mesh.get_name()):
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
    unreal.log("[floor-prop-hulls] %s" % json.dumps(result))
    return result


if __name__ == "__main__":
    main()
