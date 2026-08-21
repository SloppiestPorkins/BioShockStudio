"""Re-export one FBX through Blender's FBX writer for Unreal's legacy importer.

Run this file with Blender, not CPython:

    blender --background --python normalize_fbx_for_ue5.py -- input.fbx output.fbx
"""

import os
import sys

import bpy


def _paths():
    try:
        separator = sys.argv.index("--")
        source, destination = sys.argv[separator + 1:separator + 3]
    except (ValueError, IndexError):
        raise SystemExit("Expected: -- <input.fbx> <output.fbx>")
    return os.path.abspath(source), os.path.abspath(destination)


def main():
    source, destination = _paths()
    if not os.path.isfile(source):
        raise SystemExit(f"Input FBX does not exist: {source}")

    os.makedirs(os.path.dirname(destination), exist_ok=True)
    bpy.ops.import_scene.fbx(filepath=source)
    # Keep the skeleton's authored bone count; leaf bones would alter it.
    bpy.ops.export_scene.fbx(filepath=destination, use_selection=False, add_leaf_bones=False)
    print(f"BIO_SHOCK_UE5_NORMALIZED: {destination}")


if __name__ == "__main__":
    main()
