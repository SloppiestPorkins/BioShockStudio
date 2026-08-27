"""Runner PostMovementGoal, Concept, ScriptedSequence, WaitForGoal, InputContext, ChangePressure."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-movement] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    post_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPostMovementGoal")
    concept_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDisableOrEnableConcept"
    )
    seq_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionControlScriptedSequence"
    )
    wait_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWaitForGoal")
    input_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetOrUnsetInputContext"
    )
    pressure_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangePressure")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("MovementScript", "")

    post = unreal.new_object(post_cls)
    post.configure("SplicerA", "GoalMarker", "MoveToPoint", 40, True)
    concept = unreal.new_object(concept_cls)
    concept.configure("Concept_Hack", False)
    seq = unreal.new_object(seq_cls)
    seq.configure("MedicalRAM", 1)
    wait_goal = unreal.new_object(wait_cls)
    wait_goal.configure("SplicerA", "MovementGoal", 5.0)
    input_ctx = unreal.new_object(input_cls)
    input_ctx.configure("Cinematic", True)
    pressure = unreal.new_object(pressure_cls)
    pressure.configure("Region_A", 1)

    runner = script.get_runner()
    for action in (post, concept, seq, wait_goal, input_ctx, pressure):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(6):
        runner.tick_execution(0.0)

    if str(post.get_last_target_label()) != "SplicerA":
        f.append("post target %s" % post.get_last_target_label())
    if str(post.get_last_destination_label()) != "GoalMarker":
        f.append("post dest %s" % post.get_last_destination_label())
    if str(concept.get_last_concept_name()) != "Concept_Hack":
        f.append("concept %s" % concept.get_last_concept_name())
    if bool(concept.get_last_enable()):
        f.append("concept enable")
    if str(seq.get_last_target_label()) != "MedicalRAM":
        f.append("seq %s" % seq.get_last_target_label())
    if int(seq.get_last_run_now()) != 1:
        f.append("seq run %s" % seq.get_last_run_now())
    if str(wait_goal.get_last_goal_name()) != "MovementGoal":
        f.append("wait goal %s" % wait_goal.get_last_goal_name())
    if str(input_ctx.get_last_context()) != "Cinematic":
        f.append("input %s" % input_ctx.get_last_context())
    if not bool(input_ctx.get_unset()):
        f.append("input unset")
    if str(pressure.get_last_region_name()) != "Region_A":
        f.append("pressure %s" % pressure.get_last_region_name())
    if int(pressure.get_desired_pressure()) != 1:
        f.append("pressure level %s" % pressure.get_desired_pressure())
    report["movement"] = "ok"

    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("movement:\n- " + "\n- ".join(f))
    _log("PASS movement")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_movement_report.json",
        )
    )
