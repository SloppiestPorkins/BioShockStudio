"""Import decoded BioShock HUD SWF PNGs into /Game/BioShockUI/HUD as Texture2D.

PNG sources live outside the git repo (same rule as every other game-derived asset). Default
export directory: %TEMP%/BioShockHudUi/import — produce it with the CLI:

  dotnet run --project src/BioShockStudio.Cli -c Release -- export-swf-sprite HUDPC.swf 98 <dir>/T_Hud_HealthArc.png --size=512
  dotnet run --project src/BioShockStudio.Cli -c Release -- export-swf-shapes HUDPC.swf <tmp> --id=158 --size=512
  # copy shape_158.png -> T_Hud_EveArc.png; shape_160.png -> T_Hud_MeterUnderlay.png

Or run tools/ue5/export_hud_ui.py (no Unreal required).

Assets land only in the throwaway BioShockUE5 project Content — never the git repo.
"""

from __future__ import annotations

import json
import os

import unreal

CONTENT_FOLDER = "/Game/BioShockUI/HUD"
DEFAULT_EXPORT = os.path.join(os.environ.get("TEMP", "."), "BioShockHudUi", "import")


def _log(message):
    unreal.log("[bioshock-hud-ui] %s" % message)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _ensure_dir(path):
    if unreal.EditorAssetLibrary.does_directory_exist(path):
        return
    if not unreal.EditorAssetLibrary.make_directory(path):
        raise RuntimeError("could not create folder %s" % path)


def _disable_interchange():
    # Same Interchange assert avoidance as import_bioshock / import_weapon_meshes.
    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag
        )


def _asset_tools():
    return unreal.AssetToolsHelpers.get_asset_tools()


def _import_png(source, destination_path, asset_name):
    """Import one PNG as Texture2D under destination_path/asset_name. Returns the texture or None."""
    if not os.path.isfile(source):
        return None

    task = unreal.AssetImportTask()
    task.set_editor_property("filename", source)
    task.set_editor_property("destination_path", destination_path)
    task.set_editor_property("destination_name", asset_name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    try:
        task.set_editor_property("factory", unreal.TextureFactory())
    except Exception as exc:  # noqa: BLE001
        _log("could not pin TextureFactory (%s); Interchange may assert" % exc)

    _asset_tools().import_asset_tasks([task])
    objects = list(task.get_objects())
    texture = next((o for o in objects if isinstance(o, unreal.Texture2D)), None)
    if texture is None:
        # Fallback: load whatever landed at the expected path.
        texture = unreal.EditorAssetLibrary.load_asset(
            "%s/%s" % (destination_path, asset_name)
        )
        if texture is not None and not isinstance(texture, unreal.Texture2D):
            texture = None
    if texture is None:
        return None

    # HUD art is authored colour; keep alpha for arc silhouettes on transparent UImage brushes.
    texture.set_editor_property("srgb", True)
    texture.set_editor_property(
        "compression_settings", unreal.TextureCompressionSettings.TC_DEFAULT
    )
    try:
        texture.set_editor_property(
            "alpha_coverage_thresholds", unreal.Vector4(0.0, 0.0, 0.0, 0.0)
        )
    except Exception:  # noqa: BLE001
        pass
    unreal.EditorAssetLibrary.save_loaded_asset(texture)
    return texture


def main(export_directory=None, out=None, content_folder=CONTENT_FOLDER):
    export_directory = export_directory or os.environ.get(
        "BIOSHOCK_HUD_UI_EXPORT", DEFAULT_EXPORT
    )
    out = out or os.environ.get(
        "BIOSHOCK_HUD_UI_IMPORT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "hud_ui_import_report.json"),
    )

    report = {
        "exportDirectory": export_directory,
        "contentFolder": content_folder,
        "imported": {},
        "failures": [],
        "blockers": [],
    }
    failures = report["failures"]

    manifest_path = os.path.join(export_directory, "hud_ui_manifest.json")
    textures = []
    if os.path.isfile(manifest_path):
        with open(manifest_path, encoding="utf-8") as handle:
            manifest = json.load(handle)
        textures = list(manifest.get("textures") or [])
        report["blockers"] = list(manifest.get("blockers") or [])
        report["source"] = manifest.get("source")
    else:
        # Minimal fallback when only PNGs are present.
        textures = [
            {"name": "T_Hud_HealthArc", "file": "T_Hud_HealthArc.png"},
            {"name": "T_Hud_EveArc", "file": "T_Hud_EveArc.png"},
            {"name": "T_Hud_MeterUnderlay", "file": "T_Hud_MeterUnderlay.png"},
        ]

    if not os.path.isdir(export_directory):
        failures.append("export directory missing: %s" % export_directory)
        _write(out, report)
        raise RuntimeError("hud-ui-import:\n- " + "\n- ".join(failures))

    _disable_interchange()
    _ensure_dir("/Game/BioShockUI")
    _ensure_dir(content_folder)

    for entry in textures:
        name = entry["name"]
        source = os.path.join(export_directory, entry["file"].replace("/", os.sep))
        if not os.path.isfile(source):
            failures.append("missing PNG: %s" % source)
            continue
        texture = _import_png(source, content_folder, name)
        if texture is None:
            failures.append("import failed: %s" % name)
            continue
        path = "%s/%s" % (content_folder, name)
        report["imported"][name] = path
        _log("imported %s" % path)

    report["ok"] = not failures
    _write(out, report)
    if failures:
        raise RuntimeError("hud-ui-import:\n- " + "\n- ".join(failures))
    _log("PASS hud-ui-import (%d textures)" % len(report["imported"]))
    return report


if __name__ == "__main__":
    main()
