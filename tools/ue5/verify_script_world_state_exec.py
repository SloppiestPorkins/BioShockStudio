"""Runner RemoveGoal / ShowTrainingMessage / FadeVolume / LevelSaving / SetAIVulnerability."""

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

    runner = script.get_runner()
    for action in (post_goal, remove_goal, training, fade, save, vuln):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(6):
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
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_world_state_exec_report.json",
        )
    )
