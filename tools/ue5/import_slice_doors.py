"""Place AShockDoor actors + trigger relays into the playable 1-Medical slice map.

Full `import_level.main` already does door attachments when building the slice, but
`setup_playable_slice` historically skipped that path. This focused step is idempotent
via BioShockKey tags and also places `LoadRoomDoor` (no `door` export key) as AShockDoor
so the start-driven LoadRoomDoor script can OpenDoor via PlayAnimation(*OPEN*).
"""

from __future__ import annotations

import json
import os

import unreal

import import_level

DEFAULT_MANIFEST = (
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json"
)
SLICE_MAP = "/Game/BioShockSlice/1-Medical"
DOOR_KEY_PREFIX = "door:"


def _log(message):
    unreal.log("[bioshock-slice-doors] %s" % message)


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _open_slice_map(map_path=SLICE_MAP):
    level = _level_subsystem()
    if not unreal.EditorAssetLibrary.does_asset_exist(map_path):
        raise RuntimeError("slice map missing: %s (run verify_vertical_slice first)" % map_path)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)
    return map_path


def _decompose_location_rotation(entry):
    transform = entry.get("transform")
    location = entry.get("location") or [0, 0, 0]
    rotation = entry.get("rotation") or [0, 0, 0]
    if transform is not None:
        loc, rot, _scale = import_level._decompose(transform)
        return loc, rot
    # Location is UE uu; rotation in export is often pitch/yaw/roll degrees or UE2 rotator.
    loc = unreal.Vector(float(location[0]), float(location[1]), float(location[2]))
    if isinstance(rotation, dict):
        rot = unreal.Rotator(
            float(rotation.get("pitch", 0)),
            float(rotation.get("yaw", 0)),
            float(rotation.get("roll", 0)),
        )
    else:
        # UE2 rotator ints → degrees (same helper import_level uses via _decompose).
        pitch = float(rotation[0]) * import_level.ROTATOR_TO_DEGREES if len(rotation) > 0 else 0.0
        yaw = float(rotation[1]) * import_level.ROTATOR_TO_DEGREES if len(rotation) > 1 else 0.0
        roll = float(rotation[2]) * import_level.ROTATOR_TO_DEGREES if len(rotation) > 2 else 0.0
        rot = unreal.Rotator(pitch, yaw, roll)
    return loc, rot


def _import_load_room_doors(manifest, existing, report):
    """LoadRoomDoor has skeletal open clips, not Attachments[] — still place as AShockDoor."""
    door_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDoor")
    if door_cls is None:
        report["loadRoomDoorsSkipped"] = report.get("loadRoomDoorsSkipped", 0) + 1
        return

    instances = import_level._instances_by_actor_key(manifest)
    for entry in manifest.get("actors") or []:
        if entry.get("className") != "LoadRoomDoor":
            continue
        key = entry["key"]
        dkey = DOOR_KEY_PREFIX + key
        door_label = entry.get("label") or entry.get("name") or key
        actor_instances = instances.get(key) or []
        if actor_instances and actor_instances[0].get("transform") is not None:
            location, rotation, _scale = import_level._decompose(actor_instances[0]["transform"])
        else:
            location, rotation = _decompose_location_rotation(entry)

        actor = existing.get(dkey)
        if actor is not None:
            actor_cls = actor.get_class()
            if actor_cls != door_cls and not unreal.MathLibrary.class_is_child_of(
                    actor_cls, door_cls):
                import_level._actor_subsystem().destroy_actor(actor)
                actor = None

        if actor is None:
            actor = import_level._actor_subsystem().spawn_actor_from_class(
                door_cls, location, rotation)
            if actor is None:
                report["skipped"] = report.get("skipped", 0) + 1
                continue
            report["created"] = report.get("created", 0) + 1
        else:
            report["updated"] = report.get("updated", 0) + 1
            actor.set_actor_location(location, False, False)
            actor.set_actor_rotation(rotation, False)

        actor.set_actor_label(str(door_label))
        actor.tags = [unreal.Name(import_level.KEY_TAG_PREFIX + dkey)]
        if hasattr(actor, "set_door_label"):
            actor.set_door_label(unreal.Name(str(door_label)))
        if hasattr(actor, "configure_for_verify"):
            actor.configure_for_verify(unreal.Name(str(door_label)), False, False)
        existing[dkey] = actor
        report["loadRoomDoorsPlaced"] = report.get("loadRoomDoorsPlaced", 0) + 1


# Manifest door-mesh prefix → imported skeletal pack + (open, opened, close, closed) clip leafs.
# Packs live under /Game/BioShockCharacters/<pack>/ ; clips under .../Animations/.
_SKELETAL_DOOR_PACKS = {
    "LoadRoomDoorMESH": ("LoadRoomDoorAnim",
                         "LoadRoomDoor_OPEN", "LoadRoomDoor_OPENED",
                         "LoadRoomDoor_CLOSE", "LoadRoomDoor_CLOSED"),
    "Med_DoorAnim": ("Med_DoorAnim", "Med_DoorOPEN", None, "Med_DoorCLOSE", None),
    "BulkheadDoorANIM": ("BulkheadDoor", "TestDoorOpen", None, "TestDoorClose", None),
    "AccGateAnimMesh": ("AccGateAnim",
                        "AccGateAnim_OPEN", "AccGateAnim_OPENED",
                        "AccGateAnim_CLOSE", "AccGateAnim_CLOSED"),
    "Gate01Anim": ("Gate01Anim", "Gate01OPEN", None, "Gate01CLOSE", None),
    "SlidingBrokeStoreDoor": ("SlidingBrokeStoreDoor",
                              "SlidingStoreDoorOpen", None, "SlidingStoreDoorClose", None),
}


def _load_anim(pack, leaf):
    if not leaf:
        return None
    path = "/Game/BioShockCharacters/%s/Animations/%s.%s" % (pack, leaf, leaf)
    return unreal.load_asset(path) if unreal.EditorAssetLibrary.does_asset_exist(path) else None


def _configure_skeletal_doors(manifest, existing, report):
    """Give each placed AShockDoor its real animated mesh + open/close clips where one exists."""
    instances = import_level._instances_by_actor_key(manifest)
    asset_names = import_level._manifest_asset_names(manifest)
    by_key = dict(existing)
    by_key.update(import_level._existing_by_key())
    door_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDoor")
    configured = 0

    for entry in manifest.get("actors") or []:
        # This door's mesh asset name (strip the SkeletalMesh_ prefix + trailing _<index>).
        mesh_name = ""
        for inst in instances.get(entry["key"]) or []:
            nm = asset_names.get(inst.get("asset"), "")
            if nm:
                mesh_name = nm
                break
        if not mesh_name:
            continue
        pack = None
        for prefix, spec in _SKELETAL_DOOR_PACKS.items():
            if mesh_name.startswith(prefix):
                pack = spec
                break
        if pack is None:
            continue

        # The AShockDoor for this actor: door_attachments keys "door:<key>", load-room "door:<key>".
        actor = by_key.get(DOOR_KEY_PREFIX + entry["key"])
        if actor is None or (door_cls is not None
                             and not unreal.MathLibrary.class_is_child_of(actor.get_class(), door_cls)):
            continue

        pack_name, o, od, c, cd = pack
        mesh_path = "/Game/BioShockCharacters/%s/%s.%s" % (pack_name, pack_name, pack_name)
        if not unreal.EditorAssetLibrary.does_asset_exist(mesh_path):
            report.setdefault("skeletalDoorPackMissing", []).append(pack_name)
            continue
        mesh = unreal.load_asset(mesh_path)
        open_a = _load_anim(pack_name, o)
        if mesh is None or open_a is None:
            continue
        actor.configure_skeletal_door(
            mesh, open_a, _load_anim(pack_name, od),
            _load_anim(pack_name, c), _load_anim(pack_name, cd))
        configured += 1

        # Hide the static door-mesh StaticMeshActor the full import placed for this door — the
        # animated AShockDoor now owns the visual (they were z-fighting). Match by mesh-name
        # prefix within ~400uu of the door.
        _hide_static_door_mesh_near(actor, mesh_name, report)

    report["skeletalDoorsConfigured"] = configured


def _hide_static_door_mesh_near(door_actor, mesh_name, report):
    """Hide the StaticMeshActor whose mesh matches this door's animated mesh (same name minus
    the trailing _<index>), within 300uu of the door."""
    import re

    want = re.sub(r"_\d+$", "", mesh_name)
    if not want:
        return
    world = unreal.EditorLevelLibrary.get_editor_world()
    dl = door_actor.get_actor_location()
    for sma in unreal.GameplayStatics.get_all_actors_of_class(world, unreal.StaticMeshActor):
        comp = sma.get_component_by_class(unreal.StaticMeshComponent)
        sm = comp.get_editor_property("static_mesh") if comp else None
        if sm is None or re.sub(r"_\d+$", "", sm.get_name()) != want:
            continue
        sl = sma.get_actor_location()
        if ((sl.x - dl.x) ** 2 + (sl.y - dl.y) ** 2 + (sl.z - dl.z) ** 2) ** 0.5 > 300.0:
            continue
        comp.set_editor_property("hidden_in_game", True)
        comp.set_editor_property("visible", False)
        comp.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
        report["staticDoorMeshesHidden"] = report.get("staticDoorMeshesHidden", 0) + 1


def _wire_existing_trigger_relays(manifest, report):
    """Re-bind relays on TriggerBoxes already in the slice (idempotent InstallOnActor)."""
    by_key = import_level._existing_by_key()
    wired = 0
    for entry in manifest.get("actors") or []:
        if entry.get("className") != "TriggerVolume":
            continue
        actor = by_key.get(entry["key"])
        if actor is None:
            continue
        if import_level._ensure_trigger_relay(actor, entry) is not None:
            wired += 1
    report["triggerRelaysWired"] = wired


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    if not os.path.isfile(manifest_path):
        raise RuntimeError("missing manifest %s" % manifest_path)

    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    _open_slice_map(map_path)
    existing = import_level._existing_by_key()
    report = {
        "manifest": manifest_path,
        "map": map_path,
        "created": 0,
        "updated": 0,
        "skipped": 0,
        "doorsPlaced": 0,
        "doorAttachmentsPlaced": 0,
        "doorAttachmentsSkipped": 0,
        "loadRoomDoorsPlaced": 0,
        "triggerRelaysWired": 0,
    }
    handled = set()
    # Mesh dict empty → cube stand-in doors; labels still drive ActionOpenDoor / PlayAnimation.
    meshes = {}
    import_level._import_door_attachments(manifest, meshes, existing, report, handled)
    _import_load_room_doors(manifest, existing, report)
    _configure_skeletal_doors(manifest, existing, report)
    _wire_existing_trigger_relays(manifest, report)

    if save:
        level = _level_subsystem()
        if not level.save_current_level():
            raise RuntimeError("could not save %s" % map_path)

    _log(
        "doors=%s loadRoom=%s relays=%s"
        % (
            report.get("doorsPlaced", 0),
            report.get("loadRoomDoorsPlaced", 0),
            report.get("triggerRelaysWired", 0),
        )
    )
    return report


if __name__ == "__main__":
    out = os.environ.get(
        "BIOSHOCK_ACTION_OUT",
        os.path.join(os.environ.get("TEMP", "."), "slice_doors_report.json"),
    )
    result = main()
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
