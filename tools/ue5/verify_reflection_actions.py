"""Headless verify for R2.1 — ActionSetProperty / ActionGetProperty / ActionPropertyTest reflection.

Spawns one throwaway StaticMeshActor far from real geometry and drives the three reflection
actions directly (no script graph needed — Configure + ApplyInWorld/EvaluateInWorld, same as
verify_script_*.py). Checks:
  (a) ActionSetProperty writes a plain actor-level float property (no dot);
  (b) ActionSetProperty writes a bool through one dotted component step
      ("StaticMeshComponent.bVisible") — the beyond-1:1 extension our component-based port needs;
  (c) ActionGetProperty reads a value back onto its ReturnValueText;
  (d) ActionPropertyTest compares a property and its result drives ActionIf's branch, and also
      lands on its own ReturnValueText (for a future param-resolution consumer, R1.1);
  (e) the CDO guard: ApplyToActor on a class default object is refused;
  (f) a missing property name fails cleanly (0 applied), not a crash.
"""
import json
import os

import unreal

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "reflection_actions_report.json"))

# Far from the slice's real geometry (same "off in a test corner" convention as
# ShockPhysicsLibrary's headless self-test).
TEST_LOCATION = unreal.Vector(-17320.0, 1272.0, 8600.0)


def _cls(name):
    c = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if c is None:
        raise RuntimeError("reflection_actions: class missing - %s" % name)
    return c


def main(out=OUT):
    report = {"failures": [], "checks": {}}
    failures = report["failures"]

    def check(name, ok, detail=None):
        report["checks"][name] = bool(ok)
        if not ok:
            failures.append("%s failed%s" % (name, (" (%r)" % (detail,)) if detail is not None else ""))

    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not lvl.load_level("/Game/BioShockSlice/1-Medical"):
        failures.append("could not load slice")
        raise RuntimeError("reflection_actions:\n- " + "\n- ".join(failures))

    world = unreal.EditorLevelLibrary.get_editor_world()

    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.StaticMeshActor.static_class(), TEST_LOCATION)
    if actor is None:
        failures.append("could not spawn test actor")
        raise RuntimeError("reflection_actions:\n- " + "\n- ".join(failures))
    actor.set_actor_label("ReflectionTestActor")
    mesh = unreal.load_asset("/Engine/BasicShapes/Cube.Cube")
    if mesh:
        actor.static_mesh_component.set_static_mesh(mesh)
    label = unreal.Name("ReflectionTestActor")

    try:
        # (a) plain actor-level float, no dot.
        set_cls = _cls("ShockActionSetProperty")
        sp = unreal.new_object(set_cls)
        sp.configure(label, unreal.Name("InitialLifeSpan"), "12.5")
        applied = sp.apply_in_world(world)
        life_span = actor.get_editor_property("initial_life_span")
        check("setproperty_scalar", applied == 1 and abs(float(life_span) - 12.5) < 0.01, life_span)

        # (b) dotted component step: StaticMeshComponent.bVisible.
        sp2 = unreal.new_object(set_cls)
        sp2.configure(label, unreal.Name("StaticMeshComponent.bVisible"), "False")
        applied2 = sp2.apply_in_world(world)
        visible = actor.static_mesh_component.get_editor_property("visible")
        check("setproperty_dotted_component", applied2 == 1 and visible is False, visible)
        # restore visibility so the test actor doesn't confuse other verifies scanning the level.
        sp2b = unreal.new_object(set_cls)
        sp2b.configure(label, unreal.Name("StaticMeshComponent.bVisible"), "True")
        sp2b.apply_in_world(world)

        # (c) GetProperty round-trip onto the typed UShockVariable return value (R1.1's carrier —
        # get_return_value() rather than a GetReturnValueText-style bool+out-param UFUNCTION,
        # which does not round-trip through the Python binding as a clean tuple).
        get_cls = _cls("ShockActionGetProperty")
        gp = unreal.new_object(get_cls)
        gp.configure(label, "InitialLifeSpan")
        got_ok = gp.apply_in_world(world)
        got_return = gp.get_return_value()
        ret_text = got_return.get_value() if got_return else None
        got_val = float(ret_text) if ret_text else -1.0
        check("getproperty_roundtrip", got_ok and got_return is not None and abs(got_val - 12.5) < 0.01, ret_text)

        # (d) PropertyTest -> ActionIf branch + its own return value.
        test_cls = _cls("ShockActionPropertyTest")
        pt = unreal.new_object(test_cls)
        pt.configure(label, "InitialLifeSpan", "12.5", 2, -1)  # OPTEST_EQUALS
        eval_ok = pt.evaluate_in_world(world)
        pt_return = pt.get_return_value()
        pt_ret_text = pt_return.get_value() if pt_return else None
        check("propertytest_equals", eval_ok is True and pt_ret_text == "True",
              (eval_ok, pt_ret_text))

        if_cls = _cls("ShockActionIf")
        if_action = unreal.new_object(if_cls)
        if_action.add_test(pt)
        branch = if_action.choose_branch(world)
        check("propertytest_drives_actionif", str(branch) == "true", branch)

        # (e) the CDO guard: ApplyToActor refuses a class default object.
        cdo = unreal.get_default_object(actor.get_class())
        sp3 = unreal.new_object(set_cls)
        sp3.configure(label, unreal.Name("InitialLifeSpan"), "999")
        cdo_ok = sp3.apply_to_actor(cdo)
        check("cdo_guard_rejects_write", cdo_ok is False, cdo_ok)

        # (f) a missing property name fails cleanly.
        sp4 = unreal.new_object(set_cls)
        sp4.configure(label, unreal.Name("ThisPropertyDoesNotExist"), "x")
        missing_applied = sp4.apply_in_world(world)
        check("missing_property_fails_clean", missing_applied == 0, missing_applied)
    finally:
        actors.destroy_actor(actor)

    report["reflection_actions"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("reflection_actions:\n- " + "\n- ".join(failures))
    unreal.log("Success - %d/%d checks passed" % (len(report["checks"]), len(report["checks"])))
    return report


if __name__ == "__main__":
    main()
