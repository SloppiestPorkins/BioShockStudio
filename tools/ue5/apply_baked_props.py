"""Give the live-view map's static-mesh props the original's baked per-vertex light.

Input: `BioShockStudio.Cli export-vertex-lighting <map> <json>` (StaticMeshInstance light per vertex,
in the exported OBJ's vertex order) plus the level manifest it was exported with (instances ->
asset -> OBJ file). For each placed prop it:
  * writes per-vertex colours (raw light / VERTEX_RANGE, 8-bit) through
    UShockBakedLightLibrary::ApplyBakedVertexLight, which matches render vertices by position;
  * swaps each OPAQUE material for an instance of the unlit M_BioShock_BakedProp master:
    Emissive = BaseColor x (VertexColor x PropLightScale + ZoneAmbient) x BakedExposure, the same
    model as the baked BSP (import_baked_world.py), so props and walls agree;
  * tags the actor BIOSHOCK_BAKED_WORLD so the live bridge drives ZoneAmbient / BakedExposure on it.
Masked/translucent materials (glass, foliage, decals) keep their lit originals for now.

Scale: the BSP path ends up at raw x 1.70 (its PNGs carry the exporter's x1.304 and its material
multiplies by it again). Props store raw / 2.92 (p99 of Medical's vertex light) and multiply by
1.70 x 2.92 = 4.96, so both land on the same raw x 1.70.

Env:
  BIOSHOCK_VL_JSON      vertex lighting export (default Exports/live/1-Medical/vertex_lighting.json)
  BIOSHOCK_LEVEL_JSON   manifest (default Exports/live/1-Medical/1-Medical/1-Medical.ue5-level.json)
  BIOSHOCK_PROPS_MAP    map (default /Game/BioShockLive/1-Medical_Baked -- never the slice)

Run: python tools/ue5/ue_run.py tools/ue5/apply_baked_props.py --timeout 5400

Pipeline: entry-point -- live-renderer map preparation.
"""
from __future__ import annotations

import json
import os

import unreal

PROJECT = os.path.dirname(unreal.Paths.get_project_file_path())
VL_JSON = os.environ.get("BIOSHOCK_VL_JSON") or os.path.join(PROJECT, "Exports", "live", "1-Medical", "vertex_lighting.json")
LEVEL_JSON = os.environ.get("BIOSHOCK_LEVEL_JSON") or os.path.join(
    PROJECT, "Exports", "live", "1-Medical", "1-Medical", "1-Medical.ue5-level.json")
MAP = os.environ.get("BIOSHOCK_PROPS_MAP", "/Game/BioShockLive/1-Medical_Baked")
MASTER = "/Game/BioShockLive/M_BioShock_BakedProp"
MI_DIR = "/Game/BioShockLive/BakedProps"
VERTEX_RANGE = 2.92
PROP_LIGHT_SCALE = 1.70 * VERTEX_RANGE
TAG = "BIOSHOCK_BAKED_WORLD"
KEY_TAG = "BioShockKey="

assets = unreal.AssetToolsHelpers.get_asset_tools()
eal = unreal.EditorAssetLibrary
mel = unreal.MaterialEditingLibrary


def _master():
    if eal.does_asset_exist(MASTER):
        eal.delete_asset(MASTER)
    pkg, name = MASTER.rsplit("/", 1)
    mat = assets.create_asset(name, pkg, unreal.Material, unreal.MaterialFactoryNew())
    mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    base = mel.create_material_expression(mat, unreal.MaterialExpressionTextureSampleParameter2D, -800, -100)
    base.set_editor_property("parameter_name", "BaseColor")
    vc = mel.create_material_expression(mat, unreal.MaterialExpressionVertexColor, -800, 150)
    sc = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -800, 300)
    sc.set_editor_property("parameter_name", "PropLightScale")
    sc.set_editor_property("default_value", PROP_LIGHT_SCALE)
    lit = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, -550, 200)
    mel.connect_material_expressions(vc, "", lit, "A")
    mel.connect_material_expressions(sc, "", lit, "B")
    amb = mel.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -800, 450)
    amb.set_editor_property("parameter_name", "ZoneAmbient")
    amb.set_editor_property("default_value", unreal.LinearColor(0.5, 0.69, 0.83, 0))
    add = mel.create_material_expression(mat, unreal.MaterialExpressionAdd, -350, 250)
    mel.connect_material_expressions(lit, "", add, "A")
    mel.connect_material_expressions(amb, "", add, "B")
    mul = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, -150, 50)
    mel.connect_material_expressions(base, "RGB", mul, "A")
    mel.connect_material_expressions(add, "", mul, "B")
    expo = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -350, 450)
    expo.set_editor_property("parameter_name", "BakedExposure")
    expo.set_editor_property("default_value", 1.0)
    out = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, 50, 150)
    mel.connect_material_expressions(mul, "", out, "A")
    mel.connect_material_expressions(expo, "", out, "B")
    mel.connect_material_property(out, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    mel.recompile_material(mat)
    eal.save_loaded_asset(mat)
    return mat


def _is_opaque(mi):
    m = mi
    for _ in range(8):
        if isinstance(m, unreal.Material):
            return m.get_editor_property("blend_mode") == unreal.BlendMode.BLEND_OPAQUE
        m = m.get_editor_property("parent") if isinstance(m, unreal.MaterialInstance) else None
        if m is None:
            return False
    return False


def _base_color(mi):
    for p in mi.get_editor_property("texture_parameter_values") or []:
        if str(p.get_editor_property("parameter_info").get_editor_property("name")) == "BaseColor":
            return p.get_editor_property("parameter_value")
    return None


def _obj_positions(path, cache):
    if path not in cache:
        pts = []
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if line.startswith("v "):
                    _, x, y, z = line.split()[:4]
                    pts.append(unreal.Vector(float(x), float(y), float(z)))
        cache[path] = pts
    return cache[path]


def main():
    with open(VL_JSON, encoding="utf-8") as fh:
        vl = json.load(fh)
    with open(LEVEL_JSON, encoding="utf-8") as fh:
        manifest = json.load(fh)
    by_actor = {i["key"]: i for i in vl["instances"]}
    asset_file = {a["key"]: a.get("file") for a in manifest["assets"]}
    actor_asset = {i["actorKey"]: i["asset"] for i in manifest["instances"]}
    base_dir = os.path.dirname(LEVEL_JSON)

    if not eal.does_directory_exist(MI_DIR):
        eal.make_directory(MI_DIR)
    master = _master()
    mi_cache, obj_cache = {}, {}

    def baked_mi(src):
        name = src.get_name()
        if name not in mi_cache:
            path = "%s/MI_BakedProp_%s" % (MI_DIR, name)
            mi = eal.load_asset(path) if eal.does_asset_exist(path) else assets.create_asset(
                "MI_BakedProp_%s" % name, MI_DIR, unreal.MaterialInstanceConstant, unreal.MaterialInstanceConstantFactoryNew())
            mel.set_material_instance_parent(mi, master)
            tex = _base_color(src)
            if tex:
                mel.set_material_instance_texture_parameter_value(mi, "BaseColor", tex)
            eal.save_loaded_asset(mi)
            mi_cache[name] = mi
        return mi_cache[name]

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(MAP):
        raise RuntimeError("could not load %s" % MAP)
    report = {"props": 0, "lit": 0, "noData": 0, "countMismatch": 0, "matchedVerts": 0, "renderVerts": 0,
              "slotsSwapped": 0, "slotsKept": 0}
    for actor in unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        key = next((str(t)[len(KEY_TAG):] for t in actor.tags if str(t).startswith(KEY_TAG)), None)
        if not key:
            continue
        if key.startswith("instance:"):
            key = key[len("instance:"):].split(":", 1)[0]
        entry = by_actor.get(key)
        comp = actor.static_mesh_component
        if entry is None or not entry.get("verticesRgb"):
            report["noData"] += 1
            continue
        rel = asset_file.get(actor_asset.get(key) or "")
        if not rel:
            report["noData"] += 1
            continue
        positions = _obj_positions(os.path.join(base_dir, rel), obj_cache)
        rgb = entry["verticesRgb"]
        if len(positions) * 3 != len(rgb):
            report["countMismatch"] += 1
            continue
        colors = []
        for k in range(0, len(rgb), 3):
            colors.append(unreal.Color(r=min(255, int(rgb[k] / VERTEX_RANGE * 255 + 0.5)),
                                       g=min(255, int(rgb[k + 1] / VERTEX_RANGE * 255 + 0.5)),
                                       b=min(255, int(rgb[k + 2] / VERTEX_RANGE * 255 + 0.5)), a=255))
        matched = unreal.ShockBakedLightLibrary.apply_baked_vertex_light(comp, positions, colors)
        report["props"] += 1
        if matched > 0:
            report["lit"] += 1
            report["matchedVerts"] += matched
        for slot in range(comp.get_num_materials()):
            src = comp.get_material(slot)
            if isinstance(src, unreal.MaterialInstanceConstant) and _is_opaque(src):
                comp.set_material(slot, baked_mi(src))
                report["slotsSwapped"] += 1
            else:
                report["slotsKept"] += 1
        if TAG not in [str(t) for t in actor.tags]:
            actor.tags = list(actor.tags) + [unreal.Name(TAG)]
    level.save_current_level()
    out = os.path.join(os.environ.get("TEMP", "."), "apply_baked_props.json")
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=1)
    unreal.log("BAKED_PROPS %s -> %s" % (json.dumps(report), out))


main()
