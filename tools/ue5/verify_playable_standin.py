"""Playable-slice stand-ins: health damage, hitscan fire, SpawnAI world spawn.

Does not claim PIE possess, TommyGun mesh, or real SpawningManager.
Parked for a later UnrealEditor-Cmd run — do not require while user games.
"""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-playable-standin] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    world = unreal.EditorLevelLibrary.get_editor_world()

    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    ai = world.spawn_actor(ai_cls, unreal.Vector(200.0, 0.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
    if not ai:
        f.append("spawn AI")
    else:
        ai.authored_max_health = 100.0
        ai.ensure_health_initialized()
        if float(ai.get_current_health()) != 100.0:
            f.append("AI health init")
        remaining = float(ai.apply_authored_damage(30.0))
        if remaining != 70.0:
            f.append("AI damage %s" % remaining)
        report["ai_health"] = remaining

    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    weapon = world.spawn_actor(weapon_cls, unreal.Vector(0.0, 0.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
    weapon.configure_hitscan(25.0, 5000.0)

    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    player = world.spawn_actor(player_cls, unreal.Vector(0.0, 0.0, 100.0), unreal.Rotator(0.0, 0.0, 0.0))
    player.equip_weapon(weapon)

    # Point player at AI and fire
    if ai and player:
        direction = ai.get_actor_location() - player.get_actor_location()
        hit = bool(weapon.fire_at(player, player.get_actor_location(), direction))
        if not hit:
            f.append("hitscan miss")
        report["hitscan"] = "ok" if hit else "miss"
        report["fire_count"] = int(weapon.get_fire_count())

    spawn_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnAI")
    spawn = unreal.new_object(spawn_cls)
    spawn.configure("Agg_BabyJane", "SpawnMarker", "BabyJane_A", 0.0, 0.0, True)
    spawned = spawn.spawn_at_location(world, unreal.Vector(400.0, 0.0, 100.0))
    if not spawned:
        f.append("SpawnAtLocation")
    report["spawn_ai"] = "ok" if spawned else "fail"

    attack_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttackTarget")
    attack = unreal.new_object(attack_cls)
    attack.configure("BabyJane_A", "Player", False)
    if ai:
        before = float(ai.get_current_health())
        if not attack.apply_immediate_damage(ai, 10.0):
            f.append("ApplyImmediateDamage")
        elif float(ai.get_current_health()) != before - 10.0:
            f.append("ApplyImmediateDamage amount")
    report["attack"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("playable-standin:\n- " + "\n- ".join(f))
    _log("PASS playable stand-in")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\playable_standin_report.json"))
