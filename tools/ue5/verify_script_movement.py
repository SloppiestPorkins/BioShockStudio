"""Runner PostMovementGoal, WaitForGoal, sequence, input, pressure, facts, LOD, debug, console, force-move."""

import json
import os

import unreal


def _flag(value):
    return bool(value() if callable(value) else value)


def _log(m):
    unreal.log("[bioshock-script-movement] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
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
    lod_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetAINormalLODOverrideTime"
    )
    debug_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDisplayOnScreenDebugMessage"
    )
    console_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionRunConsoleCommand"
    )
    assert_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssertFact")
    move_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionForcePlayerMove")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("MovementScript", "")
    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(0, 0, 100), unreal.Rotator(0, 0, 0)
    )
    ai = subsystem.spawn_actor_from_class(
        ai_cls, unreal.Vector(120, 0, 50), unreal.Rotator(0, 0, 0)
    )
    ai.set_actor_label("SplicerA")
    ai.configure_identity("ThuggishSplicer", "SplicerA")
    goal_marker = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(400, 25, 80), unreal.Rotator(0, 0, 0)
    )
    goal_marker.set_actor_label("GoalMarker")
    move_marker = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(300, 0, 50), unreal.Rotator(0, 0, 0)
    )
    move_marker.set_actor_label("MoveMarker")

    post = unreal.new_object(post_cls)
    post.configure("SplicerA", "GoalMarker", "MoveToPoint", 40, True)
    concept = unreal.new_object(concept_cls)
    concept.configure("Concept_Hack", False)
    seq = unreal.new_object(seq_cls)
    seq.configure("MedicalRAM", 1)
    wait_goal = unreal.new_object(wait_cls)
    wait_goal.configure("SplicerA", "MoveToPoint", 5.0)
    input_ctx = unreal.new_object(input_cls)
    input_ctx.configure("Cinematic", True)
    pressure = unreal.new_object(pressure_cls)
    pressure.configure("Region_A", 1)
    lod = unreal.new_object(lod_cls)
    lod.configure("SplicerA", 5.0)
    debug = unreal.new_object(debug_cls)
    debug.configure("hello debug")
    console = unreal.new_object(console_cls)
    console.configure("stat fps")
    assert_f = unreal.new_object(assert_cls)
    assert_f.configure("Quest", "FindKey", "true")
    force_move = unreal.new_object(move_cls)
    force_move.configure("MoveMarker", "", 2.0, 100.0, 45.0)

    runner = script.get_runner()
    for action in (
        post,
        concept,
        seq,
        wait_goal,
        input_ctx,
        pressure,
        lod,
        debug,
        console,
        assert_f,
        force_move,
    ):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
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
    if str(wait_goal.get_last_goal_name()) != "MoveToPoint":
        f.append("wait goal %s" % wait_goal.get_last_goal_name())
    if not _flag(wait_goal.get_last_satisfied):
        f.append("wait goal not satisfied")
    if str(input_ctx.get_last_context()) != "Cinematic":
        f.append("input %s" % input_ctx.get_last_context())
    if not bool(input_ctx.get_unset()):
        f.append("input unset")
    if str(pressure.get_last_region_name()) != "Region_A":
        f.append("pressure %s" % pressure.get_last_region_name())
    if int(pressure.get_desired_pressure()) != 1:
        f.append("pressure level %s" % pressure.get_desired_pressure())
    if str(lod.get_last_ai_label()) != "SplicerA":
        f.append("lod %s" % lod.get_last_ai_label())
    if str(debug.get_last_message()) != "hello debug":
        f.append("debug %s" % debug.get_last_message())
    if not _flag(debug.get_last_displayed):
        f.append("debug not displayed")
    if str(console.get_last_command()) != "stat fps":
        f.append("console %s" % console.get_last_command())
    if str(assert_f.get_last_slot1()) != "Quest":
        f.append("assert %s" % assert_f.get_last_slot1())
    if str(force_move.get_last_marker_label()) != "MoveMarker":
        f.append("move %s" % force_move.get_last_marker_label())

    if player is None:
        f.append("no ShockPlayer")
    else:
        if bool(player.is_concept_enabled("Concept_Hack")):
            f.append("in-world concept still on")
        if int(player.get_scripted_sequence_run_now("MedicalRAM")) != 1:
            f.append("in-world seq %s" % player.get_scripted_sequence_run_now("MedicalRAM"))
        if str(player.get_last_input_context()) != "Cinematic":
            f.append("in-world input %s" % player.get_last_input_context())
        if int(player.get_region_pressure("Region_A")) != 1:
            f.append("in-world pressure %s" % player.get_region_pressure("Region_A"))
        if not bool(player.has_fact("Quest", "FindKey", "true")):
            f.append("in-world fact missing")
        loc = player.get_actor_location()
        if abs(float(loc.x) - 300.0) > 1.0:
            f.append("in-world player loc %s" % loc)

    if ai is None:
        f.append("no BaseShockAI")
    else:
        if str(ai.get_movement_goal_name()) != "MoveToPoint":
            f.append("in-world goal name %s" % ai.get_movement_goal_name())
        if not _flag(ai.is_wait_for_goal_satisfied):
            f.append("in-world wait not satisfied")
        lod_time = ai.get_lod_override_time()
        lod_val = lod_time() if callable(lod_time) else lod_time
        if abs(float(lod_val) - 5.0) > 0.01:
            f.append("in-world lod %s" % lod_val)

    report["console_executed"] = _flag(console.get_last_executed)
    report["movement"] = "ok" if not f else "fail"

    for actor in (script, player, ai, goal_marker, move_marker):
        if actor:
            subsystem.destroy_actor(actor)

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
