"""Runner AI-state batch: vision/hearing/mute/wait/patrol/goal/reactions/invinc/tip.

Fade / ChangeSkin / AISpeech stay record-only (no in-world systems yet).
"""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-ai-tweak] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    vision_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTweakAIVision")
    hearing_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTweakAIHearing")
    tip_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetTipPriority")
    mute_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionMuteAI")
    wait_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToWait")
    continue_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToContinue")
    patrol_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIPatrol")
    goal_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPostMovementGoal")
    react_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleAIReactions")
    pawn_inv_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetPawnInvincibility"
    )
    player_inv_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetPlayerInvincibility"
    )
    fade_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCinematicFadeView")
    skin_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeSkinAtIndex")
    speech_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAISpeech")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("AiTweakScript", "")
    ai = subsystem.spawn_actor_from_class(
        ai_cls, unreal.Vector(120, 0, 50), unreal.Rotator(0, 0, 0)
    )
    ai.set_actor_label("SplicerA")
    ai.configure_identity("ThuggishSplicer", "SplicerA")
    ai.ensure_health_initialized()
    dest = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(400, 25, 80), unreal.Rotator(0, 0, 0)
    )
    dest.set_actor_label("DestPad")
    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(40, 0, 100), unreal.Rotator(0, 0, 0)
    )

    vision = unreal.new_object(vision_cls)
    vision.configure("SplicerA", True, False, True)
    hearing = unreal.new_object(hearing_cls)
    hearing.configure("SplicerA", False)
    tip = unreal.new_object(tip_cls)
    tip.configure("Tip.Health", 5)
    mute = unreal.new_object(mute_cls)
    mute.configure("SplicerA", True)
    wait_ai = unreal.new_object(wait_cls)
    wait_ai.configure("SplicerA")
    continue_ai = unreal.new_object(continue_cls)
    continue_ai.configure("SplicerA")
    patrol = unreal.new_object(patrol_cls)
    patrol.configure("SplicerA", "MedicalHall")
    goal = unreal.new_object(goal_cls)
    goal.configure("SplicerA", "DestPad", "MoveToPad", 50, True)
    use = unreal.ShockToggleHitReactions.USE
    react = unreal.new_object(react_cls)
    react.configure("SplicerA", use, use)
    pawn_inv = unreal.new_object(pawn_inv_cls)
    pawn_inv.configure("SplicerA", True)
    player_inv = unreal.new_object(player_inv_cls)
    player_inv.configure(True)
    fade = unreal.new_object(fade_cls)
    fade.configure(0.0, 1.0, 2.5, 0.5)
    skin = unreal.new_object(skin_cls)
    skin.configure("BodyMesh", "M_Skin", 2)
    speech = unreal.new_object(speech_cls)
    speech.configure("SplicerA", "Speech.Greet", False)

    runner = script.get_runner()
    for action in (
        vision,
        hearing,
        tip,
        mute,
        wait_ai,
        continue_ai,
        patrol,
        goal,
        react,
        pawn_inv,
        player_inv,
        fade,
        skin,
        speech,
    ):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    runner.tick_execution(0.0)

    if str(vision.get_last_tweaked_ai_label()) != "SplicerA":
        f.append("vision %s" % vision.get_last_tweaked_ai_label())
    if not bool(vision.get_last_turn_vision_on()):
        f.append("vision on")
    if str(hearing.get_last_tweaked_ai_label()) != "SplicerA":
        f.append("hearing %s" % hearing.get_last_tweaked_ai_label())
    if bool(hearing.get_last_turn_hearing_on()):
        f.append("hearing should be off")
    if str(tip.get_last_tip_name()) != "Tip.Health":
        f.append("tip %s" % tip.get_last_tip_name())
    if int(tip.get_last_priority()) != 5:
        f.append("tip priority %s" % tip.get_last_priority())
    if str(mute.get_last_muted_ai_label()) != "SplicerA":
        f.append("mute %s" % mute.get_last_muted_ai_label())
    if not bool(mute.get_last_muted()):
        f.append("mute flag")
    if str(wait_ai.get_last_ai_label()) != "SplicerA":
        f.append("wait %s" % wait_ai.get_last_ai_label())
    if str(continue_ai.get_last_ai_label()) != "SplicerA":
        f.append("continue %s" % continue_ai.get_last_ai_label())
    if str(patrol.get_last_patrol_name()) != "MedicalHall":
        f.append("patrol %s" % patrol.get_last_patrol_name())
    if str(goal.get_last_destination_label()) != "DestPad":
        f.append("goal dest %s" % goal.get_last_destination_label())
    if str(react.get_last_ai_label()) != "SplicerA":
        f.append("react %s" % react.get_last_ai_label())
    if str(pawn_inv.get_last_pawn_label()) != "SplicerA":
        f.append("pawn inv %s" % pawn_inv.get_last_pawn_label())
    if not bool(player_inv.get_last_invincible()):
        f.append("player inv record")
    if float(fade.get_last_requested_duration()) != 2.5:
        f.append("fade %s" % fade.get_last_requested_duration())
    if str(skin.get_last_target_label()) != "BodyMesh":
        f.append("skin target %s" % skin.get_last_target_label())
    if int(skin.get_last_index()) != 2:
        f.append("skin index %s" % skin.get_last_index())
    if str(speech.get_last_ai_label()) != "SplicerA":
        f.append("speech ai %s" % speech.get_last_ai_label())
    if str(speech.get_last_speech_event_label()) != "Speech.Greet":
        f.append("speech event %s" % speech.get_last_speech_event_label())

    if ai is None:
        f.append("no BaseShockAI")
    else:
        if not bool(ai.is_vision_on()):
            f.append("in-world vision off")
        if bool(ai.is_hearing_on()):
            f.append("in-world hearing still on")
        if not bool(ai.get_always_see_player()):
            f.append("in-world always-see not set")
        if not bool(ai.is_muted()):
            f.append("in-world not muted")
        if bool(ai.is_told_to_wait()):
            f.append("in-world still waiting after continue")
        if str(ai.get_patrol_name()) != "MedicalHall":
            f.append("in-world patrol %s" % ai.get_patrol_name())
        if str(ai.get_movement_destination_label()) != "DestPad":
            f.append("in-world dest %s" % ai.get_movement_destination_label())
        dest_loc = ai.get_editor_property("movement_goal_location")
        if dest_loc is None or abs(float(dest_loc.x) - 400.0) > 0.5:
            f.append("in-world dest loc %s" % dest_loc)
        if int(ai.get_full_body_hit_reactions()) != 1:
            f.append("in-world full-body reactions %s" % ai.get_full_body_hit_reactions())
        if not bool(ai.is_invincible()):
            f.append("in-world pawn not invincible")
        else:
            health_before = float(ai.get_current_health())
            health_after = float(ai.apply_authored_damage(40.0))
            if health_after != health_before:
                f.append("invincible pawn took damage (%s -> %s)" % (
                    health_before, health_after))
            report["pawn_health"] = {"before": health_before, "after": health_after}

    if player is None:
        f.append("no ShockPlayer")
    else:
        if int(player.get_tip_priority("Tip.Health")) != 5:
            f.append("in-world tip %s" % player.get_tip_priority("Tip.Health"))
        if not bool(player.is_invincible()):
            f.append("in-world player not invincible")

    report["ai_tweak"] = "ok" if not f else "fail"

    for actor in (script, ai, dest, player):
        if actor:
            subsystem.destroy_actor(actor)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("ai-tweak:\n- " + "\n- ".join(f))
    _log("PASS ai-tweak")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_ai_tweak_report.json",
        )
    )
