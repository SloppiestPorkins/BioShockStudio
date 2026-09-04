"""Repair masters already imported with a BaseColor-alpha-as-Opacity wire that should never have
been made -- see import_bioshock._repair_translucent_alpha_opacity's own docstring for the full
root cause (outputBlending 1/2 alone used to be enough to classify a material "translucent" and
sample its diffuse texture's Alpha into Opacity, even when that material's own data says the alpha
is NOT real coverage -- declaresAlphaTexture False, packed spec/gloss data instead). User-reported
(4 Sept 2026): "wall leak" and "reinforced glass" reading as missing -- both are exactly this: their
diffuse alpha averages ~15-25%, so the whole surface renders almost fully transparent.

The import_bioshock.py fix (both the create-path and _repair_translucent_alpha_opacity on the
reuse-path) is now in place for any FUTURE import, but existing masters in the live project were
created before it and won't self-heal without a reimport. Rather than re-running the full,
heavy import_level pipeline (re-touches geometry/collision/mobility for the whole map -- the exact
class of regression this session has repeatedly had to fix), this drives the same repair function
directly against every master already on disk, scoped to materials only.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_translucent_alpha_opacity.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_OPACITY_RIG     path to the map's *.ue5-level.json (default: 1-Medical's)
  BIOSHOCK_OPACITY_ROOT    content root the masters live under (default /Game/BioShockSlice/Content)
"""
import json, os, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_bioshock

RIG_PATH = os.environ.get(
    "BIOSHOCK_OPACITY_RIG",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
)
CONTENT_ROOT = os.environ.get("BIOSHOCK_OPACITY_ROOT", "/Game/BioShockSlice/Content")
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_translucent_alpha_opacity.json")


def _master_path(material, rig):
    kind = import_bioshock._material_rendering_kind(material, rig)
    two_sided = bool(material.get("twoSided"))
    name_lower = (material.get("name") or "").lower()
    if kind == "translucent" and (
            "window" in name_lower or "glass" in name_lower
            or (material.get("className") or "") == "WindowShader"):
        two_sided = True
    suffix = "_%s" % kind
    if two_sided:
        suffix += "_TwoSided"
    name = "M_BioShock_%s_%s%s_V5" % (
        import_bioshock._safe_name(material.get("className") or "Material"),
        import_bioshock._safe_name(material.get("name") or "Material"), suffix)
    return "%s/Materials/Masters/%s" % (CONTENT_ROOT, name), kind


def main():
    with open(RIG_PATH, "r", encoding="utf-8") as handle:
        rig = json.load(handle)

    report = {"rig": RIG_PATH, "checked": 0, "candidates": [], "fixed": [], "notFound": []}
    for material in rig.get("materials") or []:
        report["checked"] += 1
        kind = import_bioshock._material_rendering_kind(material, rig)
        if kind != "translucent":
            continue
        if import_bioshock._material_declares_alpha_texture(material, rig):
            continue
        path, _ = _master_path(material, rig)
        report["candidates"].append({"material": material.get("name"), "master": path})
        master = import_bioshock._load_if_exists(path)
        if master is None:
            report["notFound"].append({"material": material.get("name"), "master": path})
            continue
        changed = import_bioshock._repair_translucent_alpha_opacity(master, material, rig)
        if changed:
            report["fixed"].append({"material": material.get("name"), "master": path})

    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2, default=str)
    unreal.log("[translucent-alpha-opacity-fix] wrote %s (%d fixed / %d candidates)" % (
        OUT, len(report["fixed"]), len(report["candidates"])))
    return report


if __name__ == "__main__":
    main()
