"""Headless verify: simulated wall impact components, sound dispatch, and surface profiles.

Collision cooking is not active in the empty commandlet editor world, so this deliberately
does not pretend to validate a world trace there. It fires once for weapon-side feedback, then
drives the production post-trace impact path with deterministic material-name evidence.
"""

from __future__ import annotations

import json
import os

import unreal


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _spawn(subsystem, cls, label, location):
    actor = subsystem.spawn_actor_from_class(
        cls, location, unreal.Rotator(0.0, 0.0, 0.0)
    )
    if actor:
        actor.set_actor_label(label)
    return actor


def _snapshot(weapon):
    return {
        "surface": str(weapon.get_last_impact_surface_for_verify()),
        "decal": str(weapon.get_last_impact_decal_asset_for_verify()),
        "fx": str(weapon.get_last_impact_fx_asset_for_verify()),
        "sound": str(weapon.get_last_impact_sound_for_verify()),
        "decalComponent": bool(weapon.has_last_impact_decal_for_verify()),
        "fxComponent": bool(weapon.has_last_impact_fx_for_verify()),
        "audioComponent": bool(weapon.has_last_impact_audio_for_verify()),
        "decalCount": int(weapon.get_impact_decal_count_for_verify()),
        "fxCount": int(weapon.get_impact_fx_count_for_verify()),
        "soundCount": int(weapon.get_impact_sound_count_for_verify()),
    }


def main(out):
    report = {"failures": []}
    failures = report["failures"]
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    spawned = []

    if not weapon_cls:
        failures.append("runtime weapon class missing")
        _write(out, report)
        raise RuntimeError("impact-fx:\n- " + "\n- ".join(failures))

    weapon = _spawn(
        subsystem, weapon_cls, "ImpactVerifyWeapon", unreal.Vector(0.0, 0.0, 100.0)
    )
    spawned.append(weapon)
    if not weapon:
        failures.append("spawn weapon")
    else:
        weapon.configure_hitscan(10.0, 2000.0)
        weapon.set_enforce_ammo(False)
        weapon.fire_at(
            weapon,
            unreal.Vector(0.0, 0.0, 100.0),
            unreal.Vector(1.0, 0.0, 0.0),
        )
        weapon.simulate_world_impact_for_verify(
            "Hospital_Concrete_Wall",
            unreal.Vector(500.0, 0.0, 100.0),
            unreal.Vector(-1.0, 0.0, 0.0),
        )
        report["wallShot"] = _snapshot(weapon)
        wall_shot = report["wallShot"]
        wall_shot["audioAsset"] = bool(
            unreal.load_asset(
                "/Game/BioShockAudio/_1_Medical/Cues/"
                "bullet_hit__MVT_Concrete.bullet_hit__MVT_Concrete"
            )
        )
        if wall_shot["surface"] != "Concrete":
            failures.append("wall trace surface was %s, expected Concrete" % wall_shot["surface"])
        if not wall_shot["decalComponent"]:
            failures.append("wall shot did not spawn a decal component")
        if not wall_shot["fxComponent"]:
            failures.append("wall shot did not spawn an impact FX component")
        if wall_shot["soundCount"] < 1:
            failures.append("wall shot did not dispatch an impact sound")
        if not wall_shot["audioAsset"]:
            failures.append(
                "wall impact cue asset missing; rerun import_audio.py to generate bullet_hit surface cues"
            )

        weapon.simulate_world_impact_for_verify(
            "railing_METAL_thick",
            unreal.Vector(500.0, 100.0, 100.0),
            unreal.Vector(-1.0, 0.0, 0.0),
        )
        report["metal"] = _snapshot(weapon)
        if report["metal"]["surface"] != "Metal":
            failures.append("known metal material did not resolve Metal")
        if report["metal"]["sound"] != "bullet_hit__MVT_ThickMetal":
            failures.append("metal impact selected wrong sound")

        weapon.simulate_world_impact_for_verify(
            "Hospital_Concrete_Wall",
            unreal.Vector(500.0, -100.0, 100.0),
            unreal.Vector(-1.0, 0.0, 0.0),
        )
        report["concrete"] = _snapshot(weapon)
        if report["concrete"]["surface"] != "Concrete":
            failures.append("known concrete material did not resolve Concrete")
        if report["concrete"]["sound"] != "bullet_hit__MVT_Concrete":
            failures.append("concrete impact selected wrong sound")

        report["weaponFeedback"] = {
            "muzzleParticles": int(weapon.get_muzzle_particle_count_for_verify()),
            "shellEjects": int(weapon.get_shell_eject_count_for_verify()),
        }
        if report["weaponFeedback"]["muzzleParticles"] < 1:
            failures.append("ballistic wall shot did not spawn muzzle particle component")
        if report["weaponFeedback"]["shellEjects"] < 1:
            failures.append("ballistic wall shot did not eject a casing")

    for actor in spawned:
        if actor:
            try:
                subsystem.destroy_actor(actor)
            except Exception:
                pass

    report["impact_fx"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("impact-fx:\n- " + "\n- ".join(failures))
    unreal.log("[bioshock-impact-fx] PASS")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "verify_impact_fx.json"),
        )
    )
