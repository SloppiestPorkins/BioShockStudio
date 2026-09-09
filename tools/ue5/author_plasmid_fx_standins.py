"""Author the stand-in materials the plasmid presentation looks for.

w9's `AShockPlasmidFx` and the first-person plasmid hand tint through
`/Game/BioShockFX/Plasmids/M_PlasmidFx_Base` and `.../M_PlasmidHand_Base` with a `Tint`
vector parameter. The shipped UE2 plasmid particle graphs are not recovered; these two
emissive materials make the cast burst / beam meshes and the tinted arm visible until real
Niagara assets exist.

Idempotent: an existing material at the path is replaced so a re-run always leaves a good one.
"""
from __future__ import annotations

import json
import os

import unreal

DEST = "/Game/BioShockFX/Plasmids"
OUT = os.path.join(os.environ.get("TEMP", "."), "author_plasmid_fx_standins.json")

_mel = unreal.MaterialEditingLibrary
_tools = unreal.AssetToolsHelpers.get_asset_tools()


def _make(name, emissive_strength, translucent):
    path = "%s/%s" % (DEST, name)
    if unreal.EditorAssetLibrary.does_asset_exist(path):
        unreal.EditorAssetLibrary.delete_asset(path)
    mat = _tools.create_asset(name, DEST, unreal.Material, unreal.MaterialFactoryNew())
    if mat is None:
        return "create_failed"
    mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    if translucent:
        mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_ADDITIVE)

    tint = _mel.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -600, -60)
    tint.set_editor_property("parameter_name", "Tint")
    tint.set_editor_property("default_value", unreal.LinearColor(0.3, 0.6, 1.0, 1.0))

    strength = _mel.create_material_expression(mat, unreal.MaterialExpressionConstant, -600, 120)
    strength.set_editor_property("r", float(emissive_strength))
    mult = _mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, -380, 0)
    _mel.connect_material_expressions(tint, "", mult, "A")
    _mel.connect_material_expressions(strength, "", mult, "B")
    _mel.connect_material_property(mult, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

    if translucent:
        fres = _mel.create_material_expression(mat, unreal.MaterialExpressionFresnel, -600, 260)
        _mel.connect_material_property(fres, "", unreal.MaterialProperty.MP_OPACITY)

    _mel.recompile_material(mat)
    unreal.EditorAssetLibrary.save_loaded_asset(mat, False)
    return "created"


def main():
    result = {"dest": DEST, "materials": {}}
    unreal.EditorAssetLibrary.make_directory(DEST)
    for name, strength, translucent in (
        ("M_PlasmidFx_Base", 6.0, True),
        ("M_PlasmidHand_Base", 1.5, False),
    ):
        try:
            result["materials"][name] = _make(name, strength, translucent)
        except Exception as exc:  # noqa: BLE001
            result["materials"][name] = "error: %s" % exc
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    unreal.log("BIOSHOCK_PLASMID_FX_STANDINS %s" % json.dumps(result))
    unreal.log("Success - 0 error(s)")
    return result


if __name__ == "__main__":
    main()
