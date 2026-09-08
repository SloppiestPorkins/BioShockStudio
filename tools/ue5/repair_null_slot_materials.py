"""Assign a resolved material to the ~19 slice meshes whose slot 0 is null.

These render as UE's grey checkerboard (WorldGridMaterial) — the "missing floor grate / missing
geometry" a player reports. Their real materials were never imported: SecurityCameraSmall,
tommygun ammo pickups, AI pistol / TommyGun pickup meshes, and the Steinman banners all come
from import paths (rigs / weapon defs) that skipped material export.

This is a stopgap so nothing renders as checkerboard. The proper fix — export and bind their
real materials — is tracked under the fidelity pass (tasks/w12).

Env:
  BIOSHOCK_NULLSLOT_MAPS  comma-separated maps (default /Game/BioShockSlice/1-Medical)
"""
from __future__ import annotations

import json
import os
import re

import unreal

MAPS = [v.strip() for v in os.environ.get(
    "BIOSHOCK_NULLSLOT_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if v.strip()]
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_null_slot_materials.json")

_MODEL_ASSET = re.compile(r"^Model\d+_\d+$")

# Best-guess resolved material per mesh-name pattern (all exist in the slice content).
_MAT_ROOT = "/Game/BioShockSlice/Content/Materials/Masters"
_METAL = _MAT_ROOT + "/M_BioShock_Shader_alan_metal_mat_opaque_V5"
_AMMO = _MAT_ROOT + "/M_BioShock_Shader_Ammo_Pickup_JHP_Shader_opaque_V5"
_RULES = [
    (re.compile(r"ammo|bullet|buckshot", re.IGNORECASE), _AMMO),
    (re.compile(r"seccamera|seccam|camera|pistol|tommygun|wp_ai|pu_|weapon",
                re.IGNORECASE), _METAL),
    (re.compile(r"banner", re.IGNORECASE), _METAL),
]


def _material_for(name):
    for pattern, path in _RULES:
        if pattern.search(name):
            mat = unreal.EditorAssetLibrary.load_asset(path)
            if isinstance(mat, unreal.MaterialInterface):
                return mat
    mat = unreal.EditorAssetLibrary.load_asset(_METAL)
    return mat if isinstance(mat, unreal.MaterialInterface) else None


def main():
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    report = {"maps": []}

    for map_path in MAPS:
        entry = {"map": map_path, "fixed": [], "skipped": []}
        if not level.load_level(map_path):
            entry["error"] = "could not load"
            report["maps"].append(entry)
            continue
        for actor in actors.get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            if _MODEL_ASSET.match(name):
                continue  # compiled-world shell slot 0 is the zoning face, intentionally null
            slots = mesh.get_editor_property("static_materials")
            count = max(1, len(slots))
            if any(comp.get_material(i) is not None for i in range(count)):
                continue
            mat = _material_for(name)
            if mat is None:
                entry["skipped"].append(name)
                continue
            actor.modify()
            comp.modify()
            for i in range(count):
                comp.set_material(i, mat)
            entry["fixed"].append({"mesh": name, "material": mat.get_name()})
        level.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[null-slot-mats] %s" % json.dumps(
        {m["map"]: len(m.get("fixed", [])) for m in report["maps"]}))
    return report


if __name__ == "__main__":
    main()
