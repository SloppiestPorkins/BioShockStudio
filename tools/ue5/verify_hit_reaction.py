"""Headless verify: ABaseShockAI hit flinch (stagger, knockback, rate limit)."""

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-hit-reaction] %s" % message)


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


def _tick_combat(ai, seconds, step=0.05):
    steps = max(1, int(seconds / step))
    for _ in range(steps):
        ai.advance_autonomous_combat(step)


def _arm_attack_on_sight(ai, world, attack_cls):
    if not ai:
        return
    ai.add_target_to_attack_on_sight(unreal.Name("HitReactPlayer"))
    if attack_cls:
        order = unreal.new_object(attack_cls)
        order.configure(unreal.Name("HitReactAI"), unreal.Name("HitReactPlayer"), True)
        order.apply_in_world(world)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    attack_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttackTarget")
    damage_lib = unreal.ShockDamageLibrary

    if not ai_cls or not player_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("hit-reaction:\n- " + "\n- ".join(failures))

    spawned = []

    # (a) Mid-swing interrupt: stagger blocks player damage, knockback, then clears
    ai_loc = unreal.Vector(0.0, 0.0, 100.0)
    player_loc = unreal.Vector(120.0, 0.0, 100.0)
    ai = _spawn(
        subsystem,
        ai_cls,
        "HitReactAI",
        ai_loc,
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    player = _spawn(
        subsystem,
        player_cls,
        "HitReactPlayer",
        player_loc,
        unreal.Rotator(0.0, 180.0, 0.0),
    )
    spawned.extend([ai, player])

    if not ai or not player:
        failures.append("interrupt spawn")
    else:
        ai.configure_identity("Agg_BabyJane", "HitReactAI")
        ai.ensure_health_initialized()
        ai.ensure_controller_for_verify()
        player.ensure_health_initialized()
        _arm_attack_on_sight(ai, world, attack_cls)

        _tick_combat(ai, 1.5)
        pre_hit_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
        health_before_stagger = float(player.get_current_health())

        applied = float(damage_lib.apply_damage(ai, 15.0, player, unreal.Name("Verify")))
        stagger = float(ai.get_hit_react_remaining())
        post_apply_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
        report["interrupt"] = {
            "applied": applied,
            "stagger": stagger,
            "preHitDist": pre_hit_dist,
            "postApplyDist": post_apply_dist,
        }

        if applied <= 0.0:
            failures.append("damage not applied %.1f" % applied)
        if stagger <= 0.0:
            failures.append("stagger not started %.2f" % stagger)
        if post_apply_dist <= pre_hit_dist + 2.0:
            failures.append(
                "no knockback away from instigator %.1f -> %.1f"
                % (pre_hit_dist, post_apply_dist)
            )

        while float(ai.get_hit_react_remaining()) > 0.02:
            health_before_step = float(player.get_current_health())
            _tick_combat(ai, 0.05)
            if float(player.get_current_health()) < health_before_step - 0.5:
                failures.append(
                    "player damaged during stagger %.1f -> %.1f (react=%.2f)"
                    % (
                        health_before_step,
                        float(player.get_current_health()),
                        float(ai.get_hit_react_remaining()),
                    )
                )
                break

        post_knockback_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
        report["interrupt"]["postStaggerDist"] = post_knockback_dist

        _tick_combat(ai, 1.0)
        if float(ai.get_hit_react_remaining()) > 0.05:
            failures.append(
                "stagger did not clear %.2f" % float(ai.get_hit_react_remaining())
            )

        health_before_resume = float(player.get_current_health())
        _tick_combat(ai, 2.5)
        health_after_resume = float(player.get_current_health())
        report["interrupt"]["healthBeforeResume"] = health_before_resume
        report["interrupt"]["healthAfterResume"] = health_after_resume
        if health_after_resume >= health_before_resume - 1.0:
            failures.append(
                "attack did not resume after stagger %.1f -> %.1f"
                % (health_before_resume, health_after_resume)
            )

    for actor in spawned:
        if actor:
            subsystem.destroy_actor(actor)
    spawned = []

    # (b) Rapid fire: extend stagger but do not freeze permanently
    rapid_ai = _spawn(
        subsystem,
        ai_cls,
        "RapidHitAI",
        unreal.Vector(0.0, 200.0, 100.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    rapid_player = _spawn(
        subsystem,
        player_cls,
        "RapidHitPlayer",
        unreal.Vector(120.0, 200.0, 100.0),
        unreal.Rotator(0.0, 180.0, 0.0),
    )
    spawned.extend([rapid_ai, rapid_player])

    if not rapid_ai or not rapid_player:
        failures.append("rapid spawn")
    else:
        rapid_ai.configure_identity("Agg_BabyJane", "RapidHitAI")
        rapid_ai.ensure_health_initialized()
        rapid_ai.ensure_controller_for_verify()
        rapid_player.ensure_health_initialized()
        _arm_attack_on_sight(rapid_ai, world, attack_cls)
        _tick_combat(rapid_ai, 0.5)

        max_stagger = 0.0
        for _ in range(12):
            damage_lib.apply_damage(rapid_ai, 5.0, rapid_player, unreal.Name("Rapid"))
            _tick_combat(rapid_ai, 0.03)
            max_stagger = max(max_stagger, float(rapid_ai.get_hit_react_remaining()))

        _tick_combat(rapid_ai, 2.0)
        final_stagger = float(rapid_ai.get_hit_react_remaining())
        health_before = float(rapid_player.get_current_health())
        _tick_combat(rapid_ai, 2.5)
        health_after = float(rapid_player.get_current_health())

        report["rapid"] = {
            "maxStagger": max_stagger,
            "finalStagger": final_stagger,
            "healthBefore": health_before,
            "healthAfter": health_after,
        }

        if final_stagger > 0.05:
            failures.append("rapid fire left stagger active %.2f" % final_stagger)
        if max_stagger > 0.55:
            failures.append("rapid fire stacked excessive stagger %.2f" % max_stagger)
        if health_after >= health_before - 1.0:
            failures.append(
                "rapid fire permanently froze attacks %.1f -> %.1f"
                % (health_before, health_after)
            )

    for actor in spawned:
        if actor:
            subsystem.destroy_actor(actor)

    report["hit_reaction"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("hit-reaction:\n- " + "\n- ".join(failures))
    _log("PASS hit-reaction")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "hit_reaction_report.json"),
        )
    )
