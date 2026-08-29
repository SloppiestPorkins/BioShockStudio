"""Shared damage path: UShockDamageLibrary + scripted damage actions via ApplyInWorld."""

import json
import os

import unreal


def _flag(value):
    return bool(value() if callable(value) else value)


def _log(m):
    unreal.log("[bioshock-script-damage-exec] %s" % m)


def _spawn(subsystem, cls, label, loc):
    actor = subsystem.spawn_actor_from_class(cls, loc, unreal.Rotator(0, 0, 0))
    if actor:
        actor.set_actor_label(label)
    return actor


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = subsystem.get_editor_world()
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    deal_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDealDamage")
    init_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionInitiateDamage")
    radius_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDealDamageInRadius")
    shock_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDealShockingDamageInRadius"
    )
    inv_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetPawnInvincibility"
    )
    damage_lib = unreal.ShockDamageLibrary

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 320), unreal.Rotator(0, 0, 0)
    )
    script.configure("DamageExecScript", "")

    victim = _spawn(subsystem, ai_cls, "DmgVictim", unreal.Vector(80, 0, 50))
    victim.configure_identity("ThuggishSplicer", "DmgVictim")
    victim.ensure_health_initialized()
    if float(victim.get_current_health()) != 100.0:
        f.append("victim health init %s" % victim.get_current_health())

    invuln = _spawn(subsystem, ai_cls, "DmgInvuln", unreal.Vector(120, 0, 50))
    invuln.configure_identity("ThuggishSplicer", "DmgInvuln")
    invuln.ensure_health_initialized()

    lethal = _spawn(subsystem, ai_cls, "LethalVictim", unreal.Vector(200, 80, 50))
    lethal.configure_identity("ThuggishSplicer", "LethalVictim")
    lethal.ensure_health_initialized()

    player = _spawn(subsystem, player_cls, "DmgPlayer", unreal.Vector(-80, 0, 100))
    weapon = subsystem.spawn_actor_from_class(
        weapon_cls, unreal.Vector(-80, 0, 100), unreal.Rotator(0, 0, 0)
    )
    if player and weapon:
        player.equip_weapon(weapon)
        weapon.configure_hitscan(25.0, 5000.0)

    deal = unreal.new_object(deal_cls)
    deal.configure("DmgVictim", 30.0, 1.0)
    lethal_deal = unreal.new_object(deal_cls)
    lethal_deal.configure("LethalVictim", 100.0, 1.0)
    init = unreal.new_object(init_cls)
    init.configure("DmgPlayer", "DmgSource", "InitTarget", "Ammo_Pistol", 0.0)
    inv_action = unreal.new_object(inv_cls)
    inv_action.configure("DmgInvuln", True)

    init_target = _spawn(subsystem, ai_cls, "InitTarget", unreal.Vector(200, -80, 50))
    init_target.configure_identity("ThuggishSplicer", "InitTarget")
    init_target.ensure_health_initialized()

    runner = script.get_runner()
    for action in (inv_action, deal, lethal_deal):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(4):
        runner.tick_execution(0.0)

    after_deal = float(victim.get_current_health())
    if after_deal != 70.0:
        f.append("deal damage health %s" % after_deal)

    if float(invuln.get_current_health()) != 100.0:
        f.append("invuln took damage %s" % invuln.get_current_health())

    if not _flag(lethal.is_dead):
        f.append("lethal not dead health=%s" % lethal.get_current_health())
    if float(lethal.get_current_health()) != 0.0:
        f.append("lethal health not zero %s" % lethal.get_current_health())

    if int(init.apply_in_world(world)) < 1:
        f.append("initiate damage apply")
    if float(init_target.get_current_health()) != 75.0:
        f.append("initiate damage amount %s" % init_target.get_current_health())

    source = subsystem.spawn_actor_from_class(
        unreal.TargetPoint, unreal.Vector(1000, 0, 50), unreal.Rotator(0, 0, 0)
    )
    source.set_actor_label("DmgSource")

    near_ai = _spawn(subsystem, ai_cls, "RadialNear", unreal.Vector(1000, 0, 50))
    near_ai.configure_identity("ThuggishSplicer", "RadialNear")
    near_ai.ensure_health_initialized()

    mid_ai = _spawn(subsystem, ai_cls, "RadialMid", unreal.Vector(1150, 0, 50))
    mid_ai.configure_identity("ThuggishSplicer", "RadialMid")
    mid_ai.ensure_health_initialized()

    far_ai = _spawn(subsystem, ai_cls, "RadialFar", unreal.Vector(1400, 0, 50))
    far_ai.configure_identity("ThuggishSplicer", "RadialFar")
    far_ai.ensure_health_initialized()

    radius = unreal.new_object(radius_cls)
    radius.configure("DmgSource", 100.0, 0, 300)
    if int(radius.apply_in_world(world)) < 2:
        f.append("radius hit count")

    near_health = float(near_ai.get_current_health())
    mid_health = float(mid_ai.get_current_health())
    far_health = float(far_ai.get_current_health())
    if near_health != 0.0:
        f.append("radial near %s" % near_health)
    if abs(mid_health - 50.0) > 0.5:
        f.append("radial mid falloff %s" % mid_health)
    if far_health != 100.0:
        f.append("radial far untouched %s" % far_health)

    shock_near = _spawn(subsystem, ai_cls, "ShockNear", unreal.Vector(1000, 0, 50))
    shock_near.configure_identity("ThuggishSplicer", "ShockNear")
    shock_near.ensure_health_initialized()
    shock = unreal.new_object(shock_cls)
    shock.configure("DmgSource", 40.0, 24, 0, 200, 3, "TeslaEffect", 2.0, unreal.Vector2D(0.1, 0.5))
    if int(shock.apply_in_world(world)) < 1:
        f.append("shocking radius")
    if float(shock_near.get_current_health()) != 60.0:
        f.append("shocking damage %s" % shock_near.get_current_health())

    applied = float(damage_lib.apply_damage(victim, 5.0, None, "Direct"))
    if applied != 5.0 or float(victim.get_current_health()) != 65.0:
        f.append("library apply %s health=%s" % (applied, victim.get_current_health()))

    if player and weapon and victim:
        direction = victim.get_actor_location() - player.get_actor_location()
        before_hitscan = float(victim.get_current_health())
        if not weapon.fire_at(player, player.get_actor_location(), direction):
            f.append("hitscan miss")
        after_hitscan = float(victim.get_current_health())
        if after_hitscan != before_hitscan - 25.0:
            f.append("hitscan damage %s->%s" % (before_hitscan, after_hitscan))

    report["damage_exec"] = "ok" if not f else "fail"
    report["radial"] = {"near": near_health, "mid": mid_health, "far": far_health}

    for actor in (
        script,
        victim,
        invuln,
        lethal,
        source,
        near_ai,
        mid_ai,
        far_ai,
        shock_near,
        init_target,
        player,
        weapon,
    ):
        if actor:
            subsystem.destroy_actor(actor)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("damage-exec:\n- " + "\n- ".join(f))
    _log("PASS damage-exec")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "script_damage_exec_report.json"),
        )
    )
