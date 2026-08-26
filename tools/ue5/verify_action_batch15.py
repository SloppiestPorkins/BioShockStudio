"""Batch15: HUD, AssassinTeleport, HandSeq start/stop, SetQuestHint."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch15] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetHUDDisplayState")
    a = unreal.new_object(cls)
    a.configure(False)
    if not a.request_set() or bool(a.get_last_enable_hud()):
        f.append("HUD")
    report["hud"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssassinTeleport")
    a = unreal.new_object(cls)
    a.configure("Assassin_A", "Teleport_A", "Rot_A", True, False)
    if not a.request_teleport():
        f.append("Assassin")
    report["assassin"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStartScriptedHandAnimationSequence")
    a = unreal.new_object(cls)
    if not a.request_start() or not bool(a.get_started()):
        f.append("HandStart")
    report["hand_start"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopScriptedHandAnimationSequence")
    a = unreal.new_object(cls)
    if not a.request_stop() or not bool(a.get_stopped()):
        f.append("HandStop")
    report["hand_stop"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetQuestHint")
    a = unreal.new_object(cls)
    a.configure("Quest_Medical", "Hint_Hack")
    if not a.request_set():
        f.append("QuestHint")
    report["quest_hint"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch15:\n- " + "\n- ".join(f))
    _log("PASS batch15")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
