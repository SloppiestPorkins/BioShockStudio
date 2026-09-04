"""Headless verify: ABaseShockAI PlayAnimation driven by brain ability name."""

import json
import math
import os

import unreal


def _log(message):
    unreal.log("[bioshock-ai-animation] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _dist2d(a, b):
    dx = float(a.x - b.x)
    dy = float(a.y - b.y)
    return math.sqrt(dx * dx + dy * dy)


def _tick_combat(ai, seconds, step=0.05):
    steps = int(seconds / step)
    for _ in range(steps):
        ai.advance_autonomous_combat(step)


def _setup_engaged_pair(subsystem, ai_cls, player_cls, player_x):
    ai_loc = unreal.Vector(0.0, 0.0, 100.0)
    player_loc = unreal.Vector(float(player_x), 0.0, 100.0)
    yaw = 0.0 if player_x >= 0 else 180.0
    ai = _spawn(subsystem, ai_cls, "BrainAI", ai_loc, unreal.Rotator(0.0, yaw, 0.0))
    player = _spawn(
        subsystem,
        player_cls,
        "BrainPlayer",
        player_loc,
        unreal.Rotator(0.0, 180.0 if player_x >= 0 else 0.0, 0.0),
    )
    if ai:
        ai.configure_identity("Agg_BabyJane", "BrainAI")
        ai.ensure_health_initialized()
        if not ai.is_using_brain():
            ai.set_editor_property("bUseBrain", True)
    if player:
        player.ensure_health_initialized()
    return ai, player


def _arm_attack_on_sight(ai, world, attack_cls):
    if not ai:
        return
    ai.add_target_to_attack_on_sight(unreal.Name("BrainPlayer"))
    if attack_cls:
        order = unreal.new_object(attack_cls)
        order.configure(unreal.Name("BrainAI"), unreal.Name("BrainPlayer"), True)
        if int(order.apply_in_world(world)) < 1:
            raise RuntimeError("ActionAttackTarget on-sight failed")


def _mesh_asset_name(ai):
    mesh = ai.mesh if ai else None
    if not mesh:
        return ""
    asset = mesh.get_editor_property("skeletal_mesh_asset")
    if asset is None:
        return ""
    return str(asset.get_name())


def _playing_anim(ai):
    if not ai:
        return ""
    return str(ai.get_playing_animation_name_for_verify())


def _flag(value):
    if callable(value):
        value = value()
    return bool(value)


def _destroy_spawned(subsystem, actors):
    for actor in actors:
        if actor:
            subsystem.destroy_actor(actor)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    attack_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttackTarget")
    damage_lib = unreal.ShockDamageLibrary

    expected = {
        "mesh": "AggressorBabyJane",
        "idle": "ME_Fidget_A_idle",
        "move": ("ME_WalkFWD_A_agg", "ME_runFWD_A_agg"),
        "melee": "ME_attackMelee_A",
        "death": "Death_StumbleFWD",
    }
    report["expected"] = {
        "mesh": expected["mesh"],
        "idle": expected["idle"],
        "move": list(expected["move"]),
        "melee": expected["melee"],
        "death": expected["death"],
    }

    for name, path in (
        ("mesh", "/Game/BioShockCharacters/AggressorBabyJane/AggressorBabyJane.AggressorBabyJane"),
        (
            "idle",
            "/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_Fidget_A_idle.ME_Fidget_A_idle",
        ),
        (
            "walk",
            "/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_WalkFWD_A_agg.ME_WalkFWD_A_agg",
        ),
        (
            "run",
            "/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_runFWD_A_agg.ME_runFWD_A_agg",
        ),
        (
            "melee",
            "/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_attackMelee_A.ME_attackMelee_A",
        ),
        (
            "death",
            "/Game/BioShockCharacters/AggressorBabyJane/Animations/Death_StumbleFWD.Death_StumbleFWD",
        ),
    ):
        asset = unreal.load_asset(path)
        report.setdefault("assetResolve", {})[name] = asset is not None
        if asset is None:
            failures.append("asset missing: %s (%s)" % (name, path))

    if not ai_cls or not player_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("ai-animation:\n- " + "\n- ".join(failures))

    spawned = []
    ai, player = _setup_engaged_pair(subsystem, ai_cls, player_cls, 800.0)
    spawned.extend([ai, player])
    if not ai or not player:
        failures.append("spawn")
        _write(out, report)
        raise RuntimeError("ai-animation:\n- " + "\n- ".join(failures))

    # Idle / mesh before combat engagement.
    _tick_combat(ai, 0.25)
    mesh_name = _mesh_asset_name(ai)
    idle_anim = _playing_anim(ai)
    report["beforeCombat"] = {"mesh": mesh_name, "anim": idle_anim}
    if expected["mesh"] not in mesh_name:
        failures.append("mesh not AggressorBabyJane: %s" % mesh_name)
    if expected["idle"] not in idle_anim and not any(m in idle_anim for m in expected["move"]):
        failures.append("expected idle/move before combat, got %s" % idle_anim)

    _arm_attack_on_sight(ai, world, attack_cls)
    brain = ai.get_shock_ai_brain()
    if brain:
        brain.initialize_for_ai(ai)

    saw_move_anim = False
    saw_melee_ability = False
    saw_melee_anim = False
    move_anim = ""
    melee_anim = ""

    for _ in range(120):
        _tick_combat(ai, 0.05)
        ability = brain.get_active_ability_name() if brain else unreal.Name("")
        ability_str = str(ability)
        anim = _playing_anim(ai)
        if "MoveTo" in ability_str:
            if any(m in anim for m in expected["move"]):
                saw_move_anim = True
                move_anim = anim
        if "MeleeAttack" in ability_str:
            saw_melee_ability = True
            if expected["melee"] in anim:
                saw_melee_anim = True
                melee_anim = anim
                break

    report["engagement"] = {
        "sawMoveAnim": saw_move_anim,
        "moveAnim": move_anim,
        "sawMeleeAbility": saw_melee_ability,
        "sawMeleeAnim": saw_melee_anim,
        "meleeAnim": melee_anim,
        "finalDist": _dist2d(ai.get_actor_location(), player.get_actor_location()),
        "finalAnim": _playing_anim(ai),
        "finalAbility": str(brain.get_active_ability_name()) if brain else "",
    }
    if not saw_melee_ability:
        failures.append("MeleeAttackAbility never active")
    if not saw_melee_anim:
        failures.append("melee anim not playing during MeleeAttackAbility (got %s)" % melee_anim)

    # Kill the AI — death clip should install and hold (no blend back to idle).
    start_health = float(ai.get_current_health())
    damage_lib.apply_damage(ai, max(start_health + 50.0, 9999.0), player, unreal.Name("VerifyKill"))
    _tick_combat(ai, 0.2)
    death_anim = _playing_anim(ai)
    report["death"] = {
        "wasDead": _flag(ai.is_dead),
        "anim": death_anim,
        "deathNotifyCount": int(ai.get_death_notify_count()),
    }
    if not _flag(ai.is_dead):
        failures.append("AI not dead after lethal damage")
    if expected["death"] not in death_anim:
        failures.append("death anim not playing after kill (got %s)" % death_anim)

    _destroy_spawned(subsystem, spawned)

    error_count = len(failures)
    report["errorCount"] = error_count
    report["ai_animation"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("ai-animation (%d errors):\n- " % error_count + "\n- ".join(failures))
    _log("Success - %d error(s)" % error_count)
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "ai_animation_report.json"),
        )
    )
