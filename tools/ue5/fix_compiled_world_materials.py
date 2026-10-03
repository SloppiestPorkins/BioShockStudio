"""Repair the "compiled world" architecture mesh so its walls/floors/ceilings are textured.

Why this exists: the level exporter writes the compiled-CSG world geometry as one asset whose
`.obj` carries no `usemtl` group markers, even though the manifest lists that same mesh with
dozens of material sections. Unreal therefore imports it as a single section with no material,
and the entire architectural shell renders as flat grey. See BuildAssetObj in
LevelSceneExporter.cs (the exporter-side fix) — this is the content-side repair that does not
need a re-import of every map.

What it does, per map:
  1. Read the map's `.ue5-level.json` manifest, find the BuiltWorld asset + its section table.
  2. Rewrite that asset's `.obj` next to the manifest, inserting one `usemtl BioShock_<n>` per
     section at the correct face boundary (face K covers manifest index K*3, sections are
     contiguous and in index order — proven against BuildAssetObj's Sections.Count==0 branch).
  3. Write a sibling `.mtl` naming BioShock_0..N (Unreal only uses these as slot names).
  4. Re-import the `.obj` over the existing `/Game/BioShockLevel/Meshes/<stem>` asset.
  5. Assign each section its manifest material (reuses import_level._assign_asset_material).
  6. Save the mesh + re-save maps that place it.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_compiled_world_materials.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_CWFIX_MANIFEST   path to <map>.ue5-level.json (required)
  BIOSHOCK_CWFIX_MAPS       comma-sep /Game map paths to re-save (optional)
  BIOSHOCK_CWFIX_DRY        "1" to rewrite the obj/mtl and report but not touch UE

Pipeline: one-off -- the exporter now writes one usemtl group per section (BuildAssetObj) and
import_level imports them; this patched maps imported before that.
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_bioshock  # noqa: E402
import import_level  # noqa: E402

MANIFEST = os.environ.get("BIOSHOCK_CWFIX_MANIFEST", "")
MAPS = [m.strip() for m in os.environ.get("BIOSHOCK_CWFIX_MAPS", "").split(",") if m.strip()]
DRY = os.environ.get("BIOSHOCK_CWFIX_DRY", "0") == "1"
CONTENT_ROOT = os.environ.get("BIOSHOCK_CWFIX_CONTENT_ROOT", "/Game/BioShockLevel")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_reports", "fix_compiled_world_materials.json")


def _find_builtworld_assets(manifest):
    return [a for a in (manifest.get("assets") or [])
            if a.get("kind") == "BuiltWorld" and a.get("file") and a.get("sections")]


def _rewrite_obj_with_sections(obj_path, sections):
    """Insert `usemtl BioShock_<n>` markers into a no-group OBJ, by face/section index range.

    BuildAssetObj (Sections.Count==0 branch) writes every triangle as one `f a/a b/b c/c` line
    in raw index order, so the K-th face line spans manifest indices [K*3, K*3+3). A section with
    (firstIndex, triangleCount) owns face lines [firstIndex/3, firstIndex/3 + triangleCount).
    """
    with open(obj_path, "r", encoding="utf-8") as handle:
        lines = handle.readlines()

    has_mtllib = any(l.lstrip().startswith("mtllib ") for l in lines)
    has_usemtl = any(l.lstrip().startswith("usemtl ") for l in lines)
    if has_mtllib and has_usemtl:
        return {"faceLines": sum(1 for l in lines if l.lstrip().startswith("f ")),
                "usemtlInserted": 0, "note": "obj already has mtllib + usemtl — left as-is"}

    # UE5's OBJ importer drops `usemtl` groups when there is no `mtllib`/`.mtl` beside them, so a
    # section table in the file still imports as one material slot. Guarantee both.
    stem = os.path.splitext(os.path.basename(obj_path))[0]

    # face-line index -> section number (only used when usemtl is missing entirely)
    starts = {}
    for n, s in enumerate(sections):
        starts[int(s["firstIndex"]) // 3] = n

    out = []
    face_i = 0
    inserted_mtllib = False
    inserted_usemtl = 0
    for line in lines:
        stripped = line.lstrip()
        if not inserted_mtllib and (stripped.startswith("v ") or stripped.startswith("o ")):
            out.append("mtllib %s.mtl\n" % stem)
            inserted_mtllib = True
        if not has_usemtl and stripped.startswith("f "):
            if face_i in starts:
                out.append("usemtl BioShock_%d\n" % starts[face_i])
                inserted_usemtl += 1
            face_i += 1
        out.append(line)
    if not inserted_mtllib:
        out.insert(0, "mtllib %s.mtl\n" % stem)

    with open(obj_path, "w", encoding="utf-8") as handle:
        handle.writelines(out)

    mtl_path = os.path.join(os.path.dirname(obj_path), stem + ".mtl")
    with open(mtl_path, "w", encoding="utf-8") as handle:
        handle.write("# slot names only - Unreal assigns real materials by position\n")
        for n in range(len(sections)):
            handle.write("newmtl BioShock_%d\nKd 0.5 0.5 0.5\n" % n)

    return {
        "faceLines": sum(1 for l in lines if l.lstrip().startswith("f ")),
        "hadUsemtl": has_usemtl, "hadMtllib": has_mtllib,
        "usemtlInserted": inserted_usemtl, "mtl": mtl_path,
    }


def _reimport_mesh(obj_path, stem):
    """Delete the stale asset, then import the fixed OBJ fresh.

    Re-importing over the existing asset (replace_existing) drives an Interchange path that
    touches the ContentBrowser and asserts in a headless commandlet; a fresh import after a
    delete stays on the safe path.
    """
    asset_path = "%s/Meshes/%s" % (CONTENT_ROOT, stem)
    if unreal.EditorAssetLibrary.does_asset_exist(asset_path):
        unreal.EditorAssetLibrary.delete_asset(asset_path)

    task = unreal.AssetImportTask()
    task.set_editor_property("filename", obj_path)
    task.set_editor_property("destination_path", "%s/Meshes" % CONTENT_ROOT)
    task.set_editor_property("destination_name", stem)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", False)
    task.set_editor_property("save", False)  # save=True drives a Slate toast that asserts headless
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    mesh = next((o for o in task.get_objects() if isinstance(o, unreal.StaticMesh)), None)
    if mesh is None:
        mesh = unreal.EditorAssetLibrary.load_asset(asset_path)
    if mesh is not None:
        _use_complex_collision(mesh)
    return mesh


def _use_complex_collision(mesh):
    """Trace level architecture against its own triangles, not an auto convex hull.

    An OBJ import defaults to CTF_USE_DEFAULT and auto-generates a single convex element. On a
    compiled world that hull is a solid blob enclosing the entire level: the player lands on its
    outer surface instead of the floor ("stuck in the air") and anything spawned inside it is
    inside solid geometry and squeezes out through the floor (ragdolls falling). Architecture
    wants complex-as-simple with no hulls at all.
    """
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False
    body.set_editor_property(
        "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
    try:
        agg = body.get_editor_property("agg_geom")
        agg.set_editor_property("convex_elems", [])
        agg.set_editor_property("box_elems", [])
        agg.set_editor_property("sphere_elems", [])
        body.set_editor_property("agg_geom", agg)
    except Exception as exc:  # noqa: BLE001 - the trace flag is the part that matters
        unreal.log_warning("[cw-fix] could not clear simple collision: %s" % exc)
    return True


def _ensure_invisible_material():
    """A fully-clipped material for compiled-world sections that name no texture at all.

    Section 0 of 1-Medical's shell is 619 triangles with `material: null, materialKey: null` - not
    the same thing as section 3, which names a real ZoningOnlyBrushMaterial. A UE2 BSP surface that
    carries no texture is a ZONE PORTAL: a large room-dividing plane the original game never draws.
    Left unassigned it renders as Unreal's default grey, which is the flat wedge that has been
    sitting across the corner of every captured frame.

    So these want to be INVISIBLE, not textured. Masked with a zero opacity mask clips every pixel
    while keeping the triangles present for collision, which is what a portal plane should be.
    """
    path = "%s/Materials/M_BioShock_Invisible" % CONTENT_ROOT
    # does_asset_exist first: load_asset on a missing asset logs at Error level, and a commandlet
    # treats any logged Error as a failed run - so the probe alone would fail an otherwise clean
    # repair the first time it is used in a content root.
    if unreal.EditorAssetLibrary.does_asset_exist(path):
        existing = unreal.EditorAssetLibrary.load_asset(path)
        if existing is not None:
            return existing

    factory = unreal.MaterialFactoryNew()
    material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
        "M_BioShock_Invisible", "%s/Materials" % CONTENT_ROOT, unreal.Material, factory)
    if material is None:
        return None

    material.set_editor_property("blend_mode", unreal.BlendMode.BLEND_MASKED)
    material.set_editor_property("two_sided", True)
    edit = unreal.MaterialEditingLibrary
    zero = edit.create_material_expression(
        material, unreal.MaterialExpressionConstant, -350, 0)
    zero.set_editor_property("r", 0.0)
    edit.connect_material_property(zero, "", unreal.MaterialProperty.MP_OPACITY_MASK)
    edit.recompile_material(material)
    unreal.EditorAssetLibrary.save_loaded_asset(material)
    return material


def _materials_by_key_from_existing(manifest, destination):
    """Resolve section materialKeys to the MI_* assets a prior import already created."""
    by_key = {}
    for material in manifest.get("materials") or []:
        name = import_bioshock._safe_name(material.get("name") or "")
        mi = unreal.EditorAssetLibrary.load_asset("%s/Materials/MI_%s" % (destination, name))
        if mi is not None:
            by_key[material["key"]] = mi
    return by_key


def main():
    report = {"manifest": MANIFEST, "dryRun": DRY, "builtWorlds": [], "mapsSaved": [], "error": None}
    if not MANIFEST or not os.path.isfile(MANIFEST):
        report["error"] = "manifest not found: %s" % MANIFEST
        _write(report)
        raise RuntimeError(report["error"])

    manifest_dir = os.path.dirname(os.path.abspath(MANIFEST))
    with open(MANIFEST, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    bw_assets = _find_builtworld_assets(manifest)
    report["builtWorldCount"] = len(bw_assets)
    if not bw_assets:
        report["error"] = "no BuiltWorld asset with sections in manifest"
        _write(report)
        raise RuntimeError(report["error"])

    destination = "%s/%s" % (CONTENT_ROOT, manifest.get("package") or "Level")
    materials_by_key = {}
    if not DRY:
        materials_by_key = _materials_by_key_from_existing(manifest, destination)
        report["materialsResolved"] = len(materials_by_key)

    for asset in bw_assets:
        obj_path = os.path.join(manifest_dir, asset["file"].replace("/", os.sep))
        stem = os.path.splitext(os.path.basename(obj_path))[0]
        entry = {"key": asset["key"], "stem": stem, "sections": len(asset["sections"]), "obj": obj_path}
        if not os.path.isfile(obj_path):
            entry["error"] = "obj missing"
            report["builtWorlds"].append(entry)
            continue

        entry["rewrite"] = _rewrite_obj_with_sections(obj_path, asset["sections"])

        if not DRY:
            mesh = _reimport_mesh(obj_path, stem)
            if mesh is None:
                entry["error"] = "re-import produced no StaticMesh"
            else:
                before = len(mesh.get_editor_property("static_materials") or [])
                import_level._assign_asset_material(mesh, asset, materials_by_key, report)

                # Fill the leftovers with the invisible material rather than leaving them on
                # Unreal's default grey. Scoped to the compiled world on purpose: here an empty
                # slot means the source surface named no texture, which means a zone portal.
                # Elsewhere an empty slot means something went wrong and should stay visible.
                invisible = _ensure_invisible_material()
                hidden = 0
                if invisible is not None:
                    # Build FRESH StaticMaterial structs rather than mutating the ones
                    # get_editor_property hands back. Mutating those and writing the array back
                    # reports success and changes nothing - the first version of this counted the
                    # assignments it intended and claimed sectionsHidden=1 while slot 0 stayed
                    # empty on disk. Constructing new structs is what _assign_asset_material does,
                    # and it is the pattern that actually persists.
                    rebuilt = []
                    for slot in mesh.get_editor_property("static_materials") or []:
                        fresh = unreal.StaticMaterial()
                        fresh.set_editor_property(
                            "material_slot_name", slot.get_editor_property("material_slot_name"))
                        bound = slot.get_editor_property("material_interface")
                        if bound is None:
                            bound = invisible
                            hidden += 1
                        fresh.set_editor_property("material_interface", bound)
                        rebuilt.append(fresh)
                    if hidden:
                        mesh.set_editor_property("static_materials", rebuilt)

                # Count what is actually bound now, by re-reading. A counter that reports what it
                # tried to do is worth nothing.
                entry["sectionsHidden"] = sum(
                    1 for s in (mesh.get_editor_property("static_materials") or [])
                    if s.get_editor_property("material_interface") == invisible)
                entry["stillEmpty"] = [
                    i for i, s in enumerate(mesh.get_editor_property("static_materials") or [])
                    if s.get_editor_property("material_interface") is None]

                slots = mesh.get_editor_property("static_materials") or []
                resolved = sum(
                    1 for s in slots if s.get_editor_property("material_interface") is not None)
                entry["slotsBefore"] = before
                entry["slotsAfter"] = len(slots)
                entry["slotsResolved"] = resolved
                report["builtWorlds"].append(entry)
                _write(report)  # persist before the save, which can trip a headless Slate assert
                unreal.EditorAssetLibrary.save_loaded_asset(mesh)
                report["builtWorlds"].pop()
                entry["unresolvedKeys"] = sorted({
                    sec.get("materialKey") for sec in asset["sections"]
                    if sec.get("materialKey") and sec["materialKey"] not in materials_by_key
                })
                # Delete the placeholder BioShock_<n> materials the OBJ import spawns from the
                # .mtl — _assign_asset_material has replaced every slot with the real MI.
                deleted = 0
                for n in range(len(asset["sections"])):
                    ph = "%s/Meshes/BioShock_%d" % (CONTENT_ROOT, n)
                    if unreal.EditorAssetLibrary.does_asset_exist(ph):
                        if unreal.EditorAssetLibrary.delete_asset(ph):
                            deleted += 1
                entry["placeholdersDeleted"] = deleted
        report["builtWorlds"].append(entry)

    # The fix lands on the shared StaticMesh asset's material slots, which every placement
    # inherits — no per-map edit needed. (save_current_level pops a Slate checkout prompt that
    # asserts in a headless commandlet, so it is deliberately not called here.)
    report["note"] = "mesh-asset fix; maps inherit on next open"

    _write(report)
    unreal.log("[cw-fix] %s" % json.dumps(report))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
