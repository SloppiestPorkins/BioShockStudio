"""Re-export one FBX through Blender for Unreal's legacy importer — axes preserved.

Run with Blender, not CPython:

    blender --background --python normalize_fbx_for_ue5.py -- input.fbx output.fbx

WHY THIS EXISTS (and why the tools/blender sibling is not enough)
----------------------------------------------------------------
UE5.7's legacy FBX reader rejects this project's binary FBX dialect; Blender reads it
and its re-export imports. The older `tools/blender/normalize_fbx_for_ue5.py` called
`export_scene.fbx` with Blender's defaults (`axis_up='Y'`, `axis_forward='-Z'`).

BioShock FBX (after `GameBasis.Convert` at decode) declares Z-up / -Y-front / +X-coord —
the same triple UE's `FFbxImporter::ConvertScene` targets when `force_front_x_axis` is
false (see Engine FbxMainImport.cpp: UnrealImportAxis is RH, Z-up, front -Y). Matching
axes make ConvertScene a no-op.

Re-exporting as Y-up forces a non-identity ConvertScene on the UE side. Measured live
on AggressorBabyJane (4 Sept 2026): headZ-feetZ = -124.6 after Identity RelRotation —
upside down. Authored bbox is Z[1.1, 197.6]; expect ~+196. Preserving Z-up/-Y-front
here is the import-time fix; do not paper over with mesh RelRotation pitch/roll.

`C = diag(1,-1,1)` is already applied once at C# decode (`ANIMATION_COORDINATE_SYSTEM.md`).
This script must not apply it again. UE's FBX path stays RH-on-import by design (engine
comment: hand flipping Max/Maya RHS→UE LHS is the known residual); level placement
reverses C separately in `import_level.py`. Full-body and first-person hands share one
basis — same normalizer for both.
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
    # Background Blender still opens its startup scene. Without clearing it, every normalized FBX
    # also contains Blender's cube, camera and light; UE can then build an extra material section or
    # consume the wrong mesh data during skeletal import.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=source)
    # Keep the skeleton's authored bone count; leaf bones would alter it.
    # axis_forward/axis_up must match the BioShock FBX declaration and UE's ConvertScene target
    # (Z-up, -Y front). Blender's defaults (Y-up, -Z forward) are what inverted AggressorBabyJane.
    bpy.ops.export_scene.fbx(
        filepath=destination,
        use_selection=False,
        add_leaf_bones=False,
        axis_forward="-Y",
        axis_up="Z",
    )
    print(f"BIO_SHOCK_UE5_NORMALIZED: {destination}")


if __name__ == "__main__":
    main()
