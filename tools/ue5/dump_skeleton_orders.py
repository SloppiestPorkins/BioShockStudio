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
    names = unreal.AnimPoseExtensions.get_bone_names(pose)
    xf = [unreal.AnimPoseExtensions.get_bone_pose(pose, n, unreal.AnimPoseSpaces.WORLD) for n in names]
    world = [t.translation for t in xf]
    quats = [t.rotation for t in xf]
    out[path] = {"skeleton": skel.get_path_name(), "bones": [str(n) for n in names],
                 "ref_world": [[round(v.x, 2), round(v.y, 2), round(v.z, 2)] for v in world],
                 "ref_world_q": [[round(q.x, 5), round(q.y, 5), round(q.z, 5), round(q.w, 5)] for q in quats]}
json.dump(out, open(OUT, "w"), indent=1)
unreal.log("SKELETON_ORDERS %d meshes -> %s" % (len(out), OUT))
