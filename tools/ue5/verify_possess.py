"""Phase 0 playable half: ShockGameMode + PlayerStart on the saved Medical umap.

Python cannot run inside PIE, and spawning a PlayerController then calling Possess in the
editor world access-violates under `-unattended` (measured 26 Aug 2026). What this proves
instead:

1. WorldSettings DefaultGameMode is ShockGameMode (whose DefaultPawnClass is ShockPlayer).
2. A real PlayerStart sits at MedicalStart and survives save → scratch → reload.
3. An AShockPlayer spawned at that start takes schema numbers (including CollisionHeight 68).
4. Editor pilot locks the viewport to that pawn — the editor-side stand-in for possess.

A human pressing Play in the editor is the remaining possess path; this does not claim PIE ran.
"""

import json
import os

import unreal

import verify_runtime_skeleton

MAP_PATH = "/Game/BioShockSlice/1-Medical"
SCRATCH_MAP = "/Game/BioShockSlice/_ScratchPossess"
PLAYER_START_TAG = "BioShockPossess=MedicalStart"
# From 1-Medical.ue5-level.json actor PlayerStart0 (label MedicalStart). UE2 yaw 16384 = 90 deg.
MEDICAL_START = unreal.Vector(-17320.002, 1271.9973, 7778.3057)
MEDICAL_START_YAW = 90.0


def _log(message):
    unreal.log("[bioshock-possess] %s" % message)


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _require_class(name):
    path = "/Script/BioShockRuntime.%s" % name
    loaded = unreal.load_class(None, path)
    if loaded is None:
        raise RuntimeError("runtime class missing: %s" % path)
    return loaded


def _tag_value(actor, prefix):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith(prefix):
            return text[len(prefix):]
    return None


def _find_tagged_player_start():
    for actor in _actors().get_all_level_actors():
        if isinstance(actor, unreal.PlayerStart) and _tag_value(actor, "BioShockPossess=") is not None:
            return actor
    return None


def _ensure_player_start():
    existing = _find_tagged_player_start()
    if existing is not None:
        existing.set_actor_location(MEDICAL_START, False, True)
        existing.set_actor_rotation(unreal.Rotator(0.0, MEDICAL_START_YAW, 0.0), False)
        return existing, False

    start = _actors().spawn_actor_from_class(unreal.PlayerStart, MEDICAL_START)
    if start is None:
        raise RuntimeError("could not spawn PlayerStart")
    start.set_actor_rotation(unreal.Rotator(0.0, MEDICAL_START_YAW, 0.0), False)
    start.set_actor_label("BioShock_MedicalStart")
    start.tags = [unreal.Name(PLAYER_START_TAG)]
    return start, True


def _set_game_mode(mode_class):
    world = unreal.EditorLevelLibrary.get_editor_world()
    settings = world.get_world_settings()
    settings.set_editor_property("default_game_mode", mode_class)
    got = settings.get_editor_property("default_game_mode")
    if got != mode_class:
        raise RuntimeError("WorldSettings.default_game_mode is %s, not ShockGameMode" % got)
    return got


def _reload_map(map_path):
    level = _level_subsystem()
    if not level.new_level(SCRATCH_MAP):
        raise RuntimeError("could not switch away to %s" % SCRATCH_MAP)
    if _find_tagged_player_start() is not None:
        raise RuntimeError("tagged PlayerStart still present after leaving the slice level")
    if not level.load_level(map_path):
        raise RuntimeError("saved level %s did not load back" % map_path)


def _spawn_apply_and_pilot(schema_path, report):
    player_class = _require_class("ShockPlayer")
    mode_class = _require_class("ShockGameMode")
    report["gameModeClass"] = str(mode_class)
    report["playerClass"] = str(player_class)

    mode_cdo = unreal.get_default_object(mode_class)
    default_pawn = mode_cdo.get_editor_property("default_pawn_class")
    report["gameModeDefaultPawn"] = str(default_pawn)
    if default_pawn != player_class:
        raise RuntimeError("ShockGameMode default pawn is %s, not ShockPlayer" % default_pawn)

    rows, injected = verify_runtime_skeleton._merge_vpawn_collision_height(
        json.load(open(schema_path, encoding="utf-8")))
    apply_schema = schema_path
    if injected:
        apply_schema = os.path.join(
            os.path.dirname(os.path.abspath(report["reportPath"])),
            "ShockGame.schema.with_vpawn.json")
        os.makedirs(os.path.dirname(apply_schema), exist_ok=True)
        with open(apply_schema, "w", encoding="utf-8") as handle:
            json.dump(rows, handle)
    report["applySchema"] = apply_schema
    report["injectedVPawn"] = injected

    subsystem = _actors()
    pawn = subsystem.spawn_actor_from_class(player_class, MEDICAL_START)
    if pawn is None:
        raise RuntimeError("spawn ShockPlayer failed")
    pawn.set_actor_rotation(unreal.Rotator(0.0, MEDICAL_START_YAW, 0.0), False)

    raw = unreal.ShockSchemaLibrary.apply_class_defaults(pawn, apply_schema, "ShockPlayer")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        raise RuntimeError("ApplyClassDefaults failed: %s" % apply.get("error"))

    capsule = pawn.get_editor_property("capsule_component")
    movement = pawn.get_editor_property("character_movement")
    measured = {
        "capsuleRadius": float(capsule.get_editor_property("capsule_radius")),
        "capsuleHalfHeight": float(capsule.get_editor_property("capsule_half_height")),
        "maxWalkSpeed": float(movement.get_editor_property("max_walk_speed")),
    }
    report["measured"] = measured
    if abs(measured["capsuleHalfHeight"] - 68.0) > 0.05:
        raise RuntimeError("capsuleHalfHeight %s != 68" % measured["capsuleHalfHeight"])
    if abs(measured["maxWalkSpeed"] - 450.0) > 0.05:
        raise RuntimeError("maxWalkSpeed %s != 450" % measured["maxWalkSpeed"])

    # Editor pilot is the headless stand-in for possess. PlayerController.Possess AVs here.
    unreal.EditorLevelLibrary.pilot_level_actor(pawn)
    report["piloted"] = True
    unreal.EditorLevelLibrary.eject_pilot_level_actor()
    report["ejected"] = True

    subsystem.destroy_actor(pawn)
    return mode_class


def main(schema_path, report_path, map_path=MAP_PATH):
    report = {
        "map": map_path,
        "schema": schema_path,
        "reportPath": report_path,
        "possessPath": "editor-pilot",
        "piePossess": "not claimed — Python does not run in PIE; editor PlayerController.Possess AVs",
        "error": None,
    }
    failures = []

    level = _level_subsystem()
    if not unreal.EditorAssetLibrary.does_asset_exist(map_path):
        raise RuntimeError("slice map missing: %s — run the vertical slice first" % map_path)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    mode_class = _spawn_apply_and_pilot(schema_path, report)
    _set_game_mode(mode_class)
    start, created = _ensure_player_start()
    report["playerStartCreated"] = created
    report["playerStartLabel"] = start.get_actor_label()
    loc = start.get_actor_location()
    report["playerStartLocation"] = [loc.x, loc.y, loc.z]

    if not level.save_current_level():
        raise RuntimeError("save_current_level failed")

    _reload_map(map_path)

    world = unreal.EditorLevelLibrary.get_editor_world()
    settings = world.get_world_settings()
    reloaded_mode = settings.get_editor_property("default_game_mode")
    report["reloadedGameMode"] = str(reloaded_mode)
    if reloaded_mode != mode_class:
        failures.append("reloaded DefaultGameMode is %s, not ShockGameMode" % reloaded_mode)

    reloaded_start = _find_tagged_player_start()
    report["reloadedPlayerStart"] = reloaded_start is not None
    if reloaded_start is None:
        failures.append("tagged PlayerStart missing after reload")
    else:
        rloc = reloaded_start.get_actor_location()
        if abs(rloc.x - MEDICAL_START.x) > 1.0 or abs(rloc.y - MEDICAL_START.y) > 1.0:
            failures.append("PlayerStart moved on reload: %s" % [rloc.x, rloc.y, rloc.z])

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("possess setup failed:\n- " + "\n- ".join(failures))
    _log("PASS: Medical umap keeps ShockGameMode + MedicalStart; ShockPlayer piloted with schema")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_RUNTIME_SCHEMA"], os.environ["BIOSHOCK_POSSESS_OUT"])
