"""What did the compiled-world import actually produce? Per section: the bound material, its
parent master, the BaseColor texture, and that texture's imported dimensions + mip count +
compression + LOD bias. Plus the LOD0 UV0 extent straight off the render data.

Read-only. Editor must be CLOSED (own commandlet session).

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_imported_bsp_uvs.py \
    -unattended -nopause -nosplash -nullrhi
"""
import os, json, unreal

MESH = "/Game/BioShockSlice/Content/Meshes/Model1_20761"
OUT = os.path.join(os.environ["TEMP"], "probe_imported_bsp_uvs.json")
res = {"mesh": MESH, "error": None}


def tex_report(t):
    if t is None:
        return None
    d = {"name": t.get_name(), "path": t.get_path_name()}
    try:
        d["imported_w"] = int(t.blueprint_get_size_x()) if hasattr(t, "blueprint_get_size_x") else None
    except Exception:
        pass
    for prop in ("lod_bias", "lod_group", "compression_settings", "srgb",
                 "never_stream", "max_texture_size", "mip_gen_settings"):
        try:
            d[prop] = str(t.get_editor_property(prop))
        except Exception:
            pass
    try:
        src = t.get_editor_property("asset_import_data")
        d["source"] = str(src.get_first_filename()) if src else None
    except Exception:
        pass
    return d


try:
    mesh = unreal.load_asset(MESH)
    if mesh is None:
        raise RuntimeError("mesh not found")

    res["num_lods"] = mesh.get_num_lods()
    res["num_sections_lod0"] = mesh.get_num_sections(0)
    res["lightmap_coordinate_index"] = mesh.get_editor_property("light_map_coordinate_index")

    per_section = []
    mats = mesh.static_materials
    for i, sm in enumerate(mats):
        mat = sm.material_interface
        row = {"slot": i, "slot_name": str(sm.material_slot_name), "material": mat.get_name() if mat else None}
        if isinstance(mat, unreal.MaterialInstanceConstant):
            p = mat.get_editor_property("parent")
            row["parent"] = p.get_name() if p else None
            row["blend_mode"] = str(p.get_editor_property("blend_mode")) if isinstance(p, unreal.Material) else None
            for tp in mat.get_editor_property("texture_parameter_values"):
                nm = str(tp.get_editor_property("parameter_info").get_editor_property("name"))
                if nm in ("BaseColor", "Diffuse", "Albedo", "Normal"):
                    row["tex_" + nm] = tex_report(tp.get_editor_property("parameter_value"))
        per_section.append(row)
    res["per_section"] = per_section

    # UV0 extent off LOD0 render data.
    try:
        import unreal
        sm_desc = unreal.EditorStaticMeshLibrary
        # get_uv_channel_count + copy of UVs is not exposed; use ProceduralMesh conversion.
        sections_uv = []
        prim = unreal.ProceduralMeshComponent
        verts, _, _, uvs, _ = (None, None, None, None, None)
        got = unreal.StaticMeshLibrary if hasattr(unreal, "StaticMeshLibrary") else None
        # Fall back: read from the mesh description
        md = mesh.get_static_mesh_description(0)
        umin = [1e30, 1e30]; umax = [-1e30, -1e30]; n = 0
        for vid in md.get_vertex_instance_indices() if hasattr(md, "get_vertex_instance_indices") else []:
            uv = md.get_vertex_instance_uv(vid, 0)
            umin[0] = min(umin[0], uv.x); umin[1] = min(umin[1], uv.y)
            umax[0] = max(umax[0], uv.x); umax[1] = max(umax[1], uv.y)
            n += 1
        res["uv0_extent"] = {"count": n, "min": umin, "max": umax}
    except Exception as exc:
        res["uv0_extent_error"] = str(exc)

except Exception as exc:
    import traceback
    res["error"] = str(exc)
    res["traceback"] = traceback.format_exc()

with open(OUT, "w") as h:
    json.dump(res, h, indent=2, default=str)
unreal.log("[probe-bsp-uv] wrote " + OUT)
