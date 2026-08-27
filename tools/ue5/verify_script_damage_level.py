"""Runner DealDamage by label + ChangeLevel/Crouch/DisableMovement records."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-damage-level] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    dmg_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDealDamage")
    level_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeLevel")
    crouch_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionForcePlayerCrouch"
    )
    move_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDisablePlayerMovement"
    )
    pawn_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPawn")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("DmgLevelScript", "")
    victim = subsystem.spawn_actor_from_class(
        pawn_cls, unreal.Vector(50, 0, 100), unreal.Rotator(0, 0, 0)
    )
    victim.set_actor_label("DmgVictim")
    victim.ensure_health_initialized()
    before = float(victim.get_current_health())

    dmg = unreal.new_object(dmg_cls)
    dmg.configure("DmgVictim", 25.0, 1.0)
    level = unreal.new_object(level_cls)
    level.configure("1-Medical", "MedicalStart", False, True)
    crouch = unreal.new_object(crouch_cls)
    crouch.configure(True)
    disable = unreal.new_object(move_cls)
    disable.configure(True)

    runner = script.get_runner()
    for action in (dmg, level, crouch, disable):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(4):
        runner.tick_execution(0.0)

    after = float(victim.get_current_health())
    if after >= before:
        f.append("no damage %s->%s" % (before, after))
    if str(dmg.get_last_target_label()) != "DmgVictim":
        f.append("last target %s" % dmg.get_last_target_label())
    if str(level.get_last_map_name()) != "1-Medical":
        f.append("map %s" % level.get_last_map_name())
    if not bool(crouch.get_last_should_crouch()):
        f.append("crouch not recorded")
    if not bool(disable.get_last_disable_movement()):
        f.append("disable move not recorded")
    report["damage_level"] = "ok"
    report["damage"] = before - after

    subsystem.destroy_actor(victim)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("damage-level:\n- " + "\n- ".join(f))
    _log("PASS damage-level")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_damage_level_report.json",
        )
    )
