"""Runner TweakAIVision/Hearing, SetTipPriority, MuteAI, Fade, ChangeSkin, AISpeech."""

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
    vision_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTweakAIVision")
    hearing_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTweakAIHearing")
    tip_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetTipPriority")
    mute_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionMuteAI")
    fade_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCinematicFadeView")
    skin_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeSkinAtIndex")
    speech_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAISpeech")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("AiTweakScript", "")

    vision = unreal.new_object(vision_cls)
    vision.configure("SplicerA", True, False, True)
    hearing = unreal.new_object(hearing_cls)
    hearing.configure("SplicerA", False)
    tip = unreal.new_object(tip_cls)
    tip.configure("Tip.Health", 5)
    mute = unreal.new_object(mute_cls)
    mute.configure("SplicerA", True)
    fade = unreal.new_object(fade_cls)
    fade.configure(0.0, 1.0, 2.5, 0.5)
    skin = unreal.new_object(skin_cls)
    skin.configure("BodyMesh", "M_Skin", 2)
    speech = unreal.new_object(speech_cls)
    speech.configure("SplicerA", "Speech.Greet", False)

    runner = script.get_runner()
    for action in (vision, hearing, tip, mute, fade, skin, speech):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(7):
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
    report["ai_tweak"] = "ok"

    subsystem.destroy_actor(script)

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
