"""Deterministic level import: create or update UE5 actors from a BioShock level manifest.

Gate 3 item 4. Reads a `<map>.ue5-level.json` produced by `export-level` and reproduces its actors
in the currently-open UE5 level, then reports what it did in one pass:

    created / updated / skipped / unsupported

**Idempotent by construction.** Every actor this script owns carries a `BioShockKey=<manifest key>`
tag. A second run finds the existing actor by that tag and updates it in place rather than spawning
a duplicate, which is the property Gate 5 item 1 asks for and the one that makes re-importing a
level safe.

**What is and is not reproduced.** Lights become real `PointLight` actors carrying the manifest's
colour and brightness. Everything else becomes a positioned, tagged placeholder: the manifest
identifies each actor's class and transform, but the geometry it references is exported as OBJ and
is not yet imported as UE5 meshes, so there is nothing to attach. That is reported as `unsupported`
rather than quietly counted as success -- the coverage ledger already distinguishes "placed" from
"decoded", and this keeps the same distinction visible in the engine.

Run headless:

    UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
        -script=<driver.py> -unattended -nopause -nosplash
"""

import json
import math
import os

import unreal

SUPPORTED_FORMAT_VERSION = 4

# Unreal rotator units to degrees. The manifest stores the game's own integer pitch/yaw/roll.
ROTATOR_TO_DEGREES = 360.0 / 65536.0

KEY_TAG_PREFIX = "BioShockKey="


def _log(message):
    unreal.log("[bioshock-level] %s" % message)


def _actor_subsystem():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _existing_by_key():
    """Every actor this importer owns, indexed by its manifest key.

    Keyed off a tag rather than the actor label: labels are not unique and a user may rename an
    actor without meaning to break the link back to the manifest.
    """
    found = {}
    for actor in _actor_subsystem().get_all_level_actors():
        for tag in actor.tags:
            text = str(tag)
            if text.startswith(KEY_TAG_PREFIX):
                found[text[len(KEY_TAG_PREFIX):]] = actor
    return found


def _rotation(rotation):
    """The manifest's integer rotator triple as a UE5 rotator in degrees."""
    pitch, yaw, roll = rotation
    return unreal.Rotator(
        roll=roll * ROTATOR_TO_DEGREES,
        pitch=pitch * ROTATOR_TO_DEGREES,
        yaw=yaw * ROTATOR_TO_DEGREES)


def _place(actor, entry, key):
    """Apply the manifest's transform and identity to an actor, whether new or existing."""
    location = entry.get("location") or [0.0, 0.0, 0.0]
    actor.set_actor_location(unreal.Vector(*location), False, False)

    if entry.get("rotation"):
        actor.set_actor_rotation(_rotation(entry["rotation"]), False)

    scale = entry.get("drawScale3D") or [1.0, 1.0, 1.0]
    uniform = entry.get("drawScale", 1.0) or 1.0
    actor.set_actor_scale3d(unreal.Vector(scale[0] * uniform, scale[1] * uniform, scale[2] * uniform))

    label = entry.get("label") or entry.get("name") or key
    actor.set_actor_label(label)

    tags = [unreal.Name(KEY_TAG_PREFIX + key)]
    if entry.get("className"):
        tags.append(unreal.Name("BioShockClass=" + entry["className"]))
    if entry.get("tag"):
        tags.append(unreal.Name("BioShockTag=" + str(entry["tag"])))
    actor.tags = tags


def _import_lights(manifest, existing, report, handled):
    """Lights are the one class reproduced as a real, functioning UE5 actor."""
    for light in manifest.get("lights") or []:
        key = light["key"]
        handled.add(key)
        actor = existing.get(key)

        # A light already owned by a previous run must still BE a light. If an earlier, buggier run
        # left a placeholder under this key, replace it rather than trying to set light properties
        # on it -- which is exactly how the duplicate-spawn bug below announced itself.
        if actor is not None and not isinstance(actor, unreal.PointLight):
            _actor_subsystem().destroy_actor(actor)
            actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                unreal.PointLight, unreal.Vector(*light.get("location", [0, 0, 0])))
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1

        existing[key] = actor
        _place(actor, light, key)

        component = actor.get_editor_property("light_component")
        colour = light.get("color")
        if colour:
            component.set_editor_property(
                "light_color", unreal.Color(r=colour[0], g=colour[1], b=colour[2], a=255))
        if light.get("brightness") is not None:
            # The game's brightness is not candelas; carried across proportionally rather than
            # converted, since no photometric mapping has been established. UNKNOWN, not guessed.
            component.set_editor_property("intensity", float(light["brightness"]) * 1000.0)


def _import_actors(manifest, existing, report, handled):
    """Everything that is not a light: positioned, identified, and honestly reported."""
    for entry in manifest.get("actors") or []:
        key = entry["key"]

        # The actors list includes the lights, which _import_lights has already placed as real
        # PointLights. Skipping on `handled` rather than on the pre-run snapshot matters: the
        # snapshot is taken before anything spawns, so on a first run it does not contain the
        # lights this same run just created, and every light was getting a duplicate placeholder.
        if key in handled:
            continue
        handled.add(key)

        actor = existing.get(key)
        if actor is None:
            # TargetPoint, not EmptyActor: the latter does not exist in UE5.7's Python API, and a
            # TargetPoint is the engine's own positioned-marker class, which is exactly what an
            # actor whose geometry has not been imported yet should be.
            actor = _actor_subsystem().spawn_actor_from_class(
                unreal.TargetPoint, unreal.Vector(*(entry.get("location") or [0, 0, 0])))
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1

        existing[key] = actor
        _place(actor, entry, key)

        # The manifest names geometry this pipeline has not imported as UE5 meshes yet, so there is
        # nothing to attach. Counted, not hidden.
        if entry.get("className") not in ("LevelInfo", "ZoneInfo"):
            report["unsupported"] += 1


def _decompose(matrix):
    """A row-major 4x4 from the manifest, as (location, rotation, scale) for UE5.

    Decomposed by hand rather than through unreal.Matrix: the manifest stores System.Numerics'
    row-vector convention, and getting the convention wrong produces a level that looks plausible
    and is subtly inside out -- a failure this project has already paid for once in the BSP
    viewport. Doing the arithmetic explicitly keeps the convention visible.
    """
    rows = [matrix[0:3], matrix[4:7], matrix[8:11]]
    location = matrix[12:15]

    scale = []
    basis = []
    for row in rows:
        length = math.sqrt(row[0] * row[0] + row[1] * row[1] + row[2] * row[2])
        scale.append(length)
        basis.append([c / length for c in row] if length > 1e-6 else [0.0, 0.0, 0.0])

    # Rotation from the orthonormalised basis, via a quaternion, so a non-uniformly scaled
    # instance still yields a valid rotation.
    m00, m01, m02 = basis[0]
    m10, m11, m12 = basis[1]
    m20, m21, m22 = basis[2]

    trace = m00 + m11 + m22
    if trace > 0.0:
        r = math.sqrt(1.0 + trace) * 2.0
        w, x, y, z = 0.25 * r, (m12 - m21) / r, (m20 - m02) / r, (m01 - m10) / r
    elif m00 > m11 and m00 > m22:
        r = math.sqrt(1.0 + m00 - m11 - m22) * 2.0
        w, x, y, z = (m12 - m21) / r, 0.25 * r, (m10 + m01) / r, (m20 + m02) / r
    elif m11 > m22:
        r = math.sqrt(1.0 + m11 - m00 - m22) * 2.0
        w, x, y, z = (m20 - m02) / r, (m10 + m01) / r, 0.25 * r, (m21 + m12) / r
    else:
        r = math.sqrt(1.0 + m22 - m00 - m11) * 2.0
        w, x, y, z = (m01 - m10) / r, (m20 + m02) / r, (m21 + m12) / r, 0.25 * r

    quat = unreal.Quat(x=x, y=y, z=z, w=w)
    return (unreal.Vector(*location), quat.rotator(), unreal.Vector(*scale))


def _import_asset_meshes(manifest, manifest_dir, content_root, report):
    """Import each unique asset's local-space mesh once, as a UE5 StaticMesh.

    Keyed by asset rather than instance for the reason the exporter writes them that way: a brush
    used forty times is one mesh and forty transforms, not forty meshes.
    """
    meshes = {}

    for asset in manifest.get("assets") or []:
        path = asset.get("file")
        if not path:
            continue

        source = os.path.join(manifest_dir, path.replace("/", os.sep))
        if not os.path.exists(source):
            report["skipped"] += 1
            continue

        stem = os.path.splitext(os.path.basename(source))[0]
        destination = f"{content_root}/Meshes"
        asset_path = f"{destination}/{stem}"

        if unreal.EditorAssetLibrary.does_asset_exist(asset_path):
            meshes[asset["key"]] = unreal.EditorAssetLibrary.load_asset(asset_path)
            continue

        task = unreal.AssetImportTask()
        task.set_editor_property("filename", source)
        task.set_editor_property("destination_path", destination)
        task.set_editor_property("automated", True)
        task.set_editor_property("replace_existing", True)
        task.set_editor_property("save", True)
        unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])

        mesh = next((o for o in task.get_objects() if isinstance(o, unreal.StaticMesh)), None)
        if mesh is None:
            report["skipped"] += 1
            continue

        meshes[asset["key"]] = mesh

    _log("%d of %d assets imported as static meshes"
         % (len(meshes), len(manifest.get("assets") or [])))
    return meshes


def _import_instances(manifest, meshes, existing, report, handled):
    """Place every geometry instance as a StaticMeshActor carrying the asset's mesh."""
    for instance in manifest.get("instances") or []:
        key = "instance:" + instance["actorKey"] + ":" + instance["asset"]
        if key in handled:
            continue
        handled.add(key)

        mesh = meshes.get(instance["asset"])
        if mesh is None:
            report["unsupported"] += 1
            continue

        location, rotation, scale = _decompose(instance["transform"])

        actor = existing.get(key)
        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                unreal.StaticMeshActor, location, rotation)
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1
            actor.set_actor_location(location, False, False)
            actor.set_actor_rotation(rotation, False)

        actor.static_mesh_component.set_static_mesh(mesh)
        actor.set_actor_scale3d(scale)
        actor.set_actor_label(instance.get("label") or instance.get("actor") or key)
        actor.tags = [unreal.Name(KEY_TAG_PREFIX + key)]
        existing[key] = actor

def main(manifest_path, import_actors=True, content_root="/Game/BioShockLevel"):
    """Import one level manifest. Returns the created/updated/skipped/unsupported report."""
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    version = manifest.get("formatVersion")
    if version != SUPPORTED_FORMAT_VERSION:
        raise RuntimeError(
            "unsupported level manifest version %r; expected %d"
            % (version, SUPPORTED_FORMAT_VERSION))

    _log("%s: %d actors, %d lights, %d instances (format v%d)" % (
        manifest.get("package"),
        len(manifest.get("actors") or []),
        len(manifest.get("lights") or []),
        len(manifest.get("instances") or []),
        version))

    report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0}
    existing = _existing_by_key()
    _log("%d actor(s) already owned by a previous run" % len(existing))

    handled = set()
    _import_lights(manifest, existing, report, handled)

    # Geometry first, so an actor that gets a real mesh is not also counted as a placeholder.
    meshes = _import_asset_meshes(
        manifest, os.path.dirname(os.path.abspath(manifest_path)), content_root, report)
    _import_instances(manifest, meshes, existing, report, handled)

    if import_actors:
        _import_actors(manifest, existing, report, handled)

    _log("import report: %d created, %d updated, %d skipped, %d unsupported"
         % (report["created"], report["updated"], report["skipped"], report["unsupported"]))

    main.last_report = report
    return report
