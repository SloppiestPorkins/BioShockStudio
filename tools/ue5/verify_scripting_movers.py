"""Headless fidelity checks for SCR-G01/G07/G11/G12/G18/G20 (y8 movers + scripting gaps).

Compatible with `-run=pythonscript` (no sibling imports). Style matches verify_scripting_fidelity.py.
Each case has a positive and a negative assertion.
"""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-scripting-movers] %s" % m)


def _cls(name):
    c = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if c is None:
        raise RuntimeError("missing class %s" % name)
    return c


def _assign(name, value):
    a = unreal.new_object(_cls("ShockActionVariableAssignOverwrite"))
    a.configure(name, value)
    return a


def _flag(runner, name):
    return str(runner.ensure_variables().get_value_or_empty(name))


def main(out):
    report = {"failures": [], "checks": {}}
    f = report["failures"]

    def check(name, ok, detail=None):
        report["checks"][name] = bool(ok)
        if not ok:
            f.append("%s%s" % (name, (" (%s)" % detail) if detail else ""))

    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    script_sub = unreal.ShockScriptSubsystem.get_for_world(world)
    if script_sub is None:
        raise RuntimeError("ShockScriptSubsystem missing for editor world")
    registry = script_sub.get_or_create_registry()

    spawned = []

    def spawn(cls_name, loc):
        a = actors.spawn_actor_from_class(_cls(cls_name), loc, unreal.Rotator(0, 0, 0))
        if a is None:
            raise RuntimeError("spawn %s failed" % cls_name)
        spawned.append(a)
        return a

    try:
        # --- SCR-G01 ScriptableMover TriggeredBy + MessageMover* ---
        mover = spawn("ShockAnimatedProp", unreal.Vector(-19000.0, 0.0, 8000.0))
        mover.configure_mover_for_verify(
            unreal.Name("LiftMover"), "LiftScript", unreal.Vector(0.0, 0.0, 100.0), 0.5, False)
        opened = spawn("ShockScript", unreal.Vector(-19000.0, 50.0, 8000.0))
        opened.configure("ElevOpen", "LiftMover")
        opened.get_runner().set_script_message_class("MessageMoverOpened")
        opened.get_runner().set_registry(registry)
        opened.get_runner().add_action(_assign("Opened", "yes"))
        opening = spawn("ShockScript", unreal.Vector(-19000.0, 100.0, 8000.0))
        opening.configure("ElevOpening", "LiftMover")
        opening.get_runner().set_script_message_class("MessageMoverOpening")
        opening.get_runner().set_registry(registry)
        opening.get_runner().add_action(_assign("Opening", "yes"))

        # Positive: MessageTrigger from TriggeredBy label starts open + Opening/Opened.
        accepted = int(registry.dispatch_message("MessageTrigger", "LiftScript"))
        check("G01_trigger_accepted_positive", accepted >= 1 and bool(mover.is_keyframe_moving()))
        opening.get_runner().tick_execution(0.0)
        check("G01_opening_msg_positive", _flag(opening.get_runner(), "Opening") == "yes")
        for _ in range(40):
            mover.advance_motion_for_verify(0.05)
        opened.get_runner().tick_execution(0.0)
        check(
            "G01_opened_msg_positive",
            (not bool(mover.is_keyframe_moving())) and _flag(opened.get_runner(), "Opened") == "yes",
        )

        # Negative: mid-move trigger ignored; wrong TriggeredBy ignored.
        accepted2 = int(registry.dispatch_message("MessageTrigger", "LiftScript"))
        # Already open — starting close should be accepted when idle.
        check("G01_close_toggle_positive", accepted2 >= 1 and bool(mover.is_keyframe_moving()))
        mid = int(registry.dispatch_message("MessageTrigger", "LiftScript"))
        check("G01_midmove_ignored_negative", mid == 0)
        for _ in range(40):
            mover.advance_motion_for_verify(0.05)
        wrong = int(registry.dispatch_message("MessageTrigger", "WrongScriptLabel"))
        check("G01_wrong_triggeredby_negative", wrong == 0)

        # --- SCR-G11 MessageSavegameRestored vs MessageLevelStarted ---
        resume = spawn("ShockScript", unreal.Vector(-19100.0, 0.0, 8000.0))
        resume.configure("ResumeAmb", "all")
        resume.get_runner().set_script_message_class("MessageSavegameRestored")
        resume.get_runner().set_registry(registry)
        resume.get_runner().add_action(_assign("Resumed", "yes"))
        fresh = spawn("ShockScript", unreal.Vector(-19100.0, 50.0, 8000.0))
        fresh.configure("FreshStart", "all")
        fresh.get_runner().set_script_message_class("MessageLevelStarted")
        fresh.get_runner().set_registry(registry)
        fresh.get_runner().add_action(_assign("Started", "yes"))

        if True:
            script_sub.reset_level_entry_dispatch_for_verify()
            script_sub.dispatch_level_entry_messages_mode(True)
            resume.get_runner().tick_execution(0.0)
            fresh.get_runner().tick_execution(0.0)
            check("G11_restore_positive", _flag(resume.get_runner(), "Resumed") == "yes")
            check(
                "G11_restore_not_levelstarted_negative",
                _flag(fresh.get_runner(), "Started") != "yes",
            )

            # Fresh start path (no pending restore).
            resume2 = spawn("ShockScript", unreal.Vector(-19150.0, 0.0, 8000.0))
            resume2.configure("ResumeAmb2", "all")
            resume2.get_runner().set_script_message_class("MessageSavegameRestored")
            resume2.get_runner().set_registry(registry)
            resume2.get_runner().add_action(_assign("Resumed", "yes"))
            fresh2 = spawn("ShockScript", unreal.Vector(-19150.0, 50.0, 8000.0))
            fresh2.configure("FreshStart2", "all")
            fresh2.get_runner().set_script_message_class("MessageLevelStarted")
            fresh2.get_runner().set_registry(registry)
            fresh2.get_runner().add_action(_assign("Started", "yes"))
            script_sub.reset_level_entry_dispatch_for_verify()
            script_sub.dispatch_level_entry_messages_mode(False)
            resume2.get_runner().tick_execution(0.0)
            fresh2.get_runner().tick_execution(0.0)
            check("G11_fresh_levelstarted_positive", _flag(fresh2.get_runner(), "Started") == "yes")
            check(
                "G11_fresh_not_restore_negative",
                _flag(resume2.get_runner(), "Resumed") != "yes",
            )
        else:
            check("G11_restore_positive", False, "no ShockGameInstance")
            check("G11_restore_not_levelstarted_negative", False, "no ShockGameInstance")
            check("G11_fresh_levelstarted_positive", False, "no ShockGameInstance")
            check("G11_fresh_not_restore_negative", False, "no ShockGameInstance")

        # --- SCR-G18 expression temps cleared in FinishExecution ---
        arith = unreal.new_object(_cls("ShockArithmeticStatement"))
        arith.configure(0, "3", "4")  # ADD
        ar_actor = spawn("ShockScript", unreal.Vector(-19200.0, 0.0, 8000.0))
        ar_actor.configure("TempClear", "")
        ar_runner = ar_actor.get_runner()
        ar_runner.add_action(arith)
        wait_hold = unreal.new_object(_cls("ShockActionWait"))
        wait_hold.configure(30.0)
        ar_runner.add_action(wait_hold)
        ar_runner.add_action(_assign("Done", "yes"))
        ar_runner.start_execution()
        ar_runner.tick_execution(0.0)
        check(
            "G18_temp_during_run_positive",
            bool(ar_runner.is_executing) and arith.get_return_value() is not None,
        )
        # Drain the wait → FinishExecution clears expression temps; Done is a script var (kept).
        ar_runner.tick_execution(31.0)
        check(
            "G18_script_finished_positive",
            (not bool(ar_runner.is_executing)) and _flag(ar_runner, "Done") == "yes",
        )
        check("G18_temp_cleared_negative", arith.get_return_value() is None)

        # --- SCR-G20 trigger filter labels ---
        vol = actors.spawn_actor_from_class(
            unreal.TriggerBox.static_class(),
            unreal.Vector(-19300.0, 0.0, 8000.0),
            unreal.Rotator(0, 0, 0),
        )
        spawned.append(vol)
        relay = unreal.ShockTriggerRelayComponent.install_on_actor(
            vol, "FilterVol", False, False,
            "MessageTriggerVolumeEnter", "MessageTriggerVolumeExit")
        relay.configure_filters(["Player"], [])
        player = spawn("ShockPlayer", unreal.Vector(-19300.0, 100.0, 8100.0))
        check("G20_filter_player_positive", bool(relay.passes_filters_for_verify(player)))
        # Negative: non-player actor fails FilterLabels=Player.
        other = actors.spawn_actor_from_class(
            unreal.StaticMeshActor.static_class(),
            unreal.Vector(-19350.0, 0.0, 8000.0),
            unreal.Rotator(0, 0, 0),
        )
        spawned.append(other)
        check("G20_filter_nonplayer_negative", not bool(relay.passes_filters_for_verify(other)))

        # --- SCR-G12 inventory + keypad fields ---
        inv = spawn("ShockScript", unreal.Vector(-19400.0, 0.0, 8000.0))
        inv.configure("InvListen", "Player")
        inv.get_runner().set_script_message_class("MessageReceivedInventory")
        inv.get_runner().set_registry(registry)
        inv.get_runner().add_action(_assign("Got", "yes"))
        player2 = spawn("ShockPlayer", unreal.Vector(-19400.0, 100.0, 8100.0))
        player2.set_suppress_inventory_messages(False)
        player2.add_stack_to_inventory("EveHypo", 2)
        inv.get_runner().tick_execution(0.0)
        check("G12_inv_fired_positive", _flag(inv.get_runner(), "Got") == "yes")
        check(
            "G12_actualclass_positive",
            str(inv.get_runner().get_last_message_field("ActualClass")) == "EveHypo",
        )
        check(
            "G12_amount_positive",
            str(inv.get_runner().get_last_message_field("Amount")) == "2",
        )
        check(
            "G12_reason_positive",
            str(inv.get_runner().get_last_message_field("Reason")) == "Touch",
        )
        check(
            "G12_absent_field_negative",
            str(inv.get_runner().get_last_message_field("Keycode")) == "",
        )

        pad = spawn("ShockScript", unreal.Vector(-19450.0, 0.0, 8000.0))
        pad.configure("PadListen", "PlasmidPad")
        pad.get_runner().set_script_message_class("MessageDoorKeypadUsed")
        pad.get_runner().set_registry(registry)
        pad.get_runner().add_action(_assign("PadOk", "yes"))
        script_sub.dispatch_door_keypad_used("PlasmidPad", "7774")
        pad.get_runner().tick_execution(0.0)
        check("G12_keycode_positive", str(pad.get_runner().get_last_message_field("Keycode")) == "7774")
        check("G12_keycode_script_fired_positive", _flag(pad.get_runner(), "PadOk") == "yes")
        # Negative: wrong source label does not start a different pad script.
        pad2 = spawn("ShockScript", unreal.Vector(-19450.0, 50.0, 8000.0))
        pad2.configure("PadMiss", "OtherPad")
        pad2.get_runner().set_script_message_class("MessageDoorKeypadUsed")
        pad2.get_runner().set_registry(registry)
        pad2.get_runner().add_action(_assign("PadOk", "yes"))
        script_sub.dispatch_door_keypad_used("PlasmidPad", "7774")
        pad2.get_runner().tick_execution(0.0)
        check("G12_keycode_wrong_label_negative", _flag(pad2.get_runner(), "PadOk") != "yes")

        # --- SCR-G07 LightType flicker → steady ---
        light = actors.spawn_actor_from_class(
            unreal.PointLight.static_class(),
            unreal.Vector(-19500.0, 0.0, 8100.0),
            unreal.Rotator(0, 0, 0),
        )
        spawned.append(light)
        light.set_actor_label("StairLight")
        light.tags = [unreal.Name("BioShockLabel=StairLight")]
        set_light = unreal.new_object(_cls("ShockActionSetLightProperties"))
        set_light.configure("StairLight", True, 3.0, False, unreal.Color(255, 255, 255, 255))
        set_light.configure_light_type(True, "LT_Flicker", True, 0.5, False, 0.0)
        check("G07_flicker_apply_positive", bool(set_light.apply_to_actor(light)))
        check(
            "G07_flicker_type_positive",
            int(set_light.get_last_applied_effect_type()) == 4,  # Flicker
        )
        effect = light.get_component_by_class(_cls("ShockLightEffectComponent"))
        check("G07_effect_component_positive", effect is not None and unreal.SystemLibrary.is_valid(effect))
        # Negative: no ChangeProperty flags → refuse.
        blank = unreal.new_object(_cls("ShockActionSetLightProperties"))
        blank.configure("StairLight", False, 9.0, False, unreal.Color(0, 0, 0, 255))
        check("G07_no_change_negative", not bool(blank.apply_to_actor(light)))
        # Steady apply records Steady and keeps brightness path.
        set_light.configure_light_type(True, "LT_Steady", False, 1.0, False, 0.0)
        check("G07_steady_apply_positive", bool(set_light.apply_to_actor(light)))
        check("G07_steady_type_positive", int(set_light.get_last_applied_effect_type()) == 1)

    finally:
        for a in spawned:
            if a and unreal.SystemLibrary.is_valid(a):
                actors.destroy_actor(a)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("scripting-movers:\n- " + "\n- ".join(f))
    _log("PASS scripting-movers (%d checks)" % len(report["checks"]))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "scripting_movers_report.json"),
        )
    )
