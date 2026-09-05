"""Strip collision from cosmetic decal static meshes (Wall_Leak, blood smears, scorch,
damdec, drips, etc.) that the OBJ importer gave an auto convex hull — thin overlays the
player was never meant to walk into.

Identification is NOT `outputBlending in (1,2)`: Wall_Leak_diff_shader and
reinforcedglass_diffuse_shader both carry outputBlending 1, and real glass panels must
keep collision. Offline measurement on the Medical export OBJs (5 Sept 2026, see
tools/ue5/README.md) showed:

  * known decals (Wall_Leak_*, bloodsmear, BloodSplat*, damdec_*, ScorchMark, Drips*):
    thinness (min/max local AABB extent) p50 = 0.0, max = 0.171 (volumetric Drips*)
  * known glass / window panes: thinness also 0.0..0.019 — thinness alone cannot
    separate decals from glass
  * puddles: similarly flat (0.0..0.015) and explicitly excluded — keep current collision
  * baseline props: thinness p50 ≈ 0.31

So the rule mirrors fix_walkable_prop_collision.py: mesh-name keywords + exclude list +
a thinness safety ceiling (0.20 catches every measured Medical decal, including Drips*).

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_decal_collision.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_DECAL_MAPS       comma-separated /Game map paths (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_DECAL_DRY        "1" to report candidates without changing anything
  BIOSHOCK_DECAL_MAX_THIN   max min/max local AABB ratio (default 0.20)
"""
from __future__ import annotations

import json
import os
import re
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

MAPS = [
    m.strip()
    for m in os.environ.get("BIOSHOCK_DECAL_MAPS", "/Game/BioShockSlice/1-Medical").split(",")
    if m.strip()
]
DRY = os.environ.get("BIOSHOCK_DECAL_DRY", "0") == "1"
MAX_THIN = float(os.environ.get("BIOSHOCK_DECAL_MAX_THIN", "0.20"))
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_decal_collision.json")

# Substring, case-insensitive — same looseness as fix_walkable_prop_collision.py. False
# positives are caught by _EXCLUDE_SUBSTR and the thinness ceiling, not by tightening
# the regex (compound names like Wall_Leak_1024 / bloodsmear / BloodSplat3 have no
# reliable word boundaries).
_KEYWORDS = re.compile(
    r"(wall_leak|bloodsmear|blood.?splat|bloodsplat|damdec|scorch|"
    r"drip|decal|smear|splat|footprint)",
    re.IGNORECASE,
)
# Real transparent architecture and floor water the player may interact with. Extend
# this list rather than narrowing keywords if another false positive turns up.
_EXCLUDE_SUBSTR = ("glass", "window", "puddle", "water")


def _matches_name(name: str) -> bool:
    if not _KEYWORDS.search(name):
        return False
    lname = name.lower()
    return not any(bad in lname for bad in _EXCLUDE_SUBSTR)


def _mesh_thinness(mesh) -> float:
    """min_extent / max_extent from the mesh's local BoxSphereBounds (full extents)."""
    try:
        bounds = mesh.get_bounds()
        extent = bounds.box_extent
    except Exception:  # noqa: BLE001
        return 1.0
    dims = sorted([abs(float(extent.x)) * 2.0, abs(float(extent.y)) * 2.0, abs(float(extent.z)) * 2.0])
    if dims[2] < 1e-6:
        return 0.0
    return dims[0] / dims[2]


def _mesh_extents(mesh):
    try:
        bounds = mesh.get_bounds()
        extent = bounds.box_extent
    except Exception:  # noqa: BLE001
        return [0.0, 0.0, 0.0]
    return sorted(
        [abs(float(extent.x)) * 2.0, abs(float(extent.y)) * 2.0, abs(float(extent.z)) * 2.0]
    )


def _set_mesh_no_collision(mesh) -> bool:
    """Persist NoCollision on the StaticMesh asset's BodySetup (all instances inherit)."""
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False
    try:
        default = body.get_editor_property("default_instance")
        default.set_editor_property("collision_enabled", unreal.CollisionEnabled.NO_COLLISION)
        try:
            default.set_editor_property("collision_profile_name", "NoCollision")
        except Exception:  # noqa: BLE001
            pass
        body.set_editor_property("default_instance", default)
    except Exception as exc:  # noqa: BLE001
        unreal.log_warning("[decal-collision-fix] default_instance: %s" % exc)
        return False
    try:
        agg = body.get_editor_property("agg_geom")
        agg.set_editor_property("convex_elems", [])
        agg.set_editor_property("box_elems", [])
        agg.set_editor_property("sphere_elems", [])
        body.set_editor_property("agg_geom", agg)
    except Exception as exc:  # noqa: BLE001
        unreal.log_warning("[decal-collision-fix] clear agg_geom: %s" % exc)
    # Also disable on the mesh object if the API is present (UE version variance).
    try:
        mesh.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
    except Exception:  # noqa: BLE001
        pass
    return True


def _set_component_no_collision(comp) -> None:
    if comp is None:
        return
    try:
        comp.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
    except Exception:  # noqa: BLE001
        pass
    try:
        comp.set_collision_profile_name("NoCollision")
    except Exception:  # noqa: BLE001
        pass


def main():
    report = {
        "maps": [],
        "maxThinness": MAX_THIN,
        "dryRun": DRY,
        "keywords": _KEYWORDS.pattern,
        "exclude": list(_EXCLUDE_SUBSTR),
    }
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors_sys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

    for map_path in MAPS:
        entry = {
            "map": map_path,
            "candidates": [],
            "fixed": [],
            "skippedThick": [],
            "skippedExclude": [],
            "meshReuse": {},
        }
        if not lvl.load_level(map_path):
            entry["error"] = "could not load"
            report["maps"].append(entry)
            continue

        # First pass: count actors per mesh name (reuse pattern evidence).
        mesh_actors = {}
        for actor in actors_sys.get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            mesh_actors.setdefault(name, []).append(actor)

        seen_meshes = set()
        for name, actors in sorted(mesh_actors.items()):
            if not _KEYWORDS.search(name):
                continue
            lname = name.lower()
            if any(bad in lname for bad in _EXCLUDE_SUBSTR):
                entry["skippedExclude"].append(
                    {"mesh": name, "actors": len(actors), "reason": "exclude_substr"}
                )
                continue

            mesh = actors[0].static_mesh_component.get_editor_property("static_mesh")
            thinness = _mesh_thinness(mesh)
            extents = _mesh_extents(mesh)
            item = {
                "mesh": name,
                "actors": len(actors),
                "thinness": thinness,
                "extents": [round(e, 4) for e in extents],
                "sampleActors": [a.get_actor_label() for a in actors[:5]],
            }
            entry["meshReuse"][name] = len(actors)

            if thinness > MAX_THIN:
                item["status"] = "skipped_too_thick"
                entry["skippedThick"].append(item)
                continue

            entry["candidates"].append(item)
            if name in seen_meshes:
                item["status"] = "already_done_this_run" if not DRY else "would_fix_dup"
                continue
            seen_meshes.add(name)

            if DRY:
                item["status"] = "would_fix"
                continue

            ok = _set_mesh_no_collision(mesh)
            for actor in actors:
                _set_component_no_collision(actor.static_mesh_component)
            saved = False
            if ok:
                saved = bool(unreal.EditorAssetLibrary.save_loaded_asset(mesh))
            item["status"] = "fixed"
            item["ok"] = ok
            item["saved"] = saved
            if not saved:
                item["status"] = "fixed_unsaved"
                unreal.log_warning(
                    "[decal-collision-fix] mesh %s changed but save failed "
                    "(is the editor locking the asset?)" % name
                )
            entry["fixed"].append(item)

        if not DRY and entry["fixed"]:
            lvl.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, default=str)
    unreal.log("[decal-collision-fix] wrote " + OUT)
    return report


if __name__ == "__main__":
    main()
