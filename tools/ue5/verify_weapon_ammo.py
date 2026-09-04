"""Headless verify: TommyGun magazine, reload, reserve pool, pickup, fire rate.

Also asserts data-driven automatic hold-fire: TommyGun fires more than once across a held
trigger spanning >1 fire-rate interval; Pistol still fires exactly once per press.
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-weapon-ammo] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _fire_once(player, weapon):
    before = int(weapon.get_rounds_in_magazine())
    player.try_fire_equipped_weapon()
    return int(weapon.get_rounds_in_magazine()) < before


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    pickup_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockAmmoPickup")
    if not player_cls or not weapon_cls or not pickup_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("weapon-ammo:\n- " + "\n- ".join(failures))

    spawned = []
    base_loc = unreal.Vector(0.0, 0.0, 100.0)
    direction = unreal.Vector(1.0, 0.0, 0.0)

    player = _spawn(subsystem, player_cls, "AmmoPlayer", base_loc)
    weapon = _spawn(subsystem, weapon_cls, "AmmoWeapon", base_loc)
    spawned.extend([player, weapon])
    if not player or not weapon:
        failures.append("spawn player/weapon")
    else:
        weapon.configure_hitscan(15.0, 5000.0)
        weapon.configure_ammo(50, 150, 10.0, 2.5)
        weapon.initialize_ammo_full_mag(150)
        weapon.set_auto_reload(False)
        player.equip_weapon(weapon)

        mag_size = int(weapon.get_magazine_size())
        start_fire = int(weapon.get_fire_count())
        start_reserve = int(weapon.get_reserve_ammo())

        shots = 0
        while int(weapon.get_rounds_in_magazine()) > 0:
            weapon.clear_fire_cooldown_for_verify()
            if not _fire_once(player, weapon):
                failures.append("fire did not consume ammo with rounds left")
                break
            shots += 1

        report["emptyMag"] = {
            "magSize": mag_size,
            "shots": shots,
            "roundsLeft": int(weapon.get_rounds_in_magazine()),
            "fireCount": int(weapon.get_fire_count()) - start_fire,
        }
        if shots != mag_size:
            failures.append("shots != magazine size (%d != %d)" % (shots, mag_size))
        if int(weapon.get_rounds_in_magazine()) != 0:
            failures.append("mag not empty after drain")

        weapon.clear_fire_cooldown_for_verify()
        if _fire_once(player, weapon):
            failures.append("dry fire consumed ammo when mag empty")
        report["dryFire"] = "ok"

        reserve_before_reload = int(weapon.get_reserve_ammo())
        if not bool(player.try_reload_equipped_weapon()):
            failures.append("reload refused")
        elif not weapon.is_reloading:
            failures.append("reload did not start")
        else:
            weapon.advance_reload_for_verify(2.5)
            if weapon.is_reloading:
                failures.append("reload still active after delay")
            mag_after = int(weapon.get_rounds_in_magazine())
            reserve_after = int(weapon.get_reserve_ammo())
            transferred = mag_after
            report["reload"] = {
                "magAfter": mag_after,
                "reserveBefore": reserve_before_reload,
                "reserveAfter": reserve_after,
                "transferred": transferred,
            }
            if mag_after != mag_size:
                failures.append("mag not full after reload (%d != %d)" % (mag_after, mag_size))
            if reserve_after != reserve_before_reload - mag_size:
                failures.append(
                    "reserve drop wrong %d -> %d expected %d"
                    % (reserve_before_reload, reserve_after, reserve_before_reload - mag_size)
                )

            weapon.clear_fire_cooldown_for_verify()
            if not _fire_once(player, weapon):
                failures.append("post-reload fire did not consume ammo")
            report["postReloadFire"] = "ok"

        pickup_loc = base_loc + unreal.Vector(0.0, 200.0, 0.0)
        pickup = _spawn(subsystem, pickup_cls, "AmmoPickup", pickup_loc)
        spawned.append(pickup)
        if not pickup:
            failures.append("pickup spawn")
        else:
            pickup.set_editor_property("pickup_amount", 60)
            reserve_before_pickup = int(weapon.get_reserve_ammo())
            player.set_actor_location(pickup_loc, False, False)
            pickup.try_grant_overlapping_player()
            spawned.remove(pickup)
            reserve_after_pickup = int(weapon.get_reserve_ammo())
            report["pickup"] = {
                "reserveBefore": reserve_before_pickup,
                "reserveAfter": reserve_after_pickup,
            }
            if reserve_after_pickup != reserve_before_pickup + 60:
                failures.append(
                    "pickup reserve wrong %d -> %d"
                    % (reserve_before_pickup, reserve_after_pickup)
                )

        rate_weapon = _spawn(subsystem, weapon_cls, "RateWeapon", base_loc + unreal.Vector(500.0, 0.0, 0.0))
        spawned.append(rate_weapon)
        if not rate_weapon:
            failures.append("rate weapon spawn")
        else:
            rate_weapon.configure_hitscan(1.0, 5000.0)
            rate_weapon.configure_ammo(100, 0, 10.0, 2.5)
            rate_weapon.initialize_ammo_full_mag(0)
            rate_weapon.set_auto_reload(False)
            rate_weapon.clear_fire_cooldown_for_verify()
            burst = 0
            for _ in range(20):
                before = int(rate_weapon.get_rounds_in_magazine())
                rate_weapon.fire_at(
                    player, base_loc + unreal.Vector(500.0, 0.0, 100.0), direction
                )
                if int(rate_weapon.get_rounds_in_magazine()) < before:
                    burst += 1
            report["fireRateBurst"] = burst
            if burst != 1:
                failures.append("fire-rate burst expected 1 got %d" % burst)

            timed = 0
            for _ in range(12):
                rate_weapon.advance_fire_rate_clock_for_verify(0.11)
                before = int(rate_weapon.get_rounds_in_magazine())
                rate_weapon.fire_at(
                    player, base_loc + unreal.Vector(500.0, 0.0, 100.0), direction
                )
                if int(rate_weapon.get_rounds_in_magazine()) < before:
                    timed += 1
            report["fireRateTimed"] = timed
            if timed < 10 or timed > 12:
                failures.append("fire-rate timed expected ~11 got %d" % timed)

        # --- Automatic hold-fire (TommyGun) vs semi-auto (Pistol) ---
        # DriveFireInputForVerify mirrors ActionMapping Fire press/release; AdvanceHeldFire
        # advances the rate clock and re-triggers only when bAutomatic.
        tommy = player.give_weapon_by_def(unreal.Name("TommyGun"), 2)
        pistol = player.give_weapon_by_def(unreal.Name("Pistol"), 1)
        if not tommy or not pistol:
            failures.append("GiveWeaponByDef TommyGun/Pistol for auto-fire verify")
        else:
            if not bool(tommy.is_automatic()):
                failures.append("TommyGun def should be automatic")
            if bool(pistol.is_automatic()):
                failures.append("Pistol def should be semi-auto (not automatic)")

            tommy.set_auto_reload(False)
            tommy.initialize_ammo_full_mag(150)
            player.equip_weapon(tommy)
            tommy.clear_fire_cooldown_for_verify()
            mag_before = int(tommy.get_rounds_in_magazine())
            player.drive_fire_input_for_verify(True)
            # >1 fire-rate interval at 10 rps (0.1s): hold across ~0.35s → expect ≥3 shots
            for _ in range(7):
                player.advance_held_fire_for_verify(0.05)
            player.drive_fire_input_for_verify(False)
            mag_after = int(tommy.get_rounds_in_magazine())
            tommy_shots = mag_before - mag_after
            report["tommyAutoHold"] = {
                "shots": tommy_shots,
                "magBefore": mag_before,
                "magAfter": mag_after,
            }
            if tommy_shots < 2:
                failures.append(
                    "TommyGun hold-fire expected >1 shot over >1 fire interval, got %d"
                    % tommy_shots
                )

            pistol.set_auto_reload(False)
            pistol.initialize_ammo_full_mag(48)
            player.equip_weapon(pistol)
            pistol.clear_fire_cooldown_for_verify()
            p_before = int(pistol.get_rounds_in_magazine())
            player.drive_fire_input_for_verify(True)
            for _ in range(7):
                player.advance_held_fire_for_verify(0.05)
            player.drive_fire_input_for_verify(False)
            p_after = int(pistol.get_rounds_in_magazine())
            pistol_shots = p_before - p_after
            report["pistolSemiHold"] = {
                "shots": pistol_shots,
                "magBefore": p_before,
                "magAfter": p_after,
            }
            if pistol_shots != 1:
                failures.append(
                    "Pistol hold should fire exactly once per press, got %d" % pistol_shots
                )

    for actor in spawned:
        if actor:
            try:
                subsystem.destroy_actor(actor)
            except Exception:
                pass

    report["weapon_ammo"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-ammo:\n- " + "\n- ".join(failures))
    _log("PASS weapon-ammo")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_ammo_report.json"),
        )
    )
