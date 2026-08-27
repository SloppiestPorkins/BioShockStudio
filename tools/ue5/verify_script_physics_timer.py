"""Runner DealDamageInRadius + ApplyImpulse + timer/console/mesh records."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-physics-timer] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    radius_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDealDamageInRadius"
    )
    impulse_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionApplyImpulse")
    start_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStartTimer")
    stop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopTimer")
    console_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionRunConsoleCommand"
    )
    mesh_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionChangeStaticMesh"
    )
    pawn_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPawn")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("PhysTimerScript", "")

    source = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(0, 0, 100), unreal.Rotator(0, 0, 0)
    )
    source.set_actor_label("BlastSource")
    near = subsystem.spawn_actor_from_class(
        pawn_cls, unreal.Vector(50, 0, 100), unreal.Rotator(0, 0, 0)
    )
    near.set_actor_label("NearVictim")
    near.ensure_health_initialized()
    before_near = float(near.get_current_health())
    far = subsystem.spawn_actor_from_class(
        pawn_cls, unreal.Vector(5000, 0, 100), unreal.Rotator(0, 0, 0)
    )
    far.set_actor_label("FarVictim")
    far.ensure_health_initialized()
    before_far = float(far.get_current_health())

    box = subsystem.spawn_actor_from_class(
        unreal.StaticMeshActor, unreal.Vector(0, 0, 80), unreal.Rotator(0, 0, 0)
    )
    box.set_actor_label("ImpulseBox")

    radius = unreal.new_object(radius_cls)
    radius.configure("BlastSource", 10.0, 0, 200)
    impulse = unreal.new_object(impulse_cls)
    impulse.configure("ImpulseBox", unreal.Vector(0, 0, 500), "")
    start = unreal.new_object(start_cls)
    start.configure(2.5)
    stop = unreal.new_object(stop_cls)
    stop.configure("MyTimerScript")
    console = unreal.new_object(console_cls)
    console.configure("stat fps")
    mesh = unreal.new_object(mesh_cls)
    mesh.configure("ImpulseBox", "SomeMesh")

    runner = script.get_runner()
    for action in (radius, impulse, start, stop, console, mesh):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(6):
        runner.tick_execution(0.0)

    after_near = float(near.get_current_health())
    after_far = float(far.get_current_health())
    if after_near >= before_near:
        f.append("near not damaged %s->%s" % (before_near, after_near))
    if after_far < before_far:
        f.append("far damaged unexpectedly")
    if str(radius.get_last_source_actor_label()) != "BlastSource":
        f.append("radius source %s" % radius.get_last_source_actor_label())
    if str(impulse.get_last_target()) != "ImpulseBox":
        f.append("impulse target %s" % impulse.get_last_target())
    if float(start.get_last_seconds()) != 2.5:
        f.append("timer %s" % start.get_last_seconds())
    if str(stop.get_last_script_label()) != "MyTimerScript":
        f.append("stop %s" % stop.get_last_script_label())
    if str(console.get_last_command()) != "stat fps":
        f.append("console %s" % console.get_last_command())
    if str(mesh.get_last_target_label()) != "ImpulseBox":
        f.append("mesh %s" % mesh.get_last_target_label())
    report["physics_timer"] = "ok"
    report["near_damage"] = before_near - after_near

    for a in (source, near, far, box, script):
        subsystem.destroy_actor(a)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("physics-timer:\n- " + "\n- ".join(f))
    _log("PASS physics-timer")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_physics_timer_report.json",
        )
    )
