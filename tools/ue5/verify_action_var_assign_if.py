"""Phase 4 census #7: ActionVariableAssignIfNotExist create-only assign."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-var-assign-if] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionVariableAssignIfNotExist" not in classes:
        raise RuntimeError("ActionVariableAssignIfNotExist missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionVariableAssignIfNotExist")
    scope_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockVariableScope")
    if action_class is None or scope_class is None:
        raise RuntimeError("ShockActionVariableAssignIfNotExist or ShockVariableScope missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionVariableAssignIfNotExist")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    scope = unreal.new_object(scope_class)
    action.configure("MedicalFlag", "true")
    if not action.apply_to_scope(scope):
        failures.append("first ApplyToScope should create")
    report["afterCreate"] = int(scope.num())
    if report["afterCreate"] != 1:
        failures.append("scope size after create")

    if not scope.contains("MedicalFlag"):
        failures.append("Contains MedicalFlag failed")
    value = str(scope.get_value_or_empty("MedicalFlag"))
    report["value"] = value
    if value != "true":
        failures.append("value after create: %s" % value)

    action.configure("MedicalFlag", "false")
    if action.apply_to_scope(scope):
        failures.append("second ApplyToScope should refuse existing lhs")
    value2 = str(scope.get_value_or_empty("MedicalFlag"))
    report["valueAfterSkip"] = value2
    if value2 != "true":
        failures.append("existing value was overwritten: %s" % value2)

    empty = unreal.new_object(action_class)
    if empty.apply_to_scope(scope):
        failures.append("empty Lhs should fail")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionVariableAssignIfNotExist failed:\n- " + "\n- ".join(failures))
    _log("PASS: AssignIfNotExist creates once and refuses overwrite")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
