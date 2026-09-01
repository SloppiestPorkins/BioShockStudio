"""One-off diagnostic: why does 1-Medical render grey? Lights + a sample of wall materials.

Run headless:
  UnrealEditor-Cmd BioShockUE5.uproject -run=pythonscript -script=tools/ue5/probe_medical_render.py -unattended -nopause -nosplash
Writes tools/ue5/_reports/probe_medical_render.json. Read-only (no map save).
"""

from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_PROBE_MAP", "/Game/BioShockLevel/1-Medical")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_reports", "probe_medical_render.json")


def _lvl():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def main():
    report = {"map": MAP, "lights": [], "sky": [], "wallSamples": [], "error": None}
    if not _lvl().load_level(MAP):
        report["error"] = "could not load %s" % MAP
        _write(report)
        return report

    world = unreal.EditorLevelLibrary.get_editor_world()
    ws = world.get_world_settings()
    report["forceNoPrecomputedLighting"] = bool(ws.get_editor_property("force_no_precomputed_lighting"))

    counts = {}
    for actor in _actors().get_all_level_actors():
        cn = actor.get_class().get_name()
        counts[cn] = counts.get(cn, 0) + 1

        if isinstance(actor, unreal.DirectionalLight):
            c = actor.get_editor_property("directional_light_component")
            report["lights"].append({
                "type": "DirectionalLight",
                "label": actor.get_actor_label(),
                "intensity": float(c.get_editor_property("intensity")) if c else None,
                "mobility": str(c.get_editor_property("mobility")) if c else None,
                "rotation": [actor.get_actor_rotation().pitch, actor.get_actor_rotation().yaw],
                "tags": [str(t) for t in actor.tags],
            })
        elif isinstance(actor, unreal.SkyLight):
            c = actor.get_editor_property("light_component")
            entry = {
                "type": "SkyLight", "label": actor.get_actor_label(),
                "tags": [str(t) for t in actor.tags],
            }
            if c:
                for prop in ("intensity", "mobility", "real_time_capture", "source_type",
                             "lower_hemisphere_is_black"):
                    try:
                        entry[prop] = str(c.get_editor_property(prop))
                    except Exception as exc:  # noqa: BLE001
                        entry[prop] = "ERR:%s" % exc
            report["sky"].append(entry)
        elif isinstance(actor, (unreal.PointLight, unreal.SpotLight, unreal.RectLight)):
            c = actor.get_editor_property("light_component")
            report["lights"].append({
                "type": actor.get_class().get_name(),
                "label": actor.get_actor_label(),
                "intensity": float(c.get_editor_property("intensity")) if c else None,
            })

    report["skyAtmospherePresent"] = counts.get("SkyAtmosphere", 0) > 0
    report["exponentialHeightFogPresent"] = counts.get("ExponentialHeightFog", 0) > 0
    report["postProcessVolumePresent"] = counts.get("PostProcessVolume", 0) > 0
    report["directionalLightCount"] = counts.get("DirectionalLight", 0)
    report["pointLightCount"] = counts.get("PointLight", 0)
    report["skyLightCount"] = counts.get("SkyLight", 0)

    # Sample "wall-like" static meshes: big, name hints at architecture.
    hints = ("wall", "floor", "ceiling", "trim", "pillar", "column", "arch", "room", "hall")
    n = 0
    for actor in _actors().get_all_level_actors():
        if n >= 12 or not isinstance(actor, unreal.StaticMeshActor):
            continue
        label = actor.get_actor_label().lower()
        if not any(h in label for h in hints):
            continue
        smc = actor.static_mesh_component
        mesh = smc.get_editor_property("static_mesh")
        mats = smc.get_materials() or []
        sample = {"label": actor.get_actor_label(),
                  "mesh": mesh.get_path_name() if mesh else None,
                  "mobility": str(smc.get_editor_property("mobility")),
                  "slots": []}
        for i, m in enumerate(mats):
            edit = unreal.MaterialEditingLibrary
            base = edit.get_material_instance_texture_parameter_value(m, "BaseColor") if m else None
            parent = None
            if isinstance(m, unreal.MaterialInstanceConstant):
                p = m.get_editor_property("parent")
                parent = p.get_path_name() if p else None
            tex_info = None
            if base:
                tex_info = {
                    "path": base.get_path_name(),
                    "sizeX": base.blueprint_get_size_x() if hasattr(base, "blueprint_get_size_x") else None,
                    "sizeY": base.blueprint_get_size_y() if hasattr(base, "blueprint_get_size_y") else None,
                }
            sample["slots"].append({
                "slot": i,
                "material": m.get_path_name() if m else None,
                "parent": parent,
                "baseColorTexture": tex_info,
            })
        report["wallSamples"].append(sample)
        n += 1

    _write(report)
    unreal.log("[probe] wrote %s" % OUT)
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
