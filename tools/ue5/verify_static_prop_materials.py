"""Assert a multi-material static prop actually has one render section per material slot.

This exists because `_assign_asset_material` used to report success while every triangle still
sampled slot 0. The Python side built one `StaticMaterial` per manifest section and wrote the
array in order; that only defines what each *slot index* means. Which slot each triangle uses
comes from the mesh's own LOD sections, baked by the OBJ importer from `usemtl` groups. Meshes
first imported before `BuildAssetObj` emitted those groups stayed at 1 section forever, because
`_import_asset_meshes` skipped existing assets and only re-ran slot assignment.

Measured 4 Sept 2026 on 1-Medical Content/Meshes: 792 of 793 multi-slot StaticMeshes had
N slots but 1 section / 1 polygon group. Fresh import of `ad_horizontal_3702.obj` produced 2/2.
Symptom in PIE: windows, ad frames, etc. show the first material on every slot.

Two checks, deliberately both:

  a) STRUCTURAL — after `_import_asset_meshes` on a known multi-material prop, LOD0 section
     count and mesh-description polygon-group count equal the manifest section count. Slot
     count alone is not enough (that is the blind spot this bug lived in).

  b) BINDING — when the manifest names two different resolved material keys, the materials
     bound to those slots are not the same object. Catches "sections exist but assignment
     still pointed everything at slot 0's MI".

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/run_static_prop_materials.py \
    -unattended -nopause -nosplash -nullrhi
Env:
  BIOSHOCK_PROP_MAT_MANIFEST   path to <map>.ue5-level.json
  BIOSHOCK_PROP_MAT_CONTENT    content root (default /Game/BioShockSlice/Content)
  BIOSHOCK_PROP_MAT_ASSET      manifest asset name to check (default ad_horizontal)
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_level  # noqa: E402

MANIFEST = os.environ.get(
    "BIOSHOCK_PROP_MAT_MANIFEST",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
)
CONTENT_ROOT = os.environ.get("BIOSHOCK_PROP_MAT_CONTENT", "/Game/BioShockSlice/Content")
ASSET_NAME = os.environ.get("BIOSHOCK_PROP_MAT_ASSET", "ad_horizontal")


def _polygon_group_count(mesh):
    smd = mesh.get_static_mesh_description(0)
    if smd is None:
        return None
    return int(smd.get_polygon_group_count())


def _materials_by_key_from_disk(manifest, content_root):
    """Reuse already-created MI_ assets; do not reimport textures."""
    import import_bioshock

    package = manifest.get("package") or "Level"
    destinations = [
        "%s/%s" % (content_root, package),
        content_root,
    ]
    by_key = {}
    for material in manifest.get("materials") or []:
        stem = import_bioshock._safe_name(material.get("name") or "")
        for dest in destinations:
            path = "%s/Materials/MI_%s" % (dest, stem)
            if unreal.EditorAssetLibrary.does_asset_exist(path):
                mi = unreal.EditorAssetLibrary.load_asset(path)
                if mi is not None:
                    by_key[material["key"]] = mi
                    break
    return by_key


def _find_asset(manifest, name):
    for asset in manifest.get("assets") or []:
        if asset.get("name") == name:
            return asset
    return None


def main(out_path):
    report = {
        "assetName": ASSET_NAME,
        "contentRoot": CONTENT_ROOT,
        "manifest": MANIFEST,
        "failures": [],
        "error": None,
    }
    with open(MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    asset = _find_asset(manifest, ASSET_NAME)
    if asset is None:
        report["failures"].append("manifest has no asset named %s" % ASSET_NAME)
        _write(report, out_path)
        return report

    sections = asset.get("sections") or []
    report["manifestSections"] = len(sections)
    if len(sections) < 2:
        report["failures"].append(
            "%s has fewer than 2 manifest sections — pick a multi-material canary" % ASSET_NAME)
        _write(report, out_path)
        return report

    keys = [s.get("materialKey") for s in sections]
    distinct_keys = sorted({k for k in keys if k})
    report["distinctMaterialKeys"] = distinct_keys
    if len(distinct_keys) < 2:
        report["failures"].append(
            "%s sections do not resolve to 2+ distinct material keys" % ASSET_NAME)

    materials_by_key = _materials_by_key_from_disk(manifest, CONTENT_ROOT)
    report["materialsResolved"] = len(materials_by_key)
    for key in distinct_keys:
        if key not in materials_by_key:
            report["failures"].append("no MI on disk for materialKey %s" % key)

    # Tiny one-asset manifest so `_import_asset_meshes` is the path under test, including the
    # reimport-on-section-mismatch branch against the already-imported (likely collapsed) mesh.
    mini = {
        "package": manifest.get("package"),
        "assets": [asset],
        "materials": manifest.get("materials") or [],
    }
    import_report = {"skipped": 0}
    manifest_dir = os.path.dirname(MANIFEST)
    meshes = import_level._import_asset_meshes(
        mini, manifest_dir, CONTENT_ROOT, import_report, materials_by_key=materials_by_key)
    report["import"] = import_report

    mesh = meshes.get(asset["key"])
    if mesh is None:
        report["failures"].append("import produced no StaticMesh for %s" % asset["key"])
        _write(report, out_path)
        return report

    nsec = int(mesh.get_num_sections(0))
    npoly = _polygon_group_count(mesh)
    slots = mesh.get_editor_property("static_materials") or []
    report["mesh"] = {
        "path": mesh.get_path_name(),
        "numSections": nsec,
        "polygonGroupCount": npoly,
        "slotCount": len(slots),
        "slots": [],
    }
    bound = []
    for index, slot in enumerate(slots):
        mi = slot.get_editor_property("material_interface")
        name = mi.get_name() if mi else None
        path = mi.get_path_name() if mi else None
        report["mesh"]["slots"].append({
            "index": index,
            "slotName": str(slot.get_editor_property("material_slot_name")),
            "material": name,
            "materialPath": path,
        })
        bound.append(path)

    if nsec != len(sections):
        report["failures"].append(
            "LOD0 section count %d != manifest sections %d" % (nsec, len(sections)))
    if npoly is not None and npoly != len(sections):
        report["failures"].append(
            "polygon group count %d != manifest sections %d" % (npoly, len(sections)))
    if len(slots) != len(sections):
        report["failures"].append(
            "static_materials length %d != manifest sections %d" % (len(slots), len(sections)))

    # Binding check: first two distinct keys must land on different MI paths when both resolve.
    resolved_paths = []
    for section in sections:
        key = section.get("materialKey")
        mi = materials_by_key.get(key)
        if mi is not None:
            resolved_paths.append(mi.get_path_name())
    if len(set(resolved_paths)) >= 2:
        # Slots corresponding to those sections must not all be the first material.
        slot_paths = [s["materialPath"] for s in report["mesh"]["slots"][:len(sections)]]
        if len(set(p for p in slot_paths if p)) < 2:
            report["failures"].append(
                "slot materials are not distinct after assign — all triangles would still share "
                "one look even with correct section counts")
        # And the mesh must expose more than one get_material entry that is non-null and distinct
        # for the section range (catches section-count OK but MaterialIndex all zero).
        used = []
        for i in range(nsec):
            try:
                mi = mesh.get_material(i)
            except Exception:  # noqa: BLE001
                mi = None
            used.append(mi.get_path_name() if mi else None)
        report["mesh"]["getMaterial"] = used
        if len(set(p for p in used if p)) < 2:
            report["failures"].append(
                "get_material(0..%d) is not distinct — sections likely all sample one slot"
                % (nsec - 1))

    report["ok"] = not report["failures"]
    _write(report, out_path)
    unreal.log("[verify-prop-mats] ok=%s failures=%s" % (
        report["ok"], json.dumps(report["failures"])))
    return report


def _write(report, out_path):
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, default=str)


if __name__ == "__main__":
    out = os.environ.get(
        "BIOSHOCK_PROP_MAT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "verify_static_prop_materials.json"),
    )
    result = main(out)
    if result.get("failures"):
        raise SystemExit(1)
