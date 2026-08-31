"""Headless verify: beam fire mode, Chemical Thrower, Crossbow."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-weapon-beam] %s" % message)


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
        except Exception:  # noqa: BLE001
            pass


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _resolve_def(name):
    return unreal.ShockWeaponDefLibrary.resolve_weapon_def(unreal.Name(name))


def _find_projectiles(projectile_cls):
    world = unreal.EditorLevelLibrary.get_editor_world()
    return unreal.GameplayStatics.get_all_actors_of_class(world, projectile_cls)


def _tick_combat(ai, seconds, step=0.05):
    steps = max(1, int(seconds / step))
    for _ in range(steps):
        ai.advance_autonomous_combat(step)


def _beam_status(name):
    return getattr(unreal.BeamStatus, name)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    pawn_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    projectile_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockProjectile")

    if not all([player_cls, weapon_cls, pawn_cls, projectile_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("weapon-beam:\n- " + "\n- ".join(failures))

    spawned = []
    base_loc = unreal.Vector(0.0, 0.0, 100.0)
    direction = unreal.Vector(1.0, 0.0, 0.0)

    # --- Chemical Thrower burning beam in range ---
    chem_def = _resolve_def("ChemicalThrower")
    if not chem_def:
        failures.append("Resolve(ChemicalThrower) null")
    else:
        player = _spawn(subsystem, player_cls, "BeamPlayer", base_loc)
        weapon = _spawn(subsystem, weapon_cls, "ChemWeapon", base_loc)
        target = _spawn(subsystem, pawn_cls, "BeamTarget", base_loc + unreal.Vector(400.0, 0.0, 0.0))
        spawned.extend([player, weapon, target])
        if not all([player, weapon, target]):
            failures.append("chem beam spawn")
        else:
            weapon.apply_def(chem_def)
            weapon.initialize_ammo_full_mag(int(chem_def.get_editor_property("reserve_ammo")))
            target.ensure_health_initialized()
            target.ensure_controller_for_verify()
            hp0 = float(target.get_current_health())
            mag0 = int(weapon.get_rounds_in_magazine())
            for _ in range(5):
                weapon.clear_fire_cooldown_for_verify()
                weapon.fire_at(player, base_loc, direction)
                weapon.advance_fire_rate_clock_for_verify(0.11)
            hp1 = float(target.get_current_health())
            burn_after_ticks = float(target.get_burning_remaining())
            weapon.stop_beam()
            hp_stop = float(target.get_current_health())
            _tick_combat(target, 0.5)
            hp_mid_burn = float(target.get_current_health())
            _tick_combat(target, 1.2)
            hp_burn_done = float(target.get_current_health())
            mag1 = int(weapon.get_rounds_in_magazine())
            report["chemBeam"] = {
                "health0": hp0,
                "healthAfterTicks": hp1,
                "burnRemaining": burn_after_ticks,
                "healthAfterStop": hp_stop,
                "healthMidBurn": hp_mid_burn,
                "healthBurnDone": hp_burn_done,
                "magBefore": mag0,
                "magAfter": mag1,
            }
            tick_drop = hp0 - hp1
            if tick_drop < 10.0:
                failures.append("chem beam tick damage too low %.1f" % tick_drop)
            if burn_after_ticks <= 0.05:
                failures.append("chem beam did not ignite target")
            if hp_mid_burn >= hp_stop - 0.5:
                failures.append("chem burn did not continue after stop")
            if float(target.get_burning_remaining()) > 0.05:
                failures.append("chem burn linger did not expire")
            if mag1 >= mag0:
                failures.append("chem beam did not consume ammo")

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Beam out of range ---
    if chem_def:
        player = _spawn(subsystem, player_cls, "BeamFarPlayer", base_loc + unreal.Vector(0.0, 500.0, 0.0))
        weapon = _spawn(subsystem, weapon_cls, "ChemFarWeapon", base_loc + unreal.Vector(0.0, 500.0, 0.0))
        far = _spawn(
            subsystem,
            pawn_cls,
            "BeamFarTarget",
            base_loc + unreal.Vector(0.0, 500.0, 0.0) + unreal.Vector(2000.0, 0.0, 0.0),
        )
        spawned.extend([player, weapon, far])
        if player and weapon and far:
            weapon.apply_def(chem_def)
            weapon.initialize_ammo_full_mag(300)
            far.ensure_health_initialized()
            hp_before = float(far.get_current_health())
            weapon.clear_fire_cooldown_for_verify()
            hit = weapon.fire_at(player, base_loc + unreal.Vector(0.0, 500.0, 0.0), direction)
            hp_after = float(far.get_current_health())
            report["chemOutOfRange"] = {"hit": bool(hit), "healthDrop": hp_before - hp_after}
            if hit or hp_after < hp_before - 0.5:
                failures.append("chem beam hit out-of-range target")

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Electric beam stun ---
    if chem_def:
        player = _spawn(subsystem, player_cls, "ElecPlayer", base_loc + unreal.Vector(0.0, 1000.0, 0.0))
        weapon = _spawn(subsystem, weapon_cls, "ElecWeapon", base_loc + unreal.Vector(0.0, 1000.0, 0.0))
        target = _spawn(
            subsystem,
            pawn_cls,
            "ElecTarget",
            base_loc + unreal.Vector(0.0, 1000.0, 0.0) + unreal.Vector(400.0, 0.0, 0.0),
        )
        spawned.extend([player, weapon, target])
        if player and weapon and target:
            weapon.apply_def(chem_def)
            weapon.initialize_ammo_full_mag(int(chem_def.get_editor_property("reserve_ammo")))
            weapon.set_beam_status_for_verify(_beam_status("ELECTRIC"))
            target.ensure_health_initialized()
            target.ensure_controller_for_verify()
            weapon.clear_fire_cooldown_for_verify()
            weapon.fire_at(player, base_loc + unreal.Vector(0.0, 1000.0, 0.0), direction)
            stagger = float(target.get_hit_react_remaining())
            report["electricBeam"] = {"stagger": stagger}
            if stagger <= 0.05:
                failures.append("electric beam did not stun")

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Freeze beam chill ---
    if chem_def:
        player = _spawn(subsystem, player_cls, "FreezePlayer", base_loc + unreal.Vector(0.0, 1500.0, 0.0))
        weapon = _spawn(subsystem, weapon_cls, "FreezeWeapon", base_loc + unreal.Vector(0.0, 1500.0, 0.0))
        target = _spawn(
            subsystem,
            pawn_cls,
            "FreezeTarget",
            base_loc + unreal.Vector(0.0, 1500.0, 0.0) + unreal.Vector(400.0, 0.0, 0.0),
        )
        spawned.extend([player, weapon, target])
        if player and weapon and target:
            weapon.apply_def(chem_def)
            weapon.initialize_ammo_full_mag(int(chem_def.get_editor_property("reserve_ammo")))
            weapon.set_beam_status_for_verify(_beam_status("FREEZE"))
            target.ensure_health_initialized()
            target.ensure_controller_for_verify()
            _tick_combat(target, 0.05)
            speed_before = float(target.get_max_walk_speed_for_verify())
            weapon.clear_fire_cooldown_for_verify()
            weapon.fire_at(player, base_loc + unreal.Vector(0.0, 1500.0, 0.0), direction)
            _tick_combat(target, 0.05)
            speed_chilled = float(target.get_max_walk_speed_for_verify())
            chill = float(target.get_chill_remaining())
            report["freezeBeam"] = {
                "speedBefore": speed_before,
                "speedChilled": speed_chilled,
                "chillRemaining": chill,
            }
            if chill <= 0.05:
                failures.append("freeze beam did not chill")
            if speed_chilled >= speed_before * 0.75:
                failures.append(
                    "freeze beam speed %.1f not below baseline %.1f" % (speed_chilled, speed_before)
                )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Crossbow projectile ---
    xbow_def = _resolve_def("Crossbow")
    if not xbow_def:
        failures.append("Resolve(Crossbow) null")
    else:
        player = _spawn(subsystem, player_cls, "XbowPlayer", base_loc + unreal.Vector(0.0, 2000.0, 0.0))
        weapon = _spawn(subsystem, weapon_cls, "XbowWeapon", base_loc + unreal.Vector(0.0, 2000.0, 0.0))
        target = _spawn(
            subsystem,
            pawn_cls,
            "XbowTarget",
            base_loc + unreal.Vector(0.0, 2000.0, 0.0) + unreal.Vector(800.0, 0.0, 0.0),
        )
        spawned.extend([player, weapon, target])
        if player and weapon and target:
            weapon.apply_def(xbow_def)
            weapon.initialize_ammo_full_mag(6)
            weapon.clear_fire_cooldown_for_verify()
            target.ensure_health_initialized()
            dmg = float(xbow_def.get_editor_property("damage"))
            hp_before = float(target.get_current_health())
            mag_before = int(weapon.get_rounds_in_magazine())
            loc = base_loc + unreal.Vector(0.0, 2000.0, 0.0)
            fired = weapon.fire_at(player, loc, direction)
            projectiles = _find_projectiles(projectile_cls)
            report["crossbow"] = {
                "fired": bool(fired),
                "projectileCount": len(projectiles),
                "damage": dmg,
                "magBefore": mag_before,
            }
            if not fired or not projectiles:
                failures.append("crossbow did not spawn projectile")
            else:
                projectile = projectiles[-1]
                for _ in range(80):
                    if projectile.has_impacted_for_verify():
                        break
                    projectile.advance_for_verify(0.05)
                hp_after = float(target.get_current_health())
                mag_after = int(weapon.get_rounds_in_magazine())
                drop = hp_before - hp_after
                report["crossbow"]["healthDrop"] = drop
                report["crossbow"]["magAfter"] = mag_after
                report["crossbow"]["impacted"] = bool(projectile.has_impacted_for_verify())
                if drop < dmg - 1.0:
                    failures.append("crossbow damage expected %.1f got %.1f" % (dmg, drop))
                if mag_after != mag_before - 1:
                    failures.append("crossbow consumed wrong ammo")

    _destroy_all(subsystem, spawned)

    error_count = len(failures)
    report["errorCount"] = error_count
    report["weapon_beam"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-beam (%d errors):\n- " % error_count + "\n- ".join(failures))
    _log("Success - %d error(s)" % error_count)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_beam_report.json"),
        )
    )
