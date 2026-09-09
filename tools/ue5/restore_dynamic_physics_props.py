"""Give the slice's loose props back their rigid-body physics.

BioShock's `PhysicalReactiveActor` / `HavokActor` / `PhysicalSteamerTrunk` archetypes (and the
`TrashCan` / `ashtray` / `debrisPile2` clutter that derive from them) all ship `Physics=1` and
`implements IAffectedByTelekinesis` — you kick them, shoot them, and Telekinesis grabs and
throws them. `import_level` places them as plain static `AStaticMeshActor`s, and the 8 Sept
"complex-as-simple on EVERYTHING" pass (`fix_all_complex_collision.py`) then *cleared* every
simple collision primitive they had — so nothing in the playable slice simulates rigid-body
physics except ragdoll corpses. That is the "props / thrown objects don't react" report.

This step (runs AFTER `fix_all_complex_collision` / `restore_floor_prop_hulls` /
`import_slice_animated_props`, so it has the last word on these specific meshes):

  1. Loads the slice, walks every `AStaticMeshActor`, reads its
     `BioShockKey=instance:<actorKey>:<asset>` tag and maps `actorKey -> className` from the
     level manifest.
  2. For an actor whose class is a physics-prop class (or whose mesh name matches the loose-
     clutter list), gives the *mesh asset* a single bounding-box simple-collision hull and
     `CTF_USE_SIMPLE_AND_COMPLEX` (a simulating body needs simple primitives; the editor Auto-
     Convex API does not run under `-run=pythonscript`, a box is stable and never tunnels), then
     flips the *component* to Movable + `PhysicsActor` + `SetSimulatePhysics(true)` with a
     size-based mass and light damping, asleep on spawn so it doesn't pop through the floor.
  3. `AShockGrabbableActor`'s `::Cast` fast-path in `UShockTelekinesisPlasmid::TraceGrabbable`
     isn't needed — the trace also accepts any actor with a simulating primitive.

Idempotent (`BioShockDynamicProp` tag). Env:
  BIOSHOCK_DYNPROP_MAPS      comma-separated maps (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_DYNPROP_MANIFEST  level manifest (default the slice export)
"""
from __future__ import annotations

import json
import os
import re
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_level  # noqa: E402

MAPS = [v.strip() for v in os.environ.get(
    "BIOSHOCK_DYNPROP_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if v.strip()]
MANIFEST = os.environ.get(
    "BIOSHOCK_DYNPROP_MANIFEST",
    r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/1-Medical.ue5-level.json")
OUT = os.path.join(os.environ.get("TEMP", "."), "restore_dynamic_physics_props.json")

_TAG = "BioShockDynamicProp"
_KEY_RE = re.compile(r"instance:([^:]+):")

# BioShock classes that are rigid-body + telekinesis-affected (Physics=1 in their .uc defaults).
# Match by CLASS only — the mesh names (decor_fridgedoor*, *_bottle, ...) are shared with
# ScriptableMover doors and AShockConsumablePickup bottles that must NOT simulate.
_PHYS_CLASSES = frozenset({
    "PhysicalReactiveActor", "HavokActor", "PhysicalSteamerTrunk",
    "PhysicalStaticMeshContainer", "PhysicalStaticMesh", "TrashCan", "ashtray", "debrisPile2",
})
# Big immovable heaps that must stay put even if a class rule catches them.
_REJECT_NAME = re.compile(r"(trash_?pile|diamondplate|pile_large|girderpile)", re.IGNORECASE)

# Meshes a looser earlier revision hulled that belong to ScriptableMover doors / pickups, not
# physics props — restore them to the slice-wide per-poly policy.
_RESTORE_MESH = re.compile(
    r"^(decor_fridgedoorsmall|single_wine_bottle|bottle_gin|beer_bottle)", re.IGNORECASE)


def _persisted_simulates(comp):
    """The saved intent (BodyInstance.bSimulatePhysics) — is_simulating_physics() is a runtime
    state that is always false in a freshly loaded editor map."""
    try:
        return bool(comp.get_editor_property("body_instance").get_editor_property("simulate_physics"))
    except Exception:  # noqa: BLE001
        return False


def _mass_for(largest_dim):
    if largest_dim < 25.0:
        return 0.5          # ashtray, bottle
    if largest_dim < 70.0:
        return 3.5          # trash can, debris chunk
    if largest_dim < 140.0:
        return 9.0          # fridge door, small trunk
    return 18.0             # steamer trunk, fridge bed


def _box_hull(mesh):
    """Replace the mesh asset's simple collision with one bounding box; simple+complex trace."""
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False, "no_body_setup"
    try:
        bounds = mesh.get_bounds()
        origin = bounds.origin
        ext = bounds.box_extent
    except Exception as exc:  # noqa: BLE001
        return False, "bounds: %s" % exc

    box = unreal.KBoxElem()
    for prop, val in (
        ("center", unreal.Vector(float(origin.x), float(origin.y), float(origin.z))),
        ("rotation", unreal.Rotator(0.0, 0.0, 0.0)),
        # KBoxElem X/Y/Z are full edge lengths. Shrink 8% so a resting prop does not spawn
        # interpenetrating the floor/shelf it sits on (that is what makes physics props "explode").
        ("x", max(2.0, float(ext.x) * 2.0 * 0.92)),
        ("y", max(2.0, float(ext.y) * 2.0 * 0.92)),
        ("z", max(2.0, float(ext.z) * 2.0 * 0.92)),
    ):
        try:
            box.set_editor_property(prop, val)
        except Exception:  # noqa: BLE001
            pass

    try:
        agg = body.get_editor_property("agg_geom")
        agg.set_editor_property("convex_elems", [])
        agg.set_editor_property("sphere_elems", [])
        agg.set_editor_property("sphyl_elems", [])
        agg.set_editor_property("box_elems", [box])
        body.set_editor_property("agg_geom", agg)
        body.set_editor_property(
            "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_SIMPLE_AND_COMPLEX)
    except Exception as exc:  # noqa: BLE001
        return False, "agg_geom: %s" % exc

    try:
        default = body.get_editor_property("default_instance")
        default.set_editor_property("collision_enabled", unreal.CollisionEnabled.QUERY_AND_PHYSICS)
        body.set_editor_property("default_instance", default)
    except Exception:  # noqa: BLE001
        pass

    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return True, "box"


def _restore_percpoly(mesh):
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False
    try:
        agg = body.get_editor_property("agg_geom")
        agg.set_editor_property("convex_elems", [])
        agg.set_editor_property("box_elems", [])
        agg.set_editor_property("sphere_elems", [])
        body.set_editor_property("agg_geom", agg)
        body.set_editor_property(
            "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
    except Exception:  # noqa: BLE001
        return False
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return True


def _simulate(actor, comp, mass):
    actor.modify()
    comp.modify()
    comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
    comp.set_collision_profile_name("PhysicsActor")
    comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
    comp.set_simulate_physics(True)
    comp.set_enable_gravity(True)
    try:
        comp.set_mass_override_in_kg(unreal.Name("None"), float(mass), True)
    except Exception:  # noqa: BLE001
        pass
    for setter, val in (("set_linear_damping", 0.06), ("set_angular_damping", 0.25)):
        try:
            getattr(comp, setter)(val)
        except Exception:  # noqa: BLE001
            pass
    # Persist the intent on the saved BodyInstance (set_simulate_physics alone is a runtime call
    # that a commandlet does not always serialise). Also asleep on spawn so a resting prop does
    # not pop through the floor it interpenetrates by a hair.
    try:
        bi = comp.get_editor_property("body_instance")
        bi.set_editor_property("simulate_physics", True)
        bi.set_editor_property("start_awake", False)
        for prop, val in (("linear_damping", 0.06), ("angular_damping", 0.25),
                          ("mass_scale", 1.0)):
            try:
                bi.set_editor_property(prop, val)
            except Exception:  # noqa: BLE001
                pass
        comp.set_editor_property("body_instance", bi)
    except Exception:  # noqa: BLE001
        pass
    if _TAG not in {str(t) for t in actor.tags}:
        actor.tags = list(actor.tags) + [unreal.Name(_TAG)]


def _wanted(class_name, mesh_name):
    if _REJECT_NAME.search(mesh_name or ""):
        return False
    return class_name in _PHYS_CLASSES


def _run_map(map_path, actor_classes, report):
    entry = {"map": map_path, "converted": [], "skipped": 0, "meshHulls": {}}
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        entry["error"] = "could not load"
        report["maps"].append(entry)
        return

    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    hulled = {}
    for actor in actors.get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        comp = actor.static_mesh_component
        mesh = comp.get_editor_property("static_mesh") if comp else None
        if mesh is None:
            continue

        if _RESTORE_MESH.match(mesh.get_name()):
            if _restore_percpoly(mesh):
                entry.setdefault("meshRestored", []).append(mesh.get_name())

        actor_key = None
        for tag in actor.tags:
            m = _KEY_RE.search(str(tag))
            if m:
                actor_key = m.group(1)
                break
        class_name = actor_classes.get(actor_key, "") if actor_key else ""
        mesh_name = mesh.get_name()
        tagged = _TAG in {str(t) for t in actor.tags}
        if not _wanted(class_name, mesh_name):
            if tagged:
                # A looser earlier run tagged this (ScriptableMover door, bottle pickup, ...) —
                # put it back to a static blocker.
                actor.modify()
                comp.modify()
                comp.set_simulate_physics(False)
                comp.set_collision_profile_name("BlockAll")
                try:
                    bi = comp.get_editor_property("body_instance")
                    bi.set_editor_property("simulate_physics", False)
                    comp.set_editor_property("body_instance", bi)
                except Exception:  # noqa: BLE001
                    pass
                actor.tags = [t for t in actor.tags if str(t) != _TAG]
                entry.setdefault("reverted", []).append(actor.get_actor_label())
            continue
        if tagged and _persisted_simulates(comp):
            entry["skipped"] += 1
            continue

        if mesh_name not in hulled:
            ok, how = _box_hull(mesh)
            hulled[mesh_name] = ok
            entry["meshHulls"][mesh_name] = how
        if not hulled[mesh_name]:
            continue

        _, ext = actor.get_actor_bounds(False)
        largest = 2.0 * max(float(ext.x), float(ext.y), float(ext.z))
        _simulate(actor, comp, _mass_for(largest))
        entry["converted"].append(
            {"actor": actor.get_actor_label(), "class": class_name or "?",
             "mesh": mesh_name, "mass": _mass_for(largest)})

    level.save_current_level()
    report["maps"].append(entry)


def main():
    with open(MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    actor_classes = import_level._manifest_actor_classes(manifest)

    report = {"manifest": MANIFEST, "maps": []}
    for map_path in MAPS:
        _run_map(map_path, actor_classes, report)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    total = sum(len(m.get("converted", [])) for m in report["maps"])
    unreal.log("[dynamic-physics-props] %s" % json.dumps(
        {m["map"]: len(m.get("converted", [])) for m in report["maps"]}))
    unreal.log("Success - %d prop(s) now simulate physics" % total)
    return report


if __name__ == "__main__":
    main()
