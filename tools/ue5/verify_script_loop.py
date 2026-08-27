"""ActionLoop / ExitLoop on ShockScriptRunner."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-loop] %s" % m)


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


def _exit_loop():
    return unreal.new_object(unreal.load_class(None, "/Script/BioShockRuntime.ShockActionExitLoop"))


def main(out):
    report = {"failures": []}
    f = report["failures"]

    runner_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScriptRunner")
    loop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLoop")

    # One pass: Increment then ExitLoop → Count=1, then Done=yes.
    runner = unreal.new_object(runner_cls)
    runner.configure("LoopOnce")
    runner.add_action(_assign("Count", "0"))
    loop = unreal.new_object(loop_cls)
    loop.add_loop_action(_inc("Count"))
    loop.add_loop_action(_exit_loop())
    runner.add_action(loop)
    runner.add_action(_assign("Done", "yes"))

    if not runner.start_execution():
        f.append("StartExecution")
    if bool(runner.tick_execution(0.0)):
        f.append("should finish in one tick")
    if str(runner.ensure_variables().get_value_or_empty("Count")) != "1":
        f.append("Count=%s" % runner.ensure_variables().get_value_or_empty("Count"))
    if str(runner.ensure_variables().get_value_or_empty("Done")) != "yes":
        f.append("Done missing")
    if int(runner.get_loop_depth()) != 0:
        f.append("loop depth %s" % runner.get_loop_depth())
    if not bool(loop.get_entered_loop()):
        f.append("EnteredLoop")
    report["loop_once"] = "ok"

    # Mid-body ExitLoop skips trailing Increment → Count stays 1.
    runner2 = unreal.new_object(runner_cls)
    runner2.configure("ExitMid")
    runner2.add_action(_assign("Count", "0"))
    loop2 = unreal.new_object(loop_cls)
    loop2.add_loop_action(_inc("Count"))
    loop2.add_loop_action(_exit_loop())
    loop2.add_loop_action(_inc("Count"))
    runner2.add_action(loop2)
    if not runner2.start_execution():
        f.append("StartExecution mid")
    runner2.tick_execution(0.0)
    if str(runner2.ensure_variables().get_value_or_empty("Count")) != "1":
        f.append("mid Count=%s" % runner2.ensure_variables().get_value_or_empty("Count"))
    report["exit_mid"] = "ok"

    # Three Increments then ExitLoop in one pass → N=3.
    runner3 = unreal.new_object(runner_cls)
    runner3.configure("Loop3")
    runner3.add_action(_assign("N", "0"))
    loop3 = unreal.new_object(loop_cls)
    loop3.add_loop_action(_inc("N"))
    loop3.add_loop_action(_inc("N"))
    loop3.add_loop_action(_inc("N"))
    loop3.add_loop_action(_exit_loop())
    runner3.add_action(loop3)
    if not runner3.start_execution():
        f.append("StartExecution 3")
    runner3.tick_execution(0.0)
    if str(runner3.ensure_variables().get_value_or_empty("N")) != "3":
        f.append("N=%s" % runner3.ensure_variables().get_value_or_empty("N"))
    report["three_incs"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-loop:\n- " + "\n- ".join(f))
    _log("PASS script loop")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_loop_report.json"))
