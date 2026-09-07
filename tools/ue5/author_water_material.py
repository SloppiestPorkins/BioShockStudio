"""Author M_ShockWater (+ cascading MI) under /Game/BioShock/Water.

Deco-era Rapture pool water: translucent blue-green, panning normal ripples, fresnel
edge opacity, depth fade. Cheap whole-level surface — no binary .uasset in git.

Idempotent: if the master already exists, leave it and only ensure the cascading MI.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/author_water_material.py \\
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
    """Minimal PNG writer (no Pillow dependency). pixels_rgba: bytes len width*height*4."""

    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    raw = b""
    stride = width * 4
    for y in range(height):
        raw += b"\x00" + pixels_rgba[y * stride : (y + 1) * stride]
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            chunk(b"IHDR", ihdr),
            chunk(b"IDAT", zlib.compress(raw, 9)),
            chunk(b"IEND", b""),
        ]
    )


def _ensure_ripple_normal(report):
    """Ripple normal for M_ShockWater.

    Prefers a previously authored T_ShockWater_Normal. Fresh imports of a procedural PNG
    trip Interchange → ContentBrowser → Slate asserts under -run=pythonscript, so a new
    checkout falls back to /Engine/EngineMaterials/DefaultNormal (still panned; look is
    weaker until a human/editor import lands the procedural map).
    """
    path = "%s/%s" % (CONTENT_FOLDER, NORMAL_NAME)
    if unreal.EditorAssetLibrary.does_asset_exist(path):
        report.setdefault("assets", {})[NORMAL_NAME] = path
        return unreal.EditorAssetLibrary.load_asset(path)

    # Optional: stage a PNG for a later editor import; do not AssetImportTask it headless.
    try:
        size = 256
        pixels = bytearray(size * size * 4)
        import math

        for y in range(size):
            for x in range(size):
                u = x / float(size)
                v = y / float(size)
                dx = 0.35 * math.sin(u * math.pi * 8.0) * math.cos(v * math.pi * 3.0)
                dy = 0.35 * math.sin(v * math.pi * 8.0) * math.cos(u * math.pi * 3.0)
                nx = max(0, min(255, int((dx * 0.5 + 0.5) * 255)))
                ny = max(0, min(255, int((dy * 0.5 + 0.5) * 255)))
                i = (y * size + x) * 4
                pixels[i] = nx
                pixels[i + 1] = ny
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
    _log("using engine DefaultNormal (headless-safe); stage PNG at %%TEMP%%/bioshock-water")
    return fallback


def _connect(edit, mat, src, src_pin, dst_prop):
    edit.connect_material_property(src, src_pin, dst_prop)


def ensure_water_materials(report=None):
    """Create/return M_ShockWater and MI_ShockWater_Cascading. Idempotent."""
    report = report if report is not None else {"failures": [], "assets": {}}
    edit = unreal.MaterialEditingLibrary
    unreal.EditorAssetLibrary.make_directory(CONTENT_FOLDER)

    normal = _ensure_ripple_normal(report)
    master_path = "%s/%s" % (CONTENT_FOLDER, MASTER_NAME)

    if unreal.EditorAssetLibrary.does_asset_exist(master_path):
        mat = unreal.EditorAssetLibrary.load_asset(master_path)
        report.setdefault("assets", {})[MASTER_NAME] = master_path
        _log("master already present %s" % master_path)
    else:
        asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
        factory = unreal.MaterialFactoryNew()
        mat = asset_tools.create_asset(MASTER_NAME, CONTENT_FOLDER, unreal.Material, factory)
        if mat is None:
            report.setdefault("failures", []).append("could not create %s" % master_path)
            return None, None

        mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_TRANSLUCENT)
        try:
            mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_DEFAULT_LIT)
        except Exception:  # noqa: BLE001
            pass
        try:
            mat.set_editor_property("two_sided", True)
        except Exception:  # noqa: BLE001
            pass
        # Cheap translucent: no separate translucency / no volumetric — whole-level cost.
        try:
            mat.set_editor_property("translucency_lighting_mode",
                                   unreal.TranslucencyLightingMode.TLM_SURFACE_PER_PIXEL_LIGHTING)
        except Exception:  # noqa: BLE001
            pass

        # --- parameters ---
        water_color = edit.create_material_expression(
            mat, unreal.MaterialExpressionVectorParameter, -720, -80
        )
        water_color.set_editor_property("parameter_name", "WaterColor")
        water_color.set_editor_property(
            "default_value", unreal.LinearColor(0.08, 0.32, 0.34, 1.0)
        )

        opacity_scale = edit.create_material_expression(
            mat, unreal.MaterialExpressionScalarParameter, -720, 120
        )
        opacity_scale.set_editor_property("parameter_name", "OpacityScale")
        opacity_scale.set_editor_property("default_value", 0.45)

        pan_speed = edit.create_material_expression(
            mat, unreal.MaterialExpressionScalarParameter, -720, 220
        )
        pan_speed.set_editor_property("parameter_name", "PanSpeed")
        pan_speed.set_editor_property("default_value", 0.04)

        normal_strength = edit.create_material_expression(
            mat, unreal.MaterialExpressionScalarParameter, -720, 320
        )
        normal_strength.set_editor_property("parameter_name", "NormalStrength")
        normal_strength.set_editor_property("default_value", 0.55)

        roughness = edit.create_material_expression(
            mat, unreal.MaterialExpressionScalarParameter, -720, 420
        )
        roughness.set_editor_property("parameter_name", "Roughness")
        roughness.set_editor_property("default_value", 0.12)

        depth_fade_dist = edit.create_material_expression(
            mat, unreal.MaterialExpressionScalarParameter, -720, 520
        )
        depth_fade_dist.set_editor_property("parameter_name", "DepthFadeDistance")
        depth_fade_dist.set_editor_property("default_value", 180.0)

        # --- panning UVs for the normal ---
        texcoord = edit.create_material_expression(
            mat, unreal.MaterialExpressionTextureCoordinate, -720, -280
        )
        time_node = edit.create_material_expression(
            mat, unreal.MaterialExpressionTime, -720, -200
        )
        mul_speed = edit.create_material_expression(
            mat, unreal.MaterialExpressionMultiply, -520, -200
        )
        edit.connect_material_expressions(time_node, "", mul_speed, "A")
        edit.connect_material_expressions(pan_speed, "", mul_speed, "B")

        # Append (speed, speed*0.7) as pan offset
        speed_y = edit.create_material_expression(
            mat, unreal.MaterialExpressionMultiply, -520, -120
        )
        const_y = edit.create_material_expression(
            mat, unreal.MaterialExpressionConstant, -720, -40
        )
        const_y.set_editor_property("r", 0.7)
        edit.connect_material_expressions(mul_speed, "", speed_y, "A")
        edit.connect_material_expressions(const_y, "", speed_y, "B")

        append_pan = edit.create_material_expression(
            mat, unreal.MaterialExpressionAppendVector, -340, -200
        )
        edit.connect_material_expressions(mul_speed, "", append_pan, "A")
        edit.connect_material_expressions(speed_y, "", append_pan, "B")

        add_uv = edit.create_material_expression(
            mat, unreal.MaterialExpressionAdd, -180, -260
        )
        edit.connect_material_expressions(texcoord, "", add_uv, "A")
        edit.connect_material_expressions(append_pan, "", add_uv, "B")

        normal_samp = edit.create_material_expression(
            mat, unreal.MaterialExpressionTextureSampleParameter2D, -40, -280
        )
        normal_samp.set_editor_property("parameter_name", "RippleNormal")
        try:
            normal_samp.set_editor_property(
                "sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL
            )
        except Exception:  # noqa: BLE001
            pass
        if normal is not None:
            try:
                normal_samp.set_editor_property("texture", normal)
            except Exception:  # noqa: BLE001
                pass
        edit.connect_material_expressions(add_uv, "", normal_samp, "UVs")

        # Flatten toward (0,0,1) by NormalStrength: lerp(flat, sampled, strength)
        flat_n = edit.create_material_expression(
            mat, unreal.MaterialExpressionConstant3Vector, -40, -80
        )
        flat_n.set_editor_property("constant", unreal.LinearColor(0.0, 0.0, 1.0, 0.0))
        lerp_n = edit.create_material_expression(
            mat, unreal.MaterialExpressionLinearInterpolate, 160, -200
        )
        edit.connect_material_expressions(flat_n, "", lerp_n, "A")
        edit.connect_material_expressions(normal_samp, "RGB", lerp_n, "B")
        edit.connect_material_expressions(normal_strength, "", lerp_n, "Alpha")

        # --- fresnel * depth fade * OpacityScale ---
        fresnel = edit.create_material_expression(
            mat, unreal.MaterialExpressionFresnel, -40, 80
        )
        try:
            fresnel.set_editor_property("exponent_in", 4.0)
            fresnel.set_editor_property("base_reflect_fraction_in", 0.08)
        except Exception:  # noqa: BLE001
            pass

        # Opacity = OpacityScale * saturate(0.25 + fresnel) * DepthFade
        fresnel_bias = edit.create_material_expression(
            mat, unreal.MaterialExpressionConstant, -40, 200
        )
        fresnel_bias.set_editor_property("r", 0.25)
        fresnel_add = edit.create_material_expression(
            mat, unreal.MaterialExpressionAdd, 140, 120
        )
        edit.connect_material_expressions(fresnel_bias, "", fresnel_add, "A")
        edit.connect_material_expressions(fresnel, "", fresnel_add, "B")

        depth_fade = edit.create_material_expression(
            mat, unreal.MaterialExpressionDepthFade, 140, 240
        )
        try:
            # FadeDistance is often a pin; also set property when present.
            depth_fade.set_editor_property("fade_distance_default", 180.0)
        except Exception:  # noqa: BLE001
            pass
        edit.connect_material_expressions(depth_fade_dist, "", depth_fade, "FadeDistance")

        mul_op = edit.create_material_expression(
            mat, unreal.MaterialExpressionMultiply, 340, 80
        )
        edit.connect_material_expressions(opacity_scale, "", mul_op, "A")
        edit.connect_material_expressions(fresnel_add, "", mul_op, "B")
        mul_op2 = edit.create_material_expression(
            mat, unreal.MaterialExpressionMultiply, 500, 80
        )
        edit.connect_material_expressions(mul_op, "", mul_op2, "A")
        edit.connect_material_expressions(depth_fade, "", mul_op2, "B")

        _connect(edit, mat, water_color, "", unreal.MaterialProperty.MP_BASE_COLOR)
        _connect(edit, mat, lerp_n, "", unreal.MaterialProperty.MP_NORMAL)
        _connect(edit, mat, roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)
        _connect(edit, mat, mul_op2, "", unreal.MaterialProperty.MP_OPACITY)

        edit.recompile_material(mat)
        unreal.EditorAssetLibrary.save_loaded_asset(mat)
        report.setdefault("assets", {})[MASTER_NAME] = master_path
        _log("created master %s" % master_path)

    # Cascading / turbulent instance — faster pan, stronger normal, slightly greener.
    mi_path = "%s/%s" % (CONTENT_FOLDER, CASCADING_MI_NAME)
    if unreal.EditorAssetLibrary.does_asset_exist(mi_path):
        mi = unreal.EditorAssetLibrary.load_asset(mi_path)
        report.setdefault("assets", {})[CASCADING_MI_NAME] = mi_path
    else:
        mi_factory = unreal.MaterialInstanceConstantFactoryNew()
        asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
        mi = asset_tools.create_asset(
            CASCADING_MI_NAME, CONTENT_FOLDER, unreal.MaterialInstanceConstant, mi_factory
        )
        if mi is None:
            report.setdefault("failures", []).append("could not create %s" % mi_path)
            return mat, None
        edit.set_material_instance_parent(mi, mat)
        edit.set_material_instance_scalar_parameter_value(mi, "PanSpeed", 0.18)
        edit.set_material_instance_scalar_parameter_value(mi, "NormalStrength", 1.0)
        edit.set_material_instance_scalar_parameter_value(mi, "OpacityScale", 0.55)
        edit.set_material_instance_vector_parameter_value(
            mi, "WaterColor", unreal.LinearColor(0.06, 0.38, 0.36, 1.0)
        )
        unreal.EditorAssetLibrary.save_loaded_asset(mi)
        report.setdefault("assets", {})[CASCADING_MI_NAME] = mi_path
        _log("created cascading MI %s" % mi_path)

    return mat, mi


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
