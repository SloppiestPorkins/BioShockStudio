"""Import Exports/live/WhiteAmbient.hdr as /Game/BioShockLive/WhiteAmbientCube (a neutral TextureCube).

The live bridge's zone ambient uses it so the tint the game sends is the colour that lands; the
engine's DefaultCubemap is strongly warm (measured 6 Oct 2026).
Run: python tools/ue5/ue_run.py tools/livegame/import_white_cube.py
"""
import os

import unreal

src = os.path.join(os.path.dirname(unreal.Paths.get_project_file_path()), "Exports", "live", "WhiteAmbient.hdr")
task = unreal.AssetImportTask()
task.filename = src
task.destination_path = "/Game/BioShockLive"
task.destination_name = "WhiteAmbientCube"
task.automated = True
task.replace_existing = True
task.save = True
unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
asset = unreal.load_asset("/Game/BioShockLive/WhiteAmbientCube")
unreal.log("WHITE_CUBE %s %s" % (asset.get_class().get_name() if asset else None, asset.get_path_name() if asset else None))
if not asset or asset.get_class().get_name() != "TextureCube":
    raise RuntimeError("import did not produce a TextureCube")
