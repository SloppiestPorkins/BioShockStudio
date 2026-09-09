"""Headless verify: plasmid framework + Electro Bolt (EVE, stun, cooldown, water chain)."""

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-plasmid] %s" % message)


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
    """Guarded teardown — a thrown/physics actor can leave the editor world and
    make destroy_actor log 'not part of the world editor' (counts as an error)."""
    for actor in actors:
        if not actor:
            continue
        try:
            if hasattr(actor, "is_valid") and not actor.is_valid():
                continue
            subsystem.destroy_actor(actor)
        except Exception:  # noqa: BLE001 -- teardown must not fail the verify
            pass


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def main(out):
    report = {"failures": [], "checks": 0}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    electro_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockElectroBoltPlasmid")
    water_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWaterVolume")
    equip_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEquipPlasmid")
    attack_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttackTarget")

    if not all([player_cls, ai_cls, electro_cls, equip_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("plasmid:\n- " + "\n- ".join(failures))

    spawned = []
    checks = 0

    def check(name, ok, detail=None):
        nonlocal checks
        checks += 1
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report.setdefault("results", []).append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    # --- (a) equip via action + cast at AI ---
    player_loc = unreal.Vector(0.0, 0.0, 100.0)
    ai_loc = unreal.Vector(600.0, 0.0, 100.0)
    player = _spawn(subsystem, player_cls, "PlasmidPlayer", player_loc)
    ai = _spawn(subsystem, ai_cls, "PlasmidAI", ai_loc)
    spawned.extend([player, ai])

    if not player or not ai:
        failures.append("spawn failed")
    else:
        ai.configure_identity("Agg_BabyJane", "PlasmidAI")
        ai.ensure_health_initialized()
        ai.ensure_controller_for_verify()
        player.ensure_health_initialized()
        player.set_current_eve_for_verify(100.0)

        equip = unreal.new_object(equip_cls)
        equip.configure(unreal.Name("ElectricBolt"), 0)
        equip.apply_in_world(world)
        check("equip_action", player.get_active_plasmid() is not None)

        yaw = _yaw_toward(player.get_actor_location(), ai.get_actor_location())
        player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

        if attack_cls:
            ai.add_target_to_attack_on_sight(unreal.Name("PlasmidPlayer"))
            order = unreal.new_object(attack_cls)
            order.configure(unreal.Name("PlasmidAI"), unreal.Name("PlasmidPlayer"), True)
            order.apply_in_world(world)
            _tick_combat(ai, 1.0)

        eve_before = float(player.get_current_eve())
        health_before = float(ai.get_current_health())
        cast_ok = bool(player.cast_active_plasmid())
        eve_after = float(player.get_current_eve())
        health_after = float(ai.get_current_health())
        stagger = float(ai.get_hit_react_remaining())

        report["cast"] = {
            "castOk": cast_ok,
            "eveBefore": eve_before,
            "eveAfter": eve_after,
            "healthBefore": health_before,
            "healthAfter": health_after,
            "stagger": stagger,
        }
        check("cast_ok", cast_ok)
        check("eve_spent", abs(eve_after - (eve_before - 15.0)) < 0.5, eve_after)
        check("ai_damaged", health_after < health_before - 0.5, health_after)
        check("stun_long", stagger > 0.5, stagger)

        health_mid_stagger = float(player.get_current_health())
        _tick_combat(ai, 0.3)
        if float(player.get_current_health()) < health_mid_stagger - 0.5:
            check("attack_blocked_during_stun", False, "player hit during stun")
        else:
            check("attack_blocked_during_stun", True)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (b) no EVE -> no-op ---
    dry_player = _spawn(
        subsystem, player_cls, "DryEvePlayer", unreal.Vector(0.0, 100.0, 100.0)
    )
    dry_ai = _spawn(
        subsystem, ai_cls, "DryEveAI", unreal.Vector(600.0, 100.0, 100.0)
    )
    spawned.extend([dry_player, dry_ai])
    if dry_player and dry_ai:
        dry_ai.ensure_health_initialized()
        dry_player.ensure_health_initialized()
        dry_player.equip_plasmid(electro_cls, 0)
        dry_player.set_current_eve_for_verify(0.0)
        yaw = _yaw_toward(dry_player.get_actor_location(), dry_ai.get_actor_location())
        dry_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
        hb = float(dry_ai.get_current_health())
        ok = bool(dry_player.cast_active_plasmid())
        ha = float(dry_ai.get_current_health())
        check("no_eve_no_cast", not ok and ha >= hb - 0.1, {"cast": ok, "health": ha})

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (c) cooldown -> second cast no-op ---
    cd_player = _spawn(
        subsystem, player_cls, "CdPlayer", unreal.Vector(0.0, 200.0, 100.0)
    )
    cd_ai = _spawn(
        subsystem, ai_cls, "CdAI", unreal.Vector(600.0, 200.0, 100.0)
    )
    spawned.extend([cd_player, cd_ai])
    if cd_player and cd_ai:
        cd_ai.ensure_health_initialized()
        cd_player.ensure_health_initialized()
        cd_player.equip_plasmid(electro_cls, 0)
        cd_player.set_current_eve_for_verify(100.0)
        yaw = _yaw_toward(cd_player.get_actor_location(), cd_ai.get_actor_location())
        cd_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
        first = bool(cd_player.cast_active_plasmid())
        eve_mid = float(cd_player.get_current_eve())
        second = bool(cd_player.cast_active_plasmid())
        eve_end = float(cd_player.get_current_eve())
        check(
            "cooldown_blocks_second",
            first and not second and abs(eve_end - eve_mid) < 0.1,
            {"first": first, "second": second, "eveMid": eve_mid, "eveEnd": eve_end},
        )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (d) water: 2x + chain ---
    if water_cls:
        w_player = _spawn(
            subsystem, player_cls, "WaterPlayer", unreal.Vector(0.0, 300.0, 100.0)
        )
        w_ai1 = _spawn(
            subsystem, ai_cls, "WaterAI1", unreal.Vector(600.0, 300.0, 100.0)
        )
        w_ai2 = _spawn(
            subsystem, ai_cls, "WaterAI2", unreal.Vector(650.0, 320.0, 100.0)
        )
        water = _spawn(
            subsystem,
            water_cls,
            "WaterVol",
            unreal.Vector(625.0, 310.0, 100.0),
        )
        spawned.extend([w_player, w_ai1, w_ai2, water])

        if w_player and w_ai1 and w_ai2 and water:
            for target in (w_ai1, w_ai2):
                target.configure_identity("Agg_BabyJane", target.get_actor_label())
                target.ensure_health_initialized()
            w_player.ensure_health_initialized()
            water.refresh_overlaps_for_verify()
            w_player.equip_plasmid(electro_cls, 0)
            w_player.set_current_eve_for_verify(100.0)
            yaw = _yaw_toward(w_player.get_actor_location(), w_ai1.get_actor_location())
            w_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

            h1b = float(w_ai1.get_current_health())
            h2b = float(w_ai2.get_current_health())
            ok = bool(w_player.cast_active_plasmid())
            h1a = float(w_ai1.get_current_health())
            h2a = float(w_ai2.get_current_health())
            plasmid = w_player.get_active_plasmid()
            hits = int(plasmid.get_last_hit_count_for_verify()) if plasmid else 0
            in_water = bool(plasmid.was_last_cast_in_water_for_verify()) if plasmid else False
            d1 = h1b - h1a
            d2 = h2b - h2a
            report["water"] = {
                "castOk": ok,
                "damagePrimary": d1,
                "damageChain": d2,
                "hits": hits,
                "inWater": in_water,
            }
            check("water_cast", ok and in_water)
            check("water_double_primary", d1 >= 25.0, d1)
            check("water_chain_hit", d2 >= 25.0 and hits >= 2, {"d2": d2, "hits": hits})
    else:
        failures.append("water volume class missing")

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (e) Incinerate: burst + burn ticks ---
    inc_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockIncineratePlasmid")
    if inc_cls:
        inc_player = _spawn(
            subsystem, player_cls, "IncineratePlayer", unreal.Vector(0.0, 400.0, 100.0)
        )
        inc_ai = _spawn(
            subsystem, ai_cls, "IncinerateAI", unreal.Vector(600.0, 400.0, 100.0)
        )
        spawned.extend([inc_player, inc_ai])
        if inc_player and inc_ai:
            inc_ai.configure_identity("Agg_BabyJane", "IncinerateAI")
            inc_ai.ensure_health_initialized()
            inc_ai.ensure_controller_for_verify()
            inc_player.ensure_health_initialized()
            inc_player.equip_plasmid(inc_cls, 0)
            inc_player.set_current_eve_for_verify(100.0)
            yaw = _yaw_toward(inc_player.get_actor_location(), inc_ai.get_actor_location())
            inc_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

            hb = float(inc_ai.get_current_health())
            cast_ok = bool(inc_player.cast_active_plasmid())
            ha_burst = float(inc_ai.get_current_health())
            burn_rem = float(inc_ai.get_burning_remaining())
            _tick_combat(inc_ai, 2.5)
            ha_burn = float(inc_ai.get_current_health())
            _tick_combat(inc_ai, 2.0)
            burn_done = float(inc_ai.get_burning_remaining()) <= 0.1
            ha_post_burn = float(inc_ai.get_current_health())
            _tick_combat(inc_ai, 1.0)
            ha_after = float(inc_ai.get_current_health())

            report["incinerate"] = {
                "castOk": cast_ok,
                "burstDrop": hb - ha_burst,
                "burnDrop": ha_burst - ha_burn,
                "afterBurn": ha_after,
                "burnRemainingMid": burn_rem,
            }
            check("incinerate_cast", cast_ok)
            check("incinerate_burst", hb - ha_burst >= 8.0, hb - ha_burst)
            check("incinerate_burning", burn_rem > 0.5, burn_rem)
            check("incinerate_burn_ticks", ha_burst - ha_burn >= 4.0, ha_burst - ha_burn)
            check(
                "incinerate_burn_stops",
                burn_done and abs(ha_post_burn - ha_after) < 1.0,
                {"postBurn": ha_post_burn, "after": ha_after, "burnDone": burn_done},
            )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (f) Incinerate oil slick ---
    oil_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockOilSlickVolume")
    if inc_cls and oil_cls:
        oil_player = _spawn(
            subsystem, player_cls, "OilPlayer", unreal.Vector(0.0, 500.0, 100.0)
        )
        oil_ai1 = _spawn(
            subsystem, ai_cls, "OilAI1", unreal.Vector(620.0, 500.0, 100.0)
        )
        oil_ai2 = _spawn(
            subsystem, ai_cls, "OilAI2", unreal.Vector(660.0, 520.0, 100.0)
        )
        oil = _spawn(
            subsystem,
            oil_cls,
            "OilVol",
            unreal.Vector(640.0, 510.0, 100.0),
        )
        spawned.extend([oil_player, oil_ai1, oil_ai2, oil])
        if oil_player and oil_ai1 and oil_ai2 and oil:
            for target in (oil_ai1, oil_ai2):
                target.configure_identity("Agg_BabyJane", target.get_actor_label())
                target.ensure_health_initialized()
            oil_player.ensure_health_initialized()
            oil.refresh_overlaps_for_verify()
            oil_player.equip_plasmid(inc_cls, 0)
            oil_player.set_current_eve_for_verify(100.0)
            yaw = _yaw_toward(oil_player.get_actor_location(), oil_ai1.get_actor_location())
            oil_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

            h1b = float(oil_ai1.get_current_health())
            h2b = float(oil_ai2.get_current_health())
            ok = bool(oil_player.cast_active_plasmid())
            h1a = float(oil_ai1.get_current_health())
            h2a = float(oil_ai2.get_current_health())
            plasmid = oil_player.get_active_plasmid()
            on_oil = bool(plasmid.was_last_cast_on_oil_for_verify()) if plasmid else False
            d1 = h1b - h1a
            d2 = h2b - h2a
            report["oil"] = {
                "castOk": ok,
                "onOil": on_oil,
                "damage1": d1,
                "damage2": d2,
                "ignited": bool(oil.get_editor_property("bIgnited")),
            }
            check("oil_cast", ok and on_oil)
            check("oil_primary", d1 >= 8.0, d1)
            check("oil_chain", d2 >= 8.0, d2)
            check("oil_consumed", bool(oil.get_editor_property("bIgnited")))

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (g) Telekinesis grab + throw ---
    tk_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTelekinesisPlasmid")
    grab_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockGrabbableActor")
    phys_lib = unreal.ShockPhysicsLibrary
    if tk_cls and grab_cls:
        tk_player = _spawn(
            subsystem, player_cls, "TkPlayer", unreal.Vector(0.0, 600.0, 100.0)
        )
        tk_ai = _spawn(
            subsystem, ai_cls, "TkAI", unreal.Vector(500.0, 600.0, 100.0)
        )
        prop = _spawn(
            subsystem,
            grab_cls,
            "TkProp",
            unreal.Vector(350.0, 600.0, 120.0),
        )
        spawned.extend([tk_player, tk_ai, prop])
        if tk_player and tk_ai and prop:
            tk_ai.configure_identity("Agg_BabyJane", "TkAI")
            tk_ai.ensure_health_initialized()
            tk_player.ensure_health_initialized()
            tk_player.equip_plasmid(tk_cls, 0)
            tk_player.set_current_eve_for_verify(100.0)
            yaw = _yaw_toward(tk_player.get_actor_location(), prop.get_actor_location())
            tk_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

            eve_before = float(tk_player.get_current_eve())
            grab_ok = bool(tk_player.cast_active_plasmid())
            eve_after_grab = float(tk_player.get_current_eve())
            plasmid = tk_player.get_active_plasmid()
            frozen = bool(phys_lib.is_actor_frozen_for_verify(prop))
            held = plasmid.get_held_actor_for_verify() if plasmid else None
            grab_action = str(plasmid.get_last_action_for_verify()) if plasmid else ""

            check("tk_grab_ok", grab_ok and frozen and held is not None)
            check("tk_grab_eve", abs(eve_after_grab - (eve_before - 2.5)) < 0.5, eve_after_grab)
            check("tk_grab_action", grab_action.lower().endswith("grab"), grab_action)

            yaw_throw = _yaw_toward(prop.get_actor_location(), tk_ai.get_actor_location())
            tk_player.set_actor_rotation(unreal.Rotator(0.0, yaw_throw, 0.0), False)
            hb = float(tk_ai.get_current_health())
            throw_ok = bool(tk_player.cast_active_plasmid())
            ha = float(tk_ai.get_current_health())
            throw_hit = bool(plasmid.did_last_throw_hit_for_verify()) if plasmid else False
            eve_after_throw = float(tk_player.get_current_eve())
            unfrozen = not bool(phys_lib.is_actor_frozen_for_verify(prop))

            report["telekinesis"] = {
                "grabOk": grab_ok,
                "throwOk": throw_ok,
                "throwHit": throw_hit,
                "aiDamage": hb - ha,
                "unfrozen": unfrozen,
            }
            check("tk_throw_ok", throw_ok)
            check("tk_throw_free_eve", abs(eve_after_throw - eve_after_grab) < 0.1, eve_after_throw)
            check(
                "tk_throw_damage_or_unfreeze",
                throw_hit or (hb - ha >= 10.0) or unfrozen,
                {"dmg": hb - ha, "hit": throw_hit, "unfrozen": unfrozen},
            )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (h) Telekinesis no EVE -> no grab ---
    if tk_cls and grab_cls:
        phys_lib = unreal.ShockPhysicsLibrary
        dry_tk_player = _spawn(
            subsystem, player_cls, "DryTkPlayer", unreal.Vector(0.0, 700.0, 100.0)
        )
        dry_prop = _spawn(
            subsystem,
            grab_cls,
            "DryTkProp",
            unreal.Vector(350.0, 700.0, 120.0),
        )
        spawned.extend([dry_tk_player, dry_prop])
        if dry_tk_player and dry_prop:
            dry_tk_player.ensure_health_initialized()
            dry_tk_player.equip_plasmid(tk_cls, 0)
            dry_tk_player.set_current_eve_for_verify(0.0)
            yaw = _yaw_toward(dry_tk_player.get_actor_location(), dry_prop.get_actor_location())
            dry_tk_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
            ok = bool(dry_tk_player.cast_active_plasmid())
            frozen = bool(phys_lib.is_actor_frozen_for_verify(dry_prop))
            check("tk_no_eve", not ok and not frozen, {"cast": ok, "frozen": frozen})

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (i) Winter Blast: cone freeze + shatter + thaw ---
    wb_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWinterBlastPlasmid")
    damage_lib = unreal.ShockDamageLibrary
    if wb_cls and damage_lib:
        wb_player = _spawn(
            subsystem, player_cls, "WinterPlayer", unreal.Vector(0.0, 800.0, 100.0)
        )
        wb_ai1 = _spawn(
            subsystem, ai_cls, "WinterAI1", unreal.Vector(500.0, 800.0, 100.0)
        )
        wb_ai2 = _spawn(
            subsystem, ai_cls, "WinterAI2", unreal.Vector(520.0, 830.0, 100.0)
        )
        spawned.extend([wb_player, wb_ai1, wb_ai2])
        if wb_player and wb_ai1 and wb_ai2:
            for target in (wb_ai1, wb_ai2):
                target.configure_identity("Agg_BabyJane", target.get_actor_label())
                target.ensure_health_initialized()
                target.ensure_controller_for_verify()
            wb_player.ensure_health_initialized()
            wb_player.equip_plasmid(wb_cls, 0)
            wb_player.set_current_eve_for_verify(100.0)
            yaw = _yaw_toward(wb_player.get_actor_location(), wb_ai1.get_actor_location())
            wb_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

            cast_ok = bool(wb_player.cast_active_plasmid())
            _tick_combat(wb_ai1, 0.05)
            _tick_combat(wb_ai2, 0.05)
            f1 = float(wb_ai1.get_frozen_solid_remaining())
            f2 = float(wb_ai2.get_frozen_solid_remaining())
            s1 = float(wb_ai1.get_max_walk_speed_for_verify())
            s2 = float(wb_ai2.get_max_walk_speed_for_verify())
            plasmid = wb_player.get_active_plasmid()
            frozen_n = int(plasmid.get_last_frozen_count_for_verify()) if plasmid else 0

            check("winter_cast", cast_ok and frozen_n >= 2, frozen_n)
            check("winter_frozen_both", f1 > 0.5 and f2 > 0.5, {"f1": f1, "f2": f2})
            check("winter_speed_zero", s1 < 0.1 and s2 < 0.1, {"s1": s1, "s2": s2})

            h_before = float(wb_ai1.get_current_health())
            applied = float(damage_lib.apply_damage(wb_ai1, 10.0, wb_player, unreal.Name("Verify")))
            h_after = float(wb_ai1.get_current_health())
            check("winter_shatter", applied >= 25.0, applied)
            check("winter_shatter_drop", h_before - h_after >= 25.0, h_before - h_after)

            _tick_combat(wb_ai1, 4.5)
            _tick_combat(wb_ai2, 4.5)
            thaw1 = float(wb_ai1.get_frozen_solid_remaining()) <= 0.1
            thaw2 = float(wb_ai2.get_frozen_solid_remaining()) <= 0.1
            speed1 = float(wb_ai1.get_max_walk_speed_for_verify())
            check("winter_thaw", thaw1 and thaw2, {"thaw1": thaw1, "thaw2": thaw2})
            check("winter_speed_restored", speed1 > 1.0, speed1)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (j) Insect Swarm: homing DoT + distract ---
    swarm_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockInsectSwarmPlasmid")
    if swarm_cls and attack_cls:
        sw_player = _spawn(
            subsystem, player_cls, "SwarmPlayer", unreal.Vector(0.0, 900.0, 100.0)
        )
        sw_victim = _spawn(
            subsystem, ai_cls, "SwarmVictim", unreal.Vector(500.0, 900.0, 100.0)
        )
        sw_dummy = _spawn(
            subsystem, player_cls, "SwarmDummy", unreal.Vector(560.0, 900.0, 100.0)
        )
        spawned.extend([sw_player, sw_victim, sw_dummy])
        if sw_player and sw_victim and sw_dummy:
            sw_victim.configure_identity("Agg_BabyJane", "SwarmVictim")
            sw_victim.ensure_health_initialized()
            sw_victim.ensure_controller_for_verify()
            sw_dummy.ensure_health_initialized()
            sw_player.ensure_health_initialized()
            sw_victim.add_target_to_attack_on_sight(unreal.Name("SwarmDummy"))
            order = unreal.new_object(attack_cls)
            order.configure(unreal.Name("SwarmVictim"), unreal.Name("SwarmDummy"), True)
            order.apply_in_world(world)
            _tick_combat(sw_victim, 1.0)
            dummy_h_pre = float(sw_dummy.get_current_health())

            sw_player.equip_plasmid(swarm_cls, 0)
            sw_player.set_current_eve_for_verify(100.0)
            yaw = _yaw_toward(sw_player.get_actor_location(), sw_victim.get_actor_location())
            sw_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
            cast_ok = bool(sw_player.cast_active_plasmid())
            plasmid = sw_player.get_active_plasmid()
            swarm = plasmid.get_last_spawned_swarm_for_verify() if plasmid else None
            check("swarm_cast", cast_ok and swarm is not None)

            hb = float(sw_victim.get_current_health())
            for _ in range(20):
                if swarm:
                    swarm.advance_for_verify(0.25)
            ha = float(sw_victim.get_current_health())
            dummy_h_mid = float(sw_dummy.get_current_health())
            check("swarm_dot", hb - ha >= 4.0, hb - ha)
            check(
                "swarm_distract",
                dummy_h_mid >= dummy_h_pre - 0.5,
                {"pre": dummy_h_pre, "mid": dummy_h_mid},
            )

            for _ in range(30):
                if swarm:
                    swarm.advance_for_verify(0.25)
            swarm_gone = swarm is None or float(swarm.get_remaining_life_for_verify()) <= 0.0
            ha_end = float(sw_victim.get_current_health())
            check("swarm_expired", swarm_gone)
            ha_before_wait = float(sw_victim.get_current_health())
            for _ in range(10):
                _tick_combat(sw_victim, 0.25)
            check(
                "swarm_damage_stops",
                abs(float(sw_victim.get_current_health()) - ha_before_wait) < 1.0,
            )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (k) Enrage: AI attacks other AI, not player ---
    enrage_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockEnragePlasmid")
    if enrage_cls and attack_cls:
        er_player = _spawn(
            subsystem, player_cls, "EnragePlayer", unreal.Vector(0.0, 1000.0, 100.0)
        )
        er_a = _spawn(
            subsystem, ai_cls, "EnrageA", unreal.Vector(800.0, 1000.0, 100.0)
        )
        er_b = _spawn(
            subsystem, ai_cls, "EnrageB", unreal.Vector(900.0, 1000.0, 100.0)
        )
        spawned.extend([er_player, er_a, er_b])
        if er_player and er_a and er_b:
            for target in (er_a, er_b):
                target.configure_identity("Agg_BabyJane", target.get_actor_label())
                target.ensure_health_initialized()
                target.ensure_controller_for_verify()
            er_player.ensure_health_initialized()
            er_a.add_target_to_attack_on_sight(unreal.Name("EnragePlayer"))
            order = unreal.new_object(attack_cls)
            order.configure(unreal.Name("EnrageA"), unreal.Name("EnragePlayer"), True)
            order.apply_in_world(world)
            _tick_combat(er_a, 0.5)

            er_player.equip_plasmid(enrage_cls, 0)
            er_player.set_current_eve_for_verify(100.0)
            yaw = _yaw_toward(er_player.get_actor_location(), er_a.get_actor_location())
            er_player.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
            cast_ok = bool(er_player.cast_active_plasmid())
            enraged = float(er_a.get_enraged_remaining()) > 0.5
            check("enrage_cast", cast_ok and enraged)

            player_h0 = float(er_player.get_current_health())
            b_h0 = float(er_b.get_current_health())
            _tick_combat(er_a, 3.0)
            player_h1 = float(er_player.get_current_health())
            b_h1 = float(er_b.get_current_health())
            check("enrage_player_safe", player_h1 >= player_h0 - 0.5, player_h1)
            check("enrage_hits_other", b_h0 - b_h1 >= 5.0, b_h0 - b_h1)

            _tick_combat(er_a, 12.0)
            enrage_done = float(er_a.get_enraged_remaining()) <= 0.1
            check("enrage_expired", enrage_done)
            player_h2 = float(er_player.get_current_health())
            er_player.set_actor_location(unreal.Vector(850.0, 1000.0, 100.0), False, None)
            reattack = unreal.new_object(attack_cls)
            reattack.configure(unreal.Name("EnrageA"), unreal.Name("EnragePlayer"), False)
            reattack.apply_in_world(world)
            _tick_combat(er_a, 2.0)
            player_h3 = float(er_player.get_current_health())
            check(
                "enrage_reverts",
                enrage_done and player_h3 < player_h2 - 0.5,
                {"h2": player_h2, "h3": player_h3},
            )

    # --- (h) the four added utility plasmids: resolve + cast + spawn presentation FX ---
    fx_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlasmidFx")
    util = [
        ("AirBlast", "SonicBoom"),
        ("SecurityBullseye", "SecurityBeacon"),
        ("TargetDummy", "DecoyHuman"),
        ("CycloneTrap", "SpringBoardTrap"),
    ]
    for name, alias in util:
        resolved = unreal.ShockPlasmid.resolve_plasmid_class(unreal.Name(name))
        alias_resolved = unreal.ShockPlasmid.resolve_plasmid_class(unreal.Name(alias))
        check("resolve_%s" % name, resolved is not None)
        check("resolve_alias_%s" % alias, alias_resolved is not None and alias_resolved == resolved)

    ut = _spawn(subsystem, ai_cls, "UtilPlasmidAI", unreal.Vector(500.0, 4000.0, 120.0))
    spawned.append(ut)
    if ut:
        ut.configure_identity("Agg_BabyJane", "UtilPlasmidAI")
        ut.ensure_health_initialized()
        ut.ensure_controller_for_verify()
    casts_ok = 0
    fx_spawned = False
    hand_seen = False
    for name, _alias in util:
        cls = unreal.ShockPlasmid.resolve_plasmid_class(unreal.Name(name))
        if not cls or not ut:
            continue
        # Fresh caster each time — plasmid cast cooldown can't be advanced headlessly.
        up = _spawn(subsystem, player_cls, "UtilPlasmidPlayer_%s" % name, unreal.Vector(0.0, 4000.0, 120.0))
        spawned.append(up)
        if not up:
            continue
        up.ensure_health_initialized()
        up.equip_plasmid(cls, 0)
        up.set_current_eve_for_verify(100.0)
        up.set_actor_rotation(
            unreal.Rotator(0.0, _yaw_toward(up.get_actor_location(), ut.get_actor_location()), 0.0), False
        )
        fx_before = len(unreal.GameplayStatics.get_all_actors_of_class(world, fx_cls)) if fx_cls else 0
        ok = bool(up.cast_active_plasmid())
        casts_ok += 1 if ok else 0
        report.setdefault("utility", {})[name] = ok
        fx_after = len(unreal.GameplayStatics.get_all_actors_of_class(world, fx_cls)) if fx_cls else 0
        if fx_after > fx_before:
            fx_spawned = True
        if up.is_plasmid_hands_visible_for_verify():
            hand_seen = True
    # CycloneTrap needs a world hit (no floor in this empty verify world); the other three don't.
    check("util_casts", casts_ok >= 3, casts_ok)
    check("util_hand_visible", hand_seen)
    check("util_cast_spawns_fx", fx_spawned)

    _destroy_all(subsystem, spawned)

    report["checks"] = checks
    report["plasmid"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("plasmid:\n- " + "\n- ".join(failures))
    _log("Success - %d" % checks)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "plasmid_report.json"),
        )
    )
