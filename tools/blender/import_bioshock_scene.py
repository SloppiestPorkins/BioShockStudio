"""Build a Blender armature and actions from a BioShock scene JSON.

Run headless:

    blender --background --python import_bioshock_scene.py -- scene.json out.blend

The scene JSON is produced by `bioshock-tool export-blender`. Bone order and indices are taken
verbatim from the game data, because Havok animation tracks address bones by index.
"""

import json
import math
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

# BioShock authors in centimetres with Z up in Havok's convention; Blender's default unit is metres.
SCENE_SCALE = 0.01

# A bone with zero length is invalid in Blender, so tips are pushed out along the bone's own axis.
MIN_BONE_LENGTH = 0.02


def parse_args():
    argv = sys.argv
    if "--" not in argv:
        raise SystemExit("usage: blender --background --python import_bioshock_scene.py -- scene.json out.blend")
    args = argv[argv.index("--") + 1:]
    if len(args) < 2:
        raise SystemExit("expected a scene json path and an output .blend path")
    return args[0], args[1]


def local_matrix(bone):
    translation = Vector(bone["translation"]) * SCENE_SCALE
    x, y, z, w = bone["rotation"]
    rotation = Quaternion((w, x, y, z)).to_matrix().to_4x4()
    scale = Matrix.Diagonal(Vector(bone["scale"]).to_4d())
    return Matrix.Translation(translation) @ rotation @ scale


def global_matrices(bones):
    """Compose reference-pose matrices into armature space. Bones are stored parent-first."""
    result = []
    for bone in bones:
        local = local_matrix(bone)
        parent = bone["parent"]
        result.append(local if parent < 0 else result[parent] @ local)
    return result


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def build_armature(scene):
    bones = scene["bones"]
    globals_ = global_matrices(bones)

    armature_data = bpy.data.armatures.new(scene["skeletonName"] or "Skeleton")
    armature = bpy.data.objects.new(scene["sourceObject"], armature_data)
    bpy.context.collection.objects.link(armature)

    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")

    edit_bones = []
    for index, bone in enumerate(bones):
        edit_bone = armature_data.edit_bones.new(bone["name"])
        matrix = globals_[index]

        head = matrix.to_translation()
        direction = matrix.to_3x3() @ Vector((1.0, 0.0, 0.0))
        if direction.length < 1e-6:
            direction = Vector((1.0, 0.0, 0.0))

        # Length is cosmetic in Blender; it does not affect the pose, so a child's offset is used
        # where available purely to make the rig readable.
        length = MIN_BONE_LENGTH
        for child in bones:
            if child["parent"] == index:
                candidate = (Vector(child["translation"]) * SCENE_SCALE).length
                if candidate > MIN_BONE_LENGTH:
                    length = candidate
                    break

        edit_bone.head = head
        edit_bone.tail = head + direction.normalized() * length
        edit_bones.append(edit_bone)

    for index, bone in enumerate(bones):
        if bone["parent"] >= 0:
            edit_bones[index].parent = edit_bones[bone["parent"]]
            edit_bones[index].use_connect = False

    bpy.ops.object.mode_set(mode="OBJECT")

    # Preserve the game's bone index and socket role as custom properties so downstream tools
    # (and the FBX/UE5 path) do not have to re-derive them from names.
    for index, bone in enumerate(bones):
        pose_bone = armature.pose.bones[bone["name"]]
        pose_bone["bioshock_bone_index"] = bone["index"]
        pose_bone["bioshock_is_socket"] = bool(bone["isSocket"])

    return armature, globals_


def build_action(armature, scene, animation, globals_):
    bones = scene["bones"]
    action = bpy.data.actions.new(f"{animation['owner']}_{animation['name']}")
    action.use_fake_user = True

    # Original timing is carried as metadata rather than resampled: authored rates vary per
    # animation (30.00, 29.94 and 27.02 all occur within the pistol set alone).
    action["bioshock_frame_duration"] = animation["frameDuration"]
    action["bioshock_duration"] = animation["duration"]
    action["bioshock_owner"] = animation["owner"]

    if armature.animation_data is None:
        armature.animation_data_create()
    armature.animation_data.action = action

    frame_count = animation["frameCount"]

    for track in animation["tracks"]:
        bone_index = track["boneIndex"]
        if bone_index < 0 or bone_index >= len(bones):
            continue

        pose_bone = armature.pose.bones[bones[bone_index]["name"]]
        pose_bone.rotation_mode = "QUATERNION"

        parent_index = bones[bone_index]["parent"]
        rest = globals_[bone_index]
        rest_inverse = rest.inverted()

        translations = track["translations"]
        rotations = track["rotations"]
        scales = track["scales"]

        for frame in range(frame_count):
            translation = Vector(translations[frame * 3:frame * 3 + 3]) * SCENE_SCALE
            x, y, z, w = rotations[frame * 4:frame * 4 + 4]
            rotation = Quaternion((w, x, y, z)).to_matrix().to_4x4()
            scale = Matrix.Diagonal(Vector(scales[frame * 3:frame * 3 + 3]).to_4d())

            local = Matrix.Translation(translation) @ rotation @ scale
            world = local if parent_index < 0 else globals_[parent_index] @ local

            # Blender pose channels are relative to the rest pose, so convert out of world space.
            pose_bone.matrix_basis = rest_inverse @ world

            pose_bone.keyframe_insert("location", frame=frame, group=pose_bone.name)
            pose_bone.keyframe_insert("rotation_quaternion", frame=frame, group=pose_bone.name)
            pose_bone.keyframe_insert("scale", frame=frame, group=pose_bone.name)

    armature.animation_data.action = None
    return action


def main():
    scene_path, output_path = parse_args()
    with open(scene_path, "r", encoding="utf-8") as handle:
        scene = json.load(handle)

    clear_scene()
    armature, globals_ = build_armature(scene)

    for animation in scene["animations"]:
        build_action(armature, scene, animation, globals_)

    if scene["animations"]:
        longest = max(scene["animations"], key=lambda a: a["frameCount"])
        bpy.context.scene.frame_start = 0
        bpy.context.scene.frame_end = max(1, longest["frameCount"] - 1)
        bpy.context.scene.render.fps = max(1, int(round(1.0 / longest["frameDuration"])))

    bpy.ops.wm.save_as_mainfile(filepath=output_path)

    print(f"bioshock: wrote {output_path}")
    print(f"bioshock: {len(scene['bones'])} bones, {len(scene['animations'])} actions, "
          f"{len(scene['failures'])} undecoded")


if __name__ == "__main__":
    main()
