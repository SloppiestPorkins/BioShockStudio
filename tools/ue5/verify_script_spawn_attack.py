"""Runner SpawnAI at labeled location + AttackTarget ScriptedAttackTarget."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-spawn-attack] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    spawn_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnAI")
    attack_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttackTarget")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 200), unreal.Rotator(0, 0, 0)
    )
    script.configure("SpawnAttackScript", "")
    loc = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(100, 0, 50), unreal.Rotator(0, 0, 0)
    )
    loc.set_actor_label("SpawnPad")
    victim = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(200, 0, 50), unreal.Rotator(0, 0, 0)
    )
    victim.set_actor_label("Victim")
    victim.ensure_health_initialized()
    health_before = float(victim.get_current_health())

    spawn = unreal.new_object(spawn_cls)
    spawn.configure("ThuggishSplicer", "SpawnPad", "SpawnedThug", 0.0, 0.0, True)
    attack = unreal.new_object(attack_cls)
    attack.configure("SpawnedThug", "Victim", False)
    sight = unreal.new_object(attack_cls)
    sight.configure("SpawnedThug", "Victim", True)

    runner = script.get_runner()
    runner.add_action(spawn)
    runner.add_action(attack)
    runner.add_action(sight)
    if not runner.start_execution():
        f.append("StartExecution")
    runner.tick_execution(0.0)

    spawned = spawn.get_last_spawned_actor()
    if spawned is None:
        f.append("no spawned AI")
    else:
        report["spawned"] = spawned.get_actor_label()
        if report["spawned"] != "SpawnedThug":
            f.append("label %s" % report["spawned"])
        ordered = spawned.get_scripted_attack_target()
        if ordered is None:
            f.append("ScriptedAttackTarget not set")
        elif ordered != victim:
            f.append("ScriptedAttackTarget was %s" % ordered.get_actor_label())
        if not bool(spawned.has_attack_on_sight_label("Victim")):
            f.append("AddTargetToAttackOnSight Victim missing")
    if str(attack.get_last_requested_ai_label()) != "SpawnedThug":
        f.append("attack AI %s" % attack.get_last_requested_ai_label())
    if str(attack.get_last_requested_target_label()) != "Victim":
        f.append("attack target %s" % attack.get_last_requested_target_label())
    if int(attack.get_last_applied_count()) != 1:
        f.append("applied count %s" % attack.get_last_applied_count())
    if int(sight.get_last_applied_count()) != 1:
        f.append("sight applied count %s" % sight.get_last_applied_count())
    health_after = float(victim.get_current_health())
    if health_after != health_before:
        f.append("AttackTarget must not deal damage itself (%s -> %s)" % (
            health_before, health_after))
    report["health"] = {"before": health_before, "after": health_after}
    report["applied"] = int(attack.get_last_applied_count())

    if spawned:
        subsystem.destroy_actor(spawned)
    subsystem.destroy_actor(victim)
    subsystem.destroy_actor(loc)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("spawn-attack:\n- " + "\n- ".join(f))
    _log("PASS spawn-attack")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_spawn_attack_report.json",
        )
    )
