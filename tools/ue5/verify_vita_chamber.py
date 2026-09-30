"""Headless verify: Medical's two Vita-Chambers and persistent-world death/respawn."""

from __future__ import annotations

import json
import math
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_level

MAP_PATH = "/Game/BioShockSlice/1-Medical"
MANIFEST = (
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical"
    r"\1-Medical.ue5-level.json"
)


def _flag(value):
    return bool(value() if callable(value) else value)


def _distance(a, b):
    return math.sqrt(
        float(a.x - b.x) ** 2
        + float(a.y - b.y) ** 2
        + float(a.z - b.z) ** 2)


def _is_class(actor, cls):
    actor_cls = actor.get_class()
    return actor_cls == cls or unreal.MathLibrary.class_is_child_of(actor_cls, cls)


def _write(path, report):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def main(out_path=None, manifest_path=MANIFEST):
    out_path = out_path or os.environ.get(
        "BIOSHOCK_VITA_OUT",
        os.path.join(os.environ.get("TEMP", "."), "vita_chamber_report.json"))
    failures = []
    report = {"map": MAP_PATH, "manifest": manifest_path, "failures": failures}

    levels = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    if not levels.load_level(MAP_PATH):
        failures.append("could not load %s" % MAP_PATH)
        _write(out_path, report)
        raise RuntimeError("vita-chamber:\n- " + "\n- ".join(failures))

    with open(manifest_path, encoding="utf-8") as handle:
        manifest = json.load(handle)
    expected = [
        entry for entry in manifest.get("actors") or []
        if entry.get("className") == "ResurrectionStation"
    ]
    expected_mesh_keys = {
        (entry.get("staticMeshReference") or {}).get("sourceKey")
        for entry in expected
    }
    assets = {
        entry["key"]: entry for entry in manifest.get("assets") or []
        if entry.get("key") in expected_mesh_keys
    }
    meshes = {}
    import_report = {"created": 0, "updated": 0, "skipped": 0}
    for key, asset in assets.items():
        source = os.path.join(
            os.path.dirname(os.path.abspath(manifest_path)),
            asset["file"].replace("/", os.sep))
        stem = os.path.splitext(os.path.basename(source))[0]
        asset_path = "/Game/BioShockLevel/1-Medical/Meshes/" + stem
        mesh = (
            unreal.EditorAssetLibrary.load_asset(asset_path)
            if unreal.EditorAssetLibrary.does_asset_exist(asset_path)
            else None
        )
        if mesh is None:
            mesh = import_level._import_static_mesh_obj(
                source, "/Game/BioShockLevel/1-Medical/Meshes", stem)
        if mesh is not None:
            meshes[key] = mesh

    handled = set()
    existing = import_level._existing_by_key()
    import_level._import_vita_chambers(
        manifest, meshes, existing, import_report, handled)
    report["import"] = import_report

    # Policy gate (stations-duplicate audit, 30 Sept 2026): Vita chambers own their mesh via
    # set_station_mesh. A generic instance StaticMeshActor at the same transform makes
    # GetPlayerStartTransform's Visibility clearance probe (ignores only `this`) report
    # near-zero clearance through the co-located duplicate. Denylist must stick.
    if import_level._should_place_mesh_instance("ResurrectionStation", "StaticMesh"):
        failures.append(
            "ResurrectionStation must not get a generic instance mesh "
            "(AShockVitaChamber owns it; see _should_place_mesh_instance)")
    # Live-map cleanup: any leftover instance: mesh under a chamber key is the same bug,
    # still sitting from an older import. Flag it so re-running import_level (which now
    # _remove_owned_mesh's the denylisted keys) is the required follow-up, not optional.
    leftover = []
    for entry in expected:
        prefix = "instance:" + entry["key"] + ":"
        for key, actor in existing.items():
            if key.startswith(prefix) and isinstance(
                    actor, (unreal.StaticMeshActor, unreal.SkeletalMeshActor)):
                leftover.append(key)
    report["leftoverInstanceMeshes"] = leftover
    if leftover:
        failures.append(
            "vita chamber still has generic instance mesh duplicate(s): %s"
            % leftover)

    chamber_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockVitaChamber")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    handler_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockDeathRespawnHandler")
    if not all((chamber_cls, player_cls, ai_cls, handler_cls)):
        failures.append("runtime class missing")
        _write(out_path, report)
        raise RuntimeError("vita-chamber:\n- " + "\n- ".join(failures))

    chambers = [
        actor for actor in actors.get_all_level_actors()
        if _is_class(actor, chamber_cls)
    ]
    report["importedChambers"] = [
        {
            "label": actor.get_actor_label(),
            "sourceKey": str(actor.get_editor_property("source_key")),
            "active": _flag(actor.can_resurrect),
        }
        for actor in chambers
    ]
    # SCR-B12: import must NOT force chambers active — activation is proximity/script-driven.
    if any(_flag(actor.can_resurrect) for actor in chambers):
        failures.append("a freshly imported chamber is already active (should require approach)")
    expected_keys = {entry["key"] for entry in expected}
    imported_keys = {
        str(actor.get_editor_property("source_key")) for actor in chambers
    }
    if len(expected) != 2 or imported_keys != expected_keys:
        failures.append(
            "expected two manifest chambers %s, imported %s"
            % (sorted(expected_keys), sorted(imported_keys)))

    spawned = []
    if len(chambers) >= 2:
        near, far = sorted(chambers, key=lambda chamber: chamber.get_actor_location().x)
        # Stand 300 uu from `near`, while remaining much farther from the other authored chamber.
        start = near.get_actor_location() + unreal.Vector(300.0, 0.0, 100.0)
        player = actors.spawn_actor_from_class(player_cls, start)
        ai = actors.spawn_actor_from_class(
            ai_cls, start + unreal.Vector(500.0, 0.0, 0.0))
        fallback = actors.spawn_actor_from_class(
            unreal.PlayerStart, start + unreal.Vector(1000.0, 0.0, 0.0))
        spawned += [player, ai, fallback]
        if not all(spawned):
            failures.append("could not spawn player/AI/fallback")
        else:
            player.set_actor_label("VitaVerifyPlayer")
            player.ensure_health_initialized()
            player.set_current_eve_for_verify(0.0)
            max_health = float(player.get_current_health())
            max_eve = float(player.get_max_eve())

            # SCR-B12: neither chamber activates on its own; simulate the player having walked
            # past `near` (as AShockVitaChamber's own ActivationVolume would on overlap) while
            # `far` is left untouched — proving an unapproached chamber is never selected.
            if _flag(near.can_resurrect):
                failures.append("near chamber active before proximity/script activation")
            if _flag(far.can_resurrect):
                failures.append("far chamber active before proximity/script activation")
            near.set_active(True)
            if not _flag(near.can_resurrect):
                failures.append("near chamber did not activate")

            ai.configure_identity("Agg_BabyJane", "VitaVerifyAI")
            ai.ensure_health_initialized()
            ai_start_health = float(ai.get_current_health())
            unreal.ShockDamageLibrary.apply_damage(
                ai, 17.0, player, unreal.Name("VitaVerify"))
            ai_damaged_health = float(ai.get_current_health())
            ai.scripted_attack_target(player)

            handler = unreal.new_object(handler_cls, outer=player)
            handler.set_editor_property("respawn_delay_seconds", 4.8)
            handler.initialize(unreal.EditorLevelLibrary.get_editor_world(), player, fallback)
            unreal.ShockDamageLibrary.apply_damage(
                player, max_health, ai, unreal.Name("VitaVerify"))
            if not handler.is_respawn_pending():
                failures.append("lethal damage did not schedule respawn")
            handler.advance_respawn_for_verify(4.8)

            selected = handler.get_last_selected_chamber()
            expected_location = near.get_player_start_transform().translation
            actual_location = player.get_actor_location()
            report["respawn"] = {
                "selected": selected.get_actor_label() if selected else None,
                "near": near.get_actor_label(),
                "far": far.get_actor_label(),
                "distanceToStart": _distance(actual_location, expected_location),
                "health": float(player.get_current_health()),
                "expectedHealth": max_health * 0.5,
                "eve": float(player.get_current_eve()),
                "expectedEve": max_eve * 0.75,
                "invulnerable": _flag(player.is_invincible),
                "aiHealthBeforeDamage": ai_start_health,
                "aiHealthAfterDamage": ai_damaged_health,
                "aiHealthAfterRespawn": float(ai.get_current_health()),
                "aiStateAfterRespawn": str(ai.get_behaviour_state_name()),
            }
            if selected != near:
                failures.append("nearest active chamber was not selected")
            if _distance(actual_location, expected_location) > 5.0:
                failures.append("player not teleported to selected chamber")
            if abs(float(player.get_current_health()) - max_health * 0.5) > 0.01:
                failures.append("health was not restored to 50 percent")
            if abs(float(player.get_current_eve()) - max_eve * 0.75) > 0.01:
                failures.append("EVE was not restored to 75 percent floor")
            if not _flag(player.is_invincible):
                failures.append("brief respawn invulnerability not active")
            if abs(float(ai.get_current_health()) - ai_damaged_health) > 0.01:
                failures.append("pre-damaged AI health changed across respawn")
            if str(ai.get_behaviour_state_name()) not in ("Search", "Idle"):
                failures.append("AI did not leave combat after respawn")

            # SCR-B12 negative: with the (now activated) `near` chamber deactivated again and
            # `far` never approached, no chamber is active — death must fall back rather than
            # resurrecting at either.
            near.set_active(False)
            player.set_invincible(False)  # clear the first respawn's brief post-respawn grace
            handler2 = unreal.new_object(handler_cls, outer=player)
            handler2.set_editor_property("respawn_delay_seconds", 4.8)
            handler2.initialize(unreal.EditorLevelLibrary.get_editor_world(), player, fallback)
            player.ensure_health_initialized()
            unreal.ShockDamageLibrary.apply_damage(
                player, float(player.get_current_health()), ai, unreal.Name("VitaVerify"))
            handler2.advance_respawn_for_verify(4.8)
            no_chamber_selected = handler2.get_last_selected_chamber()
            report["noActiveChamberFallback"] = {
                "selected": no_chamber_selected.get_actor_label() if no_chamber_selected else None,
                "distanceToFallback": _distance(
                    player.get_actor_location(), fallback.get_actor_location()),
            }
            if no_chamber_selected is not None:
                failures.append("a chamber was selected with none active")
            if _distance(player.get_actor_location(), fallback.get_actor_location()) > 5.0:
                failures.append("player not returned to the fallback PlayerStart")

    for actor in spawned:
        if actor:
            actors.destroy_actor(actor)

    report["mapSaved"] = bool(levels.save_current_level())
    if not report["mapSaved"]:
        failures.append("save_current_level failed")

    report["vita_chamber"] = "ok" if not failures else "fail"
    _write(out_path, report)
    if failures:
        raise RuntimeError("vita-chamber:\n- " + "\n- ".join(failures))
    unreal.log("[bioshock-vita-chamber] PASS")
    return report


if __name__ == "__main__":
    main()
