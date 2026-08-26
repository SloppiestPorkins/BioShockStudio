"""Phase 4 census #15: ActionAttackTarget attack-order record (no combat)."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-attack] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionAttackTarget" not in classes:
        raise RuntimeError("ActionAttackTarget missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionAttackTarget")
    if action_class is None:
        raise RuntimeError("ShockActionAttackTarget missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionAttackTarget")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    action.configure("MedicalSplicers", "Player", False)
    if not action.request_attack():
        failures.append("immediate RequestAttack failed")
    report["lastAI"] = str(action.get_last_requested_ai_label())
    report["lastTarget"] = str(action.get_last_requested_target_label())
    report["lastOnSight"] = bool(action.was_last_requested_on_sight())
    if report["lastAI"] != "MedicalSplicers" or report["lastTarget"] != "Player":
        failures.append("immediate labels mismatch")
    if report["lastOnSight"]:
        failures.append("immediate should not be on-sight")

    action.configure("MedicalSplicers", "Player", True)
    if not action.request_attack():
        failures.append("on-sight RequestAttack failed")
    if not bool(action.was_last_requested_on_sight()):
        failures.append("on-sight flag not recorded")

    empty = unreal.new_object(action_class)
    if empty.request_attack():
        failures.append("empty labels should fail")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionAttackTarget failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionAttackTarget records attack order")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
