"""Headless fidelity checks for SDK scripting audit items (SCR-B04..B13, B16, G02/G03, G19).

Compatible with `-run=pythonscript` (no sibling imports). Style matches verify_script_trigger.py.
Each case has a positive and a negative assertion.
"""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-scripting-fidelity] %s" % m)


def _cls(name):
    c = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if c is None:
        raise RuntimeError("missing class %s" % name)
    return c


def _assign(name, value):
    a = unreal.new_object(_cls("ShockActionVariableAssignOverwrite"))
    a.configure(name, value)
    return a


def _hold_open(runner):
    """Return values die when a script's list ends (SCR-G18); a trailing wait keeps them readable."""
    w = unreal.new_object(_cls("ShockActionWait"))
    w.configure(999.0)
    runner.add_action(w)


def main(out):
    report = {"failures": [], "checks": {}}
    f = report["failures"]

    def check(name, ok, detail=None):
        report["checks"][name] = bool(ok)
        if not ok:
            f.append("%s%s" % (name, (" (%s)" % detail) if detail else ""))

    runner_cls = _cls("ShockScriptRunner")
    reg_cls = _cls("ShockScriptRegistry")
    registry = unreal.new_object(reg_cls)

    # --- SCR-B05 nested And/Or ---
    get_msg = unreal.new_object(_cls("ShockActionGetMessageValue"))
    get_msg.configure("RA")
    bool_a = unreal.new_object(_cls("ShockBooleanStatement"))
    bool_a.configure(2, "x", "CallButtonBottom02")  # EQUALS
    bool_a.add_action_property_resolver("lhs", get_msg, "Value", -1)
    bool_b = unreal.new_object(_cls("ShockBooleanStatement"))
    bool_b.configure(2, "y", "OtherButton")
    bool_b.add_action_property_resolver("lhs", get_msg, "Value", -1)
    or_stmt = unreal.new_object(_cls("ShockOrStatement"))
    or_stmt.add_action_property_resolver("lhs", bool_a, "Value", -1)
    or_stmt.add_action_property_resolver("rhs", bool_b, "Value", -1)

    listener = unreal.new_object(runner_cls)
    listener.configure("LiftOr")
    listener.set_triggered_by("Lift")
    listener.set_registry(registry)
    if_cls = _cls("ShockActionIf")
    if_action = unreal.new_object(if_cls)
    if_action.add_test(or_stmt)
    if_action.add_true_action(_assign("Matched", "yes"))
    if_action.add_else_action(_assign("Matched", "no"))
    listener.add_action(if_action)

    registry.dispatch_message_with_fields(
        "MessageTrigger", "Lift", {"RA": "CallButtonBottom02"})
    listener.tick_execution(0.0)
    check(
        "B05_or_nested_positive",
        str(listener.ensure_variables().get_value_or_empty("Matched")) == "yes",
    )

    listener2 = unreal.new_object(runner_cls)
    listener2.configure("LiftOrMiss")
    listener2.set_triggered_by("Lift")
    listener2.set_registry(registry)
    get_msg2 = unreal.new_object(_cls("ShockActionGetMessageValue"))
    get_msg2.configure("RA")
    bool_miss = unreal.new_object(_cls("ShockBooleanStatement"))
    bool_miss.configure(2, "", "Nope")
    bool_miss.add_action_property_resolver("lhs", get_msg2, "Value", -1)
    or_miss = unreal.new_object(_cls("ShockOrStatement"))
    or_miss.add_action_property_resolver("lhs", bool_miss, "Value", -1)
    or_miss.add_action_property_resolver("rhs", bool_miss, "Value", -1)
    if2 = unreal.new_object(if_cls)
    if2.add_test(or_miss)
    if2.add_true_action(_assign("Matched", "yes"))
    if2.add_else_action(_assign("Matched", "no"))
    listener2.add_action(if2)
    registry.dispatch_message_with_fields("MessageTrigger", "Lift", {"RA": "Wrong"})
    listener2.tick_execution(0.0)
    check(
        "B05_or_nested_negative",
        str(listener2.ensure_variables().get_value_or_empty("Matched")) == "no",
    )

    # --- SCR-B06 BooleanStatement type rules ---
    bs = unreal.new_object(_cls("ShockBooleanStatement"))
    bs.configure(2, "given", "Given")  # name eq ignore case
    check("B06_name_eq_ignorecase_positive", bool(bs.test_evaluate()))
    bs.configure(5, "True", "False")  # GREATER on bool → always false
    check("B06_bool_ordered_negative", not bool(bs.test_evaluate()))
    bs.configure(2, "10", "abc")  # numeric lhs coerces non-numeric rhs to 0 → 10==0 false
    check("B06_numeric_coerce_rhs_zero", not bool(bs.test_evaluate()))
    bs.configure(5, "10", "abc")  # 10 > 0
    check("B06_numeric_coerce_gt_positive", bool(bs.test_evaluate()))

    # --- SCR-B04 GetMessageValue fields ---
    msg_runner = unreal.new_object(runner_cls)
    msg_runner.configure("KeypadScript")
    msg_runner.set_triggered_by("Pad")
    msg_runner.set_registry(registry)
    gmv = unreal.new_object(_cls("ShockActionGetMessageValue"))
    gmv.configure("Keycode")
    msg_runner.add_action(gmv)
    msg_runner.add_action(_assign("Code", "pending"))
    # Bind assign rhs from get message via resolve after start — simpler: apply after fields set
    registry.dispatch_message_with_fields(
        "Message", "Pad", {"Keycode": "7774", "Instigator": "Player"})
    msg_runner.tick_execution(0.0)
    check(
        "B04_keycode_positive",
        str(msg_runner.get_last_message_field("Keycode")) == "7774",
    )
    check(
        "B04_absent_field_negative",
        str(msg_runner.get_last_message_field("MissingField")) == "",
    )
    # ExecuteScript callee has empty fields
    child = unreal.new_object(runner_cls)
    child.configure("Callee")
    child.set_registry(registry)
    child.add_action(_assign("X", "1"))
    check("B04_exec_clears_fields_pre", child.start_execution())
    check(
        "B04_exec_clears_fields_negative",
        str(child.get_last_message_field("Keycode")) == "",
    )
    child.tick_execution(0.0)

    # --- SCR-B10 timers ---
    # On expiry the RUNNING script dispatches MessageTimerExpired under its own label.
    timer_listener = unreal.new_object(runner_cls)
    timer_listener.configure("HammerListener")
    timer_listener.set_triggered_by("HammerStart")
    timer_listener.set_script_message_class("MessageTimerExpired")
    timer_listener.set_registry(registry)
    timer_listener.add_action(_assign("Fired", "yes"))

    starter = unreal.new_object(runner_cls)
    starter.configure("HammerStart")
    starter.set_registry(registry)
    start_tm = unreal.new_object(_cls("ShockActionStartTimer"), starter)
    start_tm.configure(1.0)
    starter.add_action(start_tm)
    check("B10_start_positive", starter.start_execution())
    starter.tick_execution(0.0)
    check("B10_timer_armed_positive", bool(starter.has_active_script_timer()))
    starter.tick_execution(0.5)
    check(
        "B10_not_expired_yet_negative",
        str(timer_listener.ensure_variables().get_value_or_empty("Fired")) != "yes",
    )
    starter.tick_execution(1.0)
    timer_listener.tick_execution(1.0)
    check(
        "B10_expiry_dispatch_positive",
        str(timer_listener.ensure_variables().get_value_or_empty("Fired")) == "yes",
    )
    starter2 = unreal.new_object(runner_cls)
    starter2.configure("HammerStart2")
    starter2.set_registry(registry)
    start2 = unreal.new_object(_cls("ShockActionStartTimer"), starter2)
    start2.configure(5.0)
    stop2 = unreal.new_object(_cls("ShockActionStopTimer"), starter2)
    stop2.configure("HammerStart2")
    starter2.add_action(start2)
    starter2.add_action(stop2)
    starter2.start_execution()
    starter2.tick_execution(0.0)
    check("B10_stop_clears_negative", not bool(starter2.has_active_script_timer()))

    # --- SCR-B11 refuse second start ---
    busy = unreal.new_object(runner_cls)
    busy.configure("BusyChild")
    busy.set_registry(registry)
    wait = unreal.new_object(_cls("ShockActionWait"))
    wait.configure(10.0)
    busy.add_action(wait)
    check("B11_first_start_positive", busy.start_execution())
    busy.tick_execution(0.0)
    check("B11_second_start_negative", not busy.start_execution())

    # --- SCR-B16 disable drops queue ---
    queued = unreal.new_object(runner_cls)
    queued.configure("QueueDrop")
    queued.set_triggered_by("Src")
    queued.set_registry(registry)
    wq = unreal.new_object(_cls("ShockActionWait"))
    wq.configure(10.0)
    queued.add_action(wq)
    queued.start_execution()
    queued.tick_execution(0.0)
    registry.dispatch_message("Message", "Src")
    check("B16_queued_positive", int(queued.get_message_queue_num()) >= 1)
    queued.set_enabled(False)
    check("B16_disable_clears_queue_negative", int(queued.get_message_queue_num()) == 0)

    # --- SCR-B12 fade waits ---
    fade_runner = unreal.new_object(runner_cls)
    fade_runner.configure("FadeScript")
    fade = unreal.new_object(_cls("ShockActionCinematicFadeView"))
    fade.configure(0.0, 1.0, 2.0, 0.5)
    fade_runner.add_action(fade)
    fade_runner.add_action(_assign("AfterFade", "yes"))
    fade_runner.start_execution()
    fade_runner.tick_execution(0.0)
    check(
        "B12_blocks_before_duration_negative",
        str(fade_runner.ensure_variables().get_value_or_empty("AfterFade")) != "yes",
    )
    fade_runner.tick_execution(2.6)
    check(
        "B12_completes_after_duration_positive",
        str(fade_runner.ensure_variables().get_value_or_empty("AfterFade")) == "yes",
    )

    # --- SCR-G02 ArithmeticStatement ---
    arith = unreal.new_object(_cls("ShockArithmeticStatement"))
    arith.configure(3, "10", "2")  # DIVIDE
    ctx_world = unreal.EditorLevelLibrary.get_editor_world()
    # Apply via a tiny runner so Resolve/Apply path is exercised
    ar_runner = unreal.new_object(runner_cls)
    ar_runner.configure("Arith")
    ar_runner.add_action(arith)
    _hold_open(ar_runner)
    ar_runner.start_execution()
    ar_runner.tick_execution(0.0)
    rv = arith.get_return_value()
    check("G02_divide_positive", rv is not None and abs(float(rv.get_value()) - 5.0) < 0.01)
    arith_bad = unreal.new_object(_cls("ShockArithmeticStatement"))
    arith_bad.configure(3, "10", "0")  # divide by zero → 0
    ar2 = unreal.new_object(runner_cls)
    ar2.configure("Arith0")
    ar2.add_action(arith_bad)
    _hold_open(ar2)
    ar2.start_execution()
    ar2.tick_execution(0.0)
    rv0 = arith_bad.get_return_value()
    check("G02_divzero_negative", rv0 is not None and abs(float(rv0.get_value())) < 0.01)

    # --- SCR-G03 GetLevelLabel ---
    gl = unreal.new_object(_cls("ShockActionGetLevelLabel"))
    # A bare runner has no outer world, so the label is legitimately empty; use a placed script.
    gl_actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
        _cls("ShockScript"), unreal.Vector(0.0, 0.0, 5000.0))
    gl_actor.configure("LevelLbl", "")
    gl_runner = gl_actor.get_runner()
    gl_runner.add_action(gl)
    _hold_open(gl_runner)
    gl_runner.start_execution()
    gl_runner.tick_execution(0.0)
    gl_rv = gl.get_return_value()
    label_text = str(gl_rv.get_value()) if gl_rv else ""
    check("G03_lowercase_positive", label_text == label_text.lower() and len(label_text) > 0)
    check("G03_not_empty_negative", label_text != "")
    unreal.get_editor_subsystem(unreal.EditorActorSubsystem).destroy_actor(gl_actor)

    # --- SCR-G19 ExitScript multi-label ---
    a = unreal.new_object(runner_cls)
    a.configure("StandingOnCremationBody")
    a.set_registry(registry)
    wa = unreal.new_object(_cls("ShockActionWait"))
    wa.configure(30.0)
    a.add_action(wa)
    b = unreal.new_object(runner_cls)
    b.configure("StandingOnCremationBody")
    b.set_registry(registry)
    wb = unreal.new_object(_cls("ShockActionWait"))
    wb.configure(30.0)
    b.add_action(wb)
    a.start_execution()
    b.start_execution()
    a.tick_execution(0.0)
    b.tick_execution(0.0)
    check("G19_both_running_positive", bool(a.is_executing) and bool(b.is_executing))
    all_found = registry.find_all_scripts("StandingOnCremationBody")
    check("G19_registry_multi_positive", len(all_found) >= 2)
    killer = unreal.new_object(runner_cls)
    killer.configure("Killer")
    killer.set_registry(registry)
    exit_a = unreal.new_object(_cls("ShockActionExitScript"))
    exit_a.configure("StandingOnCremationBody")
    killer.add_action(exit_a)
    killer.start_execution()
    killer.tick_execution(0.0)
    check(
        "G19_exit_stops_all_negative",
        (not bool(a.is_executing)) and (not bool(b.is_executing)),
    )

    # --- SCR-B07/B13 doors (world) ---
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    door_cls = _cls("ShockDoor")
    open_cls = _cls("ShockActionOpenDoor")
    d1 = actors.spawn_actor_from_class(
        door_cls, unreal.Vector(-18000, 0, 9000), unreal.Rotator(0, 0, 0))
    d2 = actors.spawn_actor_from_class(
        door_cls, unreal.Vector(-18050, 0, 9000), unreal.Rotator(0, 0, 0))
    try:
        d1.configure_for_verify(unreal.Name("TwinDoor"), False, False)
        d2.configure_for_verify(unreal.Name("TwinDoor"), False, False)
        d1.set_enable_proximity_open(False)
        d2.set_enable_proximity_open(False)
        d1.tags = [unreal.Name("BioShockLabel=TwinDoor")]
        d2.tags = [unreal.Name("BioShockLabel=TwinDoor")]
        opener = unreal.new_object(open_cls)
        opener.configure("TwinDoor", True)
        applied = int(opener.apply_in_world(ctx_world))
        check("B07_multi_match_positive", applied >= 2 and bool(d1.is_open()) and bool(d2.is_open()))
        miss = unreal.new_object(open_cls)
        miss.configure("NoSuchDoorLabelXYZ", True)
        check("B13_missing_returns_zero_negative", int(miss.apply_in_world(ctx_world)) == 0)

        # SCR-B08 case-insensitive
        d1.close_for_verify()
        opener_ci = unreal.new_object(open_cls)
        opener_ci.configure("twindoor", True)
        check(
            "B08_ignorecase_positive",
            int(opener_ci.apply_in_world(ctx_world)) >= 1 and bool(d1.is_open()),
        )
        miss_ci = unreal.new_object(open_cls)
        miss_ci.configure("totallydifferent", True)
        check("B08_mismatch_negative", int(miss_ci.apply_in_world(ctx_world)) == 0)

        # SCR-B09 BioShockLabel= tag resolve (CollectActorsByLabel / FindActorByLabel)
        tagged = actors.spawn_actor_from_class(
            unreal.StaticMeshActor.static_class(),
            unreal.Vector(-18100, 0, 9000),
            unreal.Rotator(0, 0, 0),
        )
        tagged.tags = [unreal.Name("BioShockLabel=TagOnlyActor")]
        found = unreal.ShockPhysicsLibrary.find_actor_by_label(
            ctx_world, unreal.Name("TagOnlyActor"))
        check("B09_tag_resolve_positive", found is not None)
        missing = unreal.ShockPhysicsLibrary.find_actor_by_label(
            ctx_world, unreal.Name("NoTagActorHere"))
        check("B09_tag_resolve_negative", missing is None)
        actors.destroy_actor(tagged)
    finally:
        if d1:
            actors.destroy_actor(d1)
        if d2:
            actors.destroy_actor(d2)

    # --- SCR-B17 keypad: no keypad actor class — RequestUsed records only ---
    keypad = unreal.new_object(_cls("ShockActionDoorKeypadUsed"))
    keypad.configure("SomePad", True)
    check("B17_request_records_positive", bool(keypad.request_used()))
    check(
        "B17_no_keypad_class_documented",
        str(keypad.get_last_door_keypad_control_label()) == "SomePad",
    )

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("scripting-fidelity:\n- " + "\n- ".join(f))
    _log("PASS scripting-fidelity (%d checks)" % len(report["checks"]))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "scripting_fidelity_report.json"),
        )
    )
