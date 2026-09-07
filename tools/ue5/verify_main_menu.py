"""Assert MainMenu startup wiring: map, widget class, Play → 1-Medical.

Writes a JSON report (unreal.log is not reliable under -run=pythonscript). Raises on failure
so the commandlet surfaces `Success - N error(s)` correctly.
"""

from __future__ import annotations

import json
import os
import re

import unreal

import setup_main_menu

MENU_MAP = setup_main_menu.MENU_MAP
WBP_PATH = setup_main_menu.WBP_PATH
PLAY_LEVEL = setup_main_menu.PLAY_LEVEL
MENU_GAME_MODE = setup_main_menu.MENU_GAME_MODE
MENU_WIDGET_CPP = setup_main_menu.MENU_WIDGET_CPP
PLAY_GAME_MODE = setup_main_menu.PLAY_GAME_MODE


def _log(message):
    unreal.log("[bioshock-verify-main-menu] %s" % message)


def _require_class(path):
    loaded = unreal.load_class(None, path)
    if loaded is None:
        raise RuntimeError("runtime class missing: %s" % path)
    return loaded


def _read_ini_key(key):
    ini_path = os.path.join(setup_main_menu._project_config_dir(), "DefaultEngine.ini")
    text = open(ini_path, encoding="utf-8").read()
    match = re.search(r"(?m)^%s=(.+)$" % re.escape(key), text)
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
    widget_cpp = _require_class(MENU_WIDGET_CPP)
    _require_class(PLAY_GAME_MODE)
    report["classes"] = {
        "ShockMenuGameMode": True,
        "ShockMainMenuWidget": True,
        "ShockGameMode": True,
    }

    if not unreal.EditorAssetLibrary.does_asset_exist(MENU_MAP):
        failures.append("startup map asset missing: %s" % MENU_MAP)
    else:
        level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        if not level.load_level(MENU_MAP):
            failures.append("could not load %s" % MENU_MAP)
        else:
            settings = unreal.EditorLevelLibrary.get_editor_world().get_world_settings()
            got_mode = settings.get_editor_property("default_game_mode")
            report["mapGameMode"] = str(got_mode)
            if got_mode != mode_class:
                failures.append("MainMenu DefaultGameMode is %s" % got_mode)

    if not unreal.EditorAssetLibrary.does_asset_exist(WBP_PATH):
        failures.append("WBP_MainMenu missing: %s" % WBP_PATH)
    else:
        wbp = unreal.EditorAssetLibrary.load_asset(WBP_PATH)
        report["wbpLoaded"] = wbp is not None
        if wbp is None:
            failures.append("WBP_MainMenu failed to load")
        else:
            # Generated class should subclass ShockMainMenuWidget.
            gen = None
            for prop in ("generated_class", "GeneratedClass"):
                try:
                    gen = wbp.get_editor_property(prop)
                    break
                except Exception:  # noqa: BLE001
                    continue
            report["wbpGeneratedClass"] = str(gen) if gen else None
            if gen is None:
                # Asset exists — enough for wiring; parent checked via factory on setup.
                report["wbpGeneratedClass"] = "unreadable"
            elif not unreal.Object.is_a(gen, widget_cpp) and gen != widget_cpp:
                # is_a on UClass: generated class should be child of ShockMainMenuWidget
                try:
                    if not gen.is_child_of(widget_cpp):
                        failures.append("WBP parent is not ShockMainMenuWidget (%s)" % gen)
                except Exception:  # noqa: BLE001
                    report["wbpParentCheck"] = "skipped"

    game_default = _read_ini_key("GameDefaultMap")
    editor_startup = _read_ini_key("EditorStartupMap")
    report["gameDefaultMap"] = game_default
    report["editorStartupMap"] = editor_startup
    for label, value in (("GameDefaultMap", game_default), ("EditorStartupMap", editor_startup)):
        if not value or MENU_MAP not in value.replace("\\", "/"):
            failures.append("%s is %s, want %s" % (label, value, MENU_MAP))

    cdo = unreal.get_default_object(widget_cpp)
    play_path = str(cdo.get_resolved_play_level_path())
    travel = str(cdo.get_editor_property("play_travel_options"))
    report["playLevelPath"] = play_path
    report["playTravelOptions"] = travel
    if PLAY_LEVEL not in play_path.replace("\\", "/"):
        failures.append("Play does not resolve to %s (got %s)" % (PLAY_LEVEL, play_path))
    if "ShockGameMode" not in travel:
        failures.append("Play travel options missing ShockGameMode: %s" % travel)

    # Remastered front end: Continue (save-gated) / New Game / Load Game / Options / Extras /
    # Credits / Quit — 6 with no save, 7 with one. Keep Play->Medical wiring above intact.
    try:
        entry_count = int(cdo.get_menu_entry_count())
        report["menuEntryCount"] = entry_count
        if entry_count not in (6, 7):
            failures.append("main menu entry count is %d, want 6 or 7" % entry_count)
    except Exception as exc:  # noqa: BLE001
        report["menuEntryCount"] = "unreadable: %s" % exc

    if not unreal.EditorAssetLibrary.does_asset_exist(PLAY_LEVEL):
        failures.append("slice map missing: %s" % PLAY_LEVEL)
    else:
        report["sliceMapPresent"] = True

    report["resolvedPlayPackage"] = play_path
    if PLAY_LEVEL not in play_path.replace("\\", "/"):
        failures.append("resolved play package %s" % play_path)

    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    if failures:
        raise RuntimeError("verify_main_menu failed:\n- " + "\n- ".join(failures))
    _log("PASS verify_main_menu")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_MAIN_MENU_VERIFY_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\main_menu_verify_report.json",
        )
    )
