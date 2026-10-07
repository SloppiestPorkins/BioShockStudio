"""Dump every skeletal mesh's bone order (as the live bridge indexes it) to JSON, so it can be
compared offline with the game's Havok order (Exports/live/_bones/bone_orders.json).

Run: python tools/ue5/ue_run.py tools/ue5/dump_skeleton_orders.py

Pipeline: diagnostic -- live-renderer skeletal stand-ins.
"""
import json
import os

import unreal

OUT = os.path.join(os.environ.get("TEMP", "."), "ue_skeleton_orders.json")
reg = unreal.AssetRegistryHelpers.get_asset_registry()
reg.search_all_assets(True)
flt = unreal.ARFilter(class_paths=[unreal.TopLevelAssetPath("/Script/Engine", "SkeletalMesh")], recursive_paths=True,
                      package_paths=["/Game"])
out = {}
for data in reg.get_assets(flt):
    path = str(data.package_name)
    mesh = unreal.EditorAssetLibrary.load_asset(path)
    skel = mesh.get_editor_property("skeleton") if mesh else None
    if not skel:
        continue
    pose = unreal.AnimPoseExtensions.get_reference_pose(skel)
    out[path] = {"skeleton": skel.get_path_name(), "bones": [str(n) for n in unreal.AnimPoseExtensions.get_bone_names(pose)]}
json.dump(out, open(OUT, "w"), indent=1)
unreal.log("SKELETON_ORDERS %d meshes -> %s" % (len(out), OUT))
