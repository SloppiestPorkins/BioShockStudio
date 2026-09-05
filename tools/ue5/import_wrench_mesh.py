"""Import WP_WrenchMesh StaticMesh FBX into /Game/BioShockWeapons/WP_Wrench/WP_Wrench.

Mirrors import_weapon_meshes.py layout, but uses FBXIT_STATIC_MESH — WP_WrenchMesh is a
StaticMesh in ShockGame.U (no UAPW / SkeletalMesh). Export first:

  bioshock-tool export-staticmesh ShockGame WP_WrenchMesh %TEMP%/bioshock-h22-wrench

Then run this under UnrealEditor-Cmd -run=pythonscript (see run_import_wrench_mesh.py).
"""

import json
import os

import unreal

import import_bioshock


CONTENT_ROOT = "/Game/BioShockWeapons"
DESTINATION = "%s/WP_Wrench" % CONTENT_ROOT
ASSET_NAME = "WP_Wrench"
EXPECTED_PATH = "%s/%s.%s" % (DESTINATION, ASSET_NAME, ASSET_NAME)


def _log(message):
    unreal.log("[bioshock-wrench-import] %s" % message)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _disable_interchange():
    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag)


def _static_mesh_options(uniform_scale=1.0):
    """FBX → StaticMesh; same axis policy as import_bioshock skeletal import."""
    mesh_data = unreal.FbxStaticMeshImportData()
    mesh_data.set_editor_property("import_translation", unreal.Vector(0.0, 0.0, 0.0))
    mesh_data.set_editor_property("import_rotation", unreal.Rotator(0.0, 0.0, 0.0))
    mesh_data.set_editor_property("import_uniform_scale", uniform_scale)
    mesh_data.set_editor_property("convert_scene", True)
    mesh_data.set_editor_property("convert_scene_unit", False)
    mesh_data.set_editor_property("force_front_x_axis", False)
    mesh_data.set_editor_property(
        "normal_import_method", unreal.FBXNormalImportMethod.FBXNIM_IMPORT_NORMALS_AND_TANGENTS
    )

    options = unreal.FbxImportUI()
    options.set_editor_property("import_mesh", True)
    options.set_editor_property("import_as_skeletal", False)
    options.set_editor_property("import_animations", False)
    options.set_editor_property("import_materials", False)
    options.set_editor_property("import_textures", False)
    options.set_editor_property("create_physics_asset", False)
    options.set_editor_property("mesh_type_to_import", unreal.FBXImportType.FBXIT_STATIC_MESH)
    options.set_editor_property("original_import_type", unreal.FBXImportType.FBXIT_STATIC_MESH)
    options.set_editor_property("automated_import_should_detect_type", False)
    options.set_editor_property("static_mesh_import_data", mesh_data)
    return options


def _assign_static_materials(mesh, materials):
    """Assign authored MI slots onto a StaticMesh (static_materials, not skeletal slots)."""
    if not materials:
        return
    static_materials = []
    for index, material in enumerate(materials):
        slot = unreal.StaticMaterial()
        slot.set_editor_property("material_interface", material)
        slot.set_editor_property("material_slot_name", unreal.Name("BioShock_%d" % index))
        static_materials.append(slot)
    mesh.set_editor_property("static_materials", static_materials)
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)


def _resolve_export_dir(export_root):
    """Accept either the export dir itself or a parent containing WP_WrenchMesh / ue5_manifest."""
    candidates = [
        export_root,
        os.path.join(export_root, "WP_Wrench"),
        os.path.join(export_root, "WP_WrenchMesh"),
    ]
    for path in candidates:
        manifest = os.path.join(path, "ue5_manifest.json")
        if os.path.isfile(manifest):
            return path, manifest
    return None, None


def main(export_root=None, out=None):
    export_root = export_root or os.environ.get(
        "BIOSHOCK_WRENCH_EXPORT",
        os.path.join(os.environ.get("TEMP", "."), "bioshock-h22-wrench"),
    )
    out = out or os.environ.get(
        "BIOSHOCK_WRENCH_IMPORT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "wrench_mesh_import_report.json"),
    )

    report = {
        "exportRoot": export_root,
        "contentRoot": CONTENT_ROOT,
        "destination": DESTINATION,
        "expectedPath": EXPECTED_PATH,
        "imported": None,
        "failures": [],
    }
    failures = report["failures"]

    _disable_interchange()

    export_dir, manifest_path = _resolve_export_dir(export_root)
    if not export_dir:
        failures.append("export root missing ue5_manifest.json: %s" % export_root)
        _write(out, report)
        raise RuntimeError("wrench-import:\n- " + "\n- ".join(failures))

    with open(manifest_path, encoding="utf-8") as handle:
        manifest = json.load(handle)

    rigs = manifest.get("rigs") or []
    if not rigs:
        failures.append("ue5_manifest.json has no rigs: %s" % manifest_path)
        _write(out, report)
        raise RuntimeError("wrench-import:\n- " + "\n- ".join(failures))

    rig = rigs[0]
    mesh_rel = rig.get("mesh")
    if not mesh_rel:
        failures.append("rig has no mesh file entry")
        _write(out, report)
        raise RuntimeError("wrench-import:\n- " + "\n- ".join(failures))

    fbx_path = os.path.join(export_dir, mesh_rel.replace("/", os.sep))
    if not os.path.isfile(fbx_path):
        failures.append("FBX missing: %s" % fbx_path)
        _write(out, report)
        raise RuntimeError("wrench-import:\n- " + "\n- ".join(failures))

    # UE5.7's legacy FBX reader rejects this project's binary dialect ('File is corrupted');
    # Blender re-export is the same fix import_bioshock uses for skeletal viewmodels.
    try:
        fbx_path = import_bioshock._normalize_fbx(fbx_path, export_dir)
    except Exception as exc:  # noqa: BLE001
        failures.append("Blender normalize failed for %s: %s" % (mesh_rel, exc))
        _write(out, report)
        raise RuntimeError("wrench-import:\n- " + "\n- ".join(failures))

    _log("importing StaticMesh from %s → %s/%s" % (fbx_path, DESTINATION, ASSET_NAME))

    # Fresh create so a prior failed skeletal attempt cannot stick.
    existing = "%s/%s" % (DESTINATION, ASSET_NAME)
    if unreal.EditorAssetLibrary.does_asset_exist(existing):
        unreal.EditorAssetLibrary.delete_asset(existing)

    options = _static_mesh_options()
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", fbx_path)
    task.set_editor_property("destination_path", DESTINATION)
    task.set_editor_property("destination_name", ASSET_NAME)
    task.set_editor_property("options", options)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])

    mesh = next((o for o in task.get_objects() if isinstance(o, unreal.StaticMesh)), None)
    if mesh is None:
        failures.append(
            "FBX import produced no StaticMesh (file=%s, objects=%s)"
            % (fbx_path, [type(o).__name__ for o in task.get_objects()])
        )
        _write(out, report)
        raise RuntimeError("wrench-import:\n- " + "\n- ".join(failures))

    tex_result = import_bioshock._import_textures(
        rig, export_dir, DESTINATION, report=None
    )
    if isinstance(tex_result, tuple):
        imported_textures, imported_by_file = tex_result
    else:
        imported_textures, imported_by_file = tex_result or [], {}
    materials = import_bioshock._create_material_instances(
        rig, DESTINATION, CONTENT_ROOT, imported_by_file=imported_by_file
    )
    _assign_static_materials(mesh, materials)
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)

    got = mesh.get_path_name()
    report["imported"] = {
        "mesh": got,
        "textures": len(imported_textures or {}),
        "materials": len(materials or []),
        "sourceObject": rig.get("sourceObject") or manifest.get("sourceObject"),
        "vertexCount": rig.get("vertexCount"),
    }
    if got != EXPECTED_PATH and not got.startswith(DESTINATION + "/"):
        failures.append("imported path %s expected under %s" % (got, DESTINATION))

    report["errorCount"] = len(failures)
    report["wrench_import"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("wrench-import (%d errors):\n- " % len(failures) + "\n- ".join(failures))
    _log("Success - %s" % got)
    return report


if __name__ == "__main__":
    main()
