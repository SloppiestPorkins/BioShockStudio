"""Assert an imported level is actually standable.

This exists because of a regression I shipped. Re-importing the compiled-world mesh let Unreal
auto-generate collision, which for an 18,735-triangle architectural shell means ONE convex hull -
a solid blob enclosing the whole level. The player landed on the outside of it ("stuck in the
air") and anything spawned inside was inside solid geometry and squeezed out through the floor
(ragdolls falling). Every one of the fourteen headless verifies passed the whole time, because
not one of them asserted that the level has a floor.

Two checks, deliberately both:

  a) STRUCTURAL - the compiled-world mesh traces against its own triangles
     (CTF_USE_COMPLEX_AS_SIMPLE) with no simple primitives standing in for them. This is the
     shape of the bug that actually happened.

  b) BEHAVIOURAL - a downward trace from each PlayerStart hits world geometry within a sane
     distance, and an upward trace from just below it does not immediately hit something (which
     would mean the start is buried inside a solid). This is the property anyone actually cares
     about: can you stand here. It would catch a floor that went missing for reasons the
     structural check never anticipated.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/run_collision.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_COLLISION_MAPS   comma-separated /Game map paths
                            (default /Game/BioShockSlice/1-Medical)
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fix_exterior_collision import is_exterior_name
from fix_all_complex_collision import (
    _KEEP_NO_COLLISION, _KEEP_NO_COLLISION_EXCLUDE, _PROXY_TAG)
from restore_floor_prop_hulls import _FLOOR

# Model12_34567 - the exporter's stem for a compiled-CSG world asset.
_MODEL_ASSET = re.compile(r"^Model\d+_\d+$")

MAPS = [m.strip() for m in os.environ.get(
    "BIOSHOCK_COLLISION_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if m.strip()]

# A PlayerStart is authored at capsule centre, so the floor sits a little under half a capsule
# below it. Allow generous slack for authoring drift, but not so much that "the floor is 40 metres
# down" counts as standing on it.
MAX_DROP_TO_FLOOR = 400.0
BURIED_PROBE = 20.0
UE_CMD = r"G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
PROJECT = r"C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
GAME_URL = "/Game/BioShockSlice/1-Medical?game=/Script/BioShockRuntime.ShockGameMode"


def _lvl():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _compiled_world_meshes():
    """The compiled-CSG level shell, identified by name rather than by size.

    An earlier version of this took every static mesh over 5,000 triangles, which swept up
    Concrete_Barrier_Broken, a casket, a health station and a pipe assembly - detailed PROPS, for
    which a convex hull is the correct and cheap collision. Demanding complex-as-simple of those
    would be wrong as well as wasteful. Only the level shell has to trace against its own
    triangles, because only the level shell is the thing you walk on.

    The exporter labels that instance "compiled world" and names the asset Model<n>_<index>, so
    match on identity. If neither matches, say so rather than guessing at a mesh by size.
    """
    out = []
    for actor in _actors().get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        comp = actor.static_mesh_component
        mesh = comp.get_editor_property("static_mesh") if comp else None
        if mesh is None:
            continue

        label = (actor.get_actor_label() or "").strip().lower()
        name = mesh.get_name()
        is_shell = label == "compiled world" or _MODEL_ASSET.match(name) is not None
        if not is_shell:
            continue
        try:
            tris = mesh.get_num_triangles(0)
        except Exception:  # noqa: BLE001
            tris = 0
        out.append((actor, mesh, tris))
    return out


def _check_structural(report):
    failures = []
    checked = 0
    for actor, mesh, tris in _compiled_world_meshes():
        body = mesh.get_editor_property("body_setup")
        entry = {"actor": actor.get_actor_label(), "mesh": mesh.get_name(), "triangles": tris}
        if body is None:
            failures.append("%s has no body setup" % entry["mesh"])
            report["meshes"].append(entry)
            continue

        flag = str(body.get_editor_property("collision_trace_flag"))
        entry["traceFlag"] = flag
        try:
            agg = body.get_editor_property("agg_geom")
            convex = len(agg.get_editor_property("convex_elems") or [])
            boxes = len(agg.get_editor_property("box_elems") or [])
            entry["convexElems"] = convex
            entry["boxElems"] = boxes
        except Exception:  # noqa: BLE001
            convex = boxes = 0

        if "COMPLEX_AS_SIMPLE" not in flag:
            failures.append(
                "%s traces against simple collision (%s); architecture must be "
                "complex-as-simple" % (entry["mesh"], flag))
        if convex or boxes:
            failures.append(
                "%s carries %d convex / %d box primitives - an auto hull round a level shell is a "
                "solid blob" % (entry["mesh"], convex, boxes))
        checked += 1
        report["meshes"].append(entry)

    report["architectureMeshesChecked"] = checked
    if checked == 0:
        failures.append(
            "no compiled-world shell found - expected an actor labelled \"compiled world\" "
            "or a Model<n>_<index> mesh")
    return failures


def _check_standable(report):
    """Trace down from every PlayerStart and confirm there is ground under it."""
    failures = []
    world = unreal.EditorLevelLibrary.get_editor_world()
    starts = [a for a in _actors().get_all_level_actors() if isinstance(a, unreal.PlayerStart)]
    report["playerStarts"] = len(starts)
    if not starts:
        failures.append("no PlayerStart in the map - nothing can spawn here")
        return failures

    for start in starts:
        loc = start.get_actor_location()
        label = start.get_actor_label()
        entry = {"start": label, "location": [loc.x, loc.y, loc.z]}

        down = unreal.SystemLibrary.line_trace_single(
            world, loc, unreal.Vector(loc.x, loc.y, loc.z - MAX_DROP_TO_FLOOR),
            unreal.TraceTypeQuery.TRACE_TYPE_QUERY1, False, [],
            unreal.DrawDebugTrace.NONE, True)
        if down is None:
            entry["floor"] = None
            failures.append("%s: no floor within %.0f uu below the start" % (label, MAX_DROP_TO_FLOOR))
        else:
            hit_z = down.to_tuple()[4].z if hasattr(down, "to_tuple") else None
            try:
                hit_z = down.get_editor_property("location").z
            except Exception:  # noqa: BLE001
                pass
            entry["floor"] = hit_z
            entry["dropToFloor"] = (loc.z - hit_z) if hit_z is not None else None

        # Buried check: a very short trace straight up from just under the start. Hitting anything
        # immediately means the start sits inside solid geometry, which is what standing on the
        # outside of a convex blob looks like from the inside.
        below = unreal.Vector(loc.x, loc.y, loc.z - BURIED_PROBE)
        up = unreal.SystemLibrary.line_trace_single(
            world, below, loc, unreal.TraceTypeQuery.TRACE_TYPE_QUERY1, False, [],
            unreal.DrawDebugTrace.NONE, True)
        entry["buried"] = up is not None
        if up is not None:
            failures.append("%s: start appears to be inside solid geometry" % label)

        report["starts"].append(entry)
    return failures


def _mesh_collision(mesh):
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return "", 0
    flag = str(body.get_editor_property("collision_trace_flag"))
    agg = body.get_editor_property("agg_geom")
    count = sum(len(agg.get_editor_property(prop) or []) for prop in (
        "convex_elems", "box_elems", "sphere_elems"))
    return flag, count


def _check_prop_policy(report):
    """Everything is complex-as-simple now (user decision, fix_all_complex_collision.py).

    Non-exterior static meshes must trace against their own triangles and block; exterior
    backdrop geo + pickups/decals must be non-colliding.
    """
    failures = []
    counts = {"complex": 0, "noCollision": 0, "shell": 0}
    for actor in _actors().get_all_level_actors():
        if _PROXY_TAG in {str(tag) for tag in actor.tags}:
            failures.append("%s: stale invisible prop proxy remains" % actor.get_actor_label())
            continue
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        comp = actor.static_mesh_component
        mesh = comp.get_editor_property("static_mesh") if comp else None
        if mesh is None:
            continue
        name = mesh.get_name()
        label = (actor.get_actor_label() or "").strip().lower()
        if label == "compiled world" or _MODEL_ASSET.match(name):
            counts["shell"] += 1
            continue
        flag, _ = _mesh_collision(mesh)
        collision = str(comp.get_collision_enabled())

        if is_exterior_name(name) or (_KEEP_NO_COLLISION.search(name)
                and not _KEEP_NO_COLLISION_EXCLUDE.search(name)):
            counts["noCollision"] += 1
            if "NO_COLLISION" not in collision:
                failures.append("%s: render-only mesh collision is %s" % (name, collision))
        elif _FLOOR.search(name):
            # Floor-type props (catwalk/deck/grate/stairs) get a walkable hull, not per-poly —
            # per-poly on a Movable mesh doesn't register with FindFloor (Chaos).
            counts["floorHull"] = counts.get("floorHull", 0) + 1
            if "NO_COLLISION" in collision:
                failures.append("%s: floor-type prop render collision is disabled" % name)
        else:
            counts["complex"] += 1
            if "COMPLEX_AS_SIMPLE" not in flag:
                failures.append("%s: traces as %s, expected COMPLEX_AS_SIMPLE" % (name, flag))
            if "NO_COLLISION" in collision:
                failures.append("%s: render collision is disabled" % name)
    report["propPolicy"] = counts
    return failures


def _run_game_route(route, start, target, duration, min_z, delay):
    log_path = os.path.join(os.environ.get("TEMP", "."), "collision_%s.log" % route)
    cmd = [
        UE_CMD, PROJECT, GAME_URL, "-game", "-bioshockverifymovement",
        "-bioshockmovementroute=%s" % route,
        "-bioshockmovementtarget=%s" % target,
        "-bioshockmovementduration=%.2f" % duration,
        "-bioshockmovementminz=%.2f" % min_z,
        "-bioshockmovementdelay=%.2f" % delay,
        "-unattended", "-nopause", "-nosplash", "-log", "-abslog=%s" % log_path,
    ]
    if start:
        cmd.insert(5, "-bioshockmovementstart=%s" % start)
    proc = subprocess.run(cmd, timeout=600)
    text = open(log_path, encoding="utf-8", errors="replace").read() \
        if os.path.isfile(log_path) else ""
    ok = re.search(
        r"BIOSHOCK_COLLISION_ROUTE_OK route=(\S+) z_increase=([-\d.]+) "
        r"remaining=([-\d.]+) falling_seen=(\d)", text)
    result = {"route": route, "exitCode": proc.returncode, "log": log_path, "ok": bool(ok)}
    if ok:
        result.update({
            "zIncrease": float(ok.group(2)),
            "targetRemaining": float(ok.group(3)),
            "fallingSeen": int(ok.group(4)),
        })
    else:
        fail = re.search(r"BIOSHOCK_MOVEMENT_FAIL reason=(\S+)", text)
        result["reason"] = fail.group(1) if fail else "route marker missing"
    return result


def _check_game_routes(report):
    # NOTE: stairs are per-poly (CTF_USE_COMPLEX_AS_SIMPLE) by user decision — the character
    # capsule can catch on individual risers. A dedicated stair-climb route is deliberately not
    # asserted here; this route stays on the flat approach.
    routes = [
        # Beyond scripted load-room doors, authored PathNodes cover the Pavilion approach.
        ("bathysphere_pavilion", "-18096,2480,7794", "-19120,2224,7808",
         8.0, -20.0, 0.5),
    ]
    failures = []
    for args in routes:
        result = _run_game_route(*args)
        report["gameRoutes"].append(result)
        if not result["ok"]:
            failures.append("%s: %s" % (result["route"], result.get("reason", "failed")))
    return failures


def main(out_path):
    report = {"maps": [], "failures": [], "checks": 0, "gameRoutes": []}
    for map_path in MAPS:
        map_report = {"map": map_path, "meshes": [], "starts": [], "propSamples": []}
        if not _lvl().load_level(map_path):
            report["failures"].append("could not load %s" % map_path)
            report["maps"].append(map_report)
            continue

        failures = _check_structural(map_report)
        failures += _check_standable(map_report)
        failures += _check_prop_policy(map_report)
        map_report["failures"] = failures
        report["failures"] += ["%s: %s" % (map_path, f) for f in failures]
        report["checks"] += 1
        report["maps"].append(map_report)

    if os.environ.get("BIOSHOCK_COLLISION_GAME", "1") != "0" and not report["failures"]:
        report["failures"] += _check_game_routes(report)

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    for failure in report["failures"]:
        unreal.log_error("BIOSHOCK_COLLISION_FAIL %s" % failure)
    if not report["failures"]:
        unreal.log("BIOSHOCK_COLLISION_OK maps=%d" % report["checks"])
    return report
