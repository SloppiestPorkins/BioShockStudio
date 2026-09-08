"""One-shot prep for playing the 1-Medical slice in the editor.

Run this HEADLESS with the editor CLOSED, then open the editor fresh and Play.
It composes the existing prep steps so you do not have to run five scripts by hand:

  1. import_ai_archetypes  - UShockAiArchetype assets from document.archetypes
  2. setup_main_menu        - MainMenu map + WBP + startup-map repoint
  3. playable input         - Fire -> LMB, Reload -> R in DefaultInput.ini (legacy input)
  4. repair_null_master_textures - fill NULL master-material params (wall-texture fix)
  5. fix_exterior_collision - make window-view/backdrop geometry render-only
  6. repair_ragdoll_physics - physics assets for combat rigs + reactive placed corpses
  7. fix_all_complex_collision - complex-as-simple on every static mesh (perf later)
  8. repair_light_beams     - shipped falloff+dust additive god-ray material
  9. repair_level_lighting  - corrected falloff, practical intensity, ambient, fixed exposure
 10. import_slice_doors     - AShockDoor placements + TriggerBox MessageTrigger relays
 11. import_slice_enemies   - authored aggressor/turret runtime spawners
 12. import_slice_scripts   - AShockScript actors from level JSON + script-actions sidecar
 13. import_audio           - SoundWaves/Cues + placed AmbientSound actors

Each step is idempotent and its own failure does not stop the others; a summary
prints at the end and a JSON report is written to
%TEMP%/bioshock_slice_setup_report.json.

    "G:\\Games\\UE_5.7\\Engine\\Binaries\\Win64\\UnrealEditor-Cmd.exe" ^
      "C:\\Users\\Jack\\Documents\\BioShockUE5\\BioShockUE5.uproject" ^
      -run=pythonscript -script=tools\\ue5\\setup_playable_slice.py ^
      -unattended -nopause -nosplash

After it finishes: open the editor, let it finish compiling, open
/Game/BioShockSlice/1-Medical (or just Play if the startup map is the menu),
and Play In Editor. A **full editor restart** is required if the editor was
open while BioShockRuntime was rebuilt.
"""

from __future__ import annotations

import json
import os
import sys
import traceback

import unreal

# UE's -script runner does not put this file's directory on sys.path.
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

_TMP = os.environ.get("TEMP", ".")


def _tmp(name):
    return os.path.join(_TMP, "bioshock_slice_setup", name)


os.makedirs(os.path.join(_TMP, "bioshock_slice_setup"), exist_ok=True)

REPORT = os.path.join(_TMP, "bioshock_slice_setup_report.json")

RELOAD_LINE = (
    '+ActionMappings=(ActionName="Reload",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=R)'
)

PLASMID_LINE = (
    '+ActionMappings=(ActionName="Plasmid",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Q)'
)

PLASMID_CYCLE_LINE = (
    '+ActionMappings=(ActionName="PlasmidCycle",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Tab)'
)

HACK_TOOL_LINE = (
    '+ActionMappings=(ActionName="HackTool",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=H)'
)

USE_FIRST_AID_LINE = (
    '+ActionMappings=(ActionName="UseFirstAid",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Z)'
)

USE_EVE_HYPO_LINE = (
    '+ActionMappings=(ActionName="UseEveHypo",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=X)'
)

WEAPON_NEXT_LINE = (
    '+ActionMappings=(ActionName="WeaponNext",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=MouseScrollUp)'
)

WEAPON_PREV_LINE = (
    '+ActionMappings=(ActionName="WeaponPrev",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=MouseScrollDown)'
)

WEAPON_SLOT1_LINE = (
    '+ActionMappings=(ActionName="WeaponSlot1",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=One)'
)

WEAPON_SLOT2_LINE = (
    '+ActionMappings=(ActionName="WeaponSlot2",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Two)'
)

WEAPON_SLOT3_LINE = (
    '+ActionMappings=(ActionName="WeaponSlot3",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Three)'
)

WEAPON_SLOT4_LINE = (
    '+ActionMappings=(ActionName="WeaponSlot4",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Four)'
)

WEAPON_SLOT5_LINE = (
    '+ActionMappings=(ActionName="WeaponSlot5",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Five)'
)

WEAPON_SLOT6_LINE = (
    '+ActionMappings=(ActionName="WeaponSlot6",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Six)'
)

WEAPON_SLOT7_LINE = (
    '+ActionMappings=(ActionName="WeaponSlot7",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Seven)'
)

INTERACT_LINE = (
    '+ActionMappings=(ActionName="Interact",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=F)'
)

AMMO_TYPE_CYCLE_LINE = (
    '+ActionMappings=(ActionName="AmmoTypeCycle",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=C)'
)

WEAPON_RADIAL_LINE = (
    '+ActionMappings=(ActionName="WeaponRadial",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=V)'
)

WEAPON_SELECT_LINE = (
    '+ActionMappings=(ActionName="WeaponSelect",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=LeftShift)'
)

PLASMID_CAST_LINE = (
    '+ActionMappings=(ActionName="PlasmidCast",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=LeftAlt)'
)

RADIAL_STEP_LEFT_LINE = (
    '+ActionMappings=(ActionName="RadialStepLeft",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Left)'
)

RADIAL_STEP_RIGHT_LINE = (
    '+ActionMappings=(ActionName="RadialStepRight",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Right)'
)

STATUS_MENU_LINE = (
    '+ActionMappings=(ActionName="StatusMenu",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=M)'
)

PAUSE_MENU_LINE = (
    '+ActionMappings=(ActionName="PauseMenu",bShift=False,bCtrl=False,bAlt=False,'
    'bCmd=False,Key=Escape)'
)

TRAVEL_DEST_MAP = "/Game/BioShockSlice/_TravelDest"
PLAY_GAME_MODE = "/Script/BioShockRuntime.ShockGameMode"
SHOCK_GAME_INSTANCE = "/Script/BioShockRuntime.ShockGameInstance"
SLICE_PROJECT = r"C:\Users\Jack\Documents\BioShockUE5"
SLICE_MANIFEST = os.path.join(
    SLICE_PROJECT, "Exports", "slice", "1-Medical", "1-Medical.ue5-level.json")


def _ensure_action_mapping(action_name, key, existing_line):
    """Add ActionName -> key to DefaultInput.ini if missing."""
    ini = os.path.join(
        r"C:\Users\Jack\Documents\BioShockUE5", "Config", "DefaultInput.ini"
    )
    text = ""
    if os.path.isfile(ini):
        with open(ini, "r", encoding="utf-8", errors="ignore") as handle:
            text = handle.read()
    needle = 'ActionName="%s"' % action_name
    if needle in text or ("ActionName=%s" % action_name) in text:
        return {"mapping": "already present", "action": action_name, "ini": ini}
    line = existing_line
    if "[/Script/Engine.InputSettings]" in text:
        text = text.replace(
            "[/Script/Engine.InputSettings]",
            "[/Script/Engine.InputSettings]\n" + line,
            1,
        )
    else:
        text = text.rstrip() + "\n\n[/Script/Engine.InputSettings]\n" + line + "\n"
    os.makedirs(os.path.dirname(ini), exist_ok=True)
    with open(ini, "w", encoding="utf-8") as handle:
        handle.write(text)
    return {"mapping": "wrote %s -> %s" % (action_name, key), "ini": ini}


def _ensure_reload_mapping():
    """verify_playable_input.py only writes the Fire mapping; add Reload -> R too."""
    return _ensure_action_mapping("Reload", "R", RELOAD_LINE)


def _ensure_plasmid_mapping():
    return _ensure_action_mapping("Plasmid", "Q", PLASMID_LINE)


def _ensure_plasmid_cycle_mapping():
    return _ensure_action_mapping("PlasmidCycle", "Tab", PLASMID_CYCLE_LINE)


def _ensure_hack_tool_mapping():
    return _ensure_action_mapping("HackTool", "H", HACK_TOOL_LINE)


def _ensure_use_first_aid_mapping():
    return _ensure_action_mapping("UseFirstAid", "Z", USE_FIRST_AID_LINE)


def _ensure_use_eve_hypo_mapping():
    return _ensure_action_mapping("UseEveHypo", "X", USE_EVE_HYPO_LINE)


def _ensure_weapon_slot_mappings():
    results = []
    results.append(_ensure_action_mapping("WeaponNext", "MouseScrollUp", WEAPON_NEXT_LINE))
    results.append(_ensure_action_mapping("WeaponPrev", "MouseScrollDown", WEAPON_PREV_LINE))
    results.append(_ensure_action_mapping("WeaponSlot1", "One", WEAPON_SLOT1_LINE))
    results.append(_ensure_action_mapping("WeaponSlot2", "Two", WEAPON_SLOT2_LINE))
    results.append(_ensure_action_mapping("WeaponSlot3", "Three", WEAPON_SLOT3_LINE))
    results.append(_ensure_action_mapping("WeaponSlot4", "Four", WEAPON_SLOT4_LINE))
    results.append(_ensure_action_mapping("WeaponSlot5", "Five", WEAPON_SLOT5_LINE))
    results.append(_ensure_action_mapping("WeaponSlot6", "Six", WEAPON_SLOT6_LINE))
    results.append(_ensure_action_mapping("WeaponSlot7", "Seven", WEAPON_SLOT7_LINE))
    return {"mapping": "weapon slots", "details": results}


def _ensure_interact_mapping():
    return _ensure_action_mapping("Interact", "F", INTERACT_LINE)


def _ensure_ammo_type_cycle_mapping():
    return _ensure_action_mapping("AmmoTypeCycle", "C", AMMO_TYPE_CYCLE_LINE)


def _ensure_weapon_radial_mapping():
    return _ensure_action_mapping("WeaponRadial", "V", WEAPON_RADIAL_LINE)


def _ensure_weapon_select_mapping():
    return _ensure_action_mapping("WeaponSelect", "LeftShift", WEAPON_SELECT_LINE)


def _ensure_plasmid_cast_mapping():
    return _ensure_action_mapping("PlasmidCast", "LeftAlt", PLASMID_CAST_LINE)


def _ensure_radial_step_mappings():
    return {
        "mapping": "radial step",
        "details": [
            _ensure_action_mapping("RadialStepLeft", "Left", RADIAL_STEP_LEFT_LINE),
            _ensure_action_mapping("RadialStepRight", "Right", RADIAL_STEP_RIGHT_LINE),
        ],
    }


def _ensure_status_menu_mapping():
    return _ensure_action_mapping("StatusMenu", "M", STATUS_MENU_LINE)


def _ensure_pause_menu_mapping():
    return _ensure_action_mapping("PauseMenu", "Escape", PAUSE_MENU_LINE)


def _project_config_dir():
    return os.path.join(SLICE_PROJECT, "Config")


def _set_engine_ini_value(text, key, value):
    import re

    section = "[/Script/Engine.Engine]"
    line = "%s=%s" % (key, value)
    if section not in text:
        text = text.rstrip() + "\n\n" + section + "\n" + line + "\n"
        return text, True
    match = re.search(
        r"(\[/Script/Engine\.Engine\][^\[]*)",
        text,
        flags=re.DOTALL,
    )
    if not match:
        return text, False
    block = match.group(1)
    key_re = re.compile(r"(?m)^%s=.*$" % re.escape(key))
    if key_re.search(block):
        new_block = key_re.sub(line, block, count=1)
    else:
        new_block = block.rstrip("\n") + "\n" + line + "\n"
    if new_block == block:
        return text, False
    return text[: match.start(1)] + new_block + text[match.end(1) :], True


def _ensure_game_instance_class():
    """Point DefaultEngine.ini at UShockGameInstance so carry state survives OpenLevel."""
    ini_path = os.path.join(_project_config_dir(), "DefaultEngine.ini")
    if not os.path.isfile(ini_path):
        return {"ini": ini_path, "mapping": "missing ini"}
    original = open(ini_path, encoding="utf-8").read()
    text, changed = _set_engine_ini_value(original, "GameInstanceClass", SHOCK_GAME_INSTANCE)
    if changed and text != original:
        open(ini_path, "w", encoding="utf-8", newline="\n").write(text)
    return {
        "ini": ini_path,
        "gameInstanceClass": SHOCK_GAME_INSTANCE,
        "changed": changed and text != original,
    }


NAV_CONFIG_BLOCK = """
[/Script/NavigationSystem.NavigationSystemV1]
; Imported 1-Medical BSP has no placed NavMeshBoundsVolume, and one spawned at runtime has no brush
; geometry to size (ConstructTiledNavMesh: navmesh of size 0). A UNavigationInvokerComponent on the
; player (AShockPlayer ctor) plus invokers-only generation builds tiles in a radius around the pawn,
; so the encounter AI paths around geometry instead of the straight-line fallback.
bAutoCreateNavigationData=True
bSpawnNavDataInNavBoundsLevel=True
bAllowClientSideNavigation=True
bGenerateNavigationOnlyAroundNavigationInvokers=True

[/Script/NavigationSystem.RecastNavMesh]
RuntimeGeneration=Dynamic
"""


def _ensure_navigation_config():
    """Nav-system config so a runtime RecastNavMesh generates around the player invoker."""
    ini_path = os.path.join(_project_config_dir(), "DefaultEngine.ini")
    if not os.path.isfile(ini_path):
        return {"ini": ini_path, "nav": "missing ini"}
    original = open(ini_path, encoding="utf-8").read()
    if "[/Script/NavigationSystem.NavigationSystemV1]" in original:
        return {"ini": ini_path, "nav": "already present", "changed": False}
    text = original.rstrip() + "\n" + NAV_CONFIG_BLOCK
    open(ini_path, "w", encoding="utf-8", newline="\n").write(text)
    return {"ini": ini_path, "nav": "appended", "changed": True}


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _ensure_content_folder(path):
    if unreal.EditorAssetLibrary.does_directory_exist(path):
        return
    if not unreal.EditorAssetLibrary.make_directory(path):
        raise RuntimeError("could not create content folder %s" % path)


def _ensure_travel_dest_map():
    """Hand-built travel destination: ShockGameMode, default start + labelled arrivals."""
    mode_class = unreal.load_class(None, PLAY_GAME_MODE)
    if mode_class is None:
        raise RuntimeError("ShockGameMode class missing")

    level = _level_subsystem()
    created = False
    if unreal.EditorAssetLibrary.does_asset_exist(TRAVEL_DEST_MAP):
        if not level.load_level(TRAVEL_DEST_MAP):
            raise RuntimeError("could not load %s" % TRAVEL_DEST_MAP)
    else:
        _ensure_content_folder("/Game/BioShockSlice")
        if not level.new_level(TRAVEL_DEST_MAP):
            raise RuntimeError("could not create %s" % TRAVEL_DEST_MAP)
        created = True

    world = unreal.EditorLevelLibrary.get_editor_world()
    settings = world.get_world_settings()
    settings.set_editor_property("default_game_mode", mode_class)

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    labels_needed = {
        "TravelDestStart": unreal.Vector(0.0, 0.0, 100.0),
        "DestArrival": unreal.Vector(400.0, 0.0, 100.0),
        "ReturnArrival": unreal.Vector(-400.0, 0.0, 100.0),
    }
    existing = {}
    for actor in subsystem.get_all_level_actors():
        if isinstance(actor, unreal.PlayerStart):
            existing[actor.get_actor_label()] = actor

    spawned = []
    for label, loc in labels_needed.items():
        if label in existing:
            continue
        start = subsystem.spawn_actor_from_class(unreal.PlayerStart, loc)
        if not start:
            raise RuntimeError("could not spawn PlayerStart %s" % label)
        start.set_actor_label(label)
        spawned.append(label)

    if not level.save_current_level():
        raise RuntimeError("could not save %s" % TRAVEL_DEST_MAP)

    return {
        "map": TRAVEL_DEST_MAP,
        "created": created,
        "spawnedStarts": spawned,
    }


STEPS = [
    ("import_ai_archetypes", "import_ai_archetypes", "main", ()),
    ("setup_main_menu", "setup_main_menu", "main", (_tmp("main_menu.json"),)),
    ("playable_input", "verify_playable_input", "main", (_tmp("playable_input.json"),)),
    ("reload_key_mapping", None, _ensure_reload_mapping, ()),
    ("plasmid_key_mapping", None, _ensure_plasmid_mapping, ()),
    ("plasmid_cycle_key_mapping", None, _ensure_plasmid_cycle_mapping, ()),
    ("hack_key_mapping", None, _ensure_hack_tool_mapping, ()),
    ("use_first_aid_key_mapping", None, _ensure_use_first_aid_mapping, ()),
    ("use_eve_hypo_key_mapping", None, _ensure_use_eve_hypo_mapping, ()),
    ("weapon_slot_key_mapping", None, _ensure_weapon_slot_mappings, ()),
    ("interact_key_mapping", None, _ensure_interact_mapping, ()),
    ("ammo_type_cycle_key_mapping", None, _ensure_ammo_type_cycle_mapping, ()),
    ("weapon_radial_key_mapping", None, _ensure_weapon_radial_mapping, ()),
    ("weapon_select_key_mapping", None, _ensure_weapon_select_mapping, ()),
    ("plasmid_cast_key_mapping", None, _ensure_plasmid_cast_mapping, ()),
    ("radial_step_key_mapping", None, _ensure_radial_step_mappings, ()),
    ("status_menu_key_mapping", None, _ensure_status_menu_mapping, ()),
    ("pause_menu_key_mapping", None, _ensure_pause_menu_mapping, ()),
    ("game_instance_class", None, _ensure_game_instance_class, ()),
    ("navigation_config", None, _ensure_navigation_config, ()),
    ("travel_dest_map", None, _ensure_travel_dest_map, ()),
    ("repair_null_master_textures", "repair_null_master_textures", "main", ()),
    ("repair_placeholder_base_colours", "repair_placeholder_base_colours", "main",
     (SLICE_MANIFEST,)),
    ("fix_clobbered_diffuse_textures", "fix_clobbered_diffuse_textures", "main",
     (SLICE_MANIFEST,)),
    # Full-res rig textures. Run tools/ue5/reexport_rig_textures.ps1 first (dotnet, outside the
    # editor) to regenerate Rigs/<name>/Textures/*.png; this step re-imports whatever is on disk.
    ("import_rig_textures", "import_rig_textures", "main", ()),
    ("fix_exterior_collision", "fix_exterior_collision", "main", ()),
    ("repair_ragdoll_physics", "repair_ragdoll_physics", "main", ()),
    # User decision 8 Sept 2026: complex-as-simple on EVERYTHING (perf later). This supersedes
    # fix_prop_collision's per-class policy.
    ("fix_all_complex_collision", "fix_all_complex_collision", "main", ()),
    ("restore_stair_hulls", "restore_stair_hulls", "main", ()),
    ("repair_light_beams", "repair_light_beams", "main", ()),
    ("repair_level_lighting", "repair_level_lighting", "main",
     ("/Game/BioShockSlice/1-Medical",)),
    # Scripted events: doors + MessageTrigger relays, then AShockScript actors on the slice map.
    ("import_slice_doors", "import_slice_doors", "main", ()),
    ("import_slice_enemies", "import_slice_enemies", "main", ()),
    ("import_slice_scripts", "import_slice_scripts", "main", ()),
    # Run export_slice_audio.ps1 first (dotnet, editor closed). This imports only payloads that
    # export-audio actually wrote; located streamed/native samples with no file remain reported.
    ("import_audio", "import_audio", "main", ()),
]


def _run_step(label, module_name, func_name, args):
    entry = {"step": label, "ok": False, "detail": None}
    try:
        if module_name is None:  # local callable, not an imported module
            result = func_name()
            entry["ok"] = True
            entry["detail"] = result
            return entry
        module = __import__(module_name)
        func = getattr(module, func_name)
        result = func(*args)
        entry["ok"] = True
        if isinstance(result, dict):
            entry["detail"] = {k: result[k] for k in list(result)[:8]}
        else:
            entry["detail"] = str(result)[:400] if result is not None else "ok"
    except Exception as exc:  # noqa: BLE001 - one bad step must not kill the rest
        entry["detail"] = "%s: %s" % (type(exc).__name__, exc)
        entry["traceback"] = traceback.format_exc()
    return entry


def main():
    report = {"steps": [], "ok": 0, "failed": 0}
    for label, module_name, func_name, args in STEPS:
        unreal.log("[slice-setup] %s ..." % label)
        entry = _run_step(label, module_name, func_name, args)
        report["steps"].append(entry)
        report["ok" if entry["ok"] else "failed"] += 1
        unreal.log("[slice-setup] %s -> %s" % (label, "ok" if entry["ok"] else "FAILED"))

    os.makedirs(os.path.dirname(os.path.abspath(REPORT)), exist_ok=True)
    with open(REPORT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    unreal.log("[slice-setup] %d ok, %d failed. Report: %s"
               % (report["ok"], report["failed"], REPORT))
    if report["failed"]:
        raise RuntimeError("%d slice-setup step(s) failed - see %s" % (report["failed"], REPORT))
    return report


if __name__ == "__main__":
    main()
