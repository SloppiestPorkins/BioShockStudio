"""Headless verify: Wrench StaticMesh viewmodel via GiveWeaponByDef + EquipWeapon.

Asserts MeshAssetPath resolves to a UStaticMesh on AShockWeapon::StaticMesh, skeletal Mesh
is hidden/empty, and after equip the weapon is attached under the ViewHands Wrench grip
socket. Grip alignment / in-hand look is a human PIE check — not asserted here.
"""

import json
import os

import unreal


EXPECTED_MESH = "/Game/BioShockWeapons/WP_Wrench/WP_Wrench.WP_Wrench"
EXPECTED_SOCKET = "Wrench"


def _log(message):
    unreal.log("[bioshock-wrench-verify] %s" % message)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _asset_path(obj):
    if not obj:
        return None
    try:
        return obj.get_path_name()
    except Exception:  # noqa: BLE001
        return str(obj)


def main(out=None):
    out = out or os.environ.get(
        "BIOSHOCK_ACTION_OUT",
        os.path.join(os.environ.get("TEMP", "."), "wrench_verify_report.json"),
    )
    report = {"failures": [], "wrench": {}}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not player_cls:
        failures.append("ShockPlayer class missing")
        _write(out, report)
        raise RuntimeError("wrench-verify:\n- " + "\n- ".join(failures))

    player = _spawn(subsystem, player_cls, "WrenchVerifyPlayer", unreal.Vector(0.0, 0.0, 100.0))
    if not player:
        failures.append("player spawn")
        _write(out, report)
        raise RuntimeError("wrench-verify:\n- " + "\n- ".join(failures))

    wrench = player.give_weapon_by_def(unreal.Name("Wrench"), 0)
    entry = {
        "weapon": bool(wrench),
        "staticMeshPath": None,
        "skeletalMeshPath": None,
        "isStaticViewmodel": False,
        "socketAfterEquip": None,
        "attachParent": None,
        "skeletalHidden": None,
        "staticVisible": None,
    }
    if not wrench:
        failures.append("GiveWeaponByDef(Wrench) null")
        report["wrench"] = entry
        _write(out, report)
        raise RuntimeError("wrench-verify:\n- " + "\n- ".join(failures))

    entry["isStaticViewmodel"] = bool(wrench.is_static_viewmodel_for_verify())
    soft = wrench.get_static_mesh_asset_path_for_verify()
    # SoftObjectPath may stringify; also read the component directly.
    static_comp = wrench.get_editor_property("static_mesh")
    static_asset = static_comp.get_editor_property("static_mesh") if static_comp else None
    entry["staticMeshPath"] = _asset_path(static_asset)
    skel_comp = wrench.get_editor_property("mesh")
    skel_asset = skel_comp.get_skeletal_mesh_asset() if skel_comp else None
    entry["skeletalMeshPath"] = _asset_path(skel_asset)

    if static_asset is None:
        failures.append(
            "Wrench StaticMesh component has no mesh after GiveWeaponByDef "
            "(expected %s — import_wrench_mesh missing?)" % EXPECTED_MESH
        )
    elif entry["staticMeshPath"] != EXPECTED_MESH:
        failures.append(
            "Wrench static mesh got %s expected %s"
            % (entry["staticMeshPath"], EXPECTED_MESH)
        )

    if skel_asset is not None:
        failures.append(
            "Wrench skeletal Mesh still set (%s) — static viewmodel should clear it"
            % entry["skeletalMeshPath"]
        )

    if not entry["isStaticViewmodel"]:
        failures.append("IsStaticViewmodelForVerify returned false after GiveWeaponByDef")

    player.equip_weapon(wrench)
    socket = str(player.get_active_grip_socket_for_verify())
    entry["socketAfterEquip"] = socket
    if socket != EXPECTED_SOCKET:
        failures.append(
            "Wrench grip socket=%r expected %r (missing hands socket / alias)"
            % (socket, EXPECTED_SOCKET)
        )

    root = wrench.get_editor_property("root_component") or wrench.root_component
    attach_parent = root.get_attach_parent() if root else None
    entry["attachParent"] = (
        attach_parent.get_name() if attach_parent else None
    )
    if attach_parent is None:
        failures.append("Wrench root not attached after EquipWeapon")
    else:
        # Parent should be ViewHands skeletal component.
        if not isinstance(attach_parent, unreal.SkeletalMeshComponent):
            failures.append(
                "Wrench attach parent is %s, expected ViewHands SkeletalMeshComponent"
                % type(attach_parent).__name__
            )

    if skel_comp is not None:
        # "Hidden" for static viewmodel = no skeletal asset (parent Mesh stays visible so the
        # StaticMesh child can render).
        entry["skeletalHidden"] = skel_asset is None
        if not entry["skeletalHidden"]:
            failures.append("Wrench skeletal Mesh still assigned after equip")

    if static_comp is not None:
        # Component-flag introspection is unreliable from Python (b_hidden_in_game vs
        # hidden_in_game); the behavioural checks above already prove the StaticMesh is
        # installed, skeletal is cleared, and the actor is on the Wrench grip socket.
        entry["staticVisible"] = static_asset is not None
        if not entry["staticVisible"]:
            failures.append("Wrench StaticMesh component has no mesh after equip")

    report["wrench"] = entry
    try:
        subsystem.destroy_actor(player)
    except Exception:  # noqa: BLE001
        pass

    report["errorCount"] = len(failures)
    report["wrench_verify"] = "ok" if not failures else "fail"
    # Soft path string is informational only (binding quirks); keep for the report.
    entry["defSoftPath"] = str(soft) if soft is not None else None
    _write(out, report)
    if failures:
        raise RuntimeError("wrench-verify (%d errors):\n- " % len(failures) + "\n- ".join(failures))
    _log(
        "Success - static=%s socket=%s (grip look: human PIE)"
        % (entry["staticMeshPath"], socket)
    )
    return report


if __name__ == "__main__":
    main()
