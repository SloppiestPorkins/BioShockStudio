"""Headless verify: GiveWeaponByDef assigns the expected viewmodel mesh per def.

Exercises the real equip path (Resolve → ApplyDef → Mesh->SetSkeletalMesh), not a direct
SetSkeletalMesh in the test. Wrench is excluded from the skeletal expectation: WP_WrenchMesh in
ShockGame.U is a plain StaticMesh with no UAPW wrapper (ROADMAP Gate 5 / research/context.md), so
UShockWeaponDef leaves MeshAssetPath empty rather than pointing at a substitute.
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


# Def name → (slot, expected skeletal mesh object path). Wrench deliberately omitted.
_SKELETAL_STARTERS = (
    ("Pistol", 1, "/Game/BioShockWeapons/WP_Pistol/WP_Pistol.WP_Pistol"),
    ("TommyGun", 2, "/Game/BioShockWeapons/WP_TommyGun/WP_TommyGun.WP_TommyGun"),
    ("Shotgun", 3, "/Game/BioShockWeapons/WP_Shotgun/WP_Shotgun.WP_Shotgun"),
    ("GrenadeLauncher", 4, "/Game/BioShockWeapons/WP_GrenadeLauncher/WP_GrenadeLauncher.WP_GrenadeLauncher"),
    ("ChemicalThrower", 5, "/Game/BioShockWeapons/WP_ChemicalThrower/WP_ChemicalThrower.WP_ChemicalThrower"),
    ("Crossbow", 6, "/Game/BioShockWeapons/WP_Crossbow/WP_Crossbow.WP_Crossbow"),
)


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

    # --- Wrench: MeshAssetPath must stay empty; mesh must stay null (StaticMesh gap) ---
    wrench = player.give_weapon_by_def(unreal.Name("Wrench"), 0)
    wrench_entry = {"slot": 0, "weapon": bool(wrench), "meshPath": None, "defMeshPath": None}
    if not wrench:
        failures.append("GiveWeaponByDef(Wrench) null")
    else:
        mesh_comp = wrench.get_editor_property("mesh")
        skel = mesh_comp.get_skeletal_mesh_asset() if mesh_comp else None
        wrench_entry["meshPath"] = _asset_path(skel)
        wrench_def = unreal.ShockWeaponDefLibrary.resolve_weapon_def(unreal.Name("Wrench"))
        if wrench_def:
            # Informational only. FSoftObjectPath is a struct that's never None/falsy even
            # when empty, and this Python binding exposes none of is_valid()/is_null()/
            # to_string()/working struct equality (all tried live against UE5.7, all
            # failed) -- there's no reliable emptiness check available from here. The
            # behavioural assertion below (the equipped Wrench actually has no skeletal
            # mesh) is the real, meaningful check and needs none of this.
            wrench_entry["defMeshPath"] = str(wrench_def.get_editor_property("mesh_asset_path"))
        if skel is not None:
            failures.append(
                "Wrench unexpectedly has skeletal mesh %s (expected none until StaticMesh import)"
                % _asset_path(skel)
            )
    report["weapons"]["Wrench"] = wrench_entry
    report["wrench"] = "static_mesh_blocked"

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
    _log("Success - %d error(s); Wrench static_mesh_blocked (expected)" % error_count)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_meshes_report.json"),
        )
    )
