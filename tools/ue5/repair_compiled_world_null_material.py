"""Repair the compiled-world mesh's one material-less section — make it invisible, not textured.

Measured 29 Sept 2026: `1-Medical.ue5-level.json`'s `Model_Model1_20761` (BuiltWorld) asset has
67 sections; section 0 (619 triangles) carries no `material`/`materialKey` at all -- confirmed at
the exporter source (`src/BioShockStudio.Core/Export/LevelSceneExporter.cs:204`,
`MeshSurfaceResolver.cs:15-18`): the resolved `Materials[0]` entry for this one slot is genuinely
null, for one of `MeshSurfaceResolver`'s three documented reasons (the slot names nothing, names
something outside the package, or the reference could not be followed) -- a byte-level export gap,
not an import bug.

`repair_null_slot_materials.py:80` already found this same slot on 8 Sept 2026 and skipped it with
the comment "compiled-world shell slot 0 is the zoning face, intentionally null" -- i.e. BSP
surfaces UnrealEd's own zone/portal system (see the SDK guide's "Zones and Portals" chapter: a
Portal-flagged surface "is a zone portal", used purely for the renderer's visibility culling, not
meant to be seen) rather than decoration missing a texture. That reading holds up independently:
section 0's triangles span nearly the whole level footprint (X -65027..-16528, Z -7357..12577,
measured from the section's own face list in `Meshes/Model1_20761.obj`) -- consistent with sparse
zone-boundary planes at room transitions throughout Medical, not one localised patch of missing
wall decoration. That is also why it reads as scattered "broken texture" patches in many different
rooms rather than one obviously-isolated spot: it is the same slot, used wherever a zone boundary
falls, not many separate bugs.

The 8 Sept skip left the actual visible symptom unfixed, though: UE5 has no native "zone portal,
do not render" surface concept, so a null material slot just falls back to the engine's visible
grey checkerboard (`WorldGridMaterial`) instead of being hidden, which is almost certainly what
was reported live. This script does not paint a plausible-but-wrong texture over a surface that
was likely never meant to render at all -- it assigns a fully transparent placeholder instead, so
these faces stop being visible without asserting they are real, texturable BioShock geometry.
Collision is unaffected (a StaticMeshComponent's material assignment does not change collision).

If the "zoning face" reading turns out to be wrong for some other reason, the safe/reversible
next step is `M_UnresolvedBspSection`'s own asset -- swap its Opacity back to 1.0 and give it a
real BaseColor once/if the C# exporter is instrumented to say what the real material should have
been (which of `MeshSurfaceResolver`'s three null-reasons this slot actually hits is still
unconfirmed -- this script does not attempt that investigation).

Idempotent: safe to re-run after a fresh reimport of 1-Medical's compiled-world mesh.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_compiled_world_null_material.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_COMPILED_WORLD_MAP (default /Game/BioShockSlice/1-Medical)
"""
from __future__ import annotations

import json
import os

import unreal

MAP_PATH = os.environ.get("BIOSHOCK_COMPILED_WORLD_MAP", "/Game/BioShockSlice/1-Medical")
PLACEHOLDER_PATH = "/Game/BioShockFX/Materials/M_UnresolvedBspSection"
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_compiled_world_null_material.json")


def _log(message):
    unreal.log("[repair-compiled-world] %s" % message)


def _ensure_placeholder_material():
    if unreal.EditorAssetLibrary.does_asset_exist(PLACEHOLDER_PATH):
        return unreal.EditorAssetLibrary.load_asset(PLACEHOLDER_PATH)

    folder = "/".join(PLACEHOLDER_PATH.split("/")[:-1])
    name = PLACEHOLDER_PATH.split("/")[-1]
    unreal.EditorAssetLibrary.make_directory(folder)
    factory = unreal.MaterialFactoryNew()
    mat = unreal.AssetToolsHelpers.get_asset_tools().create_asset(name, folder, unreal.Material, factory)
    if mat is None:
        return None

    edit = unreal.MaterialEditingLibrary
    # Fully transparent, not a plausible-but-wrong solid colour: the "zoning face" reading (see
    # this file's module docstring) says these surfaces were likely never meant to render at all,
    # so painting them a confident grey would assert something not actually known. Opacity=0 on a
    # translucent master hides them cleanly without claiming they are real, texturable geometry.
    mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_TRANSLUCENT)
    try:
        mat.set_editor_property(
            "translucency_lighting_mode", unreal.TranslucencyLightingMode.TLM_SURFACE_PER_PIXEL_LIGHTING)
    except Exception:  # noqa: BLE001
        pass

    colour = edit.create_material_expression(mat, unreal.MaterialExpressionConstant3Vector, -300, -100)
    colour.set_editor_property("constant", unreal.LinearColor(0.0, 0.0, 0.0, 1.0))
    edit.connect_material_property(colour, "", unreal.MaterialProperty.MP_BASE_COLOR)

    opacity = edit.create_material_expression(mat, unreal.MaterialExpressionConstant, -300, 60)
    opacity.set_editor_property("r", 0.0)
    edit.connect_material_property(opacity, "", unreal.MaterialProperty.MP_OPACITY)

    edit.recompile_material(mat)
    unreal.EditorAssetLibrary.save_loaded_asset(mat)
    return mat


def main(map_path=None, save=True):
    map_path = map_path or MAP_PATH
    report = {"map": map_path, "repaired": [], "error": None}

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        report["error"] = "could not load %s" % map_path
        _write(report)
        raise RuntimeError(report["error"])

    placeholder = _ensure_placeholder_material()
    if placeholder is None:
        report["error"] = "could not create placeholder material %s" % PLACEHOLDER_PATH
        _write(report)
        raise RuntimeError(report["error"])

    actor = next(
        (a for a in unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
         if a.get_actor_label() == "compiled world"),
        None)
    if actor is None:
        report["error"] = "no 'compiled world' actor on %s" % map_path
        _write(report)
        raise RuntimeError(report["error"])

    comp = actor.static_mesh_component
    changed = False
    for slot in range(comp.get_num_materials()):
        if comp.get_material(slot) is not None:
            continue
        comp.set_material(slot, placeholder)
        report["repaired"].append(slot)
        changed = True

    if changed and save:
        if not level.save_current_level():
            report["error"] = "save_current_level() reported failure"
            _write(report)
            raise RuntimeError(report["error"])

    report["placeholderMaterial"] = PLACEHOLDER_PATH
    _write(report)
    _log("repaired %d slot(s) on 'compiled world': %s" % (len(report["repaired"]), report["repaired"]))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
