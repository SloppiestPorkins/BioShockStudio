"""Headless verify: GiveWeaponByDef assigns the expected viewmodel mesh per def.

Exercises the real equip path (Resolve → ApplyDef → Mesh->SetSkeletalMesh / StaticMesh),
not a direct SetSkeletalMesh in the test. Wrench is a StaticMesh viewmodel
(`/Game/BioShockWeapons/WP_Wrench/WP_Wrench`) — asserted positively here (not blocked).

Also asserts each skeletal mesh's material slots resolve non-default BaseColor/Normal texture
parameters (same class of check as audit_level_materials slot checks) so a null/default-material
texture on ChemicalThrower/Crossbow cannot ship unnoticed.
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-weapon-meshes] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _asset_path(mesh):
    if not mesh:
        return None
    try:
        return mesh.get_path_name()
    except Exception:  # noqa: BLE001
        return str(mesh)


_ENGINE_DEFAULT_MARKERS = (
    "WorldGridMaterial",
    "DefaultMaterial",
    "DefaultTextMaterialOpaque",
    "EngineMaterials/Default",
    "WhiteSquareTexture",
    "DefaultTexture",
    "DefaultNormal",
)


def _is_engine_default(path):
    if not path:
        return True
    return any(marker in path for marker in _ENGINE_DEFAULT_MARKERS)


def _texture_ok(texture):
    path = _asset_path(texture)
    return texture is not None and not _is_engine_default(path)


def _slot_texture_report(material):
    """BaseColor/Normal resolve status for one material interface (MI or master)."""
    entry = {
        "material": _asset_path(material),
        "isEngineDefault": _is_engine_default(_asset_path(material)),
        "baseColor": None,
        "normal": None,
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

    entry["baseColor"] = _asset_path(base)
    entry["normal"] = _asset_path(normal)
    entry["baseColorOk"] = _texture_ok(base)
    entry["normalOk"] = _texture_ok(normal)
    return entry


def _assert_mesh_textures(def_name, skel, failures):
    """Fail if any material slot is engine-default or has null/default BaseColor/Normal."""
    slots = skel.get_editor_property("materials") or []
    reports = []
    if not slots:
        failures.append("%s skeletal mesh has no material slots" % def_name)
        return reports
    for index, slot in enumerate(slots):
        mat = slot.get_editor_property("material_interface")
        slot_entry = _slot_texture_report(mat)
        slot_entry["index"] = index
        reports.append(slot_entry)
        if mat is None or slot_entry["isEngineDefault"]:
            failures.append(
                "%s slot %d material null/engine-default (%s)"
                % (def_name, index, slot_entry["material"])
            )
            continue
        if not slot_entry.get("baseColorOk"):
            failures.append(
                "%s slot %d BaseColor null/default (%s)"
                % (def_name, index, slot_entry.get("baseColor"))
            )
        if not slot_entry.get("normalOk"):
            failures.append(
                "%s slot %d Normal null/default (%s)"
                % (def_name, index, slot_entry.get("normal"))
            )
    return reports


# Def name → (slot, expected skeletal mesh object path).
_SKELETAL_STARTERS = (
    ("Pistol", 1, "/Game/BioShockWeapons/WP_Pistol/WP_Pistol.WP_Pistol"),
    ("TommyGun", 2, "/Game/BioShockWeapons/WP_TommyGun/WP_TommyGun.WP_TommyGun"),
    ("Shotgun", 3, "/Game/BioShockWeapons/WP_Shotgun/WP_Shotgun.WP_Shotgun"),
    ("GrenadeLauncher", 4, "/Game/BioShockWeapons/WP_GrenadeLauncher/WP_GrenadeLauncher.WP_GrenadeLauncher"),
    ("ChemicalThrower", 5, "/Game/BioShockWeapons/WP_ChemicalThrower/WP_ChemicalThrower.WP_ChemicalThrower"),
    ("Crossbow", 6, "/Game/BioShockWeapons/WP_Crossbow/WP_Crossbow.WP_Crossbow"),
)

_WRENCH_STATIC = "/Game/BioShockWeapons/WP_Wrench/WP_Wrench.WP_Wrench"


def main(out):
    report = {"failures": [], "weapons": {}}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not player_cls:
        failures.append("ShockPlayer class missing")
        _write(out, report)
        raise RuntimeError("weapon-meshes:\n- " + "\n- ".join(failures))

    player = _spawn(subsystem, player_cls, "MeshPlayer", unreal.Vector(0.0, 0.0, 100.0))
    if not player:
        failures.append("player spawn")
        _write(out, report)
        raise RuntimeError("weapon-meshes:\n- " + "\n- ".join(failures))

    # --- Wrench: StaticMesh viewmodel on StaticMesh component; skeletal Mesh cleared ---
    wrench = player.give_weapon_by_def(unreal.Name("Wrench"), 0)
    wrench_entry = {
        "slot": 0,
        "weapon": bool(wrench),
        "staticMeshPath": None,
        "skeletalMeshPath": None,
        "isStaticViewmodel": False,
    }
    if not wrench:
        failures.append("GiveWeaponByDef(Wrench) null")
    else:
        static_comp = wrench.get_editor_property("static_mesh")
        static_asset = static_comp.get_editor_property("static_mesh") if static_comp else None
        mesh_comp = wrench.get_editor_property("mesh")
        skel = mesh_comp.get_skeletal_mesh_asset() if mesh_comp else None
        wrench_entry["staticMeshPath"] = _asset_path(static_asset)
        wrench_entry["skeletalMeshPath"] = _asset_path(skel)
        wrench_entry["isStaticViewmodel"] = bool(wrench.is_static_viewmodel_for_verify())
        if static_asset is None:
            failures.append(
                "Wrench StaticMesh null after GiveWeaponByDef (expected %s)"
                % _WRENCH_STATIC
            )
        elif wrench_entry["staticMeshPath"] != _WRENCH_STATIC:
            failures.append(
                "Wrench static mesh got %s expected %s"
                % (wrench_entry["staticMeshPath"], _WRENCH_STATIC)
            )
        if skel is not None:
            failures.append(
                "Wrench unexpectedly has skeletal mesh %s (static viewmodel should clear it)"
                % _asset_path(skel)
            )
        if not wrench_entry["isStaticViewmodel"]:
            failures.append("Wrench IsStaticViewmodelForVerify false")
    report["weapons"]["Wrench"] = wrench_entry
    report["wrench"] = "static_mesh_ok" if not any(
        f.startswith("Wrench") or f.startswith("GiveWeaponByDef(Wrench)") for f in failures
    ) else "static_mesh_fail"

    for def_name, slot, expected in _SKELETAL_STARTERS:
        weapon = player.give_weapon_by_def(unreal.Name(def_name), slot)
        entry = {"slot": slot, "expected": expected, "weapon": bool(weapon), "meshPath": None}
        if not weapon:
            failures.append("GiveWeaponByDef(%s) null" % def_name)
            report["weapons"][def_name] = entry
            continue

        mesh_comp = weapon.get_editor_property("mesh")
        if not mesh_comp:
            failures.append("%s Mesh component null" % def_name)
            report["weapons"][def_name] = entry
            continue

        skel = mesh_comp.get_skeletal_mesh_asset()
        got = _asset_path(skel)
        entry["meshPath"] = got
        if skel is None:
            failures.append(
                "%s mesh null after GiveWeaponByDef (expected %s) — import missing?"
                % (def_name, expected)
            )
        elif got != expected:
            failures.append("%s mesh got %s expected %s" % (def_name, got, expected))
        else:
            entry["materialSlots"] = _assert_mesh_textures(def_name, skel, failures)
        report["weapons"][def_name] = entry

    try:
        subsystem.destroy_actor(player)
    except Exception:  # noqa: BLE001
        pass

    error_count = len(failures)
    report["errorCount"] = error_count
    report["weapon_meshes"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-meshes (%d errors):\n- " % error_count + "\n- ".join(failures))
    _log("Success - %d error(s); Wrench static_mesh_ok" % error_count)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_meshes_report.json"),
        )
    )
