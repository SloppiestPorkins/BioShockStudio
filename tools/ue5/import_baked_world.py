"""Bring the original's baked BSP lighting into a map: a lightmapped copy of the compiled world.

Input: the output of `BioShockStudio.Cli export-baked-lightmaps <map> <dir>`:
  <dir>/<model>.gltf + .bin   compiled world, TEXCOORD_0 = material UV, TEXCOORD_1 = lightmap UV,
                              one primitive per (material, baked atlas), extras {materialKey, material, bakedAtlas}
  <dir>/baked_<n>.png         RGB baked lighting per primary atlas (LINEAR 8-bit, global scale in baked_<n>.json)

The mesh comes in through UE's glTF importer (see _import_mesh for why not a hand-built
StaticMeshDescription). Materials: one unlit master,
M_BioShock_BakedWorld (Emissive = BaseColor x Lightmap x Scale), and an instance per primitive that
takes BaseColor from the level's existing MI for that material. That is how the original draws its
BSP: albedo modulated by baked light, with no runtime lighting on static world geometry.

Env:
  BIOSHOCK_BAKED_DIR   export dir (required)
  BIOSHOCK_BAKED_MAP   map to place it in (default /Game/BioShockLive/1-Medical_Baked, a COPY of the
                       slice made on first run -- never the slice itself unless asked); the copy's
                       compiled-world actor is hidden, not deleted
  BIOSHOCK_BAKED_FROM  map to copy from (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_BAKED_DEST  content folder (default /Game/BioShockLive/BakedWorld/1-Medical)
  BIOSHOCK_BAKED_SCALE emissive scale multiplier on top of the export's global scale (default 1)

Run: python tools/ue5/ue_run.py tools/ue5/import_baked_world.py --env BIOSHOCK_BAKED_DIR=... --timeout 3600

Pipeline: entry-point -- builds the baked-light world for the live renderer.
"""
from __future__ import annotations

import json
import os

import unreal

DIR = os.environ["BIOSHOCK_BAKED_DIR"]
MAP = os.environ.get("BIOSHOCK_BAKED_MAP", "/Game/BioShockLive/1-Medical_Baked")
FROM = os.environ.get("BIOSHOCK_BAKED_FROM", "/Game/BioShockSlice/1-Medical")
DEST = os.environ.get("BIOSHOCK_BAKED_DEST", "/Game/BioShockLive/BakedWorld/1-Medical")
SCALE_MULT = float(os.environ.get("BIOSHOCK_BAKED_SCALE", "1"))
MASTER = "/Game/BioShockLive/M_BioShock_BakedWorld"
MI_DIR = "/Game/BioShockLevel/1-Medical/Materials"
TAG = "BIOSHOCK_BAKED_WORLD"

assets = unreal.AssetToolsHelpers.get_asset_tools()
eal = unreal.EditorAssetLibrary
mel = unreal.MaterialEditingLibrary


# ---------------------------------------------------------------- materials
def _ensure_master():
    if eal.does_asset_exist(MASTER):
        return eal.load_asset(MASTER)
    pkg, name = MASTER.rsplit("/", 1)
    mat = assets.create_asset(name, pkg, unreal.Material, unreal.MaterialFactoryNew())
    mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    base = mel.create_material_expression(mat, unreal.MaterialExpressionTextureSampleParameter2D, -700, -100)
    base.set_editor_property("parameter_name", "BaseColor")
    uv1 = mel.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -950, 200)
    uv1.set_editor_property("coordinate_index", 1)
    lm = mel.create_material_expression(mat, unreal.MaterialExpressionTextureSampleParameter2D, -700, 200)
    lm.set_editor_property("parameter_name", "Lightmap")
    mel.connect_material_expressions(uv1, "", lm, "UVs")
    scale = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -700, 450)
    scale.set_editor_property("parameter_name", "LightmapScale")
    scale.set_editor_property("default_value", 1.0)
    mul1 = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, -350, 50)
    mel.connect_material_expressions(base, "RGB", mul1, "A")
    mel.connect_material_expressions(lm, "RGB", mul1, "B")
    mul2 = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, -150, 150)
    mel.connect_material_expressions(mul1, "", mul2, "A")
    mel.connect_material_expressions(scale, "", mul2, "B")
    mel.connect_material_property(mul2, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    mel.recompile_material(mat)
    eal.save_loaded_asset(mat)
    return mat


def _source_base_color(material_name):
    """BaseColor texture of the level's existing MI for this BioShock material, if any."""
    if not material_name:
        return None
    mi = eal.load_asset("%s/MI_%s" % (MI_DIR, material_name))
    if not mi:
        return None
    for p in mi.get_editor_property("texture_parameter_values") or []:
        if str(p.get_editor_property("parameter_info").get_editor_property("name")) == "BaseColor":
            return p.get_editor_property("parameter_value")
    return None


def _import_lightmaps(pngs):
    """One batched import of every missing lightmap. Headless imports crash on a Slate assert
    AFTER saving, so a crashed run still leaves the textures; the next run skips them."""
    tasks = []
    for png in pngs:
        name = "T_" + os.path.splitext(os.path.basename(png))[0]
        if eal.does_asset_exist("%s/%s" % (DEST, name)):
            continue
        task = unreal.AssetImportTask()
        task.filename = png
        task.destination_path = DEST
        task.destination_name = name
        task.automated = True
        task.replace_existing = True
        task.save = True
        tasks.append(task)
    if tasks:
        assets.import_asset_tasks(tasks)


def _import_lightmap(png):
    name = "T_" + os.path.splitext(os.path.basename(png))[0]
    path = "%s/%s" % (DEST, name)
    tex = eal.load_asset(path)
    if tex:
        # The exporter writes LINEAR light (value*255, no sRGB curve; BakedLightMapExporter).
        tex.set_editor_property("srgb", False)
        tex.set_editor_property("lod_group", unreal.TextureGroup.TEXTUREGROUP_LIGHTMAP)
        tex.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_HDR)
        eal.save_loaded_asset(tex)
    return tex


def _instance(master, label, base_tex, lm_tex, scale):
    name = "MI_Baked_%s" % label
    path = "%s/%s" % (DEST, name)
    mi = eal.load_asset(path) if eal.does_asset_exist(path) else assets.create_asset(
        name, DEST, unreal.MaterialInstanceConstant, unreal.MaterialInstanceConstantFactoryNew())
    mel.set_material_instance_parent(mi, master)
    if base_tex:
        mel.set_material_instance_texture_parameter_value(mi, "BaseColor", base_tex)
    if lm_tex:
        mel.set_material_instance_texture_parameter_value(mi, "Lightmap", lm_tex)
    mel.set_material_instance_scalar_parameter_value(mi, "LightmapScale", scale)
    eal.save_loaded_asset(mi)
    return mi


# ---------------------------------------------------------------- mesh
def _slot_name(i, extras):
    return "P%03d__%s__%s" % (i, extras.get("material") or "none",
                              os.path.splitext(extras.get("bakedAtlas") or "unlit")[0])


def _import_mesh(gltf_path, model_name):
    """Import the compiled world through UE's glTF importer, which keeps TEXCOORD_1 as UV1.

    Building it by hand does not work headless in 5.7: StaticMeshDescription has no UV-channel
    count, and add_uv_channel fails on a mesh built from a description (6 Oct 2026). The export
    has no glTF materials, which would merge every primitive into one section, so a copy is
    written with one named material per primitive; the section names map back to the extras.
    """
    with open(gltf_path, encoding="utf-8") as fh:
        doc = json.load(fh)
    prims = [p for m in doc["meshes"] for p in m["primitives"]]
    doc["materials"] = []
    slots = []
    for i, p in enumerate(prims):
        extras = p.get("extras", {})
        name = _slot_name(i, extras)
        doc["materials"].append({"name": name})
        p["material"] = i
        slots.append((name, extras))
    slotted = os.path.join(os.path.dirname(gltf_path), "%s_slots.gltf" % model_name)
    with open(slotted, "w", encoding="utf-8") as fh:
        json.dump(doc, fh)

    name = "SM_%s_Baked" % model_name
    existing = _find_mesh(model_name)
    if existing is not None:
        return _ordered_slots(existing, slots)
    task = unreal.AssetImportTask()
    task.filename = slotted
    task.destination_path = DEST
    task.destination_name = name
    task.automated = True
    task.replace_existing = True
    task.save = True
    assets.import_asset_tasks([task])
    mesh = _find_mesh(model_name)
    if mesh is None:
        raise RuntimeError("glTF import produced no static mesh")
    return _ordered_slots(mesh, slots)


def _find_mesh(model_name):
    for path in eal.list_assets(DEST, recursive=True):
        if "SM_%s_Baked" % model_name in path:
            obj = eal.load_asset(path)
            if isinstance(obj, unreal.StaticMesh):
                return obj
    return None


def _ordered_slots(mesh, slots):
    # get_num_uv_channels reports 0 under -run=pythonscript even for channel 0, so check the data:
    # sampled UV1 must exist, lie in 0..1 and differ from UV0 (the material UV).
    desc = mesh.get_static_mesh_description(0)
    n = desc.get_vertex_instance_count()
    step = max(1, n // 400)
    uv1 = [desc.get_vertex_instance_uv(unreal.VertexInstanceID(k), 1) for k in range(0, n, step)]
    uv0 = [desc.get_vertex_instance_uv(unreal.VertexInstanceID(k), 0) for k in range(0, n, step)]
    nonzero = sum(1 for u in uv1 if abs(u.x) > 1e-6 or abs(u.y) > 1e-6)
    inrange = sum(1 for u in uv1 if -1e-3 <= u.x <= 1.001 and -1e-3 <= u.y <= 1.001)
    differ = sum(1 for a, b in zip(uv0, uv1) if abs(a.x - b.x) > 1e-4 or abs(a.y - b.y) > 1e-4)
    unreal.log("BAKED_UV1 sampled=%d nonzero=%d inrange=%d differFromUV0=%d" % (len(uv1), nonzero, inrange, differ))
    if nonzero < len(uv1) * 0.5 or inrange < len(uv1) * 0.95:
        raise RuntimeError("lightmap UV1 did not survive import (nonzero %d, in range %d of %d)" % (nonzero, inrange, len(uv1)))
    # Order the slot list by the mesh's own material slots, matched on name.
    by_name = dict(slots)
    ordered = []
    for sm in mesh.get_editor_property("static_materials"):
        nm = str(sm.get_editor_property("material_slot_name"))
        ordered.append((nm, by_name.get(nm, {})))
    return mesh, ordered


def main():
    gltfs = [f for f in os.listdir(DIR) if f.lower().endswith(".gltf") and not f.endswith("_slots.gltf")]
    if len(gltfs) != 1:
        raise RuntimeError("expected one .gltf in %s, found %s" % (DIR, gltfs))
    model_name = os.path.splitext(gltfs[0])[0]
    if not eal.does_directory_exist(DEST):
        eal.make_directory(DEST)
    master = _ensure_master()
    _import_lightmaps([os.path.join(DIR, f) for f in sorted(os.listdir(DIR)) if f.startswith("baked_") and f.endswith(".png")])
    mesh, slots = _import_mesh(os.path.join(DIR, gltfs[0]), model_name)

    report = {"slots": len(slots), "lightmaps": {}, "missingBaseColor": []}
    lm_cache = {}
    for i, (slot, extras) in enumerate(slots):
        atlas = extras.get("bakedAtlas")
        lm = None
        scale = SCALE_MULT
        if atlas:
            if atlas not in lm_cache:
                lm_cache[atlas] = _import_lightmap(os.path.join(DIR, atlas))
                side = os.path.join(DIR, os.path.splitext(atlas)[0] + ".json")
                report["lightmaps"][atlas] = json.load(open(side)) if os.path.exists(side) else None
            lm = lm_cache[atlas]
            info = report["lightmaps"].get(atlas) or {}
            scale = SCALE_MULT * float(info.get("scale", 1.0))
        base = _source_base_color(extras.get("material"))
        if base is None:
            report["missingBaseColor"].append(extras.get("material"))
        mi = _instance(master, "%03d_%s" % (i, slot)[:120], base, lm, scale)
        mesh.set_material(i, mi)
    eal.save_loaded_asset(mesh)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    if not eal.does_asset_exist(MAP):
        if not eal.duplicate_asset(FROM, MAP):
            raise RuntimeError("could not copy %s to %s" % (FROM, MAP))
        report["copiedFrom"] = FROM
    level.load_level(MAP)
    placed = None
    for a in actors.get_all_level_actors():
        if TAG in [str(t) for t in a.tags]:
            placed = a
        elif a.get_actor_label() == "compiled world":
            a.set_actor_hidden_in_game(True)
            a.set_is_temporarily_hidden_in_editor(True)
            a.static_mesh_component.set_editor_property("visible", False)
            report["hidCompiledWorld"] = True
    if placed is None:
        placed = actors.spawn_actor_from_class(unreal.StaticMeshActor, unreal.Vector(0, 0, 0))
        placed.set_actor_label("baked world")
        placed.tags = [TAG]
    placed.static_mesh_component.set_static_mesh(mesh)
    level.save_current_level()
    out = os.path.join(os.environ.get("TEMP", "."), "import_baked_world.json")
    json.dump(report, open(out, "w"), indent=1, default=str)
    unreal.log("BAKED_WORLD slots=%d lightmaps=%d missingBaseColor=%d -> %s" % (
        len(slots), len(lm_cache), len(report["missingBaseColor"]), out))


main()
