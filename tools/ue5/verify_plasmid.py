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
