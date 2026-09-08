"""Force CTF_USE_COMPLEX_AS_SIMPLE (per-poly) collision on EVERY static mesh in the slice.

User decision (8 Sept 2026): "use complex collision as simple for EVERYTHING now. i can work
out performance later." This overrides fix_prop_collision.py's per-class policy — every prop,
every architectural piece, every decorative mesh traces against its own triangles.

Kept as-is:
  * exterior / backdrop geometry (fix_exterior_collision's set) stays NO_COLLISION — "outside
    geo shouldn't have collision" still stands;
  * pickups / flat surface FX (puddles, splats, carpets, decals), god-ray light beams and
    liquid-FX surfaces stay NO_COLLISION;
  * the compiled-world shell already traces complex-as-simple.

Stairs are included in the pass (per user, 8 Sept 2026) — per-poly like everything else, no
special hull path.

Everything else: mesh asset trace flag -> COMPLEX_AS_SIMPLE, simple hull primitives cleared,
render component -> QUERY_AND_PHYSICS / BlockAll. Mobility is left alone (Movable is fine for
query/sweep collision; the h11 "Static required" caveat is only the giant world shell + physics
simulation).

Env:
  BIOSHOCK_COMPLEX_MAPS  comma-separated maps (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_COMPLEX_DRY   "1" to report without changing anything
"""
from __future__ import annotations

import json
import os
import re
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fix_exterior_collision import is_exterior_name

MAPS = [v.strip() for v in os.environ.get(
    "BIOSHOCK_COMPLEX_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if v.strip()]
DRY = os.environ.get("BIOSHOCK_COMPLEX_DRY", "0") == "1"
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_all_complex_collision.json")

_MODEL_ASSET = re.compile(r"^Model\d+_\d+$")
# Cosmetic overlays / effects that must never block the player, weapons or AI.
_KEEP_NO_COLLISION = re.compile(
    r"(?:^|_)(?:ammo|pickup|hypo|firstaid|medkit)(?:_|$)"
    r"|puddle|bloodsplat|bloodsmear|carpet|decal|drip"
    r"|wall_leak|damdec|scorchmark|scorch_mark|(?:^|_)gore|_stain"
    # god rays / light shafts — additive translucent meshes
    r"|light_?beams?|godray|god_ray|sunbeam|light_?shaft|walltechanim_shaftb|_corona|lensflare"
    # water / liquid FX surfaces
    r"|cascade_?\d|waterspew|stairwater|fx_stairwater|oil_?slick|glassdust|caustic"
    # flat advertising billboards
    r"|_ad(?:_|$)|_advert",
    re.IGNORECASE,
)
# ...but these carry a beam/shaft substring and ARE solid props — keep their collision.
_KEEP_NO_COLLISION_EXCLUDE = re.compile(
    r"ibeam|i_beam|chainpulley|blockibeam|steelbeam|beam512|beam_512", re.IGNORECASE)
_PROXY_TAG = "BioShockPropCollisionProxy"


def _set_complex(mesh):
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False
    body.set_editor_property(
        "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
    try:
        agg = body.get_editor_property("agg_geom")
        agg.set_editor_property("convex_elems", [])
        agg.set_editor_property("box_elems", [])
        agg.set_editor_property("sphere_elems", [])
        body.set_editor_property("agg_geom", agg)
    except Exception as exc:  # noqa: BLE001
        unreal.log_warning("[all-complex] could not clear simple collision on %s: %s"
                           % (mesh.get_name(), exc))
    return True


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    report = {"dryRun": DRY, "maps": []}

    for map_path in MAPS:
        entry = {"map": map_path, "meshesForced": 0, "actorsEnabled": 0,
                 "keptNoCollision": 0, "skippedShell": 0, "proxiesDestroyed": 0}
        if not level.load_level(map_path):
            entry["error"] = "could not load"
            report["maps"].append(entry)
            continue

        done_meshes = set()
        for actor in list(actors.get_all_level_actors()):
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            if _PROXY_TAG in {str(t) for t in actor.tags}:
                if not DRY:
                    actors.destroy_actor(actor)
                entry["proxiesDestroyed"] += 1
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            label = (actor.get_actor_label() or "").strip().lower()
            if label == "compiled world" or _MODEL_ASSET.match(name):
                entry["skippedShell"] += 1
                continue
            if is_exterior_name(name) or (
                    _KEEP_NO_COLLISION.search(name)
                    and not _KEEP_NO_COLLISION_EXCLUDE.search(name)):
                entry["keptNoCollision"] += 1
                if not DRY and "NO_COLLISION" not in str(comp.get_collision_enabled()):
                    actor.modify()
                    comp.modify()
                    comp.set_collision_profile_name("NoCollision")
                    comp.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
                continue

            if not DRY:
                if name not in done_meshes:
                    if _set_complex(mesh):
                        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                        entry["meshesForced"] += 1
                    done_meshes.add(name)
                if "NO_COLLISION" in str(comp.get_collision_enabled()) \
                        or "QUERY_AND_PHYSICS" not in str(comp.get_collision_enabled()):
                    actor.modify()
                    comp.modify()
                    comp.set_collision_profile_name("BlockAll")
                    comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
                entry["actorsEnabled"] += 1
            else:
                entry["meshesForced"] += 1

        if not DRY:
            level.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[all-complex] %s" % json.dumps(report))
    return report


if __name__ == "__main__":
    main()
