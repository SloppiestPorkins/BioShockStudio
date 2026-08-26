"""Phase 4 census #11: ActionStopEffect UnTriggerEffectEvent stand-in."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-stop-effect] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionStopEffect" not in classes:
        raise RuntimeError("ActionStopEffect missing from %s" % schema_path)

    action_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopEffect")
    if action_class is None:
        raise RuntimeError("ShockActionStopEffect missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(action, schema_path, "ActionStopEffect")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    event = str(action.get_effect_event())
    report["effectEvent"] = event
    if event != "ScriptTrigger":
        failures.append("EffectEvent %s != ScriptTrigger" % event)

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target = subsystem.spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(0.0, 20.0, 0.0))
    if target is None:
        raise RuntimeError("spawn TargetPoint failed")

    action.configure("ScriptTrigger", "FX_StopTag", "SomeLabel")
    if not action.stop_on_actor(target):
        failures.append("StopOnActor returned false")
    else:
        report["lastStoppedEvent"] = str(action.get_last_stopped_event())
        report["lastStoppedTag"] = str(action.get_last_stopped_tag())
        report["lastStoppedActorName"] = str(action.get_last_stopped_actor_name())
        if report["lastStoppedEvent"] != "ScriptTrigger":
            failures.append("LastStoppedEvent mismatch")
        if report["lastStoppedTag"] != "FX_StopTag":
            failures.append("LastStoppedTag mismatch")

    if action.stop_on_actor(None):
        failures.append("StopOnActor(None) should be false")

    subsystem.destroy_actor(target)
    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionStopEffect failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionStopEffect records UnTrigger stand-in")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
