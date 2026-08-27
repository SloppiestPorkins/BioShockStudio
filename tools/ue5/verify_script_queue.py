"""MessageQueue: second Dispatch while busy is queued and runs after the first finishes."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-queue] %s" % m)


def _inc(name):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableIncrement")
    a = unreal.new_object(cls)
    a.configure(name)
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
    registry = unreal.new_object(reg_cls)

    script = unreal.new_object(runner_cls)
    script.configure("Queued")
    script.set_triggered_by("Src")
    script.set_registry(registry)
    script.add_action(_wait(0.5))
    script.add_action(_inc("Count"))

    if int(registry.dispatch_message("Touch", "Src")) != 1:
        f.append("first start")
    if int(registry.dispatch_message("Touch", "Src")) != 1:
        f.append("second should queue")
    if int(script.get_message_queue_num()) != 1:
        f.append("queue=%s" % script.get_message_queue_num())
    if str(script.get_last_message_source()) != "Src":
        f.append("source")

    if not bool(script.tick_execution(0.0)):
        f.append("should wait at t=0")
    if int(script.get_message_queue_num()) != 1:
        f.append("queue while waiting")
    report["queued"] = "ok"

    # First Wait wakes, Inc → Count=1, Finish dequeues second → PrepareWait same frame.
    still = bool(script.tick_execution(0.5))
    if str(script.ensure_variables().get_value_or_empty("Count")) != "1":
        f.append("Count after first=%s" % script.ensure_variables().get_value_or_empty("Count"))
    if int(script.get_message_queue_num()) != 0:
        f.append("queue should be empty after dequeue start")
    if not still or not bool(script.is_executing):
        f.append("second run should have started Wait")
    report["after_first"] = "ok"

    if bool(script.tick_execution(1.0)):
        f.append("should finish second at t=1.0")
    if str(script.ensure_variables().get_value_or_empty("Count")) != "2":
        f.append("Count after both=%s" % script.ensure_variables().get_value_or_empty("Count"))
    report["both_runs"] = "ok"

    # Three messages: one starts, two queue; all drain.
    script2 = unreal.new_object(runner_cls)
    script2.configure("Drain")
    script2.set_triggered_by("D")
    script2.set_registry(registry)
    script2.add_action(_wait(0.2))
    script2.add_action(_inc("N"))
    registry.dispatch_message("T", "D")
    registry.dispatch_message("T", "D")
    registry.dispatch_message("T", "D")
    if int(script2.get_message_queue_num()) != 2:
        f.append("drain queue=%s" % script2.get_message_queue_num())
    t = 0.0
    for _ in range(20):
        script2.tick_execution(t)
        if not bool(script2.is_executing) and int(script2.get_message_queue_num()) == 0:
            break
        t += 0.2
    if str(script2.ensure_variables().get_value_or_empty("N")) != "3":
        f.append("N=%s" % script2.ensure_variables().get_value_or_empty("N"))
    report["drain_three"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-queue:\n- " + "\n- ".join(f))
    _log("PASS script queue")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_queue_report.json"))
