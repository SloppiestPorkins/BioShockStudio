"""Headless checks for w20 scripting VM stubs: watchers, critical travel flush, TestFact, training HUD.

Compatible with `-run=pythonscript` (no sibling imports). Style matches verify_scripting_movers.py.
Claude builds + runs this; the sandboxed worker does not launch Unreal.
"""

from __future__ import annotations

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-scripting-vm-stubs] %s" % m)


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
        # ---- 1. Watchers ----
        owner = spawn("ShockScript", unreal.Vector(-20000.0, 0.0, 8000.0))
        owner.configure("WatchOwner", "")
        owner.get_runner().set_registry(registry)
        listener = spawn("ShockScript", unreal.Vector(-20000.0, 50.0, 8000.0))
        listener.configure("WatchListen", "WatchOwner")
        listener.get_runner().set_script_message_class("MessageWatcher")
        listener.get_runner().set_registry(registry)
        listener.get_runner().add_action(_assign("Fired", "yes"))

        truth = unreal.new_object(_cls("ShockTruthStatement"), owner.get_runner())
        truth.configure("false")
        create = unreal.new_object(_cls("ShockActionCreateWatcher"), owner.get_runner())
        create.configure("HpLow", truth, True)
        owner.get_runner().add_action(create)
        owner.get_runner().start_execution()
        owner.get_runner().tick_execution(0.0)
        check("watcher_created", int(owner.get_runner().get_watcher_count()) == 1)
        check("watcher_enabled_after_create", bool(owner.get_runner().is_watcher_enabled("HpLow")))

        # Before 1s Sleep: must not fire.
        owner.get_runner().tick_execution(0.5)
        listener.get_runner().tick_execution(0.5)
        check("watcher_no_fire_before_poll", _flag(listener.get_runner(), "Fired") != "yes")

        # Poll at 1s with false expression: still no MessageWatcher.
        owner.get_runner().tick_execution(1.0)
        listener.get_runner().tick_execution(1.0)
        check("watcher_no_fire_while_false", _flag(listener.get_runner(), "Fired") != "yes")
        check("watcher_still_enabled_while_false", bool(owner.get_runner().is_watcher_enabled("HpLow")))

        # Expression becomes true; next poll (2s) fires once and disables.
        truth.configure("true")
        owner.get_runner().tick_execution(2.0)
        listener.get_runner().tick_execution(2.0)
        check("watcher_fires_on_true", _flag(listener.get_runner(), "Fired") == "yes")
        check("watcher_disabled_after_fire", not bool(owner.get_runner().is_watcher_enabled("HpLow")))

        # Disabled path: create enabled, disable before the first poll, expression true — no fire.
        owner2 = spawn("ShockScript", unreal.Vector(-20100.0, 0.0, 8000.0))
        owner2.configure("WatchOwner2", "")
        owner2.get_runner().set_registry(registry)
        listener2 = spawn("ShockScript", unreal.Vector(-20100.0, 50.0, 8000.0))
        listener2.configure("WatchListen2", "WatchOwner2")
        listener2.get_runner().set_script_message_class("MessageWatcher")
        listener2.get_runner().set_registry(registry)
        listener2.get_runner().add_action(_assign("Fired", "yes"))
        truth2 = unreal.new_object(_cls("ShockTruthStatement"), owner2.get_runner())
        truth2.configure("true")
        create2 = unreal.new_object(_cls("ShockActionCreateWatcher"), owner2.get_runner())
        create2.configure("Always", truth2, True)
        disable = unreal.new_object(_cls("ShockActionDisableWatcher"), owner2.get_runner())
        disable.configure("", "Always")
        owner2.get_runner().add_action(create2)
        owner2.get_runner().add_action(disable)
        owner2.get_runner().start_execution()
        owner2.get_runner().tick_execution(0.0)
        check("watcher_disabled_by_action", not bool(owner2.get_runner().is_watcher_enabled("Always")))
        owner2.get_runner().tick_execution(1.0)
        listener2.get_runner().tick_execution(1.0)
        check("watcher_no_fire_while_disabled", _flag(listener2.get_runner(), "Fired") != "yes")

        # Re-enable: SetWatcherEnabled restarts LookAtExpression (1s Sleep then execute).
        ok_en = bool(owner2.get_runner().set_watcher_enabled("Always", True, 1.0))
        check("watcher_reenable_ok", ok_en and bool(owner2.get_runner().is_watcher_enabled("Always")))
        owner2.get_runner().tick_execution(1.5)
        listener2.get_runner().tick_execution(1.5)
        check("watcher_no_fire_before_reenable_poll", _flag(listener2.get_runner(), "Fired") != "yes")
        owner2.get_runner().tick_execution(2.0)
        listener2.get_runner().tick_execution(2.0)
        check("watcher_fires_after_reenable", _flag(listener2.get_runner(), "Fired") == "yes")

        # EnableWatcher action targets parent when scriptName is None.
        owner3 = spawn("ShockScript", unreal.Vector(-20150.0, 0.0, 8000.0))
        owner3.configure("WatchOwner3", "")
        owner3.get_runner().set_registry(registry)
        truth3 = unreal.new_object(_cls("ShockTruthStatement"), owner3.get_runner())
        truth3.configure("false")
        create3 = unreal.new_object(_cls("ShockActionCreateWatcher"), owner3.get_runner())
        create3.configure("Named", truth3, False)
        owner3.get_runner().add_action(create3)
        owner3.get_runner().start_execution()
        owner3.get_runner().tick_execution(0.0)
        check("watcher_starts_disabled", not bool(owner3.get_runner().is_watcher_enabled("Named")))
        enable_act = unreal.new_object(_cls("ShockActionEnableWatcher"), owner3.get_runner())
        enable_act.configure("", "Named")
        # Apply via a one-shot run.
        owner3.get_runner().add_action(enable_act)
        owner3.get_runner().start_execution()
        owner3.get_runner().tick_execution(0.0)
        check("enable_watcher_action", bool(owner3.get_runner().is_watcher_enabled("Named")))

        # ---- 2. Critical flush (simulated TravelToLevel path) ----
        crit_script = spawn("ShockScript", unreal.Vector(-20200.0, 0.0, 8000.0))
        crit_script.configure("CritFlush", "")
        crit_script.get_runner().set_registry(registry)
        wait = unreal.new_object(_cls("ShockActionWait"), crit_script.get_runner())
        wait.configure(99.0)
        check("wait_not_critical_default", not bool(wait.get_editor_property("is_game_critical")))
        crit_assign = _assign("CriticalRan", "yes")
        # Outer assign to runner so it survives; AddAction does not re-outer.
        noncrit = unreal.new_object(_cls("ShockActionVariableAssignOverwrite"), crit_script.get_runner())
        noncrit.configure("NonCriticalRan", "yes")
        noncrit.set_game_critical_for_verify(False)
        crit_script.get_runner().add_action(wait)
        crit_script.get_runner().add_action(crit_assign)
        crit_script.get_runner().add_action(noncrit)
        crit_script.get_runner().start_execution()
        crit_script.get_runner().tick_execution(0.0)
        check("crit_blocked_on_wait", bool(crit_script.get_runner().is_executing))
        check("crit_not_yet_via_tick", _flag(crit_script.get_runner(), "CriticalRan") != "yes")

        flushed = int(script_sub.execute_pending_critical_actions())
        check("crit_flush_applied", flushed >= 1, flushed)
        check("crit_assign_ran_on_flush", _flag(crit_script.get_runner(), "CriticalRan") == "yes")
        check(
            "noncrit_skipped_on_flush",
            _flag(crit_script.get_runner(), "NonCriticalRan") != "yes",
        )
        check("crit_run_finished_after_flush", not bool(crit_script.get_runner().is_executing))

        # ---- 3. TestFact ----
        player = spawn("ShockPlayer", unreal.Vector(-20300.0, 0.0, 8000.0))
        test_fact = unreal.new_object(_cls("ShockActionTestFact"))
        test_fact.configure("MedGate", "open", "1")
        check("testfact_false_before_assert", not bool(test_fact.evaluate_in_world(world)))
        assert_fact = unreal.new_object(_cls("ShockActionAssertFact"))
        assert_fact.configure("MedGate", "open", "1")
        check("assert_fact_applied", int(assert_fact.apply_in_world(world)) == 1)
        check("testfact_true_after_assert", bool(test_fact.evaluate_in_world(world)))
        retract = unreal.new_object(_cls("ShockActionRetractFact"))
        retract.configure("MedGate", "open", "1")
        check("retract_fact_applied", int(retract.apply_in_world(world)) == 1)
        check("testfact_false_after_retract", not bool(test_fact.evaluate_in_world(world)))

        # ActionIf consumes EvaluateInWorld the same way PropertyTest does.
        if_action = unreal.new_object(_cls("ShockActionIf"))
        assert_fact.apply_in_world(world)
        if_action.add_test(test_fact)
        if_action.add_true_action(_assign("Branch", "pass"))
        if_action.add_else_action(_assign("Branch", "fail"))
        branch = str(if_action.choose_branch(world))
        check("testfact_feeds_actionif_true", branch == "true", branch)

        # ---- 4. Training message HUD ----
        hud = unreal.new_object(_cls("ShockHudWidget"))
        hud.bind_display_player(player)
        show = unreal.new_object(_cls("ShockActionShowTrainingMessage"))
        show.configure("Tip_Hack")
        check("show_training_applied", int(show.apply_in_world(world)) == 1)
        hud.refresh_display_now()
        shown = str(hud.get_displayed_training_message_text())
        check("hud_shows_training", shown == "Tip_Hack", shown)
        clear = unreal.new_object(_cls("ShockActionClearTrainingMessage"))
        clear.configure("Tip_Hack")
        check("clear_training_applied", int(clear.apply_in_world(world)) == 1)
        hud.refresh_display_now()
        cleared = str(hud.get_displayed_training_message_text())
        check("hud_clears_training", cleared == "", cleared)

    finally:
        for a in reversed(spawned):
            try:
                actors.destroy_actor(a)
            except Exception:
                pass

    report["ok"] = len(f) == 0
    os.makedirs(os.path.dirname(os.path.abspath(out)) or ".", exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("scripting-vm-stubs:\n- " + "\n- ".join(f))
    _log("PASS scripting-vm-stubs (%d checks)" % len(report["checks"]))
    return report


if __name__ == "__main__":
    main(os.path.join(os.environ.get("TEMP", "."), "bioshock-verify-scripting-vm-stubs.json"))
