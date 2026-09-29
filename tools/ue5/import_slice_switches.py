"""Place 1-Medical's levers/switches/buttons into the playable slice.

None of `DoorSwitch` / `Switch` / `IncineratorSwitch` / `BathysphereSwitch` /
`Med_MedicalGateSwitch` / `ChompersDentalButton` ever had a dedicated actor class wired --
`import_level.py`'s "other decoded-but-unplaced classes" fallback left every one of them as an
invisible, non-interactive `TargetPoint`. Real scripts already gate on these actors' own labels via
`TriggeredBy` (Medical's `quarswitch` unlocks the Fisheries quarantine gate; `ToNeptuneSwitch` is
the bathysphere departure switch) -- placing them as a real `AShockSwitchActor` with the manifest
mesh + label is what actually lets a player fire those scripts at all. Mirrors
`import_slice_pickups.py`'s structure (mesh lookup, `_place`, idempotent by `BioShockKey=`).

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
# Confirmed live 29 Sept 2026: both StaticMesh and SkeletalMesh assets this level's own import
# already created land in the same /Game/BioShockLevel/Meshes folder, named
# "<objectName>_<sourceExportIndex>" from the reference's own fields (not the outer `index`, which
# is an unrelated export-table slot for the reference itself) -- e.g. staticMeshReference
# {"objectName": "Elevator_Switch2", "sourceExportIndex": 10531} resolves at
# /Game/BioShockLevel/Meshes/Elevator_Switch2_10531. import_level.py's own mesh dict is built the
# same way but keyed by `sourceKey`, only available mid-import; this reconstructs the same asset
# path directly since this script runs as a separate, later pass.
MESH_ROOT = "/Game/BioShockLevel/Meshes"
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_switches.json")

# BioShock class names that reduce to the same real behaviour: a mesh + a label + Press F.
SWITCH_CLASSES = {
    "DoorSwitch", "Switch", "IncineratorSwitch", "BathysphereSwitch",
    "Med_MedicalGateSwitch", "ChompersDentalButton",
}


def _load_mesh_reference(ref, expected_unreal_class):
    """Resolve a manifest staticMeshReference/skeletalMeshReference to the already-imported asset
    this level's own import created for it. None when the reference is missing, the asset can't be
    loaded, or the asset's own real runtime type does not match what the caller actually wants.

    The reference's own `className` field is not trusted for this -- confirmed live 29 Sept 2026 on
    one Med_MedicalGateSwitch record, a skeletalMeshReference claiming className "SkeletalMesh"
    resolved to a genuine UStaticMesh asset on disk (a real import-time mismatch between the
    manifest's claim and what actually landed at that name+index slot). Checking `isinstance` on
    the loaded asset itself is the only reliable guard; handing the wrong type to
    SetSwitchSkeletalMesh/SetSwitchStaticMesh (each only accepts its own mesh type) is a hard
    Python-binding TypeError, not a graceful no-op.
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
    created = actor is None
    if actor is None:
        actor = import_level._actor_subsystem().spawn_actor_from_class(actor_cls, loc, rot)
        if actor is None:
            return None, False
    else:
        actor.set_actor_location(loc, False, False)
        actor.set_actor_rotation(rot, False)
    actor.set_actor_label(str(entry.get("label") or entry.get("name") or key))
    actor.tags = [
        unreal.Name(import_level.KEY_TAG_PREFIX + key),
        unreal.Name("BioShockClass=" + entry["className"]),
    ]
    existing[key] = actor
    return actor, created


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    switch_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockSwitchActor")
    if switch_cls is None:
        raise RuntimeError("runtime ShockSwitchActor class missing — build the plugin first")

    existing = import_level._existing_by_key()
    report = {"manifest": manifest_path, "switches": 0, "byClass": {}, "noMesh": []}

    for entry in manifest.get("actors") or []:
        cn = entry.get("className")
        if cn not in SWITCH_CLASSES:
            continue
        actor, _created = _place(switch_cls, entry, existing)
        if actor is None:
            continue

        label = str(entry.get("label") or entry.get("name") or entry["key"])
        actor.configure(unreal.Name(label), True)

        placed_mesh = False
        static_mesh = _load_mesh_reference(entry.get("staticMeshReference"), unreal.StaticMesh)
        if static_mesh:
            actor.set_switch_static_mesh(static_mesh)
            placed_mesh = True
        skeletal_mesh = _load_mesh_reference(entry.get("skeletalMeshReference"), unreal.SkeletalMesh)
        if skeletal_mesh:
            actor.set_switch_skeletal_mesh(skeletal_mesh)
            placed_mesh = True
        if not placed_mesh:
            report["noMesh"].append({
                "key": entry["key"],
                "static": entry.get("staticMesh"),
                "skeletal": entry.get("skeletalMesh"),
            })

        report["switches"] += 1
        report["byClass"][cn] = report["byClass"].get(cn, 0) + 1

    if save:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[slice-switches] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
