"""Run every post-import repair on a batch of freshly imported story maps, in one editor session.

`import_all_levels` produces geometry + materials but leaves three things wrong that each have
their own single-purpose script:

  1. compiled-world collision  -> fix_compiled_world_collision (CTF_USE_COMPLEX_AS_SIMPLE, clear hulls)
  2. lighting reach/exposure   -> repair_level_lighting (falloff exponent 2, cold ambient, PPV)
  3. PlayerStart placement     -> repair_player_starts (promote + snap strays onto a path node)

Running them one map at a time through three separate commandlets is ~3 editor boots per map.
This drives all three per map in a single boot.

Run headless (editor CLOSED):
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_imported_levels.py \
    -unattended -nopause -nosplash

Env:
  BIOSHOCK_REPAIR_MAPS   comma-separated /Game map paths
                         (default: every /Game/BioShockLevel/* map that exists)
  BIOSHOCK_REPAIR_OUT    report JSON (default %TEMP%/repair_imported_levels.json)

Pipeline: entry-point -- the batch driver that runs the post-import repairs on the other 20
story maps; a top-level entry point itself, not a step of the 1-Medical slice rebuild.
"""

from __future__ import annotations

import json
import os
import sys
import traceback

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

_STORY_MAPS = [
    "0-Lighthouse", "1-Medical", "1-Welcome", "2-Fisheries", "2-SubBay", "3-Arcadia",
    "3-Market", "4-Recreation", "5-Hephaestus", "5-Ryan", "6-Resi", "6-Slums",
    "7-BossFight", "7-Gauntlet", "7-Science",
]

OUT = os.environ.get(
    "BIOSHOCK_REPAIR_OUT",
    os.path.join(os.environ.get("TEMP", "."), "repair_imported_levels.json"),
)


def _log(msg):
    unreal.log("[repair-imported-levels] %s" % msg)


def _maps():
    raw = os.environ.get("BIOSHOCK_REPAIR_MAPS", "").strip()
    if raw:
        return [m.strip() for m in raw.split(",") if m.strip()]
    out = []
    for name in _STORY_MAPS:
        path = "/Game/BioShockLevel/%s" % name
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            out.append(path)
    return out


def _write(report):
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _run_step(name, fn, map_path):
    try:
        return {"step": name, "ok": True, "result": fn(map_path)}
    except Exception as exc:  # noqa: BLE001
        return {"step": name, "ok": False, "error": str(exc),
                "traceback": traceback.format_exc()}


def main():
    import fix_compiled_world_collision as cwc
    import repair_level_lighting as rll
    import repair_player_starts as rps

    report = {"maps": []}
    for map_path in _maps():
        _log("repairing %s" % map_path)
        entry = {"map": map_path, "steps": []}

        # 1. collision — sets the flag + clears hulls + saves the mesh asset and the level.
        cwc.MAPS = [map_path]
        entry["steps"].append(_run_step("collision", lambda _m: _collision_one(cwc, _m), map_path))

        # 2. lighting — _repair_one loads, rescales, and saves the map.
        entry["steps"].append(_run_step("lighting", rll._repair_one, map_path))

        # 3. player starts — promote placeholders, snap strays onto the nearest walkable node.
        entry["steps"].append(_run_step("playerStarts", rps._repair_map, map_path))

        report["maps"].append(entry)
        _write(report)

    _log(json.dumps(report))
    failed = [
        "%s/%s" % (m["map"], s["step"])
        for m in report["maps"] for s in m["steps"] if not s["ok"]
    ]
    if failed:
        raise RuntimeError("repair steps failed: %s" % ", ".join(failed))
    return report


def _collision_one(cwc, map_path):
    """fix_compiled_world_collision has no per-map entry point — inline its loop body."""
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors_sys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    if not lvl.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)
    fixed = []
    for actor in actors_sys.get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        comp = actor.static_mesh_component
        mesh = comp.get_editor_property("static_mesh") if comp else None
        if mesh is None:
            continue
        label = (actor.get_actor_label() or "").strip().lower()
        name = mesh.get_name()
        if label != "compiled world" and not cwc._MODEL_ASSET.match(name):
            continue
        ok = cwc._use_complex_collision(mesh)
        restored = cwc._ensure_static_mobility(comp)
        if ok:
            unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        fixed.append({"actor": actor.get_actor_label(), "mesh": name,
                      "ok": ok, "restoredStatic": restored})
    lvl.save_current_level()
    return {"fixed": fixed}


try:
    main()
except Exception:  # noqa: BLE001 -- commandlet must still surface the traceback
    traceback.print_exc()
    raise
