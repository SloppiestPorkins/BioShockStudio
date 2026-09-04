"""Re-import ONLY the compiled-world OBJ into the slice and rebind its 67 material slots from the
MI_ assets already on disk. No level load, no delete_asset, no master recompile, no texture/rig
import -- none of the slow or headless-hang paths.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/reimport_compiled_world_only.py \
    -unattended -nopause -nosplash -nullrhi

COLLISION: `replace_existing=True` on a plain OBJ AssetImportTask resets the mesh to
CTF_USE_DEFAULT and auto-generates a convex hull -- for an 18,735-triangle level shell, one solid
blob enclosing the whole level (verify_collision.py's docstring documents the first time this
shipped as a regression; it shipped again from this exact script 4 Sept 2026, since nothing here
re-applied the fix after import). Re-set complex-as-simple every time, not just once.
"""
import os, sys, json, traceback
sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")
import unreal
import import_bioshock as ib
import import_level


def _use_complex_collision(mesh):
    """Trace level architecture against its own triangles, not an auto convex hull.

    Same fix as fix_compiled_world_materials.py's _use_complex_collision -- duplicated rather than
    imported so this script keeps its "no other module's import side effects" property.
    """
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False
    body.set_editor_property(
        "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
    try:
        agg = body.get_editor_property("agg_geom")
        agg.set_editor_property("convex_elems", [])
        agg.set_editor_property("box_elems", [])
        agg.set_editor_property("sphere_elems", [])
        body.set_editor_property("agg_geom", agg)
    except Exception as exc:  # noqa: BLE001 - the trace flag is the part that matters
        unreal.log_warning("[reimport-cw] could not clear simple collision: %s" % exc)
    return True

CONTENT = os.environ.get("BIOSHOCK_REIMPORT_CONTENT", "/Game/BioShockSlice/Content")
DEST = os.environ.get("BIOSHOCK_REIMPORT_DEST", CONTENT + "/1-Medical")
SLICE_DIR = os.environ.get("BIOSHOCK_REIMPORT_SRCDIR",
                           r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical")
MANIFEST = os.path.join(SLICE_DIR, "1-Medical.ue5-level.json")
OUT = os.path.join(os.environ["TEMP"], "reimport_compiled_world_only.json")
res = {"error": None, "steps": []}

try:
    manifest = json.load(open(MANIFEST, encoding="utf-8"))

    mats = {}
    for m in manifest.get("materials") or []:
        stem = ib._safe_name(m.get("name") or "")
        for p in ("%s/Materials/MI_%s" % (DEST, stem), "%s/Materials/MI_%s" % (CONTENT, stem)):
            if unreal.EditorAssetLibrary.does_asset_exist(p):
                a = unreal.EditorAssetLibrary.load_asset(p)
                if isinstance(a, unreal.MaterialInstanceConstant):
                    mats[m["key"]] = a
                break
    res["steps"].append("materials loaded: %d" % len(mats))

    mesh_dir = os.path.join(SLICE_DIR, "Meshes")
    model = next((f for f in os.listdir(mesh_dir) if f.startswith("Model1_") and f.endswith(".obj")), None)
    t = unreal.AssetImportTask()
    t.set_editor_property("filename", os.path.join(mesh_dir, model))
    t.set_editor_property("destination_path", "%s/Meshes" % CONTENT)
    t.set_editor_property("automated", True)
    t.set_editor_property("replace_existing", True)
    t.set_editor_property("save", False)
    ib._asset_tools().import_asset_tasks([t])
    mesh = next((o for o in t.get_objects() if isinstance(o, unreal.StaticMesh)), None)
    res["steps"].append("mesh: %s sections=%s" %
                        (mesh.get_name() if mesh else "FAILED",
                         mesh.get_num_sections(0) if mesh else "-"))
    if mesh:
        report = {}
        cw = next((a for a in manifest.get("assets") or [] if a.get("name") == "Model1"), None)
        import_level._assign_asset_material(mesh, cw, mats, report)
        collision_ok = _use_complex_collision(mesh)
        res["steps"].append("collision: complex-as-simple ok=%s" % collision_ok)
        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        res["steps"].append("assigned: %s" % json.dumps(report))
    res["saved"] = True
except Exception as exc:
    res["error"] = str(exc)
    res["traceback"] = traceback.format_exc()

with open(OUT, "w") as h:
    json.dump(res, h, indent=2, default=str)
unreal.log("[reimport-cw] " + json.dumps({k: v for k, v in res.items() if k != "traceback"}, default=str))
