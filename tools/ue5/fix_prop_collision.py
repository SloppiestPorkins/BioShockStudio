"""Apply the playable-slice collision policy directly to visible render meshes.

Policy:
* exterior/backdrop and pickup meshes: component NoCollision;
* stairs and ramps: use their imported simple convex hull (a walkable wedge);
* known concave/hollow props and walk-through tubes: complex-as-simple;
* selected lightweight clutter: retain its simple hull and simulate as a PhysicsActor;
* other tiny/low-detail or semantically simple props: retain their cheap simple hull;
* remaining props: retain simple collision until classified.

This script never spawns invisible collision proxies and never changes component mobility.
Existing hulls can be selected headlessly. Missing hulls require one full-editor execution:
  UnrealEditor.exe <project> -ExecutePythonScript="<absolute path to this script>" -unattended
The editor-only Auto Convex API then creates one hull and the process exits when the script ends.
The commandlet API and headless OBJ re-import both report temporary geometry that is absent after
restart on UE5.7, so a headless run fails honestly when the editor pass has not been performed.

Env:
  BIOSHOCK_PROP_MAPS        comma-separated maps (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_PROP_DRY         "1" to classify only
  BIOSHOCK_PROP_MIN_SIZE    simple-prop cutoff in uu (default 80)
"""
from __future__ import annotations

import json
import os
import re
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fix_exterior_collision import is_exterior_name

MAPS = [value.strip() for value in os.environ.get(
    "BIOSHOCK_PROP_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if value.strip()]
DRY = os.environ.get("BIOSHOCK_PROP_DRY", "0") == "1"
MIN_SIZE = float(os.environ.get("BIOSHOCK_PROP_MIN_SIZE", "80"))
ONLY = os.environ.get("BIOSHOCK_PROP_ONLY", "").strip().lower()
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_prop_collision.json")

_PICKUP = re.compile(r"(?:^|_)(?:ammo|pickup|hypo|firstaid|medkit)(?:_|$)", re.IGNORECASE)
_SURFACE = re.compile(r"(puddle|bloodsplat|carpet|decal|drip)", re.IGNORECASE)
_STAIR_RAMP = re.compile(r"(stairs?|ramp|broken_stairs)", re.IGNORECASE)
_STAIR_NON_TREAD = re.compile(r"(railing|stairwater|sign_(?:up|down)stairs)", re.IGNORECASE)
_ARCHITECTURE = re.compile(
    r"(tunnel|corridor|doorway|hallway|loadroom|walkway|catwalk|bridge|"
    r"platform|passage|archway|concretewall.*hole)",
    re.IGNORECASE,
)
_DETAILED = re.compile(
    r"(cabinet|shelv|couch|sink|pipe|fridge|casket|wall.*hole|tile.*pile|debrispile|railing)",
    re.IGNORECASE,
)
_SIMPLE = re.compile(
    r"(bottle|can(?:_|$)|cup|plate|tile|brick|book|ashtray|coin|shell|bullet|"
    r"cigarette|plank|board|paper|debris_small)",
    re.IGNORECASE,
)
_DYNAMIC = re.compile(
    r"(bottle|(?:^|_)can(?:_|$)|(?:^|_)cup(?:_|$)|(?:^|_)plate(?:_|$)|"
    r"ashtray|serving_?tray|food_?tray|debris_small|(?:^|_)brick(?:_|$)|"
    r"wood(?:en)?chair|chair_wood|trash_?can)",
    re.IGNORECASE,
)
_DYNAMIC_REJECT = re.compile(r"(diamondplate|trash_?pile)", re.IGNORECASE)
_DYNAMIC_TAG = "BioShockDynamicProp"
_MODEL_ASSET = re.compile(r"^Model\d+_\d+$")
_PROXY_TAG = "BioShockPropCollisionProxy"


def _primitive_counts(mesh):
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return 0, 0, 0
    agg = body.get_editor_property("agg_geom")
    return (
        len(agg.get_editor_property("convex_elems") or []),
        len(agg.get_editor_property("box_elems") or []),
        len(agg.get_editor_property("sphere_elems") or []),
    )


def _disable_collision(actor, comp):
    actor.modify()
    comp.modify()
    comp.set_collision_profile_name("NoCollision")
    comp.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)


def _enable_visible_collision(actor, comp):
    actor.modify()
    comp.modify()
    comp.set_collision_profile_name("BlockAll")
    comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)


def _enable_lightweight_physics(actor, comp, mesh, largest):
    actor.modify()
    comp.modify()
    if _DYNAMIC_TAG not in {str(tag) for tag in actor.tags}:
        actor.tags = list(actor.tags) + [unreal.Name(_DYNAMIC_TAG)]
    _set_trace_flag(mesh, unreal.CollisionTraceFlag.CTF_USE_SIMPLE_AND_COMPLEX)
    comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
    comp.set_collision_profile_name("PhysicsActor")
    comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
    comp.set_simulate_physics(True)
    comp.set_enable_gravity(True)
    # Small loose clutter should move from a kick or bullet without behaving like polystyrene.
    mass = 0.35 if largest < 35.0 else (1.5 if largest < 90.0 else 4.0)
    comp.set_mass_override_in_kg(unreal.Name("None"), mass, True)
    comp.wake_all_rigid_bodies()
    return mass


def _set_trace_flag(mesh, flag):
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False
    mesh.modify()
    body.modify()
    body.set_editor_property("collision_trace_flag", flag)
    return True


def _generate_editor_hull(mesh):
    """Invoke the same VHACD path as Static Mesh Editor > Auto Convex Collision."""
    command_line = unreal.SystemLibrary.get_command_line().lower()
    if "-run=pythonscript" in command_line:
        return "missing hull requires the documented full-editor pass"
    try:
        subsystem = unreal.get_editor_subsystem(unreal.StaticMeshEditorSubsystem)
        ok = subsystem.set_convex_decomposition_collisions(mesh, 1, 16, 100000)
    except Exception as exc:  # noqa: BLE001
        return "editor Auto Convex failed: %s" % exc
    if not ok or sum(_primitive_counts(mesh)) <= 0:
        return "editor Auto Convex generated zero simple primitives"
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return None


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    report = {"dryRun": DRY, "maps": [], "failures": []}

    for map_path in MAPS:
        entry = {"map": map_path, "actors": [], "counts": {}}
        if not level.load_level(map_path):
            entry["error"] = "could not load"
            report["failures"].append("could not load %s" % map_path)
            report["maps"].append(entry)
            continue

        level_actors = list(actors.get_all_level_actors())
        dirty = False
        for actor in list(level_actors):
            if _PROXY_TAG in {str(tag) for tag in actor.tags}:
                if not DRY:
                    actors.destroy_actor(actor)
                    dirty = True
                entry["counts"]["stale_proxies_destroyed"] = \
                    entry["counts"].get("stale_proxies_destroyed", 0) + 1
        source_actors = []
        for actor in level_actors:
            if not isinstance(actor, unreal.StaticMeshActor) \
                    or _PROXY_TAG in {str(tag) for tag in actor.tags}:
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            _, extent = actor.get_actor_bounds(False)
            largest = 2.0 * max(extent.x, extent.y, extent.z)
            source_actors.append((actor, comp, mesh, largest))

        processed_meshes = set()
        for actor, comp, mesh, largest in source_actors:
            name = mesh.get_name()
            if ONLY and name.lower() != ONLY:
                continue
            if (actor.get_actor_label() or "").strip().lower() == "compiled world" \
                    or _MODEL_ASSET.match(name):
                continue

            try:
                triangles = mesh.get_num_triangles(0)
            except Exception:  # noqa: BLE001
                triangles = 0
            convex, boxes, spheres = _primitive_counts(mesh)
            bounds_origin, bounds_extent = actor.get_actor_bounds(False)
            item = {
                "actor": actor.get_actor_label(), "mesh": name, "largestDim": largest,
                "triangles": triangles, "convexBefore": convex,
                "boxesBefore": boxes, "spheresBefore": spheres,
                "location": [actor.get_actor_location().x, actor.get_actor_location().y,
                             actor.get_actor_location().z],
                "boundsOrigin": [bounds_origin.x, bounds_origin.y, bounds_origin.z],
                "extent": [bounds_extent.x, bounds_extent.y, bounds_extent.z],
            }

            if _DYNAMIC_REJECT.search(name) and comp.is_simulating_physics():
                policy = "restore_non_dynamic"
                if not DRY:
                    comp.set_simulate_physics(False)
                    comp.set_collision_profile_name("BlockAll")
                    actor.tags = [tag for tag in actor.tags if str(tag) != _DYNAMIC_TAG]
                    dirty = True
            elif is_exterior_name(name) or _PICKUP.search(name) or _SURFACE.search(name):
                policy = "no_collision"
                before = str(comp.get_collision_enabled())
                if not DRY and "NO_COLLISION" not in before:
                    _disable_collision(actor, comp)
                    dirty = True
            elif _STAIR_RAMP.search(name) and not _STAIR_NON_TREAD.search(name):
                policy = "walkable_simple_hull"
                if convex + boxes + spheres <= 0 and not DRY and name not in processed_meshes:
                    error = _generate_editor_hull(mesh)
                    if error:
                        report["failures"].append("%s: %s" % (name, error))
                    else:
                        convex, boxes, spheres = _primitive_counts(mesh)
                        item["editorHullGenerated"] = True
                        item["convexAfterGeneration"] = convex
                if convex + boxes + spheres <= 0:
                    if name not in processed_meshes:
                        report["failures"].append(
                            "%s is stair/ramp geometry but has no imported simple hull" % name)
                elif not DRY and name not in processed_meshes:
                    if not _set_trace_flag(
                            mesh, unreal.CollisionTraceFlag.CTF_USE_SIMPLE_AND_COMPLEX):
                        report["failures"].append("%s has no body setup" % name)
                    else:
                        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                        dirty = True
                if not DRY and "NO_COLLISION" in str(comp.get_collision_enabled()):
                    _enable_visible_collision(actor, comp)
                    dirty = True
            elif _DETAILED.search(name) \
                    or (_ARCHITECTURE.search(name) and largest >= 200.0):
                policy = "visible_complex"
                if not DRY:
                    if name not in processed_meshes:
                        if not _set_trace_flag(
                                mesh, unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE):
                            report["failures"].append("%s has no body setup" % name)
                        else:
                            unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                            dirty = True
                    if "NO_COLLISION" in str(comp.get_collision_enabled()):
                        _enable_visible_collision(actor, comp)
                        dirty = True
            elif _DYNAMIC.search(name) and largest <= 220.0:
                if convex + boxes + spheres <= 0:
                    policy = "dynamic_missing_simple_hull"
                    report["failures"].append(
                        "%s matches lightweight clutter but has no simple collision" % name)
                else:
                    policy = "dynamic_lightweight"
                    if not DRY:
                        item["massKg"] = _enable_lightweight_physics(
                            actor, comp, mesh, largest)
                        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                        dirty = True
            elif largest < MIN_SIZE or triangles <= 24 or _SIMPLE.search(name):
                policy = "retain_simple"
            elif convex > 1:
                policy = "multi_convex_existing"
            else:
                policy = "retain_simple_unclassified"

            processed_meshes.add(name)
            item["policy"] = policy
            body = mesh.get_editor_property("body_setup")
            item["traceFlagAfter"] = str(
                body.get_editor_property("collision_trace_flag")) if body else None
            entry["counts"][policy] = entry["counts"].get(policy, 0) + 1
            entry["actors"].append(item)

        if not DRY and dirty:
            level.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"]:
        raise RuntimeError("prop collision:\n- " + "\n- ".join(report["failures"][:20]))
    unreal.log("[prop-collision] wrote %s" % OUT)
    return report


if __name__ == "__main__":
    main()
