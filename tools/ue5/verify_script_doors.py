"""Runner Open/Close/Lock/UnlockDoor Request* records."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-doors] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    open_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionOpenDoor")
    close_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCloseDoor")
    lock_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLockDoor")
    unlock_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionUnlockDoor")

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
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_doors_report.json",
        )
    )
