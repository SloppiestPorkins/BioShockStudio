"""Idempotent front-end setup: MainMenu map, WBP_MainMenu, project startup map.

Creates `/Game/BioShockUI/MainMenu` with ShockMenuGameMode, a WidgetBlueprint parented to
ShockMainMenuWidget, and repoints GameDefaultMap / EditorStartupMap at the menu. Assets live
only in the throwaway BioShockUE5 project — never the git repo.
"""

from __future__ import annotations

import json
import os
import re

import unreal

MENU_FOLDER = "/Game/BioShockUI"
MENU_MAP = "/Game/BioShockUI/MainMenu"
SCRATCH_MAP = "/Game/BioShockUI/_ScratchMenu"
WBP_PATH = "/Game/BioShockUI/WBP_MainMenu"
PLAY_LEVEL = "/Game/BioShockSlice/1-Medical"
MENU_GAME_MODE = "/Script/BioShockRuntime.ShockMenuGameMode"
MENU_WIDGET_CPP = "/Script/BioShockRuntime.ShockMainMenuWidget"
PLAY_GAME_MODE = "/Script/BioShockRuntime.ShockGameMode"


def _log(message):
    unreal.log("[bioshock-main-menu] %s" % message)


def _require_class(path):
    loaded = unreal.load_class(None, path)
    if loaded is None:
        raise RuntimeError("runtime class missing: %s" % path)
    return loaded


def _ensure_dir(path):
    if unreal.EditorAssetLibrary.does_directory_exist(path):
        return
    if not unreal.EditorAssetLibrary.make_directory(path):
        raise RuntimeError("could not create folder %s" % path)


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _ensure_scratch():
    level = _level_subsystem()
    if unreal.EditorAssetLibrary.does_asset_exist(SCRATCH_MAP):
        return
    _ensure_dir(MENU_FOLDER)
    if not level.new_level(SCRATCH_MAP):
        raise RuntimeError("could not create scratch map %s" % SCRATCH_MAP)
    if not level.save_current_level():
        raise RuntimeError("could not save scratch map %s" % SCRATCH_MAP)


def _set_world_game_mode(mode_class):
    world = unreal.EditorLevelLibrary.get_editor_world()
    settings = world.get_world_settings()
    settings.set_editor_property("default_game_mode", mode_class)
    got = settings.get_editor_property("default_game_mode")
    if got != mode_class:
        raise RuntimeError("WorldSettings.default_game_mode is %s" % got)
    return got


def _ensure_menu_map(mode_class):
    level = _level_subsystem()
    created = False
    if unreal.EditorAssetLibrary.does_asset_exist(MENU_MAP):
        if not level.load_level(MENU_MAP):
            raise RuntimeError("could not load %s" % MENU_MAP)
    else:
        _ensure_dir(MENU_FOLDER)
        if not level.new_level(MENU_MAP):
            raise RuntimeError("could not create %s" % MENU_MAP)
        created = True

    _set_world_game_mode(mode_class)
    if not level.save_current_level():
        raise RuntimeError("could not save %s" % MENU_MAP)

    # Round-trip through scratch so we prove the map persisted GameMode, not just memory.
    _ensure_scratch()
    if not level.load_level(SCRATCH_MAP):
        raise RuntimeError("could not leave menu map via %s" % SCRATCH_MAP)
    if not level.load_level(MENU_MAP):
        raise RuntimeError("saved %s did not load back" % MENU_MAP)
    reloaded = unreal.EditorLevelLibrary.get_editor_world().get_world_settings().get_editor_property(
        "default_game_mode"
    )
    if reloaded != mode_class:
        raise RuntimeError("reloaded DefaultGameMode is %s" % reloaded)
    return created


def _ensure_wbp(parent_class):
    if unreal.EditorAssetLibrary.does_asset_exist(WBP_PATH):
        asset = unreal.EditorAssetLibrary.load_asset(WBP_PATH)
        if asset is None:
            raise RuntimeError("WBP_MainMenu exists but failed to load")
        return asset, False

    _ensure_dir(MENU_FOLDER)
    factory = unreal.WidgetBlueprintFactory()
    factory.set_editor_property("parent_class", parent_class)
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    asset = asset_tools.create_asset(
        "WBP_MainMenu", MENU_FOLDER, unreal.WidgetBlueprint, factory
    )
    if asset is None:
        raise RuntimeError("could not create WBP_MainMenu")
    if not unreal.EditorAssetLibrary.save_loaded_asset(asset):
        raise RuntimeError("could not save WBP_MainMenu")
    return asset, True


def _project_config_dir():
    # Project/Content -> Project/Config
    content = unreal.Paths.project_content_dir()
    project = os.path.dirname(content.rstrip("/\\"))
    return os.path.join(project, "Config")


def _set_ini_value(text, section, key, value):
    section_header = "[%s]" % section
    pattern = re.compile(
        r"(?ms)^(\[%s\].*?)(?=^\[|\Z)" % re.escape(section),
    )
    match = pattern.search(text)
    line = "%s=%s" % (key, value)
    if match is None:
        block = "%s\n%s\n" % (section_header, line)
        if text and not text.endswith("\n"):
            text += "\n"
        return text + "\n" + block, True

    block = match.group(1)
    key_re = re.compile(r"(?m)^%s=.*$" % re.escape(key))
    if key_re.search(block):
        new_block = key_re.sub(line, block, count=1)
    else:
        new_block = block.rstrip("\n") + "\n" + line + "\n"
    if new_block == block:
        return text, False
    return text[: match.start(1)] + new_block + text[match.end(1) :], True


def _update_game_maps_settings():
    """Repoint startup maps at MainMenu; keep GlobalDefaultGameMode as gameplay ShockGameMode.

    Per-map WorldSettings on MainMenu carries ShockMenuGameMode. Travel into 1-Medical uses the
    `?game=` option (and Medical's own WorldSettings) for ShockGameMode possess.
    """
    ini_path = os.path.join(_project_config_dir(), "DefaultEngine.ini")
    if not os.path.isfile(ini_path):
        raise RuntimeError("DefaultEngine.ini missing at %s" % ini_path)

    original = open(ini_path, encoding="utf-8").read()
    text = original
    section = "/Script/EngineSettings.GameMapsSettings"
    changed = False
    for key, value in (
        ("GameDefaultMap", MENU_MAP),
        ("EditorStartupMap", MENU_MAP),
        ("GlobalDefaultGameMode", PLAY_GAME_MODE),
        ("GlobalDefaultServerGameMode", PLAY_GAME_MODE),
    ):
        text, did = _set_ini_value(text, section, key, value)
        changed = changed or did

    if changed and text != original:
        open(ini_path, "w", encoding="utf-8", newline="\n").write(text)
        _log("updated %s GameMapsSettings" % ini_path)
    else:
        _log("GameMapsSettings already pointed at MainMenu")

    return {
        "iniPath": ini_path,
        "gameDefaultMap": MENU_MAP,
        "editorStartupMap": MENU_MAP,
        "changed": changed and text != original,
    }


def _read_game_default_map():
    ini_path = os.path.join(_project_config_dir(), "DefaultEngine.ini")
    text = open(ini_path, encoding="utf-8").read()
    match = re.search(r"(?m)^GameDefaultMap=(.+)$", text)
    return match.group(1).strip() if match else None


def main(report_path):
    report = {
        "menuMap": MENU_MAP,
        "wbp": WBP_PATH,
        "playLevel": PLAY_LEVEL,
        "failures": [],
        "error": None,
    }
    failures = report["failures"]

    mode_class = _require_class(MENU_GAME_MODE)
    widget_class = _require_class(MENU_WIDGET_CPP)
    _require_class(PLAY_GAME_MODE)

    report["menuMapCreated"] = _ensure_menu_map(mode_class)
    wbp, wbp_created = _ensure_wbp(widget_class)
    report["wbpCreated"] = wbp_created
    report["wbpClass"] = wbp.get_name() if wbp else None

    maps = _update_game_maps_settings()
    report["gameMaps"] = maps
    startup = _read_game_default_map()
    report["startupMapReadback"] = startup
    if startup not in (MENU_MAP, MENU_MAP + "." + os.path.basename(MENU_MAP)):
        # Accept both /Game/BioShockUI/MainMenu and asset-form paths.
        if not (startup and startup.replace("\\", "/").startswith(MENU_MAP)):
            failures.append("GameDefaultMap is %s, want %s" % (startup, MENU_MAP))

    if not unreal.EditorAssetLibrary.does_asset_exist(MENU_MAP):
        failures.append("menu map missing after setup")
    if not unreal.EditorAssetLibrary.does_asset_exist(WBP_PATH):
        failures.append("WBP_MainMenu missing after setup")
    if not unreal.EditorAssetLibrary.does_asset_exist(PLAY_LEVEL):
        failures.append("play slice %s missing (run vertical slice first)" % PLAY_LEVEL)

    # Widget CDO resolves Play to the Medical slice.
    cdo = unreal.get_default_object(widget_class)
    play_path = str(cdo.get_resolved_play_level_path())
    report["widgetPlayLevel"] = play_path
    if PLAY_LEVEL not in play_path.replace("\\", "/"):
        failures.append("ShockMainMenuWidget.PlayLevelPath is %s" % play_path)
    travel = str(cdo.get_editor_property("play_travel_options"))
    report["widgetTravelOptions"] = travel
    if "ShockGameMode" not in travel:
        failures.append("PlayTravelOptions missing ShockGameMode: %s" % travel)

    out_dir = os.path.dirname(os.path.abspath(report_path))
    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    if failures:
        raise RuntimeError("setup_main_menu failed:\n- " + "\n- ".join(failures))
    _log("PASS setup_main_menu")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_MAIN_MENU_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\main_menu_setup_report.json",
        )
    )
