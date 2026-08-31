"""Headless verify: first-aid kits, EVE hypos, consumable pickups, carry caps."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-inventory] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _destroy_all(subsystem, actors):
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
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    pickup_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockConsumablePickup")

    if not all([player_cls, pickup_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("inventory:\n- " + "\n- ".join(failures))

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

    first_aid = unreal.Name("FirstAidKit")
    eve_hypo = unreal.Name("EveHypo")

    # --- (a) first-aid kit heals and consumes ---
    player = _spawn(subsystem, player_cls, "InvPlayer", unreal.Vector(0.0, 0.0, 100.0))
    spawned.append(player)
    if player:
        player.ensure_health_initialized()
        player.set_current_health_for_verify(50.0)
        player.add_stack_to_inventory(first_aid, 1)
        hb = float(player.get_current_health())
        kits_before = int(player.get_inventory_stack(first_aid))
        used = bool(player.use_first_aid_kit())
        ha = float(player.get_current_health())
        kits_after = int(player.get_inventory_stack(first_aid))
        report["first_aid"] = {
            "used": used,
            "healthBefore": hb,
            "healthAfter": ha,
            "kitsBefore": kits_before,
            "kitsAfter": kits_after,
        }
        check("first_aid_used", used)
        check("first_aid_healed", ha > hb + 0.5, ha)
        check("first_aid_consumed", kits_after == kits_before - 1, kits_after)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (b) full health -> no-op, kit kept ---
    full = _spawn(subsystem, player_cls, "FullPlayer", unreal.Vector(0.0, 100.0, 100.0))
    spawned.append(full)
    if full:
        full.ensure_health_initialized()
        full.add_stack_to_inventory(first_aid, 1)
        health_before = float(full.get_current_health())
        kits = int(full.get_inventory_stack(first_aid))
        ok = bool(full.use_first_aid_kit())
        check(
            "full_health_no_op",
            not ok
            and int(full.get_inventory_stack(first_aid)) == kits
            and float(full.get_current_health()) >= health_before - 0.1,
            {"used": ok, "kits": int(full.get_inventory_stack(first_aid))},
        )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (c) zero kits -> no-op ---
    dry = _spawn(subsystem, player_cls, "DryKitPlayer", unreal.Vector(0.0, 200.0, 100.0))
    spawned.append(dry)
    if dry:
        dry.ensure_health_initialized()
        dry.set_current_health_for_verify(40.0)
        ok = bool(dry.use_first_aid_kit())
        check("zero_kits_no_op", not ok, ok)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (d) EVE hypo refills and consumes ---
    eve_player = _spawn(subsystem, player_cls, "EvePlayer", unreal.Vector(0.0, 300.0, 100.0))
    spawned.append(eve_player)
    if eve_player:
        eve_player.ensure_health_initialized()
        eve_player.set_current_eve_for_verify(40.0)
        eve_player.add_stack_to_inventory(eve_hypo, 1)
        eve_before = float(eve_player.get_current_eve())
        hypos_before = int(eve_player.get_inventory_stack(eve_hypo))
        used = bool(eve_player.use_eve_hypo())
        eve_after = float(eve_player.get_current_eve())
        hypos_after = int(eve_player.get_inventory_stack(eve_hypo))
        report["eve_hypo"] = {
            "used": used,
            "eveBefore": eve_before,
            "eveAfter": eve_after,
            "hyposBefore": hypos_before,
            "hyposAfter": hypos_after,
        }
        check("eve_hypo_used", used)
        check("eve_hypo_refilled", eve_after > eve_before + 0.5, eve_after)
        check("eve_hypo_consumed", hypos_after == hypos_before - 1, hypos_after)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (e) carry cap clamps FirstAidKit ---
    cap_player = _spawn(subsystem, player_cls, "CapPlayer", unreal.Vector(0.0, 400.0, 100.0))
    spawned.append(cap_player)
    if cap_player:
        max_kits = int(cap_player.get_editor_property("max_first_aid_kits"))
        cap_player.add_stack_to_inventory(first_aid, max_kits + 5)
        count = int(cap_player.get_inventory_stack(first_aid))
        check("carry_cap_first_aid", count == max_kits, {"count": count, "max": max_kits})

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (f) consumable pickup: stack / money / ammo ---
    pickup_player = _spawn(
        subsystem, player_cls, "PickupPlayer", unreal.Vector(0.0, 500.0, 100.0)
    )
    weapon = None
    if weapon_cls:
        weapon = _spawn(
            subsystem,
            weapon_cls,
            "PickupWeapon",
            unreal.Vector(0.0, 500.0, 100.0),
        )
    kit_pickup = _spawn(
        subsystem, pickup_cls, "KitPickup", unreal.Vector(0.0, 500.0, 100.0)
    )
    money_pickup = _spawn(
        subsystem, pickup_cls, "MoneyPickup", unreal.Vector(0.0, 500.0, 100.0)
    )
    ammo_pickup = _spawn(
        subsystem, pickup_cls, "AmmoPickup", unreal.Vector(0.0, 500.0, 100.0)
    )
    spawned.extend([pickup_player, weapon, kit_pickup, money_pickup, ammo_pickup])

    if pickup_player and kit_pickup and money_pickup:
        pickup_player.ensure_health_initialized()
        kit_pickup.configure_for_verify(0, 2)  # FirstAidKit
        kits_before = int(pickup_player.get_inventory_stack(first_aid))
        kit_pickup.pickup_for_verify(pickup_player)
        kits_after = int(pickup_player.get_inventory_stack(first_aid))
        check("pickup_first_aid", kits_after == kits_before + 2, kits_after)

        money_pickup.configure_for_verify(2, 25)  # Money
        money_before = int(pickup_player.get_money())
        money_pickup.pickup_for_verify(pickup_player)
        money_after = int(pickup_player.get_money())
        check("pickup_money", money_after == money_before + 25, money_after)

    if pickup_player and weapon and ammo_pickup:
        weapon.configure_hitscan(10.0, 5000.0)
        weapon.configure_ammo(50, 100, 10.0, 2.5)
        weapon.initialize_ammo_full_mag(100)
        pickup_player.equip_weapon(weapon)
        reserve_before = int(weapon.get_reserve_ammo())
        ammo_pickup.configure_for_verify(3, 30)  # Ammo
        ammo_pickup.pickup_for_verify(pickup_player)
        reserve_after = int(weapon.get_reserve_ammo())
        check("pickup_ammo", reserve_after == reserve_before + 30, reserve_after)

    _destroy_all(subsystem, [a for a in [pickup_player, weapon] if a])

    report["checks"] = checks
    report["inventory"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("inventory:\n- " + "\n- ".join(failures))
    _log("Success - %d error(s)" % len(failures))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "inventory_report.json"),
        )
    )
