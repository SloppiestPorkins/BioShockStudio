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
import struct
import subprocess
import zlib

import unreal


# Prefer the UE5-lane normalizer (Z-up/-Y-front, from h4). Axis policy is independent of the
# 4 Sept 2026 IntFitsIn reimport crash (UnrealTemplate.h:170, In=2499805188): that assert fires
# during mesh AssetImportTask save (InternalPromptForCheckoutAndSave) on atomic reimport over a
# bloated package — reproduced with Z-up and Y-up normalizers and with animations emptied. See
# `_delete_existing_mesh_assets` / `_import` and tools/ue5/README.md.
_NORMALIZER = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "normalize_fbx_for_ue5.py"))
_DEFAULT_BLENDER = r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"


def _log(message):
    unreal.log(f"[bioshock] {message}")


def _asset_tools():
    return unreal.AssetToolsHelpers.get_asset_tools()


def _skeletal_mesh_options(uniform_scale=1.0, use_t0_as_ref_pose=False):
    """Import options for a skinned mesh and its skeleton.

    Studio FBX is centimetres, Z-up / -Y-front / RH after one `GameBasis.Convert` at decode
    (`docs/research/ANIMATION_COORDINATE_SYSTEM.md`). UE's ConvertScene targets that same triple
    when `force_front_x_axis` is false, so the conversion is a no-op *if* the file still declares
    those axes — which is why `normalize_fbx_for_ue5.py` must re-export Z-up/-Y, not Blender's
    default Y-up. `import_rotation` stays identity: a rotation cannot fix handedness, and must not
    be used to paper over an inverted bind pose (see `ApplyCombatSkeletalMesh`).
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
    mesh_data.set_editor_property("use_t0_as_ref_pose", use_t0_as_ref_pose)
    # SOCKET_* nulls must stay bones-to-be-stripped / restored as sockets, not nested meshes.
    mesh_data.set_editor_property("import_meshes_in_bone_hierarchy", False)
    # The game ships tangents, binormals and normals per vertex; recomputing them would discard the
    # shading the original meshes were authored with.
    mesh_data.set_editor_property("normal_import_method", unreal.FBXNormalImportMethod.FBXNIM_IMPORT_NORMALS_AND_TANGENTS)

    options = unreal.FbxImportUI()
    options.set_editor_property("import_mesh", True)
    options.set_editor_property("import_as_skeletal", True)
    options.set_editor_property("import_animations", False)
    options.set_editor_property("import_materials", False)
    options.set_editor_property("import_textures", False)
    # Auto physics on a first forced reimport of a large character package is unnecessary here
    # (import_level creates physics when a pawn needs it) and is one less build step on the
    # headless path that already asserts inside InternalPromptForCheckoutAndSave.
    options.set_editor_property("create_physics_asset", False)
    options.set_editor_property("mesh_type_to_import", unreal.FBXImportType.FBXIT_SKELETAL_MESH)
    options.set_editor_property("original_import_type", unreal.FBXImportType.FBXIT_SKELETAL_MESH)
    options.set_editor_property("automated_import_should_detect_type", False)
    options.set_editor_property("skeletal_mesh_import_data", mesh_data)
    return options


def _animation_options(skeleton, frame_rate, uniform_scale=1.0):
    """Import options for one animation, sampled at the rate the game authored it.

    Same axis policy as `_skeletal_mesh_options` — animations share the skeleton's basis, so they
    take the same ConvertScene / force_front_x_axis / identity import_rotation. Re-import mesh and
    clips together after a normalizer change; do not leave old anims on a newly oriented skeleton.

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
    # save=True routes through InternalPromptForCheckoutAndSave. Under -run=pythonscript that
    # path is unsafe (texture import already documents the Slate toast assert). On AggressorBabyJane
    # forced reimport it hung ~9 minutes after a successful 0.12s mesh build, then asserted
    # IntFitsIn In=2499805188 while still inside ImportAssetTasks. Persist via save_loaded_asset.
    task.set_editor_property("save", False)

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


def _to_unreal_location(location):
    """Reverses GameBasis.Convert(Vector3) -- negates Y.

    Manifest / scene values are in this project's right-handed, +Y-left internal basis (the same
    numbers bone translation already carries after decode). Unreal sockets want left-handed,
    +Y-right. Same involution `import_level._to_unreal_location` applies to level instances.
    """
    x, y, z = location
    return [x, -y, z]


def _to_unreal_rotator(rotation):
    """Reverses GameBasis.Convert(Quaternion) -- negate X and Z -- then to FRotator degrees.

    Same formula as `import_level._decompose`'s quaternion step for GameBasis-converted matrices.
    """
    x, y, z, w = rotation
    quat = unreal.Quat(x=-float(x), y=float(y), z=-float(z), w=float(w))
    return quat.rotator()


def _restore_manifest_sockets(mesh, sockets):
    """Restore markers dropped by the FBX round-trip through the native editor bridge."""
    library = getattr(unreal, "BioShockSocketLibrary", None)
    if library is None:
        raise RuntimeError("BioShockImportTools editor plugin is required for socket restoration.")
    valid = [item for item in sockets if item["bone"] != "PistolBody"]
    # WP_Pistol's legacy RimLight marker targets PistolBody, which is not present in the shipped
    # reference skeleton. Keep it in BioShockSockets metadata but do not create an invalid UE socket.
    names = [item["name"] for item in valid]
    bones = [item["bone"] for item in valid]
    # Only weapons that do NOT self-correct in AShockPlayer::AlignEquippedWeaponRootToGripSocket
    # want the decoded socket transform: the Wrench (a static mesh, no align at all). Every grip
    # weapon (Pistol/TommyGun/GrenadeLauncher/Crossbow → R_grip root) cancels its root-bone
    # rotation in that function, so a non-identity socket on top double-rotates it — reported in
    # PIE as "GrenadeLauncher pointing up, TommyGun facing the wrong way" (6 Sept 2026). Drop the
    # transform for those; keep name+bone.
    _SOCKET_TRANSFORM_WEAPONS = {"Wrench"}
    for item in valid:
        if item["name"] not in _SOCKET_TRANSFORM_WEAPONS:
            item.pop("translation", None)
            item.pop("rotation", None)
    has_transform = any("translation" in item or "rotation" in item for item in valid)
    if not has_transform:
        return library.restore_sockets(mesh, names, bones, [], [])

    locations = []
    rotations = []
    for item in valid:
        translation = item.get("translation")
        rotation = item.get("rotation")
        if translation is not None and len(translation) >= 3:
            loc = _to_unreal_location(translation)
            locations.append(unreal.Vector(float(loc[0]), float(loc[1]), float(loc[2])))
        else:
            locations.append(unreal.Vector(0.0, 0.0, 0.0))
        if rotation is not None and len(rotation) >= 4:
            rotations.append(_to_unreal_rotator(rotation))
        else:
            rotations.append(unreal.Rotator(0.0, 0.0, 0.0))
    return library.restore_sockets(mesh, names, bones, locations, rotations)


def _opacity_entry_identities(rig):
    """(material name, slot) pairs identifying the SPECIFIC textures[] entry that is a material's
    real Opacity source.

    Matching by (material, file) alone -- an earlier version of this function did -- is wrong
    whenever Diffuse and Opacity legitimately share one file (the common, already-documented
    "opacity-slot-same-as-diffuse-file" shape): EVERY entry with that file then matches, including
    the Diffuse one, so both get treated as opacity intent and the plain, colour-space-correct
    Diffuse import never actually runs. Confirmed live 29 Sept 2026 on `Wall_Leak_diff_shader`:
    both its "Diffuse" and "Opacity" slot entries share `Wall_Leak_diff.png`, and the file-only
    check flagged both, leaving the plain (non-"_Opacity") texture asset frozen at its stale,
    wrong `TC_MASKS`/`srgb=False` settings from before this fix even though the Opacity node
    itself now correctly pointed at a dedicated, correctly-configured `_Opacity` asset.

    Shared between `_import_textures` (decides which file gets imported under the `_Opacity`
    intent) and `_create_material_instances` (must resolve the SAME intent for the SAME entry, or
    it silently hands a material's Opacity slot the colour-space-mismatched Diffuse asset again).
    """
    identities = set()
    for material in rig.get("materials") or []:
        _diffuse, _normal, opacity, by_slot = _material_texture_bindings(material, rig)
        if not opacity:
            continue
        name = material.get("name")
        if by_slot.get("Opacity") == opacity:
            identities.add((name, "Opacity"))
            continue
        # opacity came from the material's own top-level "opacity" field with no "Opacity"-named
        # slot to unambiguously prefer -- best effort, matches every entry sharing that file for
        # this material (same limitation the old check had, only reached in this narrower case).
        for entry in rig.get("textures") or []:
            if entry.get("material") == name and entry.get("file") == opacity:
                identities.add((name, entry.get("slot")))
    return identities


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
    opacity_identities = _opacity_entry_identities(rig)

    for entry in entries:
        source = os.path.join(export_directory, entry["file"].replace("/", os.sep))
        if not os.path.exists(source):
            _log(f"  texture missing on disk, skipped: {entry['file']}")
            continue

        # The same PNG can be bound twice with different intent -- e.g. Wall_Leak_diff_shader's
        # Opacity slot points at the exact same file as its Diffuse slot (a documented, common
        # shape -- see _material_has_opacity_slot_texture). Both intents used to import to the
        # SAME destination path (stem alone), so whichever entry was processed second silently
        # overwrote the first's srgb/compression -- confirmed live 29 Sept 2026: the opacity entry
        # won the race, leaving the single resulting asset TC_MASKS/srgb=False, which is correct
        # for the Opacity read but wrong for the BaseColor read of that SAME asset, and the real
        # editor's own SM5 compiler flagged it (Color sampler on a Masks-compressed texture) even
        # after the material graph's Opacity node itself was fixed to sample Masks correctly. Give
        # the opacity-intent import its own destination name so it is a genuinely separate asset,
        # never overwriting the colour-space-sensitive one.
        is_opacity = (entry.get("material"), entry.get("slot")) in opacity_identities
        srgb = False if is_opacity else entry["colourSpace"] == "Srgb"
        stem = os.path.splitext(os.path.basename(source))[0]
        if is_opacity:
            stem = f"{stem}_Opacity"
        key = (stem, srgb)
        if key in seen:
            by_file[(entry["file"], is_opacity)] = seen[key]
            continue

        existed = _existed(f"{destination}/Textures/{stem}")

        options = unreal.AutomatedAssetImportData()
        task = unreal.AssetImportTask()
        task.set_editor_property("filename", source)
        task.set_editor_property("destination_path", f"{destination}/Textures")
        task.set_editor_property("destination_name", stem)
        task.set_editor_property("automated", True)
        task.set_editor_property("replace_existing", True)
        # save=True routes through InternalPromptForCheckoutAndSave, whose Slate notification
        # asserts under -run=pythonscript. Persist explicitly after applying texture settings.
        task.set_editor_property("save", False)
        # Pin the LEGACY texture factory. Left to itself the task goes through Interchange, which
        # fires a Slate notification when it finishes: the log reads "Interchange import completed"
        # and one millisecond later the process dies on Assertion failed:
        # CurrentApplication.IsValid(). Same failure the OBJ importer has, and the project already
        # forces legacy for FBX and OBJ via Interchange.FeatureFlags in DefaultEngine.ini - but
        # there is NO Interchange.FeatureFlags.Import.Texture, so the choice has to be made here,
        # per task, by naming the factory.
        try:
            task.set_editor_property("factory", unreal.TextureFactory())
        except Exception as exc:  # noqa: BLE001
            _log(f"  could not pin the legacy texture factory ({exc}); "
                 "Interchange may assert under -run=pythonscript")
        _asset_tools().import_asset_tasks([task])

        objects = list(task.get_objects())
        texture = next((o for o in objects if isinstance(o, unreal.Texture2D)), None)
        if texture is None:
            _log(f"  FAILED to import texture {entry['file']}")
            continue

        texture.set_editor_property("srgb", srgb)
        # Always set explicitly, never left to whatever the factory/re-import happened to leave
        # in place. `replace_existing=True` re-imports the pixels but does NOT reset an existing
        # asset's compression_settings to a default -- it preserves whatever was there before.
        # Confirmed live 29 Sept 2026: with only the Mask/NormalMap/is_opacity branches setting it,
        # a texture previously (wrongly) left at TC_MASKS by an earlier bug stayed TC_MASKS forever
        # on every later re-import, even once the code decided this entry was no longer opacity
        # intent -- nothing ever told the asset to go back to TC_DEFAULT.
        if entry["usage"] == "NormalMap":
            texture.set_editor_property("compression_settings",
                                        unreal.TextureCompressionSettings.TC_NORMALMAP)
        elif is_opacity or entry["usage"] in ("Mask", "Height"):
            texture.set_editor_property("compression_settings",
                                        unreal.TextureCompressionSettings.TC_MASKS)
        else:
            texture.set_editor_property("compression_settings",
                                        unreal.TextureCompressionSettings.TC_DEFAULT)

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
        by_file[(entry["file"], is_opacity)] = texture
        imported.append(texture)
        if report is not None:
            report["updated" if existed else "created"] += 1
        _log(f"  texture {stem}: usage={entry['usage']} sRGB={srgb} "
             f"address={entry.get('addressU')}/{entry.get('addressV')}")

    _log(f"import report: {report['created']} created, {report['updated']} updated, "
         f"{report['skipped']} skipped, {report['unsupported']} unsupported")
    main.last_report = report
    return imported, by_file


def _resolve_imported_texture(entry, destination, imported_by_file, is_opacity=False):
    """Prefer the Texture2D object this import pass just created over a disk reload.

    A concurrent editor session can lock `.uasset` files (Windows error 32) so the import task
    returns a valid texture while `save_loaded_asset` fails — reloading by path then yields None
    and every wall material falls back to the white master default.

    `is_opacity` must match the value `_import_textures` used for this same entry: a shared
    Diffuse/Opacity file imports as two distinct assets (`{stem}` and `{stem}_Opacity`, see its
    docstring), so resolving the wrong one silently hands the caller the colour-space-mismatched
    asset again.
    """
    if imported_by_file:
        texture = imported_by_file.get((entry["file"], is_opacity))
        if texture is not None:
            return texture
    stem = os.path.splitext(os.path.basename(entry["file"]))[0]
    if is_opacity:
        stem = f"{stem}_Opacity"
    return _load_if_exists("%s/Textures/%s" % (destination, stem))


def _safe_name(value):
    """A deterministic UE object name, without collapsing distinct source identities."""
    cleaned = "".join(c if c.isalnum() or c == "_" else "_" for c in value)
    return cleaned.strip("_") or "Material"


def _load_if_exists(path):
    """Load without making an expected first-import miss count as a commandlet error."""
    return unreal.EditorAssetLibrary.load_asset(path) if _existed(path) else None


def _load_engine_texture(*paths):
    """Load a known Engine Texture2D without EditorAssetLibrary.load_asset.

    `EditorAssetLibrary.load_asset` / `does_asset_exist` miss Engine content under
    -run=pythonscript (measured UE 5.7: DefaultNormal logs
    'LoadAsset failed: The AssetData ... could not be found' and counts as a
    commandlet error). `unreal.load_object` resolves the same package path.
    A prior import that used `_load_if_exists` for these defaults left Normal
    TextureSampleParameter2D nodes as NULL → 'Found NULL, requires Texture2D'
    → Default Material in game.
    """
    last = None
    for path in paths:
        # Soft-object path forms: "/Engine/.../Name" and "/Engine/.../Name.Name"
        candidates = [path]
        if "." not in path.rsplit("/", 1)[-1]:
            name = path.rsplit("/", 1)[-1]
            candidates.append("%s.%s" % (path, name))
        for candidate in candidates:
            texture = unreal.load_object(None, candidate)
            if texture is not None:
                return texture
            last = candidate
    raise RuntimeError(
        "could not load any Engine Texture2D from %s (last=%r)" % (list(paths), last))


def _default_base_color_texture(blend_mode=None):
    """The stand-in for an empty BaseColor, chosen by how the material BLENDS.

    White is only a safe default for an opaque surface. On an additive material it is the worst
    possible value: additive adds its colour to whatever is behind it, so a pure white square
    saturates everything it covers. That is exactly what happened to the Medical Pavilion god rays
    - LightBeamShader exported with no base colour, this filled it with WhiteSquareTexture, and the
    beams rendered as a flat white wedge over a quarter of the frame. Black is the identity for
    addition, so an additive material with nothing bound now disappears instead of blowing out,
    which is both the correct no-op and a far more legible failure.

    Modulate is the mirror image: it MULTIPLIES, so white is its identity and black would erase
    everything behind it. Opaque and the translucent modes keep white.
    """
    if blend_mode == unreal.BlendMode.BLEND_ADDITIVE:
        for path in ("/Engine/EngineResources/Black",
                     "/Engine/EngineMaterials/BlackTexture"):
            texture = unreal.load_object(None, path) or unreal.load_object(
                None, "%s.%s" % (path, path.rsplit("/", 1)[-1]))
            if texture is not None:
                return texture
        # Say so rather than quietly handing back the value this exists to avoid.
        unreal.log_warning(
            "[import] no engine black texture found; an additive master will be filled with "
            "white and will blow out wherever it draws")
    return _load_engine_texture(
        "/Engine/EngineResources/WhiteSquareTexture",
        "/Engine/EngineMaterials/DefaultDiffuse",
    )


def _default_normal_texture():
    return _load_engine_texture(
        "/Engine/EngineMaterials/DefaultNormal",
        "/Engine/EngineMaterials/DefaultNormal_Uncompressed",
        "/Engine/EngineMaterials/BaseFlattenNormalMap",
    )


def _repair_null_texture_parameters(master):
    """Fill NULL TextureSampleParameter2D defaults so the master can compile.

    Returns the number of parameters repaired. No-op when every sample already has a texture.
    Uses GetMaterialPropertyInputNode — MaterialEditingLibrary has no expression-list getter.
    """
    if master is None or not isinstance(master, unreal.Material):
        return 0
    edit = unreal.MaterialEditingLibrary
    repaired = 0
    # The blend mode decides what an empty BaseColor should be filled with — see
    # _default_base_color_texture. Read once here rather than per parameter.
    try:
        blend_mode = master.get_editor_property("blend_mode")
    except Exception:  # noqa: BLE001
        blend_mode = None
    checks = (
        (unreal.MaterialProperty.MP_BASE_COLOR, False),
        (unreal.MaterialProperty.MP_EMISSIVE_COLOR, False),
        (unreal.MaterialProperty.MP_OPACITY, False),
        (unreal.MaterialProperty.MP_OPACITY_MASK, False),
        (unreal.MaterialProperty.MP_NORMAL, True),
    )
    seen = set()
    for prop, is_normal in checks:
        node = edit.get_material_property_input_node(master, prop)
        if node is None or id(node) in seen:
            continue
        seen.add(id(node))
        if not isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D):
            continue
        if node.get_editor_property("texture") is not None:
            continue
        if is_normal:
            node.set_editor_property("texture", _default_normal_texture())
            node.set_editor_property(
                "sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL)
        else:
            node.set_editor_property("texture", _default_base_color_texture(blend_mode))
        repaired += 1
    if repaired:
        edit.recompile_material(master)
        unreal.EditorAssetLibrary.save_loaded_asset(master)
    return repaired


def _masks_compressed_variant(texture):
    """A sibling `<Name>_Mask` Texture2D asset: a Masks-compressed, non-sRGB copy of `texture`.

    Needed whenever a material's Opacity/OpacityMask must read the SAME pixel data as its
    BaseColor (no genuinely separate opacity source was ever exported for it) but the SM5 compiler
    requires the reading node's sampler_type to match the referenced ASSET's own compression --
    one texture asset cannot serve both a Color-sampled BaseColor read and a Masks-sampled
    Opacity/OpacityMask read at once. Found live 29 Sept 2026 via a full sampler-vs-texture sweep,
    after `Wall_Leak_diff_shader`'s own distinct bug (a genuinely separate Opacity-slot file
    colliding on import with its Diffuse slot, fixed separately) turned out to have a sibling: 30
    "mask"-kind masters whose OpacityMask node was already correctly `SAMPLERTYPE_MASKS`, but still
    pointed at the shared, `TC_DEFAULT`/sRGB diffuse asset -- `_repair_mask_opacity_sampler` /
    `_repair_translucent_opacity_sampler`'s structural splits, and the new-master creation paths in
    `_load_or_create_master`, all only ever copied the shared node's EXISTING texture reference
    across (or `diffuse_texture` directly), never converted it to a Masks-compatible asset.
    """
    if texture is None or not isinstance(texture, unreal.Texture2D):
        return texture
    src_path = texture.get_path_name().split(".")[0]
    if src_path.endswith("_Mask"):
        return texture  # already a dedicated masks variant -- do not chain _Mask_Mask
    dst_path = f"{src_path}_Mask"
    existing = _load_if_exists(dst_path)
    if existing is not None:
        return existing
    duplicated = unreal.EditorAssetLibrary.duplicate_asset(src_path, dst_path)
    if duplicated is None or not isinstance(duplicated, unreal.Texture2D):
        return texture
    duplicated.set_editor_property("srgb", False)
    duplicated.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_MASKS)
    unreal.EditorAssetLibrary.save_loaded_asset(duplicated)
    return duplicated


def _repair_base_color_sampler_type(master):
    """Correct MP_BASE_COLOR's own node back to SAMPLERTYPE_COLOR when it is stuck at MASKS.

    A sixth legacy shape, found live 29 Sept 2026 on the SAME sampler-vs-texture-compression sweep
    that found the fifth (see `_repair_opacity_texture_compression_mismatch`): 2 "opaque"-kind
    masters (`glass_shader`, `Freezer_Ice_Translucent`) had their BaseColor node's sampler_type
    stuck at SAMPLERTYPE_MASKS -- the inverse direction of every other repair in this file, and the
    only one that touches BaseColor rather than Opacity/OpacityMask. Both materials' own diffuse
    texture is a normal `TC_DEFAULT`/sRGB asset, so this is unambiguously a stale leftover (most
    plausibly from an earlier build where the material was briefly classified "mask" kind and this
    node started life as that branch's OpacityMask node, before a reclassification pass repointed
    MP_BASE_COLOR at it without ever resetting its sampler_type). BaseColor never legitimately
    needs Masks sampling, so this repair is unconditional -- no kind/blend_mode gate needed.
    """
    if master is None:
        return False
    edit = unreal.MaterialEditingLibrary
    node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_BASE_COLOR)
    if not isinstance(node, unreal.MaterialExpressionTextureSample):
        return False
    try:
        current = node.get_editor_property("sampler_type")
    except Exception:  # noqa: BLE001
        return False
    if current != unreal.MaterialSamplerType.SAMPLERTYPE_MASKS:
        return False
    node.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_COLOR)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return True


def _repair_translucent_opacity_sampler(master):
    """Give Opacity its own Masks-sampler node on a "translucent" kind master built before that
    split existed (see _load_or_create_master).

    Detected purely structurally -- no rig/JSON needed -- by Opacity and BaseColor sharing the
    exact same input node. Sampling that node's Alpha for Opacity is a hard SM5 compile error in
    this project ("Sampler type is Color, should be Masks"), not a benign warning; confirmed live
    in-editor on Wall_Leak_diff_shader/reinforcedglass_diffuse_shader (4 Sept 2026), both showing
    the default checkerboard fallback with that exact error banner on the BaseColor node.
    """
    if master is None or not isinstance(master, unreal.Material):
        return False
    try:
        if master.get_editor_property("blend_mode") != unreal.BlendMode.BLEND_TRANSLUCENT:
            return False
    except Exception:  # noqa: BLE001
        return False
    edit = unreal.MaterialEditingLibrary
    opacity_node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_OPACITY)
    base_node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_BASE_COLOR)
    if (not isinstance(opacity_node, unreal.MaterialExpressionTextureSampleParameter2D)
            or base_node is None or opacity_node.get_name() != base_node.get_name()):
        return False
    texture = opacity_node.get_editor_property("texture")
    opacity_src = edit.create_material_expression(
        master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 150)
    opacity_src.set_editor_property("parameter_name", "Opacity")
    opacity_src.set_editor_property("texture", _masks_compressed_variant(texture))
    opacity_src.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS)
    edit.connect_material_property(opacity_src, "A", unreal.MaterialProperty.MP_OPACITY)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return True


def _material_texture_bindings(material, rig):
    """Resolve texture paths, including class-specific shader slots the JSON may omit."""
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

    opacity = material.get("opacity")
    if not opacity:
        opacity = by_slot.get("Opacity")
    return diffuse, normal, opacity, by_slot


def _material_declares_alpha_texture(material, rig):
    name = material.get("name")
    for entry in rig.get("textures") or []:
        if entry["material"] == name and entry.get("declaresAlphaTexture"):
            return True
    return False


def _material_has_opacity_slot_texture(material, rig):
    """A texture the exporter assigned to a real Opacity/Mask slot, bound to a genuinely
    different file than the Diffuse slot -- not the diffuse map's own alpha channel.

    An "Opacity" slot entry existing is not sufficient on its own: measured on `glass_shader`,
    the exporter bound BOTH Diffuse and Opacity to the exact same file (glass_diffuse.png), whose
    alpha channel turns out to be uniformly opaque -- the slot exists but carries no real
    coverage data, same failure mode `_diffuse_png_alpha_extrema` exists to catch. Distinct from
    `declaresAlphaTexture`, which can also be wrong (see that function's docstring).
    """
    name = material.get("name")
    diffuse_file, _normal, _opacity, _by_slot = _material_texture_bindings(material, rig)
    for entry in rig.get("textures") or []:
        if (entry.get("material") == name and entry.get("slot") == "Opacity"
                and entry.get("file") and entry.get("file") != diffuse_file):
            return True
    return False


def _png_chunks(path):
    with open(path, "rb") as handle:
        data = handle.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    pos = 8
    chunks = {}
    idat = bytearray()
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        if tag == b"IDAT":
            idat += chunk
        elif tag == b"IEND":
            break
        else:
            chunks[tag] = chunk
        pos += 12 + length
    chunks[b"IDAT"] = bytes(idat)
    return chunks


def _png_unfilter(data, width, height, bpp):
    stride = width * bpp
    out = bytearray(height * stride)
    prev_row = bytearray(stride)
    pos = 0
    for y in range(height):
        filter_type = data[pos]
        pos += 1
        row = bytearray(data[pos:pos + stride])
        pos += stride
        if filter_type == 1:  # Sub
            for i in range(stride):
                row[i] = (row[i] + (row[i - bpp] if i >= bpp else 0)) & 0xFF
        elif filter_type == 2:  # Up
            for i in range(stride):
                row[i] = (row[i] + prev_row[i]) & 0xFF
        elif filter_type == 3:  # Average
            for i in range(stride):
                a = row[i - bpp] if i >= bpp else 0
                row[i] = (row[i] + ((a + prev_row[i]) // 2)) & 0xFF
        elif filter_type == 4:  # Paeth
            for i in range(stride):
                a = row[i - bpp] if i >= bpp else 0
                b = prev_row[i]
                c = prev_row[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                row[i] = (row[i] + pr) & 0xFF
        out[y * stride:(y + 1) * stride] = row
        prev_row = row
    return bytes(out)


def _diffuse_png_alpha_extrema(path):
    """(min, max) alpha byte value across an RGBA/LA 8-bit PNG, or None if it has no alpha
    channel / can't be parsed. Stdlib-only (struct+zlib) -- UE5's embedded Python has no PIL,
    and Texture2D's `Source` property is not readable from Python.

    Exists because `declaresAlphaTexture` (the exporter's own flag) is not reliable: measured
    29 Sept 2026 on `Window_Material`'s diffuse (Round_Windows_diffuse.png) -- the manifest marks
    it True, but the decoded PNG's alpha channel is uniformly 255 (opaque) end to end.
    """
    try:
        chunks = _png_chunks(path)
        if not chunks or b"IHDR" not in chunks:
            return None
        width, height, bit_depth, color_type = struct.unpack(">IIBB", chunks[b"IHDR"][:10])
        if color_type not in (4, 6) or bit_depth != 8:
            return None
        channels = 4 if color_type == 6 else 2
        raw = zlib.decompress(chunks[b"IDAT"])
        pixels = _png_unfilter(raw, width, height, channels)
        alpha_min, alpha_max = 255, 0
        for i in range(channels - 1, len(pixels), channels):
            v = pixels[i]
            if v < alpha_min:
                alpha_min = v
            if v > alpha_max:
                alpha_max = v
        return (alpha_min, alpha_max)
    except Exception:  # noqa: BLE001 -- best-effort signal, never block an import on this
        return None


def _material_rendering_kind(material, rig, manifest_dir=None):
    """Map decoded BioShock material flags to a UE5 master-material variant.

    OutputBlending ordinals are still UNKNOWN individually, but 2 and 3 are carried through as
    translucent and additive rather than ignored. FluidShader surfaces are translucent by class.
    Window-named shaders are a measured heuristic on Medical: they carry no OutputBlending flag
    but render as glass in the shipped game.
    """
    class_name = material.get("className") or ""
    name_lower = (material.get("name") or "").lower()

    # A real Opacity MaskMaterial the exporter judged safe to use as coverage.
    if material.get("opacity"):
        # outputBlending 1/2 (blood splats, drips, decals) means SOFT alpha blend -- a hard
        # BLEND_MASKED clip gives a jagged 1-bit edge and reads as "a weird texture". A genuine
        # hole (bMasked, e.g. wallhole_*) stays a hard cutout.
        if material.get("outputBlending") in (1, 2) and not material.get("masked"):
            return "translucent_mask"
        return "mask"
    # `bMasked` alone is NOT a reliable hard-cutout signal in this game. 15 of 1-Medical's 55
    # masked=True materials (rim-shaders, corpses, security bots, a chained door) have no Opacity
    # struct and are SOLID surfaces whose diffuse alpha is packed spec/gloss/self-illum data, not
    # coverage. Forcing BLEND_MASKED on those wires diffuse.A to the opacity mask and speckles the
    # surface with holes wherever the packed alpha is low.
    #
    # Trust masked=True when EITHER: the name says cutout (foliage, grating, alpha-test -- catches
    # 5 of the 15 solid-vs-cutout exceptions plant/kelp materials would otherwise miss without
    # this), OR the exporter itself declared a texture slot for this material with
    # `usage == "Mask"` -- a real, explicit exporter-asserted signal, not a name guess. Measured
    # 29 Sept 2026: of Medical's 55 masked=True materials, exactly 40 have a usage=="Mask" texture
    # entry, and that list is a clean, plausible "needs a cutout" set (Walltech_01/03,
    # WallTechAnim_Fan/Cog/Lattice/Wheel/Cam/ShaftB, wallHole_*/Grate_Flat, Broken_Stairs, carpets,
    # dripping stains, debris/trash, torn-paper signs/newspapers, oil slicks, ice patches) while
    # the 15 without it are exactly the rim-shader/corpse/security-bot solid-surface set the
    # original name-only heuristic was built to protect. `WallTechAnim_Fan` specifically -- a
    # spinning fan blade needs real gaps between blades to not render as a solid disc -- was
    # missed by the name-only heuristic (no "fan" pattern in the cutout list) despite genuinely
    # varying 0-255 diffuse alpha (confirmed via `_diffuse_png_alpha_extrema`); this usage=="Mask"
    # check catches it without widening the name list to something less precise.
    cutout_name = any(t in name_lower for t in (
        "alphatest", "alpha_test", "leaf", "leaves", "foliage", "plant", "ivy", "vine", "kelp",
        "grate", "grating", "fence", "chain", "mesh_wire", "wire_mesh", "net", "lattice"))
    has_mask_usage_texture = any(
        entry.get("material") == material.get("name") and entry.get("usage") == "Mask"
        for entry in rig.get("textures") or [])
    if material.get("masked") and (cutout_name or has_mask_usage_texture):
        return "mask"
    def _has_usable_transparency():
        """Real coverage data exists somewhere for this material -- a dedicated Opacity-slot
        texture, or a diffuse map whose own alpha channel actually varies. Guards the two
        "this looks translucent" signals below that are inferred rather than authoritative
        (`declaresAlphaTexture`, and the bare window/glass name heuristic): without this, a
        material with genuinely no coverage data anywhere renders BLEND_TRANSLUCENT at a
        constant opacity of 1.0 -- worse than opaque (skips normal opaque-surface shading) for
        no visual benefit. `declaresAlphaTexture` itself is not trustworthy enough to skip this
        check: measured 29 Sept 2026 on Window_Material's diffuse (Round_Windows_diffuse.png),
        the manifest marks it True but the decoded PNG's alpha is uniformly 255 end to end.
        """
        if _material_has_opacity_slot_texture(material, rig):
            return True
        if not manifest_dir:
            # No filesystem access to check -- do not downgrade on a guess either way.
            return True
        diffuse_file, _normal, _opacity, _by_slot = _material_texture_bindings(material, rig)
        if not diffuse_file:
            return False
        extrema = _diffuse_png_alpha_extrema(
            os.path.join(manifest_dir, diffuse_file.replace("/", os.sep)))
        if extrema is None:
            return True  # couldn't read it -- do not downgrade on a guess
        return extrema[0] != extrema[1]

    if _material_declares_alpha_texture(material, rig) and _has_usable_transparency():
        return "translucent"

    output_blending = material.get("outputBlending")
    # "OutputBlending ordinals are still UNKNOWN individually" (see this function's own
    # docstring) -- 1/2 are just as inferred as declaresAlphaTexture and the name heuristic, so
    # they get the same _has_usable_transparency() guard. 3 (additive) does not: an additive
    # surface with no real alpha variation still looks fine (it decays to nothing wherever the
    # base colour is black), unlike straight translucent alpha which is opaque everywhere a
    # texture-alpha source turns out to be degenerate.
    if output_blending in (1, 2) and _has_usable_transparency():
        return "translucent"
    if output_blending == 3:
        return "additive"
    # FluidShader/WindowShader are explicit engine-class markers, not inferred from a texture or
    # a name -- the original engine's own transparency mechanism for these classes is likely not
    # texture-alpha-based at all, so they are not gated on decoded alpha data either.
    if class_name in ("FluidShader", "FluidSurfaceShader"):
        return "translucent"
    if class_name in ("WindowShader", "LightBeamShader"):
        return "translucent" if class_name == "WindowShader" else "additive"
    if (class_name == "Shader" and ("window" in name_lower or "glass" in name_lower)
            and _has_usable_transparency()):
        return "translucent"
    return "opaque"


def _blend_mode_for_kind(kind):
    if kind == "mask":
        return unreal.BlendMode.BLEND_MASKED
    if kind in ("translucent", "translucent_mask"):
        return unreal.BlendMode.BLEND_TRANSLUCENT
    if kind == "additive":
        return unreal.BlendMode.BLEND_ADDITIVE
    return unreal.BlendMode.BLEND_OPAQUE


def _wire_opacity_mask(master, opacity_texture=None, soft=False):
    """Make an authored RGB coverage texture drive the master's opacity.

    soft=False (a genuine cutout): BLEND_MASKED, the texture's R clips MP_OPACITY_MASK -- a hard
    1-bit edge, right for a hole punched through a wall.
    soft=True (a blood splat / drip / decal, outputBlending 1-2): BLEND_TRANSLUCENT, the texture's
    R drives MP_OPACITY -- a soft alpha blend. A hard clip here is the jagged-edge "weird texture".
    """
    edit = unreal.MaterialEditingLibrary
    prop = unreal.MaterialProperty.MP_OPACITY if soft else unreal.MaterialProperty.MP_OPACITY_MASK
    master.set_editor_property(
        "blend_mode",
        unreal.BlendMode.BLEND_TRANSLUCENT if soft else unreal.BlendMode.BLEND_MASKED)
    node = edit.get_material_property_input_node(master, prop)
    if (not isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D)
            or str(node.get_editor_property("parameter_name")) != "OpacityMask"):
        node = edit.create_material_expression(
            master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 450)
        node.set_editor_property("parameter_name", "OpacityMask")
        edit.connect_material_property(node, "R", prop)
    node.set_editor_property("texture", opacity_texture or _default_base_color_texture())
    node.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return node


def _repair_opacity_sampler_type(master, property_id):
    """Correct an Opacity/OpacityMask input node's `sampler_type` to MASKS when it is already a
    separate node from BaseColor but was never actually set to MASKS.

    A third legacy shape, distinct from the two `_repair_translucent_opacity_sampler`/
    `_repair_mask_opacity_sampler` already handle (a still-shared node; a separate node pointed at
    the wrong texture): confirmed live 29 Sept 2026 on `Wall_Leak_diff_shader`'s master via the
    real UE5 material editor's own SM5 compile-error banner (nullrhi commandlets never trigger
    real shader compilation, so no headless verify in this project can catch this class of bug --
    it has to be read back from the actual node property). That master's Opacity node was already
    a distinct `MaterialExpressionTextureSampleParameter2D` (not sharing BaseColor's plain
    `MaterialExpressionTextureSample` node) with the correct parameter name ("Opacity") and even
    the right texture -- `_repair_translucent_opacity_sampler`'s shared-node check and
    `_repair_translucent_opacity_texture`'s texture check both correctly found nothing to do and
    reported success. Its `sampler_type` was simply still the default `SAMPLERTYPE_COLOR`, left
    over from however this specific master was first built (predates every repair pass in this
    file -- it is the plain-`TextureSample`-BaseColor shape also seen on `glass_safety_shader`),
    and none of the existing repairs ever checked that property directly, only node identity and
    the node's `texture` reference.
    """
    if master is None:
        return False
    edit = unreal.MaterialEditingLibrary
    node = edit.get_material_property_input_node(master, property_id)
    if not isinstance(node, unreal.MaterialExpressionTextureSample):
        return False
    try:
        current = node.get_editor_property("sampler_type")
    except Exception:  # noqa: BLE001
        return False
    if current == unreal.MaterialSamplerType.SAMPLERTYPE_MASKS:
        return False
    node.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return True


def _repair_opacity_texture_compression_mismatch(master, property_id):
    """Repoint an Opacity/OpacityMask node already `SAMPLERTYPE_MASKS`, but whose texture
    reference is NOT actually Masks-compressed, to a dedicated Masks-compressed sibling asset.

    A fifth legacy shape, found live 29 Sept 2026 via a full sampler-vs-texture-compression sweep
    run after `Wall_Leak_diff_shader`'s own distinct bug (a genuinely separate Opacity-slot file
    colliding on import with its Diffuse slot) was fixed: 30 further "mask"-kind masters already
    had a correctly-separate node with the correct `SAMPLERTYPE_MASKS` -- neither
    `_repair_mask_opacity_sampler`/`_repair_translucent_opacity_sampler` (only fire on a
    still-shared node) nor `_repair_opacity_sampler_type` (only checks the sampler_type property
    itself, never what the texture it points at is actually compressed as) had any way to catch
    this. Their node's TEXTURE was still the shared diffuse asset -- correctly `TC_DEFAULT`/sRGB
    for BaseColor's own read of it, but a hard SM5 sampler/compression mismatch for this node
    (the inverse of the `Wall_Leak_diff_shader` banner: "Sampler type is Masks, should be
    Color" -- from the compiler's perspective the texture itself needs Masks, not the sampler).
    See `_masks_compressed_variant`, which both the structural-split repairs above and the
    new-master creation paths in `_load_or_create_master` also use for exactly this reason.
    """
    if master is None:
        return False
    edit = unreal.MaterialEditingLibrary
    node = edit.get_material_property_input_node(master, property_id)
    if not isinstance(node, unreal.MaterialExpressionTextureSample):
        return False
    try:
        sampler = node.get_editor_property("sampler_type")
        texture = node.get_editor_property("texture")
    except Exception:  # noqa: BLE001
        return False
    if sampler != unreal.MaterialSamplerType.SAMPLERTYPE_MASKS or texture is None:
        return False
    try:
        compression = texture.get_editor_property("compression_settings")
    except Exception:  # noqa: BLE001
        return False
    if compression == unreal.TextureCompressionSettings.TC_MASKS:
        return False
    variant = _masks_compressed_variant(texture)
    if variant is None or variant.get_path_name() == texture.get_path_name():
        return False
    node.set_editor_property("texture", variant)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return True


def _repair_mask_opacity_sampler(master):
    """Give OpacityMask its own Masks-sampler node on a "mask" kind master built before that split
    existed in this code path (see `_load_or_create_master`'s `kind == "mask"` branch).

    Mirrors `_repair_translucent_opacity_sampler` exactly, gated on `BLEND_MASKED`/
    `MP_OPACITY_MASK` instead of `BLEND_TRANSLUCENT`/`MP_OPACITY` -- the "mask" branch had the
    identical shared-Color-sampler-node SM5 compile bug the translucent branch was fixed for on
    4 Sept 2026, just never got the same fix. Every "mask" kind master that predates 29 Sept 2026
    was built with this bug (the split never existed for this branch until then), so this repairs
    potentially many masters, not just the one (`WallTechAnim_Fan`) that surfaced it live.
    """
    if master is None or not isinstance(master, unreal.Material):
        return False
    try:
        if master.get_editor_property("blend_mode") != unreal.BlendMode.BLEND_MASKED:
            return False
    except Exception:  # noqa: BLE001
        return False
    edit = unreal.MaterialEditingLibrary
    mask_node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_OPACITY_MASK)
    base_node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_BASE_COLOR)
    if (not isinstance(mask_node, unreal.MaterialExpressionTextureSampleParameter2D)
            or base_node is None or mask_node.get_name() != base_node.get_name()):
        return False
    texture = mask_node.get_editor_property("texture")
    mask_src = edit.create_material_expression(
        master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 150)
    mask_src.set_editor_property("parameter_name", "OpacityMask")
    mask_src.set_editor_property("texture", _masks_compressed_variant(texture))
    mask_src.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS)
    edit.connect_material_property(mask_src, "A", unreal.MaterialProperty.MP_OPACITY_MASK)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return True


def _repair_translucent_opacity_texture(master, opacity_texture):
    """A "translucent"-kind master's Opacity sampler defaulted to the diffuse texture (the only
    source `_load_or_create_master` used to read for it, see the git history around 29 Sept 2026).
    When a real, separately-exported Opacity-slot texture exists for this material, repoint the
    Opacity sampler node at it instead — the diffuse map's own alpha is very often uniformly
    opaque (packed spec/gloss data, not coverage), which reads live as fully-opaque "glass" with
    no visible transparency.

    The node feeding MP_OPACITY on a master built by an older pass is not reliably a
    `MaterialExpressionTextureSampleParameter2D` named "Opacity" -- measured live on
    `glass_safety_shader`'s master, it is a plain (non-parameter) `MaterialExpressionTextureSample`
    with no `parameter_name` at all. Accept either class; only require that it actually exposes a
    settable `texture` property and is not the same node BaseColor reads from (that shared-node
    shape is `_repair_translucent_opacity_sampler`'s job, which must run first -- see its call
    site in `_load_or_create_master`).

    A fourth shape, found live 29 Sept 2026 on `Exterior_Window_02_Glass_Shader`'s master (a
    `WindowShader`-class material with a genuine, distinct Opacity-slot texture,
    `Exterior_Window_02_Glass_Diffuse.png`): `MP_OPACITY` has **no node connected at all**, not a
    wrong one -- the master predates this material ever having its Opacity wired at all. If
    `opacity_node` is `None`, create a fresh `SAMPLERTYPE_MASKS` node from scratch (same as
    `_load_or_create_master`'s new-master path does) rather than only repointing an existing one.
    """
    if master is None or opacity_texture is None:
        return False
    try:
        if master.get_editor_property("blend_mode") != unreal.BlendMode.BLEND_TRANSLUCENT:
            return False
    except Exception:  # noqa: BLE001
        return False
    edit = unreal.MaterialEditingLibrary
    opacity_node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_OPACITY)
    base_node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_BASE_COLOR)

    if opacity_node is None:
        new_node = edit.create_material_expression(
            master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 150)
        new_node.set_editor_property("parameter_name", "Opacity")
        new_node.set_editor_property("texture", opacity_texture)
        new_node.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS)
        edit.connect_material_property(new_node, "A", unreal.MaterialProperty.MP_OPACITY)
        edit.recompile_material(master)
        unreal.EditorAssetLibrary.save_loaded_asset(master)
        return True

    if not isinstance(opacity_node, unreal.MaterialExpressionTextureSample):
        return False
    if base_node is not None and opacity_node.get_name() == base_node.get_name():
        return False  # still the shared-node shape; the structural split has to run first
    try:
        current = opacity_node.get_editor_property("texture")
    except Exception:  # noqa: BLE001
        return False
    if current is not None and current.get_path_name() == opacity_texture.get_path_name():
        return False
    opacity_node.set_editor_property("texture", opacity_texture)
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return True


def _load_or_create_master(material, content_root, diffuse_texture=None, normal_texture=None,
                           opacity_texture=None, rig=None, manifest_dir=None):
    """Create the small, shared graph every imported BioShock material instances.

    Masked, translucent and additive variants are separate masters so UE5 blend mode and opacity
    wiring stay compile-time constants. Two-sidedness is part of the master key for the same reason.
    """
    rig = rig or {}
    kind = _material_rendering_kind(material, rig, manifest_dir=manifest_dir)
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
        # A prior import that left NULL TextureSampleParameter2D defaults must not be reused
        # as-is — UE then falls back to Default Material in game (wall textures "broken").
        _repair_null_texture_parameters(existing)
        # Unconditional, independent of every Opacity/OpacityMask repair below -- see
        # _repair_base_color_sampler_type's docstring for the (rare, 2-instance) stale-leftover
        # shape this catches.
        _repair_base_color_sampler_type(existing)
        # Must run before _repair_translucent_opacity_texture: a master built under the
        # pre-split code still has Opacity and BaseColor sharing one node (parameter_name
        # "BaseColor", not "Opacity"), so the opacity-texture repair below would find the wrong
        # node shape and silently no-op, then this split would recreate the diffuse-as-opacity
        # bug it exists to fix -- copying whatever texture the shared node already had.
        _repair_translucent_opacity_sampler(existing)
        # Same reasoning as the translucent split above, mirrored for "mask" kind's identical
        # shared-node SM5 bug (see _repair_mask_opacity_sampler's docstring) -- must also run
        # before anything else touches this master's OpacityMask node.
        _repair_mask_opacity_sampler(existing)
        # A third legacy shape neither split-repair above catches: a node that was ALREADY
        # separate from BaseColor (so the shared-node checks above correctly found nothing to
        # split) but whose sampler_type was simply never set to MASKS to begin with. Cheap and
        # idempotent to check regardless of blend mode -- see _repair_opacity_sampler_type's
        # docstring for how this was found (a live SM5 compile-error banner nullrhi cannot see).
        _repair_opacity_sampler_type(existing, unreal.MaterialProperty.MP_OPACITY)
        _repair_opacity_sampler_type(existing, unreal.MaterialProperty.MP_OPACITY_MASK)
        # A fifth legacy shape neither of the above catches: a node already separate AND already
        # SAMPLERTYPE_MASKS, but still pointed at the shared, Color-compressed diffuse asset --
        # see _repair_opacity_texture_compression_mismatch's docstring (found via a full
        # sampler-vs-texture-compression sweep, 30 "mask"-kind masters live 29 Sept 2026).
        _repair_opacity_texture_compression_mismatch(existing, unreal.MaterialProperty.MP_OPACITY)
        _repair_opacity_texture_compression_mismatch(
            existing, unreal.MaterialProperty.MP_OPACITY_MASK)
        if material.get("opacity"):
            _wire_opacity_mask(existing, opacity_texture, soft=(kind == "translucent_mask"))
        elif kind == "translucent":
            _repair_translucent_opacity_texture(existing, opacity_texture)
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

    # Partial-create path: package existed but graph was empty / NULL-textured. Repair rather
    # than stack a second set of expressions on a broken master.
    edit = unreal.MaterialEditingLibrary
    if (_repair_null_texture_parameters(master)
            and edit.get_num_material_expressions(master) >= 2):
        return master

    master.set_editor_property("two_sided", two_sided)
    master.set_editor_property("used_with_skeletal_mesh", True)
    master.set_editor_property("used_with_static_mesh", True)
    blend_mode = _blend_mode_for_kind(kind)
    if blend_mode != unreal.BlendMode.BLEND_OPAQUE:
        master.set_editor_property("blend_mode", blend_mode)

    # Wipe a partial empty master before wiring — otherwise we accumulate orphan expressions.
    if edit.get_num_material_expressions(master) > 0:
        edit.delete_all_material_expressions(master)

    base = edit.create_material_expression(master, unreal.MaterialExpressionTextureSampleParameter2D, -500, -150)
    base.set_editor_property("parameter_name", "BaseColor")
    base.set_editor_property("texture", diffuse_texture or _default_base_color_texture())
    if kind == "additive":
        edit.connect_material_property(base, "RGB", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
        edit.connect_material_property(base, "A", unreal.MaterialProperty.MP_OPACITY)
    else:
        edit.connect_material_property(base, "RGB", unreal.MaterialProperty.MP_BASE_COLOR)
        if kind == "mask":
            # Same "Sampler type is Color, should be Masks" SM5 compile error as the translucent
            # branch below, on the exact same shared-node pattern -- BaseColor's node defaults to
            # a Color-type sampler, and MP_OPACITY_MASK needs a Masks-type one. This branch never
            # got the same fix when the translucent one did (4 Sept 2026): confirmed live 29 Sept
            # 2026 on `WallTechAnim_Fan` (reclassified from "opaque" to "mask" the same day, see
            # this function's masked=True/usage=="Mask" comment -- it would have hit this compile
            # failure and fallen back to the default checkerboard regardless of that fix). Give
            # OpacityMask its own Masks-sampler node instead of reading BaseColor's Color-sampler
            # alpha directly.
            mask_src = edit.create_material_expression(
                master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 150)
            mask_src.set_editor_property("parameter_name", "OpacityMask")
            mask_src.set_editor_property(
                "texture",
                _masks_compressed_variant(diffuse_texture) or _default_base_color_texture())
            mask_src.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS)
            edit.connect_material_property(mask_src, "A", unreal.MaterialProperty.MP_OPACITY_MASK)
        elif kind == "translucent":
            # Sampling BaseColor's own Alpha output for Opacity reuses a Color-sampler node for a
            # mask read -- a hard SM5 compile error in this project ("Sampler type is Color,
            # should be Masks"), not a benign warning; confirmed live in-editor on
            # Wall_Leak_diff_shader/reinforcedglass_diffuse_shader, 4 Sept 2026 (both fell back to
            # the default checkerboard material). Give Opacity its own Masks-sampler node.
            # Prefer a real, separately-exported Opacity-slot texture when one exists (see
            # _repair_translucent_opacity_texture) -- only fall back to reading the diffuse map's
            # own alpha when no dedicated opacity source was ever exported for this material.
            opacity_src = edit.create_material_expression(
                master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 150)
            opacity_src.set_editor_property("parameter_name", "Opacity")
            opacity_src.set_editor_property(
                "texture",
                opacity_texture or _masks_compressed_variant(diffuse_texture)
                or _default_base_color_texture())
            opacity_src.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS)
            edit.connect_material_property(opacity_src, "A", unreal.MaterialProperty.MP_OPACITY)

    normal = edit.create_material_expression(master, unreal.MaterialExpressionTextureSampleParameter2D, -500, 50)
    normal.set_editor_property("parameter_name", "Normal")
    normal.set_editor_property("texture", normal_texture or _default_normal_texture())
    normal.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL)
    edit.connect_material_property(normal, "RGB", unreal.MaterialProperty.MP_NORMAL)

    roughness = edit.create_material_expression(master, unreal.MaterialExpressionScalarParameter, -500, 250)
    roughness.set_editor_property("parameter_name", "Roughness")
    roughness.set_editor_property("default_value", 0.5)
    edit.connect_material_property(roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)
    if material.get("opacity"):
        _wire_opacity_mask(master, opacity_texture, soft=(kind == "translucent_mask"))
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return master


def _create_material_instances(rig, destination, content_root, imported_by_file=None,
                               manifest_dir=None):
    """Create/update one material instance per authored material, preserving slot order."""
    imported_by_file = imported_by_file or {}
    opacity_identities = _opacity_entry_identities(rig)
    textures = {}
    for entry in rig.get("textures") or []:
        is_opacity = (entry.get("material"), entry.get("slot")) in opacity_identities
        textures[(entry["material"], entry["slot"])] = _resolve_imported_texture(
            entry, destination, imported_by_file, is_opacity=is_opacity)

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

        # repair_light_beams.py moves LightBeamShader instances onto its own authored master
        # (falloff x panning dust, tint, depth fade). Re-running this generic pass used to put them
        # back on a raw-texture additive master -- white, untinted, no depth fade. It happened after
        # the 28 Sept glass-material rerun and showed up live (30 Sept) as a white sheet across the
        # view at the arrival porthole: 11 of Medical's 14 beam actors use MI_Light_Beam_01. Leave
        # an already-repaired beam instance alone.
        current_parent = instance.get_editor_property("parent")
        if (material.get("className") == "LightBeamShader" and current_parent is not None
                and current_parent.get_name() == "M_BioShock_LightBeam_Repaired_V1"):
            instances.append(instance)
            continue

        library = unreal.MaterialEditingLibrary
        diffuse, normal, opacity, by_slot = _material_texture_bindings(material, rig)
        # When Diffuse and Opacity legitimately share one file (by_slot["Opacity"] == diffuse's
        # own file -- see _opacity_entry_identities), matching opacity_texture by file alone below
        # would also match the Diffuse slot's entry, and whichever key `textures.items()` happens
        # to iterate last would win -- order-dependent, and silently wrong half the time. Prefer
        # the literal "Opacity"-named slot's own texture whenever one exists; only fall back to a
        # file match for the rarer case where opacity came from the material's own top-level
        # field with no distinct "Opacity" slot to name.
        has_opacity_slot = by_slot.get("Opacity") is not None
        diffuse_texture = None
        normal_texture = None
        opacity_texture = None
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
            if slot == "Opacity" or (not has_opacity_slot and file == opacity):
                opacity_texture = texture

        instance.set_editor_property(
            "parent", _load_or_create_master(
                material, content_root, diffuse_texture=diffuse_texture,
                normal_texture=normal_texture, opacity_texture=opacity_texture, rig=rig,
                manifest_dir=manifest_dir))
        if diffuse_texture is not None:
            library.set_material_instance_texture_parameter_value(instance, "BaseColor", diffuse_texture)
        if normal_texture is not None:
            library.set_material_instance_texture_parameter_value(instance, "Normal", normal_texture)
        if opacity_texture is not None:
            library.set_material_instance_texture_parameter_value(
                instance, "OpacityMask", opacity_texture)

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

# Bumped when the Blender→UE normalizer's axis policy changes. Included in the fingerprint so a
# prior import stamped under Y-up normalize cannot be reused after the Z-up/-Y fix (h4).
NORMALIZER_AXIS_POLICY = "z_up_neg_y_v1"


def _existed(path):
    """Whether an asset is already present, for created-vs-updated reporting."""
    return unreal.EditorAssetLibrary.does_asset_exist(path)


def _delete_existing_mesh_assets(destination, name):
    """Delete mesh/skeleton/physics so reimport is a fresh create, not atomic reimport.

    Measured 4 Sept 2026 on AggressorBabyJane: LogEditorFactories 'Performing atomic reimport'
    then Built Skeletal Mesh [0.12s], then InternalPromptForCheckoutAndSave on the existing
    ~1.2 GiB package, then IntFitsIn In=2499805188 (~2.33 GiB). Same delete-then-import pattern
    as fix_compiled_world_materials._reimport_mesh.

    Animations under destination/Animations are left on disk. They do NOT silently re-bind to a
    newly created Skeleton at the same package path — loading them mid-import was the secondary
    crash (EditorAssetLibrary.LoadAsset → Error opening file on *_Skeleton.uasset). Re-import
    clips explicitly against the in-memory Skeleton after mesh save; use BIOSHOCK_ANIMS_ONLY /
    BIOSHOCK_ANIM_CHUNK on run_reimport_aggressor_babyjane.py rather than assuming orphans heal.
    """
    for suffix in ("", "_Skeleton", "_PhysicsAsset", "_Physics"):
        path = "%s/%s%s" % (destination, name, suffix)
        if not _existed(path):
            continue
        if unreal.EditorAssetLibrary.delete_asset(path):
            _log("  deleted existing %s before reimport" % path)
        else:
            _log("  WARNING: could not delete %s before reimport" % path)


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
        "sockets": [
            {
                "name": item["name"],
                "bone": item["bone"],
                "translation": item.get("translation"),
                "rotation": item.get("rotation"),
            }
            for item in (rig.get("sockets") or [])
        ],
        "mesh": _file_stamp(os.path.join(export_directory, rig["mesh"].replace("/", os.sep))),
        "normalizerAxisPolicy": NORMALIZER_AXIS_POLICY,
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
    """Names of AnimSequence packages under destination/Animations — path only, no load.

    Do not EditorAssetLibrary.load_asset here. After delete-then-reimport with
    AssetImportTask.save=False, leftover AnimSequences still reference the prior Skeleton
    package identity. Loading them re-opens AggressorBabyJane_Skeleton.uasset by path and
    has asserted (AsyncLoading2 !bHasFailed / 'Error opening file') even after the new
    mesh+skeleton were already save_loaded_asset'd (measured mesh-only recovery, 4 Sept 2026).
    Package-path leaf names are enough for fingerprint inventory.
    """
    folder = "%s/Animations" % destination
    if not unreal.EditorAssetLibrary.does_directory_exist(folder):
        return set()
    names = set()
    for path in unreal.EditorAssetLibrary.list_assets(folder, recursive=False) or []:
        # Soft paths look like /Game/.../Animations/ME_Fidget_A_idle.ME_Fidget_A_idle
        leaf = path.rsplit("/", 1)[-1]
        names.add(leaf.split(".", 1)[0] if "." in leaf else leaf)
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
         reuse_existing=True, rig_name_override=None, import_animations=True):
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
        if rig_name_override:
            rig = dict(rig)
            rig["name"] = rig_name_override
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
        if mesh_existed:
            # Fresh create avoids atomic reimport over a half-written / bloated package.
            _delete_existing_mesh_assets(destination, rig["name"])
            mesh_existed = _existed(f"{destination}/{rig['name']}")

        mesh_file = os.path.join(export_directory, rig["mesh"])
        if normalize_fbx:
            mesh_file = _normalize_fbx(mesh_file, export_directory, blender_path)
        assets = _import(
            mesh_file,
            destination,
            _skeletal_mesh_options(
                use_t0_as_ref_pose=rig["name"] == "LoadRoomDoorAnim"),
        )
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
        # AssetImportTask no longer saves (see _import); persist mesh + companion Skeleton before
        # ANY later step that might resolve the skeleton by package path (texture/material work is
        # fine; leftover AnimSequence load_asset was the measured crash — see
        # _animation_names_on_disk). Always use the in-memory `skeleton` / `mesh` objects below.
        if not unreal.EditorAssetLibrary.save_loaded_asset(skeleton):
            raise RuntimeError("save_loaded_asset failed for Skeleton of %s" % rig["name"])
        if not unreal.EditorAssetLibrary.save_loaded_asset(mesh):
            raise RuntimeError("save_loaded_asset failed for SkeletalMesh %s" % rig["name"])
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
            rig, destination, content_root, imported_by_file, manifest_dir=export_directory)
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

        # Re-save after materials/tags so later anim imports and fingerprint work see a stable package.
        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        imported[rig["name"]] = mesh

        notifies = 0
        animations = (rig.get("animations") or []) if import_animations else []
        for animation in animations:
            animation_file = os.path.join(export_directory, animation["file"])
            if normalize_fbx:
                animation_file = _normalize_fbx(animation_file, export_directory, blender_path)
            # Pass the in-memory Skeleton from this import — never reload it by path.
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
            unreal.EditorAssetLibrary.save_loaded_asset(sequence)

        _log(f"  {len(animations)} animations, {notifies} notifies")
        if rig.get("undecoded"):
            _log(f"  {rig['undecoded']} animations did not decode and are not present")
        if import_animations:
            _stamp_fingerprint(mesh, rig, destination, fingerprint)
        else:
            _log("  animation import intentionally deferred")

    _log(f"import report: {report['created']} created, {report['updated']} updated, "
         f"{report['reused']} reused, {report['skipped']} skipped, {report['unsupported']} unsupported")
    main.last_report = report
    return imported
