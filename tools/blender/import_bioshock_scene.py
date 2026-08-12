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


def orthonormal(matrix):
    """Strip scale and shear, keeping rotation and translation.

    Blender bone rest matrices are rigid transforms, so any scale in the game's reference pose has
    to be dropped here rather than silently baked into the rig.
    """
    rotation = matrix.to_3x3()
    rotation.normalize()
    result = rotation.to_4x4()
    result.translation = matrix.to_translation()
    return result


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

        # Length is cosmetic in Blender and does not affect the pose, so a child's offset is used
        # where available purely to make the rig readable.
        length = MIN_BONE_LENGTH
        for child in bones:
            if child["parent"] == index:
                candidate = (Vector(child["translation"]) * SCENE_SCALE).length
                if candidate > MIN_BONE_LENGTH:
                    length = candidate
                    break

        # The bone's rest matrix must equal the game's reference-pose matrix exactly. Setting head
        # and tail alone does not achieve that: Blender then picks its own roll, and the resulting
        # rest orientation differs from the game's by up to a full axis flip. Assigning `matrix`
        # makes Blender derive head, tail and roll from the orientation we hand it.
        edit_bone.head = (0.0, 0.0, 0.0)
        edit_bone.tail = (0.0, length, 0.0)
        edit_bone.roll = 0.0
        edit_bone.matrix = orthonormal(globals_[index])
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


def build_mesh(armature, scene):
    """Build the skinned mesh and bind it to the armature.

    Skin weights come from the game's own bone map, so vertex groups are named after the skeleton
    bones the influences resolve to rather than being inferred.
    """
    data = scene.get("mesh")
    if not data:
        return None

    bones = scene["bones"]
    positions = data["positions"]
    triangles = data["triangles"]
    vertex_count = len(positions) // 3

    mesh = bpy.data.meshes.new(f"{scene['sourceObject']}_Mesh")
    mesh.vertices.add(vertex_count)
    mesh.vertices.foreach_set("co", [c * SCENE_SCALE for c in positions])

    face_count = len(triangles) // 3
    mesh.loops.add(len(triangles))
    mesh.polygons.add(face_count)
    mesh.loops.foreach_set("vertex_index", triangles)
    mesh.polygons.foreach_set("loop_start", [i * 3 for i in range(face_count)])
    mesh.polygons.foreach_set("loop_total", [3] * face_count)

    uv_layer = mesh.uv_layers.new(name="UVMap")
    uvs = data["uvs"]
    # Blender's V axis runs opposite to the game's.
    uv_layer.data.foreach_set(
        "uv", [v for i in triangles for v in (uvs[i * 2], 1.0 - uvs[i * 2 + 1])])

    mesh.update()
    mesh.validate()

    obj = bpy.data.objects.new(f"{scene['sourceObject']}_Mesh", mesh)
    bpy.context.collection.objects.link(obj)

    # Custom split normals from the game data, so shading matches the original.
    try:
        normals = data["normals"]
        mesh.normals_split_custom_set_from_vertices(
            [tuple(normals[i * 3:i * 3 + 3]) for i in range(vertex_count)])
    except Exception as exc:
        print(f"bioshock: could not apply custom normals ({exc})")

    counts = data["influenceCounts"]
    bone_indices = data["influenceBones"]
    weights = data["influenceWeights"]

    groups = {}
    cursor = 0
    for vertex in range(vertex_count):
        for _ in range(counts[vertex]):
            bone_index = bone_indices[cursor]
            weight = weights[cursor]
            cursor += 1
            name = bones[bone_index]["name"]
            group = groups.get(name)
            if group is None:
                group = obj.vertex_groups.new(name=name)
                groups[name] = group
            group.add([vertex], weight, "REPLACE")

    obj.parent = armature
    modifier = obj.modifiers.new(name="Armature", type="ARMATURE")
    modifier.object = armature

    print(f"bioshock: mesh {vertex_count} verts, {face_count} tris, {len(groups)} vertex groups")
    return obj


def build_sockets(armature, scene):
    """Create an empty per socket, parented to the bone the game attaches it to.

    Sockets are what a weapon or effect actually hangs off, so they need to follow the animated
    bone rather than sit at a fixed point in the scene.
    """
    created = []
    bone_names = {bone["name"] for bone in scene["bones"]}

    for socket in scene.get("sockets", []):
        # Bone names are matched case-insensitively: the mesh writes "R_Grip" where the skeleton
        # writes "R_grip".
        target = next((n for n in bone_names if n.lower() == socket["boneName"].lower()), None)
        if target is None:
            print(f"bioshock: socket {socket['name']} references unknown bone {socket['boneName']}")
            continue

        empty = bpy.data.objects.new(f"SOCKET_{socket['name']}", None)
        empty.empty_display_type = "ARROWS"
        empty.empty_display_size = 0.05
        bpy.context.collection.objects.link(empty)

        empty.parent = armature
        empty.parent_type = "BONE"
        empty.parent_bone = target
        # Bone parenting places children at the bone tail; cancel that so the socket sits on the head.
        empty.matrix_parent_inverse = Matrix.Translation(
            (0.0, -armature.data.bones[target].length, 0.0))

        empty["bioshock_socket"] = socket["name"]
        empty["bioshock_socket_bone"] = socket["boneName"]
        created.append(empty)

    return created


def build_action(armature, scene, animation, globals_):
    bones = scene["bones"]
    # Blender's own rest hierarchy, which is what the pose basis is measured against.
    rest_globals = [armature.data.bones[b["name"]].matrix_local for b in bones]
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
        # Read the rest matrix back from Blender rather than reusing our own, so the conversion is
        # correct even if Blender adjusted anything when the bone was created.
        rest_inverse = armature.data.bones[pose_bone.name].matrix_local.inverted()

        translations = track["translations"]
        rotations = track["rotations"]
        scales = track["scales"]

        for frame in range(frame_count):
            translation = Vector(translations[frame * 3:frame * 3 + 3]) * SCENE_SCALE
            x, y, z, w = rotations[frame * 4:frame * 4 + 4]
            rotation = Quaternion((w, x, y, z)).to_matrix().to_4x4()
            scale = Matrix.Diagonal(Vector(scales[frame * 3:frame * 3 + 3]).to_4d())

            local = Matrix.Translation(translation) @ rotation @ scale
            world = local if parent_index < 0 else rest_globals[parent_index] @ local

            # Blender pose channels are relative to the rest pose, so convert out of world space.
            pose_bone.matrix_basis = rest_inverse @ world

            pose_bone.keyframe_insert("location", frame=frame, group=pose_bone.name)
            pose_bone.keyframe_insert("rotation_quaternion", frame=frame, group=pose_bone.name)
            pose_bone.keyframe_insert("scale", frame=frame, group=pose_bone.name)

    # Events become pose markers so the reload beats, equip points and so on are visible on the
    # timeline instead of being lost.
    for event in animation.get("events", []):
        frame = round(event["time"] / animation["frameDuration"]) if animation["frameDuration"] > 0 else 0
        marker = action.pose_markers.new(event["name"] or event["notifyClass"])
        marker.frame = int(frame)

    armature.animation_data.action = None
    return action


def main():
    scene_path, output_path = parse_args()
    with open(scene_path, "r", encoding="utf-8") as handle:
        scene = json.load(handle)

    clear_scene()
    armature, globals_ = build_armature(scene)
    mesh_object = build_mesh(armature, scene)
    sockets = build_sockets(armature, scene)

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
          f"{len(sockets)} sockets, mesh={'yes' if mesh_object else 'no'}, "
          f"{len(scene['failures'])} undecoded")


if __name__ == "__main__":
    main()
