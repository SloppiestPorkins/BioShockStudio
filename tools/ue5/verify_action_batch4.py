"""Batch4: WaitForGoal, ChangeSkinAtIndex, OpenDoor, AISpeech."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch4] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWaitForGoal")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", "MovementGoal", 5.0)
    if not a.request_wait() or str(a.get_last_goal_name()) != "MovementGoal":
        f.append("WaitForGoal")
    report["wait_goal"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeSkinAtIndex")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionChangeSkinAtIndex"))
    if not apply.get("ok"):
        f.append("ChangeSkin defaults")
    a.configure("MedicalProp", "M_Skin", 2)
    if not a.request_change_skin() or int(a.get_last_index()) != 2:
        f.append("ChangeSkin")
    report["skin"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionOpenDoor")
    a = unreal.new_object(cls)
    a.configure("MedicalDoor", True)
    if not a.request_open() or not bool(a.get_stay_open()):
        f.append("OpenDoor")
    report["open_door"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAISpeech")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", "Speech_Hello", False)
    if not a.request_speech() or bool(a.get_stop_speech()):
        f.append("AISpeech")
    report["speech"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch4:\n- " + "\n- ".join(f))
    _log("PASS batch4")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
