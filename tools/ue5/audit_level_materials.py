"""Audit StaticMeshActor / Brush material slots on a loaded UE5 level.

Writes a JSON report (unreal.log is not reliable under -run=pythonscript). Asserts
by raising RuntimeError when the map cannot be opened; slot findings are always
written so a partial audit is still evidence.
"""

from __future__ import annotations

import json
import os
from collections import Counter

import unreal

import import_bioshock

DEFAULT_MAP = "/Game/BioShockSlice/1-Medical"
DEFAULT_OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "_reports",
    "audit_1-Medical_materials.json",
)

ENGINE_DEFAULT_MARKERS = (
    "WorldGridMaterial",
    "DefaultMaterial",
    "DefaultTextMaterialOpaque",
    "EngineMaterials/Default",
)


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _asset_path(obj):
    if obj is None:
        return None
    try:
        return obj.get_path_name()
    except Exception:  # noqa: BLE001
        return str(obj)


def _is_engine_default(path):
    if not path:
        return True
    return any(marker in path for marker in ENGINE_DEFAULT_MARKERS)


def _texture_info(texture):
    path = _asset_path(texture)
    if texture is None:
        return {"path": None, "exists": False, "isDefault": True}
    name = path.rsplit("/", 1)[-1] if path else ""
    is_default = (
        _is_engine_default(path)
        or name in ("WhiteSquareTexture", "DefaultTexture", "DefaultNormal")
    )
    return {"path": path, "exists": True, "isDefault": is_default}


def _master_null_texture_params(material):
    """Return property names whose connected TextureSampleParameter2D has a NULL texture."""
    if material is None or not isinstance(material, unreal.Material):
        return []
    edit = unreal.MaterialEditingLibrary
    nulls = []
    for prop, label in (
        (unreal.MaterialProperty.MP_BASE_COLOR, "BaseColor"),
        (unreal.MaterialProperty.MP_EMISSIVE_COLOR, "Emissive"),
        (unreal.MaterialProperty.MP_NORMAL, "Normal"),
    ):
        node = edit.get_material_property_input_node(material, prop)
        if node is None:
            continue
        if not isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D):
            continue
        if node.get_editor_property("texture") is None:
            nulls.append(label)
    return nulls


def _resolve_parent_material(material):
    if material is None:
        return None
    if isinstance(material, unreal.Material):
        return material
    if isinstance(material, unreal.MaterialInstance):
        parent = material.get_editor_property("parent")
        return _resolve_parent_material(parent)
    return None


def _slot_report(slot_name, material):
    path = _asset_path(material)
    entry = {
        "slot": str(slot_name) if slot_name is not None else None,
        "material": path,
        "resolves": material is not None,
        "isEngineDefault": _is_engine_default(path),
        "className": material.get_class().get_name() if material is not None else None,
        "baseColor": None,
        "normal": None,
        "parent": None,
        "parentNullTextureParams": [],
    }
    if material is None:
        return entry

    edit = unreal.MaterialEditingLibrary
    # GetMaterialInstanceTextureParameterValue only accepts a MaterialInstanceConstant --
    # passing a plain Material (a Master, no instance) raises a NativizeObject TypeError.
    base = normal = None
    if isinstance(material, unreal.MaterialInstanceConstant):
        base = edit.get_material_instance_texture_parameter_value(material, "BaseColor")
        normal = edit.get_material_instance_texture_parameter_value(material, "Normal")
    # Masters expose the same parameter names via the expression default texture.
    if base is None and isinstance(material, unreal.Material):
        node = edit.get_material_property_input_node(
            material, unreal.MaterialProperty.MP_BASE_COLOR)
        if isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D):
            base = node.get_editor_property("texture")
    if normal is None and isinstance(material, unreal.Material):
        node = edit.get_material_property_input_node(
            material, unreal.MaterialProperty.MP_NORMAL)
        if isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D):
            normal = node.get_editor_property("texture")

    entry["baseColor"] = _texture_info(base)
    entry["normal"] = _texture_info(normal)

    parent = _resolve_parent_material(material)
    entry["parent"] = _asset_path(parent)
    entry["parentNullTextureParams"] = _master_null_texture_params(parent)
    return entry


def _mesh_component_slots(component):
    slots = []
    if component is None:
        return slots
    try:
        materials = component.get_materials()
    except Exception:  # noqa: BLE001
        materials = None
    if materials:
        for index, material in enumerate(materials):
            slots.append(_slot_report("Element%d" % index, material))
        return slots

    # Fallback: static mesh asset slot table when the component has no override list yet.
    try:
        mesh = component.get_editor_property("static_mesh")
    except Exception:  # noqa: BLE001
        mesh = None
    if mesh is None:
        return slots
    try:
        static_materials = mesh.get_editor_property("static_materials") or []
    except Exception:  # noqa: BLE001
        static_materials = []
    for index, slot in enumerate(static_materials):
        name = slot.get_editor_property("material_slot_name")
        material = slot.get_editor_property("material_interface")
        slots.append(_slot_report(name or ("BioShock_%d" % index), material))
    return slots


def _open_map(map_path):
    level = _level_subsystem()
    if not unreal.EditorAssetLibrary.does_asset_exist(map_path):
        raise RuntimeError("map asset missing: %s" % map_path)
    if not level.load_level(map_path):
        raise RuntimeError("load_level failed: %s" % map_path)


def _audit_actors():
    actors_out = []
    summary = Counter()
    for actor in _actors().get_all_level_actors():
        kind = None
        component = None
        if isinstance(actor, unreal.StaticMeshActor):
            kind = "StaticMeshActor"
            component = actor.static_mesh_component
        elif isinstance(actor, unreal.Brush):
            kind = "Brush"
            try:
                component = actor.get_editor_property("brush_component")
            except Exception:  # noqa: BLE001
                component = None
        else:
            continue

        summary["actors_%s" % kind] += 1
        slots = _mesh_component_slots(component)
        mobility = None
        if component is not None:
            try:
                mobility = str(component.get_editor_property("mobility"))
            except Exception:  # noqa: BLE001
                mobility = None
        actor_entry = {
            "label": actor.get_actor_label(),
            "class": kind,
            "mobility": mobility,
            "slots": slots,
        }
        actors_out.append(actor_entry)

        if not slots:
            summary["actorsWithNoSlots"] += 1
            continue
        for slot in slots:
            summary["slotsTotal"] += 1
            if not slot["resolves"]:
                summary["slotsUnresolved"] += 1
            if slot["isEngineDefault"]:
                summary["slotsEngineDefault"] += 1
            if slot["parentNullTextureParams"]:
                summary["slotsParentNullTexture"] += 1
            base = slot.get("baseColor") or {}
            if not base.get("exists"):
                summary["slotsMissingBaseColor"] += 1
            elif base.get("isDefault"):
                summary["slotsDefaultBaseColor"] += 1
            else:
                summary["slotsBoundBaseColor"] += 1

    return actors_out, dict(summary)


def _audit_master_folder(folder):
    """Scan master materials under a content folder for NULL TextureSampleParameter2D."""
    if not folder:
        return {"folder": None, "masters": 0, "nullTextureMasters": [], "repairedWouldBe": 0}
    paths = unreal.EditorAssetLibrary.list_assets(folder, recursive=True, include_folder=False) or []
    nulls = []
    masters = 0
    for path in paths:
        asset = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(asset, unreal.Material):
            continue
        masters += 1
        null_params = _master_null_texture_params(asset)
        if null_params:
            nulls.append({"path": path, "nullParams": null_params})
    return {
        "folder": folder,
        "masters": masters,
        "nullTextureMasters": nulls,
        "nullTextureMasterCount": len(nulls),
    }


def main(map_path=None, report_path=None, master_folder=None):
    map_path = map_path or os.environ.get("BIOSHOCK_AUDIT_MAP", DEFAULT_MAP)
    report_path = report_path or os.environ.get("BIOSHOCK_AUDIT_OUT", DEFAULT_OUT)
    master_folder = master_folder or os.environ.get(
        "BIOSHOCK_AUDIT_MASTERS",
        "/Game/BioShockSlice/Content/Materials/Masters",
    )

    report = {
        "map": map_path,
        "masterFolder": master_folder,
        "diagnosisHint": None,
        "confidence": {},
        "summary": {},
        "masters": {},
        "sampleBrokenSlots": [],
        "error": None,
    }

    try:
        # Prove Engine defaults are loadable in this session (the import-time failure mode).
        white = import_bioshock._default_base_color_texture()
        normal = import_bioshock._default_normal_texture()
        report["engineDefaults"] = {
            "baseColor": _asset_path(white),
            "normal": _asset_path(normal),
            "confidence": "CONFIRMED_BYTES",
        }

        _open_map(map_path)
        actors, summary = _audit_actors()
        report["summary"] = summary
        report["actorCount"] = len(actors)

        broken = []
        for actor in actors:
            for slot in actor["slots"]:
                if slot["parentNullTextureParams"] or slot["isEngineDefault"] or not slot["resolves"]:
                    broken.append({
                        "label": actor["label"],
                        "class": actor["class"],
                        "mobility": actor["mobility"],
                        "slot": slot,
                    })
        report["sampleBrokenSlots"] = broken[:80]
        report["brokenSlotCount"] = len(broken)

        report["masters"] = _audit_master_folder(master_folder)

        null_masters = report["masters"].get("nullTextureMasterCount", 0)
        engine_default_slots = summary.get("slotsEngineDefault", 0)
        if null_masters > 0:
            report["diagnosisHint"] = (
                "(a) master materials have NULL TextureSampleParameter2D defaults and fail to "
                "compile → Default Material in game. Not (b) Lightmass-only: lighting may also "
                "be unbuilt, but the compile failure alone explains broken wall textures."
            )
            report["confidence"]["nullMasterTextures"] = "CONFIRMED_BYTES"
            report["confidence"]["cause"] = "CONFIRMED_BYTES"
        elif engine_default_slots > 0:
            report["diagnosisHint"] = (
                "(a) slots still on WorldGridMaterial/DefaultMaterial — bindings missing."
            )
            report["confidence"]["cause"] = "PLAUSIBLE"
        else:
            report["diagnosisHint"] = (
                "No NULL-texture masters and no engine-default slots in this audit sample. "
                "If walls still look wrong, prefer (b)/(c) lighting/exposure — PLAUSIBLE."
            )
            report["confidence"]["cause"] = "UNKNOWN"

        # Persist a compact actor summary only — full per-actor dump is huge on 1-Medical.
        report["mobilityCounts"] = Counter(
            a.get("mobility") or "None" for a in actors
        )
        report["mobilityCounts"] = dict(report["mobilityCounts"])

    except Exception as exc:  # noqa: BLE001
        report["error"] = str(exc)
        raise
    finally:
        os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)

    if report.get("error"):
        raise RuntimeError(report["error"])
    return report


if __name__ == "__main__":
    main()
