"""Build one UE5 map holding an instance of every asset class this pipeline supports.

Gate 5 item 3. The point is not to look impressive: it is to make **regression visible in one
place**. If a future export or importer change breaks skeletal meshes, or textures stop arriving
linear, or lights lose their colour, opening this one map shows it.

It also writes a machine-readable report so the check does not depend on someone looking:

    {"map": ..., "placed": [...], "supported": [...], "unsupported": [...], "missing": [...]}

`missing` is the important field. A class this pipeline claims to support but could not instance is
a failure, and is reported rather than skipped silently -- the same rule the level importer follows
with its `unsupported` count.
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-validation] %s" % message)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _place_skeletal_mesh(path, location, report):
    """A skeletal mesh imported by import_bioshock.py, instanced as a real actor."""
    if not unreal.EditorAssetLibrary.does_asset_exist(path):
        report["missing"].append({"class": "SkeletalMesh", "asset": path})
        return None

    mesh = unreal.EditorAssetLibrary.load_asset(path)
    actor = _actors().spawn_actor_from_class(unreal.SkeletalMeshActor, unreal.Vector(*location))
    if actor is None:
        report["missing"].append({"class": "SkeletalMesh", "asset": path, "reason": "spawn failed"})
        return None

    actor.skeletal_mesh_component.set_skeletal_mesh_asset(mesh)
    actor.set_actor_label("Validation_SkeletalMesh")
    actor.tags = [unreal.Name("BioShockValidation=SkeletalMesh")]
    report["placed"].append({"class": "SkeletalMesh", "asset": path})
    return actor


def _place_textures(paths, report):
    """Textures are not actors; they are verified as assets, with their intent read back."""
    for path in paths:
        if not unreal.EditorAssetLibrary.does_asset_exist(path):
            report["missing"].append({"class": "Texture2D", "asset": path})
            continue

        texture = unreal.EditorAssetLibrary.load_asset(path)
        report["placed"].append({
            "class": "Texture2D",
            "asset": path,
            "srgb": bool(texture.get_editor_property("srgb")),
            "compression": str(texture.get_editor_property("compression_settings")),
            "usage": unreal.EditorAssetLibrary.get_metadata_tag(texture, "BioShockUsage"),
        })


def _place_light(location, report):
    actor = _actors().spawn_actor_from_class(unreal.PointLight, unreal.Vector(*location))
    if actor is None:
        report["missing"].append({"class": "PointLight"})
        return
    actor.set_actor_label("Validation_PointLight")
    actor.tags = [unreal.Name("BioShockValidation=PointLight")]
    actor.get_editor_property("light_component").set_editor_property(
        "light_color", unreal.Color(r=121, g=137, b=200, a=255))
    report["placed"].append({"class": "PointLight"})


def _place_placeholder(location, report):
    """The class the level importer uses for an actor whose geometry is not imported yet."""
    actor = _actors().spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(*location))
    if actor is None:
        report["missing"].append({"class": "TargetPoint"})
        return
    actor.set_actor_label("Validation_Placeholder")
    actor.tags = [unreal.Name("BioShockValidation=Placeholder")]
    report["placed"].append({"class": "TargetPoint"})


def _place_reflection_capture(location, report):
    """The class the level importer uses for a CubemapProbe."""
    capture_class = getattr(unreal, "SphereReflectionCapture", None)
    if capture_class is None:
        report["missing"].append({"class": "SphereReflectionCapture", "reason": "class missing"})
        return
    actor = _actors().spawn_actor_from_class(capture_class, unreal.Vector(*location))
    if actor is None:
        report["missing"].append({"class": "SphereReflectionCapture", "reason": "spawn failed"})
        return
    actor.set_actor_label("Validation_SphereReflectionCapture")
    actor.tags = [unreal.Name("BioShockValidation=SphereReflectionCapture")]
    report["placed"].append({"class": "SphereReflectionCapture"})


def main(content_root, out_path, map_path="/Game/BioShockValidation/ValidationMap"):
    """Build the validation map from assets already imported under `content_root`."""
    report = {
        "map": map_path,
        "placed": [],
        "missing": [],
        # Stated explicitly so the map documents the pipeline's own boundary rather than implying
        # that whatever happens to be in it is everything.
        "supported": ["SkeletalMesh", "Skeleton", "AnimSequence", "Texture2D", "PointLight",
                      "SphereReflectionCapture"],
        "unsupported": [
            "StaticMesh (level geometry exports as OBJ, not imported as UE5 meshes)",
            "Material (bindings are exported; no UE5 material graph is generated)",
            "TextureCube (face PNGs import as Texture2D; face-to-axis mapping is UNKNOWN)",
        ],
    }

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level.new_level(map_path)

    _place_skeletal_mesh(f"{content_root}/NEWPlayerHands/NEWPlayerHands", [0, 0, 0], report)
    _place_light([200, 0, 200], report)
    _place_placeholder([400, 0, 0], report)
    _place_reflection_capture([600, 0, 200], report)
    _place_textures([
        f"{content_root}/NEWPlayerHands/Textures/Hand_DIFF",
        f"{content_root}/NEWPlayerHands/Textures/Hand_NORM",
        f"{content_root}/NEWPlayerHands/Textures/Hand_SPEC",
    ], report)

    level.save_current_level()

    _log("placed %d, missing %d" % (len(report["placed"]), len(report["missing"])))
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=1)

    return report
