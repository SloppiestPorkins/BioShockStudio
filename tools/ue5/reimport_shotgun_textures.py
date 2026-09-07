"""Re-import WP_Shotgun textures from recovered PNGs into /Game/BioShockWeapons.

Expects PNGs produced by recover_stripped_textures.py (or any 2048+ source) under
BIOSHOCK_SHOTGUN_TEX_DIR (default %TEMP%/bioshock-shotgun-tex-fixed/Textures).

Replaces only the three Shotgun_NoUpgrades_* Texture2D assets and leaves the mesh,
skeleton, animations, and material instance in place — the MI already samples those
parameter names.

Call from Unreal -run=pythonscript (see run_reimport_shotgun_textures.py).
"""
from __future__ import annotations

import json
import os

import unreal


CONTENT_TEX = "/Game/BioShockWeapons/WP_Shotgun/Textures"
TEXTURES = (
    # stem, srgb, compression
    ("Shotgun_NoUpgrades_Diffuse", True, unreal.TextureCompressionSettings.TC_DEFAULT),
    ("Shotgun_NoUpgrades_Normal", False, unreal.TextureCompressionSettings.TC_NORMALMAP),
    ("Shotgun_NoUpgrades_Specular", True, unreal.TextureCompressionSettings.TC_DEFAULT),
)


def _log(message):
    unreal.log("[bioshock-shotgun-tex] %s" % message)


def _write(path, report):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _disable_interchange():
    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag
        )


def _import_one(stem, png_path, srgb, compression):
    if not os.path.isfile(png_path):
        raise FileNotFoundError(png_path)
    size = os.path.getsize(png_path)
    if size < 50_000:
        raise RuntimeError(
            "%s is only %d bytes — still a stub; run recover_stripped_textures.py first"
            % (png_path, size)
        )

    dest = "%s/%s" % (CONTENT_TEX, stem)
    existed = unreal.EditorAssetLibrary.does_asset_exist(dest)

    task = unreal.AssetImportTask()
    task.set_editor_property("filename", png_path)
    task.set_editor_property("destination_path", CONTENT_TEX)
    task.set_editor_property("destination_name", stem)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    try:
        task.set_editor_property("factory", unreal.TextureFactory())
    except Exception as exc:  # noqa: BLE001
        _log("could not pin TextureFactory (%s); Interchange may assert" % exc)

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    objects = list(task.get_objects())
    texture = next((o for o in objects if isinstance(o, unreal.Texture2D)), None)
    if texture is None:
        # Some UE builds return empty get_objects on replace; load by path.
        texture = unreal.EditorAssetLibrary.load_asset(dest)
    if not isinstance(texture, unreal.Texture2D):
        raise RuntimeError("import produced no Texture2D for %s" % stem)

    texture.set_editor_property("srgb", srgb)
    texture.set_editor_property("compression_settings", compression)
    unreal.EditorAssetLibrary.save_loaded_asset(texture)

    fresh = unreal.EditorAssetLibrary.load_asset(dest)
    width = fresh.blueprint_get_size_x() if hasattr(fresh, "blueprint_get_size_x") else None
    height = fresh.blueprint_get_size_y() if hasattr(fresh, "blueprint_get_size_y") else None
    return {
        "stem": stem,
        "path": dest,
        "png": png_path,
        "pngBytes": size,
        "existed": existed,
        "srgb": bool(fresh.get_editor_property("srgb")),
        "width": width,
        "height": height,
    }


def main(tex_dir=None, out=None):
    tex_dir = tex_dir or os.environ.get(
        "BIOSHOCK_SHOTGUN_TEX_DIR",
        os.path.join(os.environ.get("TEMP", "."), "bioshock-shotgun-tex-fixed", "Textures"),
    )
    out = out or os.environ.get(
        "BIOSHOCK_SHOTGUN_TEX_IMPORT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "shotgun_texture_reimport_report.json"),
    )

    report = {
        "texDir": tex_dir,
        "contentTextures": CONTENT_TEX,
        "imported": [],
        "failures": [],
    }
    _disable_interchange()

    if not os.path.isdir(tex_dir):
        report["failures"].append("texture dir missing: %s" % tex_dir)
        _write(out, report)
        raise RuntimeError(report["failures"][0])

    for stem, srgb, compression in TEXTURES:
        png = os.path.join(tex_dir, stem + ".png")
        try:
            entry = _import_one(stem, png, srgb, compression)
            report["imported"].append(entry)
            _log(
                "imported %s %sx%s srgb=%s (%d byte png)"
                % (stem, entry["width"], entry["height"], entry["srgb"], entry["pngBytes"])
            )
        except Exception as exc:  # noqa: BLE001
            report["failures"].append("%s: %s" % (stem, exc))
            _log("FAIL %s: %s" % (stem, exc))

    # Confirm the MI still resolves the diffuse parameter to our asset.
    mi_path = (
        "/Game/BioShockWeapons/WP_Shotgun/Materials/"
        "MI_Shotgun_NoUpgrades_Diffuse_shader"
    )
    mi = unreal.EditorAssetLibrary.load_asset(mi_path) if unreal.EditorAssetLibrary.does_asset_exist(mi_path) else None
    report["materialInstance"] = mi_path if mi else None
    if mi is not None:
        edit = unreal.MaterialEditingLibrary
        base = edit.get_material_instance_texture_parameter_value(mi, "BaseColor")
        report["miBaseColor"] = base.get_path_name() if base else None

    report["errorCount"] = len(report["failures"])
    report["shotgun_texture_import"] = "ok" if not report["failures"] else "fail"
    _write(out, report)
    if report["failures"]:
        raise RuntimeError(
            "shotgun texture reimport (%d):\n- " % len(report["failures"])
            + "\n- ".join(report["failures"])
        )
    _log("Success - %d textures reimported" % len(report["imported"]))
    return report


if __name__ == "__main__":
    main()
