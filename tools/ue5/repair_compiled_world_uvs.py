"""Re-import ONLY the compiled-world OBJ (corrected BSP UVs) and re-bind its material slots
from the MI_ assets already on disk. No texture / rig / actor / cubemap import -- none of the
headless-hang paths. Use after re-exporting a level with BIOSHOCK_ORIGINAL_TEXTURE_DIR set.

Pipeline: one-off -- the exporter now writes corrected BSP UVs, so a normal re-import is right;
this patched an earlier import.
"""
import os, sys, json, traceback
sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")
import unreal
import import_bioshock, import_level

CONTENT = "/Game/BioShockSlice/Content"
SLICE_DIR = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical"
MANIFEST = os.path.join(SLICE_DIR, "1-Medical.ue5-level.json")
DEST = CONTENT + "/1-Medical"
OUT = os.path.join(os.environ["TEMP"], "reimport_cw.json")
res = {"error": None, "steps": []}
try:
    manifest = json.load(open(MANIFEST, encoding="utf-8"))
    # mats_by_key from existing MI_ assets, no import
    mats = {}
    for m in manifest.get("materials") or []:
        stem = import_bioshock._safe_name(m.get("name") or "")
        for path in ("%s/Materials/MI_%s" % (DEST, stem), "%s/Materials/MI_%s" % (CONTENT, stem)):
            if unreal.EditorAssetLibrary.does_asset_exist(path):
                a = unreal.EditorAssetLibrary.load_asset(path)
                if a is not None:
                    mats[m["key"]] = a
                break
    res["steps"].append("MI_ assets loaded: %d / %d" % (len(mats), len(manifest.get("materials") or [])))

    mesh_dir = os.path.join(SLICE_DIR, "Meshes")
    model = next((f for f in os.listdir(mesh_dir) if f.startswith("Model1_") and f.endswith(".obj")), None)
    stem = os.path.splitext(model)[0]
    ap = "%s/Meshes/%s" % (CONTENT, stem)
    if unreal.EditorAssetLibrary.does_asset_exist(ap):
        unreal.EditorAssetLibrary.delete_asset(ap)
    t = unreal.AssetImportTask()
    t.set_editor_property("filename", os.path.join(mesh_dir, model))
    t.set_editor_property("destination_path", "%s/Meshes" % CONTENT)
    t.set_editor_property("automated", True)
    t.set_editor_property("replace_existing", True)
    t.set_editor_property("save", False)
    import_bioshock._asset_tools().import_asset_tasks([t])
    mesh = next((o for o in t.get_objects() if isinstance(o, unreal.StaticMesh)), None)
    res["steps"].append("mesh re-imported: %s  sections=%s" %
                        (mesh.get_name() if mesh else "FAILED",
                         mesh.get_num_sections(0) if mesh else "-"))
    if mesh:
        report = {}
        cw = next((a for a in manifest.get("assets") or [] if a.get("name") == "Model1"), None)
        import_level._assign_asset_material(mesh, cw, mats, report)
        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        res["steps"].append("assigned: %s" % json.dumps(report))
    res["saved"] = True
except Exception as exc:
    res["error"] = str(exc); res["traceback"] = traceback.format_exc()
with open(OUT, "w") as h: json.dump(res, h, indent=2, default=str)
unreal.log("[reimport-cw] " + json.dumps({k: v for k, v in res.items() if k != "traceback"}, default=str))
