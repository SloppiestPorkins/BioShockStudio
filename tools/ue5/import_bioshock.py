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

This script is NOT verified. No Unreal editor was available when it was written, so every call below
is written from the documented API and none of it has been run. Treat a failure here as a bug in
this file rather than as evidence about the FBX. In particular:

  * Unreal may import the `SOCKET_*` null nodes as bones rather than ignoring them. If the imported
    skeleton has more bones than the manifest's `boneCount`, re-export with socket nodes turned off
    and let this script add the sockets to the Skeleton asset instead.
  * The animation notify API has moved between engine versions; both known names are tried.

WHAT THE MANIFEST CARRIES THAT THE FBX CANNOT
---------------------------------------------
Animation notifies (the reload beats and equip points the game fires), the socket a weapon rig hangs
off, and which weapon animation plays with which hand animation. FBX has no place for any of it.
"""

import json
import os

import unreal


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

    options = unreal.FbxImportUI()
    options.set_editor_property("import_mesh", False)
    options.set_editor_property("import_as_skeletal", True)
    options.set_editor_property("import_animations", True)
    options.set_editor_property("import_materials", False)
    options.set_editor_property("import_textures", False)
    options.set_editor_property("mesh_type_to_import", unreal.FBXImportType.FBXIT_ANIMATION)
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


def main(export_directory, content_root="/Game/BioShock"):
    """Import every rig in an export directory. Returns the imported skeletal meshes by rig name."""
    manifest_path = os.path.join(export_directory, "ue5_manifest.json")
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    _log(f"{manifest['sourceObject']} from {manifest['sourcePackage']}; "
         f"{len(manifest['rigs'])} rig(s), units in {manifest['unit']}, {manifest['upAxis']} up")

    imported = {}
    for rig in manifest["rigs"]:
        destination = f"{content_root}/{rig['name']}"
        _log(f"importing {rig['name']}: {rig['boneCount']} bones, {rig['vertexCount']} vertices")

        assets = _import(os.path.join(export_directory, rig["mesh"]), destination, _skeletal_mesh_options())
        mesh = next((a for a in assets if isinstance(a, unreal.SkeletalMesh)), None)
        if mesh is None:
            _log(f"FAILED to import {rig['mesh']}")
            continue

        skeleton = mesh.get_editor_property("skeleton")
        bones = len(skeleton.get_editor_property("bone_tree")) if skeleton else 0
        if bones and bones != rig["boneCount"]:
            # Almost certainly the SOCKET_ nulls; see the note at the top of this file.
            _log(f"WARNING: skeleton has {bones} bones, the export declares {rig['boneCount']}")

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
            assets = _import(
                os.path.join(export_directory, animation["file"]),
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

    return imported
