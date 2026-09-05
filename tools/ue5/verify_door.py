"""Headless verify: AShockDoor default state, open/close, collision updates.

Spawns a door, asserts closed+blocking, OpenForVerify → non-blocking, CloseForVerify →
blocking again. Locked doors refuse open. Script Open/Close/Lock/Unlock drive a labeled door.
"""

from __future__ import annotations

import json
import os

import unreal

# ECollisionEnabled as uint8 from GetCollisionEnabledForVerify
_NO_COLLISION = 0
_QUERY_AND_PHYSICS = 3


def _log(message):
    unreal.log("[bioshock-door] %s" % message)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _destroy(subsystem, actors):
    for actor in actors:
        if not actor:
            continue
        try:
            if hasattr(actor, "is_valid") and not actor.is_valid():
                continue
            subsystem.destroy_actor(actor)
        except Exception:  # noqa: BLE001
            pass


def main(out):
    report = {"failures": [], "checks": 0, "results": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    door_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDoor")
    open_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionOpenDoor")
    close_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCloseDoor")
    lock_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLockDoor")
    unlock_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionUnlockDoor")

    if door_cls is None:
        failures.append("ShockDoor class missing")
        _write(out, report)
        raise RuntimeError("door:\n- " + "\n- ".join(failures))

    spawned = []

    def check(name, ok, detail=None):
        report["checks"] += 1
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report["results"].append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    door = subsystem.spawn_actor_from_class(
        door_cls, unreal.Vector(0.0, 0.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
    if door is None:
        failures.append("spawn ShockDoor failed")
        _write(out, report)
        raise RuntimeError("door:\n- " + "\n- ".join(failures))
    spawned.append(door)
    door.set_actor_label("VerifyDoor")
    door.configure_for_verify(unreal.Name("VerifyDoor"), False, False)

    check("default_closed", not bool(door.is_open()), "open=%s" % door.is_open())
    check("default_unlocked", not bool(door.is_locked()), "locked=%s" % door.is_locked())
    check("default_not_broken", not bool(door.is_broken()), "broken=%s" % door.is_broken())
    coll0 = int(door.get_collision_enabled_for_verify())
    check(
        "default_blocking",
        coll0 == _QUERY_AND_PHYSICS or bool(door.is_blocking_collision_enabled()),
        "collision=%s blocking=%s" % (coll0, door.is_blocking_collision_enabled()),
    )
    report["defaultCollision"] = coll0

    opened = bool(door.open_for_verify())
    check("open_for_verify", opened, "returned %s" % opened)
    check("is_open_after", bool(door.is_open()), "open=%s" % door.is_open())
    coll_open = int(door.get_collision_enabled_for_verify())
    check(
        "open_non_blocking",
        coll_open == _NO_COLLISION or not bool(door.is_blocking_collision_enabled()),
        "collision=%s blocking=%s" % (coll_open, door.is_blocking_collision_enabled()),
    )
    report["openCollision"] = coll_open

    closed = bool(door.close_for_verify())
    check("close_for_verify", closed, "returned %s" % closed)
    check("is_closed_after", not bool(door.is_open()), "open=%s" % door.is_open())
    coll_closed = int(door.get_collision_enabled_for_verify())
    check(
        "closed_blocking",
        coll_closed == _QUERY_AND_PHYSICS or bool(door.is_blocking_collision_enabled()),
        "collision=%s blocking=%s" % (coll_closed, door.is_blocking_collision_enabled()),
    )
    report["closedCollision"] = coll_closed

    locked_door = subsystem.spawn_actor_from_class(
        door_cls, unreal.Vector(200.0, 0.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
    spawned.append(locked_door)
    locked_door.set_actor_label("LockedDoor")
    locked_door.configure_for_verify(unreal.Name("LockedDoor"), True, False)
    refused = not bool(locked_door.open_for_verify())
    check("locked_refuses_open", refused, "open=%s" % locked_door.is_open())

    if not all([open_cls, close_cls, lock_cls, unlock_cls]):
        failures.append("door action classes missing")
    else:
        script_door = subsystem.spawn_actor_from_class(
            door_cls, unreal.Vector(400.0, 0.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
        spawned.append(script_door)
        script_door.set_actor_label("ScriptDoor")
        script_door.configure_for_verify(unreal.Name("ScriptDoor"), False, False)

        open_a = unreal.new_object(open_cls)
        open_a.configure(unreal.Name("ScriptDoor"), True)
        opened_n = int(open_a.apply_in_world(world))
        check("script_open_applied", opened_n >= 1, "n=%s" % opened_n)
        check("script_open_state", bool(script_door.is_open()), "open=%s" % script_door.is_open())
        check(
            "script_open_label",
            str(open_a.get_last_opened_door_label()) == "ScriptDoor",
            str(open_a.get_last_opened_door_label()),
        )
        # OpenDoor starts the swing; snap fully open so collision assert is deterministic.
        script_door.open_for_verify()
        coll_script = int(script_door.get_collision_enabled_for_verify())
        check(
            "script_open_non_blocking",
            coll_script == _NO_COLLISION or not bool(script_door.is_blocking_collision_enabled()),
            "collision=%s" % coll_script,
        )

        lock_a = unreal.new_object(lock_cls)
        lock_a.configure(unreal.Name("ScriptDoor"))
        check("script_lock", int(lock_a.apply_in_world(world)) >= 1, None)
        check("script_locked_state", bool(script_door.is_locked()), "locked=%s" % script_door.is_locked())
        check("locked_blocks_open", not bool(script_door.open_for_verify()), "open=%s" % script_door.is_open())

        unlock_a = unreal.new_object(unlock_cls)
        unlock_a.configure(unreal.Name("ScriptDoor"))
        check("script_unlock", int(unlock_a.apply_in_world(world)) >= 1, None)
        check(
            "script_unlocked_state",
            not bool(script_door.is_locked()),
            "locked=%s" % script_door.is_locked(),
        )

        close_a = unreal.new_object(close_cls)
        close_a.configure(unreal.Name("ScriptDoor"), True)
        # Ensure open first so close has work to do.
        script_door.open_for_verify()
        closed_n = int(close_a.apply_in_world(world))
        check("script_close_applied", closed_n >= 1, "n=%s" % closed_n)
        script_door.close_for_verify()
        check("script_closed_state", not bool(script_door.is_open()), "open=%s" % script_door.is_open())
        check(
            "script_closed_blocking",
            bool(script_door.is_blocking_collision_enabled()),
            "collision=%s" % script_door.get_collision_enabled_for_verify(),
        )

    _destroy(subsystem, spawned)
    _write(out, report)

    if failures:
        raise RuntimeError("door:\n- " + "\n- ".join(failures))
    _log("PASS door checks=%d" % report["checks"])
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "door_report.json"),
        )
    )
