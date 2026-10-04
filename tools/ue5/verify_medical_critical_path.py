"""Medical critical path: fire each progression gate's real trigger in game order, assert it advances.

ROADMAP Phase 1 item 4 -- the executable definition of "1-Medical is playable" at the script layer.
Drives the slice's own imported scripts (/Game/BioShockSlice/1-Medical), not synthetic ones: every
step dispatches the exact message class, source label and filter fields the shipped Script actor
listens for (read from 1-Medical.ue5-level.json's scriptMessageClass / TriggeredBy / messageFilter),
ticks every script, and checks the door or bathysphere state the script is supposed to change.

What it proves: the gate scripts, their triggers and their door/bathysphere actions are wired end to
end. What it does not: that a player can physically reach each trigger (navmesh, collision,
interact traces) -- that is ROADMAP item 8 -- or how anything looks (-nullrhi).

Env:
  BIOSHOCK_CRITPATH_MAP  map (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_CRITPATH_OUT  JSON report (default %TEMP%/medical_critical_path.json)

Never saves the map.
"""
from __future__ import annotations

import json
import os

import unreal

MAP_PATH = os.environ.get("BIOSHOCK_CRITPATH_MAP", "/Game/BioShockSlice/1-Medical")
OUT = os.environ.get("BIOSHOCK_CRITPATH_OUT",
                     os.path.join(os.environ.get("TEMP", "."), "medical_critical_path.json"))
TICK = 0.1
TICKS = 300  # 30 s of script time per step: covers the scripts' own delays and door swings

# (step, message class, source label, fields, expectation)
# expectation: ("unlocked", door) | ("open", door) | ("locked", door) | ("bathysphere", map)
STEPS = [
    ("arrival: Medical hallway switch", "MessageRAReacted", "MedicalHallwaySwitch", {},
     [("unlocked", "MedicalHallwayDoor"), ("open", "MedicalHallwayDoor")]),
    ("Emergency Access: maintenance-hall look trigger", "Message",
     "QuarSwitch_UnlockMaintenanceHallViewTrigger", {},
     [("unlocked", "MedLockdownDoor"), ("open", "MedLockdownDoor")]),
    ("Fisheries gate refuses without Steinman's key", "MessageRAReacted", "quarswitch", {},
     [("locked", "FisheriesAccordian")]),
    ("Steinman's waiting room trigger", "MessageTriggerVolumeEnter", "SteinmanEventTV", {},
     [("unlocked", "SteinmanDoor1")]),
    ("Steinman's gate padlock shattered", "MessageRAReacted", "GatePadlock",
     {"RA": "GatePadlock", "Reason": "Shattered"},
     [("unlocked", "SteinmanAccordianGate"), ("open", "SteinmanAccordianGate")]),
    ("Eternal Flame look trigger", "Message", "EternalFlameBlastViewTrig", {},
     [("unlocked", "EternalFlameDoor"), ("open", "EternalFlameDoor")]),
    ("Steinman dies", "MessagePawnDied", "Steinman", {"PawnLabel": "Steinman"},
     [("unlocked", "GathererSceneDoor"), ("open", "GathererSceneDoor")]),
    ("pick up Steinman's quarantine key", "@inventory", "SteinmanQuarantineKey", {}, []),
    ("Fisheries gate opens with the key", "MessageRAReacted", "quarswitch", {},
     [("unlocked", "FisheriesAccordian"), ("open", "FisheriesAccordian")]),
    ("bathysphere to Neptune's Bounty", "MessagePlayerFinishedUsingObject", "ToNeptuneSwitch", {},
     [("bathysphere", "2-Fisheries")]),
]


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(MAP_PATH):
        raise RuntimeError("could not load %s" % MAP_PATH)
    world = unreal.EditorLevelLibrary.get_editor_world()
    actor_sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    actors = actor_sub.get_all_level_actors()
    scripts = [a for a in actors if isinstance(a, unreal.ShockScript)]
    doors = {}
    for actor in actors:
        if isinstance(actor, unreal.ShockDoor):
            doors.setdefault(str(actor.get_editor_property("door_label")), []).append(actor)

    sub = unreal.ShockScriptSubsystem.get_for_world(world)
    registry = sub.get_or_create_registry()
    for script in scripts:
        script.set_registry(registry)

    # The inventory gate and the bathysphere unlock both live on the player pawn.
    players = [a for a in actors if isinstance(a, unreal.ShockPlayer)]
    spawned_player = None
    if not players:
        spawned_player = actor_sub.spawn_actor_from_class(
            unreal.ShockPlayer, unreal.Vector(-17250.0, 1280.0, 7800.0), unreal.Rotator(0, 0, 0))
        players = [spawned_player] if spawned_player else []
    player = players[0] if players else None

    report = {"map": MAP_PATH, "scripts": len(scripts), "doorLabels": len(doors),
              "registered": registry.num(), "steps": [], "failures": []}
    clock = [0.0]

    def tick_all():
        for _ in range(TICKS):
            clock[0] += TICK
            for script in scripts:
                script.tick_script(clock[0])
            sub.execute_pending_critical_actions()

    def door_state(label):
        found = doors.get(label) or []
        if not found:
            return None
        return {"locked": all(d.is_locked() for d in found), "open": any(d.is_open() for d in found)}

    try:
        for name, message, source, fields, expect in STEPS:
            entry = {"step": name, "message": message, "source": source, "checks": []}
            if message == "@inventory":
                if player is None:
                    entry["triggered"] = 0
                    report["failures"].append("%s: no ShockPlayer in the world" % name)
                else:
                    entry["added"] = int(player.add_stack_to_inventory(source, 1))
                    entry["inventory"] = int(player.get_inventory_stack(source))
            elif fields:
                entry["triggered"] = int(sub.dispatch_message_logged_with_fields(message, source, fields))
            else:
                entry["triggered"] = int(sub.dispatch_message_logged(message, source))
            tick_all()
            if entry.get("triggered") == 0:
                report["failures"].append("%s: %s from '%s' triggered no script" % (name, message, source))
            for kind, target in expect:
                if kind == "bathysphere":
                    # UShockActionUnlockBathysphereDestination's default system name.
                    ok = bool(player) and player.is_bathysphere_destination_unlocked(
                        "BioshockBathyspheres", target)
                    entry["checks"].append({"bathysphere": target, "ok": ok})
                else:
                    state = door_state(target)
                    if state is None:
                        ok = False
                    elif kind == "unlocked":
                        ok = not state["locked"]
                    elif kind == "locked":
                        ok = state["locked"]
                    else:
                        ok = state["open"]
                    entry["checks"].append({"door": target, "want": kind, "state": state, "ok": ok})
                if not ok:
                    report["failures"].append("%s: expected %s %s" % (name, target, kind))
            report["steps"].append(entry)
    finally:
        if spawned_player:
            actor_sub.destroy_actor(spawned_player)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    passed = len(STEPS) - len({f.split(":")[0] for f in report["failures"]})
    unreal.log("[bioshock-critical-path] %d/%d steps pass -> %s" % (passed, len(STEPS), OUT))
    if report["failures"]:
        raise RuntimeError("medical critical path:\n- " + "\n- ".join(report["failures"]))
    unreal.log("[bioshock-critical-path] PASS")
    return report


if __name__ == "__main__":
    main()
