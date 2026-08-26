"""Phase 4 census #4: ActionPlayEffect params + recorded TriggerEffectEvent stand-in."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-play-effect] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionPlayEffect" not in classes:
        raise RuntimeError("ActionPlayEffect missing from %s" % schema_path)

    action_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayEffect")
    if action_class is None:
        raise RuntimeError("ShockActionPlayEffect class missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(action, schema_path, "ActionPlayEffect")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    event = str(action.get_editor_property("effect_event"))
    report["effectEvent"] = event
    if event != "ScriptTrigger":
        failures.append("EffectEvent %s != ScriptTrigger" % event)

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target = subsystem.spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(0.0, 0.0, 50.0))
    if target is None:
        raise RuntimeError("spawn TargetPoint failed")

    action.configure("ScriptTrigger", "FX_TestTag", "SomeLabel")
    if not action.fire_on_actor(target):
        failures.append("FireOnActor returned false")
    else:
        report["lastFiredEvent"] = str(action.get_editor_property("last_fired_event"))
        report["lastFiredTag"] = str(action.get_editor_property("last_fired_tag"))
        report["lastFiredActorName"] = str(action.get_editor_property("last_fired_actor_name"))
        if report["lastFiredEvent"] != "ScriptTrigger":
            failures.append("LastFiredEvent mismatch")
        if report["lastFiredTag"] != "FX_TestTag":
            failures.append("LastFiredTag mismatch")

    if action.fire_on_actor(None):
        failures.append("FireOnActor(None) should be false")

    subsystem.destroy_actor(target)
    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionPlayEffect failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionPlayEffect EffectEvent from schema; FireOnActor records trigger")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
