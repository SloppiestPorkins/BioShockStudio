"""Phase 4 census #17: ActionChangeCollision CollideActors → SetActorEnableCollision."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-change-collision] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionChangeCollision" not in classes:
        raise RuntimeError("ActionChangeCollision missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionChangeCollision")
    if action_class is None:
        raise RuntimeError("ShockActionChangeCollision missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionChangeCollision")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    # Schema defaults are DoNotChange (2)
    collide_default = action.get_collide_actors()
    report["collideActorsDefault"] = str(collide_default)
    if collide_default != unreal.ShockCollisionChange.DO_NOT_CHANGE:
        failures.append("CollideActors default should be DoNotChange (got %s)" % collide_default)
    if "CollideActors" not in report["applied"]:
        failures.append("schema should apply CollideActors=2")

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target = subsystem.spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(0.0, 80.0, 0.0))
    if target is None:
        raise RuntimeError("spawn TargetPoint failed")

    action.configure("MedicalProp", unreal.ShockCollisionChange.SET_TO_TRUE)
    if not action.apply_to_actor(target):
        failures.append("SetToTrue ApplyToActor failed")
    report["enabledAfterTrue"] = bool(action.get_last_applied_enable_collision())
    if not report["enabledAfterTrue"]:
        failures.append("expected enable true")

    action.configure("MedicalProp", unreal.ShockCollisionChange.SET_TO_FALSE)
    if not action.apply_to_actor(target):
        failures.append("SetToFalse ApplyToActor failed")
    report["enabledAfterFalse"] = bool(action.get_last_applied_enable_collision())
    if report["enabledAfterFalse"]:
        failures.append("expected enable false")

    no_change = unreal.new_object(action_class)
    no_change.configure("MedicalProp", unreal.ShockCollisionChange.DO_NOT_CHANGE)
    if no_change.apply_to_actor(target):
        failures.append("DoNotChange should not apply")

    if action.apply_to_actor(None):
        failures.append("ApplyToActor(None) should fail")

    subsystem.destroy_actor(target)
    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionChangeCollision failed:\n- " + "\n- ".join(failures))
    _log("PASS: ChangeCollision applies CollideActors to SetActorEnableCollision")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
