"""Headless verify: weapon muzzle flash, tracer draw, hit markers, player recoil.

Also asserts ControlRotation pitch moves by a bounded KickDegrees-sized amount on fire —
not merely that WeaponRecoilKickRemaining increments. A raw FMath::Clamp on wrapped pitch
(e.g. 350 for "-10 looking down") snaps to +89 (ceiling); that used to pass the counter
check while breaking the camera.
"""

import json
import os

import unreal

# Must match AShockPlayer::ApplyWeaponRecoil KickDegrees.
_KICK_DEGREES = 0.6
# Wrapped equivalent of looking slightly down; raw Clamp(-89,89) snaps this to +89.
_WRAPPED_LOOK_DOWN_PITCH = 350.0


def _log(message):
    unreal.log("[bioshock-weapon-feedback] %s" % message)


def _normalize_pitch(degrees):
    """Map any pitch into (-180, 180] for delta checks (mirrors FRotator::NormalizeAxis)."""
    p = float(degrees) % 360.0
    if p > 180.0:
        p -= 360.0
    return p


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    if not player_cls or not ai_cls or not weapon_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("weapon-feedback:\n- " + "\n- ".join(failures))

    spawned = []
    base_loc = unreal.Vector(0.0, 0.0, 100.0)
    target_loc = unreal.Vector(800.0, 0.0, 100.0)

    shooter = _spawn(subsystem, player_cls, "FeedbackShooter", base_loc)
    target = _spawn(
        subsystem,
        player_cls,
        "FeedbackTarget",
        target_loc,
        unreal.Rotator(0.0, 180.0, 0.0),
    )
    weapon = _spawn(subsystem, weapon_cls, "FeedbackWeapon", base_loc)
    spawned.extend([shooter, target, weapon])

    if not shooter or not target or not weapon:
        failures.append("spawn shooter/target/weapon")
    else:
        target.ensure_health_initialized()
        weapon.configure_hitscan(10.0, 5000.0)
        weapon.configure_ammo(50, 0, 10.0, 2.5)
        weapon.initialize_ammo_full_mag(0)
        weapon.set_auto_reload(False)
        weapon.set_editor_property("draw_tracers", True)
        shooter.equip_weapon(weapon)

        # Possess with a real controller so ApplyWeaponRecoil's pitch path runs (gated on
        # GetController()). SpawnDefaultController — PlayerController.Possess AVs headless.
        shooter.ensure_controller_for_verify()
        if shooter.get_controller() is None:
            failures.append("ensure_controller_for_verify left GetController null")

        # Reproduce the ceiling snap: wrapped pitch outside [-90, 90], fire once, demand a
        # KickDegrees-sized delta — not a snap to the clamp bound.
        shooter.set_control_rotation_pitch_for_verify(_WRAPPED_LOOK_DOWN_PITCH)
        pitch_before_raw = float(shooter.get_control_rotation_pitch_for_verify())
        pitch_before_norm = _normalize_pitch(pitch_before_raw)
        recoil_before = float(shooter.get_weapon_recoil_kick_remaining_for_verify())
        tracers_before = int(weapon.get_tracer_draw_count_for_verify())
        flashes_before = int(weapon.get_muzzle_flash_count_for_verify())

        weapon.clear_fire_cooldown_for_verify()
        shooter.try_fire_equipped_weapon()

        pitch_after_raw = float(shooter.get_control_rotation_pitch_for_verify())
        pitch_after_norm = _normalize_pitch(pitch_after_raw)
        pitch_delta = pitch_after_norm - pitch_before_norm
        recoil_after_fire = float(shooter.get_weapon_recoil_kick_remaining_for_verify())

        report["playerFire"] = {
            "hasMuzzleLight": bool(weapon.has_muzzle_flash_light_for_verify()),
            "muzzleVisible": bool(weapon.is_muzzle_flash_light_visible_for_verify()),
            "tracers": int(weapon.get_tracer_draw_count_for_verify()) - tracers_before,
            "flashes": int(weapon.get_muzzle_flash_count_for_verify()) - flashes_before,
            "recoil": recoil_after_fire,
            "pitchBeforeRaw": pitch_before_raw,
            "pitchAfterRaw": pitch_after_raw,
            "pitchBeforeNorm": pitch_before_norm,
            "pitchAfterNorm": pitch_after_norm,
            "pitchDelta": pitch_delta,
            "hadController": shooter.get_controller() is not None,
        }

        if not weapon.has_muzzle_flash_light_for_verify():
            failures.append("muzzle light component missing after player fire")
        if not weapon.is_muzzle_flash_light_visible_for_verify():
            failures.append("muzzle light not visible after player fire")
        if int(weapon.get_tracer_draw_count_for_verify()) <= tracers_before:
            failures.append("tracer draw count did not increment on player fire")
        if recoil_after_fire <= recoil_before:
            failures.append("player recoil not applied")

        # Kick subtracts pitch by KickDegrees. Absolute delta must stay near that — tens of
        # degrees means the old raw Clamp snapped a wrapped value to ±89.
        if abs(pitch_delta + _KICK_DEGREES) > 0.15:
            failures.append(
                "control pitch delta %.3f (raw %.3f -> %.3f) not KickDegrees-sized (%.3f); "
                "ceiling-snap / Clamp-without-normalize regression"
                % (pitch_delta, pitch_before_raw, pitch_after_raw, -_KICK_DEGREES)
            )
        if abs(pitch_after_norm) > 89.0 + 0.01:
            failures.append(
                "control pitch after fire still outside view limits (norm=%.3f)" % pitch_after_norm
            )

        weapon.advance_muzzle_flash_for_verify(0.05)
        if weapon.is_muzzle_flash_light_visible_for_verify():
            failures.append("muzzle light still visible after advance")

        shooter.advance_weapon_recoil_for_verify(0.15)
        recoil_after = float(shooter.get_weapon_recoil_kick_remaining_for_verify())
        report["playerFire"]["recoilAfterDecay"] = recoil_after
        if recoil_after > 0.05:
            failures.append("player recoil did not decay (%.3f)" % recoil_after)

        # Level pitch path: same bounded kick from a signed near-zero pitch.
        shooter.set_control_rotation_pitch_for_verify(0.0)
        level_before = float(shooter.get_control_rotation_pitch_for_verify())
        weapon.clear_fire_cooldown_for_verify()
        # Mag may be empty after first shot — refill without changing other state.
        weapon.initialize_ammo_full_mag(0)
        shooter.try_fire_equipped_weapon()
        level_after = float(shooter.get_control_rotation_pitch_for_verify())
        level_delta = _normalize_pitch(level_after) - _normalize_pitch(level_before)
        report["playerFire"]["levelPitchDelta"] = level_delta
        if abs(level_delta + _KICK_DEGREES) > 0.15:
            failures.append(
                "level pitch delta %.3f not KickDegrees-sized after second fire" % level_delta
            )

    ai = _spawn(subsystem, ai_cls, "FeedbackAI", base_loc + unreal.Vector(0.0, 400.0, 0.0))
    ai_weapon = _spawn(
        subsystem,
        weapon_cls,
        "FeedbackAIWeapon",
        base_loc + unreal.Vector(0.0, 400.0, 0.0),
    )
    spawned.extend([ai, ai_weapon])
    if not ai or not ai_weapon or not shooter:
        failures.append("ai spawn")
    else:
        ai.configure_identity("Agg_BabyJane", "FeedbackAI")
        ai.ensure_health_initialized()
        ai_weapon.configure_hitscan(10.0, 5000.0)
        ai_weapon.set_enforce_ammo(False)
        ai.equip_ai_weapon(ai_weapon)

        player_recoil_before_ai = float(shooter.get_weapon_recoil_kick_remaining_for_verify())
        ai_tracers_before = int(ai_weapon.get_tracer_draw_count_for_verify())
        ai_loc = ai.get_actor_location()
        to_shooter = shooter.get_actor_location() - ai_loc
        ai_weapon.fire_at(ai, ai_loc, to_shooter)

        ai_tracers_after = int(ai_weapon.get_tracer_draw_count_for_verify())
        player_recoil_after_ai = float(shooter.get_weapon_recoil_kick_remaining_for_verify())
        report["aiFire"] = {
            "tracers": ai_tracers_after - ai_tracers_before,
            "playerRecoilUnchanged": abs(player_recoil_after_ai - player_recoil_before_ai) < 0.01,
        }
        if ai_tracers_after <= ai_tracers_before:
            failures.append("tracer draw count did not increment on AI fire")
        if abs(player_recoil_after_ai - player_recoil_before_ai) > 0.01:
            failures.append("AI fire changed player recoil")

    for actor in spawned:
        if actor:
            try:
                subsystem.destroy_actor(actor)
            except Exception:
                pass

    report["weapon_feedback"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-feedback:\n- " + "\n- ".join(failures))
    _log("PASS weapon-feedback")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_feedback_report.json"),
        )
    )
