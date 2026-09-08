"""Rebind material instances still showing the engine's white placeholder base colour.

`import_bioshock._repair_null_texture_parameters` fills a NULL BaseColor with
/Engine/EngineResources/WhiteSquareTexture so the master can compile. That is the right call for
an opaque surface and the wrong one for an additive surface, where a pure white square is added
over everything behind it: the Medical Pavilion god rays rendered as a flat white wedge across a
quarter of the frame.

The underlying cause was an exporter gap - LightBeamShader binds its colour as FalloffMap, which
was in neither MaterialReader.DiffuseSlots nor MaterialExporter's copy of that list, so the
material exported with no diffuse at all. That is fixed at source, but assets already imported
still carry the placeholder. This rebinds them from a current manifest without a full re-import.

Only touches instances whose BaseColor IS the placeholder, so it cannot overwrite a real texture,
and re-reads every change rather than counting intent.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_placeholder_base_colours.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_PLACEHOLDER_MANIFEST      path to <map>.ue5-level.json (required)
  BIOSHOCK_PLACEHOLDER_CONTENT_ROOT  content root the materials were imported under
  BIOSHOCK_PLACEHOLDER_DRY           "1" to report without changing anything
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_bioshock  # noqa: E402

MANIFEST = os.environ.get("BIOSHOCK_PLACEHOLDER_MANIFEST", "")
CONTENT_ROOT = os.environ.get("BIOSHOCK_PLACEHOLDER_CONTENT_ROOT", "/Game/BioShockLevel")
DRY = os.environ.get("BIOSHOCK_PLACEHOLDER_DRY", "0") == "1"
PLACEHOLDERS = {"WhiteSquareTexture", "DefaultDiffuse", "DefaultTexture"}
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_placeholder_base_colours.json")


def _texture_asset(destination, relative):
    """The Texture2D a manifest diffuse path imported as, or None."""
    stem = os.path.splitext(os.path.basename(relative))[0]
    for path in ("%s/Textures/%s" % (destination, stem), "%s/Textures/%s" % (CONTENT_ROOT, stem)):
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            asset = unreal.EditorAssetLibrary.load_asset(path)
            if isinstance(asset, unreal.Texture):
                return asset, path
    return None, None


def main(manifest_path=None):
    report = {"contentRoot": CONTENT_ROOT, "dryRun": DRY, "rebound": 0, "alreadyBound": 0,
              "textureMissing": 0, "noDiffuseInManifest": 0, "materials": []}
    with open(manifest_path or MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    destination = "%s/%s" % (CONTENT_ROOT, manifest.get("package") or "Level")

    lib = unreal.MaterialEditingLibrary
    for material in manifest.get("materials") or []:
        name = import_bioshock._safe_name(material.get("name") or "")
        path = "%s/Materials/MI_%s" % (destination, name)
        if not unreal.EditorAssetLibrary.does_asset_exist(path):
            continue
        mi = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(mi, unreal.MaterialInstanceConstant):
            continue

        try:
            current = lib.get_material_instance_texture_parameter_value(mi, "BaseColor")
        except Exception:  # noqa: BLE001
            continue
        if current is None or current.get_name() not in PLACEHOLDERS:
            continue

        entry = {"material": name, "class": material.get("className"), "path": path,
                 "was": current.get_name()}

        diffuse = material.get("diffuse")
        if not diffuse:
            entry["status"] = "manifest still has no diffuse"
            report["noDiffuseInManifest"] += 1
            report["materials"].append(entry)
            continue

        texture, texture_path = _texture_asset(destination, diffuse)
        if texture is None:
            entry["status"] = "texture asset not imported (%s)" % diffuse
            report["textureMissing"] += 1
            report["materials"].append(entry)
            continue
        entry["texture"] = texture_path

        if DRY:
            entry["status"] = "would rebind"
            report["materials"].append(entry)
            continue

        lib.set_material_instance_texture_parameter_value(mi, "BaseColor", texture)
        unreal.EditorAssetLibrary.save_loaded_asset(mi)
        # Re-read rather than trust the setter. An earlier repair in this project reported a
        # section hidden while the slot stayed empty on disk, because the struct it mutated was a
        # copy; a tool that counts intent instead of effect is worse than no tool.
        after = lib.get_material_instance_texture_parameter_value(mi, "BaseColor")
        entry["now"] = after.get_name() if after is not None else None
        if entry["now"] == texture.get_name():
            entry["status"] = "rebound"
            report["rebound"] += 1
        else:
            entry["status"] = "rebind did NOT persist"
        report["materials"].append(entry)

    _write(report)
    unreal.log("[placeholder] rebound=%d textureMissing=%d noDiffuse=%d" % (
        report["rebound"], report["textureMissing"], report["noDiffuseInManifest"]))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
