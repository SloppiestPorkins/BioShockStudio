"""Dump the UV path feeding the base-color texture sample of a master material: the sample
node itself, whatever expression is wired into its Coordinates input (a TextureCoordinate node's
UTiling/VTiling, a Multiply, etc.), and one more hop back if that's not a TextureCoordinate.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_master_graph.py \
    -unattended -nopause -nosplash -nullrhi
"""
import os, json, unreal

TARGETS = [
    "/Game/BioShockSlice/Content/Materials/Masters/M_BioShock_Shader_med_wall_public_shader_opaque_V5",
    "/Game/BioShockSlice/Content/Materials/Masters/M_BioShock_Shader_medical_pillar_texture_opaque_V5",
]
OUT = os.path.join(os.environ["TEMP"], "probe_master_graph.json")

_PROPS = (
    "parameter_name", "coordinate_index", "u_tiling", "v_tiling",
    "const_a", "const_b", "const", "default_value", "texture", "sampler_type",
    "r", "g", "b", "const_r", "const_g", "const_b",
)


def _dump_expr(ex, depth):
    if ex is None:
        return None
    d = {"type": ex.get_class().get_name(), "depth": depth}
    for prop in _PROPS:
        try:
            v = ex.get_editor_property(prop)
        except Exception:
            continue
        if v is None:
            continue
        d[prop] = v.get_name() if hasattr(v, "get_name") else str(v)
    if depth > 0:
        return d
    # Follow the Coordinates input one or two hops back, whatever the expression exposes.
    for input_prop in ("coordinates", "input", "a", "b"):
        try:
            fexpr_input = ex.get_editor_property(input_prop)
        except Exception:
            continue
        upstream = getattr(fexpr_input, "expression", None)
        if upstream is not None:
            d.setdefault("inputs", {})[input_prop] = _dump_expr(upstream, depth + 1)
    return d


res = {}
for path in TARGETS:
    m = unreal.load_asset(path)
    if m is None:
        alt = path.replace("/Content/Materials/", "/Materials/")
        m = unreal.load_asset(alt)
    if m is None:
        res[path] = {"error": "not found"}
        continue

    entry = {
        "path": m.get_path_name(),
        "blend_mode": str(m.get_editor_property("blend_mode")),
        "two_sided": bool(m.get_editor_property("two_sided")),
    }
    try:
        node = unreal.MaterialEditingLibrary.get_material_property_input_node(
            m, unreal.MaterialProperty.MP_BASE_COLOR)
        entry["baseColorChain"] = _dump_expr(node, 0)
    except Exception as e:
        entry["baseColorError"] = str(e)
    res[path] = entry

with open(OUT, "w") as h:
    json.dump(res, h, indent=2, default=str)
unreal.log("[master-graph] wrote " + OUT)
