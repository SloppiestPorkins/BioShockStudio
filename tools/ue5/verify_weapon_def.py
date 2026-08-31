"""Headless verify: UShockWeaponDef Resolve + hitscan / melee / projectile fire modes."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-weapon-def] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _resolve_def(name):
    return unreal.ShockWeaponDefLibrary.resolve_weapon_def(unreal.Name(name))


def _find_projectiles(projectile_cls):
    world = unreal.EditorLevelLibrary.get_editor_world()
    return unreal.GameplayStatics.get_all_actors_of_class(world, projectile_cls)


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
        raise RuntimeError("weapon-def:\n- " + "\n- ".join(failures))

    spawned = []
    base_loc = unreal.Vector(0.0, 0.0, 100.0)
    direction = unreal.Vector(1.0, 0.0, 0.0)

    player = _spawn(subsystem, player_cls, "DefPlayer", base_loc)
    spawned.append(player)

    # --- TommyGun hitscan ---
    tommy_def = _resolve_def("TommyGun")
    if not tommy_def:
        failures.append("Resolve(TommyGun) null")
    else:
        weapon = _spawn(subsystem, weapon_cls, "TommyWeapon", base_loc)
        target = _spawn(subsystem, pawn_cls, "TommyTarget", base_loc + unreal.Vector(500.0, 0.0, 0.0))
        spawned.extend([weapon, target])
        if not weapon or not target:
            failures.append("tommy spawn")
        else:
            weapon.apply_def(tommy_def)
            weapon.initialize_ammo_full_mag(150)
            weapon.clear_fire_cooldown_for_verify()
            target.ensure_health_initialized()
            hp_before = float(target.get_current_health())
            dmg = float(tommy_def.get_editor_property("damage"))
            weapon.fire_at(player, base_loc, direction)
            hp_after = float(target.get_current_health())
            report["tommyGun"] = {
                "damage": dmg,
                "healthBefore": hp_before,
                "healthAfter": hp_after,
            }
            if abs((hp_before - hp_after) - dmg) > 0.5:
                failures.append(
                    "tommy hitscan damage expected %.1f got %.1f"
                    % (dmg, hp_before - hp_after)
                )

            # bEnforceAmmo gates empty mag
            weapon.set_auto_reload(False)
            while int(weapon.get_rounds_in_magazine()) > 0:
                weapon.clear_fire_cooldown_for_verify()
                weapon.fire_at(player, base_loc, direction)
            reserve_before = int(weapon.get_reserve_ammo())
            if not weapon.reload():
                failures.append("tommy reload refused")
            else:
                weapon.advance_reload_for_verify(2.5)
                if weapon.is_reloading:
                    failures.append("tommy reload stuck")
                report["tommyAmmoGate"] = {
                    "magAfterReload": int(weapon.get_rounds_in_magazine()),
                    "reserveAfterReload": int(weapon.get_reserve_ammo()),
                }

    # --- Wrench melee ---
    wrench_def = _resolve_def("Wrench")
    if not wrench_def:
        failures.append("Resolve(Wrench) null")
    else:
        wrench = _spawn(subsystem, weapon_cls, "WrenchWeapon", base_loc + unreal.Vector(0.0, 300.0, 0.0))
        near = _spawn(
            subsystem,
            pawn_cls,
            "WrenchNear",
            base_loc + unreal.Vector(0.0, 300.0, 0.0) + unreal.Vector(120.0, 0.0, 0.0),
        )
        far = _spawn(
            subsystem,
            pawn_cls,
            "WrenchFar",
            base_loc + unreal.Vector(0.0, 300.0, 0.0) + unreal.Vector(800.0, 0.0, 0.0),
        )
        spawned.extend([wrench, near, far])
        if not wrench or not near or not far:
            failures.append("wrench spawn")
        else:
            wrench.apply_def(wrench_def)
            wrench.configure_ammo(1, 0, 1.0, 1.0)
            wrench.initialize_ammo_full_mag(0)
            wrench.clear_fire_cooldown_for_verify()
            near.ensure_health_initialized()
            far.ensure_health_initialized()
            near_before = float(near.get_current_health())
            far_before = float(far.get_current_health())
            wrench_loc = base_loc + unreal.Vector(0.0, 300.0, 0.0)
            hit_near = wrench.fire_at(player, wrench_loc, direction)
            wrench.clear_fire_cooldown_for_verify()
            miss_dir = unreal.Vector(0.0, 1.0, 0.0)
            hit_far = wrench.fire_at(player, wrench_loc, miss_dir)
            near_after = float(near.get_current_health())
            far_after = float(far.get_current_health())
            report["wrench"] = {
                "hitNear": bool(hit_near),
                "hitFar": bool(hit_far),
                "nearDrop": near_before - near_after,
                "farDrop": far_before - far_after,
                "magAfter": int(wrench.get_rounds_in_magazine()),
            }
            if not hit_near or near_after >= near_before - 0.5:
                failures.append("wrench missed near target")
            if hit_far or far_after < far_before - 0.5:
                failures.append("wrench hit far target")
            if int(wrench.get_rounds_in_magazine()) != 1:
                failures.append("wrench consumed ammo")

    # --- GrenadeLauncher projectile ---
    gl_def = _resolve_def("GrenadeLauncher")
    if not gl_def:
        failures.append("Resolve(GrenadeLauncher) null")
    else:
        launcher = _spawn(subsystem, weapon_cls, "GLWeapon", base_loc + unreal.Vector(0.0, 900.0, 0.0))
        cluster_a = _spawn(
            subsystem,
            pawn_cls,
            "GLTargetA",
            base_loc + unreal.Vector(0.0, 900.0, 0.0) + unreal.Vector(700.0, 0.0, 0.0),
        )
        cluster_b = _spawn(
            subsystem,
            pawn_cls,
            "GLTargetB",
            base_loc + unreal.Vector(0.0, 900.0, 0.0) + unreal.Vector(720.0, 20.0, 0.0),
        )
        spawned.extend([launcher, cluster_a, cluster_b])
        if not launcher or not cluster_a or not cluster_b:
            failures.append("grenade launcher spawn")
        else:
            launcher.apply_def(gl_def)
            launcher.initialize_ammo_full_mag(12)
            launcher.clear_fire_cooldown_for_verify()
            cluster_a.ensure_health_initialized()
            cluster_b.ensure_health_initialized()
            hp_a_before = float(cluster_a.get_current_health())
            hp_b_before = float(cluster_b.get_current_health())
            launcher_loc = base_loc + unreal.Vector(0.0, 900.0, 0.0)
            fired = launcher.fire_at(player, launcher_loc, direction)
            projectiles = _find_projectiles(projectile_cls)
            report["grenadeLauncher"] = {"fired": bool(fired), "projectileCount": len(projectiles)}
            if not fired or not projectiles:
                failures.append("grenade launcher did not spawn projectile")
            else:
                projectile = projectiles[-1]
                for _ in range(120):
                    if projectile.has_impacted_for_verify():
                        break
                    projectile.advance_for_verify(0.05)
                hp_a_after = float(cluster_a.get_current_health())
                hp_b_after = float(cluster_b.get_current_health())
                report["grenadeLauncher"]["healthA"] = [hp_a_before, hp_a_after]
                report["grenadeLauncher"]["healthB"] = [hp_b_before, hp_b_after]
                report["grenadeLauncher"]["impacted"] = bool(projectile.has_impacted_for_verify())
                if hp_a_after >= hp_a_before - 0.5:
                    failures.append("grenade radial missed target A")
                if hp_b_after >= hp_b_before - 0.5:
                    failures.append("grenade radial missed target B")

    for actor in spawned:
        if actor:
            try:
                if hasattr(actor, "is_valid") and not actor.is_valid():
                    continue
                subsystem.destroy_actor(actor)
            except Exception:
                pass

    error_count = len(failures)
    report["errorCount"] = error_count
    report["weapon_def"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-def (%d errors):\n- " % error_count + "\n- ".join(failures))
    _log("Success - %d error(s)" % error_count)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_def_report.json"),
        )
    )
