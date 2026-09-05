"""Headless verify: per-weapon grip sockets + ViewHands fidget/fire/reload.

Equips TommyGun / Pistol / Crossbow via GiveWeaponByDef + EquipWeapon, asserts the grip
socket matches that weapon's own socket name (not a stale TommyGun match), asserts the
weapon-specific fidget is playing after equip finishes, fires once and asserts the fire
clip, then advances past the fire length and asserts return to that weapon's fidget.

Also samples grip-socket world location vs weapon root bone and mesh bounds center so a
gross sideways misalignment (TommyGun "off to the side") is headlessly detectable — not
just "did a socket name resolve". Framing feel still needs a human look afterward.

Shotgun / ChemicalThrower equip cleanly with no animation assertion (zero FP clips imported).
Wrench is excluded (no skeletal viewmodel — h3). Zoomed-in variants are not wired (no ADS
signal in this codebase yet).
"""

import json
import os

import unreal


# Exact leaf names under /Game/BioShockWeapons/NEWPlayerHands/Animations/ — casing from disk.
_ANIMATED = {
    "TommyGun": {
        "slot": 2,
        "fidget": "FidgetTommygun",
        "fire": "FireTommyGun",
        "reload": "ReloadTommyGun",
        "equip": "EquipTommygun",
    },
    "Pistol": {
        "slot": 1,
        "fidget": "FidgetPistol",
        "fire": "FireSinglePistol",
        "reload": "FastReloadPistol",
        "equip": "EquipPistol",
    },
    "Crossbow": {
        "slot": 6,
        "fidget": "FidgetCrossbow",
        "fire": "FireCrossbow",
        "reload": "ReloadCrossbow",
        "equip": "EquipCrossbow",
    },
}

_UNANIMATED = {
    "Shotgun": 3,
    "ChemicalThrower": 5,
}

_ANIM_ROOT = "/Game/BioShockWeapons/NEWPlayerHands/Animations"


def _log(message):
    unreal.log("[bioshock-viewmodel-anims] %s" % message)


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


def _anim_path(leaf):
    return "%s/%s.%s" % (_ANIM_ROOT, leaf, leaf)


def _playing(player):
    if not player:
        return ""
    return str(player.get_playing_view_hands_animation_name_for_verify())


def _socket(player):
    if not player:
        return ""
    return str(player.get_active_grip_socket_for_verify())


def _play_length(asset):
    if asset is None:
        return 0.0
    try:
        return float(asset.get_editor_property("sequence_length"))
    except Exception:  # noqa: BLE001
        try:
            return float(asset.get_play_length())
        except Exception:  # noqa: BLE001
            return 1.0


def _advance_past(player, seconds, step=0.05):
    remaining = float(seconds) + 0.05
    while remaining > 0.0:
        chunk = min(step, remaining)
        player.advance_view_hands_animation_for_verify(chunk)
        remaining -= chunk


def main(out):
    report = {"failures": [], "assets": {}, "weapons": {}}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not player_cls:
        failures.append("ShockPlayer class missing")
        _write(out, report)
        raise RuntimeError("viewmodel-anims:\n- " + "\n- ".join(failures))

    # Confirm each hardcoded path resolves before asserting runtime behaviour.
    for def_name, spec in _ANIMATED.items():
        for kind in ("fidget", "fire", "reload", "equip"):
            leaf = spec[kind]
            path = _anim_path(leaf)
            asset = unreal.load_asset(path)
            key = "%s.%s" % (def_name, kind)
            report["assets"][key] = {"path": path, "ok": asset is not None}
            if asset is None:
                failures.append("asset missing: %s (%s)" % (key, path))
            else:
                report["assets"][key]["length"] = _play_length(asset)

    hands = unreal.load_asset(
        "/Game/BioShockWeapons/NEWPlayerHands/NEWPlayerHands.NEWPlayerHands"
    )
    report["assets"]["NEWPlayerHands"] = hands is not None
    if hands is None:
        failures.append("NEWPlayerHands skeletal mesh missing")

    if failures:
        _write(out, report)
        raise RuntimeError("viewmodel-anims:\n- " + "\n- ".join(failures))

    spawned = []
    player = _spawn(subsystem, player_cls, "ViewmodelAnimPlayer", unreal.Vector(0.0, 0.0, 100.0))
    spawned.append(player)
    if not player:
        failures.append("spawn player")
        _write(out, report)
        raise RuntimeError("viewmodel-anims:\n- " + "\n- ".join(failures))

    for def_name, spec in _ANIMATED.items():
        entry = {"def": def_name}
        weapon = player.give_weapon_by_def(unreal.Name(def_name), int(spec["slot"]))
        if not weapon:
            failures.append("GiveWeaponByDef(%s) null" % def_name)
            report["weapons"][def_name] = entry
            continue

        player.equip_weapon(weapon)
        socket = _socket(player)
        entry["socketAfterEquip"] = socket
        if socket != def_name:
            failures.append(
                "%s grip socket=%r expected %r (stale TommyGun / NAME_None regression)"
                % (def_name, socket, def_name)
            )

        # Socket vs mesh: root bone must sit on the grip (context.md attachment rule). Bounds
        # center is sampled for gross sideways misalignment (camera-space |Y|), not as a
        # precise framing assert — framing feel remains a human look-and-tune.
        root_dist = float(player.get_grip_to_weapon_root_distance_for_verify())
        lateral = float(player.get_grip_to_weapon_bounds_lateral_distance_for_verify())
        socket_world = player.get_active_grip_socket_world_location_for_verify()
        bounds_world = player.get_equipped_weapon_bounds_center_for_verify()
        root_world = player.get_equipped_weapon_root_bone_world_location_for_verify()
        entry["gripAlign"] = {
            "rootDist": root_dist,
            "boundsLateral": lateral,
            "socket": [socket_world.x, socket_world.y, socket_world.z],
            "root": [root_world.x, root_world.y, root_world.z],
            "boundsCenter": [bounds_world.x, bounds_world.y, bounds_world.z],
        }
        if root_dist < 0.0:
            failures.append("%s grip/root distance unreadable" % def_name)
        elif root_dist > 5.0:
            failures.append(
                "%s grip-to-root distance %.2f uu (expected ~0 after root-bone align; "
                "weapon mesh origin ≠ R_grip)"
                % (def_name, root_dist)
            )
        # Gross sideways only: a forward gun's bounds can sit far along +X; |Y| >> 80 with a
        # seated root is the "off to the side" class of failure.
        if def_name == "TommyGun" and lateral > 80.0:
            failures.append(
                "TommyGun bounds center %.1f uu lateral of grip in camera space "
                "(gross sideways misalignment)"
                % lateral
            )

        # TommyGun ammo drum = bone TG_AmmoClip on the same skeleton (not a second component).
        if def_name == "TommyGun":
            mesh_count = int(player.get_equipped_weapon_skeletal_mesh_component_count_for_verify())
            has_clip = bool(
                player.does_equipped_weapon_bone_exist_for_verify(unreal.Name("TG_AmmoClip"))
            )
            has_body = bool(
                player.does_equipped_weapon_bone_exist_for_verify(unreal.Name("TG_TommyGunBody"))
            )
            clip_dist = float(
                player.get_equipped_weapon_bone_distance_for_verify(
                    unreal.Name("TG_TommyGunBody"), unreal.Name("TG_AmmoClip")
                )
            )
            entry["ammoDrum"] = {
                "skeletalMeshComponents": mesh_count,
                "hasTG_AmmoClip": has_clip,
                "hasTG_TommyGunBody": has_body,
                "bodyToClipDist": clip_dist,
            }
            if mesh_count != 1:
                failures.append(
                    "TommyGun skeletal mesh component count %d (expected 1 — drum is same skeleton)"
                    % mesh_count
                )
            if not has_clip:
                failures.append("TommyGun missing TG_AmmoClip bone after equip/align")
            if not has_body:
                failures.append("TommyGun missing TG_TommyGunBody bone after equip/align")
            if clip_dist < 0.0:
                failures.append("TommyGun body↔TG_AmmoClip distance unreadable")
            elif clip_dist > 80.0:
                failures.append(
                    "TommyGun TG_AmmoClip %.1f uu from TG_TommyGunBody after root align "
                    "(same-skeleton drum should stay with the body)"
                    % clip_dist
                )

        equip_len = float(report["assets"]["%s.equip" % def_name].get("length", 1.0))
        _advance_past(player, equip_len)
        fidget = _playing(player)
        entry["fidgetAfterEquip"] = fidget
        if spec["fidget"] not in fidget:
            failures.append(
                "%s idle anim=%r expected %s (not always FidgetTommygun)"
                % (def_name, fidget, spec["fidget"])
            )

        weapon.clear_fire_cooldown_for_verify()
        weapon.set_auto_reload(False)
        # Drain mag partially so fire can spend a round; reload test needs room in mag.
        player.try_fire_equipped_weapon()
        fire_anim = _playing(player)
        entry["fireAnim"] = fire_anim
        if spec["fire"] not in fire_anim:
            failures.append(
                "%s fire anim=%r expected %s" % (def_name, fire_anim, spec["fire"])
            )

        fire_len = float(report["assets"]["%s.fire" % def_name].get("length", 1.0))
        _advance_past(player, fire_len)
        after_fire = _playing(player)
        entry["fidgetAfterFire"] = after_fire
        if spec["fidget"] not in after_fire:
            failures.append(
                "%s did not return to fidget after fire (got %r, want %s)"
                % (def_name, after_fire, spec["fidget"])
            )

        # Reload: empty some rounds so Reload() is allowed, then trigger.
        mag = int(weapon.get_magazine_size())
        reserve = int(weapon.get_reserve_ammo())
        if mag > 0 and reserve > 0:
            weapon.set_ammo_state_for_verify(max(0, mag - 1), reserve)
            if player.try_reload_equipped_weapon():
                reload_anim = _playing(player)
                entry["reloadAnim"] = reload_anim
                if spec["reload"] not in reload_anim:
                    failures.append(
                        "%s reload anim=%r expected %s"
                        % (def_name, reload_anim, spec["reload"])
                    )
                reload_len = float(
                    report["assets"]["%s.reload" % def_name].get("length", 1.0)
                )
                _advance_past(player, reload_len)
                after_reload = _playing(player)
                entry["fidgetAfterReload"] = after_reload
                if spec["fidget"] not in after_reload:
                    failures.append(
                        "%s did not return to fidget after reload (got %r)"
                        % (def_name, after_reload)
                    )
            else:
                entry["reloadSkipped"] = "TryReload returned false"

        report["weapons"][def_name] = entry
        _log(
            "%s socket=%s fidget=%s fire=%s"
            % (def_name, socket, entry.get("fidgetAfterEquip"), entry.get("fireAnim"))
        )

    for def_name, slot in _UNANIMATED.items():
        entry = {"def": def_name, "animated": False}
        weapon = player.give_weapon_by_def(unreal.Name(def_name), int(slot))
        if not weapon:
            failures.append("GiveWeaponByDef(%s) null (unanimate — equip must not crash)" % def_name)
        else:
            player.equip_weapon(weapon)
            entry["socket"] = _socket(player)
            entry["anim"] = _playing(player)
            entry["equipped"] = True
            # No fidget/fire assertion — zero clips on disk; holding bind/last pose is correct.
        report["weapons"][def_name] = entry
        _log("%s equip-ok (unanimate) socket=%s" % (def_name, entry.get("socket")))

    for actor in spawned:
        if actor:
            subsystem.destroy_actor(actor)

    report["ok"] = len(failures) == 0
    _write(out, report)
    if failures:
        raise RuntimeError("viewmodel-anims:\n- " + "\n- ".join(failures))
    _log("ok")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "viewmodel_anims_report.json"),
        )
    )
