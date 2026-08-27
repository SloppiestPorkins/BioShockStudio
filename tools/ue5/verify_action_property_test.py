"""ActionPropertyTest Label path EvaluateInWorld + If branch."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-property-test] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    prop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPropertyTest")
    if_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionIf")
    if not prop_cls or not if_cls:
        raise RuntimeError("missing PropertyTest/If")

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    # Place a throwaway actor with a known label.
    cube = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.StaticMeshActor.static_class(), unreal.Vector(0, 0, 0)
    )
    if cube is None:
        # Fallback: empty Actor
        cube = subsystem.spawn_actor_from_class(
            unreal.load_class(None, "/Script/Engine.Actor"),
            unreal.Vector(10, 10, 10),
            unreal.Rotator(0, 0, 0),
        )
    cube.set_actor_label("PropTestTarget")

    test = unreal.new_object(prop_cls)
    test.configure("PropTestTarget", "Label", "PropTestTarget", 2, -1)
    if not bool(test.evaluate_in_world(world)):
        f.append("equals Label should be true")
    report["equals"] = "ok"

    test.configure("PropTestTarget", "Label", "Other", 2, -1)
    if bool(test.evaluate_in_world(world)):
        f.append("mismatch Label should be false")
    report["mismatch"] = "ok"

    test.configure("PropTestTarget", "Label", "PropTestTarget", 3, -1)
    if bool(test.evaluate_in_world(world)):
        f.append("notequal same Label should be false")
    report["notequal"] = "ok"

    action_if = unreal.new_object(if_cls)
    ok_test = unreal.new_object(prop_cls)
    ok_test.configure("PropTestTarget", "Label", "PropTestTarget", 2, -1)
    action_if.add_test(ok_test)
    branch = str(action_if.choose_branch(world))
    if branch != "true":
        f.append("If branch %s != true" % branch)
    report["if_true"] = branch

    subsystem.destroy_actor(cube)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("property-test:\n- " + "\n- ".join(f))
    _log("PASS property test")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\action_property_test_report.json",
        )
    )
