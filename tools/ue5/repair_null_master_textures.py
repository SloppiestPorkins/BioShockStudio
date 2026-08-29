"""Repair BioShock master materials whose TextureSampleParameter2D defaults are NULL.

Measured failure (29 Aug 2026 BioShockUE5.log): 61 masters under
/Game/BioShockSlice/Content/Materials/Masters failed to compile with
'(Node TextureSampleParameter2D) Param2D> Found NULL, requires Texture2D' and fell
back to Default Material in game — walls read as broken textures.

Does not rebuild the C++ plugin. Writes a JSON report; raises on zero repairs when
the folder still has NULL-texture masters after the pass.
"""

from __future__ import annotations

import json
import os

import unreal

import import_bioshock

DEFAULT_FOLDER = "/Game/BioShockSlice/Content/Materials/Masters"
DEFAULT_OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "_reports",
    "repair_null_master_textures.json",
)


def main(folder=None, report_path=None):
    folder = folder or os.environ.get("BIOSHOCK_REPAIR_MASTERS", DEFAULT_FOLDER)
    report_path = report_path or os.environ.get("BIOSHOCK_REPAIR_OUT", DEFAULT_OUT)

    report = {
        "folder": folder,
        "scanned": 0,
        "repaired": 0,
        "paramsRepaired": 0,
        "stillBroken": [],
        "samples": [],
        "error": None,
    }

    try:
        # Fail fast if Engine defaults cannot load in this session.
        report["engineDefaults"] = {
            "baseColor": import_bioshock._default_base_color_texture().get_path_name(),
            "normal": import_bioshock._default_normal_texture().get_path_name(),
        }

        paths = unreal.EditorAssetLibrary.list_assets(
            folder, recursive=True, include_folder=False) or []
        for path in paths:
            asset = unreal.EditorAssetLibrary.load_asset(path)
            if not isinstance(asset, unreal.Material):
                continue
            report["scanned"] += 1
            edit = unreal.MaterialEditingLibrary
            null_before = []
            for prop, label in (
                (unreal.MaterialProperty.MP_BASE_COLOR, "BaseColor"),
                (unreal.MaterialProperty.MP_EMISSIVE_COLOR, "Emissive"),
                (unreal.MaterialProperty.MP_NORMAL, "Normal"),
            ):
                node = edit.get_material_property_input_node(asset, prop)
                if isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D):
                    if node.get_editor_property("texture") is None:
                        null_before.append(label)
            if not null_before:
                continue

            fixed = import_bioshock._repair_null_texture_parameters(asset)
            report["repaired"] += 1 if fixed else 0
            report["paramsRepaired"] += fixed
            sample = {"path": path, "nullBefore": null_before, "paramsFixed": fixed}
            report["samples"].append(sample)

            null_after = []
            for prop, label in (
                (unreal.MaterialProperty.MP_BASE_COLOR, "BaseColor"),
                (unreal.MaterialProperty.MP_EMISSIVE_COLOR, "Emissive"),
                (unreal.MaterialProperty.MP_NORMAL, "Normal"),
            ):
                node = edit.get_material_property_input_node(asset, prop)
                if isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D):
                    if node.get_editor_property("texture") is None:
                        null_after.append(label)
            if null_after:
                report["stillBroken"].append({"path": path, "nullAfter": null_after})

        if report["stillBroken"]:
            raise RuntimeError(
                "%d master(s) still have NULL texture params after repair"
                % len(report["stillBroken"]))
    except Exception as exc:  # noqa: BLE001
        report["error"] = str(exc)
        raise
    finally:
        os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)

    return report


if __name__ == "__main__":
    main()
