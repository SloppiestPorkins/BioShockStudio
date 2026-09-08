"""Headless regression for the BioShock splicer high-level behaviour rhythm."""

import json
import os

import unreal


def _spawn(subsystem, cls, label, location):
    actor = subsystem.spawn_actor_from_class(cls, location, unreal.Rotator())
    if actor:
        actor.set_actor_label(label)
    return actor


def _tick(ai, seconds, step=0.05):
    for _ in range(int(seconds / step)):
        ai.advance_autonomous_combat(step)


def _state(ai):
    return str(ai.get_behaviour_state_name())


def _pose(ai):
    return str(ai.get_playing_animation_name_for_verify())


def main(out):
    report = {"failures": []}
    failures = report["failures"]
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not ai_cls or not player_cls:
        raise RuntimeError("BioShockRuntime AI classes unavailable")

    actors = []
    idle = _spawn(subsystem, ai_cls, "BehaviourIdle", unreal.Vector(0.0, 0.0, 100.0))
    actors.append(idle)
    idle.configure_identity("SpawnedMeleeThug", "BehaviourIdle")
    idle.ensure_health_initialized()
    start = idle.get_actor_location()
    _tick(idle, 1.0)
    end = idle.get_actor_location()
    idle_state = _state(idle)
    idle_pose = _pose(idle)
    moved = (end - start).length()
    report["idle"] = {
        "state": idle_state,
        "moved": moved,
        "pose": idle_pose,
        "hasPose": bool(idle_pose and idle_pose != "None"),
    }
    if idle_state not in ("Idle", "Patrol"):
        failures.append("untargeted AI state is %s" % idle_state)
    if moved > 5.0:
        failures.append("untargeted AI invented a destination (moved %.1f)" % moved)
    if not report["idle"]["hasPose"]:
        failures.append("AI remained in reference pose after one second")

    combat = _spawn(subsystem, ai_cls, "BehaviourCombat", unreal.Vector(0.0, 500.0, 100.0))
    player = _spawn(subsystem, player_cls, "BehaviourPlayer", unreal.Vector(800.0, 500.0, 100.0))
    actors.extend((combat, player))
    combat.configure_identity("SpawnedRangedAggressorPistol", "BehaviourCombat")
    combat.ensure_health_initialized()
    player.ensure_health_initialized()
    combat.simulate_sight_event(player)
    _tick(combat, 0.25)
    sight_state = _state(combat)
    report["sight"] = {"state": sight_state}
    if sight_state != "Combat":
        failures.append("simulated sight did not enter Combat: %s" % sight_state)

    combat.set_suppress_combat_line_of_sight(True)
    hidden_states = []
    for _ in range(90):
        _tick(combat, 0.05)
        hidden_states.append(_state(combat))
    hidden_state = _state(combat)
    report["lostTarget"] = {
        "state": hidden_state,
        "statesSeen": sorted(set(hidden_states)),
        "lastKnown": str(combat.get_last_known_target_location()),
    }
    if "Investigate" not in hidden_states:
        failures.append("hidden target never entered Investigate: %s" % hidden_state)

    flee = _spawn(subsystem, ai_cls, "BehaviourFlee", unreal.Vector(0.0, -500.0, 100.0))
    actors.append(flee)
    flee.configure_identity("SpawnedMeleeThug", "BehaviourFlee")
    flee.ensure_health_initialized()
    damage = max(1.0, float(flee.get_current_health()) * 0.80)
    unreal.ShockDamageLibrary.apply_damage(flee, damage, None, unreal.Name("VerifyMorale"))
    _tick(flee, 0.25)
    flee_state = _state(flee)
    report["lowHealth"] = {
        "state": flee_state,
        "health": float(flee.get_current_health()),
    }
    if flee_state != "Flee":
        failures.append("low-health AI did not enter Flee: %s" % flee_state)

    for actor in actors:
        if actor:
            subsystem.destroy_actor(actor)

    report["errorCount"] = len(failures)
    report["ai_behaviour"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ai-behaviour:\n- " + "\n- ".join(failures))
    unreal.log("[bioshock-ai-behaviour] Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "ai_behaviour_report.json"),
        )
    )
