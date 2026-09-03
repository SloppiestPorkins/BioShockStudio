"""Dump the node graph of a master material -- every expression, and specifically anything on the
UV path (TextureCoordinate tiling, a Multiply/ScalarParameter feeding a sampler's UVs). A broken
master renders every instance as noise regardless of the mesh UVs.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_master_graph.py \
    -unattended -nopause -nosplash -nullrhi
"""
import os, json, unreal

TARGETS = [
    "/Game/BioShockSlice/Content/Materials/Masters/M_BioShock_Shader_med_wall_public_shader_opaque_V5",
    "/Game/BioShockSlice/Content/Materials/Masters/M_BioShock_Shader_medical_pillar_texture_opaque_V5",
]
OUT = os.path.join(os.environ["TEMP"], "probe_master_graph.json")
res = {}

for path in TARGETS:
    m = unreal.load_asset(path)
    if m is None:
        # try the shared Content/Materials folder
        alt = path.replace("/Content/Materials/", "/Materials/")
        m = unreal.load_asset(alt)
    if m is None:
        res[path] = {"error": "not found"}
        continue

    entry = {"path": m.get_path_name(), "blend_mode": str(m.get_editor_property("blend_mode")),
             "two_sided": bool(m.get_editor_property("two_sided")), "expressions": []}
    try:
        exprs = unreal.MaterialEditingLibrary.get_material_expressions(m)
    except Exception as e:
        exprs = []
        entry["expr_error"] = str(e)
    for ex in exprs:
        d = {"type": ex.get_class().get_name()}
        for prop in ("parameter_name", "coordinate_index", "u_tiling", "v_tiling",
                     "const", "default_value", "texture", "sampler_type", "r", "g", "b"):
            try:
                v = ex.get_editor_property(prop)
                if v is not None:
                    d[prop] = v.get_name() if hasattr(v, "get_name") else str(v)
            except Exception:
                pass
        entry["expressions"].append(d)
    res[path] = entry

with open(OUT, "w") as h:
    json.dump(res, h, indent=2, default=str)
unreal.log("[master-graph] wrote " + OUT)
