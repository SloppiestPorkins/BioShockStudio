"""Bind exported RGB opacity masks to material instances already imported into UE5.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_opacity_masks.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_OPACITY_MANIFEST      path to <map>.ue5-level.json (required)
  BIOSHOCK_OPACITY_CONTENT_ROOT  content root the level was imported under
  BIOSHOCK_OPACITY_DRY           "1" to report without changing anything

Pipeline: one-off -- import_bioshock binds the OpacityMask texture parameter on each import
(_create_material_instances).
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_bioshock  # noqa: E402

MANIFEST = os.environ.get("BIOSHOCK_OPACITY_MANIFEST", "")
CONTENT_ROOT = os.environ.get("BIOSHOCK_OPACITY_CONTENT_ROOT", "/Game/BioShockLevel")
DRY = os.environ.get("BIOSHOCK_OPACITY_DRY", "0") == "1"
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "repair_opacity_masks.json")


def _texture_asset(destination, relative):
    """The Texture2D an opacity path imported as, or None."""
    stem = os.path.splitext(os.path.basename(relative))[0]
    for path in ("%s/Textures/%s" % (destination, stem), "%s/Textures/%s" % (CONTENT_ROOT, stem)):
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            asset = unreal.EditorAssetLibrary.load_asset(path)
            if isinstance(asset, unreal.Texture2D):
                return asset, path
    return None, None


def _has_opacity_input(material):
    if material is None:
        return False
    node = unreal.MaterialEditingLibrary.get_material_property_input_node(
        material, unreal.MaterialProperty.MP_OPACITY_MASK)
    return (isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D)
            and str(node.get_editor_property("parameter_name")) == "OpacityMask")


def main():
    report = {"contentRoot": CONTENT_ROOT, "dryRun": DRY, "repaired": 0,
              "alreadyBound": 0, "textureMissing": 0, "materials": []}
    with open(MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    destination = "%s/%s" % (CONTENT_ROOT, manifest.get("package") or "Level")
    lib = unreal.MaterialEditingLibrary

    # A current export contains the PNGs, but an older level import cannot already contain assets
    # for masks the old manifest omitted. Import only the authored opacity bindings, using the same
    # linear/mask policy as the normal importer, before repairing their existing instances.
    opacity_pairs = {
        (material.get("name"), material.get("opacity"))
        for material in (manifest.get("materials") or []) if material.get("opacity")
    }
    opacity_entries = [
        entry for entry in (manifest.get("textures") or [])
        if (entry.get("material"), entry.get("file")) in opacity_pairs
    ]
    if opacity_entries and not DRY:
        texture_report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0}
        import_bioshock._import_textures(
            {"materials": manifest.get("materials") or [], "textures": opacity_entries},
            os.path.dirname(os.path.abspath(MANIFEST)), destination, texture_report)
        report["textures"] = texture_report

    for material in manifest.get("materials") or []:
        opacity = material.get("opacity")
        if not opacity:
            continue

        name = import_bioshock._safe_name(material.get("name") or "")
        path = "%s/Materials/MI_%s" % (destination, name)
        if not unreal.EditorAssetLibrary.does_asset_exist(path):
            continue
        mi = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(mi, unreal.MaterialInstanceConstant):
            continue

        entry = {"material": name, "class": material.get("className"), "path": path}
        texture, texture_path = _texture_asset(destination, opacity)
        if texture is None:
            entry["status"] = "texture asset not imported (%s)" % opacity
            report["textureMissing"] += 1
            report["materials"].append(entry)
            continue
        entry["texture"] = texture_path

        current = lib.get_material_instance_texture_parameter_value(mi, "OpacityMask")
        parent = mi.get_editor_property("parent")
        blend = parent.get_editor_property("blend_mode") if parent is not None else None
        if (current == texture and blend == unreal.BlendMode.BLEND_MASKED
                and _has_opacity_input(parent)):
            entry["status"] = "already bound"
            report["alreadyBound"] += 1
            report["materials"].append(entry)
            continue

        if DRY:
            entry["status"] = "would repair"
            report["materials"].append(entry)
            continue

        master = import_bioshock._load_or_create_master(
            material, CONTENT_ROOT, opacity_texture=texture, rig=manifest)
        mi.set_editor_property("parent", master)
        lib.set_material_instance_texture_parameter_value(mi, "OpacityMask", texture)
        lib.update_material_instance(mi)
        unreal.EditorAssetLibrary.save_loaded_asset(mi)

        # Re-read both required effects. Do not count the setter calls as success.
        after = lib.get_material_instance_texture_parameter_value(mi, "OpacityMask")
        after_parent = mi.get_editor_property("parent")
        after_blend = after_parent.get_editor_property("blend_mode") if after_parent is not None else None
        entry["now"] = after.get_name() if after is not None else None
        entry["blendMode"] = str(after_blend) if after_blend is not None else None
        if (after == texture and after_blend == unreal.BlendMode.BLEND_MASKED
                and _has_opacity_input(after_parent)):
            entry["status"] = "repaired"
            report["repaired"] += 1
        else:
            entry["status"] = "repair did NOT persist"
        report["materials"].append(entry)

    _write(report)
    unreal.log("[opacity] repaired=%d alreadyBound=%d textureMissing=%d" % (
        report["repaired"], report["alreadyBound"], report["textureMissing"]))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
