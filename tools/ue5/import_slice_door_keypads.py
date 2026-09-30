"""Place 1-Medical's `DoorKeypadControl` instances into the playable slice.

`DoorKeypadControl` never had a dedicated actor class wired -- same "other decoded-but-unplaced
classes" fallback as switches, so Medical's one instance ("TwilightFieldsKeypad", unlocking
"MorgueClosetDoor") imported as an inert `TargetPoint`. Real script gates on it
(`TwilightFieldsKeypadScript`, `TriggeredBy=TwilightFieldsKeypad`,
`scriptMessageClass=MessageDoorKeypadUsed`), so before this fix that script could never fire from
the player's own action.

Deliberately does NOT implement a real code-entry minigame -- see AShockDoorKeypadControl's class
docstring for why. Interacting with the keypad always succeeds: it unlocks the door named by the
manifest's own `interaction.doorLabel` and dispatches MessageDoorKeypadUsed so the associated
Script's own action list still runs.

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
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_door_keypads.json")

KEYPAD_CLASS_NAME = "DoorKeypadControl"


def _load_mesh_reference(ref, expected_unreal_class):
    """Same isinstance-guarded resolution as import_slice_switches.py."""
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


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    keypad_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDoorKeypadControl")
    if keypad_cls is None:
        raise RuntimeError("runtime ShockDoorKeypadControl class missing — build the plugin first")

    existing = import_level._existing_by_key()
    report = {"manifest": manifest_path, "placed": 0, "noMesh": []}

    for entry in manifest.get("actors") or []:
        if entry.get("className") != KEYPAD_CLASS_NAME:
            continue
        key = entry["key"]
        import_level.destroy_instance_duplicates(existing, key)
        actor = existing.get(key)
        if actor is not None and actor.get_class() != keypad_cls:
            import_level._actor_subsystem().destroy_actor(actor)
            actor = None
        loc = unreal.Vector(*(entry.get("location") or [0.0, 0.0, 0.0]))
        rot = import_level._rotation(entry.get("rotation") or [0, 0, 0])
        if actor is None:
            actor = import_level._actor_subsystem().spawn_actor_from_class(keypad_cls, loc, rot)
            if actor is None:
                continue
        else:
            actor.set_actor_location(loc, False, False)
            actor.set_actor_rotation(rot, False)

        label = str(entry.get("label") or entry.get("name") or key)
        actor.set_actor_label(label)
        actor.tags = [
            unreal.Name(import_level.KEY_TAG_PREFIX + key),
            unreal.Name("BioShockClass=" + entry["className"]),
        ]
        existing[key] = actor

        interaction = entry.get("interaction") or {}
        door_label = str(interaction.get("doorLabel") or "")
        hackable = bool(interaction.get("hackable") or False)
        actor.configure(unreal.Name(label), unreal.Name(door_label), hackable)

        placed_mesh = False
        static_mesh = _load_mesh_reference(entry.get("staticMeshReference"), unreal.StaticMesh)
        if static_mesh:
            actor.set_keypad_static_mesh(static_mesh)
            placed_mesh = True
        skeletal_mesh = _load_mesh_reference(entry.get("skeletalMeshReference"), unreal.SkeletalMesh)
        if skeletal_mesh:
            actor.set_keypad_skeletal_mesh(skeletal_mesh)
            placed_mesh = True
        if not placed_mesh:
            report["noMesh"].append({
                "key": key,
                "static": entry.get("staticMesh"),
                "skeletal": entry.get("skeletalMesh"),
            })

        report["placed"] += 1

    if save:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[slice-door-keypads] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
