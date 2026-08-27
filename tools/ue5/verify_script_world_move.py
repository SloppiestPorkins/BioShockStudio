"""Runner Teleport / Freeze / SetActorLabel by editor label."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-world-move] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    teleport_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionTeleportPawnToLocation"
    )
    freeze_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionFreezeHavokActor"
    )
    setlabel_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetActorLabel"
    )

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 400), unreal.Rotator(0, 0, 0)
    )
    script.configure("WorldMoveScript", "")

    pawn = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(10, 20, 30), unreal.Rotator(0, 0, 0)
    )
    pawn.set_actor_label("TeleportPawn")
    marker = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(100, 200, 50), unreal.Rotator(0, 45, 0)
    )
    marker.set_actor_label("TeleportMarker")
    freeze_target = subsystem.spawn_actor_from_class(
        unreal.StaticMeshActor, unreal.Vector(0, 0, 80), unreal.Rotator(0, 0, 0)
    )
    freeze_target.set_actor_label("FreezeMe")
    rename_me = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(0, 0, 10), unreal.Rotator(0, 0, 0)
    )
    rename_me.set_actor_label("OldLabel")

    teleport = unreal.new_object(teleport_cls)
    teleport.configure("TeleportPawn", "TeleportMarker")
    freeze = unreal.new_object(freeze_cls)
    freeze.configure("FreezeMe", True)
    setlabel = unreal.new_object(setlabel_cls)
    setlabel.configure("OldLabel", "NewLabel")

    runner = script.get_runner()
    for action in (teleport, freeze, setlabel):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(3):
        runner.tick_execution(0.0)

    ploc = pawn.get_actor_location()
    if abs(ploc.x - 100) > 0.5 or abs(ploc.y - 200) > 0.5 or abs(ploc.z - 50) > 0.5:
        f.append("teleport loc %s" % ploc)
    if str(teleport.get_last_pawn_label()) != "TeleportPawn":
        f.append("last pawn %s" % teleport.get_last_pawn_label())
    if not freeze.get_last_applied_freeze():
        f.append("freeze not applied")
    if str(setlabel.get_last_new_label()) != "NewLabel":
        f.append("setlabel %s" % setlabel.get_last_new_label())
    if rename_me.get_actor_label() != "NewLabel":
        f.append("actor label now %s" % rename_me.get_actor_label())
    report["world_move"] = "ok"

    for a in (pawn, marker, freeze_target, rename_me, script):
        subsystem.destroy_actor(a)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("world-move:\n- " + "\n- ".join(f))
    _log("PASS world-move")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_world_move_report.json",
        )
    )
