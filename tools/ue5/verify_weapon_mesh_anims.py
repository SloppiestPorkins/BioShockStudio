"""Headless verify: weapon-mesh reload PlayAnimation (not ViewHands, not world transform).

h10's weapon-track test proved the pistol actor's world transform follows the hand socket
during Reload(). That is not this bug: BioShock FP is a two-rig performance — ViewHands
plays FastReloadPistol / ReloadTommyGun / … while the weapon's own skeletal mesh must play
FastReload / Reload / … on its own bones (barrel hinge, bolt, etc.).

Confirms each WP_<Def>/Animations reload asset loads, then GiveWeaponByDef + EquipWeapon +
Reload() and asserts Mesh's active AnimSequence name matches the expected leaf.
"""

import json
import os

import unreal


# Def → (slot, expected AnimSequence leaf under /Game/BioShockWeapons/WP_<Def>/Animations/).
# Leaf names from disk (5 Sept 2026) — hands clips keep the weapon suffix; weapon clips do not.
_WEAPONS = {
    "Pistol": {"slot": 1, "reload": "FastReload"},
    "TommyGun": {"slot": 2, "reload": "Reload"},
    "Shotgun": {"slot": 3, "reload": "Reload"},
    "ChemicalThrower": {"slot": 5, "reload": "Reload"},
    "Crossbow": {"slot": 6, "reload": "Reload"},
}


def _log(message):
    unreal.log("[bioshock-weapon-mesh-anims] %s" % message)


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


def _anim_path(def_name, leaf):
    return "/Game/BioShockWeapons/WP_%s/Animations/%s.%s" % (def_name, leaf, leaf)


def _playing_mesh(weapon):
    if not weapon:
        return ""
    return str(weapon.get_playing_mesh_animation_name_for_verify())


def main(out):
    report = {"failures": [], "assets": {}, "weapons": {}}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not player_cls:
        failures.append("ShockPlayer class missing")
        _write(out, report)
        raise RuntimeError("weapon-mesh-anims:\n- " + "\n- ".join(failures))

    for def_name, spec in _WEAPONS.items():
        leaf = spec["reload"]
        path = _anim_path(def_name, leaf)
        asset = unreal.load_asset(path)
        report["assets"][def_name] = {"path": path, "ok": asset is not None, "leaf": leaf}
        if asset is None:
            failures.append("asset missing: %s (%s)" % (def_name, path))

    if failures:
        _write(out, report)
        raise RuntimeError("weapon-mesh-anims:\n- " + "\n- ".join(failures))

    spawned = []
    player = _spawn(
        subsystem, player_cls, "WeaponMeshAnimPlayer", unreal.Vector(0.0, 0.0, 100.0)
    )
    spawned.append(player)
    if not player:
        failures.append("spawn player")
        _write(out, report)
        raise RuntimeError("weapon-mesh-anims:\n- " + "\n- ".join(failures))

    for def_name, spec in _WEAPONS.items():
        entry = {"def": def_name, "expectedReload": spec["reload"]}
        weapon = player.give_weapon_by_def(unreal.Name(def_name), int(spec["slot"]))
        if not weapon:
            failures.append("GiveWeaponByDef(%s) null" % def_name)
            report["weapons"][def_name] = entry
            continue

        player.equip_weapon(weapon)
        before = _playing_mesh(weapon)
        entry["meshAnimBeforeReload"] = before

        mag = int(weapon.get_magazine_size())
        reserve = int(weapon.get_reserve_ammo())
        if mag <= 0 or reserve <= 0:
            failures.append("%s cannot reload (mag=%d reserve=%d)" % (def_name, mag, reserve))
            report["weapons"][def_name] = entry
            continue

        weapon.set_ammo_state_for_verify(max(0, mag - 1), reserve)
        weapon.set_auto_reload(False)
        if not player.try_reload_equipped_weapon():
            failures.append("%s TryReload returned false" % def_name)
            report["weapons"][def_name] = entry
            continue

        reload_anim = _playing_mesh(weapon)
        entry["meshAnimAfterReload"] = reload_anim
        if spec["reload"] not in reload_anim:
            failures.append(
                "%s weapon mesh anim=%r expected %s (ViewHands-only / screen-pin != this)"
                % (def_name, reload_anim, spec["reload"])
            )
        else:
            entry["ok"] = True
        report["weapons"][def_name] = entry
        _log("%s meshReload=%s" % (def_name, reload_anim))

    for actor in spawned:
        if actor:
            subsystem.destroy_actor(actor)

    report["ok"] = len(failures) == 0
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-mesh-anims:\n- " + "\n- ".join(failures))
    _log("ok")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_mesh_anims_report.json"),
        )
    )
