"""Phase 4 census #5: ActionNonBlockingExecuteScript request record (no Script VM)."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-nonblocking-script] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    for name in ("ActionNonBlockingExecuteScript", "ActionExecuteScript"):
        if name not in classes:
            raise RuntimeError("%s missing from %s" % (name, schema_path))

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionNonBlockingExecuteScript")
    if action_class is None:
        raise RuntimeError("ShockActionNonBlockingExecuteScript missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionNonBlockingExecuteScript")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    report["block"] = bool(action.is_blocking())
    if report["block"]:
        failures.append("NonBlocking default bBlock should be false")

    action.configure("Script_MedicalCanary", False)
    if not action.request_execute():
        failures.append("RequestExecute returned false")
    report["lastRequested"] = str(action.get_last_requested_script())
    report["lastBlocking"] = bool(action.was_last_request_blocking())
    if report["lastRequested"] != "Script_MedicalCanary":
        failures.append("LastRequestedScript mismatch")
    if report["lastBlocking"]:
        failures.append("last request should be non-blocking")

    empty = unreal.new_object(action_class)
    if empty.request_execute():
        failures.append("RequestExecute with empty TargetScript should fail")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionNonBlockingExecuteScript failed:\n- " + "\n- ".join(failures))
    _log("PASS: NonBlockingExecuteScript records target without blocking")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
