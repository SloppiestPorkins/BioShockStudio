"""Author the shared water master and decoded Medical FluidShader instances.

M_ShockWater has two independently-panned diffuse samples and two independently-panned
normal samples. Medical's FluidShader material instances bind their own decoded textures
and raw UPan/VPan values to those parameters. The generic water-volume plane keeps using
the master's fallback look because the exported volume brushes carry no material link.

Idempotent: an old one-ripple M_ShockWater is upgraded in place, preserving references.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/author_water_material.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_ACTION_OUT (JSON report path; default %TEMP%/author_water_material.json)
"""

from __future__ import annotations

import json
import os
import struct
import zlib

import unreal

CONTENT_FOLDER = "/Game/BioShock/Water"
MASTER_NAME = "M_ShockWater"
CASCADING_MI_NAME = "MI_ShockWater_Cascading"
NORMAL_NAME = "T_ShockWater_Normal"

_TEXTURE_PARAMETERS = {
    "WaterDiffuse1", "WaterDiffuse2", "WaterNormal1", "WaterNormal2",
}
_SCALAR_PARAMETERS = {
    "PanSpeed",
    "DiffusePan1U", "DiffusePan1V", "DiffusePan2U", "DiffusePan2V",
    "NormalPan1U", "NormalPan1V", "NormalPan2U", "NormalPan2V",
}
_ANIMATOR_PARAMETERS = {
    "DiffuseTextureAnimator1": "DiffusePan1",
    "DiffuseTextureAnimator2": "DiffusePan2",
    "NormalTextureAnimator1": "NormalPan1",
    "NormalTextureAnimator2": "NormalPan2",
}


def _log(message):
    unreal.log("[bioshock-water] %s" % message)


def _write_report(report):
    out = os.environ.get(
        "BIOSHOCK_ACTION_OUT",
        os.path.join(os.environ.get("TEMP", "."), "author_water_material.json"),
    )
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    return out


def _png_rgba(width, height, pixels_rgba):
    """Minimal PNG writer (no Pillow dependency)."""

    def chunk(tag, data):
        return (
            struct.pack(">I", len(data)) + tag + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    raw = b""
    stride = width * 4
    for y in range(height):
        raw += b"\x00" + pixels_rgba[y * stride : (y + 1) * stride]
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"".join([
        b"\x89PNG\r\n\x1a\n",
        chunk(b"IHDR", ihdr),
        chunk(b"IDAT", zlib.compress(raw, 9)),
        chunk(b"IEND", b""),
    ])


def _ensure_ripple_normal(report):
    """Return the generic fallback normal, staging the optional procedural PNG."""
    path = "%s/%s" % (CONTENT_FOLDER, NORMAL_NAME)
    if unreal.EditorAssetLibrary.does_asset_exist(path):
        report.setdefault("assets", {})[NORMAL_NAME] = path
        return unreal.EditorAssetLibrary.load_asset(path)

    # Fresh procedural-PNG imports trip Interchange/Slate asserts under pythonscript. Stage the
    # file in TEMP for an optional later editor import and use the engine flat normal headlessly.
    try:
        import math

        size = 256
        pixels = bytearray(size * size * 4)
        for y in range(size):
            for x in range(size):
                u = x / float(size)
                v = y / float(size)
                dx = 0.35 * math.sin(u * math.pi * 8.0) * math.cos(v * math.pi * 3.0)
                dy = 0.35 * math.sin(v * math.pi * 8.0) * math.cos(u * math.pi * 3.0)
                i = (y * size + x) * 4
                pixels[i] = max(0, min(255, int((dx * 0.5 + 0.5) * 255)))
                pixels[i + 1] = max(0, min(255, int((dy * 0.5 + 0.5) * 255)))
                pixels[i + 2] = 255
                pixels[i + 3] = 255
        staging = os.path.join(os.environ.get("TEMP", "."), "bioshock-water")
        os.makedirs(staging, exist_ok=True)
        png_path = os.path.join(staging, "%s.png" % NORMAL_NAME)
        with open(png_path, "wb") as handle:
            handle.write(_png_rgba(size, size, bytes(pixels)))
        report["normalStagingPng"] = png_path.replace("\\", "/")
    except Exception as exc:  # noqa: BLE001
        _log("could not stage normal PNG (%s)" % exc)

    fallback = unreal.load_asset("/Engine/EngineMaterials/DefaultNormal")
    report["normalFallback"] = "/Engine/EngineMaterials/DefaultNormal"
    return fallback


def _white_texture():
    for path in (
        "/Engine/EngineResources/WhiteSquareTexture",
        "/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture",
    ):
        texture = unreal.load_asset(path)
        if texture is not None:
            return texture
    return None


def _create(edit, mat, expression_class, x, y):
    node = edit.create_material_expression(mat, expression_class, x, y)
    if node is None:
        raise RuntimeError("could not create %s" % expression_class)
    return node


def _scalar(edit, mat, name, default, x, y):
    node = _create(edit, mat, unreal.MaterialExpressionScalarParameter, x, y)
    node.set_editor_property("parameter_name", name)
    node.set_editor_property("default_value", float(default))
    return node


def _panned_sample(edit, mat, texcoord, time_node, pan_speed, texture, texture_name,
                   parameter_prefix, default_u, default_v, y, normal=False):
    """Build TextureCoordinate + Time * (UPan, VPan) * PanSpeed for one layer.

    PanTime is exposed as a parameter but deliberately not connected. Its units/role are still
    UNKNOWN, so using it as a divisor or period would turn an unverified guess into rendering.
    """
    pan_u = _scalar(edit, mat, parameter_prefix + "U", default_u, -1160, y)
    pan_v = _scalar(edit, mat, parameter_prefix + "V", default_v, -1160, y + 55)
    _scalar(edit, mat, parameter_prefix + "Duration", 0.0, -1160, y + 110)

    vector = _create(edit, mat, unreal.MaterialExpressionAppendVector, -940, y + 20)
    edit.connect_material_expressions(pan_u, "", vector, "A")
    edit.connect_material_expressions(pan_v, "", vector, "B")
    timed = _create(edit, mat, unreal.MaterialExpressionMultiply, -760, y + 20)
    edit.connect_material_expressions(vector, "", timed, "A")
    edit.connect_material_expressions(time_node, "", timed, "B")
    scaled = _create(edit, mat, unreal.MaterialExpressionMultiply, -580, y + 20)
    edit.connect_material_expressions(timed, "", scaled, "A")
    edit.connect_material_expressions(pan_speed, "", scaled, "B")
    uv = _create(edit, mat, unreal.MaterialExpressionAdd, -400, y + 20)
    edit.connect_material_expressions(texcoord, "", uv, "A")
    edit.connect_material_expressions(scaled, "", uv, "B")

    sample = _create(
        edit, mat, unreal.MaterialExpressionTextureSampleParameter2D, -200, y)
    sample.set_editor_property("parameter_name", texture_name)
    if texture is not None:
        sample.set_editor_property("texture", texture)
    if normal:
        sample.set_editor_property(
            "sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL)
    edit.connect_material_expressions(uv, "", sample, "UVs")
    return sample


def _graph_is_current(mat):
    edit = unreal.MaterialEditingLibrary
    try:
        textures = {str(name) for name in (edit.get_texture_parameter_names(mat) or [])}
        scalars = {str(name) for name in (edit.get_scalar_parameter_names(mat) or [])}
    except Exception:  # noqa: BLE001 - unreadable old graph must be rebuilt
        return False
    return _TEXTURE_PARAMETERS.issubset(textures) and _SCALAR_PARAMETERS.issubset(scalars)


def _author_master_graph(mat, fallback_normal):
    edit = unreal.MaterialEditingLibrary
    edit.delete_all_material_expressions(mat)
    mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_TRANSLUCENT)
    try:
        mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_DEFAULT_LIT)
        mat.set_editor_property("two_sided", True)
        mat.set_editor_property(
            "translucency_lighting_mode",
            unreal.TranslucencyLightingMode.TLM_SURFACE_PER_PIXEL_LIGHTING,
        )
    except Exception:  # noqa: BLE001 - properties differ slightly across UE5 minors
        pass

    water_color = _create(edit, mat, unreal.MaterialExpressionVectorParameter, 120, -720)
    water_color.set_editor_property("parameter_name", "WaterColor")
    water_color.set_editor_property(
        "default_value", unreal.LinearColor(0.08, 0.32, 0.34, 1.0))
    opacity_scale = _scalar(edit, mat, "OpacityScale", 0.45, 120, 120)
    # Generic volume planes retain the old 0.04 multiplier. Decoded FluidShader instances
    # override this to 1.0 so their raw UPan/VPan values reach the graph unchanged.
    pan_speed = _scalar(edit, mat, "PanSpeed", 0.04, -1380, -570)
    normal_strength = _scalar(edit, mat, "NormalStrength", 0.55, 120, -40)
    roughness = _scalar(edit, mat, "Roughness", 0.12, 120, 520)
    depth_fade_dist = _scalar(edit, mat, "DepthFadeDistance", 180.0, 120, 420)

    texcoord = _create(edit, mat, unreal.MaterialExpressionTextureCoordinate, -1380, -720)
    time_node = _create(edit, mat, unreal.MaterialExpressionTime, -1380, -650)
    white = _white_texture()
    diffuse_1 = _panned_sample(
        edit, mat, texcoord, time_node, pan_speed, white, "WaterDiffuse1",
        "DiffusePan1", 1.0, 0.7, -720)
    diffuse_2 = _panned_sample(
        edit, mat, texcoord, time_node, pan_speed, white, "WaterDiffuse2",
        "DiffusePan2", -0.65, 0.35, -430)
    normal_1 = _panned_sample(
        edit, mat, texcoord, time_node, pan_speed, fallback_normal, "WaterNormal1",
        "NormalPan1", 1.0, 0.7, -140, normal=True)
    normal_2 = _panned_sample(
        edit, mat, texcoord, time_node, pan_speed, fallback_normal, "WaterNormal2",
        "NormalPan2", -0.65, 0.35, 150, normal=True)

    half = _create(edit, mat, unreal.MaterialExpressionConstant, 20, -470)
    half.set_editor_property("r", 0.5)
    diffuse_blend = _create(
        edit, mat, unreal.MaterialExpressionLinearInterpolate, 20, -620)
    edit.connect_material_expressions(diffuse_1, "RGB", diffuse_blend, "A")
    edit.connect_material_expressions(diffuse_2, "RGB", diffuse_blend, "B")
    edit.connect_material_expressions(half, "", diffuse_blend, "Alpha")
    tinted = _create(edit, mat, unreal.MaterialExpressionMultiply, 320, -620)
    edit.connect_material_expressions(diffuse_blend, "", tinted, "A")
    edit.connect_material_expressions(water_color, "", tinted, "B")

    normal_blend = _create(
        edit, mat, unreal.MaterialExpressionLinearInterpolate, 20, -180)
    edit.connect_material_expressions(normal_1, "RGB", normal_blend, "A")
    edit.connect_material_expressions(normal_2, "RGB", normal_blend, "B")
    edit.connect_material_expressions(half, "", normal_blend, "Alpha")
    flat_n = _create(edit, mat, unreal.MaterialExpressionConstant3Vector, 20, -20)
    flat_n.set_editor_property("constant", unreal.LinearColor(0.0, 0.0, 1.0, 0.0))
    strengthened = _create(
        edit, mat, unreal.MaterialExpressionLinearInterpolate, 320, -140)
    edit.connect_material_expressions(flat_n, "", strengthened, "A")
    edit.connect_material_expressions(normal_blend, "", strengthened, "B")
    edit.connect_material_expressions(normal_strength, "", strengthened, "Alpha")

    fresnel = _create(edit, mat, unreal.MaterialExpressionFresnel, 320, 80)
    try:
        fresnel.set_editor_property("exponent_in", 4.0)
        fresnel.set_editor_property("base_reflect_fraction_in", 0.08)
    except Exception:  # noqa: BLE001
        pass
    fresnel_bias = _create(edit, mat, unreal.MaterialExpressionConstant, 320, 200)
    fresnel_bias.set_editor_property("r", 0.25)
    fresnel_add = _create(edit, mat, unreal.MaterialExpressionAdd, 500, 120)
    edit.connect_material_expressions(fresnel_bias, "", fresnel_add, "A")
    edit.connect_material_expressions(fresnel, "", fresnel_add, "B")

    depth_fade = _create(edit, mat, unreal.MaterialExpressionDepthFade, 500, 300)
    try:
        depth_fade.set_editor_property("fade_distance_default", 180.0)
    except Exception:  # noqa: BLE001
        pass
    edit.connect_material_expressions(depth_fade_dist, "", depth_fade, "FadeDistance")
    opacity = _create(edit, mat, unreal.MaterialExpressionMultiply, 700, 120)
    edit.connect_material_expressions(opacity_scale, "", opacity, "A")
    edit.connect_material_expressions(fresnel_add, "", opacity, "B")
    faded_opacity = _create(edit, mat, unreal.MaterialExpressionMultiply, 880, 120)
    edit.connect_material_expressions(opacity, "", faded_opacity, "A")
    edit.connect_material_expressions(depth_fade, "", faded_opacity, "B")

    edit.connect_material_property(tinted, "", unreal.MaterialProperty.MP_BASE_COLOR)
    edit.connect_material_property(strengthened, "", unreal.MaterialProperty.MP_NORMAL)
    edit.connect_material_property(roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)
    edit.connect_material_property(faded_opacity, "", unreal.MaterialProperty.MP_OPACITY)
    edit.recompile_material(mat)
    unreal.EditorAssetLibrary.save_loaded_asset(mat)


def ensure_water_materials(report=None):
    """Create/upgrade M_ShockWater and its generic cascading instance."""
    report = report if report is not None else {"failures": [], "assets": {}}
    unreal.EditorAssetLibrary.make_directory(CONTENT_FOLDER)
    fallback_normal = _ensure_ripple_normal(report)
    master_path = "%s/%s" % (CONTENT_FOLDER, MASTER_NAME)
    mat = unreal.EditorAssetLibrary.load_asset(master_path)
    if mat is None:
        mat = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            MASTER_NAME, CONTENT_FOLDER, unreal.Material, unreal.MaterialFactoryNew())
    if mat is None:
        report.setdefault("failures", []).append("could not create %s" % master_path)
        return None, None

    if not _graph_is_current(mat):
        _author_master_graph(mat, fallback_normal)
        report["masterGraph"] = "created_or_upgraded"
        _log("created/upgraded dual-layer master %s" % master_path)
    else:
        report["masterGraph"] = "current"
    report.setdefault("assets", {})[MASTER_NAME] = master_path

    mi_path = "%s/%s" % (CONTENT_FOLDER, CASCADING_MI_NAME)
    mi = unreal.EditorAssetLibrary.load_asset(mi_path)
    if mi is None:
        mi = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            CASCADING_MI_NAME,
            CONTENT_FOLDER,
            unreal.MaterialInstanceConstant,
            unreal.MaterialInstanceConstantFactoryNew(),
        )
    if mi is None:
        report.setdefault("failures", []).append("could not create %s" % mi_path)
        return mat, None

    edit = unreal.MaterialEditingLibrary
    edit.set_material_instance_parent(mi, mat)
    edit.set_material_instance_scalar_parameter_value(mi, "PanSpeed", 0.18)
    edit.set_material_instance_scalar_parameter_value(mi, "NormalStrength", 1.0)
    edit.set_material_instance_scalar_parameter_value(mi, "OpacityScale", 0.55)
    edit.set_material_instance_vector_parameter_value(
        mi, "WaterColor", unreal.LinearColor(0.06, 0.38, 0.36, 1.0))
    edit.update_material_instance(mi)
    unreal.EditorAssetLibrary.save_loaded_asset(mi)
    report.setdefault("assets", {})[CASCADING_MI_NAME] = mi_path
    return mat, mi


def configure_fluid_instance(material, instance, diffuse_texture=None, normal_texture=None,
                             master=None, report=None):
    """Bind one decoded Medical FluidShader to the shared dual-layer water master.

    UPan/VPan are used directly as direction/speed inputs. PanTime is carried as a scalar
    override and metadata but intentionally does not alter speed because its semantics are UNKNOWN.
    """
    if material.get("className") != "FluidShader":
        return False
    if not isinstance(instance, unreal.MaterialInstanceConstant):
        return False
    if master is None:
        master, _ = ensure_water_materials(report)
    if master is None:
        return False

    edit = unreal.MaterialEditingLibrary
    edit.set_material_instance_parent(instance, master)
    diffuse_texture = diffuse_texture or _white_texture()
    if normal_texture is None:
        normal_texture = unreal.load_asset("/Engine/EngineMaterials/DefaultNormal")
    for parameter in ("WaterDiffuse1", "WaterDiffuse2"):
        if diffuse_texture is not None:
            edit.set_material_instance_texture_parameter_value(instance, parameter, diffuse_texture)
    for parameter in ("WaterNormal1", "WaterNormal2"):
        if normal_texture is not None:
            edit.set_material_instance_texture_parameter_value(instance, parameter, normal_texture)

    edit.set_material_instance_scalar_parameter_value(instance, "PanSpeed", 1.0)
    edit.set_material_instance_scalar_parameter_value(instance, "NormalStrength", 1.0)
    edit.set_material_instance_vector_parameter_value(
        instance, "WaterColor", unreal.LinearColor(1.0, 1.0, 1.0, 1.0))

    by_slot = {entry.get("slot"): entry for entry in material.get("animators") or []}
    for slot, prefix in _ANIMATOR_PARAMETERS.items():
        animator = by_slot.get(slot) or {}
        for source_name, suffix in (("panU", "U"), ("panV", "V"), ("duration", "Duration")):
            value = animator.get(source_name)
            edit.set_material_instance_scalar_parameter_value(
                instance, prefix + suffix, float(value) if value is not None else 0.0)

    for key, value in (
        ("BioShockWaterMaterial", material.get("name")),
        ("BioShockWaterDiffuse", material.get("diffuse")),
        ("BioShockWaterNormal", material.get("normalMap")),
        ("BioShockWaterAnimators", json.dumps(material.get("animators") or [], sort_keys=True)),
        ("BioShockPanTimeUse", "carried_not_interpreted"),
    ):
        unreal.EditorAssetLibrary.set_metadata_tag(
            instance, key, "" if value is None else str(value))

    edit.update_material_instance(instance)
    unreal.EditorAssetLibrary.save_loaded_asset(instance)
    if report is not None:
        report["fluidInstancesConfigured"] = report.get("fluidInstancesConfigured", 0) + 1
    return True


def main():
    report = {"failures": [], "assets": {}}
    ensure_water_materials(report)
    out = _write_report(report)
    if report["failures"]:
        raise RuntimeError("author_water_material:\n- " + "\n- ".join(report["failures"]))
    _log("PASS -> %s" % out)
    return report


if __name__ == "__main__":
    main()
