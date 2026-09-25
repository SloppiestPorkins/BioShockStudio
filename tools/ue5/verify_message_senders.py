"""Headless verify: real gameplay message senders (PawnDied / TookDamage / Inventory / AIWeaponFired /
RAReacted / Trigger enter-exit).

Spawns throwaway editor-world actors, triggers the real dispatch path, asserts the matching
ShockScript fires and a different scriptMessageClass on the same TriggeredBy does not.
Run via -run=pythonscript (no sibling imports).
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-message-senders] %s" % message)


def _runtime_class(name):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if cls is None:
        raise RuntimeError("missing runtime class %s" % name)
    return cls


def _check(condition, failures, message):
    if not condition:
        failures.append(message)


def _assign(name, value):
    action = unreal.new_object(_runtime_class("ShockActionVariableAssignOverwrite"))
    action.configure(name, value)
    return action


def _spawn_script(subsystem, label, triggered_by, message_class, flag_name, location):
    script = subsystem.spawn_actor_from_class(
        _runtime_class("ShockScript"), location, unreal.Rotator(0.0, 0.0, 0.0)
    )
    if script is None:
        raise RuntimeError("failed to spawn ShockScript %s" % label)
    script.set_actor_label(label)
    script.configure(label, triggered_by)
    runner = script.get_runner()
    runner.set_script_message_class(message_class)
    runner.add_action(_assign(flag_name, "yes"))
    script.ensure_registry()
    return script


def _flag(script, name):
    return str(script.get_runner().ensure_variables().get_value_or_empty(name))


def main(out_path):
    failures = []
    report = {"failures": failures}
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    spawned = []

    def spawn(cls, label, location):
        actor = subsystem.spawn_actor_from_class(
            cls, location, unreal.Rotator(0.0, 0.0, 0.0)
        )
        if actor is None:
            raise RuntimeError("failed to spawn %s" % label)
        actor.set_actor_label(label)
        spawned.append(actor)
        return actor

    try:
        # --- MessagePawnDied + MessagePawnTookDamage (killing blow order) ---
        died = _spawn_script(
            subsystem,
            "MsgDiedListener",
            "SteinmanVerify",
            "MessagePawnDied",
            "Died",
            unreal.Vector(0.0, 0.0, 50.0),
        )
        spawned.append(died)
        wrong_died = _spawn_script(
            subsystem,
            "MsgDiedWrongClass",
            "SteinmanVerify",
            "MessageRAReacted",
            "Wrong",
            unreal.Vector(0.0, 50.0, 50.0),
        )
        spawned.append(wrong_died)
        took = _spawn_script(
            subsystem,
            "MsgTookListener",
            "SteinmanVerify",
            "MessagePawnTookDamage",
            "Took",
            unreal.Vector(0.0, 100.0, 50.0),
        )
        spawned.append(took)
        all_died = _spawn_script(
            subsystem,
            "MsgDiedAll",
            "all",
            "MessagePawnDied",
            "AllDied",
            unreal.Vector(0.0, 150.0, 50.0),
        )
        spawned.append(all_died)

        ai = spawn(_runtime_class("BaseShockAI"), "SteinmanVerify", unreal.Vector(200.0, 0.0, 100.0))
        ai.configure_identity("ThuggishSplicer", "SteinmanVerify")
        ai.ensure_health_initialized()
        # Non-lethal then lethal through the real damage library path.
        ai.apply_authored_damage(10.0)
        took.tick_script(0.0)
        _check(_flag(took, "Took") == "yes", failures, "MessagePawnTookDamage did not fire on living hit")
        _check(_flag(died, "Died") != "yes", failures, "MessagePawnDied fired before lethal blow")

        # Reset took flag by spawning a fresh listener for the kill (same label / class).
        took2 = _spawn_script(
            subsystem,
            "MsgTookListener2",
            "SteinmanVerify",
            "MessagePawnTookDamage",
            "TookKill",
            unreal.Vector(0.0, 200.0, 50.0),
        )
        spawned.append(took2)
        ai.apply_authored_damage(10000.0)
        took2.tick_script(0.0)
        died.tick_script(0.0)
        wrong_died.tick_script(0.0)
        all_died.tick_script(0.0)
        _check(_flag(took2, "TookKill") == "yes", failures, "MessagePawnTookDamage missing on killing blow")
        _check(_flag(died, "Died") == "yes", failures, "MessagePawnDied did not fire")
        _check(_flag(wrong_died, "Wrong") != "yes", failures, "wrong class fired on PawnDied")
        _check(_flag(all_died, "AllDied") == "yes", failures, "TriggeredBy=all PawnDied did not fire")
        _check(float(ai.get_current_health()) <= 0.0, failures, "AI should be dead after lethal damage")
        report["pawnDied"] = "ok"
        report["pawnTookDamage"] = "ok"

        # --- MessageReceivedInventory (case-insensitive Player / player) ---
        inv = _spawn_script(
            subsystem,
            "MsgInvListener",
            "player",
            "MessageReceivedInventory",
            "Got",
            unreal.Vector(400.0, 0.0, 50.0),
        )
        spawned.append(inv)
        inv_wrong = _spawn_script(
            subsystem,
            "MsgInvWrong",
            "player",
            "MessagePawnDied",
            "InvWrong",
            unreal.Vector(400.0, 50.0, 50.0),
        )
        spawned.append(inv_wrong)
        player = spawn(_runtime_class("ShockPlayer"), "InvPlayer", unreal.Vector(500.0, 0.0, 100.0))
        player.set_suppress_inventory_messages(True)
        player.add_stack_to_inventory("FirstAidKit", 1)
        inv.tick_script(0.0)
        _check(_flag(inv, "Got") != "yes", failures, "suppressed loadout still dispatched inventory message")
        player.set_suppress_inventory_messages(False)
        player.add_stack_to_inventory("EveHypo", 1)
        inv.tick_script(0.0)
        inv_wrong.tick_script(0.0)
        _check(_flag(inv, "Got") == "yes", failures, "MessageReceivedInventory did not fire (player TriggeredBy)")
        _check(_flag(inv_wrong, "InvWrong") != "yes", failures, "wrong class fired on inventory")
        report["receivedInventory"] = "ok"

        # --- MessageAIWeaponFired ---
        fired = _spawn_script(
            subsystem,
            "MsgFireListener",
            "SteinmanGrenadierVerify",
            "MessageAIWeaponFired",
            "Shot",
            unreal.Vector(700.0, 0.0, 50.0),
        )
        spawned.append(fired)
        fire_wrong = _spawn_script(
            subsystem,
            "MsgFireWrong",
            "SteinmanGrenadierVerify",
            "MessagePawnDied",
            "FireWrong",
            unreal.Vector(700.0, 50.0, 50.0),
        )
        spawned.append(fire_wrong)
        shooter = spawn(
            _runtime_class("BaseShockAI"),
            "SteinmanGrenadierVerify",
            unreal.Vector(800.0, 0.0, 100.0),
        )
        shooter.configure_identity("ThuggishSplicer", "SteinmanGrenadierVerify")
        shooter.ensure_health_initialized()
        weapon_cls = _runtime_class("ShockWeapon")
        weapon = spawn(weapon_cls, "AIWeapon", unreal.Vector(800.0, 50.0, 100.0))
        weapon.configure_hitscan(1.0, 10000.0)
        shooter.equip_ai_weapon(weapon)
        dummy = spawn(_runtime_class("ShockPlayer"), "FireDummy", unreal.Vector(950.0, 0.0, 100.0))
        dummy.ensure_health_initialized()
        shooter.fire_ranged_at_for_verify(dummy)
        fired.tick_script(0.0)
        fire_wrong.tick_script(0.0)
        _check(_flag(fired, "Shot") == "yes", failures, "MessageAIWeaponFired did not fire")
        _check(_flag(fire_wrong, "FireWrong") != "yes", failures, "wrong class fired on AIWeaponFired")
        report["aiWeaponFired"] = "ok"

        # --- MessageRAReacted (NotifyReactedWithActor + oil ignite) ---
        ra = _spawn_script(
            subsystem,
            "MsgRAListener",
            "MedicalHallwaySwitch",
            "MessageRAReacted",
            "Reacted",
            unreal.Vector(1100.0, 0.0, 50.0),
        )
        spawned.append(ra)
        ra_wrong = _spawn_script(
            subsystem,
            "MsgRAWrong",
            "MedicalHallwaySwitch",
            "MessagePawnDied",
            "RAWrong",
            unreal.Vector(1100.0, 50.0, 50.0),
        )
        spawned.append(ra_wrong)
        switch = spawn(unreal.StaticMeshActor, "MedicalHallwaySwitch", unreal.Vector(1200.0, 0.0, 100.0))
        reactor = spawn(_runtime_class("ShockPlayer"), "RAPlayer", unreal.Vector(1250.0, 0.0, 100.0))
        reactor.notify_reacted_with_actor(switch)
        ra.tick_script(0.0)
        ra_wrong.tick_script(0.0)
        _check(_flag(ra, "Reacted") == "yes", failures, "MessageRAReacted NotifyReactedWithActor did not fire")
        _check(_flag(ra_wrong, "RAWrong") != "yes", failures, "wrong class fired on RAReacted")

        oil_ra = _spawn_script(
            subsystem,
            "MsgOilRA",
            "ScriptedOilSlick1",
            "MessageRAReacted",
            "Oil",
            unreal.Vector(1100.0, 100.0, 50.0),
        )
        spawned.append(oil_ra)
        oil = spawn(
            _runtime_class("ShockOilSlickVolume"),
            "ScriptedOilSlick1",
            unreal.Vector(1300.0, 0.0, 100.0),
        )
        oil.ignite_slick(reactor, 1.0, 1.0, 1.0)
        oil_ra.tick_script(0.0)
        _check(_flag(oil_ra, "Oil") == "yes", failures, "MessageRAReacted oil ignite did not fire")
        report["raReacted"] = "ok"

        # --- Trigger enter / exit (relay) ---
        enter = _spawn_script(
            subsystem,
            "MsgTrigEnter",
            "PSATriggerRadiusA",
            "MessageTriggerEnter",
            "Enter",
            unreal.Vector(1500.0, 0.0, 50.0),
        )
        spawned.append(enter)
        exit_s = _spawn_script(
            subsystem,
            "MsgTrigExit",
            "PSATriggerRadiusA",
            "MessageTriggerExit",
            "Exit",
            unreal.Vector(1500.0, 50.0, 50.0),
        )
        spawned.append(exit_s)
        enter_wrong = _spawn_script(
            subsystem,
            "MsgTrigEnterWrong",
            "PSATriggerRadiusA",
            "MessageTriggerVolumeEnter",
            "EnterWrong",
            unreal.Vector(1500.0, 100.0, 50.0),
        )
        spawned.append(enter_wrong)
        radius = spawn(unreal.TriggerSphere, "PSATriggerRadiusA", unreal.Vector(1600.0, 0.0, 100.0))
        relay = unreal.ShockTriggerRelayComponent.install_on_actor(
            radius,
            "PSATriggerRadiusA",
            True,
            False,
            "MessageTriggerEnter",
            "MessageTriggerExit",
        )
        _check(relay is not None, failures, "TriggerRadius relay install failed")
        shared = unreal.ShockScriptSubsystem.get_registry_for_world(world)
        if shared is not None:
            enter.set_registry(shared)
            exit_s.set_registry(shared)
            enter_wrong.set_registry(shared)
        fired_enter = int(relay.fire_for_verify()) if relay else 0
        enter.tick_script(0.0)
        enter_wrong.tick_script(0.0)
        _check(fired_enter >= 1, failures, "MessageTriggerEnter relay accepted=%s" % fired_enter)
        _check(_flag(enter, "Enter") == "yes", failures, "MessageTriggerEnter script did not fire")
        _check(_flag(enter_wrong, "EnterWrong") != "yes", failures, "VolumeEnter class fired on Radius enter")
        fired_exit = int(relay.fire_exit_for_verify()) if relay else 0
        exit_s.tick_script(0.0)
        _check(fired_exit >= 1, failures, "MessageTriggerExit relay accepted=%s" % fired_exit)
        _check(_flag(exit_s, "Exit") == "yes", failures, "MessageTriggerExit script did not fire")
        report["triggerEnterExit"] = "ok"

        vol_exit = _spawn_script(
            subsystem,
            "MsgVolExit",
            "NearCurtainsTV",
            "MessageTriggerVolumeExit",
            "VolExit",
            unreal.Vector(1700.0, 0.0, 50.0),
        )
        spawned.append(vol_exit)
        box = spawn(unreal.TriggerBox, "NearCurtainsTV", unreal.Vector(1800.0, 0.0, 100.0))
        vol_relay = unreal.ShockTriggerRelayComponent.install_on_actor(
            box, "NearCurtainsTV", True, False
        )
        if shared is not None:
            vol_exit.set_registry(shared)
        fired_vol_exit = int(vol_relay.fire_exit_for_verify()) if vol_relay else 0
        vol_exit.tick_script(0.0)
        _check(fired_vol_exit >= 1, failures, "MessageTriggerVolumeExit accepted=%s" % fired_vol_exit)
        _check(_flag(vol_exit, "VolExit") == "yes", failures, "MessageTriggerVolumeExit script did not fire")
        report["triggerVolumeExit"] = "ok"

    finally:
        for actor in spawned:
            if actor:
                subsystem.destroy_actor(actor)

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    if failures:
        raise RuntimeError("message-senders:\n- " + "\n- ".join(failures))
    _log("Success - message senders")
    unreal.log("Success - message senders")
    return report


if __name__ == "__main__":
    default_out = os.path.join(
        os.environ.get("TEMP", os.environ.get("TMP", ".")),
        "bioshock_message_senders_report.json",
    )
    main(os.environ.get("BIOSHOCK_ACTION_OUT", default_out))
