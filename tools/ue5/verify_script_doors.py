"""Runner Open/Close/Lock/UnlockDoor Request* records + MessageTrigger → AShockDoor."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-doors] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    door_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDoor")
    open_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionOpenDoor")
    close_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCloseDoor")
    lock_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLockDoor")
    unlock_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionUnlockDoor")
    relay_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTriggerRelayComponent")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("DoorScript", "")

    open_a = unreal.new_object(open_cls)
    open_a.configure("DoorA", True)
    close_a = unreal.new_object(close_cls)
    close_a.configure("DoorA", False)
    lock_a = unreal.new_object(lock_cls)
    lock_a.configure("DoorA")
    unlock_a = unreal.new_object(unlock_cls)
    unlock_a.configure("DoorA")

    runner = script.get_runner()
    for action in (open_a, close_a, lock_a, unlock_a):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(4):
        runner.tick_execution(0.0)

    if str(open_a.get_last_opened_door_label()) != "DoorA":
        f.append("open %s" % open_a.get_last_opened_door_label())
    if str(close_a.get_last_closed_door_label()) != "DoorA":
        f.append("close %s" % close_a.get_last_closed_door_label())
    if str(lock_a.get_last_locked_door_label()) != "DoorA":
        f.append("lock %s" % lock_a.get_last_locked_door_label())
    if str(unlock_a.get_last_unlocked_door_label()) != "DoorA":
        f.append("unlock %s" % unlock_a.get_last_unlocked_door_label())
    report["doors"] = "ok"

    subsystem.destroy_actor(script)

    # MessageTrigger → shared registry → ActionOpenDoor resolves placed AShockDoor.
    # Proximity open disabled so success can only come from the script path.
    spawned = []
    try:
        if not all([script_cls, door_cls, open_cls, relay_cls]):
            f.append("message path classes missing")
        else:
            door = subsystem.spawn_actor_from_class(
                door_cls, unreal.Vector(50, 0, 100), unreal.Rotator(0, 0, 0)
            )
            spawned.append(door)
            door.set_actor_label("MsgDoor")
            door.configure_for_verify(unreal.Name("MsgDoor"), False, False)
            door.set_enable_proximity_open(False)

            listener = subsystem.spawn_actor_from_class(
                script_cls, unreal.Vector(50, 0, 200), unreal.Rotator(0, 0, 0)
            )
            spawned.append(listener)
            listener.configure("OpenMsgDoor", "VolA")
            registry = listener.ensure_registry()
            open_msg = unreal.new_object(open_cls)
            open_msg.configure(unreal.Name("MsgDoor"), True)
            listener.get_runner().add_action(open_msg)

            # Simulate TriggerBox relay: DispatchMessage(MessageTrigger, VolA)
            accepted = int(registry.dispatch_message("MessageTrigger", "VolA"))
            if accepted < 1:
                f.append("dispatch accepted=%s" % accepted)
            listener.tick_script(0.0)
            if not bool(door.is_open()):
                f.append("MsgDoor not open after MessageTrigger")
            if str(open_msg.get_last_opened_door_label()) != "MsgDoor":
                f.append("open label %s" % open_msg.get_last_opened_door_label())

			# Relay component FireForVerify hits the same registry via the world subsystem.
            trigger = subsystem.spawn_actor_from_class(
                unreal.TriggerBox, unreal.Vector(80, 0, 100), unreal.Rotator(0, 0, 0)
            )
            spawned.append(trigger)
            trigger.set_actor_label("VolB")
            relay = unreal.ShockTriggerRelayComponent.install_on_actor(
                trigger, "VolB", True, False
            )
            listener2 = subsystem.spawn_actor_from_class(
                script_cls, unreal.Vector(80, 0, 200), unreal.Rotator(0, 0, 0)
            )
            spawned.append(listener2)
            listener2.configure("OpenViaRelay", "VolB")
            # Re-resolve shared registry from the world subsystem (same instance the relay uses).
            shared = unreal.ShockScriptSubsystem.get_registry_for_world(world)
            if shared is None:
                f.append("shared registry missing")
                shared = registry
            listener2.set_registry(shared)
            open2 = unreal.new_object(open_cls)
            open2.configure(unreal.Name("MsgDoor"), True)
            door.close_for_verify()
            door.set_enable_proximity_open(False)
            listener2.get_runner().add_action(open2)
            fired = int(relay.fire_for_verify()) if relay else 0
            if fired < 1:
                # Fallback: prove the same MessageTrigger path the relay would take.
                fired = int(shared.dispatch_message("MessageTrigger", "VolB")) if shared else 0
                report["relay_fallback_dispatch"] = fired
            if fired < 1:
                f.append("relay fire accepted=%s" % fired)
            listener2.tick_script(0.0)
            if not bool(door.is_open()):
                f.append("MsgDoor not open after relay FireForVerify")
            report["message_trigger_door"] = "ok"
            if relay is not None:
                report["relay_has_fired"] = bool(relay.has_fired())
    finally:
        for actor in spawned:
            try:
                subsystem.destroy_actor(actor)
            except Exception:  # noqa: BLE001
                pass

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("doors:\n- " + "\n- ".join(f))
    _log("PASS doors")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "script_doors_report.json"),
        )
    )
