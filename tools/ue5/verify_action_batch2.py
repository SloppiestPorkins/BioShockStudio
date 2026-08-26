"""Batch verify: MuteAI + SetTipPriority + PostMovementGoal."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-batch2] %s" % message)


def main(shockai_schema, shockgame_schema, report_path):
    report = {"failures": []}
    failures = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionMuteAI")
    if cls is None:
        failures.append("MuteAI missing")
    else:
        a = unreal.new_object(cls)
        a.configure("MedicalSplicers", True)
        if not a.request_mute() or str(a.get_last_muted_ai_label()) != "MedicalSplicers":
            failures.append("MuteAI")
        report["mute"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetTipPriority")
    if cls is None:
        failures.append("SetTipPriority missing")
    else:
        a = unreal.new_object(cls)
        a.configure("Tip_Medical", 3)
        if not a.request_set() or int(a.get_last_priority()) != 3:
            failures.append("SetTipPriority")
        report["tip"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPostMovementGoal")
    if cls is None:
        failures.append("PostMovementGoal missing")
    else:
        a = unreal.new_object(cls)
        apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(
            a, shockai_schema, "ActionPostMovementGoal"))
        if not apply.get("ok"):
            failures.append("PostMovementGoal apply")
        if int(a.get_priority()) != 50:
            failures.append("Priority default 50")
        a.configure("MedicalSplicer", "MedicalNavPoint", "MovementGoal", 50, True)
        if not a.request_post():
            failures.append("RequestPost")
        if str(a.get_last_destination_label()) != "MedicalNavPoint":
            failures.append("destination")
        report["move"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("batch2 failed:\n- " + "\n- ".join(failures))
    _log("PASS: MuteAI / TipPriority / PostMovementGoal")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
