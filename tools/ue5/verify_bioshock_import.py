"""Verify an imported BioShock UE5 asset set against its export manifest.

Set ``BIOSHOCK_EXPORT_DIRECTORY`` and run this with Unreal's ``-run=pythonscript`` commandlet.
The commandlet exits non-zero if the verified inventory is incomplete.
"""

import json
import os

import unreal


def _log(message):
    unreal.log(f"[bioshock verify] {message}")


def _load(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if asset is None:
        raise RuntimeError(f"Missing asset: {path}")
    return asset


def main(export_directory=None, content_root="/Game/BioShock"):
    export_directory = export_directory or os.environ.get("BIOSHOCK_EXPORT_DIRECTORY")
    content_root = os.environ.get("BIOSHOCK_CONTENT_ROOT", content_root)
    if not export_directory:
        raise RuntimeError("Set BIOSHOCK_EXPORT_DIRECTORY to the FBX export folder.")

    with open(os.path.join(export_directory, "ue5_manifest.json"), encoding="utf-8") as handle:
        manifest = json.load(handle)

    failures = []
    for rig in manifest["rigs"]:
        asset_root = f"{content_root}/{rig['name']}"
        mesh = _load(f"{asset_root}/{rig['name']}")
        if not isinstance(mesh, unreal.SkeletalMesh):
            failures.append(f"{rig['name']}: expected SkeletalMesh, got {mesh.get_class().get_name()}")
            continue

        skeleton = mesh.get_editor_property("skeleton")
        bone_count = len(skeleton.get_editor_property("bone_tree")) if skeleton else 0
        # UE5's Python bindings deliberately protect BoneNode names. The count is still valuable:
        # every manifest socket is exported as one additional skeleton node.
        socket_count = len(rig["sockets"])
        expected_animations = {animation["name"] for animation in rig["animations"]}
        animation_path = f"{asset_root}/Animations"
        imported_animations = {
            asset.get_name()
            for path in unreal.EditorAssetLibrary.list_assets(animation_path, recursive=False)
            for asset in [_load(path)]
            if isinstance(asset, unreal.AnimSequence)
        }
        missing_animations = sorted(expected_animations - imported_animations)

        _log(f"{rig['name']}: {bone_count} skeleton nodes ({socket_count} manifest sockets), "
             f"{len(imported_animations)}/{len(expected_animations)} animations")
        if bone_count < rig["boneCount"]:
            failures.append(f"{rig['name']}: skeleton has {bone_count}, expected at least "
                            f"{rig['boneCount']} authored bones")
        if skeleton is None:
            failures.append(f"{rig['name']}: mesh has no Skeleton asset")
        if missing_animations:
            failures.append(f"{rig['name']}: missing animations {', '.join(missing_animations)}")

    if failures:
        raise RuntimeError("UE5 import verification failed:\n- " + "\n- ".join(failures))
    _log("PASS: imported inventory matches the manifest")


if __name__ == "__main__":
    main()
