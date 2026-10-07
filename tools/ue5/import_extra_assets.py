"""Import specific exported meshes the live renderer's stand-ins need but the project lacks.

Static meshes (OBJ) go to /Game/BioShockLive/ExtraMeshes/<name>_<exportIndex>, with each section's
material set to the existing MI_<material> when there is one. Skeletal meshes (rig folders) go
through import_bioshock under /Game/BioShockCharacters/<name>/ WITHOUT animations -- the live bridge
streams the game's evaluated bones, so baked animation assets are not needed.

The bridge finds them by asset name minus the "_<exportIndex>" suffix (static) or by folder (skeletal).

Env:
  BIOSHOCK_EXTRA_DIR       export root containing Meshes/ and Rigs/
  BIOSHOCK_EXTRA_MANIFEST  JSON with an "assets" array (a level manifest or export-assets' assets.json)
  BIOSHOCK_EXTRA_NAMES     comma-separated game mesh names to import

Run: python tools/ue5/ue_run.py tools/ue5/import_extra_assets.py --timeout 3600 (headless imports assert in
Slate after saving; rerun until it reports done -- existing assets are skipped).

Pipeline: entry-point -- live-renderer content.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_bioshock  # noqa: E402
import import_level  # noqa: E402

DIR = os.environ["BIOSHOCK_EXTRA_DIR"]
MANIFEST = os.environ["BIOSHOCK_EXTRA_MANIFEST"]
NAMES = [n.strip() for n in os.environ["BIOSHOCK_EXTRA_NAMES"].split(",") if n.strip()]
STATIC_DEST = "/Game/BioShockLive/ExtraMeshes"
CHAR_ROOT = "/Game/BioShockCharacters"
MI_DIRS = ["/Game/BioShockLevel/1-Medical/Materials", "/Game/BioShockSlice/Content/1-Medical/Materials",
           "/Game/BioShockSlice/Content/Meshes/PropMat"]
eal = unreal.EditorAssetLibrary


def _mi(name):
    for d in MI_DIRS:
        path = "%s/MI_%s" % (d, name)
        if eal.does_asset_exist(path):
            return eal.load_asset(path)
    return None


def main():
    with open(MANIFEST, encoding="utf-8") as fh:
        assets = json.load(fh).get("assets") or []
    report = {}
    for name in NAMES:
        asset = next((a for a in assets if a.get("name") == name), None)
        rig_dir = os.path.join(DIR, "Rigs", name)
        if os.path.isdir(rig_dir):
            folder = "%s/%s" % (CHAR_ROOT, name)
            if any(isinstance(eal.load_asset(p), unreal.SkeletalMesh) for p in eal.list_assets(folder, recursive=True)) \
                    if eal.does_directory_exist(folder) else False:
                report[name] = "skeletal: already present"
                continue
            import_bioshock.main(rig_dir, content_root=CHAR_ROOT, rig_name_override=name, import_animations=False)
            report[name] = "skeletal: imported"
            continue
        if asset and asset.get("file"):
            stem = os.path.splitext(os.path.basename(asset["file"]))[0]
            path = "%s/%s" % (STATIC_DEST, stem)
            mesh = eal.load_asset(path) if eal.does_asset_exist(path) else import_level._import_static_mesh_obj(
                os.path.join(DIR, asset["file"]), STATIC_DEST, stem)
            if mesh is None:
                report[name] = "static: import failed"
                continue
            applied = 0
            for i, section in enumerate(asset.get("sections") or []):
                mi = _mi(section.get("material") or "")
                if mi is not None and i < len(mesh.get_editor_property("static_materials")):
                    mesh.set_material(i, mi)
                    applied += 1
            eal.save_loaded_asset(mesh)
            report[name] = "static: %s (%d materials)" % (stem, applied)
            continue
        report[name] = "not in this export"
    unreal.log("EXTRA_ASSETS done %s" % json.dumps(report))


main()
