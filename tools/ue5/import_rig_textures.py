"""Re-import full-resolution rig textures over the stale 64x64 assets under
/Game/BioShockCharacters.

The slice's animated meshes (splicers, corpses, turrets, security bots, animated doors, fish,
whales, ...) had their textures exported as 64x64 bulk-tail stubs before commit a8aa54a taught
the FBX export path to recover top mips from ContentBaked/pc/BulkContent.
reexport_rig_textures.ps1 regenerates Rigs/<name>/Textures/*.png at 2048; this re-imports each
PNG over every matching Texture2D asset, restoring colour-space and compression from the rig's
ue5_manifest.json intent.

Env:
  BIOSHOCK_RIG_EXPORT_ROOT  Rigs/ dir (default the slice export's Rigs)
  BIOSHOCK_RIG_TEX_DRY      "1" to report without importing
"""
from __future__ import annotations

import json
import os

import unreal

EXPORT_ROOT = os.environ.get(
    "BIOSHOCK_RIG_EXPORT_ROOT",
    r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/Rigs")
DRY = os.environ.get("BIOSHOCK_RIG_TEX_DRY", "0") == "1"
OUT = os.path.join(os.environ.get("TEMP", "."), "import_rig_textures.json")
CHAR_ROOT = "/Game/BioShockCharacters"


def _asset_index():
    """stem(lower) -> [package paths] for every Texture2D under BioShockCharacters."""
    registry = unreal.AssetRegistryHelpers.get_asset_registry()
    index = {}
    for data in registry.get_assets_by_path(CHAR_ROOT, recursive=True):
        if str(data.asset_class_path.asset_name) != "Texture2D":
            continue
        path = str(data.package_name)
        index.setdefault(path.rsplit("/", 1)[-1].lower(), []).append(path)
    return index


def _intent_for(rig_dir):
    """stem(lower) -> usage string from the rig's ue5 manifest, if present."""
    manifest = os.path.join(rig_dir, "ue5_manifest.json")
    usage = {}
    if not os.path.isfile(manifest):
        return usage
    with open(manifest, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    for rig in data.get("rigs") or [data]:
        for tex in rig.get("textures") or data.get("textures") or []:
            stem = os.path.splitext(os.path.basename(tex.get("file", "")))[0]
            if stem:
                usage.setdefault(stem.lower(), set()).add(tex.get("usage") or tex.get("intent"))
    return usage


def _reimport(asset_path, png, usage):
    destination, name = asset_path.rsplit("/", 1)
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", png)
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("destination_name", name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)  # Slate save path asserts in -run=pythonscript
    task.set_editor_property("factory", unreal.TextureFactory())
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    texture = unreal.EditorAssetLibrary.load_asset(asset_path)
    if not isinstance(texture, unreal.Texture2D):
        return None
    lower_usage = {str(u).lower() for u in usage if u}
    if any("normal" in u for u in lower_usage):
        texture.set_editor_property("srgb", False)
        texture.set_editor_property(
            "compression_settings", unreal.TextureCompressionSettings.TC_NORMALMAP)
    elif any(("mask" in u or "spec" in u or "linear" in u) for u in lower_usage):
        texture.set_editor_property("srgb", False)
    else:
        texture.set_editor_property("srgb", True)
    unreal.EditorAssetLibrary.save_loaded_asset(texture)
    return [texture.blueprint_get_size_x(), texture.blueprint_get_size_y()]


def main():
    index = _asset_index()
    report = {"dryRun": DRY, "reimported": [], "skippedNoAsset": [], "failures": []}
    seen = set()

    for rig_name in sorted(os.listdir(EXPORT_ROOT)):
        rig_dir = os.path.join(EXPORT_ROOT, rig_name)
        tex_dir = os.path.join(rig_dir, "Textures")
        if not os.path.isdir(tex_dir):
            continue
        usage_map = _intent_for(rig_dir)
        for filename in sorted(os.listdir(tex_dir)):
            if not filename.lower().endswith(".png"):
                continue
            stem = os.path.splitext(filename)[0]
            targets = index.get(stem.lower())
            if not targets:
                report["skippedNoAsset"].append("%s/%s" % (rig_name, stem))
                continue
            png = os.path.join(tex_dir, filename)
            for asset_path in targets:
                if asset_path in seen:
                    continue
                seen.add(asset_path)
                if DRY:
                    report["reimported"].append({"asset": asset_path, "png": png, "dry": True})
                    continue
                try:
                    size = _reimport(asset_path, png, usage_map.get(stem.lower(), set()))
                    if size is None:
                        report["failures"].append("%s did not reload as Texture2D" % asset_path)
                    else:
                        report["reimported"].append({"asset": asset_path, "size": size})
                except Exception as exc:  # noqa: BLE001
                    report["failures"].append("%s: %s" % (asset_path, exc))

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[rig-textures] reimported=%d skipped=%d failures=%d" % (
        len(report["reimported"]), len(report["skippedNoAsset"]), len(report["failures"])))
    if report["failures"]:
        raise RuntimeError("rig texture import:\n- " + "\n- ".join(report["failures"][:20]))
    return report


if __name__ == "__main__":
    main()
