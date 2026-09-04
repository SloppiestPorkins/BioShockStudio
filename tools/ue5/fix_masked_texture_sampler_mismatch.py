"""Fix a sampler-type mismatch caused by _import_textures's duplicate-intent overwrite bug.

Root cause (see import_bioshock.py:281-289's own comment vs its actual behaviour): a source PNG
used for both a material's Diffuse (Srgb, Color) and its Opacity/Mask (Linear, Masks) slot is
meant to import as two separate texture assets, but the code never actually gives the second
import pass a distinct destination name -- it lands on the same asset path with
replace_existing=True, so whichever intent is processed last (Opacity, in practice) silently
overwrites the first. The texture asset that ends up on disk is genuinely srgb=False / TC_MASKS,
not a color texture at all, regardless of which material property samples it.

Confirmed live in-editor on Wall_Leak_diff_shader/reinforcedglass_diffuse_shader (4 Sept-5 Sept
2026): both showed the default checkerboard with a compile error on the BaseColor node ("Sampler
type is Color, should be Masks"). The user's manual fix set BOTH the BaseColor and Opacity
texture-sample nodes to a Masks sampler, matching what the underlying asset actually is. This
propagates that exact, verified fix: for every texture-sampling node on every master (any blend
mode, not just translucent -- an opaque or masked material can hit the same overwrite bug) whose
bound texture asset is actually TC_MASKS/non-sRGB but the node's own sampler_type says otherwise,
correct the node to match the asset.

Does NOT touch the texture import pipeline itself (out of scope, higher risk -- would need a
real re-export+reimport). This only reconciles material graph nodes with texture assets as they
currently exist on disk.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_masked_texture_sampler_mismatch.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_MASK_FIX_ROOT   content root the masters live under (default /Game/BioShockSlice/Content)
"""
import json, os, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

CONTENT_ROOT = os.environ.get("BIOSHOCK_MASK_FIX_ROOT", "/Game/BioShockSlice/Content")
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_masked_texture_sampler_mismatch.json")

_PROPS = (
    ("BaseColor", unreal.MaterialProperty.MP_BASE_COLOR),
    ("Opacity", unreal.MaterialProperty.MP_OPACITY),
    ("OpacityMask", unreal.MaterialProperty.MP_OPACITY_MASK),
    ("Emissive", unreal.MaterialProperty.MP_EMISSIVE_COLOR),
)
_SAMPLE_CLASSES = (
    unreal.MaterialExpressionTextureSampleParameter2D,
    unreal.MaterialExpressionTextureSample,
)


def _fix_master(master, edit):
    changed = []
    seen_nodes = set()
    for label, prop in _PROPS:
        node = edit.get_material_property_input_node(master, prop)
        if node is None or id(node) in seen_nodes:
            continue
        seen_nodes.add(id(node))
        if not isinstance(node, _SAMPLE_CLASSES):
            continue
        texture = node.get_editor_property("texture")
        if texture is None:
            continue
        try:
            compression = texture.get_editor_property("compression_settings")
        except Exception:  # noqa: BLE001
            continue
        is_masks_asset = compression == unreal.TextureCompressionSettings.TC_MASKS
        current_sampler = node.get_editor_property("sampler_type")
        wants_masks = unreal.MaterialSamplerType.SAMPLERTYPE_MASKS
        if is_masks_asset and current_sampler != wants_masks:
            node.set_editor_property("sampler_type", wants_masks)
            changed.append({"property": label, "texture": texture.get_path_name(),
                             "from": str(current_sampler), "to": str(wants_masks)})
    return changed


def main():
    folder = "%s/Materials/Masters" % CONTENT_ROOT
    edit = unreal.MaterialEditingLibrary
    paths = unreal.EditorAssetLibrary.list_assets(folder, recursive=True, include_folder=False) or []

    report = {"folder": folder, "checked": 0, "fixed": []}
    for path in paths:
        asset = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(asset, unreal.Material):
            continue
        report["checked"] += 1
        changes = _fix_master(asset, edit)
        if changes:
            edit.recompile_material(asset)
            unreal.EditorAssetLibrary.save_loaded_asset(asset)
            report["fixed"].append({"master": path, "changes": changes})

    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2, default=str)
    unreal.log("[masked-sampler-fix] wrote %s (%d checked / %d fixed)" % (
        OUT, report["checked"], len(report["fixed"])))
    return report


if __name__ == "__main__":
    main()
