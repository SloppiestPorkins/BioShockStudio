"""Headless verify: Research Camera photos, per-archetype research, damage bonus."""

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-research-camera] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _yaw_toward(from_loc, to_loc):
    dx = float(to_loc.x - from_loc.x)
    dy = float(to_loc.y - from_loc.y)
    return math.degrees(math.atan2(dy, dx))


def _destroy_all(subsystem, actors):
    for actor in actors:
        if not actor:
            continue
        try:
            if hasattr(actor, "is_valid") and not actor.is_valid():
                continue
            subsystem.destroy_actor(actor)
        except Exception:  # noqa: BLE001
            pass


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _aim_and_fire(player, target_loc, camera):
    start = player.get_actor_location()
    yaw = _yaw_toward(start, target_loc)
    player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
    direction = unreal.Vector(
        math.cos(math.radians(yaw)),
        math.sin(math.radians(yaw)),
        0.0,
    )
    return bool(camera.fire_at(player, start, direction))


def main(out):
    report = {"failures": [], "checks": 0}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    camera_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockResearchCamera")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")

    if not all([player_cls, ai_cls, camera_cls, weapon_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("research-camera:\n- " + "\n- ".join(failures))

    spawned = []
    checks = 0
    archetype = unreal.Name("Agg_BabyJane")
    other_archetype = unreal.Name("Agg_Leadhead")

    def check(name, ok, detail=None):
        nonlocal checks
        checks += 1
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report.setdefault("results", []).append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    # --- (a) photos accumulate + level-up ---
    player_loc = unreal.Vector(0.0, 0.0, 100.0)
    ai_loc = unreal.Vector(800.0, 0.0, 100.0)
    player = _spawn(subsystem, player_cls, "PhotoPlayer", player_loc)
    ai = _spawn(subsystem, ai_cls, "PhotoAI", ai_loc)
    spawned.extend([player, ai])

    if not player or not ai:
        failures.append("photo spawn failed")
    else:
        ai.configure_identity("Agg_BabyJane", "PhotoAI")
        ai.ensure_health_initialized()
        player.ensure_health_initialized()
        camera = player.give_weapon(camera_cls, 7)
        player.select_weapon_slot(7)
        check("camera_slot7", camera is not None and player.get_active_weapon_slot() == 7)

        points_before = float(player.get_research_points_for_verify(archetype))
        level_before = int(player.get_research_level(archetype))
        mult_before = float(player.get_research_damage_multiplier(archetype))

        total_points = 0.0
        for shot in range(3):
            camera.clear_photo_cooldown_for_verify()
            camera.clear_fire_cooldown_for_verify()
            fired = _aim_and_fire(player, ai_loc, camera)
            score = float(camera.get_last_photo_score_for_verify())
            pts = float(camera.get_last_photo_points_for_verify())
            total_points += pts
            if shot == 0:
                check("first_photo_fired", fired, score)
                check("first_photo_score", score > 0.5, score)

        points_after = float(player.get_research_points_for_verify(archetype))
        level_after = int(player.get_research_level(archetype))
        mult_after = float(player.get_research_damage_multiplier(archetype))

        report["photos"] = {
            "pointsBefore": points_before,
            "pointsAfter": points_after,
            "levelBefore": level_before,
            "levelAfter": level_after,
            "multBefore": mult_before,
            "multAfter": mult_after,
            "totalAwarded": total_points,
        }
        check("points_accumulated", points_after > points_before + 50.0, points_after)
        check("level_crossed", level_after >= 1, level_after)
        check("multiplier_rises", mult_after > 1.0, mult_after)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (b) off-cone photo scores ~0 ---
    off_player = _spawn(subsystem, player_cls, "OffConePlayer", unreal.Vector(0.0, 200.0, 100.0))
    off_ai = _spawn(subsystem, ai_cls, "OffConeAI", unreal.Vector(800.0, 200.0, 100.0))
    spawned.extend([off_player, off_ai])
    if off_player and off_ai:
        off_ai.configure_identity("Agg_BabyJane", "OffConeAI")
        off_camera = off_player.give_weapon(camera_cls, 7)
        off_player.select_weapon_slot(7)
        off_player.set_actor_rotation(unreal.Rotator(0.0, 180.0, 0.0), False)
        off_camera.clear_fire_cooldown_for_verify()
        start = off_player.get_actor_location()
        direction = unreal.Vector(-1.0, 0.0, 0.0)
        off_camera.fire_at(off_player, start, direction)
        bad_score = float(off_camera.get_last_photo_score_for_verify())
        report["offConeScore"] = bad_score
        check("off_cone_low_score", bad_score < 0.15, bad_score)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (c) researched archetype takes boosted TommyGun damage ---
    dmg_player = _spawn(subsystem, player_cls, "DmgPlayer", unreal.Vector(0.0, 400.0, 100.0))
    researched_ai = _spawn(
        subsystem, ai_cls, "ResearchedAI", unreal.Vector(500.0, 400.0, 100.0)
    )
    other_ai = _spawn(
        subsystem, ai_cls, "OtherAI", unreal.Vector(500.0, 500.0, 100.0)
    )
    spawned.extend([dmg_player, researched_ai, other_ai])

    if dmg_player and researched_ai and other_ai:
        researched_ai.configure_identity("Agg_BabyJane", "ResearchedAI")
        other_ai.configure_identity("Agg_Leadhead", "OtherAI")
        researched_ai.ensure_health_initialized()
        other_ai.ensure_health_initialized()
        dmg_player.ensure_health_initialized()

        dmg_player.add_research_points(archetype, 150.0)
        mult = float(dmg_player.get_research_damage_multiplier(archetype))
        tommy = dmg_player.give_weapon_by_def(unreal.Name("TommyGun"), 2)
        dmg_player.select_weapon_slot(2)
        tommy.clear_fire_cooldown_for_verify()
        tommy.initialize_ammo_full_mag(150)

        base_dmg = 25.0
        direction = unreal.Vector(1.0, 0.0, 0.0)
        start = dmg_player.get_actor_location()

        hp_r_before = float(researched_ai.get_current_health())
        _aim_and_fire(dmg_player, researched_ai.get_actor_location(), tommy)
        hp_r_after = float(researched_ai.get_current_health())
        researched_dmg = hp_r_before - hp_r_after

        hp_o_before = float(other_ai.get_current_health())
        tommy.clear_fire_cooldown_for_verify()
        _aim_and_fire(dmg_player, other_ai.get_actor_location(), tommy)
        hp_o_after = float(other_ai.get_current_health())
        other_dmg = hp_o_before - hp_o_after

        report["damageBonus"] = {
            "multiplier": mult,
            "researchedDamage": researched_dmg,
            "otherDamage": other_dmg,
            "expectedBoosted": base_dmg * mult,
        }
        check("researched_hits_harder", researched_dmg > base_dmg + 0.5, researched_dmg)
        check("other_stays_base", abs(other_dmg - base_dmg) < 0.5, other_dmg)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (d) level-0 baseline exactly 25 ---
    base_player = _spawn(subsystem, player_cls, "BaseDmgPlayer", unreal.Vector(0.0, 600.0, 100.0))
    base_ai = _spawn(subsystem, ai_cls, "BaseDmgAI", unreal.Vector(500.0, 600.0, 100.0))
    spawned.extend([base_player, base_ai])
    if base_player and base_ai:
        base_ai.configure_identity("Agg_BabyJane", "BaseDmgAI")
        base_ai.ensure_health_initialized()
        base_player.ensure_health_initialized()
        check("level0_mult", abs(float(base_player.get_research_damage_multiplier(archetype)) - 1.0) < 0.01)

        base_tommy = base_player.give_weapon_by_def(unreal.Name("TommyGun"), 2)
        base_player.select_weapon_slot(2)
        base_tommy.clear_fire_cooldown_for_verify()
        base_tommy.initialize_ammo_full_mag(150)
        hp_before = float(base_ai.get_current_health())
        base_tommy.fire_at(base_player, base_player.get_actor_location(), unreal.Vector(1.0, 0.0, 0.0))
        hp_after = float(base_ai.get_current_health())
        base_dmg = hp_before - hp_after
        report["baseDamage"] = base_dmg
        check("level0_exact_25", abs(base_dmg - 25.0) < 0.5, base_dmg)

    _destroy_all(subsystem, spawned)

    report["checks"] = checks
    report["researchCamera"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("research-camera:\n- " + "\n- ".join(failures))
    _log("Success - %d error(s)" % len(failures))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "research_camera_report.json"),
        )
    )
