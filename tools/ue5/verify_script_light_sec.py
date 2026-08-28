"""Runner SetLightProperties/ChangeCollision + security/HUD/hack records."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-light-sec] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    light_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetLightProperties")
    coll_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeCollision")
    start_alarm_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionStartSecurityAlarm"
    )
    stop_alarm_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionStopSecurityAlarm"
    )
    door_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetDoorBrokenState")
    hack_turret_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionHackTurret")
    hack_sec_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionHackSecuritySystem"
    )
    play_hud_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayHUD")
    stop_hud_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopHUD")
    mat_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetMaterialSwitchIndex"
    )
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("LightSecScript", "")
    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(40, 0, 100), unreal.Rotator(0, 0, 0)
    )

    light_actor = subsystem.spawn_actor_from_class(
        unreal.PointLight, unreal.Vector(0, 0, 120), unreal.Rotator(0, 0, 0)
    )
    light_actor.set_actor_label("RoomLight")
    coll_actor = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(50, 0, 80), unreal.Rotator(0, 0, 0)
    )
    coll_actor.set_actor_label("CollTarget")

    light = unreal.new_object(light_cls)
    light.configure("RoomLight", True, 2500.0, False, unreal.Color(255, 255, 255, 255))
    coll = unreal.new_object(coll_cls)
    coll.configure("CollTarget", unreal.ShockCollisionChange.SET_TO_FALSE)
    alarm = unreal.new_object(start_alarm_cls)
    alarm.configure("Player", "SecurityBot", 2, False, True)
    stop_alarm = unreal.new_object(stop_alarm_cls)
    stop_alarm.configure(True)
    door = unreal.new_object(door_cls)
    door.configure("DoorA", True)
    hack_t = unreal.new_object(hack_turret_cls)
    hack_t.configure("TurretA", True)
    hack_s = unreal.new_object(hack_sec_cls)
    hack_s.configure(15.0)
    play_hud = unreal.new_object(play_hud_cls)
    stop_hud = unreal.new_object(stop_hud_cls)
    mat = unreal.new_object(mat_cls)
    mat.configure("SwitchMat", 2.0)

    runner = script.get_runner()
    for action in (light, coll, alarm, stop_alarm, door, hack_t, hack_s, play_hud, stop_hud, mat):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(10):
        runner.tick_execution(0.0)

    comps = light_actor.get_components_by_class(unreal.PointLightComponent)
    if not comps:
        f.append("no light component")
    else:
        intensity = float(comps[0].intensity)
        if intensity < 2000.0:
            f.append("light intensity %s" % intensity)
    if coll_actor.get_actor_enable_collision():
        f.append("collision still enabled")
    if str(alarm.get_last_target_label()) != "Player":
        f.append("alarm %s" % alarm.get_last_target_label())
    if not bool(stop_alarm.get_last_bots_become_dormant()):
        f.append("stop alarm dormant")
    if str(door.get_last_door_label()) != "DoorA":
        f.append("door %s" % door.get_last_door_label())
    if str(hack_t.get_last_turret_label()) != "TurretA":
        f.append("hack turret %s" % hack_t.get_last_turret_label())
    if not bool(play_hud.get_play_requested()):
        f.append("play hud")
    if not bool(stop_hud.get_stop_requested()):
        f.append("stop hud")
    if float(mat.get_last_index()) != 2.0:
        f.append("mat %s" % mat.get_last_index())
    if player is None:
        f.append("no ShockPlayer")
    else:
        alarm_on = bool(player.is_security_alarm_on())
        if alarm_on:
            f.append("alarm still on")
        last_target = str(player.get_last_alarm_target())
        if last_target != "Player":
            f.append("alarm target %s" % last_target)
        hud_playing = bool(player.is_hud_playing())
        if hud_playing:
            f.append("hud still playing")
        mat_index = float(player.get_material_switch_index("SwitchMat"))
        if mat_index != 2.0:
            f.append("player mat %s" % mat_index)
        report["alarm_on"] = alarm_on
        report["alarm_target"] = last_target
        report["hud_playing"] = hud_playing
        report["mat_index"] = mat_index
    report["light_sec"] = "ok"

    if player:
        subsystem.destroy_actor(player)
    subsystem.destroy_actor(light_actor)
    subsystem.destroy_actor(coll_actor)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("light-sec:\n- " + "\n- ".join(f))
    _log("PASS light-sec")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_light_sec_report.json",
        )
    )
