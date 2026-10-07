"""Create /Game/BioShockLive/M_LiveHud: the material that draws the original game's HUD over the
live view (Track E4). The proxy dxgi.dll streams the HUD-only back buffer (HUD on black, alpha
always 255), so opacity is keyed from brightness: saturate(max(r, g, b) * 3). Full-screen screens
(pause menu, map) set the scalar Opaque = 1 and cover the view, as they do in the game.

Run: python tools/ue5/ue_run.py tools/ue5/create_live_hud_material.py

Pipeline: entry-point -- live-renderer setup (once per project).
"""
import unreal

PATH = "/Game/BioShockLive/M_LiveHud"
lib = unreal.MaterialEditingLibrary
if unreal.EditorAssetLibrary.does_asset_exist(PATH):
    unreal.EditorAssetLibrary.delete_asset(PATH)
mat = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
    "M_LiveHud", "/Game/BioShockLive", unreal.Material, unreal.MaterialFactoryNew())
mat.set_editor_property("material_domain", unreal.MaterialDomain.MD_UI)
mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_TRANSLUCENT)

tex = lib.create_material_expression(mat, unreal.MaterialExpressionTextureSampleParameter2D, -700, 0)
tex.set_editor_property("parameter_name", "Hud")
tex.set_editor_property("texture", unreal.load_asset("/Engine/EngineResources/WhiteSquareTexture"))
mx1 = lib.create_material_expression(mat, unreal.MaterialExpressionMax, -450, 150)
mx2 = lib.create_material_expression(mat, unreal.MaterialExpressionMax, -300, 150)
mul = lib.create_material_expression(mat, unreal.MaterialExpressionMultiply, -150, 150)
mul.set_editor_property("const_b", 3.0)
sat = lib.create_material_expression(mat, unreal.MaterialExpressionSaturate, 0, 150)
opaque = lib.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, 0, 300)
opaque.set_editor_property("parameter_name", "Opaque")
opaque.set_editor_property("default_value", 0.0)
mx3 = lib.create_material_expression(mat, unreal.MaterialExpressionMax, 150, 200)
lib.connect_material_expressions(tex, "R", mx1, "A")
lib.connect_material_expressions(tex, "G", mx1, "B")
lib.connect_material_expressions(mx1, "", mx2, "A")
lib.connect_material_expressions(tex, "B", mx2, "B")
lib.connect_material_expressions(mx2, "", mul, "A")
lib.connect_material_expressions(mul, "", sat, "")
lib.connect_material_property(tex, "RGB", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
lib.connect_material_expressions(sat, "", mx3, "A")
lib.connect_material_expressions(opaque, "", mx3, "B")
lib.connect_material_property(mx3, "", unreal.MaterialProperty.MP_OPACITY)
lib.recompile_material(mat)
unreal.EditorAssetLibrary.save_asset(PATH)
unreal.log("LIVE_HUD_MATERIAL saved %s" % PATH)
