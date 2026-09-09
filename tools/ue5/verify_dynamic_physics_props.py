"""Headless verify: the slice's loose props simulate rigid-body physics with simple collision.

Asserts, on /Game/BioShockSlice/1-Medical:
  * at least MIN_PROPS StaticMeshActors are simulating physics and carry the BioShockDynamicProp
    tag (Telekinesis / kick / bullet reactive);
  * each such prop's mesh asset has >=1 simple collision primitive and is NOT
    CTF_USE_COMPLEX_AS_SIMPLE (a simulating body with only per-poly collision falls through the
    world / refuses to simulate in Chaos);
  * the big immovable heaps (Trash_Pile) are still static.
"""
import json
import os

import unreal

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "dynamic_physics_props_report.json"))
MIN_PROPS = int(os.environ.get("BIOSHOCK_DYNPROP_MIN", "20"))
_TAG = "BioShockDynamicProp"
_COMPLEX = unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE


def _persisted_simulates(comp):
    try:
        return bool(comp.get_editor_property("body_instance").get_editor_property("simulate_physics"))
    except Exception:  # noqa: BLE001
        return False


def _prims(mesh):
    body = mesh.get_editor_property("body_setup") if mesh else None
    if body is None:
        return 0, None
    agg = body.get_editor_property("agg_geom")
    n = (len(agg.get_editor_property("convex_elems") or [])
         + len(agg.get_editor_property("box_elems") or [])
         + len(agg.get_editor_property("sphere_elems") or [])
         + len(agg.get_editor_property("sphyl_elems") or []))
    return n, body.get_editor_property("collision_trace_flag")


def main(out=OUT):
    report = {"failures": [], "props": 0, "meshes": {}, "staticHeaps": 0}
    failures = report["failures"]
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not lvl.load_level("/Game/BioShockSlice/1-Medical"):
        failures.append("could not load slice")
        raise RuntimeError("dynamic_physics_props:\n- " + "\n- ".join(failures))

    acts = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for a in acts:
        if not isinstance(a, unreal.StaticMeshActor):
            continue
        comp = a.static_mesh_component
        mesh = comp.get_editor_property("static_mesh") if comp else None
        if mesh is None:
            continue
        name = mesh.get_name()
        tagged = _TAG in {str(t) for t in a.tags}
        if tagged:
            report["props"] += 1
            if not _persisted_simulates(comp):
                failures.append("%s tagged dynamic but not simulating" % a.get_actor_label())
            n, flag = _prims(mesh)
            report["meshes"][name] = n
            if n < 1:
                failures.append("%s mesh %s has no simple collision primitive" % (
                    a.get_actor_label(), name))
            if flag == _COMPLEX:
                failures.append("%s mesh %s still CTF_USE_COMPLEX_AS_SIMPLE" % (
                    a.get_actor_label(), name))
        elif "trash_pile" in name.lower():
            report["staticHeaps"] += 1
            if _persisted_simulates(comp):
                failures.append("Trash_Pile %s should stay static" % a.get_actor_label())

    if report["props"] < MIN_PROPS:
        failures.append("only %d dynamic props, want >= %d" % (report["props"], MIN_PROPS))

    report["dynamic_physics_props"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("dynamic_physics_props:\n- " + "\n- ".join(failures))
    unreal.log("Success - %d dynamic props, %d static heaps" % (
        report["props"], report["staticHeaps"]))
    return report


if __name__ == "__main__":
    main()
