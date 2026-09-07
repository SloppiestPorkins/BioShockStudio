"""Fresh-load verification for repaired Medical LightBeamShader slots."""
from __future__ import annotations

import json
import os

import unreal

MAP_PATH = os.environ.get("BIOSHOCK_BEAM_MAP", "/Game/BioShockSlice/1-Medical")
MASTER_PATH = (
    "/Game/BioShockLevel/1-Medical/Materials/Masters/"
    "M_BioShock_LightBeam_Repaired_V1"
)
OUT = os.environ.get(
    "BIOSHOCK_BEAM_VERIFY_OUT",
    os.path.join(os.environ.get("TEMP", "."), "light_beam_verify.json"),
)
KEY_TAG_PREFIX = "BioShockKey=instance:"


def main():
    report = {"map": MAP_PATH, "checked": [], "failures": []}
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(MAP_PATH):
        raise RuntimeError("could not load %s" % MAP_PATH)

    master = unreal.EditorAssetLibrary.load_asset(MASTER_PATH)
    if not isinstance(master, unreal.Material):
        report["failures"].append("repaired master missing")
    else:
        report["master"] = MASTER_PATH
        if master.get_editor_property("blend_mode") != unreal.BlendMode.BLEND_ADDITIVE:
            report["failures"].append("master is not additive")
        if master.get_editor_property("shading_model") != unreal.MaterialShadingModel.MSM_UNLIT:
            report["failures"].append("master is not unlit")

    for actor in unreal.get_editor_subsystem(
            unreal.EditorActorSubsystem).get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        source = next(
            (str(tag)[len(KEY_TAG_PREFIX):].split(":", 1)[0] for tag in actor.tags
             if str(tag).startswith(KEY_TAG_PREFIX)),
            "",
        )
        mesh = actor.static_mesh_component.static_mesh
        if not source or mesh is None or "light_beam" not in mesh.get_name().lower():
            continue
        material = actor.static_mesh_component.get_material(0)
        path = material.get_path_name() if material else None
        parent = (
            material.get_editor_property("parent")
            if isinstance(material, unreal.MaterialInstanceConstant) else None
        )
        origin, extent = actor.get_actor_bounds(False)
        report["checked"].append({
            "actor": actor.get_actor_label(),
            "source": source,
            "material": path,
            "parent": parent.get_path_name() if parent else None,
            "origin": [origin.x, origin.y, origin.z],
            "extent": [extent.x, extent.y, extent.z],
        })
        if material is None:
            report["failures"].append("%s has null slot 0" % actor.get_actor_label())
        elif parent is None or parent.get_path_name() != master.get_path_name():
            report["failures"].append(
                "%s does not use repaired non-black master" % actor.get_actor_label())

    if len(report["checked"]) != 14:
        report["failures"].append(
            "checked %d beam actors (want 14)" % len(report["checked"]))
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"]:
        raise RuntimeError("light beam verify:\n- " + "\n- ".join(report["failures"]))
    return report


if __name__ == "__main__":
    main()
