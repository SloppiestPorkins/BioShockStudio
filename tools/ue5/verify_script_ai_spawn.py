"""Runner AI/spawn/fact records + Ragdoll ApplyInWorld."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-ai-spawn] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    state_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIState")
    ragdoll_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRagdoll")
    pickup_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnPickup")
    turret_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnTurret")
    assert_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssertFact")
    retract_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRetractFact")
    move_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionForcePlayerMove")
    wait_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToWait")
    cont_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToContinue")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("AiSpawnScript", "")
    rag_target = subsystem.spawn_actor_from_class(
        unreal.StaticMeshActor, unreal.Vector(0, 0, 80), unreal.Rotator(0, 0, 0)
    )
    rag_target.set_actor_label("RagdollAI")
    spawn_here = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(150, 0, 80), unreal.Rotator(0, 0, 0)
    )
    spawn_here.set_actor_label("SpawnHere")
    turret_spawner = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(200, 0, 80), unreal.Rotator(0, 0, 0)
    )
    turret_spawner.set_actor_label("TurretSpawner")

    state = unreal.new_object(state_cls)
    state.configure("SomeAI", 3)
    ragdoll = unreal.new_object(ragdoll_cls)
    ragdoll.configure("RagdollAI", False, unreal.Vector(0, 0, 1), 100.0)
    pickup = unreal.new_object(pickup_cls)
    pickup.configure("PickupA", "SpawnHere", "PickupClass", "Item.Ammo", 5, True)
    turret = unreal.new_object(turret_cls)
    turret.configure("TurretSpawner")
    assert_f = unreal.new_object(assert_cls)
    assert_f.configure("Quest", "FindKey", "true")
    retract_f = unreal.new_object(retract_cls)
    retract_f.configure("Quest", "FindKey", "")
    move = unreal.new_object(move_cls)
    move.configure("MoveMarker", "", 2.0, 100.0, 45.0)
    wait_ai = unreal.new_object(wait_cls)
    wait_ai.configure("SomeAI")
    cont_ai = unreal.new_object(cont_cls)
    cont_ai.configure("SomeAI")

    runner = script.get_runner()
    for action in (state, ragdoll, pickup, turret, assert_f, retract_f, move, wait_ai, cont_ai):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(9):
        runner.tick_execution(0.0)

    if str(state.get_last_ai_label()) != "SomeAI":
        f.append("state %s" % state.get_last_ai_label())
    if str(ragdoll.get_last_ai_label()) != "RagdollAI":
        f.append("ragdoll %s" % ragdoll.get_last_ai_label())
    if str(pickup.get_last_target_actor_label()) != "SpawnHere":
        f.append("pickup %s" % pickup.get_last_target_actor_label())
    spawned_pickup = pickup.get_last_spawned_actor()
    if spawned_pickup is None:
        f.append("no spawned pickup")
    else:
        report["pickup_label"] = spawned_pickup.get_actor_label()
        if report["pickup_label"] != "PickupA":
            f.append("pickup label %s" % report["pickup_label"])
        pickup_loc = spawned_pickup.get_actor_location()
        if abs(float(pickup_loc.x) - 150.0) > 1.0:
            f.append("pickup loc %s" % pickup_loc)
    if str(turret.get_last_spawner_label()) != "TurretSpawner":
        f.append("turret %s" % turret.get_last_spawner_label())
    spawned_turret = turret.get_last_spawned_actor()
    if spawned_turret is None:
        f.append("no spawned turret")
    else:
        turret_loc = spawned_turret.get_actor_location()
        if abs(float(turret_loc.x) - 200.0) > 1.0:
            f.append("turret loc %s" % turret_loc)
        report["turret_spawned"] = True
    if str(assert_f.get_last_slot1()) != "Quest":
        f.append("assert %s" % assert_f.get_last_slot1())
    if str(retract_f.get_last_slot1()) != "Quest":
        f.append("retract %s" % retract_f.get_last_slot1())
    if str(move.get_last_marker_label()) != "MoveMarker":
        f.append("move %s" % move.get_last_marker_label())
    if str(wait_ai.get_last_ai_label()) != "SomeAI":
        f.append("wait %s" % wait_ai.get_last_ai_label())
    if str(cont_ai.get_last_ai_label()) != "SomeAI":
        f.append("continue %s" % cont_ai.get_last_ai_label())
    report["ai_spawn"] = "ok"

    spawned_pickup = pickup.get_last_spawned_actor()
    if spawned_pickup:
        subsystem.destroy_actor(spawned_pickup)
    spawned_turret = turret.get_last_spawned_actor()
    if spawned_turret:
        subsystem.destroy_actor(spawned_turret)
    subsystem.destroy_actor(turret_spawner)
    subsystem.destroy_actor(spawn_here)
    subsystem.destroy_actor(rag_target)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("ai-spawn:\n- " + "\n- ".join(f))
    _log("PASS ai-spawn")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_ai_spawn_report.json",
        )
    )
