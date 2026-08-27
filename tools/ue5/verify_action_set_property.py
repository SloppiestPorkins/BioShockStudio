"""Phase 4 census #2: ActionSetProperty params + Label write stand-in."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-set-property] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionSetProperty" not in classes:
        raise RuntimeError("ActionSetProperty missing from %s" % schema_path)

    action_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetProperty")
    if action_class is None:
        raise RuntimeError("ShockActionSetProperty class missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(action, schema_path, "ActionSetProperty")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applyError"] = apply.get("error")
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    report["actionClassName"] = str(action.get_editor_property("action_class_name"))
    if action.get_editor_property("action_class_name") != "ActionSetProperty":
        failures.append("ActionClassName not ActionSetProperty")

    # Decompiled execute: allActorLabel + SetPropertyText. Label is the one property we can
    # round-trip without a full SetPropertyText port (bHidden has a special SetHidden path).
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target = subsystem.spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(0.0, 0.0, 50.0))
    if target is None:
        raise RuntimeError("spawn TargetPoint failed")

    action.configure("ignored_label_lookup", "Label", "BioShockSetPropCanary")
    if not action.apply_to_actor(target):
        failures.append("ApplyToActor returned false")
    else:
        label = target.get_actor_label()
        report["targetLabel"] = label
        if label != "BioShockSetPropCanary":
            failures.append("actor label %s != BioShockSetPropCanary" % label)

	# Unknown property name must not invent a write.
    action.configure("x", "SomeUnknownProp", "1")
    if action.apply_to_actor(target):
        failures.append("ApplyToActor should refuse unknown properties")

    # bHidden stand-in (UE2 special path → SetActorHiddenInGame). ApplyToActor itself
    # round-trips via AActor::IsHidden — trust that return rather than a Python property name.
    action.configure("x", "bHidden", "true")
    if not action.apply_to_actor(target):
        failures.append("bHidden true apply failed")
    action.configure("x", "bHidden", "false")
    if not action.apply_to_actor(target):
        failures.append("bHidden false apply failed")
    report["bHidden"] = "ok"

    subsystem.destroy_actor(target)
    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionSetProperty failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionSetProperty Label write; unknown props refused")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
