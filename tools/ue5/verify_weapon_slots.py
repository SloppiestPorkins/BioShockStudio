"""Headless verify: weapon holster slots, Pistol hitscan, Shotgun pellet spread."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-weapon-slots] %s" % message)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _destroy_all(subsystem, actors):
    for actor in actors:
        if not actor:
            continue
        try:
            if hasattr(actor, "is_valid") and not actor.is_valid():
                continue
            subsystem.destroy_actor(actor)
        except Exception:  # noqa: BLE001
            pass


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    pawn_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")

    if not player_cls or not pawn_cls:
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("weapon-slots:\n- " + "\n- ".join(failures))

    spawned = []
    base_loc = unreal.Vector(0.0, 0.0, 100.0)
    direction = unreal.Vector(1.0, 0.0, 0.0)

    player = _spawn(subsystem, player_cls, "SlotPlayer", base_loc)
    spawned.append(player)
    if not player:
        failures.append("player spawn")
        _write(out, report)
        raise RuntimeError("weapon-slots:\n- " + "\n- ".join(failures))

    player.give_weapon_by_def(unreal.Name("Wrench"), 0)
    player.give_weapon_by_def(unreal.Name("Pistol"), 1)
    player.give_weapon_by_def(unreal.Name("TommyGun"), 2)
    player.give_weapon_by_def(unreal.Name("Shotgun"), 3)

    wrench = player.get_weapon_in_slot(0)
    pistol = player.get_weapon_in_slot(1)
    tommy = player.get_weapon_in_slot(2)
    shotgun = player.get_weapon_in_slot(3)
    if not all([wrench, pistol, tommy, shotgun]):
        failures.append("give_weapon_by_def missing slot weapon")

    # --- slot switch + visibility ---
    if not player.select_weapon_slot(1):
        failures.append("select_weapon_slot(1) failed")
    elif player.get_equipped_weapon() != pistol:
        failures.append("slot 1 equip mismatch")
    else:
        vis = {
            "wrench": bool(player.is_weapon_slot_hidden(0)),
            "pistol": bool(player.is_weapon_slot_hidden(1)),
            "tommy": bool(player.is_weapon_slot_hidden(2)),
            "shotgun": bool(player.is_weapon_slot_hidden(3)),
        }
        report["slot1Visibility"] = vis
        if not vis["wrench"] or vis["pistol"] or not vis["tommy"] or not vis["shotgun"]:
            failures.append("slot 1 visibility wrong: %s" % vis)

    player.select_weapon_slot(2)
    if player.get_equipped_weapon() != tommy:
        failures.append("slot 2 equip mismatch")
    if player.is_weapon_slot_hidden(2):
        failures.append("slot 2 tommy hidden")

    # NextWeapon skips empty slot 4..7 and wraps 3 -> 0
    player.select_weapon_slot(3)
    player.next_weapon()
    if player.get_active_weapon_slot() != 0:
        failures.append(
            "next_weapon wrap expected slot 0 got %d" % int(player.get_active_weapon_slot())
        )

    player.prev_weapon()
    if player.get_active_weapon_slot() != 3:
        failures.append(
            "prev_weapon wrap expected slot 3 got %d" % int(player.get_active_weapon_slot())
        )

    report["slots"] = {
        "activeAfterNext": int(player.get_active_weapon_slot()),
    }

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- GrenadeLauncher via real WeaponSlot5 input path (not direct EquipWeapon) ---
    # Pre-h16: EquipStarterWeapon never gave GL, and HandleWeaponSlot5Input skipped slot 4
    # (Key 5 → Chem). Headless GiveWeaponByDef(GL)+EquipWeapon still passed — that bypasses
    # both bugs. DriveWeaponSlotInputForVerify(5) must land on an owned GL in slot 4.
    player = _spawn(subsystem, player_cls, "GLSlotPlayer", base_loc + unreal.Vector(0.0, 200.0, 0.0))
    spawned.append(player)
    if not player:
        failures.append("GL slot player spawn")
    else:
        for def_name, slot in (
            ("Wrench", 0),
            ("Pistol", 1),
            ("TommyGun", 2),
            ("Shotgun", 3),
            ("GrenadeLauncher", 4),
            ("ChemicalThrower", 5),
            ("Crossbow", 6),
        ):
            player.give_weapon_by_def(unreal.Name(def_name), slot)
        gl = player.get_weapon_in_slot(4)
        report["grenadeLauncherOwned"] = {
            "owned": bool(gl),
            "def": str(gl.get_weapon_def_name()) if gl else None,
        }
        if not gl:
            failures.append("GiveWeaponByDef(GrenadeLauncher, 4) null")
        else:
            # Key 4 = Shotgun (slot 3); Key 5 = GrenadeLauncher (slot 4).
            player.drive_weapon_slot_input_for_verify(5)
            equipped = player.get_equipped_weapon()
            active = int(player.get_active_weapon_slot())
            report["grenadeLauncherSlot5Input"] = {
                "activeSlot": active,
                "equippedDef": str(equipped.get_weapon_def_name()) if equipped else None,
            }
            if active != 4:
                failures.append(
                    "DriveWeaponSlotInputForVerify(5) expected slot 4 got %d" % active
                )
            elif equipped != gl:
                failures.append(
                    "DriveWeaponSlotInputForVerify(5) equipped mismatch "
                    "(want GrenadeLauncher from slot 4)"
                )
            player.drive_weapon_slot_input_for_verify(4)
            if int(player.get_active_weapon_slot()) != 3:
                failures.append(
                    "DriveWeaponSlotInputForVerify(4) expected Shotgun slot 3 got %d"
                    % int(player.get_active_weapon_slot())
                )

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Pistol 40 dmg one shot ---
    player = _spawn(subsystem, player_cls, "PistolPlayer", base_loc + unreal.Vector(0.0, 400.0, 0.0))
    target = _spawn(
        subsystem,
        pawn_cls,
        "PistolTarget",
        base_loc + unreal.Vector(0.0, 400.0, 0.0) + unreal.Vector(500.0, 0.0, 0.0),
    )
    spawned.extend([player, target])
    if player and target:
        player.give_weapon_by_def(unreal.Name("Pistol"), 1)
        player.select_weapon_slot(1)
        pistol = player.get_equipped_weapon()
        pistol.clear_fire_cooldown_for_verify()
        target.ensure_health_initialized()
        hp_before = float(target.get_current_health())
        mag_before = int(pistol.get_rounds_in_magazine())
        pistol.fire_at(player, base_loc + unreal.Vector(0.0, 400.0, 0.0), direction)
        hp_after = float(target.get_current_health())
        mag_after = int(pistol.get_rounds_in_magazine())
        drop = hp_before - hp_after
        report["pistol"] = {
            "healthDrop": drop,
            "magBefore": mag_before,
            "magAfter": mag_after,
        }
        if abs(drop - 40.0) > 0.5:
            failures.append("pistol damage expected 40 got %.1f" % drop)
        if mag_after != mag_before - 1:
            failures.append("pistol consumed wrong rounds")

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Shotgun close: multi-hit, one round ---
    player = _spawn(subsystem, player_cls, "ShotgunPlayer", base_loc + unreal.Vector(0.0, 800.0, 0.0))
    close = _spawn(
        subsystem,
        pawn_cls,
        "ShotgunClose",
        base_loc + unreal.Vector(0.0, 800.0, 0.0) + unreal.Vector(300.0, 0.0, 0.0),
    )
    spawned.extend([player, close])
    if player and close:
        player.give_weapon_by_def(unreal.Name("Shotgun"), 3)
        player.select_weapon_slot(3)
        sg = player.get_equipped_weapon()
        sg.clear_fire_cooldown_for_verify()
        close.ensure_health_initialized()
        hp_before = float(close.get_current_health())
        mag_before = int(sg.get_rounds_in_magazine())
        sg.fire_at(player, base_loc + unreal.Vector(0.0, 800.0, 0.0), direction)
        hp_after = float(close.get_current_health())
        mag_after = int(sg.get_rounds_in_magazine())
        drop = hp_before - hp_after
        report["shotgunClose"] = {
            "healthDrop": drop,
            "magBefore": mag_before,
            "magAfter": mag_after,
            "pelletCount": int(sg.get_editor_property("pellet_count")),
        }
        if mag_after != mag_before - 1:
            failures.append("shotgun close consumed wrong rounds")
        if drop < 20.0 or drop > 45.0:
            failures.append("shotgun close total damage %.1f outside 20-45 band" % drop)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- Shotgun oblique: spread misses most pellets ---
    player = _spawn(subsystem, player_cls, "ShotgunFarPlayer", base_loc + unreal.Vector(0.0, 1200.0, 0.0))
    oblique = _spawn(
        subsystem,
        pawn_cls,
        "ShotgunOblique",
        base_loc + unreal.Vector(0.0, 1200.0, 0.0) + unreal.Vector(1200.0, 400.0, 0.0),
    )
    spawned.extend([player, oblique])
    if player and oblique:
        player.give_weapon_by_def(unreal.Name("Shotgun"), 3)
        player.select_weapon_slot(3)
        sg = player.get_equipped_weapon()
        sg.clear_fire_cooldown_for_verify()
        oblique.ensure_health_initialized()
        hp_before = float(oblique.get_current_health())
        aim = unreal.Vector(1.0, 0.0, 0.0)
        sg.fire_at(player, base_loc + unreal.Vector(0.0, 1200.0, 0.0), aim)
        hp_after = float(oblique.get_current_health())
        drop = hp_before - hp_after
        report["shotgunOblique"] = {"healthDrop": drop}
        if drop > 15.0:
            failures.append("shotgun oblique hit too hard (%.1f)" % drop)

    _destroy_all(subsystem, spawned)

    error_count = len(failures)
    report["errorCount"] = error_count
    report["weapon_slots"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-slots (%d errors):\n- " % error_count + "\n- ".join(failures))
    _log("Success - %d error(s)" % error_count)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_slots_report.json"),
        )
    )
