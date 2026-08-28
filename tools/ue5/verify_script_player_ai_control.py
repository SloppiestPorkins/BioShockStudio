"""Runner crouch/disable-move/concept + AI state/attack/physics."""

import json
import os

import unreal


def _flag(value):
    return bool(value() if callable(value) else value)


def _log(m):
    unreal.log("[bioshock-script-player-ai-control] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    crouch_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionForcePlayerCrouch"
    )
    move_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDisablePlayerMovement"
    )
    concept_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDisableOrEnableConcept"
    )
    state_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIState")
    attack_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionToggleAIAttacking"
    )
    phys_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionChangePawnPhysics"
    )

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("PlayerAiCtrlScript", "")
    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(40, 0, 100), unreal.Rotator(0, 0, 0)
    )
    ai = subsystem.spawn_actor_from_class(
        ai_cls, unreal.Vector(120, 0, 50), unreal.Rotator(0, 0, 0)
    )
    ai.set_actor_label("SplicerA")
    ai.configure_identity("ThuggishSplicer", "SplicerA")

    crouch = unreal.new_object(crouch_cls)
    crouch.configure(True)
    disable_move = unreal.new_object(move_cls)
    disable_move.configure(True)
    concept = unreal.new_object(concept_cls)
    concept.configure("Concept.Hack", False)
    state = unreal.new_object(state_cls)
    state.configure("SplicerA", 4)
    attack = unreal.new_object(attack_cls)
    attack.configure("SplicerA", False)
    phys = unreal.new_object(phys_cls)
    phys.configure("SplicerA", True, False)

    runner = script.get_runner()
    for action in (crouch, disable_move, concept, state, attack, phys):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    runner.tick_execution(0.0)

    if not bool(crouch.get_last_should_crouch()):
        f.append("crouch record")
    if not bool(disable_move.get_last_disable_movement()):
        f.append("disable-move record")
    if str(concept.get_last_concept_name()) != "Concept.Hack":
        f.append("concept %s" % concept.get_last_concept_name())
    if bool(concept.get_last_enable()):
        f.append("concept should be disabled")
    if str(state.get_last_ai_label()) != "SplicerA":
        f.append("state %s" % state.get_last_ai_label())
    if str(attack.get_last_ai_label()) != "SplicerA":
        f.append("attack %s" % attack.get_last_ai_label())
    if str(phys.get_last_target_label()) != "SplicerA":
        f.append("phys %s" % phys.get_last_target_label())

    if player is None:
        f.append("no ShockPlayer")
    else:
        if not _flag(player.is_forced_crouch):
            f.append("in-world not crouched")
        if not _flag(player.is_movement_disabled):
            f.append("in-world movement still on")
        if bool(player.is_concept_enabled("Concept.Hack")):
            f.append("in-world concept still on")

    if ai is None:
        f.append("no BaseShockAI")
    else:
        if int(ai.get_scripted_ai_state()) != 4:
            f.append("in-world AI state %s" % ai.get_scripted_ai_state())
        if _flag(ai.can_attack):
            f.append("in-world still can attack")
        if not _flag(ai.is_physics_disabled):
            f.append("in-world physics still on")

    report["player_ai_control"] = "ok" if not f else "fail"

    for actor in (script, player, ai):
        if actor:
            subsystem.destroy_actor(actor)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("player-ai-control:\n- " + "\n- ".join(f))
    _log("PASS player-ai-control")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_player_ai_control_report.json",
        )
    )
