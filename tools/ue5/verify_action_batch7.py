"""Batch7: WaitForQuestLog, SpotlightState, CloseDoor, ToggleAIReactions."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch7] %s" % m)


def main(scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWaitForQuestLogToFinish")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionWaitForQuestLogToFinish"))
    # TimeoutSeconds lives on ActionWaitForCriticalMessage in Scripting; walk may need both packages.
    # Configure explicitly for the request check.
    a.configure("QuestLog_Medical", 60.0)
    if not a.request_wait() or abs(float(a.get_timeout_seconds()) - 60.0) > 0.01:
        f.append("QuestLogWait")
    report["quest_log_wait"] = "ok"
    report["quest_log_apply"] = apply

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetMovableSpotlightState")
    a = unreal.new_object(cls)
    a.configure("Spot_A", True)
    if not a.request_set_state() or not bool(a.get_spotlight_on()):
        f.append("SpotlightState")
    report["spotlight_state"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCloseDoor")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionCloseDoor"))
    if not apply.get("ok"):
        f.append("CloseDoor defaults")
    a.configure("MedicalDoor", True)
    if not a.request_close() or not bool(a.get_force_close()):
        f.append("CloseDoor")
    report["close_door"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleAIReactions")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", unreal.ShockToggleHitReactions.USE, unreal.ShockToggleHitReactions.DO_NOT_CHANGE)
    if not a.request_toggle() or a.get_full_body_hit_reactions() != unreal.ShockToggleHitReactions.USE:
        f.append("ToggleReactions")
    report["toggle_reactions"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch7:\n- " + "\n- ".join(f))
    _log("PASS batch7")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SCRIPTING_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
