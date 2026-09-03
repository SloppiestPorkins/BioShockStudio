"""One headless pass: re-import the compiled-world OBJ with corrected BSP UVs and re-parent every
level material instance to the master its current manifest kind implies (Walltech/carpet off
BLEND_MASKED, blood onto translucent_mask). Loads textures off disk -- no re-import, no hang.

Run:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_walls_and_materials.py \
    -unattended -nopause -nosplash
"""
import os, sys, json, traceback
sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")
import unreal
import import_bioshock as ib
import import_level

CONTENT = "/Game/BioShockSlice/Content"
DEST = CONTENT + "/1-Medical"
SLICE_DIR = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical"
MANIFEST = os.path.join(SLICE_DIR, "1-Medical.ue5-level.json")
OUT = os.path.join(os.environ["TEMP"], "repair_walls_and_materials.json")
res = {"error": None, "steps": []}
lib = unreal.MaterialEditingLibrary

def load_tex(rel):
    if not rel: return None
    stem = os.path.splitext(os.path.basename(rel))[0]
    for base in (DEST, CONTENT):
        for sub in ("Textures", "CubemapFaces"):
            p = "%s/%s/%s" % (base, sub, stem)
            if unreal.EditorAssetLibrary.does_asset_exist(p):
                return unreal.EditorAssetLibrary.load_asset(p)
    return None

try:
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level("/Game/BioShockSlice/1-Medical")
    manifest = json.load(open(MANIFEST, encoding="utf-8"))

    # --- 1. materials: re-parent to the correct-kind master (textures loaded off disk) ---
    mats = {}
    reparented = 0
    for m in manifest.get("materials") or []:
        stem = ib._safe_name(m.get("name") or "")
        mip = None
        for p in ("%s/Materials/MI_%s" % (DEST, stem), "%s/Materials/MI_%s" % (CONTENT, stem)):
            if unreal.EditorAssetLibrary.does_asset_exist(p):
                mip = p; break
        if not mip:
            continue
        mi = unreal.EditorAssetLibrary.load_asset(mip)
        if not isinstance(mi, unreal.MaterialInstanceConstant):
            continue
        mats[m["key"]] = mi
        diffuse = load_tex(m.get("diffuse")); normal = load_tex(m.get("normalMap")); opacity = load_tex(m.get("opacity"))
        old = mi.get_editor_property("parent")
        newm = ib._load_or_create_master(m, CONTENT, diffuse_texture=diffuse, normal_texture=normal,
                                         opacity_texture=opacity, rig={})
        if newm is None:
            continue
        if old is not None and old.get_name() == newm.get_name():
            continue
        mi.set_editor_property("parent", newm)
        if diffuse is not None: lib.set_material_instance_texture_parameter_value(mi, "BaseColor", diffuse)
        if normal is not None: lib.set_material_instance_texture_parameter_value(mi, "Normal", normal)
        if opacity is not None and m.get("opacity"):
            lib.set_material_instance_texture_parameter_value(mi, "OpacityMask", opacity)
        unreal.EditorAssetLibrary.save_loaded_asset(mi)
        reparented += 1
    res["steps"].append("materials: %d loaded, %d re-parented" % (len(mats), reparented))

    # --- 2. compiled-world mesh: delete + re-import Model1_*.obj, re-bind 67 slots ---
    mesh_dir = os.path.join(SLICE_DIR, "Meshes")
    model = next((f for f in os.listdir(mesh_dir) if f.startswith("Model1_") and f.endswith(".obj")), None)
    if model:
        stem = os.path.splitext(model)[0]
        ap = "%s/Meshes/%s" % (CONTENT, stem)
        if unreal.EditorAssetLibrary.does_asset_exist(ap):
            unreal.EditorAssetLibrary.delete_asset(ap)
        t = unreal.AssetImportTask()
        t.set_editor_property("filename", os.path.join(mesh_dir, model))
        t.set_editor_property("destination_path", "%s/Meshes" % CONTENT)
        t.set_editor_property("automated", True); t.set_editor_property("replace_existing", True)
        t.set_editor_property("save", False)
        ib._asset_tools().import_asset_tasks([t])
        mesh = next((o for o in t.get_objects() if isinstance(o, unreal.StaticMesh)), None)
        if mesh:
            cw = next((a for a in manifest.get("assets") or [] if a.get("name") == "Model1"), None)
            rep = {}
            import_level._assign_asset_material(mesh, cw, mats, rep)
            unreal.EditorAssetLibrary.save_loaded_asset(mesh)
            res["steps"].append("compiled world: re-imported, %s" % json.dumps(rep))
        else:
            res["steps"].append("compiled world: IMPORT FAILED")

    world = unreal.EditorLevelLibrary.get_editor_world()
    unreal.EditorLoadingAndSavingUtils.save_map(world, "/Game/BioShockSlice/1-Medical")
    res["saved"] = True
except Exception as exc:
    res["error"] = str(exc); res["traceback"] = traceback.format_exc()
with open(OUT, "w") as h: json.dump(res, h, indent=2, default=str)
unreal.log("[repair-walls] " + json.dumps({k: v for k, v in res.items() if k != "traceback"}, default=str))
