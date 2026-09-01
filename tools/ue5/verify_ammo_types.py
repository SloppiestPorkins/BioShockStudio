"""Headless verify: ammo-type switching for Pistol / TommyGun / Shotgun."""

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-ammo-types] %s" % message)


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


def _tick_combat(ai, seconds, step=0.05):
    steps = max(1, int(seconds / step))
    for _ in range(steps):
        ai.advance_autonomous_combat(step)


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


def _resolve_def(name):
    return unreal.ShockWeaponDefLibrary.resolve_weapon_def(unreal.Name(name))


def _ammo_entry(entry):
    effect = entry.effect
    try:
        effect_val = int(effect)
    except (TypeError, ValueError):
        effect_val = str(effect)
    return {
        "name": str(entry.name),
        "damage": float(entry.damage),
        "effect": effect_val,
        "reserve": int(entry.reserve_ammo),
    }


def main(out):
    report = {"failures": [], "checks": 0}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    water_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWaterVolume")

    if not all([player_cls, weapon_cls, ai_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("ammo-types:\n- " + "\n- ".join(failures))

    spawned = []
    checks = 0
    direction = unreal.Vector(1.0, 0.0, 0.0)

    def check(name, ok, detail=None):
        nonlocal checks
        checks += 1
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report.setdefault("results", []).append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    # --- Resolve ammo tables ---
    pistol_def = _resolve_def("Pistol")
    tommy_def = _resolve_def("TommyGun")
    shotgun_def = _resolve_def("Shotgun")
    if not pistol_def or not tommy_def or not shotgun_def:
        failures.append("Resolve missing pistol/tommy/shotgun")
    else:
        pistol_types = pistol_def.get_editor_property("ammo_types")
        tommy_types = tommy_def.get_editor_property("ammo_types")
        shotgun_types = shotgun_def.get_editor_property("ammo_types")
        report["resolve"] = {
            "pistol": [_ammo_entry(t) for t in pistol_types],
            "tommy": [_ammo_entry(t) for t in tommy_types],
            "shotgun": [_ammo_entry(t) for t in shotgun_types],
        }
        check("pistol_three_types", len(pistol_types) == 3, len(pistol_types))
        check(
            "pistol_numbers",
            abs(float(pistol_types[0].damage) - 40.0) < 0.01
            and abs(float(pistol_types[1].damage) - 40.0) < 0.01
            and abs(float(pistol_types[2].damage) - 40.0) < 0.01,
            report["resolve"]["pistol"],
        )
        check("tommy_three_types", len(tommy_types) == 3, len(tommy_types))
        check(
            "tommy_numbers",
            abs(float(tommy_types[0].damage) - 25.0) < 0.01
            and abs(float(tommy_types[1].damage) - 18.0) < 0.01
            and abs(float(tommy_types[2].damage) - 30.0) < 0.01,
            report["resolve"]["tommy"],
        )
        check("shotgun_three_types", len(shotgun_types) == 3, len(shotgun_types))
        check(
            "shotgun_numbers",
            abs(float(shotgun_types[0].damage) - 35.0) < 0.01
            and abs(float(shotgun_types[1].damage) - 35.0) < 0.01
            and abs(float(shotgun_types[2].damage) - 49.0) < 0.01,
            report["resolve"]["shotgun"],
        )

    # --- Cycle index + reserve swap ---
    base_loc = unreal.Vector(0.0, 0.0, 100.0)
    player = _spawn(subsystem, player_cls, "AmmoCyclePlayer", base_loc)
    cycle_weapon = _spawn(subsystem, weapon_cls, "AmmoCycleWeapon", base_loc)
    spawned.extend([player, cycle_weapon])
    if player and cycle_weapon and pistol_def:
        cycle_weapon.apply_def(pistol_def)
        cycle_weapon.initialize_ammo_full_mag(48)
        cycle_weapon.set_active_ammo_type_index_for_verify(0)
        cycle_weapon.set_ammo_state_for_verify(6, 12)
        idx0 = int(cycle_weapon.get_active_ammo_type_index())
        cycle_weapon.cycle_ammo_type()
        idx1 = int(cycle_weapon.get_active_ammo_type_index())
        reserve1 = int(cycle_weapon.get_reserve_ammo())
        cycle_weapon.set_ammo_state_for_verify(6, 7)
        cycle_weapon.cycle_ammo_type()
        idx2 = int(cycle_weapon.get_active_ammo_type_index())
        reserve2 = int(cycle_weapon.get_reserve_ammo())
        report["cycle"] = {
            "idx0": idx0,
            "idx1": idx1,
            "reserve1": reserve1,
            "idx2": idx2,
            "reserve2": reserve2,
        }
        check("cycle_advances", idx0 == 0 and idx1 == 1 and idx2 == 2, report["cycle"])
        check("cycle_reserve_swap", reserve1 == 48 and reserve2 == 48, report["cycle"])

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Default ammo damage (index 0) ---
    player = _spawn(subsystem, player_cls, "DefaultDmgPlayer", base_loc)
    spawned.append(player)
    if player and pistol_def and tommy_def and shotgun_def:
        pistol_w = _spawn(subsystem, weapon_cls, "DefaultPistol", base_loc)
        tommy_w = _spawn(
            subsystem, weapon_cls, "DefaultTommy", base_loc + unreal.Vector(0.0, 200.0, 0.0)
        )
        shotgun_w = _spawn(
            subsystem, weapon_cls, "DefaultShotgun", base_loc + unreal.Vector(0.0, 400.0, 0.0)
        )
        spawned.extend([pistol_w, tommy_w, shotgun_w])

        targets = []
        for i, loc_y in enumerate((0.0, 200.0, 400.0)):
            target = _spawn(
                subsystem,
                ai_cls,
                "DefaultTarget%d" % i,
                base_loc + unreal.Vector(500.0, loc_y, 0.0),
            )
            targets.append(target)
            spawned.append(target)

        if pistol_w and tommy_w and shotgun_w and len(targets) == 3:
            for t in targets:
                t.ensure_health_initialized()
            pistol_w.apply_def(pistol_def)
            pistol_w.initialize_ammo_full_mag(48)
            tommy_w.apply_def(tommy_def)
            tommy_w.initialize_ammo_full_mag(150)
            shotgun_w.apply_def(shotgun_def)
            shotgun_w.initialize_ammo_full_mag(24)

            for w in (pistol_w, tommy_w, shotgun_w):
                w.clear_fire_cooldown_for_verify()

            hb_p = float(targets[0].get_current_health())
            pistol_w.fire_at(player, base_loc, direction)
            drop_p = hb_p - float(targets[0].get_current_health())

            hb_t = float(targets[1].get_current_health())
            tommy_w.fire_at(
                player, base_loc + unreal.Vector(0.0, 200.0, 0.0), direction
            )
            drop_t = hb_t - float(targets[1].get_current_health())

            hb_s = float(targets[2].get_current_health())
            shotgun_w.fire_at(
                player, base_loc + unreal.Vector(0.0, 400.0, 0.0), direction
            )
            drop_s = hb_s - float(targets[2].get_current_health())

            report["defaultDamage"] = {
                "pistol": drop_p,
                "tommy": drop_t,
                "shotgun": drop_s,
            }
            check("default_pistol_40", abs(drop_p - 40.0) < 0.5, drop_p)
            check("default_tommy_25", abs(drop_t - 25.0) < 0.5, drop_t)
            check("default_shotgun_pellet_sum", drop_s >= 20.0 and drop_s <= 40.0, drop_s)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Electric buck in water (chain) ---
    if water_cls:
        w_player = _spawn(subsystem, player_cls, "ElecAmmoPlayer", unreal.Vector(0.0, 600.0, 100.0))
        w_ai1 = _spawn(
            subsystem, ai_cls, "ElecAmmoAI1", unreal.Vector(600.0, 600.0, 100.0)
        )
        w_ai2 = _spawn(
            subsystem, ai_cls, "ElecAmmoAI2", unreal.Vector(650.0, 620.0, 100.0)
        )
        water = _spawn(
            subsystem,
            water_cls,
            "ElecAmmoWater",
            unreal.Vector(625.0, 610.0, 100.0),
        )
        elec_weapon = _spawn(
            subsystem, weapon_cls, "ElecShotgun", unreal.Vector(0.0, 600.0, 100.0)
        )
        spawned.extend([w_player, w_ai1, w_ai2, water, elec_weapon])

        if w_player and w_ai1 and w_ai2 and water and elec_weapon and shotgun_def:
            for target in (w_ai1, w_ai2):
                target.configure_identity("Agg_BabyJane", target.get_actor_label())
                target.ensure_health_initialized()
            w_player.ensure_health_initialized()
            water.refresh_overlaps_for_verify()
            elec_weapon.apply_def(shotgun_def)
            elec_weapon.initialize_ammo_full_mag(24)
            elec_weapon.set_active_ammo_type_index_for_verify(1)
            elec_weapon.set_ammo_state_for_verify(4, 24)
            elec_weapon.clear_fire_cooldown_for_verify()
            yaw = _yaw_toward(w_player.get_actor_location(), w_ai1.get_actor_location())
            w_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

            h1b = float(w_ai1.get_current_health())
            h2b = float(w_ai2.get_current_health())
            elec_weapon.fire_at(
                w_player,
                unreal.Vector(0.0, 600.0, 100.0),
                unreal.Vector(1.0, 0.0, 0.0),
            )
            h1a = float(w_ai1.get_current_health())
            h2a = float(w_ai2.get_current_health())
            d1 = h1b - h1a
            d2 = h2b - h2a
            report["electricWater"] = {"primary": d1, "chain": d2}
            check("electric_primary_hit", d1 >= 20.0, d1)
            check("electric_water_chain", d2 >= 3.0, d2)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Incendiary ignite ---
    inc_player = _spawn(subsystem, player_cls, "IncAmmoPlayer", unreal.Vector(0.0, 800.0, 100.0))
    inc_ai = _spawn(subsystem, ai_cls, "IncAmmoAI", unreal.Vector(600.0, 800.0, 100.0))
    inc_weapon = _spawn(subsystem, weapon_cls, "IncPistol", unreal.Vector(0.0, 800.0, 100.0))
    spawned.extend([inc_player, inc_ai, inc_weapon])
    if inc_player and inc_ai and inc_weapon and pistol_def:
        inc_ai.configure_identity("Agg_BabyJane", "IncAmmoAI")
        inc_ai.ensure_health_initialized()
        inc_ai.ensure_controller_for_verify()
        inc_weapon.apply_def(pistol_def)
        inc_weapon.initialize_ammo_full_mag(48)
        inc_weapon.set_ammo_effect_for_verify(0, unreal.AmmoEffect.INCENDIARY)
        inc_weapon.clear_fire_cooldown_for_verify()
        yaw = _yaw_toward(inc_player.get_actor_location(), inc_ai.get_actor_location())
        inc_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

        hb = float(inc_ai.get_current_health())
        inc_weapon.fire_at(
            inc_player,
            unreal.Vector(0.0, 800.0, 100.0),
            unreal.Vector(1.0, 0.0, 0.0),
        )
        ha_burst = float(inc_ai.get_current_health())
        burn_rem = float(inc_ai.get_burning_remaining())
        _tick_combat(inc_ai, 2.5)
        ha_burn = float(inc_ai.get_current_health())
        report["incendiary"] = {
            "burstDrop": hb - ha_burst,
            "burnRemaining": burn_rem,
            "burnDrop": ha_burst - ha_burn,
        }
        check("incendiary_burning", burn_rem > 0.5, burn_rem)
        check("incendiary_burn_ticks", ha_burst - ha_burn >= 4.0, ha_burst - ha_burn)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Explosive radial on nearby pawn ---
    exp_player = _spawn(subsystem, player_cls, "ExpAmmoPlayer", unreal.Vector(0.0, 1000.0, 100.0))
    exp_primary = _spawn(
        subsystem, ai_cls, "ExpAmmoPrimary", unreal.Vector(600.0, 1000.0, 100.0)
    )
    exp_near = _spawn(
        subsystem, ai_cls, "ExpAmmoNear", unreal.Vector(640.0, 1010.0, 100.0)
    )
    exp_weapon = _spawn(subsystem, weapon_cls, "ExpShotgun", unreal.Vector(0.0, 1000.0, 100.0))
    spawned.extend([exp_player, exp_primary, exp_near, exp_weapon])
    if exp_player and exp_primary and exp_near and exp_weapon and shotgun_def:
        for target in (exp_primary, exp_near):
            target.configure_identity("Agg_BabyJane", target.get_actor_label())
            target.ensure_health_initialized()
        exp_weapon.apply_def(shotgun_def)
        exp_weapon.initialize_ammo_full_mag(24)
        exp_weapon.set_active_ammo_type_index_for_verify(2)
        exp_weapon.set_ammo_state_for_verify(4, 24)
        exp_weapon.clear_fire_cooldown_for_verify()
        yaw = _yaw_toward(exp_player.get_actor_location(), exp_primary.get_actor_location())
        exp_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

        hp_pri_b = float(exp_primary.get_current_health())
        hp_near_b = float(exp_near.get_current_health())
        exp_weapon.fire_at(
            exp_player,
            unreal.Vector(0.0, 1000.0, 100.0),
            unreal.Vector(1.0, 0.0, 0.0),
        )
        hp_pri_a = float(exp_primary.get_current_health())
        hp_near_a = float(exp_near.get_current_health())
        report["explosive"] = {
            "primaryDrop": hp_pri_b - hp_pri_a,
            "nearDrop": hp_near_b - hp_near_a,
        }
        check("explosive_primary", hp_pri_a < hp_pri_b - 30.0, hp_pri_b - hp_pri_a)
        check("explosive_radial_near", hp_near_a < hp_near_b - 3.0, hp_near_b - hp_near_a)

    _destroy_all(subsystem, spawned)

    report["checks"] = checks
    error_count = len(failures)
    report["errorCount"] = error_count
    report["ammo_types"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("ammo-types (%d errors):\n- " % error_count + "\n- ".join(failures))
    _log("Success - %d error(s)" % error_count)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "ammo_types_report.json"),
        )
    )
