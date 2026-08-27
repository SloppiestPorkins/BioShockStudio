"""ActionFor counter iterations on ShockScriptRunner."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-for] %s" % m)


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
    for_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionFor")
    if not runner_cls or not for_cls:
        f.append("missing classes")
        raise RuntimeError("script-for: missing classes")

    # begin=1 End=3 inclusive → body runs 3 times → Hits=3, counter ends at 3.
    runner = unreal.new_object(runner_cls)
    runner.configure("ForThree")
    runner.add_action(_assign("Hits", "0"))
    for_action = unreal.new_object(for_cls)
    for_action.configure("i", 1.0, 3.0, -1)
    for_action.add_for_action(_inc("Hits"))
    runner.add_action(for_action)
    runner.add_action(_assign("Done", "yes"))

    if not runner.start_execution():
        f.append("StartExecution")
    if bool(runner.tick_execution(0.0)):
        f.append("should finish in one tick")
    hits = str(runner.ensure_variables().get_value_or_empty("Hits"))
    if hits != "3":
        f.append("Hits=%s" % hits)
    counter = str(runner.ensure_variables().get_value_or_empty("i"))
    try:
        if abs(float(counter) - 3.0) > 1e-4:
            f.append("counter i=%s" % counter)
    except ValueError:
        f.append("counter i=%s" % counter)
    if str(runner.ensure_variables().get_value_or_empty("Done")) != "yes":
        f.append("Done missing")
    if int(runner.get_for_depth()) != 0:
        f.append("for depth %s" % runner.get_for_depth())
    if not bool(for_action.get_entered_for()):
        f.append("EnteredFor")
    report["for_1_to_3"] = "ok"

    # begin=0 End=0 → one body run.
    runner2 = unreal.new_object(runner_cls)
    runner2.configure("ForOnce")
    runner2.add_action(_assign("N", "0"))
    for2 = unreal.new_object(for_cls)
    for2.configure("j", 0.0, 0.0, -1)
    for2.add_for_action(_inc("N"))
    runner2.add_action(for2)
    if not runner2.start_execution():
        f.append("StartExecution once")
    runner2.tick_execution(0.0)
    if str(runner2.ensure_variables().get_value_or_empty("N")) != "1":
        f.append("once N=%s" % runner2.ensure_variables().get_value_or_empty("N"))
    report["for_0_to_0"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-for:\n- " + "\n- ".join(f))
    _log("PASS script for")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_for_report.json"))
