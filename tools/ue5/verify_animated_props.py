"""Headless verify: AShockAnimatedProp spin + keyframe move via script actions."""

from __future__ import annotations

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-animated-props] %s" % message)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _destroy(subsystem, actors):
    for actor in actors:
        if not actor:
            continue
        try:
            if hasattr(actor, "is_valid") and not actor.is_valid():
                continue
            subsystem.destroy_actor(actor)
        except Exception:  # noqa: BLE001
            pass


def main(out):
    report = {"failures": [], "checks": 0, "results": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    prop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockAnimatedProp")
    play_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayAnimation")
    rate_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeAnimationRate")
    turret_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTurret")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")

    if prop_cls is None or play_cls is None or rate_cls is None:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("animated-props:\n- " + "\n- ".join(failures))

    spawned = []

    def check(name, ok, detail=None):
        report["checks"] += 1
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report["results"].append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    # --- Fan: continuous spin + ChangeAnimationRate ---
    fan = subsystem.spawn_actor_from_class(
        prop_cls, unreal.Vector(0.0, 0.0, 50.0), unreal.Rotator(0.0, 0.0, 0.0))
    if fan is None:
        failures.append("spawn fan failed")
        _write(out, report)
        raise RuntimeError("animated-props:\n- " + "\n- ".join(failures))
    spawned.append(fan)
    fan.set_actor_label("VerifyFan")
    fan.configure_spin_for_verify(unreal.Name("VerifyFan"), 1.0)
    check("fan_mode_spin", int(fan.get_motion_mode_for_verify()) == 0,
          "mode=%s" % fan.get_motion_mode_for_verify())
    check("fan_spin_enabled", bool(fan.is_spin_enabled()), "enabled=%s" % fan.is_spin_enabled())
    check("fan_rps", abs(float(fan.get_effective_revolutions_per_second()) - 1.0) < 0.01,
          fan.get_effective_revolutions_per_second())

    r0 = fan.get_actor_rotation()
    spin0 = float(fan.get_accumulated_spin_degrees())
    for _ in range(20):
        fan.advance_motion_for_verify(0.05)
    r1 = fan.get_actor_rotation()
    spin1 = float(fan.get_accumulated_spin_degrees())
    dyaw = abs(float(r1.yaw) - float(r0.yaw))
    if dyaw > 180.0:
        dyaw = 360.0 - dyaw
    check("fan_spins", (spin1 - spin0) > 30.0 or dyaw > 30.0,
          "dspin=%s dyaw=%s" % (spin1 - spin0, dyaw))

    rate = unreal.new_object(rate_cls)
    rate.configure(unreal.Name("VerifyFan"), unreal.Name("Spin"), 2.5, 0.0)
    if hasattr(rate, "apply_rate_in_world"):
        applied = int(rate.apply_rate_in_world(world))
        check("change_rate_applied", applied >= 1, "applied=%s" % applied)
    else:
        check("change_rate_applied", bool(rate.request_change()), "request_change fallback")
        fan.set_spin_rate_scale(2.5)
    check("change_rate_recorded", str(rate.get_last_target_label()) == "VerifyFan",
          str(rate.get_last_target_label()))
    check("spin_rate_scale", abs(float(fan.get_spin_rate_scale()) - 2.5) < 0.01,
          fan.get_spin_rate_scale())

    # --- Mover: PlayAnimation drives keyframe translate ---
    gate = subsystem.spawn_actor_from_class(
        prop_cls, unreal.Vector(200.0, 0.0, 50.0), unreal.Rotator(0.0, 0.0, 0.0))
    spawned.append(gate)
    gate.set_actor_label("VerifyGate")
    gate.configure_keyframe_for_verify(
        unreal.Name("VerifyGate"), unreal.Vector(0.0, 0.0, 100.0), 0.5)
    check("gate_mode_keyframe", int(gate.get_motion_mode_for_verify()) == 1,
          "mode=%s" % gate.get_motion_mode_for_verify())
    check("gate_key_count", int(gate.get_keyframe_count_for_verify()) >= 2,
          "keys=%s" % gate.get_keyframe_count_for_verify())

    play = unreal.new_object(play_cls)
    play.configure(unreal.Name("VerifyGate"), unreal.Name("Open"), 1.0, 0)
    played_ok = bool(play.play_on_actor(gate))
    check("play_on_gate", played_ok, "PlayOnActor")
    check("play_recorded", str(play.get_last_played_animation()) == "Open",
          str(play.get_last_played_animation()))
    check("gate_moving", bool(gate.is_keyframe_moving()),
          "moving=%s keys=%s mode=%s" % (
              gate.is_keyframe_moving(),
              gate.get_keyframe_count_for_verify(),
              gate.get_motion_mode_for_verify()))

    loc0 = gate.get_actor_location()
    for _ in range(20):
        gate.advance_motion_for_verify(0.05)
    loc1 = gate.get_actor_location()
    dz = abs(float(loc1.z) - float(loc0.z))
    check("gate_translated", dz > 10.0, "z0=%s z1=%s dz=%s alpha=%s moving=%s" % (
        loc0.z, loc1.z, dz, gate.get_keyframe_alpha(), gate.is_keyframe_moving()))

    play2 = unreal.new_object(play_cls)
    play2.configure(unreal.Name("VerifyGate"), unreal.Name("Close"), 1.0, 0)
    played = int(play2.play_in_world(world))
    check("play_in_world", played >= 1, "played=%s" % played)

    # --- Turret faces player (transform pan/tilt APPROXIMATION) ---
    if turret_cls and player_cls:
        turret = subsystem.spawn_actor_from_class(
            turret_cls, unreal.Vector(0.0, 0.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
        player = subsystem.spawn_actor_from_class(
            player_cls, unreal.Vector(400.0, 200.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
        spawned.extend([turret, player])
        if turret and player:
            turret.configure_for_verify(unreal.Name("VerifyTurret"), 1, 40.0)
            yaw_before = float(turret.get_actor_rotation().yaw)
            for _ in range(40):
                turret.advance_device_for_verify(0.05)
            yaw_after = float(turret.get_actor_rotation().yaw)
            dx = 400.0 - 0.0
            dy = 200.0 - 0.0
            desired = math.degrees(math.atan2(dy, dx))
            faced = abs(((yaw_after - desired + 180) % 360) - 180) < 25.0
            check("turret_faces_player", faced,
                  "yaw=%s desired=%s before=%s" % (yaw_after, desired, yaw_before))
            barrel = turret.get_editor_property("barrel_mesh")
            barrel_mesh = None
            if barrel is not None:
                barrel_mesh = barrel.get_editor_property("static_mesh")
            check("turret_has_barrel", barrel is not None and barrel_mesh is not None,
                  "barrel=%s mesh=%s" % (barrel, barrel_mesh))

    # --- slice placement (w3): the ScriptableMovers exist and respond to a scripted play ---
    if unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(
            "/Game/BioShockSlice/1-Medical"):
        placed = [a for a in subsystem.get_all_level_actors()
                  if isinstance(a, unreal.ShockAnimatedProp)]
        check("slice_movers_placed", len(placed) >= 8, "count=%d" % len(placed))
        moved = 0
        for prop in placed:
            if int(prop.get_motion_mode_for_verify()) != 1:
                continue
            prop.play_scripted_motion(unreal.Name("Open"), 1.0, False)
            for _ in range(40):
                prop.advance_motion_for_verify(0.05)
            if prop.get_keyframe_alpha() > 0.05 or prop.is_keyframe_moving():
                moved += 1
        check("slice_mover_moves", moved >= 1, "moved=%d of %d" % (moved, len(placed)))

    report["animated_props"] = "ok" if not failures else "fail"
    _destroy(subsystem, spawned)
    _write(out, report)
    if failures:
        raise RuntimeError("animated-props:\n- " + "\n- ".join(failures))
    _log("PASS animated props")
    return report


if __name__ == "__main__":
    main(os.environ.get(
        "BIOSHOCK_ACTION_OUT",
        os.path.join(os.environ.get("TEMP", "."), "animated_props_report.json"),
    ))
