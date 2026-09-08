"""Reimport host-recovered BulkContent PNGs over existing slice texture assets."""
from __future__ import annotations

import json
import os

import unreal

SOURCE = os.environ.get("BIOSHOCK_RECOVERED_TEXTURE_DIR", "")
MANIFEST = os.environ.get(
    "BIOSHOCK_RECOVERED_TEXTURE_MANIFEST",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json")
OUT = os.path.join(os.environ.get("TEMP", "."), "import_recovered_slice_textures.json")
ROOTS = (
    "/Game/BioShockSlice/Content/1-Medical/Textures",
    "/Game/BioShockLevel/1-Medical/Textures",
)


def main():
    with open(MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    intents = {}
    for entry in manifest.get("textures") or []:
        stem = os.path.splitext(os.path.basename(entry.get("file") or ""))[0]
        intents.setdefault(stem, []).append(entry)

    report = {"source": SOURCE, "imported": [], "failures": []}
    for filename in sorted(os.listdir(SOURCE) if os.path.isdir(SOURCE) else []):
        if not filename.lower().endswith(".png"):
            continue
        stem = os.path.splitext(filename)[0]
        asset_path = next((
            "%s/%s" % (root, stem) for root in ROOTS
            if unreal.EditorAssetLibrary.does_asset_exist("%s/%s" % (root, stem))), None)
        if asset_path is None:
            report["failures"].append("%s has no existing texture asset" % stem)
            continue
        destination, asset_name = asset_path.rsplit("/", 1)
        task = unreal.AssetImportTask()
        task.set_editor_property("filename", os.path.join(SOURCE, filename))
        task.set_editor_property("destination_path", destination)
        task.set_editor_property("destination_name", asset_name)
        task.set_editor_property("automated", True)
        task.set_editor_property("replace_existing", True)
        # save=True enters a Slate checkout/toast path and asserts in -run=pythonscript.
        task.set_editor_property("save", False)
        # Pin the legacy factory: UE5.7 Interchange enters the same invalid Slate path headlessly.
        task.set_editor_property("factory", unreal.TextureFactory())
        unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])

        texture = unreal.EditorAssetLibrary.load_asset(asset_path)
        if not isinstance(texture, unreal.Texture2D):
            report["failures"].append("%s did not reload as Texture2D" % asset_path)
            continue
        usage = {entry.get("usage") for entry in intents.get(stem, [])}
        if "NormalMap" in usage:
            texture.set_editor_property("srgb", False)
            texture.set_editor_property(
                "compression_settings", unreal.TextureCompressionSettings.TC_NORMALMAP)
        elif "BaseColor" in usage:
            texture.set_editor_property("srgb", True)
            texture.set_editor_property(
                "compression_settings", unreal.TextureCompressionSettings.TC_DEFAULT)
        unreal.EditorAssetLibrary.save_loaded_asset(texture)
        report["imported"].append({
            "stem": stem, "asset": asset_path,
            "size": [texture.blueprint_get_size_x(), texture.blueprint_get_size_y()],
            "usage": sorted(value for value in usage if value),
        })

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"] or not report["imported"]:
        raise RuntimeError("recovered texture import:\n- " + "\n- ".join(report["failures"]))
    return report


if __name__ == "__main__":
    main()
