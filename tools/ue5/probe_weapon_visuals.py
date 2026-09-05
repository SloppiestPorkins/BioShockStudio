"""Read-only probe: starter weapon mesh slots, MI texture params, master sampler mismatch.

Compares ChemicalThrower / Crossbow against working Pistol/TommyGun/Shotgun assets under
/Game/BioShockWeapons. Writes JSON to TEMP (not the worktree).

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_weapon_visuals.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_WEAPON_VISUAL_OUT  report path (default %TEMP%/weapon_visuals_probe.json)
"""

from __future__ import annotations

import json
import os

import unreal

OUT = os.environ.get(
    "BIOSHOCK_WEAPON_VISUAL_OUT",
    os.path.join(os.environ.get("TEMP", "."), "weapon_visuals_probe.json"),
)

_WEAPONS = (
    "WP_Pistol",
    "WP_TommyGun",
    "WP_Shotgun",
    "WP_GrenadeLauncher",
    "WP_ChemicalThrower",
    "WP_Crossbow",
)

_ENGINE_DEFAULT_MARKERS = (
    "WorldGridMaterial",
    "DefaultMaterial",
    "DefaultTextMaterialOpaque",
    "EngineMaterials/Default",
    "WhiteSquareTexture",
    "DefaultTexture",
    "DefaultNormal",
)

_SAMPLE_CLASSES = (
    unreal.MaterialExpressionTextureSampleParameter2D,
    unreal.MaterialExpressionTextureSample,
)

_PROPS = (
    ("BaseColor", unreal.MaterialProperty.MP_BASE_COLOR),
    ("Opacity", unreal.MaterialProperty.MP_OPACITY),
    ("OpacityMask", unreal.MaterialProperty.MP_OPACITY_MASK),
    ("Emissive", unreal.MaterialProperty.MP_EMISSIVE_COLOR),
    ("Normal", unreal.MaterialProperty.MP_NORMAL),
)


def _path(obj):
    if obj is None:
        return None
    try:
        return obj.get_path_name()
    except Exception:  # noqa: BLE001
        return str(obj)


def _is_default(path):
    if not path:
        return True
    return any(marker in path for marker in _ENGINE_DEFAULT_MARKERS)


def _texture_entry(texture):
    path = _path(texture)
    entry = {
        "path": path,
        "exists": texture is not None,
        "isDefault": _is_default(path),
        "srgb": None,
        "compression": None,
    }
    if texture is None:
        return entry
    try:
        entry["srgb"] = bool(texture.get_editor_property("srgb"))
    except Exception:  # noqa: BLE001
        pass
    try:
        entry["compression"] = str(texture.get_editor_property("compression_settings"))
    except Exception:  # noqa: BLE001
        pass
    return entry


def _master_sampler_issues(master):
    """Same class of bug as fix_masked_texture_sampler_mismatch.py (Color vs Masks)."""
    if master is None or not isinstance(master, unreal.Material):
        return []
    edit = unreal.MaterialEditingLibrary
    issues = []
    seen = set()
    for label, prop in _PROPS:
        node = edit.get_material_property_input_node(master, prop)
        if node is None or id(node) in seen:
            continue
        seen.add(id(node))
        if not isinstance(node, _SAMPLE_CLASSES):
            continue
        texture = node.get_editor_property("texture")
        if texture is None:
            issues.append({"property": label, "issue": "null_texture"})
            continue
        try:
            compression = texture.get_editor_property("compression_settings")
            sampler = node.get_editor_property("sampler_type")
        except Exception as exc:  # noqa: BLE001
            issues.append({"property": label, "issue": "unreadable: %s" % exc})
            continue
        is_masks = compression == unreal.TextureCompressionSettings.TC_MASKS
        wants_masks = unreal.MaterialSamplerType.SAMPLERTYPE_MASKS
        wants_normal = unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL
        is_normal = compression == unreal.TextureCompressionSettings.TC_NORMALMAP
        if is_masks and sampler != wants_masks:
            issues.append({
                "property": label,
                "issue": "sampler_mismatch",
                "sampler": str(sampler),
                "texture": _path(texture),
                "compression": str(compression),
                "expected": str(wants_masks),
            })
        if is_normal and sampler != wants_normal:
            issues.append({
                "property": label,
                "issue": "sampler_mismatch",
                "sampler": str(sampler),
                "texture": _path(texture),
                "compression": str(compression),
                "expected": str(wants_normal),
            })
    return issues


def _resolve_parent(material):
    if material is None:
        return None
    if isinstance(material, unreal.Material):
        return material
    if isinstance(material, unreal.MaterialInstance):
        return _resolve_parent(material.get_editor_property("parent"))
    return None


def _slot_report(index, material):
    path = _path(material)
    entry = {
        "index": index,
        "material": path,
        "resolves": material is not None,
        "isEngineDefault": _is_default(path),
        "className": material.get_class().get_name() if material is not None else None,
        "baseColor": None,
        "normal": None,
        "parent": None,
        "samplerIssues": [],
    }
    if material is None:
        return entry

    edit = unreal.MaterialEditingLibrary
    base = normal = None
    if isinstance(material, unreal.MaterialInstanceConstant):
        base = edit.get_material_instance_texture_parameter_value(material, "BaseColor")
        normal = edit.get_material_instance_texture_parameter_value(material, "Normal")
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

    entry["baseColor"] = _texture_entry(base)
    entry["normal"] = _texture_entry(normal)
    parent = _resolve_parent(material)
    entry["parent"] = _path(parent)
    entry["samplerIssues"] = _master_sampler_issues(parent)
    return entry


def _mesh_bounds(mesh):
    try:
        bounds = mesh.get_bounds()
        box = bounds.box_extent
        origin = bounds.origin
        return {
            "origin": [round(origin.x, 2), round(origin.y, 2), round(origin.z, 2)],
            "extent": [round(box.x, 2), round(box.y, 2), round(box.z, 2)],
            "radius": round(bounds.sphere_radius, 2),
        }
    except Exception as exc:  # noqa: BLE001
        return {"error": str(exc)}


def _probe_mesh(name):
    path = "/Game/BioShockWeapons/%s/%s.%s" % (name, name, name)
    entry = {"meshPath": path, "exists": False, "slots": [], "bounds": None, "issues": []}
    if not unreal.EditorAssetLibrary.does_asset_exist(path):
        entry["issues"].append("mesh_missing")
        return entry
    mesh = unreal.EditorAssetLibrary.load_asset(path)
    if not isinstance(mesh, unreal.SkeletalMesh):
        entry["issues"].append("not_skeletal_mesh: %s" % type(mesh).__name__)
        return entry
    entry["exists"] = True
    entry["bounds"] = _mesh_bounds(mesh)

    slots = mesh.get_editor_property("materials") or []
    if not slots:
        entry["issues"].append("no_material_slots")
    for index, slot in enumerate(slots):
        mat = slot.get_editor_property("material_interface")
        slot_entry = _slot_report(index, mat)
        slot_entry["slotName"] = str(slot.get_editor_property("material_slot_name"))
        entry["slots"].append(slot_entry)
        if not slot_entry["resolves"] or slot_entry["isEngineDefault"]:
            entry["issues"].append("slot_%d_default_or_null" % index)
        bc = slot_entry.get("baseColor") or {}
        if not bc.get("exists") or bc.get("isDefault"):
            entry["issues"].append("slot_%d_basecolor_default_or_null" % index)
        if slot_entry.get("samplerIssues"):
            entry["issues"].append("slot_%d_sampler_issues" % index)
    return entry


def _probe_hands_sockets():
    path = "/Game/BioShockWeapons/NEWPlayerHands/NEWPlayerHands.NEWPlayerHands"
    entry = {"path": path, "exists": False, "sockets": {}}
    if not unreal.EditorAssetLibrary.does_asset_exist(path):
        return entry
    mesh = unreal.EditorAssetLibrary.load_asset(path)
    if not isinstance(mesh, unreal.SkeletalMesh):
        return entry
    entry["exists"] = True
    # Socket names from export manifest that matter for starter weapons.
    wanted = (
        "TommyGun", "Pistol", "Crossbow", "Chem", "ChemicalThrower",
        "Launcher", "GrenadeLauncher", "Wrench", "Shotgun",
    )
    for name in wanted:
        entry["sockets"][name] = bool(mesh.find_socket(unreal.Name(name)))
    return entry


def main():
    report = {
        "weapons": {},
        "hands": _probe_hands_sockets(),
        "summaryIssues": [],
    }
    for name in _WEAPONS:
        entry = _probe_mesh(name)
        report["weapons"][name] = entry
        for issue in entry.get("issues") or []:
            report["summaryIssues"].append("%s: %s" % (name, issue))

    hands = report["hands"].get("sockets") or {}
    # Confirmed alias class: GrenadeLauncher def → Launcher socket.
    if hands.get("Chem") and not hands.get("ChemicalThrower"):
        report["summaryIssues"].append(
            "ChemicalThrower: grip socket on hands is 'Chem' not 'ChemicalThrower' "
            "(same alias class as GrenadeLauncher→Launcher)"
        )
    if hands.get("Launcher") and not hands.get("GrenadeLauncher"):
        report["summaryIssues"].append(
            "GrenadeLauncher: grip socket on hands is 'Launcher' (already aliased in runtime)"
        )

    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[weapon-visuals] wrote %s (%d summary issues)" % (
        OUT, len(report["summaryIssues"])))
    return report


if __name__ == "__main__":
    main()
