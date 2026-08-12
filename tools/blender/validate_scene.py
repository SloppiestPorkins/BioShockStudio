"""Validate an exported .blend against the scene JSON it was built from.

    blender --background <scene.blend> --python validate_scene.py -- <scene.json>

Exits non-zero if anything fails, so it can be run as a check rather than read by eye.

Two properties are checked, because the mesh work already showed that plausible numbers can hide a
completely wrong result:

1. Every bone's rest matrix equals the game's reference-pose matrix. Blender derives roll from head
   and tail, so a rig built that way silently ends up with different rest orientations, and the pose
   conversion is then measured against the wrong basis.
2. Every animated bone's posed world position matches the position computed independently from the
   game's own track data, at the start, middle and end of every action.
"""

import json
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

SCENE_SCALE = 0.01
REST_TOLERANCE = 1e-4
POSE_TOLERANCE = 1e-3  # metres


def parse_args():
    argv = sys.argv
    if "--" not in argv:
        raise SystemExit("usage: blender --background <blend> --python validate_scene.py -- <scene.json>")
    args = argv[argv.index("--") + 1:]
    if not args:
        raise SystemExit("expected a scene json path")
    return args[0]


def local_matrix(translation, rotation, scale):
    x, y, z, w = rotation
    return (Matrix.Translation(Vector(translation) * SCENE_SCALE)
            @ Quaternion((w, x, y, z)).to_matrix().to_4x4()
            @ Matrix.Diagonal(Vector(scale).to_4d()))


def check_rest(armature, bones):
    globals_ = []
    for bone in bones:
        local = local_matrix(bone["translation"], bone["rotation"], bone["scale"])
        parent = bone["parent"]
        globals_.append(local if parent < 0 else globals_[parent] @ local)

    worst = 0.0
    worst_name = ""
    for index, bone in enumerate(bones):
        rest = armature.data.bones[bone["name"]].matrix_local
        error = max(abs(rest[r][c] - globals_[index][r][c]) for r in range(3) for c in range(3))
        error = max(error, (rest.to_translation() - globals_[index].to_translation()).length)
        if error > worst:
            worst, worst_name = error, bone["name"]

    print(f"rest pose: worst error {worst:.6f} ({worst_name})")
    return worst <= REST_TOLERANCE, globals_


def check_poses(armature, scene, bones):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    worst = 0.0
    worst_where = ""

    for animation in scene["animations"]:
        action = bpy.data.actions.get(f"{animation['owner']}_{animation['name']}")
        if action is None:
            print(f"MISSING action for {animation['name']}")
            return False, 1.0
        armature.animation_data.action = action

        tracks = {t["boneIndex"]: t for t in animation["tracks"]}
        frames = animation["frameCount"]

        for frame in {0, frames // 2, frames - 1}:
            expected = [None] * len(bones)
            for index, bone in enumerate(bones):
                track = tracks.get(index)
                if track is None:
                    continue
                local = local_matrix(
                    track["translations"][frame * 3:frame * 3 + 3],
                    track["rotations"][frame * 4:frame * 4 + 4],
                    track["scales"][frame * 3:frame * 3 + 3])
                parent = bone["parent"]
                expected[index] = local if parent < 0 or expected[parent] is None else expected[parent] @ local

            bpy.context.scene.frame_set(frame)
            depsgraph.update()
            evaluated = armature.evaluated_get(depsgraph)

            for index, bone in enumerate(bones):
                if expected[index] is None:
                    continue
                posed = evaluated.pose.bones[bone["name"]].matrix
                error = (posed.to_translation() - expected[index].to_translation()).length
                if error > worst:
                    worst = error
                    worst_where = f"{animation['name']} frame {frame} bone {bone['name']}"

    print(f"posed bones: worst position error {worst:.6f} m ({worst_where})")
    return worst <= POSE_TOLERANCE, worst


def main():
    scene = json.load(open(parse_args(), encoding="utf-8"))
    bones = scene["bones"]

    armatures = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not armatures:
        raise SystemExit("no armature in the .blend")
    armature = armatures[0]

    rest_ok, _ = check_rest(armature, bones)
    pose_ok, _ = check_poses(armature, scene, bones)

    if rest_ok and pose_ok:
        print("VALIDATION PASSED")
    else:
        print("VALIDATION FAILED")
        sys.exit(1)


if __name__ == "__main__":
    main()
