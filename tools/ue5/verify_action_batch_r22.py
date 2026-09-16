"""Headless R2.2-R2.4 verification for the actions that were still record-only.

Run inside UnrealEditor-Cmd after compiling the runtime plugin. The test creates only throwaway
editor-world actors and destroys them before writing its JSON report.
"""

import json
import os

import unreal


MESH_ROOTS = (
    "/Game/BioShockSlice/Content/Meshes",
    "/Game/BioShockLevel/Content/Meshes",
)


def _runtime_class(name):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if cls is None:
        raise RuntimeError("missing runtime class %s" % name)
    return cls


def _first_imported_mesh():
    for root in MESH_ROOTS:
        for path in unreal.EditorAssetLibrary.list_assets(root, recursive=True):
            asset = unreal.load_asset(path)
            if isinstance(asset, unreal.StaticMesh):
                return asset
    raise RuntimeError("no imported static mesh under %s" % (MESH_ROOTS,))


def _check(condition, failures, message):
    if not condition:
        failures.append(message)


def main(out_path):
    failures = []
    report = {"failures": failures}
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    spawned = []

    def spawn(cls, label, location):
        actor = subsystem.spawn_actor_from_class(
            cls, location, unreal.Rotator(0.0, 0.0, 0.0)
        )
        if actor is None:
            raise RuntimeError("failed to spawn %s" % label)
        actor.set_actor_label(label)
        spawned.append(actor)
        return actor

    try:
        # ChangeStaticMesh: resolve the same two roots as import_slice_pickups and replace the
        # component's UStaticMesh pointer (the old implementation only added a tag).
        imported_mesh = _first_imported_mesh()
        mesh_target = spawn(
            unreal.StaticMeshActor, "R22_MeshTarget", unreal.Vector(0.0, 0.0, 100.0)
        )
        mesh_target.static_mesh_component.set_static_mesh(
            unreal.load_asset("/Engine/BasicShapes/Cube.Cube")
        )
        mesh_action = unreal.new_object(_runtime_class("ShockActionChangeStaticMesh"))
        mesh_action.configure("R22_MeshTarget", imported_mesh.get_name())
        _check(int(mesh_action.apply_in_world(world)) == 1, failures, "ChangeStaticMesh apply")
        assigned = mesh_target.static_mesh_component.get_editor_property("static_mesh")
        _check(assigned == imported_mesh, failures, "ChangeStaticMesh did not swap component mesh")
        report["mesh"] = imported_mesh.get_path_name()

        # ChangeCollision: one independent action per authored field.  The integer channel values
        # are UE5's built-in WorldStatic, WorldDynamic, Pawn, Visibility and PhysicsBody order.
        collision_target = spawn(
            unreal.StaticMeshActor,
            "R22_CollisionTarget",
            unreal.Vector(200.0, 0.0, 100.0),
        )
        collision_target.static_mesh_component.set_static_mesh(
            unreal.load_asset("/Engine/BasicShapes/Cube.Cube")
        )
        change = unreal.ShockCollisionChange
        no = change.DO_NOT_CHANGE
        yes = change.SET_TO_TRUE

        collision_cases = (
            ("CollideWorld", 0, (no, yes, no, no, no, no, no)),
            ("BlockActors", 1, (no, no, yes, no, no, no, no)),
            ("BlockPlayers", 2, (no, no, no, yes, no, no, no)),
            ("BlockNonZeroExtentTraces", 3, (no, no, no, no, yes, no, no)),
            ("WorldGeometry", 0, (no, no, no, no, no, yes, no)),
            ("BlockHavok", 4, (no, no, no, no, no, no, yes)),
        )
        collision_results = {}
        for field, channel, values in collision_cases:
            action = unreal.new_object(_runtime_class("ShockActionChangeCollision"))
            action.configure_all("R22_CollisionTarget", *values)
            _check(action.apply_to_actor(collision_target), failures, "%s apply" % field)
            response = int(action.get_response_to_channel_for_verify(collision_target, channel))
            collision_results[field] = {"channel": channel, "response": response}
            _check(response == 2, failures, "%s response=%s, expected Block" % (field, response))

        actor_collision = unreal.new_object(_runtime_class("ShockActionChangeCollision"))
        actor_collision.configure("R22_CollisionTarget", change.SET_TO_FALSE)
        _check(actor_collision.apply_to_actor(collision_target), failures, "CollideActors apply")
        _check(
            not collision_target.get_actor_enable_collision(),
            failures,
            "CollideActors did not disable actor collision",
        )
        collision_results["CollideActors"] = False
        report["collision"] = collision_results

        # PlaceItemInContainerSlot: action changes the container slot and searching transfers that
        # exact stack to the player's real inventory map.
        container = spawn(
            _runtime_class("ShockSearchableContainer"),
            "R22_Container",
            unreal.Vector(400.0, 0.0, 100.0),
        )
        container.configure_container("R22_Container", 0, 0, "", 1)
        player = spawn(
            _runtime_class("ShockPlayer"),
            "R22_Player",
            unreal.Vector(500.0, 0.0, 100.0),
        )
        place = unreal.new_object(_runtime_class("ShockActionPlaceItemInContainerSlot"))
        place.configure_inventory("FirstAidKit", 2)
        place.configure_slot("R22_Container", 3, False)
        _check(int(place.apply_in_world(world)) == 1, failures, "PlaceItemInContainerSlot apply")
        _check(str(container.get_slot_item_class(3)) == "FirstAidKit", failures, "slot item")
        _check(int(container.get_slot_stack_size(3)) == 2, failures, "slot stack")
        _check(container.search(player), failures, "container search")
        _check(int(player.get_inventory_stack("FirstAidKit")) == 2, failures, "slot transfer")
        report["containerSlot"] = {"slot": 3, "item": "FirstAidKit", "stack": 2}

        # SetOrUnsetInputContext preserves UE2 PUSH/POP stack semantics.
        input_action = unreal.new_object(_runtime_class("ShockActionSetOrUnsetInputContext"))
        input_action.configure("Gameplay", False)
        _check(int(input_action.apply_in_world(world)) == 1, failures, "input push Gameplay")
        input_action.configure("Cinematic", False)
        _check(int(input_action.apply_in_world(world)) == 1, failures, "input push Cinematic")
        input_action.configure("Cinematic", True)
        _check(int(input_action.apply_in_world(world)) == 1, failures, "input pop Cinematic")
        _check(str(player.get_current_input_context()) == "Gameplay", failures, "input stack restore")
        _check(int(player.get_input_context_depth()) == 1, failures, "input stack depth")
        report["inputContext"] = "push_pop"

        # ToggleAIReactions: prove the action now gates ReactToHit, rather than only storing bytes.
        ai = spawn(
            _runtime_class("BaseShockAI"),
            "R22_ReactionAI",
            unreal.Vector(700.0, 0.0, 100.0),
        )
        ai.configure_identity("ThuggishSplicer", "R22_ReactionAI")
        ai.ensure_health_initialized()
        reactions = unreal.new_object(_runtime_class("ShockActionToggleAIReactions"))
        reactions.configure(
            "R22_ReactionAI",
            unreal.ShockToggleHitReactions.DO_NOT_USE,
            unreal.ShockToggleHitReactions.DO_NOT_USE,
        )
        _check(int(reactions.apply_in_world(world)) == 1, failures, "ToggleAIReactions disable")
        ai.apply_authored_damage(1.0)
        _check(float(ai.get_hit_react_remaining()) == 0.0, failures, "disabled quick reaction fired")
        reactions.configure(
            "R22_ReactionAI",
            unreal.ShockToggleHitReactions.USE,
            unreal.ShockToggleHitReactions.USE,
        )
        _check(int(reactions.apply_in_world(world)) == 1, failures, "ToggleAIReactions enable")
        ai.apply_authored_damage(1.0)
        _check(float(ai.get_hit_react_remaining()) > 0.0, failures, "enabled quick reaction did not fire")
        report["reactions"] = "gated"

        # WaitForGoal observes the AI goal lifecycle: active blocks, completion yields result 0.
        ai.post_scripted_movement_goal(
            "R22_GoalDestination", "R22_MoveGoal", 50, True, unreal.Vector(850.0, 0.0, 100.0)
        )
        goal_wait = unreal.new_object(_runtime_class("ShockActionWaitForGoal"))
        goal_wait.configure("R22_ReactionAI", "R22_MoveGoal", 2.0)
        _check(goal_wait.prepare_wait(world, 0.0), failures, "WaitForGoal prepare")
        _check(not goal_wait.is_ready(world, 0.0), failures, "active goal did not block")
        ai.complete_scripted_movement_goal(True)
        _check(goal_wait.is_ready(world, 0.5), failures, "completed goal did not resume")
        _check(int(goal_wait.get_result()) == 0, failures, "completed goal result")
        report["goalWait"] = "blocked_then_completed"

        # WaitForQuestLogToFinish: the runner must stop before the following action while the
        # named log is active, then continue as soon as playback clears.
        script = spawn(
            _runtime_class("ShockScript"),
            "R22_QuestWaitScript",
            unreal.Vector(900.0, 0.0, 200.0),
        )
        script.configure("R22_QuestWaitScript", "")
        player.set_quest_log_playing("QuestLog_R22", True)
        quest_wait = unreal.new_object(_runtime_class("ShockActionWaitForQuestLogToFinish"))
        quest_wait.configure("QuestLog_R22", 2.0)
        concept = unreal.new_object(_runtime_class("ShockActionDisableOrEnableConcept"))
        concept.configure("R22_AfterQuestLog", False)
        runner = script.get_runner()
        runner.add_action(quest_wait)
        runner.add_action(concept)
        _check(runner.start_execution(), failures, "quest wait runner start")
        _check(runner.tick_execution(0.0), failures, "quest wait should remain blocked")
        _check(player.is_concept_enabled("R22_AfterQuestLog"), failures, "quest wait fell through")
        player.set_quest_log_playing("QuestLog_R22", False)
        runner.tick_execution(0.5)
        _check(not player.is_concept_enabled("R22_AfterQuestLog"), failures, "quest wait did not resume")
        _check(not quest_wait.did_last_wait_time_out(), failures, "quest wait timed out unexpectedly")
        report["questLogWait"] = "blocked_then_resumed"
    finally:
        for actor in reversed(spawned):
            if actor:
                subsystem.destroy_actor(actor)

    report["status"] = "pass" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("R2.2-R2.4 action batch failed:\n- " + "\n- ".join(failures))
    unreal.log("[bioshock-action-r22] PASS")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "verify_action_batch_r22.json"),
        )
    )
