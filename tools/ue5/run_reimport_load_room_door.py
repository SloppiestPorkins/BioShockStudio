"""Cleanly reimport the five LoadRoomDoor clips and their T0 reference pose."""

import json
import os
import sys
import traceback

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_bioshock

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "load_room_door_import.json"),
)
EXPORT = os.environ.get(
    "BIOSHOCK_LOAD_ROOM_EXPORT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical"
    r"\Rigs\LoadRoomDoorMESH",
)
DESTINATION = "/Game/BioShockCharacters/LoadRoomDoorAnim"


try:
    # AnimSequences retain a hard Skeleton reference. Remove them before import_bioshock
    # replaces the mesh/skeleton packages; otherwise UE5.7 can assert in AsyncLoading2 while
    # resolving the now-orphaned clips.
    animation_dir = DESTINATION + "/Animations"
    if unreal.EditorAssetLibrary.does_directory_exist(animation_dir):
        if not unreal.EditorAssetLibrary.delete_directory(animation_dir):
            raise RuntimeError("could not remove stale " + animation_dir)
    if os.environ.get("BIOSHOCK_DELETE_ONLY", "").strip() == "1":
        result = {"deleted": animation_dir}
        with open(OUT, "w", encoding="utf-8") as handle:
            json.dump(result, handle, indent=2)
        raise SystemExit(0)

    os.environ["BIOSHOCK_FORCE_IMPORT"] = "1"
    imported = import_bioshock.main(EXPORT, content_root="/Game/BioShockCharacters")
    mesh = imported.get("LoadRoomDoorAnim")
    result = {
        "mesh": mesh.get_path_name() if mesh is not None else None,
        "animations": [
            str(data.asset_name)
            for data in unreal.AssetRegistryHelpers.get_asset_registry().get_assets_by_path(
                unreal.Name(animation_dir), recursive=True)
        ],
    }
    if mesh is None:
        raise RuntimeError("LoadRoomDoorAnim did not import")
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
except Exception as exc:  # noqa: BLE001
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(
            {"error": str(exc), "traceback": traceback.format_exc()},
            handle,
            indent=2,
        )
    raise
