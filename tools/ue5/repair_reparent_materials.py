"""Re-parent every level material instance to the master its CURRENT manifest kind implies.

After the exporter's opacity guard (fb277d2) and the bMasked fix (c2555a9), many materials
change rendering kind (mask -> opaque/translucent). The imported MI_ stays parented to the
stale master, so a wall panel keeps BLEND_MASKED with its diffuse alpha wired as a cutout and
speckles. This loads the already-imported textures (no re-import -- fast, no Interchange) and
re-parents. Idempotent.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_reparent_materials.py \n    -unattended -nopause -nosplash
Env: BIOSHOCK_REPARENT_MANIFEST, BIOSHOCK_REPARENT_CONTENT_ROOT (defaults target the slice)
"""
import os, sys, json, traceback
sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")
import unreal
import import_bioshock as ib

CONTENT = "/Game/BioShockSlice/Content"
DEST = CONTENT + "/1-Medical"
MANIFEST = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json"
OUT = os.path.join(os.environ["TEMP"], "reparent_materials.json")
res = {"error": None, "reparented": 0, "unchanged": 0, "missing": 0, "changes": []}
lib = unreal.MaterialEditingLibrary

def load_tex(filerel):
    if not filerel: return None
    stem = os.path.splitext(os.path.basename(filerel))[0]
    for base in (DEST, CONTENT):
        for sub in ("Textures", "CubemapFaces"):
            p = "%s/%s/%s" % (base, sub, stem)
            if unreal.EditorAssetLibrary.does_asset_exist(p):
                return unreal.EditorAssetLibrary.load_asset(p)
    return None

try:
    manifest = json.load(open(MANIFEST, encoding="utf-8"))
    for m in manifest.get("materials") or []:
        stem = ib._safe_name(m.get("name") or "")
        mi_path = "%s/Materials/MI_%s" % (DEST, stem)
        if not unreal.EditorAssetLibrary.does_asset_exist(mi_path):
            mi_path = "%s/Materials/MI_%s" % (CONTENT, stem)
            if not unreal.EditorAssetLibrary.does_asset_exist(mi_path):
                res["missing"] += 1; continue
        mi = unreal.EditorAssetLibrary.load_asset(mi_path)
        if not isinstance(mi, unreal.MaterialInstanceConstant):
            res["missing"] += 1; continue

        old_parent = mi.get_editor_property("parent")
        old_name = old_parent.get_name() if old_parent else "(none)"

        diffuse = load_tex(m.get("diffuse"))
        normal = load_tex(m.get("normalMap"))
        opacity = load_tex(m.get("opacity"))
        new_master = ib._load_or_create_master(
            m, CONTENT, diffuse_texture=diffuse, normal_texture=normal,
            opacity_texture=opacity, rig={})
        if new_master is None:
            res["missing"] += 1; continue

        if old_parent is not None and old_parent.get_name() == new_master.get_name():
            res["unchanged"] += 1
            continue

        mi.set_editor_property("parent", new_master)
        if diffuse is not None:
            lib.set_material_instance_texture_parameter_value(mi, "BaseColor", diffuse)
        if normal is not None:
            lib.set_material_instance_texture_parameter_value(mi, "Normal", normal)
        if opacity is not None and m.get("opacity"):
            lib.set_material_instance_texture_parameter_value(mi, "OpacityMask", opacity)
        unreal.EditorAssetLibrary.save_loaded_asset(mi)
        res["reparented"] += 1
        if len(res["changes"]) < 40:
            res["changes"].append("%s: %s -> %s" % (m.get("name"), old_name, new_master.get_name()))
except Exception as exc:
    res["error"] = str(exc); res["traceback"] = traceback.format_exc()

with open(OUT, "w") as h: json.dump(res, h, indent=2, default=str)
unreal.log("[reparent] reparented=%d unchanged=%d missing=%d" % (res["reparented"], res["unchanged"], res["missing"]))
