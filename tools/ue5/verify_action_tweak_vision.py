"""Phase 4 census #18: ActionTweakAIVision request record (no sense wiring)."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-tweak-vision] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionTweakAIVision" not in classes:
        raise RuntimeError("ActionTweakAIVision missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionTweakAIVision")
    if action_class is None:
        raise RuntimeError("ShockActionTweakAIVision missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionTweakAIVision")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    action.configure("MedicalSplicers", True, False, False)
    if not action.request_tweak():
        failures.append("RequestTweak failed")
    report["lastAI"] = str(action.get_last_tweaked_ai_label())
    report["lastOn"] = bool(action.get_last_turn_vision_on())
    if report["lastAI"] != "MedicalSplicers" or not report["lastOn"]:
        failures.append("vision record mismatch")

    empty = unreal.new_object(action_class)
    if empty.request_tweak():
        failures.append("empty AILabel should fail")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionTweakAIVision failed:\n- " + "\n- ".join(failures))
    _log("PASS: TweakAIVision records request")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
