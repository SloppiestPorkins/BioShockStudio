"""Verify /Game/BioShockSlice/TestArena after hostility + mesh fixes.

Loads the saved map (does NOT spawn fresh ABaseShockAI) and asserts:
  - Enemy_Melee / Enemy_Ranged_A / Enemy_Ranged_B exist
  - bHostileToAnyPlayer is set on each
  - EnsureCombatMeshAndAnims path assigns AggressorBabyJane on level-loaded actors
  - mesh upright delta (head.Z - feet.Z) is positive (Identity RelRotation)
  - a nearby ShockPlayer is acquired and combat advances without AttackOnSightLabels

Report: %TEMP%/bioshock_test_arena_verify_report.json
"""

from __future__ import annotations

import json
import math
import os

import unreal

ARENA_MAP = "/Game/BioShockSlice/TestArena"
ENEMY_LABELS = ("Enemy_Melee", "Enemy_Ranged_A", "Enemy_Ranged_B")
REPORT = os.path.join(
    os.environ.get("TEMP", "."), "bioshock_test_arena_verify_report.json"
)


def _log(message):
    unreal.log("[bioshock-test-arena-verify] %s" % message)


def _dist2d(a, b):
    dx = float(a.x - b.x)
    dy = float(a.y - b.y)
    return math.sqrt(dx * dx + dy * dy)


def _actors_by_label(subsystem):
    out = {}
    for actor in subsystem.get_all_level_actors():
        out[actor.get_actor_label()] = actor
    return out


def _mesh_name(ai):
    mesh = ai.mesh if ai else None
    if not mesh:
        return ""
    asset = mesh.get_editor_property("skeletal_mesh_asset")
    return str(asset.get_name()) if asset else ""


def _rel_rot(ai):
    mesh = ai.mesh if ai else None
    if not mesh:
        return None
    rot = mesh.get_editor_property("relative_rotation")
    return {
        "pitch": float(rot.pitch),
        "yaw": float(rot.yaw),
        "roll": float(rot.roll),
    }


def main(out):
    report = {"failures": [], "enemies": [], "map": ARENA_MAP}
    failures = report["failures"]

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not unreal.EditorAssetLibrary.does_asset_exist(ARENA_MAP):
        failures.append("map missing: %s" % ARENA_MAP)
        _write(out, report)
        raise RuntimeError("test-arena-verify:\n- " + "\n- ".join(failures))

    if not level.load_level(ARENA_MAP):
        failures.append("could not load %s" % ARENA_MAP)
        _write(out, report)
        raise RuntimeError("test-arena-verify:\n- " + "\n- ".join(failures))

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    by_label = _actors_by_label(subsystem)

    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not player_cls:
        failures.append("ShockPlayer class missing")
        _write(out, report)
        raise RuntimeError("test-arena-verify:\n- " + "\n- ".join(failures))

    # Place a verify player in front of Enemy_Melee — headless has no GameMode pawn.
    # Intentionally do NOT call add_target_to_attack_on_sight: that is the bug under test.
    melee = by_label.get("Enemy_Melee")
    player_loc = unreal.Vector(800.0, 0.0, 100.0)
    if melee:
        mloc = melee.get_actor_location()
        # Enemy_Melee faces yaw 180 (-X); stand on that side inside the sight cone.
        player_loc = unreal.Vector(float(mloc.x) - 400.0, float(mloc.y), 100.0)
    player = subsystem.spawn_actor_from_class(
        player_cls, player_loc, unreal.Rotator(0.0, 0.0, 0.0)
    )
    if player:
        player.set_actor_label("ArenaVerifyPlayer")
        player.ensure_health_initialized()
    else:
        failures.append("verify player spawn failed")

    for label in ENEMY_LABELS:
        entry = {"label": label}
        ai = by_label.get(label)
        if not ai:
            failures.append("missing enemy %s" % label)
            entry["present"] = False
            report["enemies"].append(entry)
            continue
        entry["present"] = True
        entry["class"] = ai.get_class().get_name()

        try:
            hostile = bool(ai.get_editor_property("bHostileToAnyPlayer"))
        except Exception:
            try:
                hostile = bool(ai.get_editor_property("b_hostile_to_any_player"))
            except Exception as exc:
                hostile = False
                failures.append("%s hostile property unreadable: %s" % (label, exc))
        entry["bHostileToAnyPlayer"] = hostile
        if not hostile:
            failures.append("%s bHostileToAnyPlayer is false" % label)

        # Drive the same Tick path PIE uses (not a fresh spawn_actor mesh assign).
        ai.ensure_controller_for_verify()
        for _ in range(10):
            ai.advance_autonomous_combat(0.05)

        mesh_name = _mesh_name(ai)
        entry["mesh"] = mesh_name
        entry["relRot"] = _rel_rot(ai)
        if "AggressorBabyJane" not in mesh_name:
            failures.append("%s mesh not AggressorBabyJane: %s" % (label, mesh_name))

        upright = float(ai.get_mesh_upright_delta_for_verify())
        entry["uprightDelta"] = upright
        if upright < 50.0:
            failures.append(
                "%s mesh not upright (headZ-feetZ=%.1f); if largely negative the "
                "import is inverted — do not paper over with a guessed pitch/roll"
                % (label, upright)
            )

        if player and label == "Enemy_Melee":
            start = ai.get_actor_location()
            for _ in range(100):
                ai.advance_autonomous_combat(0.05)
            end = ai.get_actor_location()
            moved = _dist2d(start, end)
            entry["moved"] = moved
            # GetCombatTargetPawn() isn't UFUNCTION-exposed to Python; the brain's active
            # goal is (proven in verify_ai_brain.py) and KillTarget means a target was
            # acquired and engagement is underway.
            brain = ai.get_shock_ai_brain()
            has_target = bool(
                brain and brain.get_active_goal_type() == unreal.ShockAIGoalType.KILL_TARGET
            )
            entry["hasTarget"] = has_target
            if not has_target and moved < 20.0:
                failures.append(
                    "%s did not acquire/engage verify player "
                    "(moved=%.1f, hostile=%s) — level-loaded path may diverge from fresh spawn"
                    % (label, moved, hostile)
                )
            else:
                entry["engaged"] = True

        report["enemies"].append(entry)

    if player:
        subsystem.destroy_actor(player)

    report["errorCount"] = len(failures)
    report["test_arena_verify"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError(
            "test-arena-verify (%d errors):\n- " % len(failures)
            + "\n- ".join(failures)
        )
    _log("Success - level-loaded arena enemies mesh+hostile+engage ok")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", REPORT))
