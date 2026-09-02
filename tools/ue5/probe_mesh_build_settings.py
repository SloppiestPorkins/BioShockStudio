"""Why 514 static meshes are built at map load, and what it would cost to stop.

A -game launch of 1-Medical logs 514 "Waiting on static mesh" lines and spends 481 seconds getting
to a screenshot, of which three gaps account for 89%: 99s at LoadMap, 155s after the DDC opens,
and 174s after the world is brought up. Those are derived-data builds, not loading.

Static mesh derived data is keyed on the mesh's build settings, so anything that generates
per-mesh data the level does not need is pure load-time cost, paid on every machine with a cold
DDC. Distance fields are the usual one: they are needed for Lumen/DF shadows and are expensive to
build, and this level runs on movable lights with force_no_precomputed_lighting.

Read-only. Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_mesh_build_settings.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_MESHPROBE_ROOT (default /Game/BioShockSlice/Content/Meshes)
"""

from __future__ import annotations

import json
import os

import unreal

ROOT = os.environ.get("BIOSHOCK_MESHPROBE_ROOT", "/Game/BioShockSlice/Content/Meshes")
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "probe_mesh_build_settings.json")

# (property, where it lives). Build settings are per-LOD; the rest sit on the mesh.
BUILD_FLAGS = (
    "generate_lightmap_u_vs",
    "recompute_normals",
    "recompute_tangents",
    "use_high_precision_tangent_basis",
    "build_reversed_index_buffer",
)


def main():
    report = {"root": ROOT, "meshes": 0, "error": None, "tally": {}, "examples": {}}
    registry = unreal.AssetRegistryHelpers.get_asset_registry()

    def bump(key, value):
        slot = report["tally"].setdefault(key, {})
        name = str(value)
        slot[name] = slot.get(name, 0) + 1

    for data in registry.get_assets_by_path(unreal.Name(ROOT), recursive=True):
        asset = unreal.EditorAssetLibrary.load_asset(str(data.package_name))
        if not isinstance(asset, unreal.StaticMesh):
            continue
        report["meshes"] += 1

        # Distance fields are the expensive one and are a per-mesh property.
        for prop, key in (("generate_mesh_distance_field", "distanceField"),
                          ("nanite_settings", "nanite"),
                          ("lod_group", "lodGroup")):
            try:
                value = asset.get_editor_property(prop)
            except Exception:  # noqa: BLE001
                continue
            if key == "nanite":
                try:
                    value = bool(value.get_editor_property("enabled"))
                except Exception:  # noqa: BLE001
                    value = "unreadable"
            bump(key, value)
            if key == "distanceField" and value and "distanceField" not in report["examples"]:
                report["examples"]["distanceField"] = str(data.package_name)

        try:
            build = asset.get_editor_property("lod_for_collision")  # touch, keeps API honest
        except Exception:  # noqa: BLE001
            pass
        try:
            settings = asset.get_build_settings(0)
            for flag in BUILD_FLAGS:
                try:
                    bump(flag, settings.get_editor_property(flag))
                except Exception:  # noqa: BLE001
                    continue
        except Exception as exc:  # noqa: BLE001
            report.setdefault("buildSettingsError", str(exc))

    _write(report)
    unreal.log("[meshprobe] %s" % json.dumps(report))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
