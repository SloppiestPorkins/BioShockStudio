"""Headless verify: level travel carry-state capture, restore, and starter-loadout branch."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-level-travel] %s" % message)


def _spawn(subsystem, cls, label, loc):
    actor = subsystem.spawn_actor_from_class(cls, loc, unreal.Rotator(0.0, 0.0, 0.0))
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


def _configure_distinctive_player(player, electro_cls, inc_cls):
    player.ensure_health_initialized()
    player.set_current_health_for_verify(55.0)
    player.set_current_eve_for_verify(30.0)

    pistol = player.give_weapon_by_def(unreal.Name("Pistol"), 1)
    tommy = player.give_weapon_by_def(unreal.Name("TommyGun"), 2)
    if tommy:
        tommy.set_ammo_state_for_verify(12, 88)

    player.equip_plasmid(electro_cls, 0)
    player.equip_plasmid(inc_cls, 1)
    player.add_research_points(unreal.Name("Agg_BabyJane"), 250.0)
    player.add_stack_to_inventory(unreal.Name("FirstAidKit"), 3)
    player.add_money(175)
    player.select_weapon_slot(2)
    return pistol, tommy


def _assert_carried_state(player, failures, prefix=""):
    def expect(name, ok, detail=None):
        if not ok:
            failures.append("%s%s: %s" % (prefix, name, detail))

    health = float(player.get_current_health())
    expect("health", abs(health - 55.0) < 0.5, health)

    eve = float(player.get_current_eve())
    expect("eve", abs(eve - 30.0) < 0.5, eve)

    pistol = player.get_weapon_in_slot(1)
    tommy = player.get_weapon_in_slot(2)
    expect("pistol_slot", pistol is not None)
    expect("tommy_slot", tommy is not None)
    if tommy:
        expect("tommy_mag", int(tommy.get_rounds_in_magazine()) == 12, tommy.get_rounds_in_magazine())

    plasmid0 = player.equipped_plasmids[0] if player.equipped_plasmids else None
    plasmid1 = player.equipped_plasmids[1] if len(player.equipped_plasmids) > 1 else None
    expect("electro_plasmid", plasmid0 is not None)
    expect("incinerate_plasmid", plasmid1 is not None)

    research_pts = float(player.get_research_points_for_verify(unreal.Name("Agg_BabyJane")))
    expect("research_points", abs(research_pts - 250.0) < 0.5, research_pts)
    level = int(player.get_research_level(unreal.Name("Agg_BabyJane")))
    expect("research_level", level == 1, level)

    kits = int(player.get_inventory_stack(unreal.Name("FirstAidKit")))
    expect("first_aid", kits == 3, kits)

    money = int(player.get_money())
    expect("money", money == 175, money)

    expect("active_weapon_slot", int(player.get_active_weapon_slot()) == 2)


def main(out):
    report = {"failures": [], "checks": 0}
    failures = report["failures"]
    checks = 0

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    gm_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockGameMode")
    electro_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockElectroBoltPlasmid")
    inc_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockIncineratePlasmid")
    change_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeLevel")

    if not all([player_cls, gm_cls, electro_cls, inc_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("level travel:\n- " + "\n- ".join(failures))

    spawned = []

    def check(name, ok, detail=None):
        nonlocal checks
        checks += 1
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report.setdefault("results", []).append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    # --- (a) direct capture -> restore ---
    source = _spawn(subsystem, player_cls, "TravelSource", unreal.Vector(0.0, 0.0, 120.0))
    spawned.append(source)
    if not source:
        failures.append("spawn source failed")
    else:
        _configure_distinctive_player(source, electro_cls, inc_cls)
        carry = unreal.ShockCarryState.capture(source)
        check("capture", carry is not None)

        dest = _spawn(subsystem, player_cls, "TravelDest", unreal.Vector(200.0, 0.0, 120.0))
        spawned.append(dest)
        if carry and dest:
            carry.restore_onto(dest)
            before_failures = len(failures)
            _assert_carried_state(dest, failures, prefix="restore:")
            check("restore_fields", len(failures) == before_failures)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (b) UShockGameInstance pending consume ---
    gi_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockGameInstance")
    traveler = _spawn(subsystem, player_cls, "TravelPending", unreal.Vector(50.0, 200.0, 120.0))
    spawned.append(traveler)
    if gi_cls and traveler:
        gi = unreal.new_object(gi_cls)
        _configure_distinctive_player(traveler, electro_cls, inc_cls)
        carry = unreal.ShockCarryState.capture(traveler)
        gi.set_pending_carry_for_verify(carry, unreal.Name("DestArrival"))
        check("pending_set", bool(gi.has_pending_arrival()))

        arrival = _spawn(subsystem, player_cls, "TravelArrival", unreal.Vector(100.0, 200.0, 120.0))
        spawned.append(arrival)
        restored = bool(gi.consume_pending_arrival(arrival))
        check("gi_restored", restored)
        check("pending_cleared", not bool(gi.has_pending_arrival()))
        before_failures = len(failures)
        _assert_carried_state(arrival, failures, prefix="gi:")
        check("gi_restore_fields", len(failures) == before_failures)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (c) no pending -> ApplyArrivalLoadout does not restore (starter equip covered by game_possess) ---
    world = unreal.EditorLevelLibrary.get_editor_world()
    gm2 = unreal.new_object(gm_cls, outer=world) if world else None
    fresh = _spawn(subsystem, player_cls, "StarterApply", unreal.Vector(50.0, 400.0, 120.0))
    spawned.append(fresh)
    if fresh and gm2 and gi_cls and world:
        gi_world = unreal.ShockGameInstance.get_shock_instance_for_verify(world)
        if gi_world:
            gi_world.clear_pending_arrival()
        restored = bool(gm2.apply_arrival_loadout(fresh))
        check("starter_apply_not_restore", not restored)

    _destroy_all(subsystem, spawned)
    spawned = []

    # --- (d) ActionChangeLevel records map and calls TravelToLevel (no OpenLevel in editor) ---
    if change_cls:
        action = unreal.new_object(change_cls)
        action.configure("/Game/BioShockSlice/_TravelDest", "DestArrival", False, True)
        check("request_change", bool(action.request_change()))
        # ApplyInWorld would OpenLevel; verify RequestChange + configure only here.
        check("action_map", action.get_last_map_name() == "/Game/BioShockSlice/_TravelDest")

    report["checks"] = checks
    report["levelTravel"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("level travel:\n- " + "\n- ".join(failures))
    _log("Success - %d error(s)" % checks)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "level_travel_report.json"),
        )
    )
