"""Blocking / non-blocking ExecuteScript parent-child on ShockScriptRunner."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-blocking] %s" % m)


def _assign(name, value):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableAssignOverwrite")
    a = unreal.new_object(cls)
    a.configure(name, value)
    return a


def _wait(seconds):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWait")
    a = unreal.new_object(cls)
    a.configure(seconds)
    return a


def main(out):
    report = {"failures": []}
    f = report["failures"]

    reg_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScriptRegistry")
    runner_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScriptRunner")
    block_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionBlockingExecuteScript")
    nonblock_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionNonBlockingExecuteScript")

    registry = unreal.new_object(reg_cls)

    # --- Blocking: parent waits for child Wait(0.5) ---
    child = unreal.new_object(runner_cls)
    child.configure("Child_Block")
    child.set_registry(registry)
    child.add_action(_assign("ChildFlag", "child_done"))
    child.add_action(_wait(0.5))

    parent = unreal.new_object(runner_cls)
    parent.configure("Parent_Block")
    parent.set_registry(registry)
    parent.add_action(_assign("ParentFlag", "before_child"))
    block = unreal.new_object(block_cls)
    block.configure("Child_Block", True)
    parent.add_action(block)
    parent.add_action(_assign("ParentFlag", "after_child"))

    if not parent.start_execution():
        f.append("block StartExecution")

    still = bool(parent.tick_execution(0.0))
    if not still:
        f.append("block should wait at t=0")
    if str(parent.ensure_variables().get_value_or_empty("ParentFlag")) != "before_child":
        f.append("parent advanced early")
    if not bool(child.is_executing):
        f.append("child should be executing at t=0")
    if str(child.ensure_variables().get_value_or_empty("ChildFlag")) != "child_done":
        f.append("child assign missing")
    report["block_t0"] = "ok"

    still = bool(parent.tick_execution(0.4))
    if not still or not bool(child.is_executing):
        f.append("block should still wait at t=0.4")
    if str(parent.ensure_variables().get_value_or_empty("ParentFlag")) != "before_child":
        f.append("parent Flag early at 0.4")
    report["block_t04"] = "ok"

    still = bool(parent.tick_execution(0.5))
    if still:
        f.append("block should finish at t=0.5")
    if str(parent.ensure_variables().get_value_or_empty("ParentFlag")) != "after_child":
        f.append("parent Flag after: %s" % parent.ensure_variables().get_value_or_empty("ParentFlag"))
    if bool(child.is_executing):
        f.append("child should be done")
    report["blocking"] = "ok"

    # --- Non-blocking: parent continues while child waits ---
    child2 = unreal.new_object(runner_cls)
    child2.configure("Child_NB")
    child2.set_registry(registry)
    child2.add_action(_wait(0.5))
    child2.add_action(_assign("NB", "child_finished"))

    parent2 = unreal.new_object(runner_cls)
    parent2.configure("Parent_NB")
    parent2.set_registry(registry)
    parent2.add_action(_assign("NB", "parent_ran"))
    nb = unreal.new_object(nonblock_cls)
    nb.configure("Child_NB", False)
    parent2.add_action(nb)
    parent2.add_action(_assign("ParentDone", "yes"))

    if not parent2.start_execution():
        f.append("nb StartExecution")

    still = bool(parent2.tick_execution(0.0))
    # parent finished its actions but child still waiting → still True via spawned children
    if str(parent2.ensure_variables().get_value_or_empty("ParentDone")) != "yes":
        f.append("parent should finish immediately")
    if str(parent2.ensure_variables().get_value_or_empty("NB")) != "parent_ran":
        f.append("parent NB overwrite")
    if not bool(child2.is_executing):
        f.append("nb child should still be waiting")
    report["nb_t0"] = "ok"

    still = bool(parent2.tick_execution(0.5))
    if still:
        f.append("nb should finish at t=0.5")
    if str(child2.ensure_variables().get_value_or_empty("NB")) != "child_finished":
        f.append("nb child Flag: %s" % child2.ensure_variables().get_value_or_empty("NB"))
    report["nonblocking"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-blocking:\n- " + "\n- ".join(f))
    _log("PASS script blocking")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_blocking_report.json"))
