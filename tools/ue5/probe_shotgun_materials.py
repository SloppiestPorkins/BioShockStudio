"""Probe WP_Shotgun mesh material slots + bound texture sizes. Writes JSON to TEMP."""
import json
import os
import unreal

OUT = os.path.join(os.environ.get("TEMP", "."), "shotgun_material_probe.json")
MESH = "/Game/BioShockWeapons/WP_Shotgun/WP_Shotgun.WP_Shotgun"
report = {"mesh": MESH, "slots": [], "failures": []}

mesh = unreal.EditorAssetLibrary.load_asset(MESH)
if mesh is None:
    report["failures"].append("mesh missing")
else:
    mats = mesh.get_editor_property("materials") or []
    edit = unreal.MaterialEditingLibrary
    for i, slot in enumerate(mats):
        mat = slot.get_editor_property("material_interface") if hasattr(slot, "get_editor_property") else None
        # UE5 SkeletalMesh materials can be a list of MaterialInterface directly on some builds
        if mat is None and isinstance(slot, unreal.MaterialInterface):
            mat = slot
        entry = {"index": i, "material": mat.get_path_name() if mat else None}
        if isinstance(mat, unreal.MaterialInstanceConstant):
            for pname in ("BaseColor", "Normal", "Specular", "Roughness"):
                tex = edit.get_material_instance_texture_parameter_value(mat, pname)
                if tex:
                    entry[pname] = {
                        "path": tex.get_path_name(),
                        "w": tex.blueprint_get_size_x() if hasattr(tex, "blueprint_get_size_x") else None,
                        "h": tex.blueprint_get_size_y() if hasattr(tex, "blueprint_get_size_y") else None,
                        "srgb": bool(tex.get_editor_property("srgb")),
                    }
        report["slots"].append(entry)

# Also list texture assets on disk under WP_Shotgun/Textures
tex_root = "/Game/BioShockWeapons/WP_Shotgun/Textures"
report["textureAssets"] = []
for path in unreal.EditorAssetLibrary.list_assets(tex_root, recursive=False, include_folder=False) or []:
    tex = unreal.EditorAssetLibrary.load_asset(path)
    if isinstance(tex, unreal.Texture2D):
        report["textureAssets"].append({
            "path": path,
            "w": tex.blueprint_get_size_x(),
            "h": tex.blueprint_get_size_y(),
            "srgb": bool(tex.get_editor_property("srgb")),
        })

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)
unreal.log("[shotgun-probe] wrote %s" % OUT)
