"""Headless verify: ABaseShockAI Chase uses nav path-following when data exists, else direct input."""

import json
import math
import os
import time

import unreal


def _log(message):
    unreal.log("[bioshock-ai-nav] %s" % message)


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


def _load_cube_mesh():
    return unreal.load_asset("/Engine/BasicShapes/Cube.Cube")


def _spawn_box(subsystem, label, loc, scale, cube_mesh):
    actor = _spawn(subsystem, unreal.StaticMeshActor, label, loc)
    if not actor:
        return None
    mesh = actor.static_mesh_component
    mesh.set_static_mesh(cube_mesh)
    mesh.set_mobility(unreal.ComponentMobility.MOVABLE)
    mesh.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
    actor.set_actor_scale3d(scale)
    return actor


def _build_nav(world):
    if not unreal.ShockGameMode.build_navigation_for_verify(world):
        return False
    for _ in range(80):
        if not unreal.NavigationSystemV1.is_navigation_being_built(world):
            break
        time.sleep(0.05)
    return True


def _nav_data_ready(world):
    return bool(unreal.ShockGameMode.can_project_point_to_navigation(world, unreal.Vector(0.0, 0.0, 100.0)))


def _tick_chase(ai, seconds, step=0.05):
    path_len = 0.0
    prev = ai.get_actor_location()
    steps = int(seconds / step)
    for _ in range(steps):
        ai.advance_autonomous_combat(step)
        cur = ai.get_actor_location()
        path_len += _dist2d(prev, cur)
        prev = cur
    return path_len, prev


def _destroy_spawned(subsystem, actors):
    for actor in actors:
        if actor:
            subsystem.destroy_actor(actor)


def _run_fallback_chase(subsystem, ai_cls, player_cls):
    """Same geometry as verify_ai_combat engage — no floor/wall so direct input can close."""
    spawned = []
    ai = _spawn(subsystem, ai_cls, "FallbackAI", unreal.Vector(0.0, 0.0, 100.0))
    player = _spawn(subsystem, player_cls, "FallbackTarget", unreal.Vector(800.0, 0.0, 100.0))
    spawned.extend([ai, player])
    if not ai or not player:
        return spawned, {"error": "spawn"}
    ai.configure_identity("Agg_BabyJane", "FallbackAI")
    ai.ensure_health_initialized()
    player.ensure_health_initialized()
    ai.scripted_attack_target(player)
    start_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
    path_len, _ = _tick_chase(ai, 5.0)
    end_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
    return spawned, {
        "startDist": start_dist,
        "endDist": end_dist,
        "pathLen": path_len,
        "fallback": bool(ai.is_nav_using_fallback()),
    }


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    cube_mesh = _load_cube_mesh()
    if not ai_cls or not player_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("ai-nav:\n- " + "\n- ".join(failures))

    spawned, fb = _run_fallback_chase(subsystem, ai_cls, player_cls)
    report["fallbackChase"] = fb
    if fb.get("error"):
        failures.append("fallback spawn")
    else:
        if not fb["fallback"]:
            failures.append("nav unavailable but BIOSHOCK_NAV_FALLBACK not taken")
        if fb["endDist"] >= fb["startDist"] - 100.0:
            failures.append(
                "fallback did not close distance %.1f -> %.1f" % (fb["startDist"], fb["endDist"])
            )
        _log("BIOSHOCK_NAV_FALLBACK")
    _destroy_spawned(subsystem, spawned)

    nav_ready = False
    if cube_mesh:
        nav_spawned = []
        floor = _spawn_box(
            subsystem,
            "NavFloor",
            unreal.Vector(0.0, 0.0, 0.0),
            unreal.Vector(60.0, 60.0, 0.5),
            cube_mesh,
        )
        wall = _spawn_box(
            subsystem,
            "NavWall",
            unreal.Vector(0.0, 0.0, 120.0),
            unreal.Vector(2.0, 18.0, 6.0),
            cube_mesh,
        )
        nav_bounds = _spawn(
            subsystem,
            unreal.NavMeshBoundsVolume,
            "NavBounds",
            unreal.Vector(0.0, 0.0, 100.0),
        )
        nav_spawned.extend([floor, wall])
        if nav_bounds:
            nav_bounds.set_actor_scale3d(unreal.Vector(30.0, 30.0, 15.0))
            nav_spawned.append(nav_bounds)
        built = _build_nav(world)
        nav_ready = built and _nav_data_ready(world)
        report["navReady"] = nav_ready
        if nav_ready:
            ai = _spawn(
                subsystem,
                ai_cls,
                "NavAI",
                unreal.Vector(-1200.0, 0.0, 100.0),
            )
            player = _spawn(
                subsystem,
                player_cls,
                "NavTarget",
                unreal.Vector(1200.0, 0.0, 100.0),
                unreal.Rotator(0.0, 180.0, 0.0),
            )
            nav_spawned.extend([ai, player])
            if not ai or not player:
                failures.append("nav chase spawn")
            else:
                ai.configure_identity("Agg_BabyJane", "NavAI")
                ai.ensure_health_initialized()
                ai.ensure_controller_for_verify()
                player.ensure_health_initialized()
                ai.scripted_attack_target(player)
                start_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
                straight = start_dist
                path_len, _ = _tick_chase(ai, 6.0)
                end_dist = _dist2d(ai.get_actor_location(), player.get_actor_location())
                report["navChase"] = {
                    "startDist": start_dist,
                    "endDist": end_dist,
                    "straight": straight,
                    "pathLen": path_len,
                    "navActive": bool(ai.is_nav_chase_active()),
                    "fallback": bool(ai.is_nav_using_fallback()),
                }
                if ai.is_nav_using_fallback():
                    failures.append("nav ready but fell back during walled chase")
                if path_len <= straight * 1.02:
                    failures.append(
                        "nav path %.1f not longer than straight %.1f" % (path_len, straight)
                    )
                if end_dist >= start_dist - 150.0:
                    failures.append(
                        "nav did not close distance %.1f -> %.1f" % (start_dist, end_dist)
                    )
        _destroy_spawned(subsystem, nav_spawned)
    else:
        report["navReady"] = False

    report["ai_nav"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("ai-nav:\n- " + "\n- ".join(failures))
    _log("PASS ai-nav")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "ai_nav_report.json"),
        )
    )
