"""ActionSendTriggerMessage dispatches the base "Message" class through the script registry."""

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
    listener.set_triggered_by("Sender")  # SendTriggerMessage goes out under the SENDING script's label
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
    # SDK guide: ActionSendTriggerMessage sends MessageTrigger under the running script's own
    # label (Instigator is only a carried field). Earlier code used the Instigator as the source
    # and class "Message" -- the SDK cross-reference audit caught it (SCR-B01/B02).
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

    # scriptMessageClass gating (23-Scripting-Examples.md Example 10, the elevator): two scripts
    # share TriggeredBy="Lift" but listen for different classes. Each must fire only for its own.
    opened = unreal.new_object(runner_cls)
    opened.configure("ElevatorDoorOpen")
    opened.set_triggered_by("Lift")
    opened.set_script_message_class("MessageMoverOpened")
    opened.set_registry(registry)
    opened.add_action(_assign("DingPlayed", "yes"))

    closing = unreal.new_object(runner_cls)
    closing.configure("ElevatorDoorClose")
    closing.set_triggered_by("Lift")
    closing.set_script_message_class("MessageMoverClosing")
    closing.set_registry(registry)
    closing.add_action(_assign("DoorsShut", "yes"))

    wildcard = unreal.new_object(runner_cls)
    wildcard.configure("LiftAnyMessage")
    wildcard.set_triggered_by("Lift")
    wildcard.set_script_message_class("Message")
    wildcard.set_registry(registry)
    wildcard.add_action(_assign("SawAny", "yes"))

    registry.dispatch_message("MessageMoverOpened", "Lift")
    for r in (opened, closing, wildcard):
        r.tick_execution(0.0)
    if str(opened.ensure_variables().get_value_or_empty("DingPlayed")) != "yes":
        f.append("class-matched script did not fire")
    if str(closing.ensure_variables().get_value_or_empty("DoorsShut")) == "yes":
        f.append("MessageMoverClosing script fired on MessageMoverOpened")
    if str(wildcard.ensure_variables().get_value_or_empty("SawAny")) != "yes":
        f.append("scriptMessageClass=Message wildcard did not fire")
    report["message_class_gate"] = "ok"

    # Subclass acceptance (20-Scripting-Basics): a script accepts its class AND every subclass.
    base_l = unreal.new_object(runner_cls)
    base_l.configure("BaseTriggerListener")
    base_l.set_triggered_by("Vol")
    base_l.set_script_message_class("MessageTrigger")
    base_l.set_registry(registry)
    base_l.add_action(_assign("Got", "yes"))
    vol_l = unreal.new_object(runner_cls)
    vol_l.configure("VolBaseListener")
    vol_l.set_triggered_by("Vol")
    vol_l.set_script_message_class("MessageTriggerVolume")
    vol_l.set_registry(registry)
    vol_l.add_action(_assign("Got", "yes"))
    mover_l = unreal.new_object(runner_cls)
    mover_l.configure("MoverBaseListener")
    mover_l.set_triggered_by("Vol")
    mover_l.set_script_message_class("MessageMover")
    mover_l.set_registry(registry)
    mover_l.add_action(_assign("Got", "yes"))
    registry.dispatch_message("MessageTriggerVolumeEnter", "Vol")
    for r in (base_l, vol_l, mover_l):
        r.tick_execution(0.0)
    got = lambda r: str(r.ensure_variables().get_value_or_empty("Got")) == "yes"
    if not got(base_l):
        f.append("MessageTrigger listener rejected MessageTriggerVolumeEnter (subclass)")
    if not got(vol_l):
        f.append("MessageTriggerVolume listener rejected MessageTriggerVolumeEnter (subclass)")
    if got(mover_l):
        f.append("MessageMover listener accepted an unrelated trigger message")
    report["message_class_subclass"] = "ok"

    # messageFilter (23-Scripting-Examples.md Examples 4/9/14): the script starts only when every
    # non-empty filter field equals the message's own field. Empty/None/0 fields are ignored, and
    # a field the sender didn't supply cannot rule the script out.
    def _filtered(name, fields):
        r = unreal.new_object(runner_cls)
        r.configure(name)
        r.set_triggered_by("all")
        r.set_script_message_class("MessagePawnDied")
        r.set_registry(registry)
        for k, v in fields:
            r.set_message_filter_field(k, v)
        r.add_action(_assign("Ran", "yes"))
        return r

    only_friend = _filtered("OnlyFriend", [("PawnLabel", "Friend1")])
    only_thug = _filtered("OnlyThug", [("PawnClass", "SpawnedMeleeThug")])
    empty_fields = _filtered("EmptyFilter", [("PawnLabel", "None"), ("Reason", "0"), ("PawnClass", "")])
    needs_unsent = _filtered("NeedsUnsent", [("Instigator", "Player")])

    registry.dispatch_message_with_fields(
        "MessagePawnDied", "all", {"PawnLabel": "friend1", "PawnClass": "SpawnedBouncer"})
    for r in (only_friend, only_thug, empty_fields, needs_unsent):
        r.tick_execution(0.0)

    def _ran(r):
        return str(r.ensure_variables().get_value_or_empty("Ran")) == "yes"

    if not _ran(only_friend):
        f.append("PawnLabel filter (case-insensitive) rejected a matching message")
    if _ran(only_thug):
        f.append("PawnClass filter accepted a different class")
    if not _ran(empty_fields):
        f.append("empty/None/0 filter fields should match anything")
    if not _ran(needs_unsent):
        f.append("a filter field the sender did not supply must not rule the script out")
    report["message_filter"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-trigger:\n- " + "\n- ".join(f))
    _log("PASS script trigger")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_trigger_report.json"))
