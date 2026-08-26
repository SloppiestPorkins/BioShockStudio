"""Batch18: DisablePlayerMovement, StopSecurityAlarm, FailQuest, CeilingCrawler."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch18] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDisablePlayerMovement")
    a = unreal.new_object(cls)
    a.configure(True)
    if not a.request_set() or not bool(a.get_last_disable_movement()):
        f.append("DisableMovement")
    report["disable_movement"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopSecurityAlarm")
    a = unreal.new_object(cls)
    a.configure(True)
    if not a.request_stop() or not bool(a.get_last_bots_become_dormant()):
        f.append("StopAlarm")
    report["stop_alarm"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionFailQuest")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionFailQuest"))
    if not apply.get("ok") or "FailQuestMessage" not in apply.get("applied", []):
        f.append("FailQuest defaults")
    a.configure("MedicalQuest", "Goal Failed")
    if not a.request_fail() or str(a.get_last_quest_name()) != "MedicalQuest":
        f.append("FailQuest")
    report["fail_quest"] = "ok"
    report["fail_quest_message"] = str(a.get_fail_quest_message())

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleCeilingCrawlerRangedAttack")
    a = unreal.new_object(cls)
    a.configure("CeilingCrawler_A", False)
    if not a.request_toggle() or bool(a.get_enable_ranged_attack()):
        f.append("CeilingCrawler")
    report["ceiling_crawler"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch18:\n- " + "\n- ".join(f))
    _log("PASS batch18")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
