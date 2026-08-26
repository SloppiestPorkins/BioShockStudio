"""Batch verify: BlockingExecute + Increment + Log + Exit + Freeze + UnlockDoor."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-batch] %s" % message)


def main(scripting_schema, shockgame_schema, report_path):
    with open(scripting_schema, encoding="utf-8") as handle:
        scripting = {row["name"]: row for row in json.load(handle)}
    with open(shockgame_schema, encoding="utf-8") as handle:
        shockgame = {row["name"]: row for row in json.load(handle)}
    report = {"failures": []}
    failures = report["failures"]

    # --- BlockingExecuteScript ---
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionBlockingExecuteScript")
    if cls is None:
        failures.append("BlockingExecuteScript class missing")
    else:
        a = unreal.new_object(cls)
        apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(
            a, scripting_schema, "ActionBlockingExecuteScript"))
        if not apply.get("ok") or not a.is_blocking():
            failures.append("Blocking defaults")
        a.configure("Script_X", True)
        if not a.request_execute() or not a.was_last_request_blocking():
            failures.append("Blocking RequestExecute")
        report["blocking"] = "ok"

    # --- VariableIncrement ---
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableIncrement")
    scope_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockVariableScope")
    if cls is None or scope_cls is None:
        failures.append("VariableIncrement/Scope missing")
    else:
        a = unreal.new_object(cls)
        scope = unreal.new_object(scope_cls)
        a.configure("MedicalCounter")
        if not a.apply_to_scope(scope):
            failures.append("Increment create failed")
        if str(scope.get_value_or_empty("MedicalCounter")) != "1":
            failures.append("Increment to 1 failed")
        if not a.apply_to_scope(scope):
            failures.append("Increment second failed")
        if str(scope.get_value_or_empty("MedicalCounter")) != "2":
            failures.append("Increment to 2 failed")
        report["increment"] = "ok"

    # --- Log ---
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLog")
    if cls is None:
        failures.append("Log class missing")
    else:
        a = unreal.new_object(cls)
        a.configure("hello medical")
        if not a.emit() or str(a.get_last_logged_text()) != "hello medical":
            failures.append("Log Emit failed")
        report["log"] = "ok"

    # --- ExitScript ---
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionExitScript")
    if cls is None:
        failures.append("ExitScript class missing")
    else:
        a = unreal.new_object(cls)
        a.configure("Script_Medical")
        if not a.request_exit() or str(a.get_last_exited_script()) != "Script_Medical":
            failures.append("ExitScript failed")
        report["exit"] = "ok"

    # --- FreezeHavok ---
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionFreezeHavokActor")
    if cls is None:
        failures.append("FreezeHavok class missing")
    else:
        a = unreal.new_object(cls)
        apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(
            a, scripting_schema, "ActionFreezeHavokActor"))
        if not apply.get("ok") or not a.get_freeze():
            failures.append("Freeze defaults")
        subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        target = subsystem.spawn_actor_from_class(
            unreal.StaticMeshActor, unreal.Vector(0.0, 100.0, 0.0))
        a.configure("Prop", True)
        if not a.apply_to_actor(target) or not a.get_last_applied_freeze():
            failures.append("Freeze apply")
        subsystem.destroy_actor(target)
        report["freeze"] = "ok"

    # --- UnlockDoor ---
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionUnlockDoor")
    if cls is None:
        failures.append("UnlockDoor class missing")
    else:
        a = unreal.new_object(cls)
        unreal.ShockSchemaLibrary.apply_action_defaults(
            a, shockgame_schema, "ActionUnlockDoor")
        a.configure("MedicalDoor_1")
        if not a.request_unlock() or str(a.get_last_unlocked_door_label()) != "MedicalDoor_1":
            failures.append("UnlockDoor failed")
        if unreal.new_object(cls).request_unlock():
            failures.append("empty DoorLabel should fail")
        report["unlock"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("batch failed:\n- " + "\n- ".join(failures))
    _log("PASS: batch Blocking/Increment/Log/Exit/Freeze/Unlock")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
