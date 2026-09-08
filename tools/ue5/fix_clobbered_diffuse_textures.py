"""Repair diffuse textures clobbered to srgb=False / TC_MASKS by _import_textures's
duplicate-intent bug, and set every material node that samples them back to a Color sampler.

Root cause (import_bioshock._import_textures, its own comment vs its behaviour): a source PNG
used as both a material's `Diffuse` slot (colourSpace Srgb) and its `Opacity` slot (colourSpace
Linear, usage Mask) is meant to import as two separate assets. It never gets distinct names, so
the second (mask, non-sRGB) import overwrites the first with replace_existing=True. The single
asset on disk ends up srgb=False / TC_MASKS -- wrong for its primary use as BaseColor.

`fix_masked_texture_sampler_mismatch.py` (5 Sept 2026) then made the material *node* match that
wrong state (Color -> Masks sampler), which for a genuine colour wall/carpet texture renders it
as a flat mask -- reported as "walls broken again". This reverses that: reimport each affected
PNG as a proper colour texture (srgb=True, default compression) and reset the nodes.

The texture's alpha channel still carries whatever cutout/coverage data the Opacity slot wanted
-- sampling .A is unaffected by sRGB -- so a single correctly-typed Color asset serves both uses.
The deeper _import_textures fix (actually emit two assets) stays a separate follow-up.

The pixel data on disk is already correct RGBA -- only the import *flags* were clobbered -- so
this just corrects the flags (srgb=True, TC_DEFAULT) and re-saves. A reimport was tried first
and the srgb flag would not stick within the same commandlet session (the async texture factory
resettles the asset after set_editor_property returns); a plain property write + save is reliable.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_clobbered_diffuse_textures.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_CLOBBER_RIG   path to the map's *.ue5-level.json
  BIOSHOCK_CLOBBER_TEXDIR  directory holding the source PNGs (default: <rig dir>/Textures)
  BIOSHOCK_CLOBBER_DRY   "1" to report without changing anything
"""
import json, os, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

RIG = os.environ.get(
    "BIOSHOCK_CLOBBER_RIG",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
)
TEXDIR = os.environ.get(
    "BIOSHOCK_CLOBBER_TEXDIR", os.path.join(os.path.dirname(RIG), "Textures"))
DRY = os.environ.get("BIOSHOCK_CLOBBER_DRY", "0") == "1"
CONTENT_ROOTS = [
    "/Game/BioShockSlice/Content/1-Medical/Textures",
    "/Game/BioShockLevel/1-Medical/Textures",
]
MASTERS_FOLDER = "/Game/BioShockSlice/Content/Materials/Masters"
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_clobbered_diffuse_textures.json")


def _dual_intent_stems(rig_path):
    rig = json.load(open(rig_path, encoding="utf-8"))
    srgb_diffuse, mask_use = set(), set()
    for e in rig.get("textures") or []:
        stem = os.path.splitext(os.path.basename(e.get("file", "")))[0]
        if (e.get("slot") == "Diffuse" or e.get("usage") == "BaseColor") and e.get("colourSpace") == "Srgb":
            srgb_diffuse.add(stem)
        if e.get("slot") == "Opacity" or e.get("usage") == "Mask":
            mask_use.add(stem)
    return srgb_diffuse & mask_use


def _find_asset(stem):
    for root in CONTENT_ROOTS:
        path = "%s/%s" % (root, stem)
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            return path
    return None


def _fix_texture_flags(asset_path, png_path):  # png_path kept for signature parity / logging
    tex = unreal.EditorAssetLibrary.load_asset(asset_path)
    if not isinstance(tex, unreal.Texture2D):
        return False
    tex.set_editor_property("srgb", True)
    tex.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_DEFAULT)
    unreal.EditorAssetLibrary.save_loaded_asset(tex)
    # reload from disk and confirm the flag actually persisted
    unreal.EditorAssetLibrary.load_asset(asset_path)
    fresh = unreal.EditorAssetLibrary.load_asset(asset_path)
    return bool(fresh and fresh.get_editor_property("srgb"))


def _reset_material_samplers(fixed_asset_paths):
    edit = unreal.MaterialEditingLibrary
    fixed = set(fixed_asset_paths)
    props = (
        unreal.MaterialProperty.MP_BASE_COLOR,
        unreal.MaterialProperty.MP_OPACITY,
        unreal.MaterialProperty.MP_OPACITY_MASK,
        unreal.MaterialProperty.MP_EMISSIVE_COLOR,
    )
    sample_classes = (
        unreal.MaterialExpressionTextureSampleParameter2D,
        unreal.MaterialExpressionTextureSample,
    )
    changed = []
    for path in unreal.EditorAssetLibrary.list_assets(MASTERS_FOLDER, recursive=True, include_folder=False) or []:
        mat = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(mat, unreal.Material):
            continue
        touched = False
        seen = set()
        for prop in props:
            node = edit.get_material_property_input_node(mat, prop)
            if node is None or id(node) in seen or not isinstance(node, sample_classes):
                continue
            seen.add(id(node))
            tex = node.get_editor_property("texture")
            if tex is None or tex.get_path_name().split(".")[0] not in fixed:
                continue
            if node.get_editor_property("sampler_type") != unreal.MaterialSamplerType.SAMPLERTYPE_COLOR:
                node.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_COLOR)
                touched = True
        if touched:
            edit.recompile_material(mat)
            unreal.EditorAssetLibrary.save_loaded_asset(mat)
            changed.append(path)
    return changed


def main(rig_path=None):
    rig_path = rig_path or RIG
    stems = sorted(_dual_intent_stems(rig_path))
    report = {"dry": DRY, "candidates": stems, "reimported": [], "failed": [], "materialsReset": []}
    fixed_paths = []
    for stem in stems:
        asset_path = _find_asset(stem)
        png = os.path.join(TEXDIR, stem + ".png")
        if asset_path is None or not os.path.isfile(png):
            report["failed"].append({"stem": stem, "asset": asset_path, "pngExists": os.path.isfile(png)})
            continue
        if DRY:
            report["reimported"].append({"stem": stem, "asset": asset_path, "would": True})
            fixed_paths.append(asset_path)
            continue
        if _fix_texture_flags(asset_path, png):
            report["reimported"].append({"stem": stem, "asset": asset_path})
            fixed_paths.append(asset_path)
        else:
            report["failed"].append({"stem": stem, "asset": asset_path, "reason": "srgb flag did not persist"})

    if not DRY and fixed_paths:
        report["materialsReset"] = _reset_material_samplers(fixed_paths)

    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2, default=str)
    unreal.log("[clobber-fix] %s: %d reimported, %d materials reset, %d failed" % (
        "DRY" if DRY else "applied",
        len(report["reimported"]), len(report["materialsReset"]), len(report["failed"])))
    return report


if __name__ == "__main__":
    main()
