"""Game-mode possess on 1-Medical: prep map, then -game -bioshockverifypossess.

Editor PIE (editor_request_begin_play) access-violates under UnrealEditor-Cmd; this uses
standalone -game with ShockGameMode::PostLogin logging BIOSHOCK_POSSESS_OK and quitting.
"""

import json
import os
import re
import subprocess

import unreal

import verify_playable_input
import verify_possess

MAP_PATH = "/Game/BioShockSlice/1-Medical"
MEDICAL_START = verify_possess.MEDICAL_START
GAME_URL = "%s?game=/Script/BioShockRuntime.ShockGameMode" % MAP_PATH
UE_CMD = r"G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
PROJECT = r"C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
LOG_PATH = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\game_possess_run.log"
POSSESS_RE = re.compile(
    r"BIOSHOCK_POSSESS_OK class=(\S+) x=([-\d.]+) y=([-\d.]+) z=([-\d.]+) playable=(\d)"
)
FAIL_RE = re.compile(r"BIOSHOCK_POSSESS_FAIL reason=(\S+)")


def _log(message):
    unreal.log("[bioshock-game-possess] %s" % message)


def _dist_xy(a, b):
    dx = float(a.x - b.x)
    dy = float(a.y - b.y)
    return (dx * dx + dy * dy) ** 0.5


def _run_game_possess(timeout_s=180):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifypossess",
        "-unattended",
        "-nopause",
        "-nosplash",
        "-log",
        "-abslog=%s" % LOG_PATH,
    ]
    proc = subprocess.run(cmd, timeout=timeout_s)
    return proc.returncode


def _parse_log():
    if not os.path.isfile(LOG_PATH):
        return None, "log missing"
    text = open(LOG_PATH, encoding="utf-8", errors="replace").read()
    fail = FAIL_RE.search(text)
    if fail:
        return None, "fail:%s" % fail.group(1)
    match = POSSESS_RE.search(text)
    if not match:
        return None, "BIOSHOCK_POSSESS_OK not in log"
    return {
        "class": match.group(1),
        "x": float(match.group(2)),
        "y": float(match.group(3)),
        "z": float(match.group(4)),
        "playable": int(match.group(5)),
    }, None


def main(schema_path, report_path, map_path=MAP_PATH):
    report = {
        "map": map_path,
        "schema": schema_path,
        "reportPath": report_path,
        "possessPath": "game-mode-postlogin",
        "error": None,
    }
    failures = []

    out_dir = os.path.dirname(os.path.abspath(report_path))
    possess_out = os.path.join(out_dir, "possess_report.json")
    input_out = os.path.join(out_dir, "playable_input_report.json")

    verify_possess.main(schema_path, possess_out, map_path=map_path)
    report["possessPrep"] = "ok"

    verify_playable_input.main(input_out)
    report["playableInput"] = "ok"

    exit_code = _run_game_possess()
    report["gameExitCode"] = exit_code

    parsed, err = _parse_log()
    if parsed is None:
        failures.append(err or "parse failed")
    else:
        report["pawn"] = parsed
        if "ShockPlayer" not in parsed["class"]:
            failures.append("pawn class %s" % parsed["class"])
        loc = unreal.Vector(parsed["x"], parsed["y"], parsed["z"])
        xy = _dist_xy(loc, MEDICAL_START)
        report["xyDistanceFromMedicalStart"] = xy
        if xy > 250.0:
            failures.append("pawn %.0f units XY from MedicalStart" % xy)
        if parsed["playable"] != 1:
            failures.append("playable input not enabled")

    report["failures"] = failures
    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("game possess failed:\n- " + "\n- ".join(failures))
    _log("PASS game possess at MedicalStart")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_RUNTIME_SCHEMA"],
        os.environ.get(
            "BIOSHOCK_GAME_POSSESS_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\game_possess_report.json",
        ),
    )
