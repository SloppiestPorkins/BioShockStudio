"""Headless verify: security turret + hack flow (C3 hacking first slice)."""

import json
import math
import os

import unreal

# EShockDeviceAllegiance
ALLEGIANCE_NEUTRAL = 0
ALLEGIANCE_HOSTILE = 1
ALLEGIANCE_FRIENDLY = 2
ALLEGIANCE_DISABLED = 3


def _log(message):
    unreal.log("[bioshock-hacking] %s" % message)


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


def _tick_device(device, seconds, step=0.05):
    steps = max(1, int(seconds / step))
    for _ in range(steps):
        device.advance_device_for_verify(step)


def _destroy_all(subsystem, actors):
    """Guarded teardown — follow verify_plasmid.py pattern."""
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
    turret_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTurret")
    hack_sec_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionHackSecuritySystem")

    if not all([player_cls, ai_cls, turret_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("hacking:\n- " + "\n- ".join(failures))

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

    # --- (a) hostile turret damages player ---
    player_loc = unreal.Vector(0.0, 0.0, 100.0)
    ai_loc = unreal.Vector(800.0, 0.0, 100.0)
    turret_loc = unreal.Vector(0.0, -400.0, 100.0)
    player = _spawn(subsystem, player_cls, "HackPlayer", player_loc)
    ai = _spawn(subsystem, ai_cls, "HackAI", ai_loc)
    turret = _spawn(subsystem, turret_cls, "HackTurret", turret_loc)
    spawned.extend([player, ai, turret])

    if not player or not ai or not turret:
        failures.append("spawn failed")
    else:
        ai.configure_identity("Agg_BabyJane", "HackAI")
        ai.ensure_health_initialized()
        player.ensure_health_initialized()
        turret.configure_for_verify(unreal.Name("HackTurret"), ALLEGIANCE_HOSTILE, 40.0)
        yaw = _yaw_toward(turret.get_actor_location(), player.get_actor_location())
        turret.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

        ph_before = float(player.get_current_health())
        _tick_device(turret, 1.0)
        ph_after = float(player.get_current_health())
        check("hostile_damages_player", ph_after < ph_before - 0.5, {"before": ph_before, "after": ph_after})

        player.set_hack_skill_for_verify(0.7)
        player.set_instant_hack_for_verify(True)
        ok = bool(player.try_hack_device(turret, 0.2))
        allegiance = int(turret.get_allegiance_for_verify())
        check("easy_hack_success", ok and allegiance == ALLEGIANCE_FRIENDLY, allegiance)
        check("turret_bookkeeping", bool(player.is_turret_hacked(unreal.Name("HackTurret"))))

        ah_before = float(ai.get_current_health())
        ph_mid = float(player.get_current_health())
        _tick_device(turret, 1.0)
        ah_after = float(ai.get_current_health())
        ph_end = float(player.get_current_health())
        check("friendly_damages_ai", ah_after < ah_before - 0.5, ah_after)
        check("friendly_spares_player", ph_end >= ph_mid - 0.5, {"mid": ph_mid, "end": ph_end})

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (b) hard hack fails, stays hostile ---
    fail_player = _spawn(subsystem, player_cls, "FailHackPlayer", unreal.Vector(0.0, 200.0, 100.0))
    fail_turret = _spawn(
        subsystem, turret_cls, "FailHackTurret", unreal.Vector(0.0, -200.0, 100.0)
    )
    spawned.extend([fail_player, fail_turret])
    if fail_player and fail_turret:
        fail_player.ensure_health_initialized()
        fail_turret.configure_for_verify(unreal.Name("FailHackTurret"), ALLEGIANCE_HOSTILE, 40.0)
        yaw = _yaw_toward(fail_turret.get_actor_location(), fail_player.get_actor_location())
        fail_turret.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
        fail_player.set_hack_skill_for_verify(0.7)
        fail_player.set_instant_hack_for_verify(True)
        hb = float(fail_player.get_current_health())
        ok = bool(fail_player.try_hack_device(fail_turret, 0.95))
        ha = float(fail_player.get_current_health())
        allegiance = int(fail_turret.get_allegiance_for_verify())
        check(
            "hard_hack_fail",
            not ok and allegiance == ALLEGIANCE_HOSTILE,
            {"ok": ok, "allegiance": allegiance, "selfDmg": hb - ha},
        )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (c) security shutdown disables turret ---
    sec_player = _spawn(subsystem, player_cls, "SecPlayer", unreal.Vector(0.0, 400.0, 100.0))
    sec_ai = _spawn(subsystem, ai_cls, "SecAI", unreal.Vector(800.0, 400.0, 100.0))
    sec_turret = _spawn(
        subsystem, turret_cls, "SecTurret", unreal.Vector(0.0, 200.0, 100.0)
    )
    spawned.extend([sec_player, sec_ai, sec_turret])
    if sec_player and sec_ai and sec_turret:
        sec_ai.ensure_health_initialized()
        sec_player.ensure_health_initialized()
        sec_turret.configure_for_verify(unreal.Name("SecTurret"), ALLEGIANCE_HOSTILE, 40.0)
        yaw = _yaw_toward(sec_turret.get_actor_location(), sec_player.get_actor_location())
        sec_turret.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

        if hack_sec_cls:
            action = unreal.new_object(hack_sec_cls)
            action.configure(5.0)
            action.apply_in_world(world)
        else:
            sec_player.set_security_hacked(True, 5.0)

        allegiance = int(sec_turret.get_allegiance_for_verify())
        fires_before = int(sec_turret.get_fire_count_for_verify())
        ph_before = float(sec_player.get_current_health())
        _tick_device(sec_turret, 0.8)
        ph_after = float(sec_player.get_current_health())
        fires_after = int(sec_turret.get_fire_count_for_verify())
        check("security_shutdown_disabled", allegiance == ALLEGIANCE_DISABLED, allegiance)
        check(
            "disabled_stops_firing",
            fires_after == fires_before and ph_after >= ph_before - 0.1,
            {"firesBefore": fires_before, "firesAfter": fires_after},
        )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (d) killed turret -> Disabled ---
    kill_turret = _spawn(
        subsystem, turret_cls, "KillTurret", unreal.Vector(0.0, 600.0, 100.0)
    )
    spawned.append(kill_turret)
    if kill_turret:
        kill_turret.configure_for_verify(unreal.Name("KillTurret"), ALLEGIANCE_HOSTILE, 40.0)
        kill_turret.apply_authored_damage(50.0)
        allegiance = int(kill_turret.get_allegiance_for_verify())
        health = float(kill_turret.get_health())
        check(
            "killed_turret_disabled",
            allegiance == ALLEGIANCE_DISABLED and health <= 0.1,
            {"allegiance": allegiance, "health": health},
        )

    _destroy_all(subsystem, spawned)

    report["checks"] = checks
    report["hacking"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("hacking:\n- " + "\n- ".join(failures))
    _log("Success - %d error(s)" % len(failures))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "hacking_report.json"),
        )
    )
