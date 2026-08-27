"""Script runner first slice: Wait / If / Exit / Note / VariableAssign linear queue."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-runner] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    runner_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScriptRunner")
    runner = unreal.new_object(runner_cls)
    runner.configure("TestScript_A")

    note_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionScriptNote")
    note = unreal.new_object(note_cls)
    note.configure("begin")

    assign_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableAssignOverwrite")
    assign1 = unreal.new_object(assign_cls)
    assign1.configure("Flag", "before_wait")

    wait_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWait")
    wait = unreal.new_object(wait_cls)
    wait.configure(0.5)

    assign2 = unreal.new_object(assign_cls)
    assign2.configure("Flag", "after_wait")

    exit_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionExitScript")
    exit_action = unreal.new_object(exit_cls)
    exit_action.configure("TestScript_A")

    runner.add_action(note)
    runner.add_action(assign1)
    runner.add_action(wait)
    runner.add_action(assign2)
    runner.add_action(exit_action)

    if not runner.start_execution():
        f.append("StartExecution")
    if not bool(runner.is_executing):
        f.append("IsExecuting after start")

    # t=0: note + assign1, then block on wait
    still = bool(runner.tick_execution(0.0))
    if not still:
        f.append("should be waiting at t=0")
    scope = runner.ensure_variables()
    if str(scope.get_value_or_empty("Flag")) != "before_wait":
        f.append("Flag before wait: %s" % scope.get_value_or_empty("Flag"))
    report["after_t0"] = "ok"

    still = bool(runner.tick_execution(0.4))
    if not still:
        f.append("should still wait at t=0.4")
    if str(scope.get_value_or_empty("Flag")) != "before_wait":
        f.append("Flag mutated early")
    report["after_t04"] = "ok"

    still = bool(runner.tick_execution(0.5))
    if still:
        f.append("should finish at t=0.5")
    if str(scope.get_value_or_empty("Flag")) != "after_wait":
        f.append("Flag after wait: %s" % scope.get_value_or_empty("Flag"))
    if int(runner.actions_completed) < 4:
        f.append("ActionsCompleted %s" % runner.actions_completed)
    report["linear_wait"] = "ok"

    # If true branch expands into the queue
    runner2 = unreal.new_object(runner_cls)
    runner2.configure("IfScript")
    if_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionIf")
    if_action = unreal.new_object(if_cls)
    truth_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTruthStatement")
    truth = unreal.new_object(truth_cls)
    truth.configure("true")
    if_action.add_test(truth)
    true_assign = unreal.new_object(assign_cls)
    true_assign.configure("Branch", "true_path")
    else_assign = unreal.new_object(assign_cls)
    else_assign.configure("Branch", "else_path")
    if_action.add_true_action(true_assign)
    if_action.add_else_action(else_assign)
    runner2.add_action(if_action)
    if not runner2.start_execution():
        f.append("If StartExecution")
    runner2.tick_execution(0.0)
    if bool(runner2.is_executing):
        f.append("If should finish in one tick")
    if str(runner2.ensure_variables().get_value_or_empty("Branch")) != "true_path":
        f.append("If branch: %s" % runner2.ensure_variables().get_value_or_empty("Branch"))
    if str(if_action.get_last_branch()) != "true":
        f.append("LastBranch %s" % if_action.get_last_branch())
    report["if_true"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-runner:\n- " + "\n- ".join(f))
    _log("PASS script runner")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_runner_report.json"))
