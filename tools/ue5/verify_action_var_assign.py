"""Phase 4 census #8: ActionVariableAssign overwrite into variable scope."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-var-assign] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionVariableAssign" not in classes:
        raise RuntimeError("ActionVariableAssign missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionVariableAssignOverwrite")
    scope_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockVariableScope")
    if action_class is None or scope_class is None:
        raise RuntimeError("ShockActionVariableAssignOverwrite or ShockVariableScope missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionVariableAssign")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    report["actionClassName"] = str(action.get_editor_property("action_class_name"))
    if report["actionClassName"] != "ActionVariableAssign":
        failures.append("ActionClassName mismatch")

    scope = unreal.new_object(scope_class)
    action.configure("MedicalCounter", "1")
    if not action.apply_to_scope(scope):
        failures.append("first assign failed")
    action.configure("MedicalCounter", "2")
    if not action.apply_to_scope(scope):
        failures.append("overwrite assign failed")
    value = str(scope.get_value_or_empty("MedicalCounter"))
    report["value"] = value
    if value != "2":
        failures.append("overwrite did not stick: %s" % value)
    report["num"] = int(scope.num())
    if report["num"] != 1:
        failures.append("expected one key after overwrite")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionVariableAssign failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionVariableAssign overwrites existing lhs")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
