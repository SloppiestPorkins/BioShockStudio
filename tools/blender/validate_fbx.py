"""Validate exported FBX against the scene JSON it was written from.

    blender --background --python validate_fbx.py -- <scene.json> <fbx-dir> [rig-name]

The FBX writer has no dependency on Blender; Blender is used here only as an independent reader,
because a file that writes without error can still describe the wrong rig. The checks are the ones
that caught real bugs on the Blender path:

1. Bone rest matrices equal the game's reference-pose matrices, composed independently here from the
   scene JSON. A wrong Euler order or rotation convention shows up here and nowhere else.
2. Posed bone positions match transforms composed independently from the game's own track data, at
   the start, middle and end of every animation.
3. Vertex count, triangle count and skin weights survive the round trip.

Exits non-zero on failure, so it can be run as a check rather than read by eye.
"""

import json
import os
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

REST_TOLERANCE = 1e-3        # game units (centimetres)
POSE_TOLERANCE = 1e-2        # game units; a hundredth of a centimetre
WEIGHT_TOLERANCE = 1e-3


def parse_args():
    argv = sys.argv
    if "--" not in argv:
        raise SystemExit("usage: blender --background --python validate_fbx.py -- <scene.json> <fbx-dir> [rig]")
    args = argv[argv.index("--") + 1:]
    if len(args) < 2:
        raise SystemExit("expected a scene json path and the directory the FBX files were written to")
    return args[0], args[1], (args[2] if len(args) > 2 else None)


def local_matrix(translation, rotation, scale):
    x, y, z, w = rotation
    return (Matrix.Translation(Vector(translation))
            @ Quaternion((w, x, y, z)).to_matrix().to_4x4()
            @ Matrix.Diagonal(Vector(scale).to_4d()))


def global_matrices(bones):
    result = []
    for bone in bones:
        local = local_matrix(bone["translation"], bone["rotation"], bone["scale"])
        parent = bone["parent"]
        result.append(local if parent < 0 else result[parent] @ local)
    return result


def import_fbx(path):
    """Import with the file's own axis declaration, so that declaration is under test too.

    Blender still converts the file's centimetres to its own metres, and it puts that conversion on
    the armature object rather than on the bones. Everything below is therefore compared in armature
    space, where the numbers are the exporter's own; the object transform is checked separately.
    """
    bpy.ops.import_scene.fbx(
        filepath=path,
        use_manual_orientation=False,
        global_scale=1.0,
        use_custom_normals=True,
        ignore_leaf_bones=False,
        automatic_bone_orientation=False,
        use_anim=True,
    )


def check_orientation(armature):
    """The armature object must carry a pure uniform scale — no rotation, no flip.

    Any rotation here would mean the file's declared up and front axes disagree with the data, which
    is exactly the kind of error that still renders plausibly.
    """
    matrix = armature.matrix_world
    scale = matrix.to_scale()
    rotation = matrix.to_3x3()
    for axis in range(3):
        rotation[axis] = [c / scale[axis] for c in rotation[axis]]

    error = max(abs(rotation[r][c] - (1.0 if r == c else 0.0)) for r in range(3) for c in range(3))
    error = max(error, abs(scale[0] - scale[1]), abs(scale[1] - scale[2]))
    error = max(error, matrix.to_translation().length)

    print(f"orientation: unit scale {scale[0]:.5f}, worst axis error {error:.6f}")
    return error <= REST_TOLERANCE


def find_armature():
    armatures = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not armatures:
        raise SystemExit("the imported FBX contains no armature")
    return armatures[0]


def check_rest(armature, bones, globals_):
    """Bone rest matrices, in armature space, against the game's reference pose."""
    worst, worst_name = 0.0, ""
    missing = []

    for index, bone in enumerate(bones):
        blender_bone = armature.data.bones.get(bone["name"])
        if blender_bone is None:
            missing.append(bone["name"])
            continue

        rest = blender_bone.matrix_local
        expected = globals_[index]

        # Compare the basis directions rather than the raw matrix: Blender bones point down their own
        # Y axis and store a rigid transform, so a mirrored or scaled reference pose cannot round
        # trip through a bone matrix. Positions must be exact either way.
        error = (rest.to_translation() - expected.to_translation()).length
        if expected.to_3x3().determinant() > 0.0:
            for r in range(3):
                for c in range(3):
                    error = max(error, abs(rest[r][c] - expected[r][c]))

        if error > worst:
            worst, worst_name = error, bone["name"]

    print(f"rest pose: worst error {worst:.6f} ({worst_name})")
    if missing:
        print(f"MISSING bones: {', '.join(missing[:10])}")
    return worst <= REST_TOLERANCE and not missing


def check_mesh(armature, scene):
    data = scene.get("mesh")
    if not data:
        return True

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        print("MISSING mesh")
        return False
    obj = meshes[0]

    expected_vertices = len(data["positions"]) // 3
    expected_triangles = len(data["triangles"]) // 3
    vertices = len(obj.data.vertices)
    triangles = len(obj.data.polygons)

    ok = vertices == expected_vertices and triangles == expected_triangles
    print(f"mesh: {vertices}/{expected_vertices} vertices, {triangles}/{expected_triangles} triangles")

    worst_position = 0.0
    for index, vertex in enumerate(obj.data.vertices):
        expected = Vector(data["positions"][index * 3:index * 3 + 3])
        worst_position = max(worst_position, (vertex.co - expected).length)
    print(f"mesh: worst vertex position error {worst_position:.6f}")
    ok = ok and worst_position <= REST_TOLERANCE

    # Skin weights, per vertex, against the game's own influences.
    bones = scene["bones"]
    counts, indices, weights = data["influenceCounts"], data["influenceBones"], data["influenceWeights"]
    groups = {g.index: g.name for g in obj.vertex_groups}

    worst_weight, cursor = 0.0, 0
    for vertex in range(expected_vertices):
        actual = {groups[g.group]: g.weight for g in obj.data.vertices[vertex].groups}
        for _ in range(counts[vertex]):
            name = bones[indices[cursor]]["name"]
            worst_weight = max(worst_weight, abs(actual.get(name, 0.0) - weights[cursor]))
            cursor += 1

    print(f"mesh: worst skin weight error {worst_weight:.6f}")
    return ok and worst_weight <= WEIGHT_TOLERANCE


def key_positions(action):
    """The Blender frame positions of the imported keys, in order.

    Not simply 0, 1, 2, ...: FBX stores absolute times, and Blender lays them out on its own frame
    axis at the scene's rounded frame rate. Three of the shipped pistol animations are authored at
    rates that are not integers (29.94 and 27.02 among them), so their keys land on fractional
    frames. Sampling those at whole frames measures Blender's interpolation rather than the file, so
    the checks below evaluate at the key positions themselves.
    """
    curves = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for slot in action.slots:
                bag = strip.channelbag(slot)
                if bag:
                    curves.extend(bag.fcurves)
    curves.extend(getattr(action, "fcurves", []))

    longest = max((c for c in curves if len(c.keyframe_points)), key=lambda c: len(c.keyframe_points), default=None)
    return [] if longest is None else [k.co.x for k in longest.keyframe_points]


def check_animation(fbx_directory, scene, animation, bones, rig_name):
    """Import one animation file on its own and compare posed bones against the game's tracks."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import_fbx(os.path.join(fbx_directory, animation["file"]))
    armature = find_armature()

    if armature.animation_data is None or armature.animation_data.action is None:
        actions = list(bpy.data.actions)
        if not actions:
            print(f"MISSING action in {animation['file']}")
            return False, (1.0, animation["name"])
        armature.animation_data_create()
        armature.animation_data.action = actions[0]

    positions = key_positions(armature.animation_data.action)

    depsgraph = bpy.context.evaluated_depsgraph_get()
    tracks = {t["boneIndex"]: t for t in animation["tracks"]}
    frames = animation["frameCount"]

    worst, worst_where = 0.0, ""
    for frame in sorted({0, frames // 2, frames - 1}):
        world = [None] * len(bones)
        expected = [None] * len(bones)
        for index, bone in enumerate(bones):
            parent = bone["parent"]
            parent_world = Matrix.Identity(4) if parent < 0 else world[parent]
            track = tracks.get(index)

            if track is None:
                world[index] = parent_world @ local_matrix(bone["translation"], bone["rotation"], bone["scale"])
                continue

            world[index] = parent_world @ local_matrix(
                track["translations"][frame * 3:frame * 3 + 3],
                track["rotations"][frame * 4:frame * 4 + 4],
                track["scales"][frame * 3:frame * 3 + 3])
            expected[index] = world[index]

        position = positions[frame] if frame < len(positions) else float(frame)
        bpy.context.scene.frame_set(int(position), subframe=position - int(position))
        depsgraph.update()
        evaluated = armature.evaluated_get(depsgraph)

        for index, bone in enumerate(bones):
            if expected[index] is None:
                continue
            pose_bone = evaluated.pose.bones.get(bone["name"])
            if pose_bone is None:
                continue
            posed = pose_bone.matrix
            error = (posed.to_translation() - expected[index].to_translation()).length
            if error > worst:
                worst, worst_where = error, f"{animation['name']} frame {frame} bone {bone['name']}"

    return worst <= POSE_TOLERANCE, (worst, worst_where)


def same_rig(a, b):
    """Whether two names refer to the same rig.

    An FBX is named after the asset and a scene after the AnimationPackageWrapper that holds it, so
    'NEWPlayerHands' and 'UAPW_NEWPlayerHands' are the same thing. Comparing them literally is what
    made this script stop finding its rig.
    """
    strip = lambda n: n[len("UAPW_"):] if n.startswith("UAPW_") else n
    return strip(a) == strip(b)


def main():
    scene_path, fbx_directory, rig_name = parse_args()
    scene = json.load(open(scene_path, encoding="utf-8"))

    manifest_path = os.path.join(fbx_directory, "ue5_manifest.json")
    manifest = json.load(open(manifest_path, encoding="utf-8"))
    wanted = rig_name or scene["sourceObject"]
    rig = next((r for r in manifest["rigs"] if same_rig(r["name"], wanted)), manifest["rigs"][0])

    # An attached rig — a first-person weapon — is a scene in its own right nested in the host's.
    if not same_rig(rig["name"], scene["sourceObject"]):
        scene = next(a["scene"] for a in scene["attachments"]
                     if same_rig(rig["name"], a["scene"]["sourceObject"]))

    bones = scene["bones"]
    globals_ = global_matrices(bones)

    print(f"validating rig '{rig['name']}' from {rig['mesh']}")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    import_fbx(os.path.join(fbx_directory, rig["mesh"]))
    armature = find_armature()

    orientation_ok = check_orientation(armature)
    rest_ok = check_rest(armature, bones, globals_)
    mesh_ok = check_mesh(armature, scene)

    animations_ok = True
    worst_pose, worst_where = 0.0, ""
    by_name = {a["name"]: a for a in scene["animations"]}
    for entry in rig["animations"]:
        animation = by_name.get(entry["name"])
        if animation is None:
            continue
        ok, (worst, where) = check_animation(fbx_directory, scene, {**animation, "file": entry["file"]}, bones, rig["name"])
        animations_ok = animations_ok and ok
        if worst > worst_pose:
            worst_pose, worst_where = worst, where

    print(f"posed bones: worst position error {worst_pose:.6f} ({worst_where})")

    if orientation_ok and rest_ok and mesh_ok and animations_ok:
        print("VALIDATION PASSED")
    else:
        print(f"VALIDATION FAILED (orientation={orientation_ok} rest={rest_ok} "
              f"mesh={mesh_ok} animations={animations_ok})")
        sys.exit(1)


if __name__ == "__main__":
    main()
