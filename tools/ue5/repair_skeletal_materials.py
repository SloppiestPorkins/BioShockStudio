"""Audit and, where needed, bind manifest materials to placed `kind: SkeletalMesh` assets.

FINDS NOTHING TO FIX ON 1-Medical TODAY: all 28 placed assets report already bound. Kept as an
audit - it answers "is any placed mesh missing its material" in one headless run.

It was written to fix a bug that did not exist. The screen probe reported

    u=0.50 v=0.50  actor=MedicalLoadRoomDoor  mesh=LoadRoomDoorMESH_20894  material=none

and I believed it, because it fit a real gap I could see in the code: `_assign_asset_material`
only ever writes `static_materials`, so a genuine SkeletalMesh would import unbound. But the probe
was indexing materials by `Hit.ElementIndex`, which is a physics element and not a material
section - on a complex-collision trace it matches no slot at all. The door's material had been
bound the whole time. Two things had to be wrong together for the false reading to look credible,
which is exactly when a plausible mechanism is most dangerous: it explains the symptom, so you
stop looking. Confirm the symptom is real before explaining it.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_skeletal_materials.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_SKELMAT_MANIFEST      path to <map>.ue5-level.json (required)
  BIOSHOCK_SKELMAT_CONTENT_ROOT  content root the meshes were imported under
  BIOSHOCK_SKELMAT_DRY           "1" to report what it would bind and change nothing

Pipeline: retired -- an audit that found nothing to fix on 1-Medical; kept for the record only.
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_bioshock  # noqa: E402

MANIFEST = os.environ.get("BIOSHOCK_SKELMAT_MANIFEST", "")
CONTENT_ROOT = os.environ.get("BIOSHOCK_SKELMAT_CONTENT_ROOT", "/Game/BioShockLevel")
DRY = os.environ.get("BIOSHOCK_SKELMAT_DRY", "0") == "1"
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "repair_skeletal_materials.json")


def _material_lookup(manifest, destination):
    """materialKey -> MI asset, for the material instances a prior import already created."""
    by_key = {}
    for material in manifest.get("materials") or []:
        name = import_bioshock._safe_name(material.get("name") or "")
        path = "%s/Materials/MI_%s" % (destination, name)
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            mi = unreal.EditorAssetLibrary.load_asset(path)
            if mi is not None:
                by_key[material["key"]] = mi
    return by_key


def _mesh_asset_path(asset):
    """Where _import_asset_meshes / _import_skeletal_rigs put this asset."""
    stem = "%s_%s" % (
        import_bioshock._safe_name(asset.get("name") or ""), asset.get("exportIndex"))
    return "%s/Meshes/%s" % (CONTENT_ROOT, stem)


def main():
    report = {"contentRoot": CONTENT_ROOT, "dryRun": DRY, "assets": [],
              "bound": 0, "alreadyBound": 0, "missingMesh": 0, "noMaterial": 0}
    with open(MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    destination = "%s/%s" % (CONTENT_ROOT, manifest.get("package") or "Level")
    lookup = _material_lookup(manifest, destination)
    report["materialsAvailable"] = len(lookup)

    placed = {i["asset"] for i in (manifest.get("instances") or [])}

    for asset in manifest.get("assets") or []:
        if asset.get("kind") != "SkeletalMesh" or asset["key"] not in placed:
            continue
        sections = asset.get("sections") or []
        keys = [s.get("materialKey") for s in sections]
        if not any(keys):
            report["noMaterial"] += 1
            continue

        path = _mesh_asset_path(asset)
        entry = {"asset": asset["key"], "path": path, "sections": len(sections)}
        if not unreal.EditorAssetLibrary.does_asset_exist(path):
            entry["status"] = "mesh missing"
            report["missingMesh"] += 1
            report["assets"].append(entry)
            continue

        mesh = unreal.EditorAssetLibrary.load_asset(path)

        # These are `kind: SkeletalMesh` in the manifest - that is their type in the SOURCE game -
        # but they arrive here as StaticMesh, because _import_asset_meshes imports the exported
        # .obj and the FBX rig path only runs for explicitly named rigs. So the asset type on disk
        # is what decides which property to write, not the manifest's idea of it.
        if isinstance(mesh, unreal.SkeletalMesh):
            slot_type, prop = unreal.SkeletalMaterial, "materials"
        elif isinstance(mesh, unreal.StaticMesh):
            slot_type, prop = unreal.StaticMaterial, "static_materials"
        else:
            entry["status"] = "unsupported asset type (%s)" % type(mesh).__name__
            report["assets"].append(entry)
            continue
        entry["assetType"] = type(mesh).__name__

        current = mesh.get_editor_property(prop) or []
        entry["existingSlots"] = len(current)
        entry["existingBound"] = sum(
            1 for m in current if m.get_editor_property("material_interface") is not None)
        if entry["existingBound"] and entry["existingBound"] >= len(sections):
            entry["status"] = "already bound"
            report["alreadyBound"] += 1
            report["assets"].append(entry)
            continue

        # Fresh SkeletalMaterial structs, one per manifest section, in section order - the same
        # positional contract _assign_asset_material relies on for static meshes. Mutating the
        # structs get_editor_property hands back reports success and persists nothing.
        rebuilt = []
        bound = 0
        for index, section in enumerate(sections):
            slot = slot_type()
            slot.set_editor_property("material_slot_name", unreal.Name("BioShock_%d" % index))
            mi = lookup.get(section.get("materialKey"))
            if mi is not None:
                slot.set_editor_property("material_interface", mi)
                bound += 1
            rebuilt.append(slot)

        entry["wouldBind"] = bound
        if not bound:
            entry["status"] = "no MI resolved"
            report["assets"].append(entry)
            continue

        if not DRY:
            mesh.set_editor_property(prop, rebuilt)
            after = mesh.get_editor_property(prop) or []
            entry["boundAfter"] = sum(
                1 for m in after if m.get_editor_property("material_interface") is not None)
            unreal.EditorAssetLibrary.save_loaded_asset(mesh)
            entry["status"] = "bound"
            report["bound"] += 1
        else:
            entry["status"] = "would bind"

        report["assets"].append(entry)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[skel-mat] bound=%d alreadyBound=%d missingMesh=%d noMaterial=%d" % (
        report["bound"], report["alreadyBound"], report["missingMesh"], report["noMaterial"]))
    return report


if __name__ == "__main__":
    main()
