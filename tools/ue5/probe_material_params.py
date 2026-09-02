"""Dump the parameters of named material instances, and what their master exposes.

Written for the light-beam materials. They are BLEND_ADDITIVE, so they add their full brightness
to whatever is behind them - with a bright diffuse and no intensity control they saturate to white
and swallow whole corners of the frame. Before dimming them, find out which knob exists: a scalar
on the instance, a vector tint, or nothing at all (in which case the master needs the parameter
before an instance can be tuned).

Read-only. Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_material_params.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_MATPROBE_NAMES  comma-separated substrings to match (default "Light_Beam,bloodsplat")
     BIOSHOCK_MATPROBE_ROOTS  comma-separated content roots to search
"""

from __future__ import annotations

import json
import os

import unreal

NAMES = [n.strip().lower() for n in os.environ.get(
    "BIOSHOCK_MATPROBE_NAMES", "Light_Beam,bloodsplat").split(",") if n.strip()]
ROOTS = [r.strip() for r in os.environ.get(
    "BIOSHOCK_MATPROBE_ROOTS",
    "/Game/BioShockLevel,/Game/BioShockSlice").split(",") if r.strip()]
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "probe_material_params.json")


def _describe(mi):
    entry = {"path": mi.get_path_name(), "class": type(mi).__name__}
    base = mi
    if isinstance(mi, unreal.MaterialInstance):
        parent = mi.get_editor_property("parent")
        entry["parent"] = parent.get_path_name() if parent is not None else None
        if parent is not None:
            base = parent
    for prop, key in (("blend_mode", "blend"), ("two_sided", "twoSided"),
                      ("shading_model", "shadingModel")):
        try:
            entry[key] = str(base.get_editor_property(prop))
        except Exception:  # noqa: BLE001
            pass

    lib = unreal.MaterialEditingLibrary
    if isinstance(mi, unreal.MaterialInstanceConstant):
        for kind, getter in (("scalar", lib.get_scalar_parameter_names),
                             ("vector", lib.get_vector_parameter_names),
                             ("texture", lib.get_texture_parameter_names)):
            try:
                names = [str(n) for n in (getter(mi) or [])]
            except Exception as exc:  # noqa: BLE001
                entry["%sParams" % kind] = "unreadable: %s" % exc
                continue
            values = {}
            for name in names:
                try:
                    if kind == "scalar":
                        values[name] = round(
                            lib.get_material_instance_scalar_parameter_value(mi, name), 4)
                    elif kind == "vector":
                        c = lib.get_material_instance_vector_parameter_value(mi, name)
                        values[name] = [round(c.r, 3), round(c.g, 3), round(c.b, 3), round(c.a, 3)]
                    else:
                        t = lib.get_material_instance_texture_parameter_value(mi, name)
                        values[name] = t.get_name() if t is not None else None
                except Exception as exc:  # noqa: BLE001
                    values[name] = "unreadable: %s" % exc
            entry["%sParams" % kind] = values
    return entry


def main():
    report = {"names": NAMES, "roots": ROOTS, "materials": []}
    registry = unreal.AssetRegistryHelpers.get_asset_registry()
    seen = set()
    for root in ROOTS:
        for data in registry.get_assets_by_path(unreal.Name(root), recursive=True):
            name = str(data.asset_name)
            if not any(n in name.lower() for n in NAMES):
                continue
            path = str(data.package_name)
            if path in seen:
                continue
            seen.add(path)
            asset = unreal.EditorAssetLibrary.load_asset(path)
            if isinstance(asset, unreal.MaterialInterface):
                report["materials"].append(_describe(asset))

    report["found"] = len(report["materials"])
    _write(report)
    unreal.log("[matprobe] found=%d" % report["found"])
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
