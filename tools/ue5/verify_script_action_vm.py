"""Polymorphic action VM: mixed implemented + stub + flow-control through ShockScriptRunner."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-action-vm] %s" % m)


def _assign(name, value):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableAssignOverwrite")
    a = unreal.new_object(cls)
    a.configure(name, value)
    return a


def _inc(name):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableIncrement")
    a = unreal.new_object(cls)
    a.configure(name)
    return a


def main(out):
    report = {"failures": []}
    f = report["failures"]

    runner_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScriptRunner")
    note_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionScriptNote")
    stub_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionShowBathysphereUI")
    door_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionOpenDoor")
    wait_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWait")
    loop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLoop")
    if_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionIf")
    exit_loop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionExitLoop")

    runner = unreal.new_object(runner_cls)
    runner.configure("ActionVmMix")

    note = unreal.new_object(note_cls)
    note.configure("vm-note")

    stub = unreal.new_object(stub_cls)
    stub.configure("TestBathy")

    door = unreal.new_object(door_cls)
    door.configure("DoorA", False)

    wait = unreal.new_object(wait_cls)
    wait.configure(0.25)

    if_action = unreal.new_object(if_cls)
    truth_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTruthStatement")
    truth = unreal.new_object(truth_cls)
    truth.configure("true")
    if_action.add_test(truth)
    if_action.add_true_action(_assign("Branch", "yes"))
    if_action.add_else_action(_assign("Branch", "no"))

    loop = unreal.new_object(loop_cls)
    loop.add_loop_action(_inc("N"))
    loop.add_loop_action(unreal.new_object(exit_loop_cls))

    runner.add_action(note)
    runner.add_action(stub)
    runner.add_action(door)
    runner.add_action(_assign("N", "0"))
    runner.add_action(loop)
    runner.add_action(if_action)
    runner.add_action(wait)
    runner.add_action(_assign("Done", "1"))

    if not runner.start_execution():
        f.append("StartExecution")
    if not bool(runner.is_executing):
        f.append("IsExecuting after start")

    # t=0: note, stub, door, N=0, loop body (N=1), if (Branch=yes), block on wait
    if not bool(runner.tick_execution(0.0)):
        f.append("should block on wait at t=0")
    scope = runner.ensure_variables()
    if str(scope.get_value_or_empty("N")) != "1":
        f.append("N after loop=%s" % scope.get_value_or_empty("N"))
    if str(scope.get_value_or_empty("Branch")) != "yes":
        f.append("Branch=%s" % scope.get_value_or_empty("Branch"))
    if str(door.get_last_opened_door_label()) != "DoorA":
        f.append("door label=%s" % door.get_last_opened_door_label())
    if str(stub.get_last_bathysphere_system()) not in ("None", ""):
        f.append("stub side effect=%s" % stub.get_last_bathysphere_system())
    report["t0"] = "ok"

    if not bool(runner.tick_execution(0.1)):
        f.append("should still wait at t=0.1")
    if bool(runner.tick_execution(0.3)):
        f.append("should finish after wait")
    if str(scope.get_value_or_empty("Done")) != "1":
        f.append("Done=%s" % scope.get_value_or_empty("Done"))
    if bool(runner.is_executing):
        f.append("still executing after finish")
    report["finished"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-action-vm:\n- " + "\n- ".join(f))
    _log("PASS script action vm")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "script_action_vm_report.json"),
        )
    )
