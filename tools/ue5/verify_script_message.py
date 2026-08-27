"""Message-triggered Script start via TriggeredBy + ShockScriptRegistry.DispatchMessage."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-message] %s" % m)


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
    registry = unreal.new_object(reg_cls)

    script = unreal.new_object(runner_cls)
    script.configure("OnDoor")
    script.set_triggered_by("DoorA,DoorB")
    script.set_registry(registry)
    script.add_action(_assign("Fired", "yes"))

    other = unreal.new_object(runner_cls)
    other.configure("OnOther")
    other.set_triggered_by("Crate")
    other.set_registry(registry)
    other.add_action(_assign("Fired", "crate"))

    started = int(registry.dispatch_message("Touch", "Nope"))
    if started != 0:
        f.append("Nope should start 0, got %s" % started)
    report["mismatch"] = "ok"

    started = int(registry.dispatch_message("Touch", "DoorA"))
    if started != 1:
        f.append("DoorA started %s" % started)
    if not bool(script.is_executing):
        # may already have finished if no wait — tick anyway
        pass
    script.tick_execution(0.0)
    if str(script.ensure_variables().get_value_or_empty("Fired")) != "yes":
        f.append("Fired=%s" % script.ensure_variables().get_value_or_empty("Fired"))
    if str(script.get_last_message_source()) != "DoorA":
        f.append("LastMessageSource %s" % script.get_last_message_source())
    report["door_a"] = "ok"

    started = int(registry.dispatch_message("Touch", "DoorB"))
    if started != 1:
        f.append("DoorB started %s" % started)
    script.tick_execution(0.0)
    report["door_b"] = "ok"

    # Re-entry skip while waiting
    waiting = unreal.new_object(runner_cls)
    waiting.configure("Busy")
    waiting.set_triggered_by("BusySrc")
    waiting.set_registry(registry)
    waiting.add_action(_wait(1.0))
    waiting.add_action(_assign("Once", "1"))
    if int(registry.dispatch_message("Trigger", "BusySrc")) != 1:
        f.append("Busy start")
    if int(registry.dispatch_message("Trigger", "BusySrc")) != 0:
        f.append("Busy re-entry should skip")
    waiting.tick_execution(0.0)
    if not bool(waiting.is_executing):
        f.append("Busy should still wait")
    waiting.tick_execution(1.0)
    if str(waiting.ensure_variables().get_value_or_empty("Once")) != "1":
        f.append("Once missing")
    report["reentry"] = "ok"

    # Empty TriggeredBy does not start (UC only registers when non-empty)
    any_script = unreal.new_object(runner_cls)
    any_script.configure("Any")
    any_script.set_triggered_by("")
    any_script.set_registry(registry)
    any_script.add_action(_assign("Any", "ok"))
    if int(registry.dispatch_message("X", "Whatever")) != 0:
        f.append("empty TriggeredBy should not dispatch")
    report["empty_trigger"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-message:\n- " + "\n- ".join(f))
    _log("PASS script message")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_message_report.json"))
