"""Headless verify: player death + Vita-Chamber-style respawn + AI death reaction."""

import json
import math
import os

import unreal


def _flag(value):
    return bool(value() if callable(value) else value)


def _log(message):
    unreal.log("[bioshock-player-death] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _dist3d(a, b):
    dx = float(a.x - b.x)
    dy = float(a.y - b.y)
    dz = float(a.z - b.z)
    return math.sqrt(dx * dx + dy * dy + dz * dz)


def _tick_combat(ai, seconds, step=0.05):
    steps = int(seconds / step)
    for _ in range(steps):
        ai.advance_autonomous_combat(step)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    handler_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDeathRespawnHandler")
    damage_lib = unreal.ShockDamageLibrary
    if not player_cls or not ai_cls or not handler_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("player-death:\n- " + "\n- ".join(failures))

    spawned = []
    start_loc = unreal.Vector(-200.0, 0.0, 100.0)
    moved_loc = unreal.Vector(-50.0, 120.0, 100.0)

    start_actor = _spawn(
        subsystem,
        unreal.PlayerStart,
        "DeathRespawnStart",
        start_loc,
        unreal.Rotator(0.0, 90.0, 0.0),
    )
    spawned.append(start_actor)

    player = _spawn(subsystem, player_cls, "DeathPlayer", moved_loc)
    spawned.append(player)
    if not player or not start_actor:
        failures.append("player/start spawn")
    else:
        player.ensure_health_initialized()
        max_health = float(player.get_current_health())
        world = unreal.EditorLevelLibrary.get_editor_world()
        handler = unreal.new_object(handler_cls, outer=player)
        if not handler:
            failures.append("respawn handler create")
        else:
            handler.set_editor_property("respawn_delay_seconds", 3.0)
            handler.set_editor_property("reload_level_on_death", False)
            handler.initialize(world, player, start_actor)

            applied = float(damage_lib.apply_damage(player, max_health, None, unreal.Name("Test")))
            report["playerDamageApplied"] = applied

            if int(player.get_death_notify_count()) != 1:
                failures.append("OnDied count %s" % player.get_death_notify_count())
            if not _flag(player.is_dead):
                failures.append("player not dead")
            if player.is_playable_input_enabled():
                failures.append("input still enabled after death")
            if float(player.get_current_health()) != 0.0:
                failures.append("player health not zero %s" % player.get_current_health())

            if not handler.is_respawn_pending():
                failures.append("respawn not pending after death")

            loc_before = player.get_actor_location()
            handler.advance_respawn_for_verify(3.0)
            loc_after = player.get_actor_location()

            report["respawn"] = {
                "health": float(player.get_current_health()),
                "startDist": _dist3d(loc_after, start_loc),
                "movedDist": _dist3d(loc_after, moved_loc),
            }

            if handler.is_respawn_pending():
                failures.append("respawn still pending after delay")
            if not player.is_playable_input_enabled():
                failures.append("input not re-enabled after respawn")
            if float(player.get_current_health()) != max_health:
                failures.append("health not restored %.1f != %.1f" % (player.get_current_health(), max_health))
            if _dist3d(loc_after, start_loc) > 5.0:
                failures.append("not teleported to start dist=%.1f" % _dist3d(loc_after, start_loc))
            if _dist3d(loc_after, moved_loc) < 50.0:
                failures.append("still at death location")

    # AI death: combat stops after lethal damage
    ai = _spawn(subsystem, ai_cls, "DeathAI", unreal.Vector(400.0, 0.0, 100.0))
    ai_target = _spawn(subsystem, player_cls, "DeathAITarget", unreal.Vector(650.0, 0.0, 100.0))
    spawned.extend([ai, ai_target])
    if not ai or not ai_target:
        failures.append("ai death spawn")
    else:
        ai.configure_identity("Agg_BabyJane", "DeathAI")
        ai.ensure_health_initialized()
        ai_target.ensure_health_initialized()
        ai.add_target_to_attack_on_sight(unreal.Name("DeathAITarget"))
        ai.scripted_attack_target(ai_target)

        start_target_health = float(ai_target.get_current_health())
        ai_health = float(ai.get_current_health())
        applied_ai = float(damage_lib.apply_damage(ai, ai_health, ai_target, unreal.Name("Test")))
        report["aiDamageApplied"] = applied_ai

        if int(ai.get_death_notify_count()) != 1:
            failures.append("AI death notify count %s" % ai.get_death_notify_count())
        if not _flag(ai.is_dead):
            failures.append("AI not dead")
        if ai.is_combat_loop_active():
            failures.append("AI combat loop still active after death")

        _tick_combat(ai, 2.0)
        end_target_health = float(ai_target.get_current_health())
        report["aiDeath"] = {
            "startTargetHealth": start_target_health,
            "endTargetHealth": end_target_health,
        }
        if end_target_health != start_target_health:
            failures.append("dead AI still damaged target %.1f -> %.1f" % (start_target_health, end_target_health))

    for actor in spawned:
        if actor:
            subsystem.destroy_actor(actor)

    report["player_death"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("player-death:\n- " + "\n- ".join(failures))
    _log("PASS player-death")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "player_death_report.json"),
        )
    )
