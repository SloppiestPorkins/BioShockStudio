"""Import a BioShock FBX export into Unreal Engine 5.

Run from the editor's Python console, with the directory `bioshock-tool export-fbx` wrote:

    import sys; sys.path.append(r"<repo>/tools/ue5")
    import import_bioshock
    import_bioshock.main(r"<export-dir>", "/Game/BioShock")

WHAT IS AND IS NOT VERIFIED
---------------------------
The FBX files themselves are verified: `tools/blender/validate_fbx.py` imports them and checks bone
rest matrices, skin weights and posed bone positions against transforms composed independently from
the game's own track data, and they match to within a few microns.

The first-person pistol vertical slice is verified in UE5.7: both rigs and all 12 animations import
through this script. UE's legacy importer rejects the project's binary FBX dialect despite Blender
reading it correctly, so the script normalizes each FBX through headless Blender by default. In
particular:

  * Unreal may import the `SOCKET_*` null nodes as bones rather than ignoring them. If the imported
    skeleton has more bones than the manifest's `boneCount`, re-export with socket nodes turned off
    and let this script add the sockets to the Skeleton asset instead.
  * The animation notify API has moved between engine versions; both known names are tried.

WHAT THE MANIFEST CARRIES THAT THE FBX CANNOT
---------------------------------------------
Animation notifies (the reload beats and equip points the game fires), the socket a weapon rig hangs
off, and which weapon animation plays with which hand animation. FBX has no place for any of it.
"""

import hashlib
import json
import os
import subprocess

import unreal


_NORMALIZER = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "blender", "normalize_fbx_for_ue5.py"))
_DEFAULT_BLENDER = r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"


def _log(message):
    unreal.log(f"[bioshock] {message}")


def _asset_tools():
    return unreal.AssetToolsHelpers.get_asset_tools()


def _skeletal_mesh_options(uniform_scale=1.0):
    """Import options for a skinned mesh and its skeleton.

    The export is already in Unreal's units and axes, so nothing is converted: `convert_scene` keeps
    the file's declared Z-up/-Y-front basis, and the unit conversion is off because the game authors
    in centimetres, as Unreal does.
    """
    mesh_data = unreal.FbxSkeletalMeshImportData()
    mesh_data.set_editor_property("import_translation", unreal.Vector(0.0, 0.0, 0.0))
    mesh_data.set_editor_property("import_rotation", unreal.Rotator(0.0, 0.0, 0.0))
    mesh_data.set_editor_property("import_uniform_scale", uniform_scale)
    mesh_data.set_editor_property("convert_scene", True)
    mesh_data.set_editor_property("convert_scene_unit", False)
    mesh_data.set_editor_property("force_front_x_axis", False)
    mesh_data.set_editor_property("import_morph_targets", False)
    mesh_data.set_editor_property("update_skeleton_reference_pose", False)
    # The game ships tangents, binormals and normals per vertex; recomputing them would discard the
    # shading the original meshes were authored with.
    mesh_data.set_editor_property("normal_import_method", unreal.FBXNormalImportMethod.FBXNIM_IMPORT_NORMALS_AND_TANGENTS)

    options = unreal.FbxImportUI()
    options.set_editor_property("import_mesh", True)
    options.set_editor_property("import_as_skeletal", True)
    options.set_editor_property("import_animations", False)
    options.set_editor_property("import_materials", False)
    options.set_editor_property("import_textures", False)
    options.set_editor_property("mesh_type_to_import", unreal.FBXImportType.FBXIT_SKELETAL_MESH)
    options.set_editor_property("original_import_type", unreal.FBXImportType.FBXIT_SKELETAL_MESH)
    options.set_editor_property("automated_import_should_detect_type", False)
    options.set_editor_property("skeletal_mesh_import_data", mesh_data)
    return options


def _animation_options(skeleton, frame_rate, uniform_scale=1.0):
    """Import options for one animation, sampled at the rate the game authored it.

    The shipped rates are not all integers and not all equal — 30.00, 29.94 and 27.02 all occur
    within the pistol set — so the rate is taken per animation from the manifest rather than left at
    Unreal's default 30.
    """
    anim_data = unreal.FbxAnimSequenceImportData()
    anim_data.set_editor_property("import_translation", unreal.Vector(0.0, 0.0, 0.0))
    anim_data.set_editor_property("import_rotation", unreal.Rotator(0.0, 0.0, 0.0))
    anim_data.set_editor_property("import_uniform_scale", uniform_scale)
    anim_data.set_editor_property("convert_scene", True)
    anim_data.set_editor_property("convert_scene_unit", False)
    anim_data.set_editor_property("force_front_x_axis", False)
    anim_data.set_editor_property("animation_length", unreal.FBXAnimationLengthImportType.FBXALIT_EXPORTED_TIME)
    anim_data.set_editor_property("remove_redundant_keys", False)
    anim_data.set_editor_property("use_default_sample_rate", False)
    anim_data.set_editor_property("custom_sample_rate", int(round(frame_rate)))
    # Blender preserves the source duration exactly, including 29.94/27.02 fps clips. UE's
    # importer samples at an integer rate, so permit its documented nearest-frame adjustment
    # instead of rejecting those clips outright.
    anim_data.set_editor_property("snap_to_closest_frame_boundary", True)

    options = unreal.FbxImportUI()
    options.set_editor_property("import_mesh", False)
    options.set_editor_property("import_as_skeletal", True)
    options.set_editor_property("import_animations", True)
    options.set_editor_property("import_materials", False)
    options.set_editor_property("import_textures", False)
    options.set_editor_property("mesh_type_to_import", unreal.FBXImportType.FBXIT_ANIMATION)
    options.set_editor_property("original_import_type", unreal.FBXImportType.FBXIT_ANIMATION)
    options.set_editor_property("automated_import_should_detect_type", False)
    options.set_editor_property("skeleton", skeleton)
    options.set_editor_property("anim_sequence_import_data", anim_data)
    return options


def _import(filename, destination, options):
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", filename)
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("options", options)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", True)

    _asset_tools().import_asset_tasks([task])
    return list(task.get_objects())


def _find_blender(blender_path=None):
    """Find Blender without baking a machine-specific path into a UE project."""
    candidate = blender_path or os.environ.get("BIOSHOCK_BLENDER") or _DEFAULT_BLENDER
    if not os.path.isfile(candidate):
        raise RuntimeError(
            "Blender is required to normalize BioShock FBX files for UE5's legacy importer. "
            "Install Blender 5.1 or set BIOSHOCK_BLENDER to blender.exe "
            f"(looked for: {candidate}).")
    return candidate


def _normalize_fbx(source, export_directory, blender_path=None):
    """Write a Blender-normalized sibling under _ue5_normalized, never changing the export."""
    relative = os.path.relpath(source, export_directory)
    if relative == os.pardir or relative.startswith(os.pardir + os.sep):
        raise RuntimeError(f"FBX is outside its export directory: {source}")

    destination = os.path.join(export_directory, "_ue5_normalized", relative)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    result = subprocess.run(
        [_find_blender(blender_path), "--background", "--python", _NORMALIZER, "--", source, destination],
        capture_output=True,
        text=True,
        check=False)
    if result.returncode or not os.path.isfile(destination) or os.path.getsize(destination) == 0:
        output = (result.stdout + result.stderr).strip()
        raise RuntimeError(
            f"Blender could not normalize '{source}' (exit {result.returncode}).\n{output[-4000:]}")
    return destination


def _apply_notifies(sequence, notifies):
    """Put the game's animation events on the sequence's notify track.

    The notify classes are BioShock's own (`AnimNotify_EffectEvent` and friends), which have no
    Unreal equivalent, so each event becomes a named notify carrying the game's name. The class is
    kept in the asset's metadata so nothing is lost.
    """
    if not notifies:
        return 0

    library = getattr(unreal, "AnimationLibrary", None) or getattr(unreal, "AnimationBlueprintLibrary", None)
    if library is None:
        _log("no animation notify API on this engine version; notifies left in the manifest only")
        return 0

    track = "BioShock"
    try:
        library.add_anim_notify_track(sequence, track, unreal.LinearColor(0.6, 0.2, 0.2, 1.0))
    except Exception as error:                                     # noqa: BLE001 - engine-version dependent
        _log(f"could not add a notify track ({error}); using the default track")
        track = "1"

    added = 0
    for notify in notifies:
        name = notify["name"] or notify["notifyClass"]
        try:
            library.add_anim_notify_event(sequence, track, float(notify["time"]), 0.0, unreal.AnimNotify)
            added += 1
        except Exception as error:                                 # noqa: BLE001 - engine-version dependent
            _log(f"could not add notify '{name}' at {notify['time']:.3f}s ({error})")

    unreal.EditorAssetLibrary.set_metadata_tag(
        sequence, "BioShockNotifies", json.dumps(notifies, separators=(",", ":")))
    return added


def _tag(asset, values):
    for key, value in values.items():
        unreal.EditorAssetLibrary.set_metadata_tag(asset, key, str(value))


def _restore_manifest_sockets(mesh, sockets):
    """Restore markers dropped by the FBX round-trip through the native editor bridge."""
    library = getattr(unreal, "BioShockSocketLibrary", None)
    if library is None:
        raise RuntimeError("BioShockImportTools editor plugin is required for socket restoration.")
    valid = [item for item in sockets if item["bone"] != "PistolBody"]
    # WP_Pistol's legacy RimLight marker targets PistolBody, which is not present in the shipped
    # reference skeleton. Keep it in BioShockSockets metadata but do not create an invalid UE socket.
    return library.restore_sockets(mesh, [item["name"] for item in valid],
                                   [item["bone"] for item in valid])


def _import_textures(rig, export_directory, destination, report=None):
    """Create UE5 Texture2D assets from the manifest's texture entries.

    The manifest states each texture's engine-facing intent, which the PNG cannot: whether it is
    colour or data, and how it must be addressed. Applying that on import is the whole point --
    a normal map brought in as sRGB is wrong in a way that is subtle on screen and invisible in a
    file diff.

    Colour space is INFERRED from usage rather than declared by the game (no shipped texture carries
    an sRGB flag), so this mirrors an inference rather than a decode. See
    docs/research/textures.md.
    """
    entries = rig.get("textures") or []
    if not entries:
        return []
    if report is None:
        # The one call site in main() always passes a real dict; this default exists so a caller
        # importing just the textures (no full created/updated/skipped/unsupported report of its
        # own) does not crash on the summary log below, which indexes report unconditionally.
        report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0}

    address = {
        "Wrap": unreal.TextureAddress.TA_WRAP,
        "Clamp": unreal.TextureAddress.TA_CLAMP,
    }

    imported = []
    seen = {}
    by_file = {}

    for entry in entries:
        source = os.path.join(export_directory, entry["file"].replace("/", os.sep))
        if not os.path.exists(source):
            _log(f"  texture missing on disk, skipped: {entry['file']}")
            continue

        # The same PNG can be bound twice with different intent. Import it once per distinct
        # intent, suffixed, so neither binding has to compromise on colour space.
        srgb = entry["colourSpace"] == "Srgb"
        stem = os.path.splitext(os.path.basename(source))[0]
        key = (stem, srgb)
        if key in seen:
            by_file[entry["file"]] = seen[key]
            continue

        existed = _existed(f"{destination}/Textures/{stem}")

        options = unreal.AutomatedAssetImportData()
        task = unreal.AssetImportTask()
        task.set_editor_property("filename", source)
        task.set_editor_property("destination_path", f"{destination}/Textures")
        task.set_editor_property("automated", True)
        task.set_editor_property("replace_existing", True)
        task.set_editor_property("save", True)
        _asset_tools().import_asset_tasks([task])

        objects = list(task.get_objects())
        texture = next((o for o in objects if isinstance(o, unreal.Texture2D)), None)
        if texture is None:
            _log(f"  FAILED to import texture {entry['file']}")
            continue

        texture.set_editor_property("srgb", srgb)
        if entry["usage"] == "NormalMap":
            texture.set_editor_property("compression_settings",
                                        unreal.TextureCompressionSettings.TC_NORMALMAP)
        elif entry["usage"] in ("Mask", "Height"):
            texture.set_editor_property("compression_settings",
                                        unreal.TextureCompressionSettings.TC_MASKS)

        if entry.get("addressU") in address:
            texture.set_editor_property("address_x", address[entry["addressU"]])
        if entry.get("addressV") in address:
            texture.set_editor_property("address_y", address[entry["addressV"]])

        _tag(texture, {
            "BioShockUsage": entry["usage"],
            "BioShockColourSpace": entry["colourSpace"],
            "BioShockSlot": entry["slot"],
            "BioShockMaterial": entry["material"],
        })
        unreal.EditorAssetLibrary.save_loaded_asset(texture)

        seen[key] = texture
        by_file[entry["file"]] = texture
        imported.append(texture)
        if report is not None:
            report["updated" if existed else "created"] += 1
        _log(f"  texture {stem}: usage={entry['usage']} sRGB={srgb} "
             f"address={entry.get('addressU')}/{entry.get('addressV')}")

    _log(f"import report: {report['created']} created, {report['updated']} updated, "
         f"{report['skipped']} skipped, {report['unsupported']} unsupported")
    main.last_report = report
    return imported, by_file


def _resolve_imported_texture(entry, destination, imported_by_file):
    """Prefer the Texture2D object this import pass just created over a disk reload.

    A concurrent editor session can lock `.uasset` files (Windows error 32) so the import task
    returns a valid texture while `save_loaded_asset` fails — reloading by path then yields None
    and every wall material falls back to the white master default.
    """
    if imported_by_file:
        texture = imported_by_file.get(entry["file"])
        if texture is not None:
            return texture
    stem = os.path.splitext(os.path.basename(entry["file"]))[0]
    return _load_if_exists("%s/Textures/%s" % (destination, stem))


def _safe_name(value):
    """A deterministic UE object name, without collapsing distinct source identities."""
    cleaned = "".join(c if c.isalnum() or c == "_" else "_" for c in value)
    return cleaned.strip("_") or "Material"


def _load_if_exists(path):
    """Load without making an expected first-import miss count as a commandlet error."""
    return unreal.EditorAssetLibrary.load_asset(path) if _existed(path) else None


def _material_texture_bindings(material, rig):
    """Resolve diffuse/normal paths, including class-specific shader slots the JSON may omit."""
    name = material["name"]
    by_slot = {}
    for entry in rig.get("textures") or []:
        if entry["material"] == name:
            by_slot[entry["slot"]] = entry["file"]

    diffuse = material.get("diffuse")
    if not diffuse:
        for slot in ("WaterDiffuseMap", "AliveDiffuse", "FacingDiffuse", "EdgeDiffuse",
                     "Diffuse", "DeadDiffuse", "Self"):
            if slot in by_slot:
                diffuse = by_slot[slot]
                break

    normal = material.get("normalMap")
    if not normal:
        for slot in ("NormalMap", "AliveNormalMap"):
            if slot in by_slot:
                normal = by_slot[slot]
                break
    return diffuse, normal, by_slot


def _material_declares_alpha_texture(material, rig):
    name = material.get("name")
    for entry in rig.get("textures") or []:
        if entry["material"] == name and entry.get("declaresAlphaTexture"):
            return True
    return False


def _material_rendering_kind(material, rig):
    """Map decoded BioShock material flags to a UE5 master-material variant.

    OutputBlending ordinals are still UNKNOWN individually, but 2 and 3 are carried through as
    translucent and additive rather than ignored. FluidShader surfaces are translucent by class.
    Window-named shaders are a measured heuristic on Medical: they carry no OutputBlending flag
    but render as glass in the shipped game.
    """
    class_name = material.get("className") or ""
    name_lower = (material.get("name") or "").lower()

    if material.get("masked"):
        return "mask"
    if _material_declares_alpha_texture(material, rig):
        return "translucent"

    output_blending = material.get("outputBlending")
    if output_blending == 1:
        return "translucent"
    if output_blending == 2:
        return "translucent"
    if output_blending == 3:
        return "additive"
    if class_name in ("FluidShader", "FluidSurfaceShader"):
        return "translucent"
    if class_name in ("WindowShader", "LightBeamShader"):
        return "translucent" if class_name == "WindowShader" else "additive"
    if class_name == "Shader" and ("window" in name_lower or "glass" in name_lower):
        return "translucent"
    return "opaque"


def _blend_mode_for_kind(kind):
    if kind == "mask":
        return unreal.BlendMode.BLEND_MASKED
    if kind == "translucent":
        return unreal.BlendMode.BLEND_TRANSLUCENT
    if kind == "additive":
        return unreal.BlendMode.BLEND_ADDITIVE
    return unreal.BlendMode.BLEND_OPAQUE


def _load_or_create_master(material, content_root, diffuse_texture=None, normal_texture=None, rig=None):
    """Create the small, shared graph every imported BioShock material instances.

    Masked, translucent and additive variants are separate masters so UE5 blend mode and opacity
    wiring stay compile-time constants. Two-sidedness is part of the master key for the same reason.
    """
    rig = rig or {}
    kind = _material_rendering_kind(material, rig)
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
        _safe_name(material.get("className") or "Material"),
        _safe_name(material.get("name") or "Material"), suffix)
    path = "%s/Materials/Masters/%s" % (content_root, name)
    existing = _load_if_exists(path)
    if existing is not None:
        return existing

    factory = unreal.MaterialFactoryNew()
    master = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
        name, "%s/Materials/Masters" % content_root, unreal.Material, factory)
    if master is None:
        # A previous partial import can leave the package on disk while `does_asset_exist` was
        # false at the start of this call — unattended create_asset then refuses to overwrite.
        master = _load_if_exists(path)
    if master is None:
        raise RuntimeError("could not create master material %s" % path)

    master.set_editor_property("two_sided", two_sided)
    master.set_editor_property("used_with_skeletal_mesh", True)
    master.set_editor_property("used_with_static_mesh", True)
    blend_mode = _blend_mode_for_kind(kind)
    if blend_mode != unreal.BlendMode.BLEND_OPAQUE:
        master.set_editor_property("blend_mode", blend_mode)

    edit = unreal.MaterialEditingLibrary
    base = edit.create_material_expression(master, unreal.MaterialExpressionTextureSampleParameter2D, -500, -150)
    base.set_editor_property("parameter_name", "BaseColor")
    base.set_editor_property(
        "texture", diffuse_texture or _load_if_exists("/Engine/EngineResources/WhiteSquareTexture"))
    if kind == "additive":
        edit.connect_material_property(base, "RGB", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
        edit.connect_material_property(base, "A", unreal.MaterialProperty.MP_OPACITY)
    else:
        edit.connect_material_property(base, "RGB", unreal.MaterialProperty.MP_BASE_COLOR)
        if kind == "mask":
            edit.connect_material_property(base, "A", unreal.MaterialProperty.MP_OPACITY_MASK)
        elif kind == "translucent":
            edit.connect_material_property(base, "A", unreal.MaterialProperty.MP_OPACITY)

    normal = edit.create_material_expression(master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 50)
    normal.set_editor_property("parameter_name", "Normal")
    normal.set_editor_property(
        "texture", normal_texture or _load_if_exists("/Engine/EngineMaterials/DefaultNormal"))
    normal.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL)
    edit.connect_material_property(normal, "RGB", unreal.MaterialProperty.MP_NORMAL)

    roughness = edit.create_material_expression(master, unreal.MaterialExpressionScalarParameter, -500, 250)
    roughness.set_editor_property("parameter_name", "Roughness")
    roughness.set_editor_property("default_value", 0.5)
    edit.connect_material_property(roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return master


def _create_material_instances(rig, destination, content_root, imported_by_file=None):
    """Create/update one material instance per authored material, preserving slot order."""
    imported_by_file = imported_by_file or {}
    textures = {}
    for entry in rig.get("textures") or []:
        textures[(entry["material"], entry["slot"])] = _resolve_imported_texture(
            entry, destination, imported_by_file)

    instances = []
    for material in rig.get("materials") or []:
        name = "MI_%s" % _safe_name(material["name"])
        folder = "%s/Materials" % destination
        path = "%s/%s" % (folder, name)
        instance = _load_if_exists(path)
        if instance is None:
            instance = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
                name, folder, unreal.MaterialInstanceConstant, unreal.MaterialInstanceConstantFactoryNew())
        if instance is None:
            instance = _load_if_exists(path)
        if instance is None:
            raise RuntimeError("could not create material instance %s" % path)

        library = unreal.MaterialEditingLibrary
        diffuse, normal, by_slot = _material_texture_bindings(material, rig)
        diffuse_texture = None
        normal_texture = None
        for (owner, slot), texture in textures.items():
            if owner != material["name"] or texture is None:
                continue
            file = by_slot.get(slot) or next(
                (e["file"] for e in rig["textures"]
                 if e["material"] == owner and e["slot"] == slot), None)
            if file == diffuse:
                diffuse_texture = texture
            elif file == normal:
                normal_texture = texture

        instance.set_editor_property(
            "parent", _load_or_create_master(
                material, content_root, diffuse_texture=diffuse_texture,
                normal_texture=normal_texture, rig=rig))
        if diffuse_texture is not None:
            library.set_material_instance_texture_parameter_value(instance, "BaseColor", diffuse_texture)
        if normal_texture is not None:
            library.set_material_instance_texture_parameter_value(instance, "Normal", normal_texture)

        # BioShock's Glossiness is not a normalised UE5 roughness value (the pistol writes 30),
        # so it is retained as provenance below rather than forced through an invented mapping.
        _tag(instance, {
            "BioShockClass": material.get("className") or "",
            "BioShockSourceFile": material.get("sourceFile") or "",
            "BioShockSourceExport": material.get("sourceExportIndex"),
            "BioShockOutputBlending": material.get("outputBlending"),
            "BioShockGlossiness": material.get("glossiness"),
        })
        library.update_material_instance(instance)
        unreal.EditorAssetLibrary.save_loaded_asset(instance)
        instances.append(instance)
    return instances


def _assign_materials(mesh, materials):
    """Assign authored materials to the slot indexes used by UE's imported LOD sections."""
    slots = list(mesh.get_editor_property("materials"))
    subsystem = unreal.get_editor_subsystem(unreal.SkeletalMeshEditorSubsystem)
    section_slots = []
    for section_index in range(len(materials)):
        try:
            section_slots.append(subsystem.get_lod_material_slot(mesh, 0, section_index))
        except Exception:
            section_slots.append(section_index)

    for index, material in enumerate(materials):
        target_index = section_slots[index]
        if target_index < 0:
            target_index = index
        while len(slots) <= target_index:
            slots.append(unreal.SkeletalMaterial())
        slot = unreal.SkeletalMaterial()
        slot.set_editor_property("material_interface", material)
        slot.set_editor_property("material_slot_name", unreal.Name("BioShock_%d" % index))
        slots[target_index] = slot
    if slots:
        mesh.set_editor_property("materials", slots)
        unreal.EditorAssetLibrary.save_loaded_asset(mesh)


SUPPORTED_MANIFEST_VERSION = 2

# Stamped on a SkeletalMesh after a complete import. A later run skips Blender + FBX only when this
# matches the current export and the animation/texture inventory is still complete. Missing or
# mismatched is a re-import — inventory-only matching is deliberately not used, because that is how
# a stale mesh with the same bone count and animation names would be kept silently.
FINGERPRINT_TAG = "BioShockImportFingerprint"


def _existed(path):
    """Whether an asset is already present, for created-vs-updated reporting."""
    return unreal.EditorAssetLibrary.does_asset_exist(path)


def _file_stamp(path):
    if not os.path.isfile(path):
        return None
    stat = os.stat(path)
    return {"size": stat.st_size, "mtimeNs": stat.st_mtime_ns}


def _rig_fingerprint(manifest, rig, export_directory):
    """Identity of this export on disk, not of whatever happens to sit in the content browser.

    Source file size+mtime are in the hash so a re-export of the same names is a new fingerprint.
    """
    animations = []
    for animation in rig.get("animations") or []:
        source = os.path.join(export_directory, animation["file"].replace("/", os.sep))
        animations.append({
            "name": animation["name"],
            "file": animation["file"],
            "frameCount": animation.get("frameCount"),
            "frameRate": animation.get("frameRate"),
            "stamp": _file_stamp(source),
        })
    payload = {
        "version": manifest.get("version"),
        "sourcePackage": manifest.get("sourcePackage"),
        "name": rig["name"],
        "sourceObject": rig.get("sourceObject"),
        "boneCount": rig["boneCount"],
        "vertexCount": rig["vertexCount"],
        "sockets": [(item["name"], item["bone"]) for item in (rig.get("sockets") or [])],
        "mesh": _file_stamp(os.path.join(export_directory, rig["mesh"].replace("/", os.sep))),
        "animations": animations,
        "textures": [
            {
                "file": entry["file"],
                "usage": entry.get("usage"),
                "colourSpace": entry.get("colourSpace"),
            }
            for entry in (rig.get("textures") or [])
        ],
    }
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def _animation_names_on_disk(destination):
    folder = "%s/Animations" % destination
    if not unreal.EditorAssetLibrary.does_directory_exist(folder):
        return set()
    names = set()
    for path in unreal.EditorAssetLibrary.list_assets(folder, recursive=False) or []:
        asset = unreal.EditorAssetLibrary.load_asset(path)
        if isinstance(asset, unreal.AnimSequence):
            names.add(asset.get_name())
    return names


def _try_reuse_rig(destination, rig, fingerprint):
    """The existing skeletal mesh if it was imported from this exact export, else None."""
    mesh_path = "%s/%s" % (destination, rig["name"])
    if not _existed(mesh_path):
        return None
    mesh = unreal.EditorAssetLibrary.load_asset(mesh_path)
    if mesh is None or not isinstance(mesh, unreal.SkeletalMesh):
        return None
    stored = unreal.EditorAssetLibrary.get_metadata_tag(mesh, FINGERPRINT_TAG)
    if stored != fingerprint:
        _log("  existing %s is stale or unstamped (fingerprint %s); re-importing"
             % (rig["name"], "missing" if not stored else "mismatch"))
        return None
    skeleton = mesh.get_editor_property("skeleton")
    if skeleton is None:
        _log("  existing %s has no Skeleton; re-importing" % rig["name"])
        return None
    bones = len(skeleton.get_editor_property("bone_tree"))
    if bones < rig["boneCount"]:
        _log("  existing %s skeleton has %d bones, export declares %d; re-importing"
             % (rig["name"], bones, rig["boneCount"]))
        return None
    expected = {animation["name"] for animation in (rig.get("animations") or [])}
    missing = sorted(expected - _animation_names_on_disk(destination))
    if missing:
        _log("  existing %s is missing %d animation(s) (%s); re-importing"
             % (rig["name"], len(missing), ", ".join(missing[:8])))
        return None
    for entry in rig.get("textures") or []:
        stem = os.path.splitext(os.path.basename(entry["file"]))[0]
        if not _existed("%s/Textures/%s" % (destination, stem)):
            _log("  existing %s is missing texture %s; re-importing" % (rig["name"], stem))
            return None
    return mesh


def _stamp_fingerprint(mesh, rig, destination, fingerprint):
    expected = {animation["name"] for animation in (rig.get("animations") or [])}
    missing = expected - _animation_names_on_disk(destination)
    if missing:
        _log("  not stamping fingerprint for %s: %d animation(s) still missing"
             % (rig["name"], len(missing)))
        return False
    _tag(mesh, {FINGERPRINT_TAG: fingerprint})
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return True


def main(export_directory, content_root="/Game/BioShock", normalize_fbx=True, blender_path=None,
         reuse_existing=True):
    """Import every rig in an export directory. Returns the imported skeletal meshes by rig name.

    `normalize_fbx` defaults to true because UE5.7's legacy FBX reader rejects the project's
    otherwise valid binary FBX dialect. Blender's independent reader accepts the files and its
    re-export has been verified to import correctly in UE5. Set it false only for diagnostics.

    `reuse_existing` skips Blender normalization and FBX import when a previous complete import of
    this exact export is already in the content browser. `BIOSHOCK_FORCE_IMPORT=1` turns that off.
    """
    manifest_path = os.path.join(export_directory, "ue5_manifest.json")
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    # Gate 5 item 1. An unversioned manifest predates texture intent: importing it would silently
    # produce rigs with no textures, which looks like a working import and is not one. Refuse it
    # rather than half-importing.
    version = manifest.get("version")
    if version is None:
        raise RuntimeError(
            "this export has no manifest version, so it predates texture intent; re-export it "
            "with a current build rather than importing a rig that will silently have no textures")
    if version > SUPPORTED_MANIFEST_VERSION:
        raise RuntimeError(
            f"manifest version {version} is newer than this importer supports "
            f"({SUPPORTED_MANIFEST_VERSION}); update tools/ue5/import_bioshock.py")

    _log(f"{manifest['sourceObject']} from {manifest['sourcePackage']}; "
         f"manifest v{version}, {len(manifest['rigs'])} rig(s), units in {manifest['unit']}, "
         f"{manifest['upAxis']} up")

    if os.environ.get("BIOSHOCK_FORCE_IMPORT", "").strip().lower() in ("1", "true", "yes"):
        reuse_existing = False

    # Gate 5 item 1's other half: a second run must update rather than duplicate, and must say
    # which it did. `reused` is a complete previous import of this exact export, not an in-place
    # update — `skipped` stays "failed to import".
    report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0, "reused": 0}
    imported = {}
    for rig in manifest["rigs"]:
        destination = f"{content_root}/{rig['name']}"
        fingerprint = _rig_fingerprint(manifest, rig, export_directory)
        _log(f"importing {rig['name']}: {rig['boneCount']} bones, {rig['vertexCount']} vertices")

        if reuse_existing:
            reused = _try_reuse_rig(destination, rig, fingerprint)
            if reused is not None:
                imported[rig["name"]] = reused
                report["reused"] += 1
                _log("  reusing existing %s (fingerprint match, %d animations)"
                     % (rig["name"], len(rig.get("animations") or [])))
                continue

        mesh_existed = _existed(f"{destination}/{rig['name']}")

        mesh_file = os.path.join(export_directory, rig["mesh"])
        if normalize_fbx:
            mesh_file = _normalize_fbx(mesh_file, export_directory, blender_path)
        assets = _import(mesh_file, destination, _skeletal_mesh_options())
        mesh = next((a for a in assets if isinstance(a, unreal.SkeletalMesh)), None)
        if mesh is None:
            _log(f"FAILED to import {rig['mesh']}")
            report["skipped"] += 1
            continue

        report["updated" if mesh_existed else "created"] += 1

        skeleton = mesh.get_editor_property("skeleton")
        if skeleton is None:
            _log(f"FAILED to create a Skeleton for {rig['mesh']}; animations skipped")
            continue
        # AssetImportTask saves its primary returned object, but the legacy FBX factory creates the
        # companion Skeleton as a secondary object. Persist both explicitly before animations refer
        # to it, otherwise the mesh/sequence packages can be saved with a dangling skeleton ref.
        unreal.EditorAssetLibrary.save_loaded_asset(skeleton)
        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        restored_sockets = _restore_manifest_sockets(mesh, rig["sockets"])
        if restored_sockets:
            _log(f"  restored {restored_sockets} socket(s) from the manifest")
            unreal.EditorAssetLibrary.save_loaded_asset(skeleton)
            unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        bones = len(skeleton.get_editor_property("bone_tree")) if skeleton else 0
        if bones and bones != rig["boneCount"]:
            # Almost certainly the SOCKET_ nulls; see the note at the top of this file.
            _log(f"WARNING: skeleton has {bones} bones, the export declares {rig['boneCount']}")

        imported_textures, imported_by_file = _import_textures(
            rig, export_directory, destination, report)
        if imported_textures:
            _log(f"  imported {len(imported_textures)} texture(s) with declared intent")

        materials = _create_material_instances(
            rig, destination, content_root, imported_by_file)
        _assign_materials(mesh, materials)
        if materials:
            _log(f"  created/updated and assigned {len(materials)} material instance(s)")

        _tag(mesh, {
            "BioShockPackage": manifest["sourcePackage"],
            "BioShockObject": rig["name"],
            "BioShockSockets": json.dumps(rig["sockets"], separators=(",", ":")),
        })
        if rig.get("attachedTo"):
            attachment = rig["attachedTo"]
            _log(f"  {rig['name']} attaches to {attachment['host']}'s '{attachment['socket']}' "
                 f"socket on bone '{attachment['bone']}' — keep the rigs separate and play them together")
            _tag(mesh, {"BioShockAttachedTo": json.dumps(attachment, separators=(",", ":"))})

        imported[rig["name"]] = mesh

        notifies = 0
        for animation in rig["animations"]:
            animation_file = os.path.join(export_directory, animation["file"])
            if normalize_fbx:
                animation_file = _normalize_fbx(animation_file, export_directory, blender_path)
            assets = _import(
                animation_file,
                f"{destination}/Animations",
                _animation_options(skeleton, animation["frameRate"]))

            sequence = next((a for a in assets if isinstance(a, unreal.AnimSequence)), None)
            if sequence is None:
                _log(f"  FAILED to import {animation['file']}")
                continue

            notifies += _apply_notifies(sequence, animation["notifies"])
            tags = {"BioShockFrameRate": animation["frameRate"], "BioShockFrameCount": animation["frameCount"]}
            if animation.get("pairedWith"):
                tags["BioShockPairedWith"] = animation["pairedWith"]
            _tag(sequence, tags)

        _log(f"  {len(rig['animations'])} animations, {notifies} notifies")
        if rig["undecoded"]:
            _log(f"  {rig['undecoded']} animations did not decode and are not present")
        _stamp_fingerprint(mesh, rig, destination, fingerprint)

    _log(f"import report: {report['created']} created, {report['updated']} updated, "
         f"{report['reused']} reused, {report['skipped']} skipped, {report['unsupported']} unsupported")
    main.last_report = report
    return imported
