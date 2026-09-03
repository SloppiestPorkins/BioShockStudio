"""Export the imported compiled-world StaticMesh back to OBJ so its UVs can be read directly and
compared against the source. Answers: did the importer keep the UVs we exported?

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/dump_imported_mesh_obj.py \
    -unattended -nopause -nosplash -nullrhi
"""
import os, unreal

MESH = "/Game/BioShockSlice/Content/Meshes/Model1_20761"
OUT_DIR = os.path.join(os.environ["TEMP"], "imported_mesh_dump")
os.makedirs(OUT_DIR, exist_ok=True)

mesh = unreal.load_asset(MESH)
task = unreal.AssetExportTask()
task.object = mesh
task.filename = os.path.join(OUT_DIR, "Model1_imported.obj")
task.automated = True
task.prompt = False
task.exporter = unreal.ObjectExporterOBJ() if hasattr(unreal, "ObjectExporterOBJ") else None
ok = unreal.Exporter.run_asset_export_task(task) if hasattr(unreal, "Exporter") else False
unreal.log(f"[dump-mesh] export ok={ok} -> {task.filename}  exists={os.path.exists(task.filename)}")

# Fallback: FBX
if not os.path.exists(task.filename):
    t2 = unreal.AssetExportTask()
    t2.object = mesh
    t2.filename = os.path.join(OUT_DIR, "Model1_imported.fbx")
    t2.automated = True
    t2.prompt = False
    unreal.Exporter.run_asset_export_task(t2)
    unreal.log(f"[dump-mesh] fbx fallback exists={os.path.exists(t2.filename)}")
