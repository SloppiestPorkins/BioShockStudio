"""Runner batch1+batch2 world-state exec: player/AI stores via ApplyInWorld."""

import json
import os

import unreal


def _flag(value):
    return bool(value() if callable(value) else value)


def _log(m):
    unreal.log("[bioshock-script-world-state-exec] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    post_goal_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionPostMovementGoal"
    )
    remove_goal_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionRemoveGoal"
    )
    training_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionShowTrainingMessage"
    )
    fade_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionFadeVolumeOverride"
    )
    save_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionEnableOrDisableLevelSaving"
    )
    vuln_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetAIVulnerability"
    )
    res_station_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionActivateResurrectionStation"
    )
    attach_vis_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionToggleAIAttachmentVisibility"
    )
    hud_state_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetHUDDisplayState"
    )
    weapon_vis_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionToggleAIWeaponVisibility"
    )
    level_switch_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionEnableOrDisableLevelSwitching"
    )

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("WorldStateExecScript", "")
    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(40, 0, 100), unreal.Rotator(0, 0, 0)
    )
    marker = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(200, 0, 50), unreal.Rotator(0, 0, 0)
    )
    marker.set_actor_label("GoalMarker")
    ai = subsystem.spawn_actor_from_class(
        ai_cls, unreal.Vector(120, 0, 50), unreal.Rotator(0, 0, 0)
    )
    ai.set_actor_label("SplicerA")
    ai.configure_identity("ThuggishSplicer", "SplicerA")

    post_goal = unreal.new_object(post_goal_cls)
    post_goal.configure("SplicerA", "GoalMarker", "PatrolGoal", 50, False)
    remove_goal = unreal.new_object(remove_goal_cls)
    remove_goal.configure("SplicerA", "PatrolGoal")
    training = unreal.new_object(training_cls)
    training.configure("Train.Move")
    fade = unreal.new_object(fade_cls)
    fade.configure(0.25, 2.5)
    save = unreal.new_object(save_cls)
    save.configure(True)
    vuln = unreal.new_object(vuln_cls)
    vuln.configure("SplicerA", False, True, True)
    res_station = unreal.new_object(res_station_cls)
    res_station.configure("VitaChamber_Medical", True)
    attach_vis = unreal.new_object(attach_vis_cls)
    attach_vis.configure("SplicerA", "Hat", True)
    hud_state = unreal.new_object(hud_state_cls)
    hud_state.configure(False)
    weapon_vis = unreal.new_object(weapon_vis_cls)
    weapon_vis.configure("SplicerA", False)
    level_switch = unreal.new_object(level_switch_cls)
    level_switch.configure(True)

    runner = script.get_runner()
    actions = (
        post_goal,
        remove_goal,
        training,
        fade,
        save,
        vuln,
        res_station,
        attach_vis,
        hud_state,
        weapon_vis,
        level_switch,
    )
    for action in actions:
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(len(actions) + 1):
        runner.tick_execution(0.0)

    if str(remove_goal.get_last_target_label()) != "SplicerA":
        f.append("remove goal target %s" % remove_goal.get_last_target_label())
    if remove_goal.get_last_goal_name() != "PatrolGoal":
        f.append("remove goal name %s" % remove_goal.get_last_goal_name())
    if str(training.get_last_message_name()) != "Train.Move":
        f.append("training %s" % training.get_last_message_name())
    if float(fade.get_last_volume()) != 0.25:
        f.append("fade volume %s" % fade.get_last_volume())
    if bool(save.get_last_disable_level_saving()) is not True:
        f.append("level save record")
    if str(vuln.get_last_ai_label()) != "SplicerA":
        f.append("vuln label %s" % vuln.get_last_ai_label())
    if str(res_station.get_last_station_label()) != "VitaChamber_Medical":
        f.append("res station record %s" % res_station.get_last_station_label())
    if str(attach_vis.get_last_ai_label()) != "SplicerA":
        f.append("attach vis record %s" % attach_vis.get_last_ai_label())
    if bool(hud_state.get_last_enable_hud()) is not False:
        f.append("hud state record")
    if str(weapon_vis.get_last_ai_label()) != "SplicerA":
        f.append("weapon vis record %s" % weapon_vis.get_last_ai_label())
    if bool(level_switch.get_last_disable_level_switching()) is not True:
        f.append("level switch record")

    if player is None:
        f.append("no ShockPlayer")
    else:
        if str(player.get_training_message()) != "Train.Move":
            f.append("in-world training %s" % player.get_training_message())
        if abs(float(player.get_fade_volume_override()) - 0.25) > 0.001:
            f.append("in-world fade %s" % player.get_fade_volume_override())
        if abs(float(player.get_fade_volume_duration()) - 2.5) > 0.001:
            f.append("in-world fade duration %s" % player.get_fade_volume_duration())
        if not _flag(player.is_level_saving_disabled):
            f.append("in-world level saving still enabled")
        if not _flag(
            lambda: player.is_resurrection_station_activated("VitaChamber_Medical")
        ):
            f.append("in-world res station not activated")
        if _flag(player.is_hud_enabled):
            f.append("in-world HUD still enabled")
        if not _flag(player.is_level_switching_disabled):
            f.append("in-world level switching still enabled")

    if ai is None:
        f.append("no BaseShockAI")
    else:
        goal = str(ai.get_movement_goal_name())
        if goal:
            f.append("in-world goal still %s" % goal)
        if _flag(ai.is_vulnerable):
            f.append("in-world still vulnerable")
        if not _flag(ai.cannot_die):
            f.append("in-world can still die")
        if not _flag(ai.cannot_become_unconscious):
            f.append("in-world can still unconscious")
        if not _flag(lambda: ai.is_attachment_category_hidden("Hat")):
            f.append("in-world attachment Hat not hidden")
        if _flag(ai.is_weapon_visible):
            f.append("in-world weapon still visible")

    report["world_state_exec"] = "ok" if not f else "fail"

    for actor in (script, player, marker, ai):
        if actor:
            subsystem.destroy_actor(actor)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("world-state-exec:\n- " + "\n- ".join(f))
    _log("PASS world-state-exec")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "script_world_state_exec_report.json"),
        )
    )
