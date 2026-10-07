"""Apply the manifest's per-actor material overrides (BioShock `Skins`) to a map's placed actors.

import_level places each StaticMeshActor with its mesh's own materials, and nothing applied
`actors[].materialOverrides`. 410 of Medical's static mesh actors carry them, which is why posters,
the handbag and others showed the wrong texture in the live view (7 Oct 2026). Overrides are in slot
order (Skins[i] replaces material i); each names a BioShock material whose instance the material
pass already made as MI_<objectName>. Texture-only overrides with no MI are reported, not guessed.

Env:
  BIOSHOCK_OVERRIDE_MAP  map (default /Game/BioShockLive/1-Medical_Baked -- the live-view copy, not the slice)
  BIOSHOCK_LEVEL_JSON    manifest (default Exports/slice/1-Medical/1-Medical.ue5-level.json)

Run: python tools/ue5/ue_run.py tools/ue5/apply_material_overrides.py --timeout 1800

Pipeline: entry-point -- live-renderer map preparation.
"""
from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_OVERRIDE_MAP", "/Game/BioShockLive/1-Medical_Baked")
MI_DIRS = ["/Game/BioShockLevel/1-Medical/Materials", "/Game/BioShockSlice/Content/1-Medical/Materials",
           "/Game/BioShockSlice/Content/Meshes/PropMat"]
KEY_TAG = "BioShockKey="


def main():
    manifest_path = os.environ.get("BIOSHOCK_LEVEL_JSON") or os.path.join(
        os.path.dirname(unreal.Paths.get_project_file_path()), "Exports", "slice", "1-Medical", "1-Medical.ue5-level.json")
    with open(manifest_path, encoding="utf-8") as fh:
        manifest = json.load(fh)
    overrides = {a["key"]: a["materialOverrides"] for a in manifest["actors"] if a.get("materialOverrides")}

    mi_cache = {}

    def find_mi(name):
        if name not in mi_cache:
            mi_cache[name] = None
            for d in MI_DIRS:
                path = "%s/MI_%s" % (d, name)
                if unreal.EditorAssetLibrary.does_asset_exist(path):
                    mi_cache[name] = unreal.EditorAssetLibrary.load_asset(path)
                    break
        return mi_cache[name]

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(MAP):
        raise RuntimeError("could not load %s" % MAP)
    report = {"actorsWithOverrides": 0, "slotsApplied": 0, "noMi": {}, "noSlot": 0}
    for actor in unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors():
        key = next((str(t)[len(KEY_TAG):] for t in actor.tags if str(t).startswith(KEY_TAG)), None)
        # Props placed from manifest `instances` are tagged instance:<actorKey>:<asset>.
        if key and key.startswith("instance:"):
            key = key[len("instance:"):].split(":", 1)[0]
        if not key or key not in overrides:
            continue
        comps = actor.get_components_by_class(unreal.StaticMeshComponent)
        if not comps:
            continue
        comp = comps[0]
        report["actorsWithOverrides"] += 1
        for slot, ov in enumerate(overrides[key]):
            name = ov.get("objectName")
            if not name or name == "None":
                continue
            if slot >= comp.get_num_materials():
                report["noSlot"] += 1
                continue
            mi = find_mi(name)
            if mi is None:
                report["noMi"][name] = report["noMi"].get(name, 0) + 1
                continue
            comp.set_material(slot, mi)
            report["slotsApplied"] += 1
    level.save_current_level()
    out = os.path.join(os.environ.get("TEMP", "."), "apply_material_overrides.json")
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=1)
    unreal.log("MATERIAL_OVERRIDES actors=%d slots=%d noMi=%d noSlot=%d -> %s" % (
        report["actorsWithOverrides"], report["slotsApplied"], sum(report["noMi"].values()), report["noSlot"], out))


main()
