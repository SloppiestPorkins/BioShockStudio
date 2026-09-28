"""Deterministic level import: create or update UE5 actors from a BioShock level manifest.

Gate 3 item 4. Reads a `<map>.ue5-level.json` produced by `export-level` and reproduces its actors
in the currently-open UE5 level, then reports what it did in one pass:

    created / updated / skipped / unsupported

**Idempotent by construction.** Every actor this script owns carries a `BioShockKey=<manifest key>`
tag. A second run finds the existing actor by that tag and updates it in place rather than spawning
a duplicate, which is the property Gate 5 item 1 asks for and the one that makes re-importing a
level safe.

**What is and is not reproduced.** Lights become real UE5 light actors branched on authored
`LightEffect` shape (W-BUG-01): point → `PointLight`, spot → `SpotLight` (rotation + cone),
sun/directional → `DirectionalLight` (rotation; no attenuation radius). Colour and authored
`LightBrightness` map to intensity (no candela conversion); point/spot carry `LightRadius` as
attenuation radius with inverse-square falloff off so intensity stays a brightness scale. A
point/spot/directional light with no radius is not spawned — its reach is UNKNOWN; sun lights
omit radius by design and still spawn. **Drawable** geometry instances become `StaticMeshActor`/
`SkeletalMeshActor`. **Gameplay volumes** (`TriggerVolume`, `BlockingVolume`, `FluidVolume`, …)
become invisible UE5 volume actors sized from their brush OBJ bounds — never as visible meshes.
**Water volumes** (`FluidVolume`, `CascadingWaterVolume`, `TunnelCollapseWaterVolume`) spawn as
`AShockWaterVolume`: hidden query box plus a visible top-face plane (`M_ShockWater`).
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
import struct

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

    tags = [unreal.Name(KEY_TAG_PREFIX + key), unreal.Name("BioShockLabel=" + str(label))]
    if entry.get("className"):
        tags.append(unreal.Name("BioShockClass=" + entry["className"]))
    if entry.get("tag"):
        tags.append(unreal.Name("BioShockTag=" + str(entry["tag"])))
    actor.tags = tags


# UE2 ELightType ordinal -> our EShockLightEffectType ordinal (SCR-G07 / W-BUG-03). Engine.u's
# ELightType is a native base-engine enum with no decompiled UE2 source in this repo; 0-5 are read
# off its declared order (None, Steady, Pulse, Blink, Flicker, Strobe) and happen to already match
# our own component's first six ordinals (see ShockLightEffectComponent.h) one-for-one. 7 is
# SubtlePulse, one slot further along than our component's SubtlePulse (6) because our enum has no
# BackdropLight slot. 6/8/9/10 (BackdropLight, the two TexturePalette modes, FadeOut) have no
# equivalent modulator here — an authored texture palette isn't decoded, so a light using one stays
# steady rather than getting a guessed waveform. Values are (name-for-logging, our-ordinal); the
# ordinal is what actually gets written — unreal.EShockLightEffectType is not attribute-accessible
# on the unreal module in a commandlet that has never otherwise touched the enum by name, but a
# plain int coerces into an EnumProperty fine via set_editor_property.
_UE2_LIGHT_TYPE_TO_EFFECT = {
    # 0 (LT_None) is handled separately in _apply_light_effect — it means the light is off, not
    # just unanimated, so it never reaches this table.
    2: ("Pulse", 2),
    3: ("Blink", 3),
    4: ("Flicker", 4),
    5: ("Strobe", 5),
    7: ("SubtlePulse", 6),
}

# BioShock LightEffect → shape (W-BUG-01). Not stock UE2's 20-value waver enum — the SDK guide's
# lighting chapter lists four shapes in declaration order (Pointlight, Spotlight, Sunlight,
# Directionallight). Engine.u's exact ordinals are still unreadable here (W-UNK-01), so the map
# below is inferred the same way `_UE2_LIGHT_TYPE_TO_EFFECT` is: declared-order names plus the
# real Medical census. In `1-Medical.ue5-level.json` (695 lights): effect absent 514, 2→175,
# 3→6; cone set on 232 (148 of the effect=2 set). That pins:
#   absent / 0 / 1 → point  (guide default is Pointlight; whole-game also writes rare explicit 1)
#   2             → spot   (25% of Medical; 148/175 carry LightCone; 174/175 non-identity rotation)
#   3             → sun    (6 lights; two omit radius entirely — only sun does that per the guide)
#   4             → directional (not seen in Medical; same UE5 class as sun)
# Confidence: PLAUSIBLE. **28 Sept correction:** sun/directional originally spawned UE5's
# `DirectionalLight` (a positionless, whole-scene actor). UE5 expects at most ONE meaningful
# DirectionalLight per level -- it is the single light selected for forward shading / water /
# volumetric fog, and a second one only produces "multiple directional lights are competing"
# (visible in-editor, and the reason water and other forward-shaded surfaces read as an untextured
# checker: the wrong light -- or none deterministically -- won the selection). Medical alone places
# 6 "sun"-shaped lights, each at its own room location; BioShock's own engine has no such
# singleton rule, so a 1:1 class mapping was wrong regardless of how confident the shape ordinal
# is. A DirectionalLight also ignores its Location entirely (only rotation matters), so mapping a
# POSITIONED BioShock light onto it silently discarded exactly the data that makes each one a
# separate room light. Sun/directional now spawn `SpotLight` like a real aimed local light --
# still uses the (now-exported) rotation and an authored/default cone -- never the scene-wide actor.
_UE2_LIGHT_EFFECT_TO_SHAPE = {
    0: "point",
    1: "point",
    2: "spot",
    3: "sun",
    4: "directional",
}

# Guide default LightCone when a spotlight omits the byte.
_DEFAULT_SPOT_CONE_BYTE = 128


def _light_shape(light):
    """Return 'point' | 'spot' | 'sun' | 'directional' from the authored LightEffect byte."""
    effect = light.get("effect")
    if effect is None:
        return "point"
    return _UE2_LIGHT_EFFECT_TO_SHAPE.get(int(effect), "point")


def _light_actor_class(shape):
    if shape in ("spot", "sun", "directional"):
        return unreal.SpotLight
    return unreal.PointLight


def _is_imported_light_actor(actor):
    return isinstance(actor, (unreal.PointLight, unreal.SpotLight, unreal.DirectionalLight))


def _cone_half_angle_degrees(cone_byte):
    """Spot half-angle in degrees from the guide relation cos(θ) = 1 − LightCone/255."""
    cosine = 1.0 - float(cone_byte) / 255.0
    cosine = max(-1.0, min(1.0, cosine))
    return math.degrees(math.acos(cosine))


def _with_light_rotation(light, actors_by_key):
    """Prefer lights[].rotation; fall back to actors[] (same key) until manifests are re-exported."""
    if light.get("rotation"):
        return light
    actor_doc = actors_by_key.get(light.get("key"))
    if actor_doc is not None and actor_doc.get("rotation") is not None:
        enriched = dict(light)
        enriched["rotation"] = actor_doc["rotation"]
        return enriched
    return light


def _apply_light_effect(actor, light, component):
    """SCR-G07 / W-BUG-03: animate LightType via UShockLightEffectComponent; steady is untouched.

    Only touches `intensity` on the shared ULightComponent base — safe for Point/Spot/Directional.
    Does not read or write attenuation_radius (DirectionalLight has none).
    """
    light_type = light.get("type")
    if light_type is None:
        return
    light_type = int(light_type)
    if light_type == 0:
        # LT_None: the guide's light-types table describes this ordinal as the light being off,
        # not merely unanimated — an authored radius/brightness still exists (this importer would
        # otherwise light the room), so zero the intensity rather than skip it.
        component.set_editor_property("intensity", 0.0)
        return
    mapped = _UE2_LIGHT_TYPE_TO_EFFECT.get(light_type)
    if not mapped:
        return  # unmapped ordinal (BackdropLight/TexturePalette*/FadeOut) — leave steady, not guessed
    _effect_name, effect_ordinal = mapped
    effect_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockLightEffectComponent")
    if effect_cls is None:
        return
    effect_component = unreal.ShockLightEffectComponent.ensure_on_actor(actor)
    if effect_component is None:
        return
    period_raw = light.get("period")
    # LightPeriod's authored unit is UNKNOWN (byte/scale APPROXIMATED per the component's own
    # comment); treat it as already-seconds rather than invent a conversion factor.
    period_seconds = float(period_raw) if period_raw else 1.0
    base_intensity = float(component.get_editor_property("intensity"))
    # LightPhase is not exported (UNKNOWN offset) — start every cycle at 0 rather than guess.
    effect_component.configure_from_int(effect_ordinal, base_intensity, max(period_seconds, 0.1), 0.0)


def _import_lights(manifest, existing, report, handled):
    """Lights are the one class reproduced as a real, functioning UE5 actor."""
    actors_by_key = {a["key"]: a for a in (manifest.get("actors") or []) if a.get("key")}
    for light in manifest.get("lights") or []:
        key = light["key"]
        actor = existing.get(key)
        shape = _light_shape(light)
        expected_cls = _light_actor_class(shape)
        radius = light.get("radius")
        has_radius = radius is not None and float(radius) > 0
        if not has_radius and shape == "sun":
            # A radius-less "sun" light (2 of Medical's 6) modelled infinite reach when this shape
            # spawned UE5's positionless DirectionalLight; now that it is a real local SpotLight (see
            # the shape-mapping comment above), it needs an actual reach. No authored value exists to
            # carry, so this is a placed guess sized to fill a room rather than a decoded number.
            radius = 3000.0
            has_radius = True
        # Point/spot need a radius; without one and not a sun, reach is UNKNOWN — drop rather than
        # invent UE5's 1000 cm default.
        if not has_radius:
            if actor is not None and _is_imported_light_actor(actor):
                _actor_subsystem().destroy_actor(actor)
                existing.pop(key, None)
            continue

        handled.add(key)
        light = _with_light_rotation(light, actors_by_key)

        # Wrong class (placeholder TargetPoint, or a prior PointLight under a spot key) → replace.
        if actor is not None and not isinstance(actor, expected_cls):
            _actor_subsystem().destroy_actor(actor)
            actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                expected_cls, unreal.Vector(*_to_unreal_location(light.get("location", [0, 0, 0]))))
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

        brightness = light.get("brightness")
        intensity = float(brightness) if brightness is not None else 1.0
        component.set_editor_property("intensity", intensity)

        if shape in ("point", "spot", "sun", "directional"):
            # Radius is world centimetres, same unit as UE5 AttenuationRadius — carry it, do not scale.
            component.set_editor_property("attenuation_radius", float(radius))
            # Inverse-square treats AttenuationRadius as a clip on 1/r^2. BioShock authored a finite
            # radius as the light's reach. When inverse-square is off, Intensity is a brightness
            # scale — carry LightBrightness, do not multiply.
            component.set_editor_property("use_inverse_squared_falloff", False)
            units = getattr(unreal.LightUnits, "UNITLESS", None)
            if units is not None:
                component.set_editor_property("intensity_units", units)
            if shape == "spot":
                cone_byte = light.get("cone")
                if cone_byte is None:
                    cone_byte = _DEFAULT_SPOT_CONE_BYTE
                component.set_editor_property(
                    "outer_cone_angle", _cone_half_angle_degrees(cone_byte))
            elif shape in ("sun", "directional"):
                # No LightCone concept for these shapes (the guide's cone formula is spot-only) --
                # a wide fixed cone approximates a broad wash of light rather than a narrow beam.
                component.set_editor_property("outer_cone_angle", 80.0)
        # (no remaining shape needs component-level handling here)
        # brightness, rotation, and type-driven effect only.

        _apply_light_effect(actor, light, component)


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
            # save=True and the default (Interchange) factory both trip
            # Assertion failed: CurrentApplication.IsValid() under -run=pythonscript -- Interchange
            # fires a Slate completion notification, and save routes through
            # InternalPromptForCheckoutAndSave. Pin the legacy factory (there is no
            # Interchange.FeatureFlags.Import.Texture CVar) and persist explicitly below.
            task.set_editor_property("save", False)
            try:
                task.set_editor_property("factory", unreal.TextureFactory())
            except Exception as exc:  # noqa: BLE001
                _log("  could not pin the legacy texture factory for cubemap faces (%s)" % exc)
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


# BioShock actor classes that must come through as a real UE5 class rather than a marker,
# because the engine gives them behaviour a TargetPoint does not have. PlayerStart is the one
# that matters today: without it ChoosePlayerStart finds nothing and the pawn spawns at world
# origin. Everything absent from this table stays a positioned TargetPoint, which is honest —
# it records where something belongs without pretending the pipeline understands it yet.
_PLACED_ACTOR_CLASSES = {
    "PlayerStart": unreal.PlayerStart,
}


def _import_vita_chambers(manifest, meshes, existing, report, handled):
    """Import BaseResurrectionStation records as active runtime chambers.

    The actor directly names the shipped Resurrection static mesh. ResStationAnim is the original
    door/player-start skeleton, but the level exporter currently supplies it only as a reference,
    not an animation asset; AShockVitaChamber therefore owns the machine mesh and explicit start
    offset documented in docs/research/vita-chamber.md.
    """
    chamber_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockVitaChamber")
    chamber_type = getattr(unreal, "ShockVitaChamber", None)
    if chamber_cls is None or chamber_type is None:
        return

    for entry in manifest.get("actors") or []:
        if entry.get("className") != "ResurrectionStation":
            continue
        key = entry["key"]
        handled.add(key)
        actor = existing.get(key)
        if actor is not None and not isinstance(actor, chamber_type):
            _actor_subsystem().destroy_actor(actor)
            actor = None
        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(
                chamber_cls, unreal.Vector(*(entry.get("location") or [0, 0, 0])))
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1

        existing[key] = actor
        _place(actor, entry, key)
        actor.configure_identity(
            unreal.Name(entry.get("label") or entry.get("name") or key), key)
        mesh_ref = entry.get("staticMeshReference") or {}
        mesh = meshes.get(mesh_ref.get("sourceKey"))
        if mesh is not None:
            actor.set_station_mesh(mesh)
        actor.set_available(True)
        # SCR-B12: available (usable when active) != active. A chamber is not activated until the
        # player approaches it (AShockVitaChamber's own overlap volume) or a level script fires
        # ActionActivateResurrectionStation — do not force it on at import.
        report["vitaChambersPlaced"] = report.get("vitaChambersPlaced", 0) + 1


def _import_actors(manifest, existing, report, handled):
    """Everything that is not a light: positioned, identified, and honestly reported."""
    for entry in manifest.get("actors") or []:
        key = entry["key"]

        # The actors list includes the lights, which _import_lights has already placed as real
        # light actors (Point/Spot/Directional). Skipping on `handled` rather than on the pre-run
        # snapshot matters: the
        # snapshot is taken before anything spawns, so on a first run it does not contain the
        # lights this same run just created, and every light was getting a duplicate placeholder.
        if key in handled:
            continue
        handled.add(key)

        spawn_class = _PLACED_ACTOR_CLASSES.get(entry.get("className"), unreal.TargetPoint)

        actor = existing.get(key)
        # A previous run placed everything as a TargetPoint, including the PlayerStarts. Recreate
        # when the existing actor is the wrong class, the same way _import_instances does for a
        # mesh whose rig appeared later.
        if actor is not None and not isinstance(actor, spawn_class):
            _actor_subsystem().destroy_actor(actor)
            actor = None

        if actor is None:
            # TargetPoint is the fallback, not the rule: it is the engine's own positioned-marker
            # class, right for an actor whose geometry this pipeline has not imported. But a class
            # with real engine behaviour has to come through as itself — a PlayerStart placed as a
            # TargetPoint is invisible to ChoosePlayerStart, so the pawn spawns at world origin,
            # outside the level, which is exactly what the first captured render showed.
            actor = _actor_subsystem().spawn_actor_from_class(
                spawn_class, unreal.Vector(*(entry.get("location") or [0, 0, 0])))
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
            if spawn_class is not unreal.TargetPoint:
                report["typedActors"] = report.get("typedActors", 0) + 1
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


def _material_texture_for_file(manifest, material, relative_file, destination,
                               imported_by_file):
    if not relative_file:
        return None
    entry = next((
        item for item in (manifest.get("textures") or [])
        if item.get("material") == material.get("name")
        and item.get("file") == relative_file
    ), None)
    if entry is None:
        return None
    return import_bioshock._resolve_imported_texture(entry, destination, imported_by_file)


def _configure_medical_fluid_materials(manifest, instances, destination,
                                       imported_by_file, report):
    """Reparent Medical's decoded FluidShader MIs to the specialised water graph.

    The confirmed surface link is the ordinary render chain
    assets[].sections[].materialKey -> instances[].asset/actorKey. The 27 water-volume brush
    assets have no materialKey and their actors have empty materialOverrides, so this deliberately
    does not invent a nearest-volume association for the generic collision-volume planes.
    """
    if manifest.get("package") != "1-Medical":
        return

    import author_water_material

    water_report = {"failures": [], "assets": {}}
    master, _ = author_water_material.ensure_water_materials(water_report)
    report["waterMaterials"] = water_report.get("assets") or {}
    if water_report.get("failures") or master is None:
        raise RuntimeError(
            "could not author Medical FluidShader master: %s" % water_report.get("failures"))

    for material, instance in zip(manifest.get("materials") or [], instances):
        if material.get("className") != "FluidShader":
            continue
        diffuse = _material_texture_for_file(
            manifest, material, material.get("diffuse"), destination, imported_by_file)
        normal = _material_texture_for_file(
            manifest, material, material.get("normalMap"), destination, imported_by_file)
        author_water_material.configure_fluid_instance(
            material,
            instance,
            diffuse_texture=diffuse,
            normal_texture=normal,
            master=master,
            report=report,
        )


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
    _configure_medical_fluid_materials(
        manifest, instances, destination, imported_by_file, report)
    return {material["key"]: instance for material, instance in zip(materials, instances)}


def _mesh_section_count_mismatch(mesh, asset):
    """True when LOD0 has fewer render sections than the manifest's section table.

    Measured 4 Sept 2026 on 1-Medical: 792 of 793 multi-slot StaticMeshes carried N correctly
    bound `static_materials` entries but only 1 render section / 1 polygon group. Cause: the mesh
    was first imported before `BuildAssetObj` emitted `usemtl` groups, and `_import_asset_meshes`
    reused the existing asset forever, only re-running `_assign_asset_material`. Slot assignment
    cannot invent sections — every triangle keeps MaterialIndex 0, so every slot shows the first
    material. A fresh OBJ import of the same file yields the correct section count (confirmed on
    `ad_horizontal_3702`: existing 1 section / 1 polygon group; fresh import 2 / 2).
    """
    sections = asset.get("sections") or []
    if len(sections) <= 1:
        return False
    try:
        return int(mesh.get_num_sections(0)) < len(sections)
    except Exception:  # noqa: BLE001 — treat unreadable section count as needing a reimport
        return True


def _assign_asset_material(mesh, asset, materials_by_key, report):
    """Assign each of a static mesh's material slots from the manifest section table, in order.

    `BuildAssetObj` writes one `usemtl BioShock_{index}` group per manifest `sections` entry, in
    that same order. A correct OBJ import therefore produces one LOD section per entry, and slot N
    corresponds to `sections[N]`. This function only writes `static_materials` — it does not create
    or split render sections. If the mesh still has fewer sections than the manifest (the
    pre-usemtl import case), reimport the OBJ first; see `_mesh_section_count_mismatch`.

    One slot is built per section regardless of whether several sections share a material key, so
    a later section can't shift into an earlier section's slot index. A section with no resolved
    key gets an empty slot (no material_interface) rather than silently inheriting a neighbour's
    material.
    """
    sections = asset.get("sections") or []
    if not sections:
        # No section table at all: leave whatever material the import gave the mesh alone, exactly
        # as before this function assigned anything. Setting an empty static_materials list here
        # would clear the mesh's material instead of leaving it untouched.
        return

    if _mesh_section_count_mismatch(mesh, asset):
        # Do not paper over a 1-section mesh with an N-slot array — that is exactly the state that
        # made "materialsAssigned" look healthy while every triangle still sampled slot 0.
        report["materialSectionMismatch"] = report.get("materialSectionMismatch", 0) + 1
        _log("  skip material assign for %s: mesh has %s section(s), manifest has %d — reimport OBJ"
             % (asset.get("name") or asset.get("key"), mesh.get_num_sections(0), len(sections)))
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


def _import_static_mesh_obj(source, destination, stem):
    """Import (or replace) one OBJ as a StaticMesh under destination/stem."""
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", source)
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("destination_name", stem)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", True)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    return next((o for o in task.get_objects() if isinstance(o, unreal.StaticMesh)), None)


def _import_asset_meshes(manifest, manifest_dir, content_root, report, materials_by_key=None):
    """Import each unique asset's local-space mesh once, as a UE5 StaticMesh.

    Keyed by asset rather than instance for the reason the exporter writes them that way: a brush
    used forty times is one mesh and forty transforms, not forty meshes.

    An existing mesh whose LOD0 section count is below the manifest section count is reimported
    rather than reused: material-slot assignment alone cannot fix a single-section import.
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

        mesh = None
        if unreal.EditorAssetLibrary.does_asset_exist(asset_path):
            mesh = unreal.EditorAssetLibrary.load_asset(asset_path)
            if mesh is not None and _mesh_section_count_mismatch(mesh, asset):
                report["sectionReimports"] = report.get("sectionReimports", 0) + 1
                _log("  reimport %s: section count %s < manifest %d"
                     % (stem, mesh.get_num_sections(0), len(asset.get("sections") or [])))
                mesh = None

        if mesh is None:
            mesh = _import_static_mesh_obj(source, destination, stem)

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
            or class_name == "TriggerRadius"
            or class_name.endswith("ZoneInfo")
            or class_name.endswith("Zone"))


def _is_animated_prop_class(actor_class):
    """ScriptableMover / Fan / Mover — placed as AShockAnimatedProp, not a static mesh."""
    return actor_class in ("ScriptableMover", "Fan", "Mover")


def _is_fan_mesh_name(name):
    """Medical has no Fan class; spinning props ship as StaticMeshActors named *fan*."""
    return bool(name) and "fan" in name.lower()


def _should_place_mesh_instance(actor_class, asset_kind, asset_name=""):
    """Whether a manifest instance should become a visible mesh actor.

    Gameplay volumes are placed separately by `_import_region_volumes`. Source CSG brushes are never
    drawn in the shipped game — the compiled world already contains them. Animated props
    (ScriptableMover / Fan / fan meshes) are placed by `_import_animated_props`.
    """
    if asset_kind == "Brush" and not _is_non_drawn_volume(actor_class):
        return False
    if _is_non_drawn_volume(actor_class):
        return False
    if _is_animated_prop_class(actor_class) or _is_fan_mesh_name(asset_name):
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
# Water volumes become AShockWaterVolume (overlap + rendered surface), not PhysicsVolume — the
# brush-backed PhysicsVolume was drawing green bars in -game captures (see _hide_volume_in_game).
_WATER_VOLUME_CLASSES = frozenset({
    "FluidVolume",
    "CascadingWaterVolume",
    "TunnelCollapseWaterVolume",
})

_VOLUME_SPAWN_CLASS = {
    "TriggerVolume": ("TriggerBox", "TriggerVolume"),
    # TriggerRadius has no brush; TriggerSphere exposes a settable sphere radius from Python.
    "TriggerRadius": ("TriggerSphere", "TriggerBox"),
    "BlockingVolume": ("BlockingVolume",),
    "PathBlockingVolume": ("BlockingVolume",),
    "FluidVolume": ("PhysicsVolume",),  # fallback if ShockWaterVolume missing
    "CascadingWaterVolume": ("PhysicsVolume",),
    "TunnelCollapseWaterVolume": ("PhysicsVolume",),
    "Volume": ("PhysicsVolume",),
}


def _resolve_volume_class(bio_class):
    if bio_class in _WATER_VOLUME_CLASSES:
        water_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWaterVolume")
        if water_cls is not None:
            return water_cls
    for name in _VOLUME_SPAWN_CLASS.get(bio_class, ()):
        cls = getattr(unreal, name, None)
        if cls is not None:
            return cls
    return None


def _is_water_volume_class(class_name):
    return class_name in _WATER_VOLUME_CLASSES


def _ensure_water_materials_for_import(report):
    """Author M_ShockWater if missing — surfaces need it before ConfigureFromHalfExtent."""
    try:
        import author_water_material
    except ImportError:
        report["waterMaterialError"] = "author_water_material import failed"
        return
    water_report = {"failures": [], "assets": {}}
    author_water_material.ensure_water_materials(water_report)
    report["waterMaterials"] = water_report.get("assets") or {}
    if water_report.get("failures"):
        report.setdefault("waterMaterialFailures", []).extend(water_report["failures"])


def _configure_shock_water_volume(actor, half_extent, class_name, report):
    """Size AShockWaterVolume, hide the query box, place the top-face surface."""
    cascading = class_name == "CascadingWaterVolume"
    configure = getattr(actor, "configure_from_half_extent", None)
    if configure is not None:
        configure(half_extent, cascading)
        report["waterSurfacesConfigured"] = report.get("waterSurfacesConfigured", 0) + 1
        return True
    # Fallback if the C++ API is unavailable on a stale binary.
    if _try_set_box_extent(actor, half_extent):
        refresh = getattr(actor, "refresh_surface", None)
        if refresh is not None:
            try:
                actor.set_editor_property("b_cascading", cascading)
            except Exception:  # noqa: BLE001
                pass
            refresh()
            report["waterSurfacesConfigured"] = report.get("waterSurfacesConfigured", 0) + 1
            return True
    return False


def _hide_volume_in_game(actor):
    """Stop a gameplay volume's brush drawing in the shipped view.

    These are supposed to be invisible - the module docstring above says so - but a spawned
    PhysicsVolume keeps a UBrushComponent that is a real, renderable primitive, and Unreal draws
    volume brushes GREEN. A -game scene capture aimed at the Medical Pavilion entrance came back
    with a saturated green bar (RGB ~80,255,30) across the bottom of the window, which is three
    overlapping water volumes - CascadingWaterVolume3, FluidVolume2, TunnelCollapseWaterVolume -
    being drawn as geometry. Nothing in the editor viewport makes this obvious, because volume
    brushes are *supposed* to show there.

    Sets both flags: hidden_in_game covers the running game, and visible covers a scene capture,
    which does not respect hidden_in_game on every component type.

    AShockWaterVolume owns a separate Surface mesh for the waterline; this still hides the
    query/brush primitives so only the surface draws.
    """
    hidden = 0
    surface = getattr(actor, "surface", None)
    for component in actor.get_components_by_class(unreal.PrimitiveComponent):
        # Keep the authored water surface visible.
        if surface is not None and component == surface:
            continue
        # Collision must keep working - this is a volume, being inside it is its whole job.
        try:
            component.set_editor_property("hidden_in_game", True)
            component.set_editor_property("visible", False)
            hidden += 1
        except Exception:  # noqa: BLE001
            continue
    return hidden


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


# AVolume's default CubeBuilder is 200uu on a side (local half-extent 100). Scaling the actor
# by the desired half-extent in uu (e.g. scale=112 for a 112uu half-box) makes BlockingVolumes
# ~100x too large — solid boxes tens of thousands of uu across that trap the player and zero
# CMC velocity. Measured 4 Sept 2026 on 1-Medical: scale=(112,60,180) → extent=(11200,6000,18000).
_DEFAULT_VOLUME_BRUSH_HALF = 100.0


def _set_volume_half_extent(actor, half_extent):
    """Size a spawned volume to the manifest brush bounds, without the 100x scale bug."""
    if _try_set_box_extent(actor, half_extent):
        return "box_extent"
    actor.set_actor_scale3d(unreal.Vector(
        half_extent.x / _DEFAULT_VOLUME_BRUSH_HALF,
        half_extent.y / _DEFAULT_VOLUME_BRUSH_HALF,
        half_extent.z / _DEFAULT_VOLUME_BRUSH_HALF))
    return "brush_scale"


def _volume_tags(entry):
    tags = [
        unreal.Name(KEY_TAG_PREFIX + entry["key"]),
        unreal.Name("BioShockLabel=" + str(entry.get("label") or entry.get("name") or entry["key"])),
        unreal.Name("BioShockClass=" + entry.get("className", "")),
    ]
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
    """Place brush-backed gameplay volumes as invisible UE5 volume actors.

    Water volumes (FluidVolume / CascadingWaterVolume / TunnelCollapseWaterVolume) spawn as
    AShockWaterVolume: hidden query box + visible top-face surface with M_ShockWater.
    """
    assets = _manifest_assets_by_key(manifest)
    instances = _instances_by_actor_key(manifest)

    water_entries = [
        e for e in (manifest.get("actors") or [])
        if _is_water_volume_class(e.get("className") or "")
    ]
    if water_entries:
        _ensure_water_materials_for_import(report)

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

        # TriggerRadius has no brush OBJ — size from CollisionRadius at the actor location.
        if class_name == "TriggerRadius":
            _import_trigger_radius(entry, spawn_class, existing, report)
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

        if _is_water_volume_class(class_name) and _configure_shock_water_volume(
                actor, half_extent, class_name, report):
            report["volumeSizeMethod"] = report.get("volumeSizeMethod") or {}
            report["volumeSizeMethod"]["shock_water"] = (
                report["volumeSizeMethod"].get("shock_water", 0) + 1)
            report["waterVolumesPlaced"] = report.get("waterVolumesPlaced", 0) + 1
        else:
            sized = _set_volume_half_extent(actor, half_extent)
            report["volumeSizeMethod"] = report.get("volumeSizeMethod") or {}
            report["volumeSizeMethod"][sized] = report["volumeSizeMethod"].get(sized, 0) + 1

        actor.set_actor_label(entry.get("label") or entry.get("name") or key)
        actor.tags = _volume_tags(entry)
        _hide_volume_in_game(actor)
        if class_name in ("TriggerVolume", "TriggerRadius"):
            _ensure_trigger_relay(actor, entry, class_name)
        existing[key] = actor


def _property_float(entry, name, default=0.0):
    """Decode a Float-typed tagged property from an actor entry (little-endian hex)."""
    import struct
    for prop in entry.get("properties") or []:
        if prop.get("name") != name or prop.get("type") != "Float":
            continue
        hx = prop.get("valueHex") or ""
        if len(hx) >= 8:
            try:
                return struct.unpack("<f", bytes.fromhex(hx[:8]))[0]
            except Exception:  # noqa: BLE001
                return default
    return default


def _import_trigger_radius(entry, spawn_class, existing, report):
    """Place a TriggerRadius as TriggerSphere (or TriggerBox fallback) from CollisionRadius."""
    key = entry["key"]
    loc = entry.get("location") or [0, 0, 0]
    center = unreal.Vector(float(loc[0]), float(loc[1]), float(loc[2]))
    radius = max(1.0, float(_property_float(entry, "CollisionRadius", 100.0)))

    actor = existing.get(key)
    if actor is not None and not isinstance(actor, spawn_class):
        _actor_subsystem().destroy_actor(actor)
        actor = None

    if actor is None:
        actor = _actor_subsystem().spawn_actor_from_class(
            spawn_class, center, unreal.Rotator(0, 0, 0))
        if actor is None:
            report["volumesSkipped"] = report.get("volumesSkipped", 0) + 1
            return
        report["created"] += 1
        report["volumesPlaced"] = report.get("volumesPlaced", 0) + 1
    else:
        report["updated"] += 1
        actor.set_actor_location(center, False, False)

    sized = "unscaled"
    for prop in ("collision_component", "root_component"):
        comp = getattr(actor, prop, None)
        if comp is None:
            continue
        setter = getattr(comp, "set_sphere_radius", None)
        if callable(setter):
            try:
                setter(radius, False)
                sized = "sphere_radius"
                break
            except Exception:  # noqa: BLE001
                pass
        setter = getattr(comp, "set_box_extent", None)
        if callable(setter):
            try:
                setter(unreal.Vector(radius, radius, radius), False)
                sized = "box_as_radius"
                break
            except Exception:  # noqa: BLE001
                pass

    report["volumeSizeMethod"] = report.get("volumeSizeMethod") or {}
    report["volumeSizeMethod"][sized] = report["volumeSizeMethod"].get(sized, 0) + 1
    report["triggerRadiiPlaced"] = report.get("triggerRadiiPlaced", 0) + 1

    actor.set_actor_label(entry.get("label") or entry.get("name") or key)
    actor.tags = _volume_tags(entry)
    _hide_volume_in_game(actor)
    _ensure_trigger_relay(actor, entry, "TriggerRadius")
    existing[key] = actor


def _ensure_trigger_relay(actor, entry, class_name="TriggerVolume"):
    """Attach UShockTriggerRelayComponent so player overlap -> enter/exit message (volume label).

    TriggerVolume → MessageTriggerVolumeEnter / MessageTriggerVolumeExit.
    TriggerRadius → MessageTriggerEnter / MessageTriggerExit (Medical PSA* / ghostscreen scripts).

    SCR-G20: wire filter label/class lists from regionActor when present. MaxEnterCount and
    RequireClearTrace are not in the C# regionActor export — only triggerOnlyOnce / disabled /
    triggerOnlyByLabels / triggeredByFilter / triggerOnlyByClasses exist.
    """
    relay_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTriggerRelayComponent")
    if relay_cls is None or actor is None:
        return None
    region = entry.get("regionActor") or {}
    label = entry.get("label") or entry.get("name") or entry.get("key") or ""
    # One-shot is the safe default when the export omits triggerOnlyOnce.
    once = True if "triggerOnlyOnce" not in region else bool(region.get("triggerOnlyOnce"))
    disabled = bool(region.get("disabled") or False)
    if class_name == "TriggerRadius":
        enter_cls = "MessageTriggerEnter"
        exit_cls = "MessageTriggerExit"
    else:
        enter_cls = "MessageTriggerVolumeEnter"
        exit_cls = "MessageTriggerVolumeExit"
    try:
        relay = unreal.ShockTriggerRelayComponent.install_on_actor(
            actor, str(label), once, disabled, enter_cls, exit_cls)
    except Exception:  # noqa: BLE001
        return None
    if relay is None:
        return None

    filter_labels = []
    for name in (region.get("triggerOnlyByLabels") or []):
        if name:
            filter_labels.append(str(name))
    for name in (region.get("triggeredByFilter") or []):
        if name and str(name) not in filter_labels:
            filter_labels.append(str(name))
    filter_classes = []
    for ref in (region.get("triggerOnlyByClasses") or []):
        if not isinstance(ref, dict):
            continue
        cname = ref.get("className") or ref.get("objectName") or ""
        if cname:
            filter_classes.append(str(cname))
    if filter_labels or filter_classes:
        try:
            relay.configure_filters(filter_labels, filter_classes)
        except Exception:  # noqa: BLE001
            pass
    return relay


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
            # Every Medical corpse export comes from UAPW_AggressorBabyJane and therefore calls
            # its FBX object AggressorBabyJane. Without an override each distinct body overwrites
            # the same content package. Corpses do not need the wrapper's 457 combat animations.
            rig_override = None if asset["name"] == "Agg_BabyJane" else asset["name"]
            imported = import_bioshock.main(
                rig_dir,
                content_root=character_content_root,
                rig_name_override=rig_override,
                import_animations=asset["name"] not in _dead_body_mesh_names(manifest))
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
        asset_name = _manifest_asset_names(manifest).get(instance["asset"], "")
        if not _should_place_mesh_instance(actor_class_name, asset_kind, asset_name):
            _remove_owned_mesh(key, existing, report)
            if _is_animated_prop_class(actor_class_name) or _is_fan_mesh_name(asset_name):
                report["animatedPropMeshDeferred"] = report.get("animatedPropMeshDeferred", 0) + 1
            else:
                report["meshInstancesSkipped"] = report.get("meshInstancesSkipped", 0) + 1
            continue

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
            # Same as lights: Movable so PIE/game lighting works without a Lightmass build.
            actor.static_mesh_component.set_editor_property(
                "mobility", unreal.ComponentMobility.MOVABLE)
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


def _decode_float32_hex(value_hex):
    if not value_hex or len(value_hex) < 8:
        return None
    try:
        return struct.unpack("<f", bytes.fromhex(value_hex[:8]))[0]
    except (ValueError, struct.error):
        return None


def _decode_vector_hex(value_hex):
    if not value_hex or len(value_hex) < 24:
        return None
    try:
        return struct.unpack("<fff", bytes.fromhex(value_hex[:24]))
    except (ValueError, struct.error):
        return None


def _decode_rotator_hex(value_hex):
    """Package Rotator (int32 pitch/yaw/roll) → degrees. APPROXIMATED KeyRot decode."""
    if not value_hex or len(value_hex) < 24:
        return None
    try:
        pitch, yaw, roll = struct.unpack("<iii", bytes.fromhex(value_hex[:24]))
    except (ValueError, struct.error):
        return None
    return (
        pitch * ROTATOR_TO_DEGREES,
        yaw * ROTATOR_TO_DEGREES,
        roll * ROTATOR_TO_DEGREES,
    )


def _mover_keyframes_from_properties(entry):
    """Decode KeyPos/KeyRot from raw tagged properties (not typed in the C# mover record).

    Key 0 is implicit rest pose (actor placement). Indices observed start at 1.
    Confidence: CONFIRMED_BYTES for float/int layout; motion path APPROXIMATED until rendered.
    """
    by_index = {}
    move_time = None
    for prop in entry.get("properties") or []:
        name = prop.get("name")
        if name == "MoveTime":
            decoded = _decode_float32_hex(prop.get("valueHex") or "")
            if decoded is not None:
                move_time = decoded
        elif name == "KeyPos":
            vec = _decode_vector_hex(prop.get("valueHex") or "")
            if vec is None:
                continue
            idx = int(prop.get("arrayIndex") or 0)
            slot = by_index.setdefault(idx, {})
            slot["pos"] = vec
        elif name == "KeyRot":
            rot = _decode_rotator_hex(prop.get("valueHex") or "")
            if rot is None:
                continue
            idx = int(prop.get("arrayIndex") or 0)
            slot = by_index.setdefault(idx, {})
            slot["rot"] = rot

    mover = entry.get("mover") or {}
    if move_time is None and mover.get("moveTime") is not None:
        move_time = float(mover["moveTime"])

    keys = []
    for idx in sorted(by_index):
        if idx <= 0:
            continue
        slot = by_index[idx]
        pos = slot.get("pos") or (0.0, 0.0, 0.0)
        rot = slot.get("rot") or (0.0, 0.0, 0.0)
        # KeyPos shares Actor Location's Unreal-native basis (not GameBasis) — use as-is.
        keys.append({
            "location": unreal.Vector(pos[0], pos[1], pos[2]),
            "rotation": unreal.Rotator(pitch=rot[0], yaw=rot[1], roll=rot[2]),
        })
    return keys, (move_time if move_time is not None else 1.0)


# Default fan spin when RotationRate is absent from the export (Medical: StaticMeshActor + fanv2).
_DEFAULT_FAN_REVOLUTIONS_PER_SECOND = 0.75


def _import_animated_props(manifest, meshes, existing, report, handled):
    """Place ScriptableMover / Fan / fan-mesh actors as AShockAnimatedProp."""
    prop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockAnimatedProp")
    if prop_cls is None:
        report["animatedPropsSkipped"] = report.get("animatedPropsSkipped", 0) + 1
        _log("ShockAnimatedProp class missing — animated props not placed")
        return

    instances = _instances_by_actor_key(manifest)
    by_name = {
        asset["name"]: meshes[asset["key"]]
        for asset in manifest.get("assets") or []
        if asset.get("key") in meshes
    }
    asset_names = _manifest_asset_names(manifest)

    for entry in manifest.get("actors") or []:
        class_name = entry.get("className") or ""
        mesh_name = entry.get("staticMesh") or ""
        is_mover = _is_animated_prop_class(class_name)
        is_fan = class_name == "Fan" or _is_fan_mesh_name(mesh_name)
        if not is_mover and not is_fan:
            actor_instances = instances.get(entry["key"]) or []
            for inst in actor_instances:
                if _is_fan_mesh_name(asset_names.get(inst.get("asset"), "")):
                    is_fan = True
                    mesh_name = asset_names.get(inst.get("asset"), mesh_name)
                    break
        if not is_mover and not is_fan:
            continue

        actor_instances = instances.get(entry["key"]) or []
        transform = actor_instances[0].get("transform") if actor_instances else entry.get("transform")
        if transform is not None:
            location, rotation, scale = _decompose(transform)
        else:
            location = unreal.Vector(*(entry.get("location") or [0.0, 0.0, 0.0]))
            rotation = _rotation(entry.get("rotation") or [0, 0, 0])
            scale = unreal.Vector(1.0, 1.0, 1.0)

        for inst in actor_instances:
            old_key = "instance:" + entry["key"] + ":" + inst["asset"]
            old = existing.get(old_key)
            if old is not None:
                _actor_subsystem().destroy_actor(old)
                existing.pop(old_key, None)

        label = entry.get("label") or entry.get("name") or entry["key"]
        akey = "aprop:" + entry["key"]
        actor = existing.get(akey)
        if actor is not None:
            actor_cls = actor.get_class()
            if actor_cls != prop_cls and not unreal.MathLibrary.class_is_child_of(actor_cls, prop_cls):
                _actor_subsystem().destroy_actor(actor)
                actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(prop_cls, location, rotation)
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1
            actor.set_actor_location(location, False, False)
            actor.set_actor_rotation(rotation, False)

        actor.set_actor_scale3d(scale)
        actor.set_actor_label(label)
        actor.tags = [
            unreal.Name(KEY_TAG_PREFIX + akey),
            unreal.Name("BioShockClass=" + class_name),
            unreal.Name("BioShockLabel=" + str(label)),
        ]

        mesh = by_name.get(mesh_name)
        if mesh is None and actor_instances:
            mesh = meshes.get(actor_instances[0].get("asset"))
        mesh_comp = actor.get_editor_property("prop_mesh")
        if mesh is not None and mesh_comp is not None:
            mesh_comp.set_static_mesh(mesh)
            mesh_comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
            mesh_comp.set_relative_scale3d(unreal.Vector(1.0, 1.0, 1.0))

        # Movers with a mover record use keyframes; pure fans spin continuously.
        use_keyframes = bool(entry.get("mover")) or (is_mover and class_name != "Fan")
        if use_keyframes and not (class_name == "Fan"):
            keys, move_time = _mover_keyframes_from_properties(entry)
            relative_keys = []
            for key in keys:
                relative_keys.append(unreal.Transform(
                    key["location"],
                    key["rotation"],
                    unreal.Vector(1.0, 1.0, 1.0)))
            # TriggerToggle → one-shot; script PlayAnimation toggles direction.
            loop_mode = 0  # EShockPropLoopMode::OneShot
            if hasattr(unreal, "ShockPropLoopMode"):
                loop_mode = unreal.ShockPropLoopMode.ONE_SHOT
            if hasattr(actor, "configure_keyframe_motion"):
                actor.configure_keyframe_motion(
                    unreal.Name(label), relative_keys, float(move_time), loop_mode)
            # SCR-G01: ScriptableMover TriggeredBy + StayOpenTime / TriggerOnceOnly / InitialState.
            mover = entry.get("mover") or {}
            triggered_by = mover.get("triggeredBy")
            if triggered_by is None:
                for prop in entry.get("properties") or []:
                    if prop.get("name") == "TriggeredBy" and prop.get("type") == "Str":
                        # Same UTF-16LE decode as import_scripts TriggeredBy.
                        hx = prop.get("valueHex") or ""
                        try:
                            raw = bytes.fromhex(hx)
                            if raw:
                                count = raw[0]
                                triggered_by = raw[1:1 + count * 2].decode(
                                    "utf-16-le", errors="replace")
                        except Exception:  # noqa: BLE001
                            triggered_by = None
                        break
            if triggered_by and hasattr(actor, "set_triggered_by"):
                actor.set_triggered_by(str(triggered_by))
            if mover.get("triggerOnceOnly") is True:
                try:
                    actor.set_editor_property("b_trigger_once_only", True)
                except Exception:  # noqa: BLE001
                    pass
            if mover.get("stayOpenTime") is not None:
                try:
                    actor.set_editor_property("stay_open_time", float(mover["stayOpenTime"]))
                except Exception:  # noqa: BLE001
                    pass
            if mover.get("initialState"):
                try:
                    actor.set_editor_property(
                        "initial_state", unreal.Name(str(mover["initialState"])))
                except Exception:  # noqa: BLE001
                    pass
            report["scriptableMoversPlaced"] = report.get("scriptableMoversPlaced", 0) + 1
        else:
            if hasattr(actor, "configure_continuous_spin"):
                actor.configure_continuous_spin(
                    unreal.Name(label),
                    unreal.Vector(1.0, 0.0, 0.0),
                    _DEFAULT_FAN_REVOLUTIONS_PER_SECOND,
                    True)
            report["fansPlaced"] = report.get("fansPlaced", 0) + 1
            report["fanDefaultSpinUsed"] = report.get("fanDefaultSpinUsed", 0) + 1

        existing[akey] = actor
        handled.add(akey)
        handled.add(entry["key"])
        report["animatedPropsPlaced"] = report.get("animatedPropsPlaced", 0) + 1


def _property_present(entry, name):
    for prop in entry.get("properties") or []:
        if prop.get("name") == name:
            return True
    return False


def _import_turret_spawners(manifest, existing, report, handled):
    """Place hostile AShockTurret at TurretSpawner markers (unless ForScriptedSpawn)."""
    turret_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTurret")
    if turret_cls is None:
        _log("ShockTurret class missing — turret spawners not placed")
        return

    for entry in manifest.get("actors") or []:
        if entry.get("className") != "TurretSpawner":
            continue

        key = entry["key"]
        if key in handled:
            continue

        label = entry.get("label") or entry.get("name") or key
        # ForScriptedSpawn present → keep TargetPoint path for ActionSpawnTurret.
        if _property_present(entry, "ForScriptedSpawn"):
            report["turretSpawnersScriptOnly"] = report.get("turretSpawnersScriptOnly", 0) + 1
            continue

        location = unreal.Vector(*(entry.get("location") or [0.0, 0.0, 0.0]))
        rotation = _rotation(entry.get("rotation") or [0, 0, 0])
        tkey = "turret:" + key
        actor = existing.get(tkey)
        if actor is not None:
            actor_cls = actor.get_class()
            if actor_cls != turret_cls and not unreal.MathLibrary.class_is_child_of(
                    actor_cls, turret_cls):
                _actor_subsystem().destroy_actor(actor)
                actor = None

        if actor is None:
            actor = _actor_subsystem().spawn_actor_from_class(turret_cls, location, rotation)
            if actor is None:
                report["skipped"] += 1
                continue
            report["created"] += 1
        else:
            report["updated"] += 1
            actor.set_actor_location(location, False, False)
            actor.set_actor_rotation(rotation, False)

        actor.set_actor_label(label)
        actor.tags = [
            unreal.Name(KEY_TAG_PREFIX + tkey),
            unreal.Name("BioShockClass=TurretSpawner"),
        ]
        if hasattr(actor, "configure_for_verify"):
            actor.configure_for_verify(unreal.Name(label), 1, 40.0)
        elif hasattr(actor, "set_device_label"):
            actor.set_device_label(unreal.Name(label))

        existing[tkey] = actor
        handled.add(tkey)
        handled.add(key)
        report["turretsPlaced"] = report.get("turretsPlaced", 0) + 1


def _import_door_attachments(
        manifest, meshes, existing, report, handled, skeletal_meshes=None):
    """Spawn AShockDoor for each door actor and reproduce its source visual shape.

    Source MedicalDoors attach rigid static leaves to an animation-proxy skeleton. When that
    proxy rig was imported, leaves become components attached to its named sockets. If the rig
    is unavailable, retain the static-slide fallback rather than drawing the proxy itself.
    """
    skeletal_meshes = skeletal_meshes or {}
    door_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockDoor")
    instances = _instances_by_actor_key(manifest)
    by_name = {
        asset["name"]: meshes[asset["key"]]
        for asset in manifest.get("assets") or []
        if asset.get("key") in meshes
    }

    def components(value):
        if value is None:
            return 0.0, 0.0, 0.0
        if isinstance(value, dict):
            return value.get("x", 0.0), value.get("y", 0.0), value.get("z", 0.0)
        return value[0], value[1], value[2]

    for entry in manifest.get("actors") or []:
        door_data = entry.get("door")
        if not door_data:
            continue

        attachments = door_data.get("attachments") or []
        actor_instances = instances.get(entry["key"]) or []
        transform = actor_instances[0].get("transform") if actor_instances else entry.get("transform")
        if transform is None:
            report["doorAttachmentsSkipped"] = report.get("doorAttachmentsSkipped", 0) + 1
            continue

        location, rotation, scale = _decompose(transform)
        door_label = entry.get("label") or entry.get("name") or entry["key"]
        dkey = "door:" + entry["key"]
        actor = existing.get(dkey)
        proxy_ref = entry.get("skeletalMeshReference") or {}
        proxy_mesh = skeletal_meshes.get(proxy_ref.get("sourceKey"))

        # The source mesh instance is the animation proxy, not a second visible door. Remove
        # only this actor's exact owned instance and reserve its key before generic placement.
        for instance in actor_instances:
            instance_key = "instance:" + entry["key"] + ":" + instance["asset"]
            old_instance = existing.get(instance_key)
            if old_instance is not None:
                _actor_subsystem().destroy_actor(old_instance)
                existing.pop(instance_key, None)
                report["removed"] = report.get("removed", 0) + 1
            handled.add(instance_key)

        if door_cls is not None:
            if actor is not None:
                actor_cls = actor.get_class()
                if actor_cls != door_cls and not unreal.MathLibrary.class_is_child_of(
                        actor_cls, door_cls):
                    _actor_subsystem().destroy_actor(actor)
                    actor = None

            if actor is None:
                actor = _actor_subsystem().spawn_actor_from_class(
                    door_cls, location, rotation)
                if actor is None:
                    report["skipped"] += 1
                else:
                    report["created"] += 1
            else:
                report["updated"] += 1
                actor.set_actor_location(location, False, False)
                actor.set_actor_rotation(rotation, False)

            if actor is not None:
                actor.set_actor_scale3d(scale)
                actor.set_actor_label(door_label)
                actor.tags = [
                    unreal.Name(KEY_TAG_PREFIX + dkey),
                    unreal.Name("BioShockLabel=" + str(door_label)),
                ]
                if hasattr(actor, "set_door_label"):
                    actor.set_door_label(unreal.Name(door_label))
                locked = bool(door_data.get("locked") or False)
                initially_open = bool(door_data.get("initiallyOpen") or False)
                if hasattr(actor, "configure_for_verify"):
                    actor.configure_for_verify(unreal.Name(door_label), locked, initially_open)
                else:
                    if hasattr(actor, "set_locked"):
                        actor.set_locked(locked)

                if proxy_mesh is not None and hasattr(actor, "configure_skeletal_door"):
                    actor.configure_skeletal_door(proxy_mesh, False)
                    if hasattr(actor, "clear_door_leaves"):
                        actor.clear_door_leaves()
                    for att in attachments:
                        static_mesh = att.get("staticMesh")
                        object_name = (
                            static_mesh.get("objectName")
                            if isinstance(static_mesh, dict) else None)
                        leaf_mesh = by_name.get(object_name)
                        if leaf_mesh is None:
                            report["doorAttachmentsSkipped"] = (
                                report.get("doorAttachmentsSkipped", 0) + 1)
                            continue
                        lx, ly, lz = components(att.get("attachLocationOffset"))
                        pitch, yaw, roll = components(att.get("attachRotationOffset"))
                        added = actor.add_door_leaf(
                            leaf_mesh,
                            unreal.Name(att.get("attachSocket") or ""),
                            unreal.Vector(lx, ly, lz),
                            unreal.Rotator(
                                pitch=pitch * ROTATOR_TO_DEGREES,
                                yaw=yaw * ROTATOR_TO_DEGREES,
                                roll=roll * ROTATOR_TO_DEGREES),
                            bool(att.get("interactWithPhysicalObjects") or False))
                        if added:
                            report["doorAttachmentsPlaced"] = (
                                report.get("doorAttachmentsPlaced", 0) + 1)
                    attachments = []

                first_mesh = None
                if attachments:
                    static_mesh = attachments[0].get("staticMesh")
                    object_name = (
                        static_mesh.get("objectName") if isinstance(static_mesh, dict) else None)
                    first_mesh = by_name.get(object_name)
                    # Drop the pre-AShockDoor StaticMeshActor leaf if a prior import left one.
                    socket0 = attachments[0].get("attachSocket") or ""
                    if object_name:
                        old_leaf_key = "door:%s:%s:%s" % (entry["key"], socket0, object_name)
                        old_leaf = existing.get(old_leaf_key)
                        if old_leaf is not None:
                            _actor_subsystem().destroy_actor(old_leaf)
                            existing.pop(old_leaf_key, None)
                if first_mesh is not None:
                    mesh_comp = actor.get_editor_property("door_mesh")
                    if mesh_comp is not None:
                        mesh_comp.set_static_mesh(first_mesh)
                        mesh_comp.set_editor_property(
                            "mobility", unreal.ComponentMobility.MOVABLE)
                        # Drop the cube stand-in scale once a real leaf mesh is assigned.
                        mesh_comp.set_relative_scale3d(unreal.Vector(1.0, 1.0, 1.0))

                existing[dkey] = actor
                handled.add(dkey)
                report["doorsPlaced"] = report.get("doorsPlaced", 0) + 1
                # First attachment consumed by AShockDoor; place any further leaves as props.
                attachments = attachments[1:]
        elif not attachments:
            report["doorAttachmentsSkipped"] = report.get("doorAttachmentsSkipped", 0) + 1
            continue

        for att in attachments:
            static_mesh = att.get("staticMesh")
            object_name = static_mesh.get("objectName") if isinstance(static_mesh, dict) else None
            mesh = by_name.get(object_name)
            if mesh is None:
                report["doorAttachmentsSkipped"] = report.get("doorAttachmentsSkipped", 0) + 1
                continue

            lx, ly, lz = components(att.get("attachLocationOffset"))
            pitch, yaw, roll = components(att.get("attachRotationOffset"))
            attachment_location = unreal.Vector(
                location.x + lx, location.y + ly, location.z + lz)
            attachment_rotation = unreal.Rotator(
                pitch=rotation.pitch + pitch * ROTATOR_TO_DEGREES,
                yaw=rotation.yaw + yaw * ROTATOR_TO_DEGREES,
                roll=rotation.roll + roll * ROTATOR_TO_DEGREES)

            socket = att.get("attachSocket") or ""
            leaf_key = "door:" + entry["key"] + ":" + socket + ":" + object_name
            leaf = existing.get(leaf_key)
            if leaf is not None and not isinstance(leaf, unreal.StaticMeshActor):
                _actor_subsystem().destroy_actor(leaf)
                leaf = None

            if leaf is None:
                leaf = _actor_subsystem().spawn_actor_from_class(
                    unreal.StaticMeshActor, attachment_location, attachment_rotation)
                if leaf is None:
                    report["skipped"] += 1
                    continue
                report["created"] += 1
            else:
                report["updated"] += 1
                leaf.set_actor_location(attachment_location, False, False)
                leaf.set_actor_rotation(attachment_rotation, False)

            leaf.static_mesh_component.set_static_mesh(mesh)
            leaf.static_mesh_component.set_editor_property(
                "mobility", unreal.ComponentMobility.MOVABLE)
            # Visual-only second leaf — interactive collision lives on AShockDoor.
            leaf.static_mesh_component.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
            leaf.set_actor_scale3d(scale)
            leaf.set_actor_label(door_label + ":" + socket)
            leaf.tags = [unreal.Name(KEY_TAG_PREFIX + leaf_key)]
            existing[leaf_key] = leaf
            handled.add(leaf_key)
            report["doorAttachmentsPlaced"] = report.get("doorAttachmentsPlaced", 0) + 1


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
    _import_vita_chambers(manifest, meshes, existing, report, handled)
    _import_door_attachments(
        manifest, meshes, existing, report, handled, skeletal_meshes=skeletal_meshes)
    _import_instances(manifest, meshes, skeletal_meshes, existing, report, handled)
    _import_animated_props(manifest, meshes, existing, report, handled)
    _import_turret_spawners(manifest, existing, report, handled)
    _import_region_volumes(manifest, manifest_dir, existing, report, handled)

    if import_actors:
        _import_actors(manifest, existing, report, handled)

    _log("import report: %d created, %d updated, %d skipped, %d unsupported, "
         "%d mesh instance(s) not drawn, %d volume(s) placed, %d volume(s) skipped, "
         "%d ShockDoor(s) placed, %d door attachment(s) placed, %d door attachment(s) skipped, "
         "%d animated prop(s) placed (%d mover, %d fan), %d turret(s) placed, "
         "%d mesh(es) with a material assigned, %d material slot(s) resolved"
         % (report["created"], report["updated"], report["skipped"], report["unsupported"],
            report.get("meshInstancesSkipped", 0), report.get("volumesPlaced", 0),
            report.get("volumesSkipped", 0), report.get("doorsPlaced", 0),
            report.get("doorAttachmentsPlaced", 0),
            report.get("doorAttachmentsSkipped", 0),
            report.get("animatedPropsPlaced", 0),
            report.get("scriptableMoversPlaced", 0),
            report.get("fansPlaced", 0),
            report.get("turretsPlaced", 0),
            report.get("materialsAssigned", 0),
            report.get("materialSlotsResolved", 0)))

    main.last_report = report
    return report
