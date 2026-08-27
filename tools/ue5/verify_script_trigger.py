"""ActionSendTriggerMessage dispatches MessageTrigger through the script registry."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-trigger] %s" % m)


def _assign(name, value):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableAssignOverwrite")
    a = unreal.new_object(cls)
    a.configure(name, value)
    return a


def _send(instigator=None):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSendTriggerMessage")
    a = unreal.new_object(cls)
    if instigator is not None:
        a.configure(instigator)
    return a


def main(out):
    report = {"failures": []}
    f = report["failures"]

    reg_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScriptRegistry")
    runner_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScriptRunner")
    registry = unreal.new_object(reg_cls)

    listener = unreal.new_object(runner_cls)
    listener.configure("Listener")
    listener.set_triggered_by("DoorA")
    listener.set_registry(registry)
    listener.add_action(_assign("Opened", "yes"))

    sender = unreal.new_object(runner_cls)
    sender.configure("Sender")
    sender.set_registry(registry)
    send_action = _send("DoorA")
    sender.add_action(send_action)

    if not bool(sender.start_execution()):
        f.append("sender start")
    sender.tick_execution(0.0)
    if int(send_action.get_last_dispatch_accepted()) != 1:
        f.append("accepted=%s" % send_action.get_last_dispatch_accepted())
    if str(send_action.get_last_instigator_label()) != "DoorA":
        f.append("instigator label")
    listener.tick_execution(0.0)
    if str(listener.ensure_variables().get_value_or_empty("Opened")) != "yes":
        f.append("Opened=%s" % listener.ensure_variables().get_value_or_empty("Opened"))
    if str(listener.get_last_message_class()) != "MessageTrigger":
        f.append("msg class %s" % listener.get_last_message_class())
    report["door_a"] = "ok"

    # Instigator unset (NAME_None) → parent ScriptLabel as TriggeredBy source
    listener2 = unreal.new_object(runner_cls)
    listener2.configure("L2")
    listener2.set_triggered_by("ParentSrc")
    listener2.set_registry(registry)
    listener2.add_action(_assign("FromParent", "1"))

    parent = unreal.new_object(runner_cls)
    parent.configure("ParentSrc")
    parent.set_registry(registry)
    send_none = _send()
    parent.add_action(send_none)
    parent.start_execution()
    parent.tick_execution(0.0)
    if int(send_none.get_last_dispatch_accepted()) != 1:
        f.append("parent fallback accepted=%s" % send_none.get_last_dispatch_accepted())
    listener2.tick_execution(0.0)
    if str(listener2.ensure_variables().get_value_or_empty("FromParent")) != "1":
        f.append("FromParent missing")
    if str(send_none.get_last_instigator_label()) != "ParentSrc":
        f.append("fallback source %s" % send_none.get_last_instigator_label())
    report["parent_fallback"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-trigger:\n- " + "\n- ".join(f))
    _log("PASS script trigger")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_trigger_report.json"))
