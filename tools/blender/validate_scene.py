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
3. Every material the mesh names has its own slot, in the scene's order, and every face is in the
   slot the game's section table puts it in. A wrong pairing is not visible in any count — the mesh
   is complete and every triangle is textured, just with the wrong material — so this compares the
   imported per-face assignment against the scene's, face by face.

A scene with no bones (a StaticMesh prop) is valid: checks 1 and 2 are skipped and 3 still runs.
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
        raise SystemExit("usage: blender --background <blend> --python validate_scene.py "
                         "-- <scene.json> [validation.json]")
    args = argv[argv.index("--") + 1:]
    if not args:
        raise SystemExit("expected a scene json path")
    return args[0], (args[1] if len(args) > 1 else None)


def library_report(scene):
    """Count what the .blend actually contains, for a machine-readable record.

    Written beside the library so a bulk export can be checked without opening every file, and so a
    later run can be compared against an earlier one.
    """
    actions = list(bpy.data.actions)
    armatures = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    props = [o for o in meshes if o.get("bioshock_static_attachment")]
    sockets = [o for o in bpy.data.objects if o.type == "EMPTY" and o.name.startswith("SOCKET_")]

    without_metadata = [a.name for a in actions if a.get("bioshock_original_name") is None]
    sets = {}
    for action in actions:
        key = action.get("bioshock_animation_set") or "<none>"
        sets[key] = sets.get(key, 0) + 1

    return {
        "sourcePackage": scene.get("sourcePackage"),
        "sourceObject": scene.get("sourceObject"),
        "skeleton": scene.get("skeletonName"),
        "bones": len(scene.get("bones", [])),
        "armatures": len(armatures),
        "meshes": len(meshes),
        "staticProps": len(props),
        "sockets": len(sockets),
        "socketsInScene": len(scene.get("sockets", [])),
        "materials": len(bpy.data.materials),
        "images": len(bpy.data.images),
        "actions": len(actions),
        "actionsWithEventMarkers": sum(1 for a in actions if len(a.pose_markers)),
        "eventMarkers": sum(len(a.pose_markers) for a in actions),
        "actionsMissingMetadata": without_metadata,
        "animationSets": dict(sorted(sets.items(), key=lambda kv: -kv[1])),
        "attachments": [
            {
                "object": o.name,
                "bone": o.parent_bone,
                "kind": "prop" if o.get("bioshock_static_attachment") else "rig",
            }
            for o in bpy.data.objects
            if o.parent_type == "BONE" and o.parent_bone and not o.name.startswith("SOCKET_")
        ],
        "undecodedAnimations": len(scene.get("failures", [])),
    }


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
    mirrored = []
    for index, bone in enumerate(bones):
        # A mirrored reference transform cannot be a Blender bone matrix, which must be a proper
        # rotation. Those bones are reported rather than compared; the pose conversion reads the rest
        # matrix back from Blender, so their poses are still correct.
        if globals_[index].to_3x3().determinant() < 0.0:
            mirrored.append(bone["name"])
            continue

        rest = armature.data.bones[bone["name"]].matrix_local
        error = max(abs(rest[r][c] - globals_[index][r][c]) for r in range(3) for c in range(3))
        error = max(error, (rest.to_translation() - globals_[index].to_translation()).length)
        if error > worst:
            worst, worst_name = error, bone["name"]

    print(f"rest pose: worst error {worst:.6f} ({worst_name}); {len(mirrored)} mirrored bones skipped")
    return worst <= REST_TOLERANCE, worst


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
            # Bones without a track keep their rest transform, and animated children still hang off
            # them, so the chain has to fall back to the rest pose rather than treating such a bone
            # as a root.
            world = [None] * len(bones)
            expected = [None] * len(bones)
            for index, bone in enumerate(bones):
                track = tracks.get(index)
                parent = bone["parent"]
                parent_world = Matrix.Identity(4) if parent < 0 else world[parent]

                if track is None:
                    local = local_matrix(bone["translation"], bone["rotation"], bone["scale"])
                    world[index] = parent_world @ local
                    continue

                local = local_matrix(
                    track["translations"][frame * 3:frame * 3 + 3],
                    track["rotations"][frame * 4:frame * 4 + 4],
                    track["scales"][frame * 3:frame * 3 + 3])
                world[index] = parent_world @ local
                expected[index] = world[index]

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


def check_materials(scene):
    """Check the mesh's material slots and which slot each face is in.

    The Nth section of a StaticMesh draws with the Nth entry of its Materials array. Nothing about a
    wrong pairing shows up in a count, so this compares the imported assignment against the scene's
    face by face.
    """
    expected = scene.get("materials") or ([scene["material"]] if scene.get("material") else [])
    mesh_data = scene.get("mesh")
    if mesh_data is None or not expected:
        print("materials: nothing to check")
        return True

    # The host's own mesh, not an attachment's. The importer names it "<sourceObject>_Mesh", and a
    # library holds several meshes — picking the first put the Bouncer's cigarette up against the
    # hands' material list and reported a mismatch that was entirely this line's fault.
    meshes = [
        o for o in bpy.data.objects
        if o.type == "MESH" and not o.get("bioshock_static_attachment") and not o.parent_bone
    ]
    if not meshes:
        print("FAIL materials: no mesh object in the .blend")
        return False

    source = scene["sourceObject"]
    obj = (next((o for o in meshes if o.name == f"{source}_Mesh"), None)
           or next((o for o in meshes if o.name == source), None)
           or next((o for o in meshes if o.name.startswith(source)), None)
           or meshes[0])
    slots = list(obj.data.materials)

    ok = True

    if len(slots) != len(expected):
        print(f"FAIL materials: {len(slots)} slots in the .blend, {len(expected)} in the scene")
        return False

    for index, (slot, entry) in enumerate(zip(slots, expected)):
        if slot is None:
            print(f"FAIL materials: slot {index} is empty")
            ok = False
            continue
        # Blender uniquifies a name that already exists, so compare on the prefix it keeps.
        if not slot.name.startswith(entry["name"]):
            print(f"FAIL materials: slot {index} is '{slot.name}', expected '{entry['name']}'")
            ok = False

    assignment = mesh_data.get("triangleMaterials") or []
    faces = len(obj.data.polygons)

    if not assignment:
        # One material for the whole mesh: every face must be in slot 0, or something reassigned it.
        stray = [p.index for p in obj.data.polygons if p.material_index != 0]
        if stray:
            print(f"FAIL materials: {len(stray)} faces are not in slot 0 on a single-material mesh")
            ok = False
        print(f"materials: {len(slots)} slot(s), {faces} faces all in slot 0")
        return ok

    if len(assignment) != faces:
        print(f"FAIL materials: {faces} faces in the .blend, {len(assignment)} assignments in the scene")
        return False

    wrong = 0
    for polygon in obj.data.polygons:
        want = assignment[polygon.index]
        # -1 is a run whose slot named no material; the importer puts it in slot 0 deliberately.
        want = want if 0 <= want < len(slots) else 0
        if polygon.material_index != want:
            if wrong < 5:
                print(f"FAIL materials: face {polygon.index} is in slot "
                      f"{polygon.material_index}, expected {want}")
            wrong += 1

    if wrong:
        print(f"FAIL materials: {wrong} of {faces} faces are in the wrong slot")
        return False

    # The check would pass vacuously if every face landed in one slot anyway.
    used = {p.material_index for p in obj.data.polygons}
    print(f"materials: {len(slots)} slots, {faces} faces assigned per section, {len(used)} slots used")
    if len(slots) > 1 and len(used) < 2:
        print(f"FAIL materials: {len(slots)} slots exist but every face is in slot {used.pop()}")
        return False

    return ok


def main():
    scene_path, report_path = parse_args()
    scene = json.load(open(scene_path, encoding="utf-8"))
    bones = scene["bones"]

    material_ok = check_materials(scene)
    report = library_report(scene)
    report["materialsPassed"] = material_ok

    def finish(passed, note=""):
        report["passed"] = bool(passed)
        if report_path:
            with open(report_path, "w", encoding="utf-8") as handle:
                json.dump(report, handle, indent=2)
            print(f"wrote {report_path}")
        print(("VALIDATION PASSED" + note) if passed else "VALIDATION FAILED")
        if not passed:
            sys.exit(1)

    print(f"library: {report['actions']} actions, {report['eventMarkers']} event markers, "
          f"{report['sockets']} sockets, {report['staticProps']} props, "
          f"{len(report['attachments'])} attachments")

    if report["actionsMissingMetadata"]:
        print(f"FAIL library: {len(report['actionsMissingMetadata'])} actions carry no bioshock metadata")
        material_ok = False

    # A StaticMesh has no skeleton. Demanding one would make every prop fail a check that does not
    # apply to it, which is how a real failure gets lost in noise.
    if not bones:
        finish(material_ok, " (no skeleton: rest and pose checks not applicable)")
        return

    armatures = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not armatures:
        raise SystemExit("no armature in the .blend")

    # A first-person scene contains the host rig and its attached weapon rig; validate the host.
    armature = next((o for o in armatures if o.name == scene["sourceObject"]), None) or armatures[0]

    rest_ok, rest_worst = check_rest(armature, bones)
    pose_ok, pose_worst = check_poses(armature, scene, bones)

    report["worstRestError"] = rest_worst
    report["worstPoseError"] = pose_worst
    report["restPassed"] = bool(rest_ok)
    report["posePassed"] = bool(pose_ok)

    finish(rest_ok and pose_ok and material_ok)


if __name__ == "__main__":
    main()
