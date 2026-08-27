"""Runner fires PlayEffect / StopEffect by actor label."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-fx] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    play_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayEffect")
    stop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopEffect")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 120), unreal.Rotator(0, 0, 0)
    )
    script.configure("FxScript", "")
    target = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(0, 0, 60), unreal.Rotator(0, 0, 0)
    )
    target.set_actor_label("FxTarget")

    play = unreal.new_object(play_cls)
    play.configure("ScriptTrigger", "FX_Tag", "FxTarget")
    stop = unreal.new_object(stop_cls)
    stop.configure("ScriptTrigger", "FX_Tag", "FxTarget")

    runner = script.get_runner()
    runner.add_action(play)
    runner.add_action(stop)
    if not runner.start_execution():
        f.append("StartExecution")
    runner.tick_execution(0.0)

    if str(play.get_editor_property("last_fired_event")) != "ScriptTrigger":
        f.append("play event %s" % play.get_editor_property("last_fired_event"))
    if str(play.get_editor_property("last_fired_tag")) != "FX_Tag":
        f.append("play tag %s" % play.get_editor_property("last_fired_tag"))
    if not str(play.get_editor_property("last_fired_actor_name")):
        f.append("play actor name empty")
    if str(stop.get_last_stopped_event()) != "ScriptTrigger":
        f.append("stop event %s" % stop.get_last_stopped_event())
    report["runner"] = "ok"

    play2 = unreal.new_object(play_cls)
    play2.configure("ScriptTrigger", "Direct", "FxTarget")
    if int(play2.fire_in_world(world)) < 1:
        f.append("fire_in_world")
    report["direct"] = "ok"

    subsystem.destroy_actor(target)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-fx:\n- " + "\n- ".join(f))
    _log("PASS script fx")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_fx_report.json",
        )
    )
