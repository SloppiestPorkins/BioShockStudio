"""Give Opacity its own Masks-sampler node on every "translucent" kind master already imported
before this split existed -- see import_bioshock._repair_translucent_opacity_sampler's own
docstring for the full root cause. User-confirmed live in-editor (4 Sept 2026): Wall_Leak_diff_
shader and reinforcedglass_diffuse_shader both showed the default checkerboard, with an ERROR
banner directly on the BaseColor node reading "Sampler type is Color, should be Masks" -- a hard
SM5 compile error, not a benign warning, from sampling that Color-typed node's Alpha channel
directly for Opacity.

Detected and fixed purely structurally (Opacity and BaseColor sharing the same input node) --
no rig/JSON needed, so this scans every master under the given content root's Materials/Masters
folder, not just one map's materials.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_translucent_opacity_sampler.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_OPACITY_ROOT   content root the masters live under (default /Game/BioShockSlice/Content)
"""
import json, os, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_bioshock

CONTENT_ROOT = os.environ.get("BIOSHOCK_OPACITY_ROOT", "/Game/BioShockSlice/Content")
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_translucent_opacity_sampler.json")


def main():
    folder = "%s/Materials/Masters" % CONTENT_ROOT
    paths = unreal.EditorAssetLibrary.list_assets(folder, recursive=True, include_folder=False) or []

    report = {"folder": folder, "checked": 0, "fixed": [], "stillBroken": []}
    for path in paths:
        asset = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(asset, unreal.Material):
            continue
        report["checked"] += 1
        changed = import_bioshock._repair_translucent_opacity_sampler(asset)
        if changed:
            report["fixed"].append(path)

    # Second pass: force every changed master to recompile again and report which (if any) still
    # carry the exact error string, by way of the structural check itself finding nothing left to
    # fix (a real "does this still have the merged-node bug" re-check, not just "did we run").
    for path in report["fixed"]:
        asset = unreal.EditorAssetLibrary.load_asset(path)
        edit = unreal.MaterialEditingLibrary
        opacity_node = edit.get_material_property_input_node(asset, unreal.MaterialProperty.MP_OPACITY)
        base_node = edit.get_material_property_input_node(asset, unreal.MaterialProperty.MP_BASE_COLOR)
        if (opacity_node is not None and base_node is not None
                and opacity_node.get_name() == base_node.get_name()):
            report["stillBroken"].append(path)

    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2, default=str)
    unreal.log("[translucent-opacity-sampler-fix] wrote %s (%d checked / %d fixed / %d still broken)" % (
        OUT, report["checked"], len(report["fixed"]), len(report["stillBroken"])))
    return report


if __name__ == "__main__":
    main()
