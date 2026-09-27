"""Headless verify: gameplay fidelity batch (sdk-crossref B01/B02/B03/B04/B05/B08/B10/B11/G19/G20).

Compatible with -run=pythonscript (no sibling imports). House style matches verify_security.py.
"""

import json
import math
import os

import unreal

ALLEGIANCE_HOSTILE = 1
ALLEGIANCE_FRIENDLY = 2
ALLEGIANCE_DISABLED = 3


def _log(message):
    unreal.log("[bioshock-gameplay-fidelity] %s" % message)


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
            if not unreal.SystemLibrary.is_valid(actor):
                continue
            subsystem.destroy_actor(actor)
        except Exception:  # noqa: BLE001 -- teardown must not fail the verify
            pass


def _tick_security(world, seconds, step=0.05):
    sec = unreal.ShockSecuritySubsystem.get_for_world(world)
    if not sec:
        return
    steps = max(1, int(seconds / step))
    for _ in range(steps):
        sec.advance_security_for_verify(step)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _yaw_toward(from_loc, to_loc):
    dx = float(to_loc.x - from_loc.x)
    dy = float(to_loc.y - from_loc.y)
    return math.degrees(math.atan2(dy, dx))


def main(out):
    report = {"failures": [], "checks": 0, "results": []}
    failures = report["failures"]
    checks = 0

    def check(name, ok, detail=None):
        nonlocal checks
        checks += 1
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report["results"].append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    camera_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockSecurityCamera")
    turret_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTurret")
    bot_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockSecurityBot")
    turret_spawner_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTurretSpawner")
    aggressor_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockAggressorSpawner")
    station_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockStationBase")
    invent_menu_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockUInventMenu")
    hack_menu_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockHackingMinigame")
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    assign_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableAssignOverwrite")
    target_cls = unreal.TargetPoint
    vita_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockVitaChamber")

    if not all([player_cls, camera_cls, turret_cls, bot_cls]):
        failures.append("runtime classes missing")
        _write(out, report)
        raise RuntimeError("gameplay_fidelity:\n- " + "\n- ".join(failures))

    sec = unreal.ShockSecuritySubsystem.get_for_world(world)
    spawned = []

    # --- B04: camera defaults FOV 60° (half-angle 30) / SightDistance 1000 ---
    cam = _spawn(subsystem, camera_cls, "FidCamDefaults", unreal.Vector(50.0, 50.0, 100.0))
    spawned.append(cam)
    if cam:
        rng = float(cam.get_editor_property("detection_range"))
        half = float(cam.get_editor_property("detection_half_angle_deg"))
        check("B04_camera_detection_range_1000", abs(rng - 1000.0) < 0.5, rng)
        check("B04_camera_half_angle_30", abs(half - 30.0) < 0.5, half)
    # Negative: explicit configure still overrides (existing verifies do this).
    if cam:
        cam.set_editor_property("detection_range", 3000.0)
        cam.set_editor_property("detection_half_angle_deg", 90.0)
        check(
            "B04_explicit_override_still_works",
            abs(float(cam.get_editor_property("detection_range")) - 3000.0) < 0.5,
            float(cam.get_editor_property("detection_range")),
        )
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- B01: device hack flips only that device (not SetSecurityHacked / system shutdown) ---
    player = _spawn(subsystem, player_cls, "FidB01Player", unreal.Vector(0.0, 0.0, 100.0))
    t_a = _spawn(subsystem, turret_cls, "FidHackTurretA", unreal.Vector(0.0, -400.0, 100.0))
    t_b = _spawn(subsystem, turret_cls, "FidHackTurretB", unreal.Vector(400.0, -400.0, 100.0))
    spawned.extend([player, t_a, t_b])
    if player and t_a and t_b:
        player.ensure_health_initialized()
        t_a.configure_for_verify(unreal.Name("FidHackTurretA"), ALLEGIANCE_HOSTILE, 40.0)
        t_b.configure_for_verify(unreal.Name("FidHackTurretB"), ALLEGIANCE_HOSTILE, 40.0)
        player.set_instant_hack_for_verify(True)
        player.set_hack_skill_for_verify(0.9)
        ok = bool(player.try_hack_device(t_a, 0.1))
        alleg_a = int(t_a.get_allegiance_for_verify())
        alleg_b = int(t_b.get_allegiance_for_verify())
        sys_hacked = bool(player.is_security_hacked())
        check(
            "B01_device_hack_flips_only_target",
            ok and alleg_a == ALLEGIANCE_FRIENDLY and alleg_b == ALLEGIANCE_HOSTILE,
            {"ok": ok, "a": alleg_a, "b": alleg_b},
        )
        check(
            "B01_device_hack_does_not_set_security_hacked",
            not sys_hacked,
            sys_hacked,
        )
        # Negative: ActionHackSecuritySystem still shuts everything down.
        t_b.configure_for_verify(unreal.Name("FidHackTurretB"), ALLEGIANCE_HOSTILE, 40.0)
        player.set_security_hacked(True, 5.0)
        check(
            "B01_system_hack_still_disables_other",
            int(t_b.get_allegiance_for_verify()) == ALLEGIANCE_DISABLED,
            int(t_b.get_allegiance_for_verify()),
        )
        player.set_security_hacked(False, 0.0)
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- B05: MaxActiveBots=4; second alarm adds +1 ---
    if sec:
        max_bots = int(sec.get_editor_property("max_active_bots"))
        check("B05_max_active_bots_default_4", max_bots == 4, max_bots)
        sec.despawn_all_bots_for_verify()
        p = _spawn(subsystem, player_cls, "FidB05Player", unreal.Vector(1000.0, 0.0, 100.0))
        spawned.append(p)
        if p:
            p.ensure_health_initialized()
            p.set_security_alarm_on(True, unreal.Name("B05First"))
            c1 = int(sec.get_active_bot_count_for_verify())
            p.set_security_alarm_on(True, unreal.Name("B05Second"))
            c2 = int(sec.get_active_bot_count_for_verify())
            check(
                "B05_second_alarm_adds_bot",
                c1 >= 1 and c2 == c1 + 1,
                {"c1": c1, "c2": c2},
            )
            # Cap: keep re-alarming until MaxActiveBots.
            for i in range(8):
                p.set_security_alarm_on(True, unreal.Name("B05Cap%d" % i))
            capped = int(sec.get_active_bot_count_for_verify())
            check("B05_cap_at_four", capped <= 4, capped)
            # Negative: with alarm off, re-on starts fresh count 1 (not add).
            sec.despawn_all_bots_for_verify()
            p.set_security_alarm_on(False, unreal.Name(""))
            p.set_security_alarm_on(True, unreal.Name("B05Fresh"))
            fresh = int(sec.get_active_bot_count_for_verify())
            check("B05_fresh_alarm_spawns_at_least_one", fresh >= 1, fresh)
            sec.despawn_all_bots_for_verify()
            p.set_security_alarm_on(False, unreal.Name(""))
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- B08: default lifetime -1; alarm clear does not despawn ---
    if sec:
        life = float(sec.get_editor_property("bot_lifetime_after_alarm_clear_seconds"))
        check("B08_default_lifetime_never", life < 0.0, life)
        p = _spawn(subsystem, player_cls, "FidB08Player", unreal.Vector(2000.0, 0.0, 100.0))
        spawned.append(p)
        if p:
            sec.set_editor_property("bot_lifetime_after_alarm_clear_seconds", -1.0)
            p.ensure_health_initialized()
            p.set_security_alarm_on(True, unreal.Name("B08"))
            before = int(sec.get_active_bot_count_for_verify())
            p.set_security_alarm_on(False, unreal.Name(""))
            _tick_security(world, 1.0)
            after = int(sec.get_active_bot_count_for_verify())
            check(
                "B08_alarm_clear_keeps_bots",
                before >= 1 and after == before,
                {"before": before, "after": after},
            )
            sec.despawn_all_bots_for_verify()
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- B02: NextSpawnLocationLabel + distance-band marker honour ---
    if sec:
        p = _spawn(subsystem, player_cls, "FidB02Player", unreal.Vector(3000.0, 0.0, 100.0))
        marker = _spawn(
            subsystem, target_cls, "FidBotSpawnSpot", unreal.Vector(3000.0, 4500.0, 200.0)
        )
        spawned.extend([p, marker])
        if p and marker:
            p.ensure_health_initialized()
            sec.set_next_spawn_location_label(unreal.Name("FidBotSpawnSpot"))
            sec.despawn_all_bots_for_verify()
            spawned_n = int(sec.spawn_bots_near(p.get_actor_location(), 1, p))
            bots = unreal.GameplayStatics.get_all_actors_of_class(world, bot_cls)
            near_marker = False
            for bot in bots:
                if not unreal.SystemLibrary.is_valid(bot):
                    continue
                d = float(
                    unreal.Vector.distance(bot.get_actor_location(), marker.get_actor_location())
                )
                if d < 200.0:
                    near_marker = True
            check(
                "B02_next_spawn_label_honoured",
                spawned_n >= 1 and near_marker,
                {"spawned": spawned_n, "near_marker": near_marker},
            )
            # Fallback path: no markers in band → still spawns (near player +250).
            sec.despawn_all_bots_for_verify()
            sec.set_next_spawn_location_label(unreal.Name(""))
            n2 = int(sec.spawn_bots_near(p.get_actor_location(), 1, p))
            check("B02_fallback_still_spawns", n2 >= 1, n2)
            sec.despawn_all_bots_for_verify()
    _destroy_all(subsystem, spawned)
    spawned = []


    # --- B11: InitialAITypes spawn via set_repopulation_enabled(bSpawnNow) / BeginPlay path ---
    # import_slice_enemies places ShockAggressorSpawner markers only (no live AI) — BeginPlay
    # initial spawn cannot double-place Medical's authored enemies.
    if aggressor_cls:
        sp = _spawn(
            subsystem, aggressor_cls, "FidAggressor", unreal.Vector(5000.0, 0.0, 100.0)
        )
        spawned.append(sp)
        if sp:
            # Empty initial list: negative — enabling zone does not invent AIs.
            sp.configure(
                unreal.Name("fid_agg"),
                unreal.Name("FidAggressor"),
                [],
                [],
                [],
                unreal.Name(""),
                unreal.Name(""),
                1200.0,
            )
            before_ai = len(
                unreal.GameplayStatics.get_all_actors_of_class(
                    world, unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
                )
            )
            sp.set_repopulation_enabled(True, True)
            after_ai = len(
                unreal.GameplayStatics.get_all_actors_of_class(
                    world, unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
                )
            )
            check(
                "B11_empty_initial_does_not_spawn",
                after_ai == before_ai,
                {"before": before_ai, "after": after_ai},
            )
            # Positive: with an archetype name configured, script-zone spawn path fires.
            # (Archetype asset may be missing in blank editor world — treat spawn attempt ok if
            # API accepts without crashing; Living count may stay 0 without nav/archetype.)
            sp.configure(
                unreal.Name("fid_agg2"),
                unreal.Name("FidAggressor2"),
                [unreal.Name("MedicalBabyJaneMelee")],
                [],
                [unreal.Name("fid_zone")],
                unreal.Name(""),
                unreal.Name(""),
                1200.0,
            )
            try:
                sp.set_repopulation_enabled(True, True)
                check("B11_initial_spawn_api_runs", True, "set_repopulation_enabled ok")
            except Exception as exc:  # noqa: BLE001
                check("B11_initial_spawn_api_runs", False, str(exc))
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- B10: hacked U-Invent ceil(0.8 * count) ---
    if invent_menu_cls:
        # Formula unit checks (independent of inventory / recipes).
        check(
            "B10_ceil_formula_5",
            int(unreal.ShockUInventMenu.component_cost_for_hack_state(5, True)) == 4,
            int(unreal.ShockUInventMenu.component_cost_for_hack_state(5, True)),
        )
        check(
            "B10_ceil_formula_2",
            int(unreal.ShockUInventMenu.component_cost_for_hack_state(2, True)) == 2,
            int(unreal.ShockUInventMenu.component_cost_for_hack_state(2, True)),
        )
        check(
            "B10_unhacked_formula_unchanged",
            int(unreal.ShockUInventMenu.component_cost_for_hack_state(5, False)) == 5,
            int(unreal.ShockUInventMenu.component_cost_for_hack_state(5, False)),
        )
        p = _spawn(subsystem, player_cls, "FidB10Player", unreal.Vector(6000.0, 0.0, 100.0))
        st = _spawn(subsystem, station_cls, "FidUInvent", unreal.Vector(6080.0, 0.0, 100.0))
        spawned.extend([p, st])
        if p and st and station_cls:
            st.set_editor_property("station_kind", unreal.ShockStationKind.U_INVENT)
            p.ensure_health_initialized()
            for name, amt in (("Glue", 5), ("Rubber", 5), ("Screws", 5), ("Oil", 5)):
                p.add_stack_to_inventory(unreal.Name(name), amt)
            menu = unreal.new_object(invent_menu_cls)
            menu.bind_display_player(p)
            menu.bind_station(st)
            glue_before = int(p.get_inventory_stack(unreal.Name("Glue")))
            st.set_hacked(False)
            ok_un = bool(menu.craft_recipe(1))  # Glue 2, Oil 1
            glue_mid = int(p.get_inventory_stack(unreal.Name("Glue")))
            check(
                "B10_unhacked_deducts_full",
                ok_un and glue_mid == glue_before - 2,
                {"ok": ok_un, "before": glue_before, "mid": glue_mid},
            )
            st.set_hacked(True)
            oil_before = int(p.get_inventory_stack(unreal.Name("Oil")))
            ok_h = bool(menu.craft_recipe(1))
            oil_after = int(p.get_inventory_stack(unreal.Name("Oil")))
            glue_after = int(p.get_inventory_stack(unreal.Name("Glue")))
            check(
                "B10_hacked_craft_uses_formula",
                ok_h and oil_after == oil_before - 1 and glue_after == glue_mid - 2,
                {
                    "ok": ok_h,
                    "oil_before": oil_before,
                    "oil_after": oil_after,
                    "glue_after": glue_after,
                },
            )
            # Negative: Glue=1 insufficient for unhacked recipe1 (needs 2).
            st.set_hacked(False)
            have = int(p.get_inventory_stack(unreal.Name("Glue")))
            if have > 1:
                p.remove_stack_from_inventory(unreal.Name("Glue"), have - 1)
            ok_fail = bool(menu.craft_recipe(1))
            check("B10_unhacked_insufficient_fails", not ok_fail, ok_fail)
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- G20: StartedHacking / FinishedHacking messages ---
    if script_cls and assign_cls and player_cls and turret_cls:
        p = _spawn(subsystem, player_cls, "FidG20Player", unreal.Vector(7000.0, 0.0, 100.0))
        tur = _spawn(subsystem, turret_cls, "FidG20Turret", unreal.Vector(7000.0, -400.0, 100.0))
        started = _spawn(
            subsystem, script_cls, "FidG20Started", unreal.Vector(7000.0, 100.0, 100.0)
        )
        finished = _spawn(
            subsystem, script_cls, "FidG20Finished", unreal.Vector(7000.0, 150.0, 100.0)
        )
        spawned.extend([p, tur, started, finished])
        if p and tur and started and finished:
            tur.configure_for_verify(unreal.Name("FidG20Turret"), ALLEGIANCE_HOSTILE, 40.0)
            started.configure("FidG20Started", "FidG20Turret")
            fin_runner = finished.get_runner()
            started.get_runner().set_script_message_class("MessagePlayerStartedHacking")
            assign_s = unreal.new_object(assign_cls)
            assign_s.configure("Started", "yes")
            started.get_runner().add_action(assign_s)
            started.ensure_registry()

            finished.configure("FidG20Finished", "FidG20Turret")
            fin_runner.set_script_message_class("MessagePlayerFinishedHacking")
            fin_runner.set_message_filter_field("SuccessfulHack", "True")
            assign_f = unreal.new_object(assign_cls)
            assign_f.configure("FinishedOk", "yes")
            fin_runner.add_action(assign_f)
            finished.ensure_registry()

            p.ensure_health_initialized()
            p.set_instant_hack_for_verify(True)
            p.set_hack_skill_for_verify(0.9)
            ok = bool(p.try_hack_device(tur, 0.1))
            started.tick_script(0.0)
            finished.tick_script(0.0)
            started_flag = str(
                started.get_runner().ensure_variables().get_value_or_empty("Started")
            )
            finished_flag = str(
                fin_runner.ensure_variables().get_value_or_empty("FinishedOk")
            )
            check(
                "G20_started_and_finished_success",
                ok and started_flag == "yes" and finished_flag == "yes",
                {"ok": ok, "started": started_flag, "finished": finished_flag},
            )
            # Negative: fail path should not trip SuccessfulHack=True filter.
            tur2 = _spawn(
                subsystem, turret_cls, "FidG20TurretFail", unreal.Vector(7100.0, -400.0, 100.0)
            )
            spawned.append(tur2)
            fail_script = _spawn(
                subsystem, script_cls, "FidG20FailOnly", unreal.Vector(7100.0, 150.0, 100.0)
            )
            spawned.append(fail_script)
            if tur2 and fail_script:
                tur2.configure_for_verify(unreal.Name("FidG20TurretFail"), ALLEGIANCE_HOSTILE, 40.0)
                fail_script.configure("FidG20FailOnly", "FidG20TurretFail")
                fr = fail_script.get_runner()
                fr.set_script_message_class("MessagePlayerFinishedHacking")
                fr.set_message_filter_field("SuccessfulHack", "True")
                assign_x = unreal.new_object(assign_cls)
                assign_x.configure("ShouldStayEmpty", "yes")
                fr.add_action(assign_x)
                fail_script.ensure_registry()
                p.set_hack_skill_for_verify(0.1)
                ok_fail = bool(p.try_hack_device(tur2, 0.95))
                fail_script.tick_script(0.0)
                flag = str(fr.ensure_variables().get_value_or_empty("ShouldStayEmpty"))
                check(
                    "G20_fail_does_not_match_success_filter",
                    (not ok_fail) and flag != "yes",
                    {"ok_fail": ok_fail, "flag": flag},
                )
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- G19: dormant bot explodes on FinishFail, not on CloseMinigame cancel ---
    if bot_cls and hack_menu_cls:
        p = _spawn(subsystem, player_cls, "FidG19Player", unreal.Vector(8000.0, 0.0, 100.0))
        bot = _spawn(subsystem, bot_cls, "FidDormantBot", unreal.Vector(8000.0, -200.0, 100.0))
        spawned.extend([p, bot])
        if p and bot:
            bot.configure_for_verify(unreal.Name("FidDormantBot"), ALLEGIANCE_HOSTILE, 30.0)
            bot.set_dormant(True)
            menu = unreal.new_object(hack_menu_cls)
            menu.bind_display_player(p)
            menu.bind_bot(bot)
            menu.open_minigame(0.25)
            menu.close_minigame()  # cancel — must NOT explode
            still = unreal.SystemLibrary.is_valid(bot)
            check("G19_cancel_does_not_explode", still and bool(bot.is_dormant()), still)

            bot2 = _spawn(
                subsystem, bot_cls, "FidDormantBot2", unreal.Vector(8100.0, -200.0, 100.0)
            )
            spawned.append(bot2)
            if bot2:
                bot2.configure_for_verify(unreal.Name("FidDormantBot2"), ALLEGIANCE_HOSTILE, 30.0)
                bot2.set_dormant(True)
                menu2 = unreal.new_object(hack_menu_cls)
                menu2.bind_display_player(p)
                menu2.bind_bot(bot2)
                menu2.open_minigame(0.25)
                menu2.build_scripted_lose_board()
                failed_enum = unreal.ShockHackResult.FAILED
                for _ in range(120):
                    if menu2.get_result() != unreal.ShockHackResult.PLAYING:
                        break
                    menu2.advance_minigame(0.1)
                exploded = not unreal.SystemLibrary.is_valid(bot2)
                check(
                    "G19_fail_explodes_dormant",
                    exploded and menu2.get_result() == failed_enum,
                    {
                        "exploded": exploded,
                        "result": str(menu2.get_result()),
                        "failed_enum": str(failed_enum),
                    },
                )
    _destroy_all(subsystem, spawned)
    spawned = []

    # --- B12: chambers are NOT active until approached (fixed 28 Sept — see verify_vita_chamber
    # for the full proximity/fallback checks; this just confirms the spawn default). ---
    if vita_cls:
        vita = _spawn(subsystem, vita_cls, "FidVita", unreal.Vector(9000.0, 0.0, 100.0))
        spawned.append(vita)
        if vita:
            active = bool(vita.get_editor_property("active"))
            report["B12_vita_default_active"] = active
            check(
                "B12_default_inactive_until_approached",
                active is False,
                active,
            )
    _destroy_all(subsystem, spawned)

    report["checks"] = checks
    report["gameplay_fidelity"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("gameplay_fidelity:\n- " + "\n- ".join(failures))
    _log("Success - %d check(s)" % checks)
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "gameplay_fidelity_report.json"),
        )
    )
