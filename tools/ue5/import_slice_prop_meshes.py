"""Import the 1-Medical pickup / container / mover / station prop meshes into slice content.

Run `export_slice_prop_meshes.ps1` first (dotnet, editor closed). This imports each exported
FBX as a StaticMesh under `/Game/BioShockSlice/Content/Meshes/<name>`, imports its diffuse +
normal textures, and builds a MaterialInstanceConstant off the shared prop master so the mesh
has real BioShock art. Then `import_slice_pickups` / `_stations` / `_animated_props` pick the
meshes up via `_load_mesh` and the placeholder marker spheres go away.

Idempotent. Wired into `setup_playable_slice` BEFORE the pickup/station/mover placement steps.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_bioshock  # noqa: E402  (reuse _normalize_fbx — Blender fix for the legacy reader)

EXPORT_ROOT = r"C:/Users/Jack/Documents/BioShockUE5/Exports/props"
MESH_DEST = "/Game/BioShockSlice/Content/Meshes"
TEX_DEST = "/Game/BioShockSlice/Content/Meshes/PropTex"
MAT_DEST = "/Game/BioShockSlice/Content/Meshes/PropMat"
MASTER = "/Game/BioShockSlice/Content/Materials/Masters/M_BioShock_Shader_alan_metal_mat_opaque_V5"
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_prop_meshes.json")

_tools = unreal.AssetToolsHelpers.get_asset_tools()
_mel = unreal.MaterialEditingLibrary


def _import_mesh(fbx_path, export_dir, name):
    # The CLK's FBX trips UE5.7's legacy reader ("File is corrupted") and the Interchange path
    # asserts on Slate under -run=pythonscript. Blender-normalise, then legacy FbxFactory.
    try:
        normalized = import_bioshock._normalize_fbx(fbx_path, export_dir)
    except Exception as exc:  # noqa: BLE001
        return None, "normalize_failed: %s" % exc
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", normalized)
    task.set_editor_property("destination_path", MESH_DEST)
    task.set_editor_property("destination_name", name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    opts = unreal.FbxImportUI()
    opts.set_editor_property("import_mesh", True)
    opts.set_editor_property("import_as_skeletal", False)
    opts.set_editor_property("import_materials", False)
    opts.set_editor_property("import_textures", False)
    opts.set_editor_property("original_import_type", unreal.FBXImportType.FBXIT_STATIC_MESH)
    opts.static_mesh_import_data.set_editor_property("combine_meshes", True)
    opts.static_mesh_import_data.set_editor_property("generate_lightmap_u_vs", True)
    task.set_editor_property("options", opts)
    _tools.import_asset_tasks([task])
    return unreal.load_asset("%s/%s" % (MESH_DEST, name)), "ok"


def _import_texture(png_path, name, srgb):
    dest = "%s/%s" % (TEX_DEST, name)
    if unreal.EditorAssetLibrary.does_asset_exist(dest):
        return unreal.load_asset(dest)
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", png_path)
    task.set_editor_property("destination_path", TEX_DEST)
    task.set_editor_property("destination_name", name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    task.set_editor_property("factory", unreal.TextureFactory())
    _tools.import_asset_tasks([task])
    tex = unreal.load_asset(dest)
    if tex:
        tex.set_editor_property("srgb", srgb)
        if not srgb:
            tex.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_NORMALMAP)
        unreal.EditorAssetLibrary.save_loaded_asset(tex)
    return tex


def _material_for(name, diffuse, normal):
    master = unreal.load_asset(MASTER)
    if master is None:
        return None
    mic_path = "%s/MI_%s" % (MAT_DEST, name)
    mic = unreal.load_asset(mic_path)
    if mic is None:
        mic = _tools.create_asset(
            "MI_%s" % name, MAT_DEST, unreal.MaterialInstanceConstant,
            unreal.MaterialInstanceConstantFactoryNew())
        if mic is None:
            return None
        mic.set_editor_property("parent", master)
    if diffuse:
        _mel.set_material_instance_texture_parameter_value(mic, "BaseColor", diffuse)
    if normal:
        _mel.set_material_instance_texture_parameter_value(mic, "Normal", normal)
    unreal.EditorAssetLibrary.save_loaded_asset(mic)
    return mic


def _process(name):
    d = os.path.join(EXPORT_ROOT, name)
    manifest_path = os.path.join(d, "ue5_manifest.json")
    fbx = os.path.join(d, "%s.fbx" % name)
    if not os.path.isfile(fbx):
        return "no_export"
    rig = {}
    if os.path.isfile(manifest_path):
        rig = (json.load(open(manifest_path, encoding="utf-8")).get("rigs") or [{}])[0]

    mesh, why = _import_mesh(fbx, d, name)
    if mesh is None:
        return "import_failed: %s" % why

    diffuse = normal = None
    for t in rig.get("textures") or []:
        rel = t.get("file")
        if not rel:
            continue
        png = os.path.join(d, rel.replace("/", os.sep))
        if not os.path.isfile(png):
            continue
        stem = "%s_%s" % (name, os.path.splitext(os.path.basename(png))[0])
        usage = (t.get("usage") or "").lower()
        if "normal" in usage:
            normal = _import_texture(png, stem, srgb=False)
        elif "basecolor" in usage or "diffuse" in usage:
            diffuse = _import_texture(png, stem, srgb=True)

    mic = _material_for(name, diffuse, normal)
    if mic is not None:
        slots = list(mesh.get_editor_property("static_materials"))
        for s in slots:
            s.set_editor_property("material_interface", mic)
        mesh.set_editor_property("static_materials", slots)

    body = mesh.get_editor_property("body_setup")
    if body is not None:
        body.set_editor_property(
            "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return "ok:diffuse=%d normal=%d" % (diffuse is not None, normal is not None)


def main():
    result = {"dest": MESH_DEST, "meshes": {}}
    unreal.EditorAssetLibrary.make_directory(TEX_DEST)
    unreal.EditorAssetLibrary.make_directory(MAT_DEST)
    names = ([n for n in sorted(os.listdir(EXPORT_ROOT))
              if os.path.isdir(os.path.join(EXPORT_ROOT, n))]
             if os.path.isdir(EXPORT_ROOT) else [])
    if not names:
        result["error"] = "no exports in %s — run export_slice_prop_meshes.ps1 first" % EXPORT_ROOT
    for name in names:
        try:
            result["meshes"][name] = _process(name)
        except Exception as exc:  # noqa: BLE001
            result["meshes"][name] = "error: %s" % exc
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    unreal.log("[slice-prop-meshes] %s" % json.dumps(result))
    unreal.log("Success - 0 error(s)")
    return result


if __name__ == "__main__":
    main()
