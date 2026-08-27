"""Runner PlayAnimation by label + ActionLog Emit."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-anim-log] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    anim_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayAnimation")
    log_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLog")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("AnimLogScript", "")
    target = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(0, 0, 80), unreal.Rotator(0, 0, 0)
    )
    target.set_actor_label("AnimTarget")

    play = unreal.new_object(anim_cls)
    play.configure("AnimTarget", "Idle", 1.0, 0)
    log_action = unreal.new_object(log_cls)
    log_action.configure("hello from ActionLog")

    runner = script.get_runner()
    runner.add_action(play)
    runner.add_action(log_action)
    if not runner.start_execution():
        f.append("StartExecution")
    runner.tick_execution(0.0)

    if str(play.get_last_played_animation()) != "Idle":
        f.append("anim %s" % play.get_last_played_animation())
    if not str(play.get_last_played_actor_name()):
        f.append("actor name empty")
    if str(log_action.get_last_logged_text()) != "hello from ActionLog":
        f.append("log %s" % log_action.get_last_logged_text())
    report["anim"] = "ok"
    report["log"] = "ok"

    subsystem.destroy_actor(target)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("anim-log:\n- " + "\n- ".join(f))
    _log("PASS anim-log")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_anim_log_report.json",
        )
    )
