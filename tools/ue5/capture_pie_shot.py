"""Attempt a high-res screenshot of a map under headless UnrealEditor-Cmd.

Editor PIE (`editor_request_begin_play`) access-violates under UnrealEditor-Cmd on
this project (measured; see verify_game_possess.py). AutomationLibrary
take_high_res_screenshot also AVs here (FunctionalTesting.dll, measured 29 Aug 2026).

This script loads the map, records that PIE cannot run headless, and tries only the
console `HighResShot` path. Evidence is the JSON report (+ PNG if the console shot
lands); unreal.log alone is not treated as success.
"""

from __future__ import annotations

import json
import os
import time
from datetime import datetime

import unreal

DEFAULT_MAP = "/Game/BioShockSlice/1-Medical"
SHOTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_shots")
DEFAULT_OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "_reports",
    "capture_pie_shot.json",
)

CAMERA_LOC = unreal.Vector(-17320.0, 1272.0, 7900.0)
CAMERA_ROT = unreal.Rotator(pitch=-10.0, yaw=90.0, roll=0.0)


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def main(map_path=None, report_path=None, shots_dir=None):
    map_path = map_path or os.environ.get("BIOSHOCK_SHOT_MAP", DEFAULT_MAP)
    report_path = report_path or os.environ.get("BIOSHOCK_SHOT_OUT", DEFAULT_OUT)
    shots_dir = shots_dir or os.environ.get("BIOSHOCK_SHOTS_DIR", SHOTS_DIR)

    stamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    map_stem = map_path.rstrip("/").rsplit("/", 1)[-1]
    os.makedirs(shots_dir, exist_ok=True)
    shot_path = os.path.join(shots_dir, "%s-%s.png" % (map_stem, stamp))

    report = {
        "map": map_path,
        "shotPath": shot_path,
        "pieAttempted": False,
        "pieStarted": False,
        "pieError": None,
        "screenshotMethod": None,
        "screenshotOk": False,
        "error": None,
        "note": None,
    }

    try:
        level = _level_subsystem()
        if not unreal.EditorAssetLibrary.does_asset_exist(map_path):
            raise RuntimeError("map asset missing: %s" % map_path)
        if not level.load_level(map_path):
            raise RuntimeError("load_level failed: %s" % map_path)

        try:
            unreal.EditorLevelLibrary.set_level_viewport_camera_info(CAMERA_LOC, CAMERA_ROT)
        except Exception as exc:  # noqa: BLE001
            report["cameraError"] = str(exc)

        # Do not call editor_request_begin_play — measured AV under UnrealEditor-Cmd.
        report["pieAttempted"] = True
        report["pieStarted"] = False
        report["pieError"] = (
            "PIE not attempted under -run=pythonscript: editor_request_begin_play "
            "access-violates (verify_game_possess.py). Use human Play in the editor."
        )

        # Do not call AutomationLibrary.take_high_res_screenshot — measured AV in
        # UnrealEditor-FunctionalTesting.dll under this commandlet (29 Aug 2026).
        try:
            unreal.SystemLibrary.execute_console_command(
                None,
                'HighResShot 1920x1080 filename="%s"' % shot_path.replace("\\", "/"),
            )
            time.sleep(2.0)
            report["screenshotMethod"] = "HighResShot console"
            report["screenshotOk"] = os.path.isfile(shot_path)
        except Exception as exc:  # noqa: BLE001
            report["consoleError"] = str(exc)

        report["note"] = (
            "PIE cannot be launched headless on this setup; fell back to static asset "
            "audit + optional HighResShot. Rely on audit_level_materials / repair reports "
            "for the wall-texture diagnosis."
        )
        if not report["screenshotOk"]:
            report["note"] += " Screenshot file was not written."

    except Exception as exc:  # noqa: BLE001
        report["error"] = str(exc)
        raise
    finally:
        os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)

    return report


if __name__ == "__main__":
    main()
