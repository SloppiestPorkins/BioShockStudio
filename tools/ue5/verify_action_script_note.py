"""Phase 4 census #13: ActionScriptNote holds Note; runtime no-op."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-script-note] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionScriptNote" not in classes:
        raise RuntimeError("ActionScriptNote missing from %s" % schema_path)

    action_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionScriptNote")
    if action_class is None:
        raise RuntimeError("ShockActionScriptNote missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionScriptNote")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    action.configure("Medical hallway spawn note")
    report["note"] = str(action.get_note())
    if report["note"] != "Medical hallway spawn note":
        failures.append("Note mismatch")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionScriptNote failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionScriptNote stores Note string")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
