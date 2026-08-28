"""Deterministic level import: create or update UE5 actors from a BioShock level manifest.

Gate 3 item 4. Reads a `<map>.ue5-level.json` produced by `export-level` and reproduces its actors
in the currently-open UE5 level, then reports what it did in one pass:

    created / updated / skipped / unsupported

**Idempotent by construction.** Every actor this script owns carries a `BioShockKey=<manifest key>`
tag. A second run finds the existing actor by that tag and updates it in place rather than spawning
a duplicate, which is the property Gate 5 item 1 asks for and the one that makes re-importing a
level safe.

**What is and is not reproduced.** Lights become real `PointLight` actors: colour, authored
`LightBrightness` as intensity (no candela conversion), `LightRadius` as attenuation radius,
inverse-square falloff off so intensity stays a brightness scale. A light with no radius is not
spawned — its reach is UNKNOWN. **Drawable** geometry instances become `StaticMeshActor`/
`SkeletalMeshActor`. **Gameplay volumes** (`TriggerVolume`, `BlockingVolume`, `FluidVolume`, …)
become invisible UE5 volume actors sized from their brush OBJ bounds — never as visible meshes.
**Source CSG brushes** (`kind: Brush` on a plain `Brush` actor) are omitted: their geometry is
already in the single `BuiltWorld` instance, and placing them again would duplicate architecture
(the studio viewer hides them for the same reason). `CubemapProbe` actors become
`SphereReflectionCapture` at the probe position (influence radius left at the engine default —
no shipped radius is decoded; UNKNOWN rather than guessed). Face PNGs import as `Texture2D`s
tagged with declaration index; they are **not** packed into a `TextureCube` (face order UNKNOWN).
Other decoded-but-unplaced classes still become tagged `TargetPoint`s and count as `unsupported`.

Run headless:

    UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
        -script=<driver.py> -unattended -nopause -nosplash
"""

import json
import math
import os

import unreal

# Reused rather than reimplemented: LevelMaterialDocument and FbxTextureEntry are shaped to match
# the rig manifest's own materials/textures records on purpose (see LevelSceneExporter.cs), so the
# same texture-import and material-instance code serves both paths. Both modules live in this
# directory, which the caller must already have added to sys.path to import this one.
import import_bioshock
import import_policy

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
    """The manifest's integer rotator triple as a UE5 rotator in degrees.

    No basis conversion here: this is `ActorTransform.Rotation`'s raw UnrealRotator, read straight
    off the package and never passed through `GameBasis.Convert` on the C# side (see
    LevelSceneExporter.cs's `LevelActorDocument.Rotation`) -- because BioShock's Vengeance engine
    already shares Unreal's own left-handed, +Y-right basis (GameBasis.cs). It is only positions and
    composed matrices that this project's own pipeline mirrors for Blender/FBX/glTF, and only those
    need mirroring back on the way into an actual Unreal level; see `_to_unreal_location`.
    """
    pitch, yaw, roll = rotation
    return unreal.Rotator(
        roll=roll * ROTATOR_TO_DEGREES,
        pitch=pitch * ROTATOR_TO_DEGREES,
        yaw=yaw * ROTATOR_TO_DEGREES)


def _to_unreal_location(location):
    """Reverses GameBasis.Convert(Vector3) -- negates Y -- for a manifest value in this project's
    own right-handed, +Y-left basis, so it lands correctly in Unreal's native left-handed, +Y-right
    one.

    `GameBasis.Convert` is a reflection (an involution: applying it twice is the identity), so
    reversing it is applying the exact same negation again. `LevelLightDocument.Location` and
    `LevelInstanceDocument.Transform` are both written through it on the C# side;
    `LevelActorDocument.Location` (a placeholder TargetPoint) is not, and must be passed through
    `_place()` unconverted -- see the `convert_location` flag there.
    """
    x, y, z = location
    return [x, -y, z]


def _place(actor, entry, key, convert_location=False):
    """Apply the manifest's transform and identity to an actor, whether new or existing.

    `convert_location` is True only for a location this project's own exporter ran through
    `GameBasis.Convert` -- a light's, not a placeholder actor's; see `_to_unreal_location`.
    """
    location = entry.get("location") or [0.0, 0.0, 0.0]
    if convert_location:
        location = _to_unreal_location(location)
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
        actor = existing.get(key)
        radius = light.get("radius")

        # Reach is UNKNOWN when the package wrote no radius (or zero). The studio drops those
        # rather than inventing one. Do not spawn a PointLight with UE5's 1000 cm default.
        if radius is None or float(radius) <= 0:
            if actor is not None and isinstance(actor, unreal.PointLight):
                _actor_subsystem().destroy_actor(actor)
                existing.pop(key, None)
            continue

        handled.add(key)

        # A light already owned by a previous run must still BE a light. If an earlier, buggier run
        # left a placeholder under this key, replace it rather than trying to set light properties
        # on it -- which is exactly how the duplicate-spawn bug below announced itself.
        if actor is not None and not isinstance(actor, unreal.PointLight):
            _actor_subsystem().destroy_actor(actor)
            actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                unreal.PointLight, unreal.Vector(*_to_unreal_location(light.get("location", [0, 0, 0]))))
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1

        existing[key] = actor
        _place(actor, light, key, convert_location=True)

        component = actor.get_editor_property("light_component")
        # Movable so they illuminate in the editor without a Lightmass build. BioShock never
        # serialises bStatic (class default applies; UNKNOWN), so this is an import-time choice,
        # not a decoded mobility.
        component.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
        colour = light.get("color")
        if colour:
            component.set_editor_property(
                "light_color", unreal.Color(r=colour[0], g=colour[1], b=colour[2], a=255))

        # Radius is world centimetres, same unit as UE5 AttenuationRadius — carry it, do not scale.
        component.set_editor_property("attenuation_radius", float(radius))

        # Inverse-square treats AttenuationRadius as a clip on 1/r^2. BioShock authored a finite
        # radius as the light's reach (float world units, median hundreds of cm). This project's
        # own viewer found inverse-square "almost black" at those scales (SoftwareRenderer). UE5's
        # PointLightComponent: when inverse-square is off, Intensity is a brightness scale. The
        # authored LightBrightness is that scale (0–4, median ~1) — carry it, do not multiply.
        # The previous `* 1000` was the uncalibrated guess Phase 1.4 exists to remove.
        component.set_editor_property("use_inverse_squared_falloff", False)
        units = getattr(unreal.LightUnits, "UNITLESS", None)
        if units is not None:
            component.set_editor_property("intensity_units", units)
        brightness = light.get("brightness")
        component.set_editor_property(
            "intensity", float(brightness) if brightness is not None else 1.0)


def _import_cubemap_faces(manifest, export_directory, destination, report):
    """Import each cubemap face PNG as a Texture2D. Does not assemble a TextureCube.

    Face-to-axis mapping is UNKNOWN; packing six faces into a cube here would bake a guessed
    rotation into every reflection. Returns cubemap object name -> list of (index, texture).
    """
    by_name = {}
    seen_files = {}
    for cube in manifest.get("cubemaps") or []:
        name = cube.get("name")
        faces = []
        for face in cube.get("faces") or []:
            relative = face.get("file")
            if not relative:
                continue
            source = os.path.join(export_directory, relative.replace("/", os.sep))
            if not os.path.exists(source):
                _log("  cubemap face missing on disk, skipped: %s" % relative)
                continue
            if source in seen_files:
                faces.append((face.get("index", len(faces)), seen_files[source]))
                continue

            stem = os.path.splitext(os.path.basename(source))[0]
            existed = import_bioshock._existed("%s/CubemapFaces/%s" % (destination, stem))
            task = unreal.AssetImportTask()
            task.set_editor_property("filename", source)
            task.set_editor_property("destination_path", "%s/CubemapFaces" % destination)
            task.set_editor_property("automated", True)
            task.set_editor_property("replace_existing", True)
            task.set_editor_property("save", True)
            import_bioshock._asset_tools().import_asset_tasks([task])
            texture = next((o for o in task.get_objects() if isinstance(o, unreal.Texture2D)), None)
            if texture is None:
                _log("  FAILED to import cubemap face %s" % relative)
                continue
            texture.set_editor_property("srgb", True)
            texture.set_editor_property("address_x", unreal.TextureAddress.TA_CLAMP)
            texture.set_editor_property("address_y", unreal.TextureAddress.TA_CLAMP)
            import_bioshock._tag(texture, {
                "BioShockCubemap": name or "",
                "BioShockFaceIndex": str(face.get("index", "")),
                "BioShockFaceName": face.get("objectName") or "",
            })
            unreal.EditorAssetLibrary.save_loaded_asset(texture)
            seen_files[source] = texture
            faces.append((face.get("index", len(faces)), texture))
            report["updated" if existed else "created"] += 1
        if name:
            by_name[name] = faces
    if by_name:
        _log("%d cubemap(s), faces imported as Texture2D (no TextureCube assembly)" % len(by_name))
    return by_name


def _import_cubemap_probes(manifest, existing, report, handled, face_textures=None):
    """Place each CubemapProbe as a SphereReflectionCapture.

    Positions only this pass: the game names a Cubemap export, but UE5's capture actor rebuilds from
    the scene at lighting build, and no shipped influence radius is decoded (UNKNOWN — the engine
    default stands rather than a guessed number). The cubemap object name rides in a tag so a later
    TextureCube bind has a stable key.
    """
    capture_class = getattr(unreal, "SphereReflectionCapture", None)
    if capture_class is None:
        raise RuntimeError(
            "unreal.SphereReflectionCapture is missing; this editor cannot place cubemap probes")
    face_textures = face_textures or {}

    for entry in manifest.get("actors") or []:
        if entry.get("className") != "CubemapProbe":
            continue
        key = entry["key"]
        handled.add(key)
        actor = existing.get(key)
        if actor is not None and not isinstance(actor, capture_class):
            _actor_subsystem().destroy_actor(actor)
            actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                capture_class, unreal.Vector(*(entry.get("location") or [0, 0, 0])))
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1

        existing[key] = actor
        _place(actor, entry, key)
        cubemap = (entry.get("cubemap") or {}).get("objectName")
        if cubemap:
            tags = list(actor.tags)
            tags.append(unreal.Name("BioShockCubemap=" + cubemap))
            for index, texture in face_textures.get(cubemap, []):
                path = texture.get_path_name() if hasattr(texture, "get_path_name") else str(texture)
                tags.append(unreal.Name("BioShockCubemapFace%d=%s" % (index, path)))
            actor.tags = tags


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

    This matrix is `LevelSceneBuilder.MeshPlacement`'s result, which is `ActorTransform.ToMatrix()`
    run through `GameBasis.Convert` -- this project's own right-handed, +Y-left basis, chosen so
    Blender/FBX/glTF read it correctly, not Unreal's native left-handed, +Y-right one. `GameBasis`'s
    reflection is an involution, so the location and rotation extracted below are reversed back to
    Unreal's own basis the same way `GameBasis.Convert` itself is defined: negate the location's Y,
    and negate the quaternion's X and Z (`GameBasis.Convert(Quaternion)`'s exact formula). Getting
    this backwards -- or forgetting it entirely, which is what shipped first -- places every
    instance mirrored in Y with an inverted rotation sense: numerically well-formed, and visibly
    scattered wrong once there is more than a handful of instances to look at.
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

    # Reverse GameBasis.Convert: negate the location's Y and the quaternion's X and Z.
    unreal_location = _to_unreal_location(location)
    quat = unreal.Quat(x=-x, y=y, z=-z, w=w)
    return (unreal.Vector(*unreal_location), quat.rotator(), unreal.Vector(*scale))


def _import_level_materials(manifest, manifest_dir, destination, content_root, report):
    """Create UE5 textures and material instances for a level's resolved materials.

    Returns {materialKey: MaterialInstanceConstant}, keyed by each LevelMaterialDocument's own
    `key` — the identity a section's own `materialKey` names — rather than by material name. A
    `MaterialSwitch` reference and its resolved default child are recorded under two different
    keys but share one instance when they resolve to the same content; see
    `LevelSceneExporter.WriteMaterials`'s remarks on the C# side for why the key and the
    class/name/texture fields on one entry do not always describe the same export.
    """
    materials = manifest.get("materials") or []
    if not materials:
        return {}

    textures, imported_by_file = import_bioshock._import_textures(
        manifest, manifest_dir, destination, report)
    if textures:
        _log("  imported %d texture(s) with declared intent" % len(textures))

    instances = import_bioshock._create_material_instances(
        manifest, destination, content_root, imported_by_file)
    return {material["key"]: instance for material, instance in zip(materials, instances)}


def _assign_asset_material(mesh, asset, materials_by_key, report):
    """Assign each of a static mesh's sections its own material slot, in section order.

    `BuildAssetObj` now writes one "usemtl BioShock_{index}" group per entry in the manifest's own
    `sections` list, in that same order -- both are built by iterating the same geometry section
    table -- so imported material slot N is assumed to correspond to `sections[N]`. One slot is
    built per section regardless of whether several sections share a material key, so a later
    section can't shift into an earlier section's slot index. A section with no resolved key gets
    an empty slot (no material_interface) rather than silently inheriting a neighbour's material.
    """
    sections = asset.get("sections") or []
    if not sections:
        # No section table at all: leave whatever material the import gave the mesh alone, exactly
        # as before this function assigned anything. Setting an empty static_materials list here
        # would clear the mesh's material instead of leaving it untouched.
        return

    static_materials = []
    resolved_any = False
    resolved_slots = 0
    for index, section in enumerate(sections):
        slot = unreal.StaticMaterial()
        slot.set_editor_property("material_slot_name", unreal.Name("BioShock_%d" % index))

        material = materials_by_key.get(section.get("materialKey"))
        if material is not None:
            slot.set_editor_property("material_interface", material)
            resolved_any = True
            resolved_slots += 1

        static_materials.append(slot)

    if not resolved_any:
        return

    mesh.set_editor_property("static_materials", static_materials)
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    report["materialsAssigned"] = report.get("materialsAssigned", 0) + 1
    report["materialSlotsResolved"] = report.get("materialSlotsResolved", 0) + resolved_slots


def _import_asset_meshes(manifest, manifest_dir, content_root, report, materials_by_key=None):
    """Import each unique asset's local-space mesh once, as a UE5 StaticMesh.

    Keyed by asset rather than instance for the reason the exporter writes them that way: a brush
    used forty times is one mesh and forty transforms, not forty meshes.
    """
    meshes = {}
    materials_by_key = materials_by_key or {}

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
            mesh = unreal.EditorAssetLibrary.load_asset(asset_path)
        else:
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
        # Re-attempted on every run, existing mesh or not: cheap, idempotent, and the only way a
        # level re-exported with newly-resolved materials picks them up on an asset already in
        # the content browser from an earlier, material-less run.
        if materials_by_key:
            _assign_asset_material(mesh, asset, materials_by_key, report)

    _log("%d of %d assets imported as static meshes"
         % (len(meshes), len(manifest.get("assets") or [])))
    return meshes


def _manifest_actor_classes(manifest):
    return {entry["key"]: entry.get("className") or ""
            for entry in manifest.get("actors") or []}


def _manifest_asset_kinds(manifest):
    return {entry["key"]: entry.get("kind") or ""
            for entry in manifest.get("assets") or []}


def _manifest_asset_names(manifest):
    return {entry["key"]: entry.get("name") or ""
            for entry in manifest.get("assets") or []}


# BioShock corpse actors — policy lives in import_policy.py for unit tests outside the editor.
_is_dead_body_actor = import_policy.is_dead_body_actor
_uses_corpse_physics = import_policy.uses_corpse_physics
_requires_skeletal_rig = import_policy.requires_skeletal_rig
_dead_body_mesh_names = import_policy.dead_body_mesh_names
_effective_rig_names = import_policy.effective_rig_names


def _ensure_physics_asset(skeletal_mesh):
    """Create and assign a PhysicsAsset when the rig import left the mesh without one."""
    physics_asset = skeletal_mesh.get_editor_property("physics_asset")
    if physics_asset is not None:
        return physics_asset
    subsystem = unreal.get_editor_subsystem(unreal.SkeletalMeshEditorSubsystem)
    physics_asset = subsystem.create_physics_asset(skeletal_mesh, True, 0)
    if physics_asset is not None:
        unreal.EditorAssetLibrary.save_loaded_asset(physics_asset)
        unreal.EditorAssetLibrary.save_loaded_asset(skeletal_mesh)
    return physics_asset


def _configure_corpse_physics(actor, skeletal_mesh):
    """Ragdoll containers simulate; bodies start asleep so the level does not collapse on load."""
    physics_asset = _ensure_physics_asset(skeletal_mesh)
    component = actor.skeletal_mesh_component
    if physics_asset is not None:
        component.set_physics_asset(physics_asset, True)
    component.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
    component.set_simulate_physics(True)
    component.set_enable_gravity(True)
    component.set_collision_profile_name("Ragdoll")
    put_to_sleep = getattr(component, "put_all_rigid_bodies_to_sleep", None)
    if put_to_sleep is not None:
        put_to_sleep()


def _is_non_drawn_volume(class_name):
    """Gameplay regions the shipped game never renders — mirrors `ViewportItem.IsVolume`."""
    if not class_name:
        return False
    return (class_name.endswith("Volume")
            or class_name.endswith("Trigger")
            or class_name.endswith("ZoneInfo")
            or class_name.endswith("Zone"))


def _should_place_mesh_instance(actor_class, asset_kind):
    """Whether a manifest instance should become a visible mesh actor.

    Gameplay volumes are placed separately by `_import_region_volumes`. Source CSG brushes are never
    drawn in the shipped game — the compiled world already contains them.
    """
    if asset_kind == "Brush" and not _is_non_drawn_volume(actor_class):
        return False
    if _is_non_drawn_volume(actor_class):
        return False
    return True


# Back-compat for verify scripts written against the interim skip-only policy name.
_should_place_instance = _should_place_mesh_instance


def _remove_owned_mesh(key, existing, report):
    """Remove a visible mesh stand-in that a previous import wrongly placed on a non-drawn instance."""
    actor = existing.get(key)
    if actor is None:
        return
    if isinstance(actor, (unreal.StaticMeshActor, unreal.SkeletalMeshActor)):
        _actor_subsystem().destroy_actor(actor)
        existing.pop(key, None)
        report["removed"] = report.get("removed", 0) + 1


# UE2 volume class -> UE5 spawn class. TriggerBox is used for TriggerVolume because its box extent
# is settable from Python; ATriggerVolume's brush builder is not. Collision semantics match.
_VOLUME_SPAWN_CLASS = {
    "TriggerVolume": ("TriggerBox", "TriggerVolume"),
    "BlockingVolume": ("BlockingVolume",),
    "PathBlockingVolume": ("BlockingVolume",),
    "FluidVolume": ("PhysicsVolume",),
    "CascadingWaterVolume": ("PhysicsVolume",),
    "Volume": ("PhysicsVolume",),
}


def _resolve_volume_class(bio_class):
    for name in _VOLUME_SPAWN_CLASS.get(bio_class, ()):
        cls = getattr(unreal, name, None)
        if cls is not None:
            return cls
    return None


def _manifest_assets_by_key(manifest):
    return {entry["key"]: entry for entry in manifest.get("assets") or []}


def _instances_by_actor_key(manifest):
    grouped = {}
    for instance in manifest.get("instances") or []:
        grouped.setdefault(instance["actorKey"], []).append(instance)
    return grouped


def _obj_local_bounds(obj_path):
    """Axis-aligned bounds of an exported brush OBJ in its local space."""
    mins = [float("inf"), float("inf"), float("inf")]
    maxs = [-float("inf"), -float("inf"), -float("inf")]
    found = False
    with open(obj_path, "r", encoding="utf-8") as handle:
        for line in handle:
            if not line.startswith("v "):
                continue
            parts = line.split()
            if len(parts) < 4:
                continue
            x, y, z = float(parts[1]), float(parts[2]), float(parts[3])
            mins[0] = min(mins[0], x)
            mins[1] = min(mins[1], y)
            mins[2] = min(mins[2], z)
            maxs[0] = max(maxs[0], x)
            maxs[1] = max(maxs[1], y)
            maxs[2] = max(maxs[2], z)
            found = True
    if not found:
        return None
    return mins, maxs


def _point_from_manifest_matrix(matrix, x, y, z):
    """Row-major manifest matrix * column vector, matching `_decompose`'s convention."""
    return unreal.Vector(
        matrix[0] * x + matrix[4] * y + matrix[8] * z + matrix[12],
        matrix[1] * x + matrix[5] * y + matrix[9] * z + matrix[13],
        matrix[2] * x + matrix[6] * y + matrix[10] * z + matrix[14])


def _world_bounds_from_transform(matrix, local_mins, local_maxs):
    corners = []
    for sx in (local_mins[0], local_maxs[0]):
        for sy in (local_mins[1], local_maxs[1]):
            for sz in (local_mins[2], local_maxs[2]):
                corners.append(_point_from_manifest_matrix(matrix, sx, sy, sz))
    xs = [corner.x for corner in corners]
    ys = [corner.y for corner in corners]
    zs = [corner.z for corner in corners]
    center = unreal.Vector(
        (min(xs) + max(xs)) * 0.5,
        (min(ys) + max(ys)) * 0.5,
        (min(zs) + max(zs)) * 0.5)
    half = unreal.Vector(
        (max(xs) - min(xs)) * 0.5,
        (max(ys) - min(ys)) * 0.5,
        (max(zs) - min(zs)) * 0.5)
    return center, half


def _try_set_box_extent(actor, half_extent):
    """Set half-extents on a box-shaped volume actor if the spawned class exposes one."""
    for prop in ("collision_component", "brush_component", "root_component"):
        try:
            component = actor.get_editor_property(prop)
        except Exception:
            component = None
        if component is None:
            continue
        setter = getattr(component, "set_box_extent", None)
        if setter is not None:
            setter(half_extent, False)
            return True
    return False


def _volume_tags(entry):
    tags = [unreal.Name(KEY_TAG_PREFIX + entry["key"]),
            unreal.Name("BioShockClass=" + entry.get("className", ""))]
    if entry.get("tag"):
        tags.append(unreal.Name("BioShockTag=" + str(entry["tag"])))
    region = entry.get("regionActor") or {}
    triggered_by = region.get("triggeredBy")
    if triggered_by:
        tags.append(unreal.Name("BioShockTriggeredBy=" + str(triggered_by)))
    if region.get("triggerOnlyOnce") is True:
        tags.append(unreal.Name("BioShockTriggerOnlyOnce=1"))
    if region.get("disabled") is True:
        tags.append(unreal.Name("BioShockVolumeDisabled=1"))
    return tags


def _import_region_volumes(manifest, manifest_dir, existing, report, handled):
    """Place brush-backed gameplay volumes as invisible UE5 volume actors."""
    assets = _manifest_assets_by_key(manifest)
    instances = _instances_by_actor_key(manifest)

    for entry in manifest.get("actors") or []:
        class_name = entry.get("className") or ""
        if not _is_non_drawn_volume(class_name) or class_name.endswith("ZoneInfo"):
            continue

        key = entry["key"]
        handled.add(key)

        spawn_class = _resolve_volume_class(class_name)
        if spawn_class is None:
            report["volumesUnsupported"] = report.get("volumesUnsupported", 0) + 1
            continue

        brush_instances = [
            inst for inst in instances.get(key, [])
            if assets.get(inst.get("asset"), {}).get("kind") == "Brush"]
        if not brush_instances:
            report["volumesSkipped"] = report.get("volumesSkipped", 0) + 1
            continue

        instance = brush_instances[0]
        asset = assets.get(instance["asset"])
        if asset is None or not asset.get("file"):
            report["volumesSkipped"] = report.get("volumesSkipped", 0) + 1
            continue

        obj_path = os.path.join(manifest_dir, asset["file"].replace("/", os.sep))
        bounds = _obj_local_bounds(obj_path)
        if bounds is None:
            report["volumesSkipped"] = report.get("volumesSkipped", 0) + 1
            _log("volume %s: no OBJ bounds at %s" % (key, obj_path))
            continue

        center, half_extent = _world_bounds_from_transform(
            instance["transform"], bounds[0], bounds[1])
        _, rotation, _ = _decompose(instance["transform"])

        actor = existing.get(key)
        if actor is not None and not isinstance(actor, spawn_class):
            _actor_subsystem().destroy_actor(actor)
            actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                spawn_class, center, rotation)
            if actor is None:
                report["volumesSkipped"] = report.get("volumesSkipped", 0) + 1
                continue
            report["created"] += 1
            report["volumesPlaced"] = report.get("volumesPlaced", 0) + 1
        else:
            report["updated"] += 1
            actor.set_actor_location(center, False, False)
            actor.set_actor_rotation(rotation, False)

        if not _try_set_box_extent(actor, half_extent):
            # Fallback: scale the actor root when no box component API is exposed.
            actor.set_actor_scale3d(half_extent)

        actor.set_actor_label(entry.get("label") or entry.get("name") or key)
        actor.tags = _volume_tags(entry)
        existing[key] = actor


def _import_skeletal_rigs(manifest, manifest_dir, report, character_content_root, rig_names=None):
    """Imports the FBX rig export-level wrote for each SkeletalMesh-kind asset (one directory per
    distinct mesh, `Rigs/<meshName>/ue5_manifest.json`, next to the level's own manifest), so
    `_import_instances` can place these as real animated SkeletalMeshActors below.

    Returns {assetKey: unreal.SkeletalMesh}, keyed the same way `_import_asset_meshes` keys its own
    {assetKey: StaticMesh} dict, so a single instance's `"asset"` field looks either dict up the
    same way. A missing or failed rig import is skipped rather than raised -- `_import_instances`
    falls back to the bind-pose static mesh for that asset, so a broken rig loses animation, not
    the actor's representation entirely.

    `character_content_root` is deliberately separate from this level's own `content_root`: a
    character (e.g. a common splicer variant) can appear in many different levels and should be
    one shared, reused asset across all of them, not duplicated per level.
    `import_bioshock.main` reuses a previous complete import of the same export (fingerprint +
    inventory), so a later level that shares a character does not re-normalize every animation.
    `rig_names`, when given, is the set of mesh names to import rigs for; every other SkeletalMesh
    asset falls back to the bind-pose static mesh exactly as it does for a rig that failed to
    import. That is a deliberate narrowing for a thin slice, not a coverage claim -- the caller
    reports which names it asked for so a filtered run cannot read as a whole-level one.

    Corpse placements are always unioned into that set — see `_effective_rig_names`.
    """
    rig_names = _effective_rig_names(manifest, rig_names)
    if rig_names is not None:
        report["deadBodyRigs"] = sorted(_dead_body_mesh_names(manifest))
        report["rigsRequested"] = sorted(rig_names)

    skeletal_meshes = {}
    for asset in manifest.get("assets") or []:
        if asset.get("kind") != "SkeletalMesh":
            continue
        if rig_names is not None and asset["name"] not in rig_names:
            continue

        rig_dir = os.path.join(manifest_dir, "Rigs", asset["name"])
        if not os.path.exists(os.path.join(rig_dir, "ue5_manifest.json")):
            continue

        try:
            imported = import_bioshock.main(rig_dir, content_root=character_content_root)
        except Exception as error:
            _log("rig import failed for %s: %s" % (asset["name"], error))
            continue

        if imported:
            skeletal_meshes[asset["key"]] = next(iter(imported.values()))

    if skeletal_meshes:
        _log("%d character rig(s) imported" % len(skeletal_meshes))
    return skeletal_meshes


def _import_instances(manifest, meshes, skeletal_meshes, existing, report, handled):
    """Place every geometry instance as a StaticMeshActor carrying the asset's mesh -- or, for an
    instance whose asset has a successfully imported character rig, a SkeletalMeshActor instead."""
    actor_classes = _manifest_actor_classes(manifest)
    asset_kinds = _manifest_asset_kinds(manifest)

    for instance in manifest.get("instances") or []:
        key = "instance:" + instance["actorKey"] + ":" + instance["asset"]
        if key in handled:
            continue
        handled.add(key)

        actor_class_name = actor_classes.get(instance["actorKey"], "")
        asset_kind = asset_kinds.get(instance["asset"], "")
        if not _should_place_mesh_instance(actor_class_name, asset_kind):
            _remove_owned_mesh(key, existing, report)
            report["meshInstancesSkipped"] = report.get("meshInstancesSkipped", 0) + 1
            continue

        asset_name = _manifest_asset_names(manifest).get(instance["asset"], "")
        needs_skeletal = _requires_skeletal_rig(actor_class_name, asset_name)
        skeletal_mesh = skeletal_meshes.get(instance["asset"])
        static_mesh = meshes.get(instance["asset"])
        if needs_skeletal and skeletal_mesh is None:
            _remove_owned_mesh(key, existing, report)
            report["unsupported"] += 1
            _log("corpse placement %s: no skeletal rig for %s" % (instance["actorKey"], asset_name))
            continue

        actor_class = unreal.SkeletalMeshActor if skeletal_mesh is not None else unreal.StaticMeshActor

        if skeletal_mesh is None and static_mesh is None:
            report["unsupported"] += 1
            continue

        location, rotation, scale = _decompose(instance["transform"])

        actor = existing.get(key)
        # An actor already owned by a previous run must still be the right class -- a run before
        # this asset's rig existed (or after one was newly added) would have left a placeholder of
        # the other class here. _import_lights already has this exact pattern for a light
        # replacing a stale placeholder; recreate rather than try to reuse the wrong actor type.
        if actor is not None and not isinstance(actor, actor_class):
            _actor_subsystem().destroy_actor(actor)
            actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                actor_class, location, rotation)
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1
            actor.set_actor_location(location, False, False)
            actor.set_actor_rotation(rotation, False)

        if skeletal_mesh is not None:
            actor.skeletal_mesh_component.set_skeletal_mesh_asset(skeletal_mesh)
            if _uses_corpse_physics(actor_class_name):
                _configure_corpse_physics(actor, skeletal_mesh)
                report["corpsesWithPhysics"] = report.get("corpsesWithPhysics", 0) + 1
            elif needs_skeletal:
                report["corpseSkeletalOnly"] = report.get("corpseSkeletalOnly", 0) + 1
        else:
            actor.static_mesh_component.set_static_mesh(static_mesh)
        actor.set_actor_scale3d(scale)
        actor.set_actor_label(instance.get("label") or instance.get("actor") or key)
        actor.tags = [unreal.Name(KEY_TAG_PREFIX + key)]
        existing[key] = actor

        # _import_actors checks the bare actor key, not this function's "instance:...:..." one --
        # only added here, once a real mesh actor is actually standing, so a mesh lookup or spawn
        # failure above still falls through to _import_actors' TargetPoint fallback rather than
        # leaving the actor with no representation at all. Before this, EVERY actor that reached
        # this point still got a second, overlapping TargetPoint spawned afterwards and miscounted
        # as unsupported -- on 1-Medical this inflated the reported unsupported count from a true
        # 2,018 to 7,337, since 5,321 actors with working geometry were double-counted as if they
        # had none.
        handled.add(instance["actorKey"])

def main(manifest_path, import_actors=True, content_root="/Game/BioShockLevel",
         character_content_root="/Game/BioShockCharacters", rig_names=None):
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

    report = {
        "created": 0, "updated": 0, "skipped": 0, "unsupported": 0,
        "meshInstancesSkipped": 0, "volumesPlaced": 0, "volumesSkipped": 0,
        "volumesUnsupported": 0,
    }
    existing = _existing_by_key()
    _log("%d actor(s) already owned by a previous run" % len(existing))

    manifest_dir = os.path.dirname(os.path.abspath(manifest_path))
    # A level-specific subfolder, the same convention _load_or_create_master's caller uses per
    # rig -- distinct levels can otherwise resolve two different materials to the same generated
    # name and collide in one shared folder. content_root itself stays shared for the master
    # material graphs, which are meant to be reused across every level and rig alike.
    destination = "%s/%s" % (content_root, manifest.get("package") or "Level")
    materials_by_key = _import_level_materials(manifest, manifest_dir, destination, content_root, report)
    if materials_by_key:
        _log("%d material instance(s) resolved for this level" % len(materials_by_key))

    cubemap_faces = _import_cubemap_faces(manifest, manifest_dir, destination, report)

    handled = set()
    _import_lights(manifest, existing, report, handled)
    _import_cubemap_probes(manifest, existing, report, handled, cubemap_faces)

    skeletal_meshes = _import_skeletal_rigs(
        manifest, manifest_dir, report, character_content_root, rig_names)

    # Geometry first, so an actor that gets a real mesh is not also counted as a placeholder.
    meshes = _import_asset_meshes(manifest, manifest_dir, content_root, report, materials_by_key)
    _import_instances(manifest, meshes, skeletal_meshes, existing, report, handled)
    _import_region_volumes(manifest, manifest_dir, existing, report, handled)

    if import_actors:
        _import_actors(manifest, existing, report, handled)

    _log("import report: %d created, %d updated, %d skipped, %d unsupported, "
         "%d mesh instance(s) not drawn, %d volume(s) placed, %d volume(s) skipped, "
         "%d mesh(es) with a material assigned, %d material slot(s) resolved"
         % (report["created"], report["updated"], report["skipped"], report["unsupported"],
            report.get("meshInstancesSkipped", 0), report.get("volumesPlaced", 0),
            report.get("volumesSkipped", 0), report.get("materialsAssigned", 0),
            report.get("materialSlotsResolved", 0)))

    main.last_report = report
    return report
