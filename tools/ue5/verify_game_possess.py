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
SLICE_RE = re.compile(
    r"BIOSHOCK_SLICE_OK enemy=(\S+) mesh=(\d) health_before=([-\d.]+) health_after=([-\d.]+) fire=(\d)"
)
SLICE_FAIL_RE = re.compile(r"BIOSHOCK_SLICE_FAIL reason=(\S+)")
SLICE_SPAWN_RE = re.compile(
    r"BIOSHOCK_SLICE_SPAWN loc=X=([-\d.]+) Y=([-\d.]+) Z=([-\d.]+) "
    r"player=X=([-\d.]+) Y=([-\d.]+) Z=([-\d.]+)"
)


def _log(message):
    unreal.log("[bioshock-game-possess] %s" % message)


def _dist_xy(a, b):
    dx = float(a.x - b.x)
    dy = float(a.y - b.y)
    return (dx * dx + dy * dy) ** 0.5


def _run_game_possess(timeout_s=360):
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
        return None, None, "log missing"
    text = open(LOG_PATH, encoding="utf-8", errors="replace").read()
    fail = FAIL_RE.search(text)
    if fail:
        return None, None, "fail:%s" % fail.group(1)
    slice_fail = SLICE_FAIL_RE.search(text)
    if slice_fail:
        return None, None, "slice_fail:%s" % slice_fail.group(1)
    match = POSSESS_RE.search(text)
    if not match:
        return None, None, "BIOSHOCK_POSSESS_OK not in log"
    possess = {
        "class": match.group(1),
        "x": float(match.group(2)),
        "y": float(match.group(3)),
        "z": float(match.group(4)),
        "playable": int(match.group(5)),
    }
    slice_match = SLICE_RE.search(text)
    if not slice_match:
        return possess, None, "BIOSHOCK_SLICE_OK not in log"
    slice_ok = {
        "enemy": slice_match.group(1),
        "mesh": int(slice_match.group(2)),
        "health_before": float(slice_match.group(3)),
        "health_after": float(slice_match.group(4)),
        "fire": int(slice_match.group(5)),
    }
    spawn_match = SLICE_SPAWN_RE.search(text)
    if spawn_match:
        slice_ok["spawn_x"] = float(spawn_match.group(1))
        slice_ok["spawn_y"] = float(spawn_match.group(2))
        slice_ok["spawn_z"] = float(spawn_match.group(3))
        slice_ok["player_x"] = float(spawn_match.group(4))
        slice_ok["player_y"] = float(spawn_match.group(5))
        slice_ok["player_z"] = float(spawn_match.group(6))
    return possess, slice_ok, None


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

    # Possess prep leaves 1-Medical loaded. Hitscan at the origin would miss inside that BSP.
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(verify_possess.SCRATCH_MAP):
        if not level.new_level(verify_possess.SCRATCH_MAP):
            raise RuntimeError("could not leave Medical before playable-input")

    verify_playable_input.main(input_out)
    report["playableInput"] = "ok"

    exit_code = _run_game_possess()
    report["gameExitCode"] = exit_code

    parsed, slice_ok, err = _parse_log()
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
        if slice_ok is None:
            failures.append(err or "slice parse failed")
        else:
            report["slice"] = slice_ok
            if slice_ok["enemy"] != "SliceBabyJane":
                failures.append("enemy %s" % slice_ok["enemy"])
            if slice_ok["mesh"] != 1:
                failures.append("BabyJane mesh not on enemy")
            if slice_ok["fire"] != 1:
                failures.append("slice fire missed")
            if slice_ok["health_after"] >= slice_ok["health_before"]:
                failures.append("no slice damage (%s -> %s)" % (
                    slice_ok["health_before"], slice_ok["health_after"]))
            if "spawn_x" not in slice_ok:
                failures.append("BIOSHOCK_SLICE_SPAWN not in log")
            else:
                spawn_xy = (
                    (slice_ok["spawn_x"] - slice_ok["player_x"]) ** 2
                    + (slice_ok["spawn_y"] - slice_ok["player_y"]) ** 2
                ) ** 0.5
                report["sliceSpawnXy"] = spawn_xy
                if spawn_xy < 200.0 or spawn_xy > 400.0:
                    failures.append("slice spawn XY %.0f uu from player (want ~250)" % spawn_xy)

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
