"""Phase 4 head: ActionWait Seconds from Scripting.U schema, wake check without a script VM."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-wait] %s" % message)


def _schema_float(classes, class_name, prop):
    entry = classes.get(class_name) or {}
    for default in entry.get("defaults") or []:
        if default.get("name") != prop:
            continue
        if default.get("index") not in (None, 0):
            continue
        text = default.get("value") or ""
        if text.startswith("<") or text.startswith('"'):
            return None
        try:
            return float(text)
        except ValueError:
            return None
    return None


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionWait" not in classes:
        raise RuntimeError("ActionWait missing from %s — export Scripting.U schema" % schema_path)

    wait_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWait")
    if wait_class is None:
        raise RuntimeError("ShockActionWait class missing")

    action = unreal.new_object(wait_class)
    if action is None:
        raise RuntimeError("new_object ShockActionWait failed")

    raw = unreal.ShockSchemaLibrary.apply_action_defaults(action, schema_path, "ActionWait")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applyError"] = apply.get("error")
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    want = _schema_float(classes, "ActionWait", "Seconds")
    got = float(action.get_editor_property("seconds"))
    report["expectedSeconds"] = want
    report["measuredSeconds"] = got
    if want is None:
        failures.append("schema has no Seconds float")
    elif abs(got - want) > 0.05:
        failures.append("Seconds %s != schema %s" % (got, want))

    # Decompiled latentExecute: WakeTime = TimeSeconds + Seconds; ready when Now >= WakeTime.
    # Seconds is VisibleAnywhere (schema-applied); do not set_editor_property — it is read-only.
    now = 10.0
    action.prepare_wait(now)
    wake = float(action.get_editor_property("wake_at_time"))
    report["wakeAt"] = wake
    expect_wake = now + (want if want is not None else got)
    if abs(wake - expect_wake) > 0.05:
        failures.append("WakeAtTime %s != %s" % (wake, expect_wake))
    if action.is_ready(expect_wake - 0.1):
        failures.append("IsReady(before wake) should be false")
    if not action.is_ready(expect_wake):
        failures.append("IsReady(at wake) should be true")
    if not action.is_ready(expect_wake + 1.0):
        failures.append("IsReady(after wake) should be true")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionWait failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionWait Seconds from Scripting.U; wake check matches latentExecute shape")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
