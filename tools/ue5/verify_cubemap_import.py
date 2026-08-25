"""Verify CubemapProbe -> SphereReflectionCapture and face PNG import.

Does not assemble a TextureCube: face-to-axis mapping is UNKNOWN
(docs/research/textures.md). Call from Unreal's -run=pythonscript commandlet.

Set BIOSHOCK_CUBEMAP_MANIFEST to the probe-only <map>.ue5-level.json, and
BIOSHOCK_CUBEMAP_LOOK_OUT to the JSON report path. Raises RuntimeError on a
real failure so a clean commandlet summary is not treated as success.
"""

import json
import os

import unreal

import import_level


def _disable_interchange():
    # PNG import asserts under -unattended (CurrentApplication.IsValid()).
    unreal.SystemLibrary.execute_console_command(None, "Interchange.FeatureFlags.Import.PNG 0")
    unreal.SystemLibrary.execute_console_command(None, "Interchange.FeatureFlags.Import.Texture 0")


def _tag_value(actor, prefix):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith(prefix):
            return text[len(prefix):]
    return None


def main(manifest_path=None, report_path=None):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_CUBEMAP_MANIFEST")
    report_path = report_path or os.environ.get("BIOSHOCK_CUBEMAP_LOOK_OUT")
    if not manifest_path:
        raise RuntimeError("Set BIOSHOCK_CUBEMAP_MANIFEST to the probe-only level JSON.")
    if not report_path:
        raise RuntimeError("Set BIOSHOCK_CUBEMAP_LOOK_OUT to the JSON report path.")

    _disable_interchange()

    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    expected_probes = [a for a in (manifest.get("actors") or []) if a.get("className") == "CubemapProbe"]
    expected_cubemaps = manifest.get("cubemaps") or []
    if not expected_probes:
        raise RuntimeError("manifest has no CubemapProbe actors")
    if not expected_cubemaps:
        raise RuntimeError("manifest has no cubemaps[] — this export predates face PNG write")

    report = {
        "package": manifest.get("package"),
        "expectedProbes": len(expected_probes),
        "expectedCubemaps": len(expected_cubemaps),
        "textureCubeAssembled": False,
        "captures": [],
        "faces": [],
        "error": None,
    }

    import_report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0}
    existing = import_level._existing_by_key()
    destination = "/Game/BioShockLevel/%s" % (manifest.get("package") or "Level")
    faces = import_level._import_cubemap_faces(
        manifest, os.path.dirname(os.path.abspath(manifest_path)), destination, import_report)
    handled = set()
    import_level._import_cubemap_probes(manifest, existing, import_report, handled, faces)
    report["import"] = import_report

    capture_class = getattr(unreal, "SphereReflectionCapture", None)
    if capture_class is None:
        raise RuntimeError("unreal.SphereReflectionCapture is missing")

    captures = [
        actor for actor in import_level._actor_subsystem().get_all_level_actors()
        if isinstance(actor, capture_class)
    ]
    if len(captures) != len(expected_probes):
        raise RuntimeError(
            "SphereReflectionCapture count %d != CubemapProbe count %d"
            % (len(captures), len(expected_probes)))

    for actor in captures:
        loc = actor.get_actor_location()
        report["captures"].append({
            "label": str(actor.get_actor_label()),
            "class": actor.get_class().get_name(),
            "key": _tag_value(actor, "BioShockKey="),
            "cubemap": _tag_value(actor, "BioShockCubemap="),
            "location": [loc.x, loc.y, loc.z],
        })

    missing_faces = []
    for cube in expected_cubemaps:
        imported = faces.get(cube.get("name") or "") or []
        for index, texture in imported:
            size_x = texture.blueprint_get_size_x() if hasattr(texture, "blueprint_get_size_x") else None
            size_y = texture.blueprint_get_size_y() if hasattr(texture, "blueprint_get_size_y") else None
            report["faces"].append({
                "cubemap": cube.get("name"),
                "index": index,
                "path": texture.get_path_name(),
                "srgb": bool(texture.get_editor_property("srgb")),
                "sizeX": size_x,
                "sizeY": size_y,
            })
        declared = len(cube.get("faces") or [])
        if len(imported) != declared:
            missing_faces.append("%s: imported %d of %d faces" % (cube.get("name"), len(imported), declared))
    if missing_faces:
        raise RuntimeError("face import incomplete: " + "; ".join(missing_faces))

    cube_cls = getattr(unreal, "TextureCube", None)
    if cube_cls is not None:
        face_folder = "%s/CubemapFaces" % destination
        for path in unreal.EditorAssetLibrary.list_assets(face_folder, recursive=True) or []:
            asset = unreal.EditorAssetLibrary.load_asset(path)
            if isinstance(asset, cube_cls):
                raise RuntimeError(
                    "TextureCube assets exist; face order is UNKNOWN and must not be packed: %s" % path)

    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    return report


if __name__ == "__main__":
    main()
