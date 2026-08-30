"""Import `document.archetypes` from a level manifest into UShockAiArchetype assets.

Idempotent via a per-asset fingerprint tag (same pattern as import_bioshock.py).
Assets live only in the throwaway UE5 project under `/Game/BioShockArchetypes/<package>/`.
"""

from __future__ import annotations

import hashlib
import json
import os

import unreal

CONTENT_ROOT = "/Game/BioShockArchetypes"
FINGERPRINT_TAG = "BioShockArchetypeFingerprint"


def _log(message):
    unreal.log("[bioshock-ai-archetypes] %s" % message)


def _package_folder(manifest):
    package = manifest.get("package") or "unknown"
    return "%s/%s" % (CONTENT_ROOT, package)


def _ensure_dir(path):
    if unreal.EditorAssetLibrary.does_directory_exist(path):
        return
    if not unreal.EditorAssetLibrary.make_directory(path):
        raise RuntimeError("could not create folder %s" % path)


def _archetype_class():
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockAiArchetype")
    if cls is None:
        raise RuntimeError("ShockAiArchetype missing — rebuild BioShockRuntime")
    return cls


def _slot_entries(slots):
    out = []
    for slot in slots or []:
        out.append(
            {
                "name": slot.get("name"),
                "chance": float(slot.get("chance") or 0.0),
                "replacement": slot.get("replacement"),
            }
        )
    return out


def _slot_name_looks_ranged(name):
    if not name:
        return False
    lowered = str(name).lower()
    return any(
        token in lowered
        for token in ("pistol", "tommy", "gun", "leadhead", "thug", "ranged")
    )


def _is_ranged_archetype(archetype):
    """PLAUSIBLE heuristic from aiType / weapon-slot names (Leadhead, Thug, *Pistol*, *Tommy*)."""
    ai_type = str(archetype.get("aiType") or "").lower()
    if any(token in ai_type for token in ("leadhead", "thug", "ranged", "pistol", "tommy")):
        return True
    for slot in archetype.get("weaponSlots") or []:
        if _slot_name_looks_ranged(slot.get("name")):
            return True
        if _slot_name_looks_ranged(slot.get("replacement")):
            return True
    return False


def _archetype_payload(archetype):
    return {
        "name": archetype.get("name"),
        "aiType": archetype.get("aiType"),
        "mesh": archetype.get("mesh"),
        "health": archetype.get("health"),
        "frozenHealth": archetype.get("frozenHealth"),
        "damageResistanceSetName": archetype.get("damageResistanceSetName"),
        "materialSlots": _slot_entries(archetype.get("materialSlots")),
        "attachmentSlots": _slot_entries(archetype.get("attachmentSlots")),
        "weaponSlots": _slot_entries(archetype.get("weaponSlots")),
        "bIsRanged": _is_ranged_archetype(archetype),
    }


def _fingerprint(archetype):
    encoded = json.dumps(_archetype_payload(archetype), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def _mesh_group_name(mesh_name, manifest):
    if not mesh_name:
        return None
    for asset in manifest.get("assets") or []:
        if asset.get("name") == mesh_name and asset.get("kind") == "SkeletalMesh":
            return asset.get("group") or mesh_name
    return None


def _resolve_mesh_asset_path(mesh_name, manifest):
    if not mesh_name:
        return ""
    candidates = []
    group = _mesh_group_name(mesh_name, manifest)
    if group:
        candidates.append("/Game/BioShockCharacters/%s/%s" % (group, group))
    candidates.append("/Game/BioShockCharacters/%s/%s" % (mesh_name, mesh_name))
    for folder in candidates:
        object_path = "%s.%s" % (folder, folder.rsplit("/", 1)[-1])
        if unreal.EditorAssetLibrary.does_asset_exist(folder):
            return object_path
    return ""


def _make_loadout_slots(slots):
    out = []
    for slot in slots or []:
        entry = unreal.ShockAiArchetypeLoadoutSlot()
        entry.set_editor_property("name", slot.get("name") or "")
        entry.set_editor_property("chance", float(slot.get("chance") or 0.0))
        entry.set_editor_property("replacement", slot.get("replacement") or "")
        out.append(entry)
    return out


def _configure_asset(asset, archetype, manifest):
    payload = _archetype_payload(archetype)
    asset.set_editor_property("archetype_name", unreal.Name(archetype.get("name") or ""))
    asset.set_editor_property("ai_type_class_name", archetype.get("aiType") or "")
    asset.set_editor_property("mesh_path", archetype.get("mesh") or "")
    mesh_asset = _resolve_mesh_asset_path(archetype.get("mesh"), manifest)
    if mesh_asset:
        asset.set_editor_property("mesh_asset_path", unreal.SoftObjectPath(mesh_asset))
    else:
        asset.set_editor_property("mesh_asset_path", unreal.SoftObjectPath())

    health = archetype.get("health")
    if health is not None:
        asset.set_editor_property("health", float(health))
        asset.set_editor_property("has_health", True)
    else:
        asset.set_editor_property("health", 0.0)
        asset.set_editor_property("has_health", False)

    frozen = archetype.get("frozenHealth")
    if frozen is not None:
        asset.set_editor_property("frozen_health", float(frozen))
        asset.set_editor_property("has_frozen_health", True)
    else:
        asset.set_editor_property("frozen_health", 0.0)
        asset.set_editor_property("has_frozen_health", False)

    asset.set_editor_property(
        "damage_resistance_set_name",
        archetype.get("damageResistanceSetName") or "",
    )
    asset.set_editor_property(
        "material_slots",
        _make_loadout_slots(archetype.get("materialSlots")),
    )
    asset.set_editor_property(
        "attachment_slots",
        _make_loadout_slots(archetype.get("attachmentSlots")),
    )
    asset.set_editor_property(
        "weapon_slots",
        _make_loadout_slots(archetype.get("weaponSlots")),
    )
    asset.set_editor_property("b_is_ranged", _is_ranged_archetype(archetype))
    unreal.EditorAssetLibrary.set_metadata_tag(asset, FINGERPRINT_TAG, _fingerprint(archetype))
    return payload


def import_ai_archetypes(manifest_path, content_root=CONTENT_ROOT):
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    archetypes = manifest.get("archetypes") or []
    if not archetypes:
        raise RuntimeError(
            "manifest %s has no archetypes — re-export with a current export-level build"
            % manifest_path
        )

    package = manifest.get("package") or "unknown"
    folder = "%s/%s" % (content_root, package)
    _ensure_dir(CONTENT_ROOT)
    _ensure_dir(folder)

    archetype_cls = _archetype_class()
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    factory = unreal.DataAssetFactory()
    factory.set_editor_property("data_asset_class", archetype_cls)

    report = {
        "manifest": manifest_path,
        "package": package,
        "folder": folder,
        "archetypesInManifest": len(archetypes),
        "created": 0,
        "updated": 0,
        "reused": 0,
        "sample": {},
    }

    for archetype in archetypes:
        name = archetype.get("name")
        if not name:
            continue
        asset_path = "%s/%s" % (folder, name)
        fingerprint = _fingerprint(archetype)
        existed = unreal.EditorAssetLibrary.does_asset_exist(asset_path)
        if existed:
            asset = unreal.EditorAssetLibrary.load_asset(asset_path)
            stored = unreal.EditorAssetLibrary.get_metadata_tag(asset, FINGERPRINT_TAG)
            if stored == fingerprint:
                report["reused"] += 1
                continue
            _configure_asset(asset, archetype, manifest)
            if not unreal.EditorAssetLibrary.save_loaded_asset(asset):
                raise RuntimeError("could not save %s" % asset_path)
            report["updated"] += 1
            continue

        asset = asset_tools.create_asset(name, folder, archetype_cls, factory)
        if asset is None:
            raise RuntimeError("could not create %s" % asset_path)
        payload = _configure_asset(asset, archetype, manifest)
        if not unreal.EditorAssetLibrary.save_loaded_asset(asset):
            raise RuntimeError("could not save %s" % asset_path)
        report["created"] += 1
        if name == "MedicalBabyJaneMelee":
            report["sample"] = payload

    _log(
        "imported archetypes created=%s updated=%s reused=%s total=%s"
        % (report["created"], report["updated"], report["reused"], len(archetypes))
    )
    import_ai_archetypes.last_report = report
    return report


import_ai_archetypes.last_report = {}


def main(manifest_path=None, content_root=CONTENT_ROOT):
    manifest_path = manifest_path or os.environ.get(
        "BIOSHOCK_LEVEL_JSON",
        r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
    )
    return import_ai_archetypes(manifest_path, content_root=content_root)


if __name__ == "__main__":
    main()
