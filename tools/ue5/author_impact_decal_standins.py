"""Author simple deferred-decal materials so bullet impacts are visible before the shipped
BioShock Cascade/decal assets are recovered.

w15 spawns impact decals at `/Game/BioShockFX/Impacts/M_BulletHole_*`; when the asset is
missing the runtime falls back to UE's default deferred-decal material, which is nearly
invisible. This creates a small set of dark radial-falloff decal materials at those exact
paths so `SpawnDecalAtLocation` produces a real mark on the wall.

Idempotent: an existing material at the path is left alone.
"""
from __future__ import annotations

import json
import os

import unreal

DEST = "/Game/BioShockFX/Impacts"
OUT = os.path.join(os.environ.get("TEMP", "."), "author_impact_decal_standins.json")

# name -> (base colour rgb, edge softness, roughness)
DECALS = {
    "M_BulletHole_Concrete": ((0.015, 0.014, 0.012), 0.35),
    "M_BulletHole_Metal": ((0.02, 0.018, 0.015), 0.30),
    "M_BulletHole_Wood": ((0.03, 0.018, 0.010), 0.40),
    "M_BulletHole_Glass": ((0.04, 0.05, 0.06), 0.20),
    "M_BulletHole_Dirt": ((0.03, 0.022, 0.015), 0.45),
    "M_BeamScorch": ((0.008, 0.006, 0.005), 0.55),
}

_mel = unreal.MaterialEditingLibrary
_tools = unreal.AssetToolsHelpers.get_asset_tools()


def _make(name, colour, softness):
    path = "%s/%s" % (DEST, name)
    if unreal.EditorAssetLibrary.does_asset_exist(path):
        unreal.EditorAssetLibrary.delete_asset(path)
    mat = _tools.create_asset(name, DEST, unreal.Material, unreal.MaterialFactoryNew())
    if mat is None:
        return "create_failed"
    mat.set_editor_property("material_domain", unreal.MaterialDomain.MD_DEFERRED_DECAL)
    mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_TRANSLUCENT)

    base = _mel.create_material_expression(mat, unreal.MaterialExpressionConstant3Vector, -600, -100)
    base.set_editor_property("constant", unreal.LinearColor(colour[0], colour[1], colour[2], 1.0))
    _mel.connect_material_property(base, "", unreal.MaterialProperty.MP_BASE_COLOR)

    rough = _mel.create_material_expression(mat, unreal.MaterialExpressionConstant, -600, 40)
    rough.set_editor_property("r", 0.85)
    _mel.connect_material_property(rough, "", unreal.MaterialProperty.MP_ROUGHNESS)

    # Radial opacity: SphereMask over the decal's 0..1 UV, centred at 0.5,0.5.
    uv = _mel.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -700, 200)
    centre = _mel.create_material_expression(mat, unreal.MaterialExpressionConstant2Vector, -700, 320)
    centre.set_editor_property("r", 0.5)
    centre.set_editor_property("g", 0.5)
    # SphereMask A=UV B=centre; its default radius (1.0) over the 0..1 decal UV gives a soft
    # round mark. Radius/hardness are protected in Python, so shape it with OneMinus + Power.
    mask = _mel.create_material_expression(mat, unreal.MaterialExpressionSphereMask, -450, 240)
    _mel.connect_material_expressions(uv, "", mask, "A")
    _mel.connect_material_expressions(centre, "", mask, "B")
    inv = _mel.create_material_expression(mat, unreal.MaterialExpressionOneMinus, -300, 240)
    _mel.connect_material_expressions(mask, "", inv, "")
    tighten = _mel.create_material_expression(mat, unreal.MaterialExpressionPower, -150, 240)
    tighten.set_editor_property("const_exponent", 3.0 + softness * 4.0)
    _mel.connect_material_expressions(inv, "", tighten, "Base")
    _mel.connect_material_property(tighten, "", unreal.MaterialProperty.MP_OPACITY)

    _mel.recompile_material(mat)
    unreal.EditorAssetLibrary.save_loaded_asset(mat, False)
    return "created"


def main():
    result = {"dest": DEST, "materials": {}}
    unreal.EditorAssetLibrary.make_directory(DEST)
    for name, (colour, softness) in DECALS.items():
        try:
            result["materials"][name] = _make(name, colour, softness)
        except Exception as exc:  # noqa: BLE001
            result["materials"][name] = "error: %s" % exc
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    unreal.log("BIOSHOCK_IMPACT_DECAL_STANDINS %s" % json.dumps(result))
    unreal.log("Success - 0 error(s)")
    return result


if __name__ == "__main__":
    main()
