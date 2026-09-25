"""Headless verify: security camera alert, alarm bot spawn, hack + shutdown."""

import json
import math
import os

import unreal

ALLEGIANCE_NEUTRAL = 0
ALLEGIANCE_HOSTILE = 1
ALLEGIANCE_FRIENDLY = 2
ALLEGIANCE_DISABLED = 3


def _log(message):
    unreal.log("[bioshock-security] %s" % message)


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


def _tick_camera(camera, seconds, step=0.05):
    steps = max(1, int(seconds / step))
    for _ in range(steps):
        camera.advance_device_for_verify(step)


def _tick_security(world, seconds, step=0.05):
    sec = unreal.ShockSecuritySubsystem.get_for_world(world)
    if not sec:
        return
    steps = max(1, int(seconds / step))
    for _ in range(steps):
        sec.advance_security_for_verify(step)


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
    camera_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockSecurityCamera")
    bot_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockSecurityBot")
    hack_sec_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionHackSecuritySystem")

    if not all([player_cls, camera_cls, bot_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("security:\n- " + "\n- ".join(failures))

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

    sec = unreal.ShockSecuritySubsystem.get_for_world(world)
    if sec:
        # Default BotLifetimeAfterAlarmClearSeconds is -1 (never). Opt-in delay unused here.
        sec.set_editor_property("bot_lifetime_after_alarm_clear_seconds", -1.0)

    # --- (a) hostile camera alerts and spawns bot ---
    player_loc = unreal.Vector(0.0, 0.0, 100.0)
    camera_loc = unreal.Vector(0.0, -350.0, 100.0)
    player = _spawn(subsystem, player_cls, "SecPlayer", player_loc)
    camera = _spawn(subsystem, camera_cls, "SecCamera", camera_loc)
    spawned.extend([player, camera])

    if not player or not camera:
        failures.append("spawn failed")
    else:
        player.ensure_health_initialized()
        camera.configure_for_verify(unreal.Name("SecCamera"), ALLEGIANCE_HOSTILE, 40.0)
        # The camera's real default cone is 60 degrees wide / 1000 uu (SDK guide ch.31) and it
        # sweeps; this test is about alert->alarm->bot mechanics, so give it a wide cone.
        camera.set_editor_property("detection_half_angle_deg", 90.0)
        camera.set_editor_property("detection_range", 3000.0)
        camera.set_editor_property("alert_threshold", 1.5)
        yaw = _yaw_toward(camera.get_actor_location(), player.get_actor_location())
        camera.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)

        _tick_camera(camera, 1.6)
        alarm_on = bool(player.is_security_alarm_on())
        bot_count = int(sec.get_active_bot_count_for_verify()) if sec else 0
        check(
            "camera_raises_alarm",
            alarm_on and camera.has_triggered_alert_for_verify(),
            {"alarm": alarm_on, "alert": camera.has_triggered_alert_for_verify()},
        )
        check("alarm_spawns_bot", bot_count >= 1, bot_count)

        ph_before = float(player.get_current_health())
        _tick_security(world, 1.5)
        ph_after = float(player.get_current_health())
        check("bot_damages_player", ph_after < ph_before - 0.5, {"before": ph_before, "after": ph_after})

        buildup_before = float(camera.get_alert_buildup_for_verify())
        player.set_hack_skill_for_verify(0.7)
        player.set_instant_hack_for_verify(True)
        ok = bool(player.try_hack_device(camera, 0.2))
        allegiance = int(camera.get_allegiance_for_verify())
        if sec:
            sec.despawn_all_bots_for_verify()
        _tick_camera(camera, 1.0)
        buildup_after = float(camera.get_alert_buildup_for_verify())
        check(
            "hack_camera_friendly",
            ok and allegiance == ALLEGIANCE_FRIENDLY,
            allegiance,
        )
        check(
            "hacked_camera_stops_alerting",
            buildup_after < buildup_before + 0.1,
            {"before": buildup_before, "after": buildup_after},
        )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (b) security shutdown disables camera + bot ---
    shut_player = _spawn(subsystem, player_cls, "ShutPlayer", unreal.Vector(0.0, 200.0, 100.0))
    shut_camera = _spawn(subsystem, camera_cls, "ShutCamera", unreal.Vector(0.0, -150.0, 100.0))
    shut_bot = _spawn(subsystem, bot_cls, "ShutBot", unreal.Vector(200.0, 200.0, 100.0))
    spawned.extend([shut_player, shut_camera, shut_bot])

    if shut_player and shut_camera and shut_bot:
        shut_player.ensure_health_initialized()
        shut_camera.configure_for_verify(unreal.Name("ShutCamera"), ALLEGIANCE_HOSTILE, 40.0)
        shut_bot.configure_for_verify(unreal.Name("ShutBot"), ALLEGIANCE_HOSTILE, 30.0)
        shut_bot.activate_for_player(shut_player)
        yaw = _yaw_toward(shut_camera.get_actor_location(), shut_player.get_actor_location())
        shut_camera.set_actor_rotation(unreal.Rotator(0.0, yaw, 0.0), False)
        _tick_security(world, 0.2)

        ph_before = float(shut_player.get_current_health())
        if hack_sec_cls:
            action = unreal.new_object(hack_sec_cls)
            action.configure(5.0)
            action.apply_in_world(world)
        else:
            shut_player.set_security_hacked(True, 5.0)

        cam_allegiance = int(shut_camera.get_allegiance_for_verify())
        bot_allegiance = int(shut_bot.get_bot_allegiance_for_verify())
        _tick_security(world, 0.8)
        ph_after = float(shut_player.get_current_health())
        check("shutdown_disables_camera", cam_allegiance == ALLEGIANCE_DISABLED, cam_allegiance)
        check("shutdown_disables_bot", bot_allegiance == ALLEGIANCE_DISABLED, bot_allegiance)
        check(
            "shutdown_stops_damage",
            ph_after >= ph_before - 0.1,
            {"before": ph_before, "after": ph_after},
        )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (c) alarm clear keeps bots (guide silent on despawn; default lifetime=-1 never) ---
    clear_player = _spawn(subsystem, player_cls, "ClearPlayer", unreal.Vector(0.0, 400.0, 100.0))
    spawned.append(clear_player)
    if clear_player and sec:
        clear_player.ensure_health_initialized()
        clear_player.set_security_alarm_on(True, unreal.Name("ClearAlarm"))
        sec.spawn_bots_near(unreal.Vector(400.0, 400.0, 100.0), 1, clear_player)
        before = int(sec.get_active_bot_count_for_verify())
        clear_player.set_security_alarm_on(False, unreal.Name(""))
        _tick_security(world, 0.5)
        after = int(sec.get_active_bot_count_for_verify())
        check(
            "alarm_clear_keeps_bots",
            before >= 1 and after == before,
            {"before": before, "after": after},
        )
        # Explicit positive lifetime still despawns (opt-in / old behaviour).
        sec.set_editor_property("bot_lifetime_after_alarm_clear_seconds", 0.25)
        clear_player.set_security_alarm_on(True, unreal.Name("ClearAlarm2"))
        sec.spawn_bots_near(unreal.Vector(400.0, 400.0, 100.0), 1, clear_player)
        before2 = int(sec.get_active_bot_count_for_verify())
        clear_player.set_security_alarm_on(False, unreal.Name(""))
        _tick_security(world, 0.5)
        after2 = int(sec.get_active_bot_count_for_verify())
        check(
            "alarm_clear_optin_despawn",
            before2 >= 1 and after2 == 0,
            {"before": before2, "after": after2},
        )
        sec.set_editor_property("bot_lifetime_after_alarm_clear_seconds", -1.0)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (c2) alarm auto-expires after AlarmDurationSeconds (guide-confirmed 60s) even when
    # nothing ever explicitly stops it -- previously untested because the whole security
    # subsystem's time-based state was never ticked outside this verify harness.
    expire_player = _spawn(subsystem, player_cls, "ExpirePlayer", unreal.Vector(0.0, 700.0, 100.0))
    spawned.append(expire_player)
    if expire_player and sec:
        expire_player.ensure_health_initialized()
        sec.set_editor_property("alarm_duration_seconds", 1.0)
        expire_player.set_security_alarm_on(True, unreal.Name("ExpireAlarm"))
        still_on_before = bool(expire_player.is_security_alarm_on())
        _tick_security(world, 0.5)
        still_on_mid = bool(expire_player.is_security_alarm_on())
        _tick_security(world, 0.7)
        off_after = bool(expire_player.is_security_alarm_on())
        check(
            "alarm_auto_expires",
            still_on_before and still_on_mid and not off_after,
            {"before": still_on_before, "mid": still_on_mid, "after": off_after},
        )
        sec.set_editor_property("alarm_duration_seconds", 60.0)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (d) killed bot disabled ---
    kill_bot = _spawn(subsystem, bot_cls, "KillBot", unreal.Vector(0.0, 600.0, 100.0))
    spawned.append(kill_bot)
    if kill_bot:
        kill_bot.configure_for_verify(unreal.Name("KillBot"), ALLEGIANCE_HOSTILE, 30.0)
        kill_bot.apply_authored_damage(50.0)
        allegiance = int(kill_bot.get_bot_allegiance_for_verify())
        operational = bool(kill_bot.is_bot_operational_for_verify())
        check(
            "killed_bot_disabled",
            allegiance == ALLEGIANCE_DISABLED and not operational,
            {"allegiance": allegiance, "operational": operational},
        )

    _destroy_all(subsystem, spawned)

    report["checks"] = checks
    report["security"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("security:\n- " + "\n- ".join(failures))
    _log("Success - %d error(s)" % len(failures))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "security_report.json"),
        )
    )
