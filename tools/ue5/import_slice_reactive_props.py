"""Place 1-Medical's `NonPhysicalReactiveActor` debris/set-dressing into the playable slice.

Like the switches (`import_slice_switches.py`), `NonPhysicalReactiveActor` never had a
dedicated actor class wired in `import_level.py` -- all 54 instances in 1-Medical fall
through the "other decoded-but-unplaced classes" path and land as invisible,
non-collidable `TargetPoint`s. Checked live 30 Sept 2026: unlike the switches, none of
these 54 instances' labels are referenced by any Script's `TriggeredBy`/`scriptMessageClass`
gate anywhere in the manifest, and no other actor's action property targets them either --
so this is not a "unlocks dead content" fix the way switches were.

It is still a real playability gap: several `TunnelBlock`/`CollapsedTunnel` instances carry
`bBlockActors`/`bBlockPlayers`/`bBlockHavok`/`bCollideActors` in their own manifest property
list (only-non-default properties are serialized in the original .lvl format, so presence
here means the level design explicitly wants these to physically block a corridor -- rubble
forcing a detour). Right now that blockage doesn't exist at all: the corridor is wide open
with nothing to see or collide with. The rest (SteinmanBrokenGlass, ShatterGlass,
CremationContainer, SteinmanBed, EternalFlameBlast prop dressing, ...) are set-dressing a
player currently sees as empty floor space instead of the intended debris/wreckage.

No custom interact class is needed -- these aren't interactable, just real level geometry --
so this uses the engine's own StaticMeshActor/SkeletalMeshActor directly, with a "BlockAll"
collision profile so path-blocking debris actually blocks, and respects `bHidden` when the
manifest's own property list carries it (again: presence means non-default, i.e. explicitly
hidden by design).

Env: BIOSHOCK_LEVEL_JSON overrides the manifest path.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_level  # noqa: E402

SLICE_MAP = "/Game/BioShockSlice/1-Medical"
DEFAULT_MANIFEST = r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/1-Medical.ue5-level.json"
# Same convention confirmed for import_slice_switches.py: both StaticMesh and SkeletalMesh
# assets this level's own import already created land in /Game/BioShockLevel/Meshes, named
# "<objectName>_<sourceExportIndex>" from the reference's own fields.
MESH_ROOT = "/Game/BioShockLevel/Meshes"
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_reactive_props.json")

REACTIVE_CLASSES = {"NonPhysicalReactiveActor"}


def _load_mesh_reference(ref, expected_unreal_class):
    """Same isinstance-guarded resolution as import_slice_switches.py -- the manifest's own
    className claim on a mesh reference is not reliable, only the loaded asset's real type is.
    """
    if not ref:
        return None
    object_name = ref.get("objectName")
    export_index = ref.get("sourceExportIndex")
    if not object_name or export_index is None:
        return None
    asset = unreal.load_asset("%s/%s_%d" % (MESH_ROOT, object_name, export_index))
    if asset is None or not isinstance(asset, expected_unreal_class):
        return None
    return asset


def _place(actor_cls, entry, existing):
    key = entry["key"]
    actor = existing.get(key)
    if actor is not None and actor.get_class() != actor_cls:
        import_level._actor_subsystem().destroy_actor(actor)
        actor = None
    loc = unreal.Vector(*(entry.get("location") or [0.0, 0.0, 0.0]))
    rot = import_level._rotation(entry.get("rotation") or [0, 0, 0])
    if actor is None:
        actor = import_level._actor_subsystem().spawn_actor_from_class(actor_cls, loc, rot)
        if actor is None:
            return None
    else:
        actor.set_actor_location(loc, False, False)
        actor.set_actor_rotation(rot, False)
    actor.set_actor_label(str(entry.get("label") or entry.get("name") or key))
    actor.tags = [
        unreal.Name(import_level.KEY_TAG_PREFIX + key),
        unreal.Name("BioShockClass=" + entry["className"]),
    ]
    existing[key] = actor
    return actor


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    existing = import_level._existing_by_key()
    report = {"manifest": manifest_path, "placed": 0, "hidden": 0, "byClass": {}, "noMesh": []}

    for entry in manifest.get("actors") or []:
        cn = entry.get("className")
        if cn not in REACTIVE_CLASSES:
            continue

        static_mesh = _load_mesh_reference(entry.get("staticMeshReference"), unreal.StaticMesh)
        skeletal_mesh = _load_mesh_reference(entry.get("skeletalMeshReference"), unreal.SkeletalMesh)
        if skeletal_mesh is not None:
            actor_cls = unreal.SkeletalMeshActor
        else:
            actor_cls = unreal.StaticMeshActor

        actor = _place(actor_cls, entry, existing)
        if actor is None:
            continue

        placed_mesh = False
        if isinstance(actor, unreal.SkeletalMeshActor) and skeletal_mesh is not None:
            actor.skeletal_mesh_component.set_skeletal_mesh(skeletal_mesh)
            actor.skeletal_mesh_component.set_collision_profile_name("BlockAll")
            placed_mesh = True
        elif isinstance(actor, unreal.StaticMeshActor) and static_mesh is not None:
            actor.static_mesh_component.set_static_mesh(static_mesh)
            actor.static_mesh_component.set_collision_profile_name("BlockAll")
            placed_mesh = True
        if not placed_mesh:
            report["noMesh"].append({
                "key": entry["key"],
                "static": entry.get("staticMesh"),
                "skeletal": entry.get("skeletalMesh"),
            })

        prop_names = {p.get("name") for p in (entry.get("properties") or [])}
        is_hidden = "bHidden" in prop_names
        actor.set_actor_hidden_in_game(is_hidden)
        if is_hidden:
            report["hidden"] += 1

        report["placed"] += 1
        report["byClass"][cn] = report["byClass"].get(cn, 0) + 1

    if save:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[slice-reactive-props] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
