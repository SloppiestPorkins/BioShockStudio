"""Runner spawn zone, spotlight, quest wait, AI reactions, debug, invincibility, patrol."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-world-ai] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    spawn_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionManipulateSpawnZoneRepopulation"
    )
    spot_tgt_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetMovableSpotlightTarget"
    )
    spot_state_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetMovableSpotlightState"
    )
    quest_wait_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionWaitForQuestLogToFinish"
    )
    react_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleAIReactions")
    debug_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDisplayOnScreenDebugMessage"
    )
    player_inv_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetPlayerInvincibility"
    )
    patrol_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIPatrol")
    physics_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangePawnPhysics")
    pawn_inv_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetPawnInvincibility"
    )
    lod_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetAINormalLODOverrideTime"
    )

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("WorldAiScript", "")

    spawn = unreal.new_object(spawn_cls)
    spawn.configure(
        "MedicalZone",
        unreal.ShockSpawnZoneRepopulationState.ENABLE,
        unreal.ShockSpawnZoneRepopulationState.NO_CHANGE,
    )
    spot_tgt = unreal.new_object(spot_tgt_cls)
    spot_tgt.configure("Spot_A", "PlayerPawn")
    spot_state = unreal.new_object(spot_state_cls)
    spot_state.configure("Spot_A", True)
    quest_wait = unreal.new_object(quest_wait_cls)
    quest_wait.configure("QuestLog_Medical", 60.0)
    react = unreal.new_object(react_cls)
    react.configure(
        "SplicerA",
        unreal.ShockToggleHitReactions.USE,
        unreal.ShockToggleHitReactions.DO_NOT_CHANGE,
    )
    debug = unreal.new_object(debug_cls)
    debug.configure("hello debug")
    player_inv = unreal.new_object(player_inv_cls)
    player_inv.configure(False)
    patrol = unreal.new_object(patrol_cls)
    patrol.configure("SplicerA", "Patrol_A")
    physics = unreal.new_object(physics_cls)
    physics.configure("PlayerPawn", True, False)
    pawn_inv = unreal.new_object(pawn_inv_cls)
    pawn_inv.configure("SplicerA", False)
    lod = unreal.new_object(lod_cls)
    lod.configure("SplicerA", 5.0)

    runner = script.get_runner()
    for action in (
        spawn,
        spot_tgt,
        spot_state,
        quest_wait,
        react,
        debug,
        player_inv,
        patrol,
        physics,
        pawn_inv,
        lod,
    ):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(11):
        runner.tick_execution(0.0)

    if str(spawn.get_last_spawn_zone_name()) != "MedicalZone":
        f.append("spawn %s" % spawn.get_last_spawn_zone_name())
    if spawn.get_aggressor_state() != unreal.ShockSpawnZoneRepopulationState.ENABLE:
        f.append("spawn aggressor")
    if str(spot_tgt.get_last_spotlight_label()) != "Spot_A":
        f.append("spot tgt %s" % spot_tgt.get_last_spotlight_label())
    if str(spot_tgt.get_last_target_actor_label()) != "PlayerPawn":
        f.append("spot target %s" % spot_tgt.get_last_target_actor_label())
    if str(spot_state.get_last_spotlight_label()) != "Spot_A":
        f.append("spot state %s" % spot_state.get_last_spotlight_label())
    if not bool(spot_state.get_spotlight_on()):
        f.append("spot on")
    if str(quest_wait.get_last_quest_log_class_name()) != "QuestLog_Medical":
        f.append("quest wait %s" % quest_wait.get_last_quest_log_class_name())
    if str(react.get_last_ai_label()) != "SplicerA":
        f.append("react %s" % react.get_last_ai_label())
    if str(debug.get_last_message()) != "hello debug":
        f.append("debug %s" % debug.get_last_message())
    if bool(player_inv.get_last_invincible()):
        f.append("player inv")
    if str(patrol.get_last_patrol_name()) != "Patrol_A":
        f.append("patrol %s" % patrol.get_last_patrol_name())
    if str(physics.get_last_target_label()) != "PlayerPawn":
        f.append("physics %s" % physics.get_last_target_label())
    if str(pawn_inv.get_last_pawn_label()) != "SplicerA":
        f.append("pawn inv %s" % pawn_inv.get_last_pawn_label())
    if str(lod.get_last_ai_label()) != "SplicerA":
        f.append("lod %s" % lod.get_last_ai_label())
    report["world_ai"] = "ok"

    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("world-ai:\n- " + "\n- ".join(f))
    _log("PASS world-ai")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_world_ai_report.json",
        )
    )
