"""Headless verify: UShockAIBrain goal selection + ability execution on slice combat."""

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-ai-brain] %s" % message)


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
    ai = _spawn(subsystem, ai_cls, "BrainAI", ai_loc, unreal.Rotator(0.0, yaw, 0.0))
    player = _spawn(
        subsystem,
        player_cls,
        "BrainPlayer",
        player_loc,
        unreal.Rotator(0.0, 180.0 if player_x >= 0 else 0.0, 0.0),
    )
    if ai:
        ai.configure_identity("Agg_BabyJane", "BrainAI")
        ai.ensure_health_initialized()
        if not ai.is_using_brain():
            ai.set_editor_property("bUseBrain", True)
    if player:
        player.ensure_health_initialized()
    return ai, player


def _equip_test_weapon(subsystem, ai, damage=20.0):
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    if not weapon_cls or not ai:
        return None
    weapon = subsystem.spawn_actor_from_class(
        weapon_cls, ai.get_actor_location(), unreal.Rotator(0.0, 0.0, 0.0)
    )
    if weapon:
        weapon.configure_hitscan(float(damage), 10000.0)
        ai.equip_ai_weapon(weapon)
        brain = ai.get_shock_ai_brain()
        if brain and int(brain.get_ability_count()) > 0:
            brain.initialize_for_ai(ai)
    return weapon


def _arm_attack_on_sight(ai, world, attack_cls):
    if not ai:
        return
    ai.add_target_to_attack_on_sight(unreal.Name("BrainPlayer"))
    if attack_cls:
        order = unreal.new_object(attack_cls)
        order.configure(unreal.Name("BrainAI"), unreal.Name("BrainPlayer"), True)
        if int(order.apply_in_world(world)) < 1:
            raise RuntimeError("ActionAttackTarget on-sight failed")


def _brain_goal_name(ai):
    brain = ai.get_shock_ai_brain() if ai else None
    if not brain:
        return "none"
    goal = brain.get_active_goal_type()
    return str(goal)


def _destroy_spawned(subsystem, actors):
    for actor in actors:
        if actor:
            subsystem.destroy_actor(actor)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    wait_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToWait")
    attack_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttackTarget")
    damage_lib = unreal.ShockDamageLibrary
    kill_target = unreal.ShockAIGoalType.KILL_TARGET

    if not ai_cls or not player_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("ai-brain:\n- " + "\n- ".join(failures))

    spawned = []

    # (a) melee: brain picks KillTarget, closes distance, melee damage on cadence
    ai, player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 800.0)
    spawned.extend([ai, player])
    if not ai or not player:
        failures.append("melee spawn")
    else:
        _arm_attack_on_sight(ai, world, attack_cls)
        brain = ai.get_shock_ai_brain()
        if brain:
            brain.initialize_for_ai(ai)
        if not brain:
            failures.append("brain component missing")
        elif int(brain.get_ability_count()) < 5:
            failures.append("brain ability count %d" % int(brain.get_ability_count()))

        start_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
        start_health = float(player.get_current_health())
        saw_kill_target = False
        saw_move = False
        saw_melee = False

        for _ in range(100):
            _tick_combat(ai, 0.05)
            goal = brain.get_active_goal_type() if brain else None
            if goal == kill_target:
                saw_kill_target = True
            ability = brain.get_active_ability_name() if brain else unreal.Name("")
            ability_str = str(ability)
            if "MoveTo" in ability_str:
                saw_move = True
            if "MeleeAttack" in ability_str:
                saw_melee = True
            if float(player.get_current_health()) < start_health - 1.0:
                break

        end_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
        end_health = float(player.get_current_health())
        report["melee"] = {
            "startDist": start_dist,
            "endDist": end_dist,
            "startHealth": start_health,
            "endHealth": end_health,
            "sawKillTarget": saw_kill_target,
            "sawMoveTo": saw_move,
            "sawMeleeAttack": saw_melee,
            "finalGoal": _brain_goal_name(ai),
        }
        if not saw_kill_target:
            failures.append("brain never picked KillTarget")
        if not saw_move and start_dist > 300.0:
            failures.append("MoveToAbility never active at range")
        if end_dist >= start_dist - 100.0:
            failures.append("brain did not close distance %.1f -> %.1f" % (start_dist, end_dist))
        if end_health >= start_health - 1.0:
            failures.append("brain melee no damage %.1f -> %.1f" % (start_health, end_health))

    _destroy_spawned(subsystem, spawned)
    spawned = []

    # (b) ranged: RangedAttackAbility from range
    ranged_ai, ranged_player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 800.0)
    ranged_weapon = _equip_test_weapon(subsystem, ranged_ai)
    spawned.extend([ranged_ai, ranged_player, ranged_weapon])
    if not ranged_ai or not ranged_player or not ranged_weapon:
        failures.append("ranged spawn")
    else:
        _arm_attack_on_sight(ranged_ai, world, attack_cls)
        rbrain = ranged_ai.get_shock_ai_brain()
        r_start_health = float(ranged_player.get_current_health())
        saw_ranged = False
        for _ in range(100):
            _tick_combat(ranged_ai, 0.05)
            ability = rbrain.get_active_ability_name() if rbrain else unreal.Name("")
            if "RangedAttack" in str(ability):
                saw_ranged = True
            if float(ranged_player.get_current_health()) < r_start_health - 1.0:
                break
        r_end_dist = _dist2d(ranged_ai.get_actor_location(), ranged_player.get_actor_location())
        r_end_health = float(ranged_player.get_current_health())
        r_fires = int(ranged_ai.get_ai_weapon_fire_count())
        report["ranged"] = {
            "endDist": r_end_dist,
            "startHealth": r_start_health,
            "endHealth": r_end_health,
            "fireCount": r_fires,
            "sawRangedAttack": saw_ranged,
        }
        if not saw_ranged:
            failures.append("RangedAttackAbility never active")
        if r_end_dist < 300.0:
            failures.append("ranged closed to melee dist %.1f" % r_end_dist)
        if r_fires < 1:
            failures.append("ranged did not fire")
        if r_end_health >= r_start_health - 1.0:
            failures.append("ranged no damage %.1f -> %.1f" % (r_start_health, r_end_health))

    _destroy_spawned(subsystem, spawned)
    spawned = []

    # (c) told to wait: IdleAbility, no movement or damage
    wait_ai, wait_player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 150.0)
    spawned.extend([wait_ai, wait_player])
    if not wait_ai or not wait_player:
        failures.append("wait spawn")
    else:
        _arm_attack_on_sight(wait_ai, world, attack_cls)
        wait_action = unreal.new_object(wait_cls)
        wait_action.configure(unreal.Name("BrainAI"))
        if int(wait_action.apply_in_world(world)) < 1:
            failures.append("TellAIToWait apply")
        w_start_dist = _dist2d(wait_ai.get_actor_location(), wait_player.get_actor_location())
        w_start_health = float(wait_player.get_current_health())
        _tick_combat(wait_ai, 3.0)
        w_end_dist = _dist2d(wait_ai.get_actor_location(), wait_player.get_actor_location())
        w_end_health = float(wait_player.get_current_health())
        report["wait"] = {
            "startDist": w_start_dist,
            "endDist": w_end_dist,
            "startHealth": w_start_health,
            "endHealth": w_end_health,
        }
        if abs(w_end_dist - w_start_dist) > 5.0:
            failures.append("wait moved %.1f -> %.1f" % (w_start_dist, w_end_dist))
        if w_end_health != w_start_health:
            failures.append("wait damaged %.1f -> %.1f" % (w_start_health, w_end_health))

    _destroy_spawned(subsystem, spawned)
    spawned = []

    # (d) hit react: stagger interrupts attack, then resumes
    hit_ai, hit_player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 120.0)
    spawned.extend([hit_ai, hit_player])
    if not hit_ai or not hit_player:
        failures.append("hit spawn")
    else:
        hit_ai.ensure_controller_for_verify()
        _arm_attack_on_sight(hit_ai, world, attack_cls)
        _tick_combat(hit_ai, 1.5)
        health_before = float(hit_player.get_current_health())
        damage_lib.apply_damage(hit_ai, 15.0, hit_player, unreal.Name("Verify"))
        stagger = float(hit_ai.get_hit_react_remaining())
        hbrain = hit_ai.get_shock_ai_brain()
        react_goal = unreal.ShockAIGoalType.REACT
        _tick_combat(hit_ai, 0.05)
        saw_react = hbrain and hbrain.get_active_goal_type() == react_goal
        interrupted = False
        for _ in range(20):
            h_before = float(hit_player.get_current_health())
            _tick_combat(hit_ai, 0.05)
            if float(hit_ai.get_hit_react_remaining()) > 0.02 and float(hit_player.get_current_health()) < h_before - 0.5:
                interrupted = False
                break
            if float(hit_player.get_current_health()) < health_before - 0.5 and float(hit_ai.get_hit_react_remaining()) > 0.02:
                interrupted = True
                break
            if float(hit_ai.get_hit_react_remaining()) <= 0.02:
                break

        while float(hit_ai.get_hit_react_remaining()) > 0.02:
            step_health = float(hit_player.get_current_health())
            _tick_combat(hit_ai, 0.05)
            if float(hit_player.get_current_health()) < step_health - 0.5:
                interrupted = True

        _tick_combat(hit_ai, 3.0)
        health_after = float(hit_player.get_current_health())
        report["hitReact"] = {
            "stagger": stagger,
            "sawReactGoal": saw_react,
            "interruptedDuringStagger": interrupted,
            "healthBefore": health_before,
            "healthAfter": health_after,
        }
        if stagger <= 0.0:
            failures.append("hit react stagger not started")
        if not saw_react and stagger > 0.0:
            failures.append("HitReactAbility goal not selected during stagger")
        if health_after >= health_before - 1.0:
            failures.append("attack did not resume after stagger")

    _destroy_spawned(subsystem, spawned)

    error_count = len(failures)
    report["errorCount"] = error_count
    report["ai_brain"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("ai-brain (%d errors):\n- " % error_count + "\n- ".join(failures))
    _log("Success - %d error(s)" % error_count)
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "ai_brain_report.json"),
        )
    )
