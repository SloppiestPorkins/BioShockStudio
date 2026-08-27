"""Runner executes HideOrShow / SetProperty / Destroy by actor label in World."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-world-actions] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    hide_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionHideOrShowActor")
    set_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetProperty")
    destroy_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDestroyActor")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 100), unreal.Rotator(0, 0, 0)
    )
    script.configure("WorldActionScript", "")
    target = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(0, 0, 50), unreal.Rotator(0, 0, 0)
    )
    target.set_actor_label("WorldActionTarget")

    hide = unreal.new_object(hide_cls)
    hide.configure("WorldActionTarget", True)
    setp = unreal.new_object(set_cls)
    setp.configure("WorldActionTarget", "Label", "WorldActionRenamed")
    destroy = unreal.new_object(destroy_cls)
    destroy.configure("WorldActionRenamed")

    runner = script.get_runner()
    runner.add_action(hide)
    runner.add_action(setp)
    runner.add_action(destroy)
    if not runner.start_execution():
        f.append("StartExecution")
    runner.tick_execution(0.0)

    if not bool(hide.did_last_apply_succeed()):
        f.append("hide did not apply")
    still = [
        a
        for a in subsystem.get_all_level_actors()
        if a.get_actor_label() in ("WorldActionTarget", "WorldActionRenamed")
    ]
    if still:
        f.append("expected destroy, left %s" % [a.get_actor_label() for a in still])
    report["pipeline"] = "ok"

    # Direct ApplyInWorld / DestroyInWorld
    t2 = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(10, 10, 50), unreal.Rotator(0, 0, 0)
    )
    t2.set_actor_label("HideOnly")
    hide2 = unreal.new_object(hide_cls)
    hide2.configure("HideOnly", True)
    if int(hide2.apply_in_world(world)) < 1:
        f.append("hide apply_in_world")
    report["hide_direct"] = "ok"
    subsystem.destroy_actor(t2)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("world-actions:\n- " + "\n- ".join(f))
    _log("PASS world actions")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_world_actions_report.json",
        )
    )
