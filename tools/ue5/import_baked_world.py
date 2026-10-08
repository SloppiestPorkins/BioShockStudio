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
import sys
import struct

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import live_paths  # noqa: E402

DIR = os.environ.get("BIOSHOCK_BAKED_DIR") or live_paths.baked_dir()
MAP = os.environ.get("BIOSHOCK_BAKED_MAP") or live_paths.live_map()
FROM = os.environ.get("BIOSHOCK_BAKED_FROM") or live_paths.source_map()
DEST = os.environ.get("BIOSHOCK_BAKED_DEST") or live_paths.baked_world_dest()
SCALE_MULT = float(os.environ.get("BIOSHOCK_BAKED_SCALE", "1"))
# 1: lightmap UV in channel 0 and material UV in channel 1. The rendered UV1 came out wrong although
# the mesh description held it (6 Oct 2026); UV0 is known to render.
SWAP_UV = os.environ.get("BIOSHOCK_BAKED_SWAP_UV", "1") == "1"
MASTER = "/Game/BioShockLive/M_BioShock_BakedWorld"
# Global multiplier the live bridge drives at runtime ("L <value>" -> BakedExposure): the slice pins a
# manual exposure tuned for its dynamic lights, so the right emissive level is found by measurement.
MPC = "/Game/BioShockLive/MPC_BioShockLive"
MI_DIR = live_paths.mi_dirs()[0]
TAG = "BIOSHOCK_BAKED_WORLD"

assets = unreal.AssetToolsHelpers.get_asset_tools()
eal = unreal.EditorAssetLibrary
mel = unreal.MaterialEditingLibrary


# ---------------------------------------------------------------- materials
def _ensure_mpc():
    if eal.does_asset_exist(MPC):
        mpc = eal.load_asset(MPC)
    else:
        pkg, name = MPC.rsplit("/", 1)
        mpc = assets.create_asset(name, pkg, unreal.MaterialParameterCollection, unreal.MaterialParameterCollectionFactoryNew())
    params = list(mpc.get_editor_property("scalar_parameters") or [])
    if not any(str(p.get_editor_property("parameter_name")) == "BakedExposure" for p in params):
        sp = unreal.CollectionScalarParameter()
        sp.set_editor_property("parameter_name", "BakedExposure")
        sp.set_editor_property("default_value", 1.0)
        params.append(sp)
        mpc.set_editor_property("scalar_parameters", params)
        eal.save_loaded_asset(mpc)
    return mpc


def _ensure_master(default_lightmap):
    """Build the unlit master fresh: Emissive = BaseColor x Lightmap(UV1) x LightmapScale x BakedExposure.

    Rebuilt from scratch each run: delete_all_material_expressions left the previous graph in place
    (14 expressions where 8 were made). The Lightmap parameter samples LinearColor, so its default
    texture must be linear too -- the engine default is sRGB, and that sampler mismatch fails the
    compile, which silently renders every instance with the default checker material.
    """
    if eal.does_asset_exist(MASTER):
        eal.delete_asset(MASTER)
    pkg, name = MASTER.rsplit("/", 1)
    mat = assets.create_asset(name, pkg, unreal.Material, unreal.MaterialFactoryNew())
    mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    base = mel.create_material_expression(mat, unreal.MaterialExpressionTextureSampleParameter2D, -700, -100)
    base.set_editor_property("parameter_name", "BaseColor")
    base_uv = mel.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -950, -100)
    base_uv.set_editor_property("coordinate_index", 1 if SWAP_UV else 0)
    mel.connect_material_expressions(base_uv, "", base, "UVs")
    uv1 = mel.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -1150, 200)
    uv1.set_editor_property("coordinate_index", 0 if SWAP_UV else 1)   # the lightmap's own channel
    uv0 = mel.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -1150, 330)
    uv0.set_editor_property("coordinate_index", 1 if SWAP_UV else 0)   # debug: the material channel
    # Debug: LightmapFromUV0 = 1 samples the lightmap with the material channel instead of its own.
    uvsw = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -1150, 450)
    uvsw.set_editor_property("parameter_name", "LightmapFromUV0")
    uvsw.set_editor_property("default_value", 0.0)
    uvl = mel.create_material_expression(mat, unreal.MaterialExpressionLinearInterpolate, -950, 250)
    mel.connect_material_expressions(uv1, "", uvl, "A")
    mel.connect_material_expressions(uv0, "", uvl, "B")
    mel.connect_material_expressions(uvsw, "", uvl, "Alpha")
    lm = mel.create_material_expression(mat, unreal.MaterialExpressionTextureSampleParameter2D, -700, 200)
    lm.set_editor_property("parameter_name", "Lightmap")
    lm.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_LINEAR_COLOR)
    if default_lightmap is not None:
        lm.set_editor_property("texture", default_lightmap)
    mel.connect_material_expressions(uvl, "", lm, "UVs")
    scale = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -700, 450)
    scale.set_editor_property("parameter_name", "LightmapScale")
    scale.set_editor_property("default_value", 1.0)
    # A plain scalar (not a parameter-collection read): the live bridge sets it on dynamic instances
    # of this actor's materials. The MPC route rendered black at every value (6 Oct 2026).
    expo = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -700, 600)
    expo.set_editor_property("parameter_name", "BakedExposure")
    expo.set_editor_property("default_value", 1.0)
    # Debug switches (default 1 = normal): UseBase / UseLightmap replace their factor with 1 when 0,
    # so a capture can show base colour alone or baked light alone.
    def factor(src, src_pin, name, x, y):
        sw = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, x - 250, y + 120)
        sw.set_editor_property("parameter_name", name)
        sw.set_editor_property("default_value", 1.0)
        one = mel.create_material_expression(mat, unreal.MaterialExpressionConstant3Vector, x - 250, y - 60)
        one.set_editor_property("constant", unreal.LinearColor(1, 1, 1, 1))
        lerp = mel.create_material_expression(mat, unreal.MaterialExpressionLinearInterpolate, x, y)
        mel.connect_material_expressions(one, "", lerp, "A")
        mel.connect_material_expressions(src, src_pin, lerp, "B")
        mel.connect_material_expressions(sw, "", lerp, "Alpha")
        return lerp
    fb = factor(base, "RGB", "UseBase", -350, -150)
    fl = factor(lm, "RGB", "UseLightmap", -350, 250)
    # albedo x (baked x LightmapScale + ZoneAmbient) x BakedExposure: the original adds its zone's
    # ambient to the baked light, so surfaces no static light reaches are dim, not black. ZoneAmbient
    # is set live by the bridge from the player's zone (Z line).
    lmscaled = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, -100, 250)
    mel.connect_material_expressions(fl, "", lmscaled, "A")
    mel.connect_material_expressions(scale, "", lmscaled, "B")
    amb = mel.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -350, 450)
    amb.set_editor_property("parameter_name", "ZoneAmbient")
    amb.set_editor_property("default_value", unreal.LinearColor(0, 0, 0, 0))
    light = mel.create_material_expression(mat, unreal.MaterialExpressionAdd, 50, 300)
    mel.connect_material_expressions(lmscaled, "", light, "A")
    mel.connect_material_expressions(amb, "", light, "B")
    mul2 = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, 100, 150)
    mel.connect_material_expressions(fb, "", mul2, "A")
    mel.connect_material_expressions(light, "", mul2, "B")
    mul3 = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, 300, 250)
    mel.connect_material_expressions(mul2, "", mul3, "A")
    mel.connect_material_expressions(expo, "", mul3, "B")
    # Debug: ShowLightmapUV = 1 outputs the lightmap UV itself as colour (R = U, G = V), to see what
    # the GPU actually receives.
    show = mel.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, 300, 450)
    show.set_editor_property("parameter_name", "ShowLightmapUV")
    show.set_editor_property("default_value", 0.0)
    uvcol = mel.create_material_expression(mat, unreal.MaterialExpressionAppendVector, 300, 600)
    zero = mel.create_material_expression(mat, unreal.MaterialExpressionConstant, 150, 650)
    # frac(uv * 32): a tile ~30 texels wide shows as one gradient ramp, so a constant UV is obvious.
    k32 = mel.create_material_expression(mat, unreal.MaterialExpressionConstant, -100, 700)
    k32.set_editor_property("r", 32.0)
    uvm = mel.create_material_expression(mat, unreal.MaterialExpressionMultiply, 0, 650)
    mel.connect_material_expressions(uvl, "", uvm, "A")
    mel.connect_material_expressions(k32, "", uvm, "B")
    uvf = mel.create_material_expression(mat, unreal.MaterialExpressionFrac, 120, 650)
    mel.connect_material_expressions(uvm, "", uvf, "")
    mel.connect_material_expressions(uvf, "", uvcol, "A")
    mel.connect_material_expressions(zero, "", uvcol, "B")
    out = mel.create_material_expression(mat, unreal.MaterialExpressionLinearInterpolate, 500, 300)
    mel.connect_material_expressions(mul3, "", out, "A")
    mel.connect_material_expressions(uvcol, "", out, "B")
    mel.connect_material_expressions(show, "", out, "Alpha")
    mel.connect_material_property(out, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
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


def _suppress_interchange_slate_sync():
    # Interchange.FeatureFlags.Import.SyncToBrowser overrides ImportAssetTasks' bSyncToBrowser=false
    # and drives SyncBrowserToAssets → FSlateApplication::Get(), which asserts under
    # -run=pythonscript. Also set in DefaultEngine.ini and ue_run.py's shim.
    unreal.SystemLibrary.execute_console_command(
        None, "Interchange.FeatureFlags.Import.SyncToBrowser 0")


def _import_lightmaps(pngs):
    """One batched import of every missing lightmap."""
    _suppress_interchange_slate_sync()
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
        try:
            task.factory = unreal.TextureFactory()
        except Exception:
            pass
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
        # WORLD, not LIGHTMAP: the Lightmap group is meant for UE's own baked lightmaps.
        tex.set_editor_property("lod_group", unreal.TextureGroup.TEXTUREGROUP_WORLD)
        tex.set_editor_property("never_stream", True)
        tex.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_HDR)
        eal.save_loaded_asset(tex)
    return tex


def _invisible_material():
    """/Game/BioShockLive/M_BakedInvisible: masked, opacity mask 0 - draws nothing."""
    path = "/Game/BioShockLive/M_BakedInvisible"
    if eal.does_asset_exist(path):
        return eal.load_asset(path)
    lib = unreal.MaterialEditingLibrary
    mat = assets.create_asset("M_BakedInvisible", "/Game/BioShockLive", unreal.Material, unreal.MaterialFactoryNew())
    mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_MASKED)
    zero = lib.create_material_expression(mat, unreal.MaterialExpressionConstant, -300, 0)
    zero.set_editor_property("r", 0.0)
    lib.connect_material_property(zero, "", unreal.MaterialProperty.MP_OPACITY_MASK)
    lib.recompile_material(mat)
    eal.save_asset(path)
    return mat


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
    if SWAP_UV:
        for p in prims:
            a = p["attributes"]
            if "TEXCOORD_0" in a and "TEXCOORD_1" in a:
                a["TEXCOORD_0"], a["TEXCOORD_1"] = a["TEXCOORD_1"], a["TEXCOORD_0"]
    _to_gltf_convention(doc, os.path.dirname(gltf_path), model_name)
    slotted = os.path.join(os.path.dirname(gltf_path), "%s_slots.gltf" % model_name)
    with open(slotted, "w", encoding="utf-8") as fh:
        json.dump(doc, fh)

    name = "SM_%s_Baked" % model_name
    existing = _find_mesh(model_name)
    # BIOSHOCK_BAKED_REIMPORT=1: import over the existing mesh (the export changed, e.g. new UVs).
    if existing is not None and os.environ.get("BIOSHOCK_BAKED_REIMPORT") != "1":
        return _ordered_slots(existing, slots)
    _suppress_interchange_slate_sync()
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


def _to_gltf_convention(doc, folder, model_name):
    """Rewrite POSITION/NORMAL from UE space (cm, Z-up) into glTF space (m, Y-up) in a new .bin.

    The export writes UE coordinates (same as the BuiltWorld OBJ), but UE's glTF importer converts
    from glTF convention (m, Y-up). Measured 6 Oct 2026 by comparing mesh bounds against the compiled
    world: writing (X/100, Z/100, -Y/100) lands every vertex where it belongs. That is a rotation
    (determinant +1), so triangle winding is unchanged.
    """
    src = doc["buffers"][0]["uri"]
    with open(os.path.join(folder, src), "rb") as fh:
        data = bytearray(fh.read())
    done = set()
    for m in doc["meshes"]:
        for p in m["primitives"]:
            for attr, scale in (("POSITION", 0.01), ("NORMAL", 1.0)):
                ai = p["attributes"].get(attr)
                if ai is None or ai in done:
                    continue
                done.add(ai)
                acc = doc["accessors"][ai]
                view = doc["bufferViews"][acc["bufferView"]]
                stride = view.get("byteStride") or 12
                base = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
                lo, hi = [1e30] * 3, [-1e30] * 3
                for k in range(acc["count"]):
                    o = base + k * stride
                    x, y, z = struct.unpack_from("<3f", data, o)
                    v = (x * scale, z * scale, -y * scale)
                    struct.pack_into("<3f", data, o, *v)
                    lo = [min(a, b) for a, b in zip(lo, v)]
                    hi = [max(a, b) for a, b in zip(hi, v)]
                if attr == "POSITION":
                    acc["min"], acc["max"] = lo, hi
            # No V flip: measured in the imported mesh data, the lightmap UVs hit lit atlas texels 74%
            # of the time as exported and 28% when flipped -- UE's glTF importer keeps V as written
            # (6 Oct 2026; an earlier pre-flip, from a bad inference, is what made the world black).
    out = "%s_slots.bin" % model_name
    with open(os.path.join(folder, out), "wb") as fh:
        fh.write(data)
    doc["buffers"][0]["uri"] = out


def _find_mesh(model_name):
    for path in eal.list_assets(DEST, recursive=True):
        if "SM_%s_Baked" % model_name in path:
            obj = eal.load_asset(path)
            if isinstance(obj, unreal.StaticMesh):
                return obj
    return None


def _ordered_slots(mesh, slots):
    # The import builds with "Generate Lightmap UVs" on (destination channel 1), which replaces our
    # baked-light UV1 in the RENDER data while the source description keeps it -- the lightmap then
    # samples atlas padding and the world renders black (6 Oct 2026). Turn it off and rebuild.
    lib = unreal.get_editor_subsystem(unreal.StaticMeshEditorSubsystem) or unreal.EditorStaticMeshLibrary
    lib.set_generate_lightmap_uv(mesh, False)
    eal.save_loaded_asset(mesh)
    # get_num_uv_channels reports 0 under -run=pythonscript even for channel 0, so check the data:
    # sampled UV1 must exist, lie in 0..1 and differ from UV0 (the material UV).
    desc = mesh.get_static_mesh_description(0)
    n = desc.get_vertex_instance_count()
    step = max(1, n // 400)
    lm_ch, mat_ch = (0, 1) if SWAP_UV else (1, 0)
    uv1 = [desc.get_vertex_instance_uv(unreal.VertexInstanceID(k), lm_ch) for k in range(0, n, step)]
    uv0 = [desc.get_vertex_instance_uv(unreal.VertexInstanceID(k), mat_ch) for k in range(0, n, step)]
    nonzero = sum(1 for u in uv1 if abs(u.x) > 1e-6 or abs(u.y) > 1e-6)
    inrange = sum(1 for u in uv1 if -1e-3 <= u.x <= 1.001 and -1e-3 <= u.y <= 1.001)
    differ = sum(1 for a, b in zip(uv0, uv1) if abs(a.x - b.x) > 1e-4 or abs(a.y - b.y) > 1e-4)
    unreal.log("BAKED_UV1 sampled=%d nonzero=%d inrange=%d differFromUV0=%d" % (len(uv1), nonzero, inrange, differ))
    if nonzero < len(uv1) * 0.5 or inrange < len(uv1) * 0.95:
        raise RuntimeError("lightmap UV (channel %d) did not survive import" % lm_ch + "  (nonzero %d, in range %d of %d)" % (nonzero, inrange, len(uv1)))
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
    pngs = [os.path.join(DIR, f) for f in sorted(os.listdir(DIR)) if f.startswith("baked_") and f.endswith(".png")]
    _import_lightmaps(pngs)
    master = _ensure_master(_import_lightmap(pngs[0]) if pngs else None)
    mesh, slots = _import_mesh(os.path.join(DIR, gltfs[0]), model_name)

    report = {"slots": len(slots), "lightmaps": {}, "missingBaseColor": [], "hiddenSlots": []}
    lm_cache = {}
    invisible = None
    for i, (slot, extras) in enumerate(slots):
        # Surfaces with no material, and zoning-only brushes, are never drawn by the game (portals,
        # zone boundaries); rendered with a default texture they showed as a blue grid on Medical's
        # walls and ceilings (7 Oct 2026). Hide them.
        mat_name = extras.get("material")
        if not mat_name or mat_name == "ZoningOnlyBrushMaterial":
            invisible = invisible or _invisible_material()
            mesh.set_material(i, invisible)
            report["hiddenSlots"].append(slot)
            continue
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
