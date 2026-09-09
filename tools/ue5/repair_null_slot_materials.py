"""Kill every checkerboard (WorldGridMaterial) / null material slot in the slice.

Two causes:
  * meshes whose real material was never imported (SecurityCameraSmall, tommygun ammo pickups,
    AI pistol / TommyGun pickup, Steinman banners — rig / weapon-def paths skip material export);
  * meshes with a stale extra render section the geometry no longer fills, so slot 1 falls back
    to WorldGridMaterial (stair faces, seen as "green grates with missing squares").

For a mesh where at least one slot has a real material, the empty / grid slots are set to that
material (a prop is effectively one material). Where every slot is empty, a name-based fallback
(ammo master / alan_metal) applies. Proper fix — bind the real per-section materials — is
tracked under the fidelity pass (tasks/w12).

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
    (re.compile(r"banner|resurrection|resstation|vita", re.IGNORECASE), _METAL),
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
        seen_meshes = set()
        for actor in actors.get_all_level_actors():
            # Plain StaticMeshActors AND non-StaticMeshActor actors that carry a mesh component
            # (AShockSecurityCamera, AShockVitaChamber, banners, ...) — the null-slot fix has to
            # reach those too (R0.2).
            comp = None
            if isinstance(actor, unreal.StaticMeshActor):
                comp = actor.static_mesh_component
            else:
                comps = actor.get_components_by_class(unreal.StaticMeshComponent)
                comp = comps[0] if comps else None
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            if _MODEL_ASSET.match(name) or name in seen_meshes:
                continue  # compiled-world shell slot 0 is the zoning face, intentionally null

            slots = list(mesh.get_editor_property("static_materials"))
            count = max(1, len(slots))

            def _bad(m):
                return m is None or "WorldGrid" in m.get_name()

            asset_mats = [s.get_editor_property("material_interface") for s in slots]
            real = next((m for m in asset_mats if not _bad(m)), None)

            if real is not None:
                # At least one good slot: fill the empty / checkerboard slots on the asset.
                if any(_bad(m) for m in asset_mats):
                    for s in slots:
                        if _bad(s.get_editor_property("material_interface")):
                            s.set_editor_property("material_interface", real)
                    mesh.set_editor_property("static_materials", slots)
                    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                    entry["fixed"].append({"mesh": name, "material": real.get_name(),
                                           "how": "fill_from_sibling_slot"})
                seen_meshes.add(name)
                continue

            # Every slot empty / grid: name-based fallback, applied as a component override.
            if all(comp.get_material(i) is None
                   or "WorldGrid" in comp.get_material(i).get_name() for i in range(count)):
                mat = _material_for(name)
                if mat is None:
                    entry["skipped"].append(name)
                    seen_meshes.add(name)
                    continue
                actor.modify()
                comp.modify()
                for i in range(count):
                    comp.set_material(i, mat)
                entry["fixed"].append({"mesh": name, "material": mat.get_name(),
                                       "how": "name_fallback_override"})
            seen_meshes.add(name)
        level.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[null-slot-mats] %s" % json.dumps(
        {m["map"]: len(m.get("fixed", [])) for m in report["maps"]}))
    return report


if __name__ == "__main__":
    main()
