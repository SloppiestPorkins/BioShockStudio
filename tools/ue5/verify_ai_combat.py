"""Headless verify: ABaseShockAI autonomous Idle/Chase/Attack combat loop."""

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-ai-combat] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _dist2d(a, b):
    dx = float(a.x - b.x)
    dy = float(a.y - b.y)
    return math.sqrt(dx * dx + dy * dy)


def _face_dot(actor, target):
    forward = actor.get_actor_forward_vector()
    delta = target.get_actor_location() - actor.get_actor_location()
    dx = float(delta.x)
    dy = float(delta.y)
    length = math.sqrt(dx * dx + dy * dy)
    if length < 1.0:
        return 1.0
    dx /= length
    dy /= length
    return float(forward.x) * dx + float(forward.y) * dy


def _tick_combat(ai, seconds, step=0.05):
    steps = int(seconds / step)
    for _ in range(steps):
        ai.advance_autonomous_combat(step)


def _setup_engaged_pair(subsystem, ai_cls, player_cls, player_x):
    ai_loc = unreal.Vector(0.0, 0.0, 100.0)
    player_loc = unreal.Vector(float(player_x), 0.0, 100.0)
    yaw = 0.0 if player_x >= 0 else 180.0
    ai = _spawn(subsystem, ai_cls, "CombatAI", ai_loc, unreal.Rotator(0.0, yaw, 0.0))
    player = _spawn(subsystem, player_cls, "Player", player_loc, unreal.Rotator(0.0, 180.0 if player_x >= 0 else 0.0, 0.0))
    if ai:
        ai.configure_identity("Agg_BabyJane", "CombatAI")
        ai.ensure_health_initialized()
    if player:
        player.ensure_health_initialized()
    return ai, player


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    wait_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToWait")
    attack_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttackTarget")
    if not ai_cls or not player_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("ai-combat:\n- " + "\n- ".join(failures))

    spawned = []

    def _arm_attack_on_sight(ai):
        if not ai:
            return
        ai.add_target_to_attack_on_sight(unreal.Name("Player"))
        if attack_cls:
            order = unreal.new_object(attack_cls)
            order.configure(unreal.Name("CombatAI"), unreal.Name("Player"), True)
            if int(order.apply_in_world(world)) < 1:
                failures.append("ActionAttackTarget on-sight")
        if not ai.has_attack_on_sight_label(unreal.Name("Player")):
            failures.append("attack-on-sight label missing")

    # (a)+(b) engage: close distance, face target, melee damage on cadence
    ai, player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 800.0)
    spawned.extend([ai, player])
    if not ai or not player:
        failures.append("engage spawn")
    else:
        _arm_attack_on_sight(ai)
        start_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
        start_health = float(player.get_current_health())
        _tick_combat(ai, 5.0)
        end_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
        end_health = float(player.get_current_health())
        facing = _face_dot(ai, player)

        report["engage"] = {
            "startDist": start_dist,
            "endDist": end_dist,
            "startHealth": start_health,
            "endHealth": end_health,
            "facingDot": facing,
        }

        if end_dist >= start_dist - 100.0:
            failures.append("engage distance %.1f -> %.1f" % (start_dist, end_dist))
        if facing < 0.7:
            failures.append("engage facing dot %.2f" % facing)
        if end_health >= start_health - 1.0:
            failures.append("engage no melee damage %.1f -> %.1f" % (start_health, end_health))

    # (c) told to wait: no movement or damage
    wait_ai, wait_player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 150.0)
    spawned.extend([wait_ai, wait_player])
    if not wait_ai or not wait_player:
        failures.append("wait spawn")
    else:
        _arm_attack_on_sight(wait_ai)
        wait_action = unreal.new_object(wait_cls)
        wait_action.configure(unreal.Name("CombatAI"))
        if int(wait_action.apply_in_world(world)) < 1:
            failures.append("TellAIToWait apply")
        if not wait_ai.is_told_to_wait():
            failures.append("TellAIToWait flag")
        wait_start_dist = _dist2d(wait_ai.get_actor_location(), wait_player.get_actor_location())
        wait_start_health = float(wait_player.get_current_health())
        _tick_combat(wait_ai, 3.0)
        wait_end_dist = _dist2d(wait_ai.get_actor_location(), wait_player.get_actor_location())
        wait_end_health = float(wait_player.get_current_health())
        report["wait"] = {
            "startDist": wait_start_dist,
            "endDist": wait_end_dist,
            "startHealth": wait_start_health,
            "endHealth": wait_end_health,
        }
        if abs(wait_end_dist - wait_start_dist) > 5.0:
            failures.append("wait moved %.1f -> %.1f" % (wait_start_dist, wait_end_dist))
        if wait_end_health != wait_start_health:
            failures.append("wait damaged %.1f -> %.1f" % (wait_start_health, wait_end_health))

    # (d) out of sight range: no acquisition
    far_ai, far_player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 4000.0)
    spawned.extend([far_ai, far_player])
    if not far_ai or not far_player:
        failures.append("far spawn")
    else:
        _arm_attack_on_sight(far_ai)
        far_start_health = float(far_player.get_current_health())
        _tick_combat(far_ai, 3.0)
        far_end_health = float(far_player.get_current_health())
        far_dist = _dist2d(far_ai.get_actor_location(), far_player.get_actor_location())
        report["far"] = {
            "dist": far_dist,
            "startHealth": far_start_health,
            "endHealth": far_end_health,
        }
        if far_end_health != far_start_health:
            failures.append("far damaged at dist %.0f" % far_dist)
        if far_dist < 3900.0:
            failures.append("far closed distance to %.1f" % far_dist)

    for actor in spawned:
        if actor:
            subsystem.destroy_actor(actor)

    report["ai_combat"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("ai-combat:\n- " + "\n- ".join(failures))
    _log("PASS ai-combat")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "ai_combat_report.json"),
        )
    )
