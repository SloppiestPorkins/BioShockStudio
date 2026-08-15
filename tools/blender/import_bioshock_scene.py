"""Build a Blender armature and actions from a BioShock scene JSON.

Run headless:

    blender --background --python import_bioshock_scene.py -- scene.json out.blend

The scene JSON is produced by `bioshock-tool export-blender`. Bone order and indices are taken
verbatim from the game data, because Havok animation tracks address bones by index.
"""

import json
import math
import os
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

    # Some bones carry a mirrored reference transform (a -1 scale axis; Bip01_L_Toe0Nub on the
    # Little Sister is one). A Blender bone matrix has to be a proper rotation, so the mirror is
    # removed here. The pose conversion reads the rest matrix back from Blender, so poses stay
    # correct; only the rest orientation of that bone differs from the game's.
    if rotation.determinant() < 0.0:
        rotation[0] = [-c for c in rotation[0]]

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


#: Outliner groups. A library holds a rig, its mesh, several weapons and twenty-odd socket empties,
#: and a flat scene list is unusable at that size. Objects are linked to exactly one of these.
COLLECTIONS = ("ARMATURE", "MESH", "WEAPONS", "PROPS", "SOCKETS", "DEBUG")


def collection(name):
    """The named outliner collection, created on first use."""
    existing = bpy.data.collections.get(name)
    if existing is None:
        existing = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(existing)
    return existing


def place(obj, name):
    """Move an object into one outliner collection, removing it from any other."""
    for other in list(obj.users_collection):
        other.objects.unlink(obj)
    collection(name).objects.link(obj)
    return obj


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def build_armature(scene):
    bones = scene["bones"]
    globals_ = global_matrices(bones)

    armature_data = bpy.data.armatures.new(scene["skeletonName"] or "Skeleton")
    armature = bpy.data.objects.new(scene["sourceObject"], armature_data)
    place(armature, "ARMATURE")

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
    place(obj, "MESH")

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

    # A prop has no skeleton: it is positioned on a socket, not deformed by one, so it gets neither
    # a parent armature nor an armature modifier. Giving it one would state a binding the game does
    # not have and would deform the drill by the Bouncer's spine.
    if armature is not None:
        obj.parent = armature
        modifier = obj.modifiers.new(name="Armature", type="ARMATURE")
        modifier.object = armature

    assign_materials(scene, mesh, obj, face_count)

    print(f"bioshock: mesh {vertex_count} verts, {face_count} tris, {len(groups)} vertex groups")
    return obj


def assign_materials(scene, mesh, obj, face_count):
    """Create one slot per material the mesh uses and put each face in its own.

    A mesh naming several materials draws a run of its index buffer with each — which triangles use
    which comes from the game's section table. Without the per-face assignment the whole mesh takes
    the first material, which is what painted the Bathysphere's windows in hull metal.
    """
    directory = os.path.dirname(os.path.abspath(scene["__path__"]))

    # "materials" is the slot-ordered list; "material" is the older single-material field, kept so a
    # scene written before this still imports.
    entries = scene.get("materials")
    if not entries:
        single = scene.get("material")
        entries = [single] if single else []

    if not entries:
        return

    for entry in entries:
        material = build_material(entry, directory)
        mesh.materials.append(material)

    assignment = scene.get("mesh", {}).get("triangleMaterials") or []
    if len(entries) < 2 or len(assignment) != face_count:
        # One material, or nothing trustworthy to assign with: every face takes slot 0, which is
        # what a single-slot mesh does anyway.
        return

    slots = len(entries)
    for index, polygon in enumerate(mesh.polygons):
        slot = assignment[index]
        # -1 is a run whose slot named no material. Blender has no empty assignment, so it stays in
        # slot 0 and shows as untextured rather than silently taking a neighbour's material.
        polygon.material_index = slot if 0 <= slot < slots else 0

    print(f"bioshock: {slots} material slots, assigned per face")


def build_material(data, directory):
    """Build a Principled BSDF from one of the game's shaders.

    Only the maps the game actually names are wired up. A slot the shader leaves empty is left empty
    here rather than filled with a default, so a missing map stays visible as a missing map.
    """
    material = bpy.data.materials.new(data["name"])
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled is None:
        return material

    material["bioshock_shader_class"] = data["className"]
    if data.get("partial"):
        # The shader's property list could not be walked to its end, so this material is incomplete.
        material["bioshock_partial"] = True
    if data.get("uninterpreted"):
        material["bioshock_uninterpreted"] = ", ".join(data["uninterpreted"])

    def image(relative):
        path = os.path.join(directory, relative.replace("/", os.sep))
        if not os.path.exists(path):
            print(f"bioshock: texture missing on disk: {path}")
            return None
        node = material.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = bpy.data.images.load(path, check_existing=True)
        return node

    if data.get("diffuse"):
        node = image(data["diffuse"])
        if node is not None:
            node.location = (-600, 300)
            material.node_tree.links.new(principled.inputs["Base Color"], node.outputs["Color"])

    if data.get("normalMap"):
        node = image(data["normalMap"])
        if node is not None:
            node.location = (-600, -300)
            node.image.colorspace_settings.name = "Non-Color"
            normal = material.node_tree.nodes.new("ShaderNodeNormalMap")
            normal.location = (-300, -300)
            material.node_tree.links.new(normal.inputs["Color"], node.outputs["Color"])
            material.node_tree.links.new(principled.inputs["Normal"], normal.outputs["Normal"])

    if data.get("specular"):
        node = image(data["specular"])
        if node is not None:
            node.location = (-600, 0)
            node.image.colorspace_settings.name = "Non-Color"
            # The game's specular map is a colour, which Principled has no direct input for; it drives
            # the specular tint so the information is present rather than discarded.
            if "Specular Tint" in principled.inputs:
                material.node_tree.links.new(principled.inputs["Specular Tint"], node.outputs["Color"])

    material.use_backface_culling = not data.get("twoSided", False)
    if data.get("masked"):
        material.blend_method = "CLIP" if hasattr(material, "blend_method") else material.blend_method

    return material


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
        place(empty, "SOCKETS")

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


def weapon_for(scene, owner):
    """Which weapon an animation set belongs to, if any.

    HEURISTIC, and deliberately a narrow one. The game names a first-person animation set after the
    weapon it is for — `Pistol`, `TommyGun`, `Crossbow` — and names the socket the weapon hangs on
    the same way, but not always identically: the `GrenadeLauncher` set hangs on `Launcher` and
    `ChemicalThrower` on `Chem`. So a set is credited to a weapon only when the host actually
    *declares a socket* whose name and the set's contain one another, and the longest such match
    wins. `Default` matches nothing and is left blank rather than being assigned whichever socket
    sorted first.

    Returns (weapon, socket) — both empty strings when the set is not a weapon's.
    """
    if not owner:
        return "", ""

    lowered = owner.lower()
    best, best_score = "", 0

    for socket in scene.get("sockets", []):
        name = socket["name"]
        candidate = name.lower()
        if candidate in lowered or lowered in candidate:
            score = min(len(candidate), len(lowered))
            if score > best_score:
                best, best_score = name, score

    # Two characters of overlap is a coincidence, not a match.
    if best_score < 3:
        return "", ""
    return owner, best


def build_action(armature, scene, animation, globals_):
    bones = scene["bones"]
    # Blender's own rest hierarchy, which is what the pose basis is measured against.
    rest_globals = [armature.data.bones[b["name"]].matrix_local for b in bones]
    action = bpy.data.actions.new(f"{armature.name}_{animation['owner']}_{animation['name']}"
                                 if armature.name.endswith("_Rig")
                                 else f"{animation['owner']}_{animation['name']}")
    action.use_fake_user = True

    # Original timing is carried as metadata rather than resampled: authored rates vary per
    # animation (30.00, 29.94 and 27.02 all occur within the pistol set alone). The action's name is
    # sanitised for Blender and can collide, so the game's own name travels with it and is what any
    # tool downstream should match on.
    action["bioshock_original_name"] = animation["name"]
    action["bioshock_frame_duration"] = animation["frameDuration"]
    action["bioshock_duration"] = animation["duration"]
    action["bioshock_frame_count"] = animation["frameCount"]
    action["bioshock_original_fps"] = (
        round(1.0 / animation["frameDuration"], 4) if animation["frameDuration"] > 0 else 0.0)
    action["bioshock_owner"] = animation["owner"]
    action["bioshock_animation_set"] = animation["owner"]
    action["bioshock_skeleton"] = scene.get("skeletonName", "")
    action["bioshock_package"] = scene.get("sourcePackage", "")
    action["bioshock_source_export"] = scene.get("sourceObject", "")
    action["bioshock_compression"] = animation.get("compression", "")

    weapon, socket_name = weapon_for(scene, animation["owner"])
    action["bioshock_weapon"] = weapon
    action["bioshock_weapon_socket"] = socket_name
    action["bioshock_track_count"] = len(animation["tracks"])
    action["bioshock_event_count"] = len(animation.get("events", []))

    if armature.animation_data is None:
        armature.animation_data_create()
    armature.animation_data.action = action

    frame_count = animation["frameCount"]
    driven = set()

    for track in animation["tracks"]:
        bone_index = track["boneIndex"]
        if bone_index < 0 or bone_index >= len(bones):
            continue
        driven.add(bone_index)

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

    # Bones the animation does not drive must still be keyed, at their reference pose. Without this
    # they keep whatever pose the previously assigned action left behind, so switching actions in
    # Blender - or exporting to FBX - silently carries motion across. Several animations drive only
    # a handful of bones: the Little Sister's LipFlap has a single track.
    for index, bone in enumerate(bones):
        if index in driven:
            continue
        pose_bone = armature.pose.bones[bone["name"]]
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.matrix_basis = Matrix.Identity(4)
        pose_bone.keyframe_insert("location", frame=0, group=pose_bone.name)
        pose_bone.keyframe_insert("rotation_quaternion", frame=0, group=pose_bone.name)
        pose_bone.keyframe_insert("scale", frame=0, group=pose_bone.name)

    armature.animation_data.action = None
    return action


def build_camera(scene, armature, attachment_objects):
    """Add a camera that frames the asset so the file is usable the moment it opens.

    This is a viewing convenience, not a reconstruction of the game's camera. The game does have a
    camera rig — `PlayerCameraAnim`, a two-bone `Parent`/`CameraDummy` skeleton with 56 recoil
    animations including `PlayerCamera_PistolFired` — but its `CameraDummy` sits at the origin of its
    own space, and how that space relates to the viewmodel's has not been established. Guessing at it
    produced worse framing than simply aiming at the subject, so the camera is labelled approximate.

    The subject is the weapon when there is one, because that is what the viewmodel is built around.
    """
    subject = None
    for obj, _ in attachment_objects:
        if obj is None:
            continue
        # A weapon is an armature whose mesh hangs under it; a prop is the mesh itself.
        subject = obj if obj.type == "MESH" else next(
            (c for c in obj.children_recursive if c.type == "MESH"), None)
        if subject is not None:
            break
    if subject is None:
        subject = next((o for o in bpy.data.objects if o.type == "MESH"), None)
    if subject is None:
        return None

    depsgraph = bpy.context.evaluated_depsgraph_get()
    depsgraph.update()
    evaluated = subject.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    points = [evaluated.matrix_world @ v.co for v in mesh.vertices]
    evaluated.to_mesh_clear()
    if not points:
        return None

    centre = sum(points, Vector()) / len(points)
    radius = max((p - centre).length for p in points)

    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera_data.angle = math.radians(50.0)
    camera_data.clip_start = 0.01
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    place(camera, "DEBUG")

    # Three-quarter view from the weapon's right and slightly above, which keeps the left arm — it
    # hangs well below the weapon and only animates during the reload — out of the way.
    distance = max(radius * 3.5, 0.35)
    offset = Vector((-0.55, -0.62, 0.30)).normalized() * distance
    camera.location = centre + offset
    direction = (centre - camera.location).normalized()
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    bpy.context.scene.camera = camera
    camera["bioshock_note"] = "preview framing only; the game camera transform is not yet known"
    return camera


def assign_default_actions(armature, scene, attachments):
    """Assign an action to every rig so the file plays as soon as it is opened.

    Actions are otherwise created with a fake user and left unassigned, which is why pressing play
    did nothing. The host and its attachment are given the matching pair, so hands and weapon move
    together.
    """
    if not scene["animations"]:
        return None

    def counterpart(host_animation):
        """The attachment animation that goes with a host animation, matched by name prefix.

        The weapon's "FastReload" pairs with the hands' "FastReloadPistol", so the longest shared
        prefix wins. A short match is treated as no match rather than a wrong pairing.
        """
        best, best_score = None, 0
        for _, attachment in attachments:
            for candidate in attachment["scene"]["animations"]:
                score = len(os.path.commonprefix([candidate["name"].lower(), host_animation["name"].lower()]))
                if score > best_score:
                    best, best_score = candidate, score
        return (best, best_score) if best_score >= 4 else (None, 0)

    # When something is attached, prefer an animation that drives both rigs — otherwise the weapon
    # sits still and the file looks broken.
    paired = [a for a in scene["animations"] if counterpart(a)[0] is not None]
    pool = paired or scene["animations"]

    preferred = ("Reload", "Fidget", "Idle", "Fire", "Equip")
    chosen = None
    for key in preferred:
        chosen = next((a for a in pool if key.lower() in a["name"].lower()), None)
        if chosen:
            break
    chosen = chosen or pool[0]

    host_action = bpy.data.actions.get(f"{chosen['owner']}_{chosen['name']}")
    if host_action is not None:
        if armature.animation_data is None:
            armature.animation_data_create()
        armature.animation_data.action = host_action

    for attachment_object, attachment in attachments:
        if attachment_object is None:
            continue
        best, best_score = 0, 0
        best = None
        for candidate in attachment["scene"]["animations"]:
            score = len(os.path.commonprefix([candidate["name"].lower(), chosen["name"].lower()]))
            if score > best_score:
                best, best_score = candidate, score
        if best is None or best_score < 4:
            continue
        action = bpy.data.actions.get(f"{attachment_object.name}_{best['owner']}_{best['name']}")
        if action is None:
            continue
        if attachment_object.animation_data is None:
            attachment_object.animation_data_create()
        attachment_object.animation_data.action = action
        print(f"bioshock: playing {chosen['name']} with {best['name']}")

    return chosen


def build_static_attachment(host_armature, attachment, scene, target):
    """Parent a prop to the host's socket bone.

    The Bouncer's drill, cage and backpack are static meshes the game hangs on sockets. They have no
    skeleton, so there is nothing to build an armature from: the mesh is parented to the bone and
    travels with it, which is what the viewport already draws.
    """
    obj = build_mesh(None, scene)
    if obj is not None:
        place(obj, "PROPS")
    if obj is None:
        print(f"bioshock: static attachment {attachment['socketName']} has no geometry")
        return None

    obj.name = f"{attachment['socketName']}_{scene['sourceObject']}"
    obj.parent = host_armature
    obj.parent_type = "BONE"
    obj.parent_bone = target
    # Bone parenting places children at the bone tail; cancel that so the prop sits on the socket.
    obj.matrix_parent_inverse = Matrix.Translation(
        (0.0, -host_armature.data.bones[target].length, 0.0))

    obj["bioshock_socket"] = attachment["socketName"]
    obj["bioshock_socket_bone"] = attachment["socketBone"]
    obj["bioshock_static_attachment"] = True

    print(f"bioshock: attached prop {attachment['socketName']} ({scene['sourceObject']}) to {target}")
    return obj


def build_attachment(host_armature, attachment):
    """Build an attached asset — a weapon — as its own rig parented to the host's socket bone.

    The weapon is not merged into the host skeleton. It has its own skeleton (the pistol's is rooted
    at R_grip and drives the hammer, trigger, barrel and drum) and its own animations, which run in
    sync with the hand animations. Merging them would destroy that structure.
    """
    scene = attachment["scene"]
    scene.setdefault("__path__", host_armature.get("bioshock_scene_path", ""))
    bone_names = {b.name for b in host_armature.data.bones}
    target = next((n for n in bone_names if n.lower() == attachment["socketBone"].lower()), None)
    if target is None:
        print(f"bioshock: attachment {attachment['socketName']} references unknown bone {attachment['socketBone']}")
        return None

    # A prop has no skeleton of its own — the Bouncer's drill, cage and backpack are static meshes
    # the game hangs on a socket. It is parented to the bone directly rather than given an invented
    # armature, which would put a joint in the file the game does not have.
    if not scene.get("bones"):
        return build_static_attachment(host_armature, attachment, scene, target)

    armature, globals_ = build_armature(scene)
    armature.name = f"{attachment['socketName']}_Rig"
    place(armature, "WEAPONS")
    weapon_mesh = build_mesh(armature, scene)
    if weapon_mesh is not None:
        place(weapon_mesh, "WEAPONS")

    for animation in scene["animations"]:
        build_action(armature, scene, animation, globals_)

    armature.parent = host_armature
    armature.parent_type = "BONE"
    armature.parent_bone = target
    # Bone parenting places children at the bone tail; cancel that so the weapon sits on the socket.
    armature.matrix_parent_inverse = Matrix.Translation(
        (0.0, -host_armature.data.bones[target].length, 0.0))

    armature["bioshock_socket"] = attachment["socketName"]
    armature["bioshock_socket_bone"] = attachment["socketBone"]

    print(f"bioshock: attached {attachment['socketName']} "
          f"({len(scene['bones'])} bones, {len(scene['animations'])} actions) to {target}")
    return armature


def main():
    scene_path, output_path = parse_args()
    with open(scene_path, "r", encoding="utf-8") as handle:
        scene = json.load(handle)
    # Texture paths in the scene are relative to it, so the importer has to remember where it came
    # from; attachments inherit the same base.
    scene["__path__"] = scene_path

    clear_scene()
    armature, globals_ = build_armature(scene)
    armature["bioshock_scene_path"] = scene_path
    mesh_object = build_mesh(armature, scene)
    sockets = build_sockets(armature, scene)

    for animation in scene["animations"]:
        build_action(armature, scene, animation, globals_)

    attachments = [(build_attachment(armature, a), a) for a in scene.get("attachments", [])]

    build_camera(scene, armature, attachments)
    playing = assign_default_actions(armature, scene, attachments)

    if scene["animations"]:
        # Frame range follows whatever is actually assigned, so play works immediately.
        reference = playing or max(scene["animations"], key=lambda a: a["frameCount"])
        bpy.context.scene.frame_start = 0
        bpy.context.scene.frame_end = max(1, reference["frameCount"] - 1)
        bpy.context.scene.render.fps = max(1, int(round(1.0 / reference["frameDuration"])))
        bpy.context.scene.frame_set(0)

    bpy.ops.wm.save_as_mainfile(filepath=output_path)

    print(f"bioshock: wrote {output_path}")
    print(f"bioshock: {len(scene['bones'])} bones, {len(scene['animations'])} actions, "
          f"{len(sockets)} sockets, mesh={'yes' if mesh_object else 'no'}, "
          f"{len(scene['failures'])} undecoded")


if __name__ == "__main__":
    main()
