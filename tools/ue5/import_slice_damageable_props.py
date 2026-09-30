"""Place 1-Medical's shootable/damageable reactive props (padlocks, grates, ice, oil slicks, TVs)
into the playable slice.

`Padlock`, `dyn_grate64`, `NonPhysicalNonPathBlockingReactiveActor`, `OilSlick02_Reactive`/
`OilSlick04_Reactive`, and `TV_WallMounted` never had a dedicated actor class wired -- same
"other decoded-but-unplaced classes" fallback as switches, so all 17 instances in 1-Medical
imported as invisible, non-collidable `TargetPoint`s. Unlike the pure set-dressing debris
(`import_slice_reactive_props.py`), these ARE script-load-bearing: real Scripts gate on these
actors' own labels via `TriggeredBy`/`messageFilter` (e.g. `OpenSteinmanGate` waits on
`GatePadlock`/Reason=Shattered, `KureAllGrate1Damaged` waits on `KureAllGrate1`/Reason=Damaged,
`TurnOffLightOnDynamicTelevision` waits on `TV_WallMountedWIthLight`/Reason=Damaged, `MeltedIce`
waits on `IceBlockage`, `IncinerateOilSlickSpread` waits on `ScriptedOilSlick1,ScriptedOilSlick2`)
-- so before this fix, none of these could ever fire from the player shooting/burning/freezing the
prop, since the prop itself didn't exist as a real actor and `UShockDamageLibrary::ApplyDamage`
only ever recognized `AShockPawn` targets in the first place.

New `AShockDamageableProp` (mirrors `AShockSwitchActor`'s shape, but reacts to a weapon hit
instead of a player interact-press) is now checked in `ApplyDamage` and at each hitscan/beam call
site in `ShockWeapon.cpp`. This script places the mesh + label; the damage plumbing lives in the
runtime plugin, not here.

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
MESH_ROOT = "/Game/BioShockLevel/Meshes"
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_damageable_props.json")

DAMAGEABLE_CLASSES = {
    "Padlock", "dyn_grate64", "NonPhysicalNonPathBlockingReactiveActor",
    "OilSlick02_Reactive", "OilSlick04_Reactive", "TV_WallMounted",
}


def _load_mesh_reference(ref, expected_unreal_class):
    """Same isinstance-guarded resolution as import_slice_switches.py / _reactive_props.py."""
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
    # _import_instances already placed a real, visible mesh for most of these keys (see
    # destroy_instance_duplicates' docstring) -- remove it so this dedicated actor's own mesh
    # doesn't overlap a second, non-interactive collider at the same transform. Load-bearing here:
    # a duplicate BlockAll collider means a weapon hitscan can resolve to the dead duplicate
    # instead of this actor, silently defeating the whole damage-reaction fix in real play even
    # though a direct-call unit test (bypassing the trace) would never catch it.
    import_level.destroy_instance_duplicates(existing, key)
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

    prop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDamageableProp")
    if prop_cls is None:
        raise RuntimeError("runtime ShockDamageableProp class missing — build the plugin first")

    existing = import_level._existing_by_key()
    report = {"manifest": manifest_path, "placed": 0, "byClass": {}, "noMesh": []}

    for entry in manifest.get("actors") or []:
        cn = entry.get("className")
        if cn not in DAMAGEABLE_CLASSES:
            continue
        actor = _place(prop_cls, entry, existing)
        if actor is None:
            continue

        label = str(entry.get("label") or entry.get("name") or entry["key"])
        actor.configure(unreal.Name(label), True)

        placed_mesh = False
        static_mesh = _load_mesh_reference(entry.get("staticMeshReference"), unreal.StaticMesh)
        if static_mesh:
            actor.set_prop_static_mesh(static_mesh)
            placed_mesh = True
        skeletal_mesh = _load_mesh_reference(entry.get("skeletalMeshReference"), unreal.SkeletalMesh)
        if skeletal_mesh:
            actor.set_prop_skeletal_mesh(skeletal_mesh)
            placed_mesh = True
        if not placed_mesh:
            report["noMesh"].append({
                "key": entry["key"],
                "static": entry.get("staticMesh"),
                "skeletal": entry.get("skeletalMesh"),
            })

        report["placed"] += 1
        report["byClass"][cn] = report["byClass"].get(cn, 0) + 1

    if save:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[slice-damageable-props] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
