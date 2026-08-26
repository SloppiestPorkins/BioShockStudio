"""Phase 4 census #14: ActionDestroyActor Destroy stand-in."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-destroy] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionDestroyActor" not in classes:
        raise RuntimeError("ActionDestroyActor missing from %s" % schema_path)

    action_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDestroyActor")
    if action_class is None:
        raise RuntimeError("ShockActionDestroyActor missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionDestroyActor")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target = subsystem.spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(0.0, 60.0, 0.0))
    if target is None:
        raise RuntimeError("spawn TargetPoint failed")
    name_before = str(target.get_name())

    action.configure("MedicalTrash")
    if not action.destroy_target(target):
        failures.append("DestroyTarget returned false")
    report["lastDestroyed"] = str(action.get_last_destroyed_actor_name())
    report["nameBefore"] = name_before
    # Actor should be pending kill / invalid
    try:
        still = target.is_valid_low_level() and (not target.is_actor_being_destroyed())
        # After Destroy, is_actor_being_destroyed or invalid
        report["stillAlive"] = bool(still) if target else False
    except Exception:  # noqa: BLE001
        report["stillAlive"] = False

    if action.destroy_target(None):
        failures.append("DestroyTarget(None) should fail")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionDestroyActor failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionDestroyActor destroys passed actor")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
