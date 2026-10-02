"""Author the additive LightBeamShader graph and assign it to Medical's beam instances.

Uses the shipped FalloffMap and DustMap. Actor-specific LightBeamShader overrides select tint;
the common dust texture pans at the decoded 0.7/0.2 direction. A depth fade softens intersections.

Env:
  BIOSHOCK_BEAM_MANIFEST     1-Medical.ue5-level.json (required)
  BIOSHOCK_BEAM_MAP          map to repair (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_BEAM_CONTENT_ROOT imported content root (default /Game/BioShockLevel)
  BIOSHOCK_BEAM_DRY          "1" to report only
"""
from __future__ import annotations

import json
import os

import unreal

MANIFEST = os.environ.get("BIOSHOCK_BEAM_MANIFEST", "")
MAP_PATH = os.environ.get("BIOSHOCK_BEAM_MAP", "/Game/BioShockSlice/1-Medical")
CONTENT_ROOT = os.environ.get("BIOSHOCK_BEAM_CONTENT_ROOT", "/Game/BioShockLevel")
DRY = os.environ.get("BIOSHOCK_BEAM_DRY", "0") == "1"
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_light_beams.json")
KEY_TAG_PREFIX = "BioShockKey="


def _safe_name(value):
    return "".join(ch if ch.isalnum() or ch == "_" else "_" for ch in value)


def _load_texture(destination, stem):
    for path in (
        "%s/Textures/%s" % (destination, stem),
        "%s/Textures/%s" % (CONTENT_ROOT, stem),
    ):
        texture = unreal.EditorAssetLibrary.load_asset(path)
        if isinstance(texture, unreal.Texture):
            return texture, path
    return None, None


def _create_expression(edit, material, cls, x, y):
    node = edit.create_material_expression(material, cls, x, y)
    if node is None:
        raise RuntimeError("could not create %s" % cls)
    return node


def _author_master(destination, falloff, dust):
    path = "%s/Materials/Masters/M_BioShock_LightBeam_Repaired_V1" % destination
    material = unreal.EditorAssetLibrary.load_asset(path)
    if material is None:
        folder, asset_name = path.rsplit("/", 1)
        material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            asset_name, folder, unreal.Material, unreal.MaterialFactoryNew())
    if not isinstance(material, unreal.Material):
        raise RuntimeError("could not create beam master")

    edit = unreal.MaterialEditingLibrary
    edit.delete_all_material_expressions(material)
    material.set_editor_property("blend_mode", unreal.BlendMode.BLEND_ADDITIVE)
    material.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    material.set_editor_property("two_sided", True)

    uv = _create_expression(edit, material, unreal.MaterialExpressionTextureCoordinate, -900, 0)
    falloff_node = _create_expression(
        edit, material, unreal.MaterialExpressionTextureSampleParameter2D, -700, -180)
    falloff_node.set_editor_property("parameter_name", "FalloffMap")
    falloff_node.set_editor_property("texture", falloff)
    edit.connect_material_expressions(uv, "", falloff_node, "UVs")

    time_node = _create_expression(edit, material, unreal.MaterialExpressionTime, -900, 230)
    speed = _create_expression(edit, material, unreal.MaterialExpressionScalarParameter, -900, 320)
    speed.set_editor_property("parameter_name", "DustPanSpeed")
    speed.set_editor_property("default_value", 0.10)
    time_x = _create_expression(edit, material, unreal.MaterialExpressionMultiply, -700, 230)
    edit.connect_material_expressions(time_node, "", time_x, "A")
    edit.connect_material_expressions(speed, "", time_x, "B")
    ratio = _create_expression(edit, material, unreal.MaterialExpressionConstant, -700, 360)
    ratio.set_editor_property("r", 0.285714)
    time_y = _create_expression(edit, material, unreal.MaterialExpressionMultiply, -510, 310)
    edit.connect_material_expressions(time_x, "", time_y, "A")
    edit.connect_material_expressions(ratio, "", time_y, "B")
    pan = _create_expression(edit, material, unreal.MaterialExpressionAppendVector, -330, 260)
    edit.connect_material_expressions(time_x, "", pan, "A")
    edit.connect_material_expressions(time_y, "", pan, "B")
    dust_uv = _create_expression(edit, material, unreal.MaterialExpressionAdd, -150, 210)
    edit.connect_material_expressions(uv, "", dust_uv, "A")
    edit.connect_material_expressions(pan, "", dust_uv, "B")
    dust_node = _create_expression(
        edit, material, unreal.MaterialExpressionTextureSampleParameter2D, 20, 170)
    dust_node.set_editor_property("parameter_name", "DustMap")
    dust_node.set_editor_property("texture", dust)
    edit.connect_material_expressions(dust_uv, "", dust_node, "UVs")

    dust_weight = _create_expression(edit, material, unreal.MaterialExpressionConstant, 210, 250)
    dust_weight.set_editor_property("r", 0.35)
    weighted_dust = _create_expression(
        edit, material, unreal.MaterialExpressionMultiply, 390, 220)
    edit.connect_material_expressions(dust_node, "RGB", weighted_dust, "A")
    edit.connect_material_expressions(dust_weight, "", weighted_dust, "B")
    base_transmission = _create_expression(
        edit, material, unreal.MaterialExpressionConstant, 390, 320)
    base_transmission.set_editor_property("r", 0.65)
    dust_modulation = _create_expression(edit, material, unreal.MaterialExpressionAdd, 570, 240)
    edit.connect_material_expressions(weighted_dust, "", dust_modulation, "A")
    edit.connect_material_expressions(base_transmission, "", dust_modulation, "B")
    beam = _create_expression(edit, material, unreal.MaterialExpressionMultiply, 220, -80)
    edit.connect_material_expressions(falloff_node, "RGB", beam, "A")
    edit.connect_material_expressions(dust_modulation, "", beam, "B")
    tint = _create_expression(edit, material, unreal.MaterialExpressionVectorParameter, 20, -180)
    tint.set_editor_property("parameter_name", "BeamTint")
    tint.set_editor_property("default_value", unreal.LinearColor(1.0, 0.72, 0.35, 1.0))
    tinted = _create_expression(edit, material, unreal.MaterialExpressionMultiply, 410, -80)
    edit.connect_material_expressions(beam, "", tinted, "A")
    edit.connect_material_expressions(tint, "", tinted, "B")
    intensity = _create_expression(edit, material, unreal.MaterialExpressionScalarParameter, 220, -220)
    intensity.set_editor_property("parameter_name", "BeamIntensity")
    intensity.set_editor_property("default_value", 0.8)
    bright = _create_expression(edit, material, unreal.MaterialExpressionMultiply, 600, -80)
    edit.connect_material_expressions(tinted, "", bright, "A")
    edit.connect_material_expressions(intensity, "", bright, "B")
    depth = _create_expression(edit, material, unreal.MaterialExpressionDepthFade, 410, 120)
    depth.set_editor_property("fade_distance_default", 120.0)
    # Fade a beam surface out as it nears the camera. Medical's beams are open two-sided tubes
    # (Light_Beams at drawScale 0.5 is ~250 cm wide) and the loadroom puts the player inside one,
    # so without this a face centimetres from the eye drew over the whole view, viewmodel
    # included. PLAUSIBLE stand-in: the original LightBeamShader's own near-view behaviour isn't
    # decoded; 40 uu fully hidden, fading in over the next 200 uu. Built from PixelDepth because
    # MaterialExpressionCameraDepthFade isn't exposed to Python: saturate((depth - 40) / 200).
    pixel_depth = _create_expression(edit, material, unreal.MaterialExpressionPixelDepth, 0, 420)
    near_offset = _create_expression(edit, material, unreal.MaterialExpressionConstant, 0, 500)
    near_offset.set_editor_property("r", 40.0)
    near_length = _create_expression(edit, material, unreal.MaterialExpressionConstant, 0, 580)
    near_length.set_editor_property("r", 200.0)
    past_offset = _create_expression(edit, material, unreal.MaterialExpressionSubtract, 210, 440)
    edit.connect_material_expressions(pixel_depth, "", past_offset, "A")
    edit.connect_material_expressions(near_offset, "", past_offset, "B")
    ramp = _create_expression(edit, material, unreal.MaterialExpressionDivide, 390, 460)
    edit.connect_material_expressions(past_offset, "", ramp, "A")
    edit.connect_material_expressions(near_length, "", ramp, "B")
    near = _create_expression(edit, material, unreal.MaterialExpressionSaturate, 570, 460)
    edit.connect_material_expressions(ramp, "", near, "")
    fade = _create_expression(edit, material, unreal.MaterialExpressionMultiply, 600, 200)
    edit.connect_material_expressions(depth, "", fade, "A")
    edit.connect_material_expressions(near, "", fade, "B")
    softened = _create_expression(edit, material, unreal.MaterialExpressionMultiply, 790, -60)
    edit.connect_material_expressions(bright, "", softened, "A")
    edit.connect_material_expressions(fade, "", softened, "B")
    opacity = _create_expression(edit, material, unreal.MaterialExpressionMultiply, 790, 100)
    edit.connect_material_expressions(falloff_node, "R", opacity, "A")
    edit.connect_material_expressions(fade, "", opacity, "B")
    edit.connect_material_property(softened, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    edit.connect_material_property(opacity, "", unreal.MaterialProperty.MP_OPACITY)
    edit.recompile_material(material)
    unreal.EditorAssetLibrary.save_loaded_asset(material)
    return material, path


def _tint(name):
    lower = name.lower()
    if "orange" in lower:
        return unreal.LinearColor(1.0, 0.28, 0.06, 1.0)
    if "yellow" in lower or "science" in lower:
        return unreal.LinearColor(1.0, 0.78, 0.22, 1.0)
    return unreal.LinearColor(1.0, 0.62, 0.28, 1.0)


def _instance(destination, master, name, falloff, dust):
    path = "%s/Materials/MI_%s" % (destination, _safe_name(name))
    instance = unreal.EditorAssetLibrary.load_asset(path)
    if instance is None:
        folder, asset_name = path.rsplit("/", 1)
        instance = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            asset_name, folder,
            unreal.MaterialInstanceConstant, unreal.MaterialInstanceConstantFactoryNew())
    if not isinstance(instance, unreal.MaterialInstanceConstant):
        raise RuntimeError("could not create %s" % path)
    instance.set_editor_property("parent", master)
    edit = unreal.MaterialEditingLibrary
    edit.set_material_instance_texture_parameter_value(instance, "FalloffMap", falloff)
    edit.set_material_instance_texture_parameter_value(instance, "DustMap", dust)
    edit.set_material_instance_vector_parameter_value(instance, "BeamTint", _tint(name))
    edit.set_material_instance_scalar_parameter_value(instance, "BeamIntensity", 0.8)
    unreal.EditorAssetLibrary.save_loaded_asset(instance)
    return instance, path


def main():
    manifest_path = MANIFEST or os.path.join(
        os.path.dirname(unreal.Paths.get_project_file_path()),
        "Exports", "slice", "1-Medical", "1-Medical.ue5-level.json")
    if not os.path.isfile(manifest_path):
        raise RuntimeError("BIOSHOCK_BEAM_MANIFEST is required")
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    destination = "%s/%s" % (CONTENT_ROOT, manifest.get("package") or "Level")
    falloff, falloff_path = _load_texture(destination, "Light_beam_LowFalloff")
    dust, dust_path = _load_texture(destination, "LightDust_Dif")
    if falloff is None or dust is None:
        raise RuntimeError("beam textures missing: falloff=%s dust=%s" % (falloff_path, dust_path))

    actor_records = {entry.get("key"): entry for entry in manifest.get("actors") or []}
    beam_assets = {
        entry.get("key") for entry in manifest.get("assets") or []
        if "light_beam" in (entry.get("name") or "").lower()
    }
    actor_beams = {}
    for instance in manifest.get("instances") or []:
        if instance.get("asset") not in beam_assets:
            continue
        source = actor_records.get(instance.get("actorKey")) or {}
        override = next((
            value.get("objectName") for value in source.get("materialOverrides") or []
            if value.get("className") == "LightBeamShader"), None)
        actor_beams[instance.get("actorKey")] = override or "Light_Beam_01"

    report = {
        "dryRun": DRY, "map": MAP_PATH, "falloff": falloff_path, "dust": dust_path,
        "beamActorsInManifest": len(actor_beams), "assigned": [], "failures": [],
    }
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(MAP_PATH):
        raise RuntimeError("could not load %s" % MAP_PATH)
    if DRY:
        report["wouldAssign"] = actor_beams
    else:
        master, report["master"] = _author_master(destination, falloff, dust)
        materials = {}
        for name in set(actor_beams.values()):
            materials[name] = _instance(destination, master, name, falloff, dust)
        for actor in unreal.get_editor_subsystem(
                unreal.EditorActorSubsystem).get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            source_key = None
            for tag in actor.tags:
                text = str(tag)
                if text.startswith(KEY_TAG_PREFIX + "instance:"):
                    parts = text[len(KEY_TAG_PREFIX + "instance:"):].split(":", 1)
                    source_key = parts[0] if parts else None
                    break
            name = actor_beams.get(source_key)
            if not name:
                continue
            material, path = materials[name]
            actor.modify()
            actor.static_mesh_component.modify()
            actor.static_mesh_component.set_material(0, material)
            assigned = actor.static_mesh_component.get_material(0)
            if assigned is None or assigned.get_path_name() != material.get_path_name():
                report["failures"].append("%s material did not persist" % actor.get_actor_label())
            report["assigned"].append({
                "actor": actor.get_actor_label(), "source": source_key,
                "beamMaterial": name, "material": path,
            })
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"]:
        raise RuntimeError("light beams:\n- " + "\n- ".join(report["failures"]))
    unreal.log("[light-beams] wrote %s" % OUT)
    return report


if __name__ == "__main__":
    main()
