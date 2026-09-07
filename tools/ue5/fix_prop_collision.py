"""Apply the playable-slice collision policy without changing movable-prop mobility.

Policy:
* exterior/backdrop and pickup meshes: component NoCollision;
* known concave/hollow props and walk-through architecture: invisible Static
  complex-as-simple collision proxies beside their Movable render actors;
* tiny/low-detail or semantically simple props: retain their cheap simple hull;
* remaining props: retain simple collision until a geometric classifier exists.

Env:
  BIOSHOCK_PROP_MAPS        comma-separated maps (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_PROP_DRY         "1" to classify only
  BIOSHOCK_PROP_MIN_SIZE    simple-prop cutoff in uu (default 80)
"""
from __future__ import annotations

import json
import os
import re
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fix_compiled_world_collision import _use_complex_collision
from fix_exterior_collision import is_exterior_name

MAPS = [value.strip() for value in os.environ.get(
    "BIOSHOCK_PROP_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if value.strip()]
DRY = os.environ.get("BIOSHOCK_PROP_DRY", "0") == "1"
MIN_SIZE = float(os.environ.get("BIOSHOCK_PROP_MIN_SIZE", "80"))
ONLY = os.environ.get("BIOSHOCK_PROP_ONLY", "").strip().lower()
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_prop_collision.json")

_PICKUP = re.compile(r"(?:^|_)(?:ammo|pickup|hypo|firstaid|medkit)(?:_|$)", re.IGNORECASE)
_SURFACE = re.compile(r"(puddle|bloodsplat|carpet|decal|drip)", re.IGNORECASE)
_ARCHITECTURE = re.compile(
    r"(tunnel|corridor|stairs?|doorway|hallway|loadroom|ramp|walkway|catwalk|bridge|"
    r"platform|passage|archway|concretewall.*hole)",
    re.IGNORECASE,
)
_DETAILED = re.compile(
    r"(cabinet|shelv|couch|sink|pipe|fridge|casket|wall.*hole|tile.*pile|debrispile)",
    re.IGNORECASE,
)
_SIMPLE = re.compile(
    r"(bottle|can(?:_|$)|cup|plate|tile|brick|book|ashtray|coin|shell|bullet|"
    r"cigarette|plank|board|paper|debris_small)",
    re.IGNORECASE,
)
_MODEL_ASSET = re.compile(r"^Model\d+_\d+$")
_PROXY_TAG = "BioShockPropCollisionProxy"
_SOURCE_TAG = "BioShockCollisionSource="


def _primitive_counts(mesh):
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return 0, 0, 0
    agg = body.get_editor_property("agg_geom")
    return (
        len(agg.get_editor_property("convex_elems") or []),
        len(agg.get_editor_property("box_elems") or []),
        len(agg.get_editor_property("sphere_elems") or []),
    )


def _tag_value(actor, prefix):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith(prefix):
            return text[len(prefix):]
    return None


def _disable_collision(actor, comp):
    actor.modify()
    comp.modify()
    comp.set_collision_profile_name("NoCollision")
    comp.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)


def _sync_proxy(actors, source, mesh, existing):
    source_name = source.get_name()
    proxy = existing.get(source_name)
    if proxy is None:
        proxy = actors.spawn_actor_from_class(
            unreal.StaticMeshActor, source.get_actor_location(), source.get_actor_rotation())
        if proxy is None:
            return None
        proxy.set_actor_label("CollisionProxy_%s" % source.get_actor_label())
        proxy.tags = [
            unreal.Name(_PROXY_TAG),
            unreal.Name(_SOURCE_TAG + source_name),
        ]
        existing[source_name] = proxy
    proxy.set_actor_location(source.get_actor_location(), False, False)
    proxy.set_actor_rotation(source.get_actor_rotation(), False)
    proxy.set_actor_scale3d(source.get_actor_scale3d())
    comp = proxy.static_mesh_component
    comp.set_static_mesh(mesh)
    comp.set_editor_property("mobility", unreal.ComponentMobility.STATIC)
    comp.set_collision_profile_name("BlockAll")
    comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
    comp.set_visibility(False, True)
    proxy.set_actor_hidden_in_game(True)
    return proxy


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    report = {"dryRun": DRY, "maps": [], "failures": []}

    for map_path in MAPS:
        entry = {"map": map_path, "actors": [], "counts": {}}
        if not level.load_level(map_path):
            entry["error"] = "could not load"
            report["failures"].append("could not load %s" % map_path)
            report["maps"].append(entry)
            continue

        level_actors = list(actors.get_all_level_actors())
        existing_proxies = {
            _tag_value(actor, _SOURCE_TAG): actor
            for actor in level_actors
            if _PROXY_TAG in {str(tag) for tag in actor.tags}
            and _tag_value(actor, _SOURCE_TAG)
        }
        source_actors = []
        proxy_meshes = set()
        for actor in level_actors:
            if not isinstance(actor, unreal.StaticMeshActor) \
                    or _PROXY_TAG in {str(tag) for tag in actor.tags}:
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            _, extent = actor.get_actor_bounds(False)
            largest = 2.0 * max(extent.x, extent.y, extent.z)
            source_actors.append((actor, comp, mesh, largest))
            if _DETAILED.search(name) or (_ARCHITECTURE.search(name) and largest >= 200.0):
                proxy_meshes.add(name)

        processed_meshes = set()
        dirty = False
        for actor, comp, mesh, largest in source_actors:
            name = mesh.get_name()
            if ONLY and name.lower() != ONLY:
                continue
            if (actor.get_actor_label() or "").strip().lower() == "compiled world" \
                    or _MODEL_ASSET.match(name):
                continue

            try:
                triangles = mesh.get_num_triangles(0)
            except Exception:  # noqa: BLE001
                triangles = 0
            convex, boxes, spheres = _primitive_counts(mesh)
            item = {
                "actor": actor.get_actor_label(), "mesh": name, "largestDim": largest,
                "triangles": triangles, "convexBefore": convex,
            }

            if is_exterior_name(name) or _PICKUP.search(name) or _SURFACE.search(name):
                policy = "no_collision"
                before = str(comp.get_collision_enabled())
                if not DRY and "NO_COLLISION" not in before:
                    _disable_collision(actor, comp)
                    dirty = True
            elif name in proxy_meshes:
                policy = "static_complex_proxy"
                if not DRY:
                    if name not in processed_meshes:
                        if not _use_complex_collision(mesh):
                            report["failures"].append("%s has no body setup" % name)
                        else:
                            unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                            dirty = True
                    _disable_collision(actor, comp)
                    proxy = _sync_proxy(actors, actor, mesh, existing_proxies)
                    if proxy is None:
                        report["failures"].append(
                            "could not create collision proxy for %s" % actor.get_name())
                    else:
                        item["proxy"] = proxy.get_actor_label()
                        dirty = True
            elif largest < MIN_SIZE or triangles <= 24 or _SIMPLE.search(name):
                policy = "retain_simple"
            elif convex > 1:
                policy = "multi_convex_existing"
            else:
                policy = "retain_simple_unclassified"

            processed_meshes.add(name)
            item["policy"] = policy
            entry["counts"][policy] = entry["counts"].get(policy, 0) + 1
            entry["actors"].append(item)

        if not DRY and dirty:
            level.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"]:
        raise RuntimeError("prop collision:\n- " + "\n- ".join(report["failures"][:20]))
    unreal.log("[prop-collision] wrote %s" % OUT)
    return report


if __name__ == "__main__":
    main()
