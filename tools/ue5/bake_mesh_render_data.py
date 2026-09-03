"""Force every imported static mesh to build and persist its render data.

A -game launch of 1-Medical logs "Waiting on static mesh" 514 times -- once per placed mesh --
and does it on a WARM cache: a second launch with nothing changed waits the same 514 times
(commit 30b7f2f). So the derived render data is not surviving between runs. UE5 keeps the SOURCE
mesh in the .uasset and the DERIVED render data in the DDC keyed on (source + build settings);
a miss on every run means either the key is unstable or the legacy OBJ import never generated
the data in the first place.

This loads each mesh, normalises the build settings that most often force a per-load rebuild
(lightmap-UV generation, distance fields, full-precision positions), blocks until
FStaticMeshCompilingManager has finished, and re-saves the asset. Run it once; then check whether
`capture_shot.ps1` still logs 514 mesh waits.

Read/normalise/save only -- never re-imports. Idempotent.

Run headless (no window):
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/bake_mesh_render_data.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_BAKE_ROOTS   comma-separated content roots (default the two Meshes folders)
  BIOSHOCK_BAKE_DRY     "1" to report the build-setting census and change nothing
"""

from __future__ import annotations

import json
import os

import unreal

ROOTS = [r.strip() for r in os.environ.get(
    "BIOSHOCK_BAKE_ROOTS",
    "/Game/BioShockSlice/Content/Meshes,/Game/BioShockLevel/Meshes").split(",") if r.strip()]
DRY = os.environ.get("BIOSHOCK_BAKE_DRY", "0") == "1"
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "bake_mesh_render_data.json")


def _tally(d, key, value):
    slot = d.setdefault(key, {})
    slot[str(value)] = slot.get(str(value), 0) + 1


def main():
    registry = unreal.AssetRegistryHelpers.get_asset_registry()
    report = {"roots": ROOTS, "dryRun": DRY, "meshes": 0, "changed": 0, "saved": 0,
              "census": {}, "error": None}

    paths = []
    for root in ROOTS:
        for data in registry.get_assets_by_path(unreal.Name(root), recursive=True):
            paths.append(str(data.package_name))

    for path in paths:
        if not unreal.EditorAssetLibrary.does_asset_exist(path):
            continue
        mesh = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(mesh, unreal.StaticMesh):
            continue
        report["meshes"] += 1

        try:
            build = mesh.get_editor_property("build_settings") if hasattr(mesh, "get_editor_property") else None
        except Exception:  # noqa: BLE001
            build = None

        # Census the per-mesh flags that force a rebuild, so the cause is on record.
        try:
            _tally(report["census"], "generateLightmapUVs",
                   mesh.get_lod_build_settings(0).get_editor_property("generate_lightmap_u_vs"))
        except Exception:  # noqa: BLE001
            pass
        for prop, key in (("generate_mesh_distance_field", "distanceField"),):
            try:
                _tally(report["census"], key, mesh.get_editor_property(prop))
            except Exception:  # noqa: BLE001
                pass

        if DRY:
            continue

        changed = False
        try:
            lod0 = mesh.get_lod_build_settings(0)
            # These meshes run on movable lights with precomputed lighting forced off, so a
            # generated lightmap UV set is pure per-load build cost for nothing.
            if lod0.get_editor_property("generate_lightmap_u_vs"):
                lod0.set_editor_property("generate_lightmap_u_vs", False)
                changed = True
            if lod0.get_editor_property("use_full_precision_u_vs"):
                lod0.set_editor_property("use_full_precision_u_vs", False)
                changed = True
            if changed:
                mesh.set_lod_build_settings(0, lod0)
        except Exception as exc:  # noqa: BLE001
            report.setdefault("buildSettingErrors", []).append("%s: %s" % (path, exc))

        try:
            if mesh.get_editor_property("generate_mesh_distance_field"):
                mesh.set_editor_property("generate_mesh_distance_field", False)
                changed = True
        except Exception:  # noqa: BLE001
            pass

        if changed:
            report["changed"] += 1
            mesh.build()  # rebuild render data now, on this machine, once

        # Persist. save_loaded_asset writes the .uasset without the Slate checkout prompt that
        # save_current_level / AssetImportTask(save=True) trip under -run=pythonscript.
        if unreal.EditorAssetLibrary.save_loaded_asset(mesh):
            report["saved"] += 1

    # Block until every queued static-mesh build has finished before the process exits, so the
    # DDC entries are actually written.
    try:
        unreal.StaticMeshEditorSubsystem  # noqa: B018  (presence check)
    except Exception:  # noqa: BLE001
        pass
    try:
        unreal.SystemLibrary.execute_console_command(None, "Editor.AsyncAssetCompilation.FinishAllCompilation")
    except Exception:  # noqa: BLE001
        pass

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[bake] meshes=%d changed=%d saved=%d census=%s" % (
        report["meshes"], report["changed"], report["saved"], json.dumps(report["census"])))
    return report


if __name__ == "__main__":
    main()
