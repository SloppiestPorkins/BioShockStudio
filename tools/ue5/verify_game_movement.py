"""Game-mode movement on 1-Medical: prep map, then -game -bioshockverifymovement.

Editor PIE (editor_request_begin_play) access-violates under UnrealEditor-Cmd; this uses
standalone -game with ShockGameMode driving MoveForward for real seconds, logging
BIOSHOCK_MOVEMENT_OK / _FAIL, and quitting.
"""

import json
import os
import re
import subprocess

import unreal

import verify_possess

MAP_PATH = "/Game/BioShockSlice/1-Medical"
GAME_URL = "%s?game=/Script/BioShockRuntime.ShockGameMode" % MAP_PATH
UE_CMD = r"G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
PROJECT = r"C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
LOG_PATH = os.path.join(os.environ.get("TEMP", "."), "game_movement_run.log")
OK_RE = re.compile(
    r"BIOSHOCK_MOVEMENT_OK displacement=([-\d.]+) mode_start=(\S+) mode_end=(\S+)"
)
FAIL_RE = re.compile(
    r"BIOSHOCK_MOVEMENT_FAIL reason=(\S+)(?: displacement=([-\d.]+) "
    r"mode_start=(\S+) mode_end=(\S+))?"
)
END_RE = re.compile(
    r"BIOSHOCK_MOVEMENT_END start=\(([-\d.]+),([-\d.]+),([-\d.]+)\) "
    r"end=\(([-\d.]+),([-\d.]+),([-\d.]+)\) "
    r"displacement=([-\d.]+) mode_start=(\S+) mode_end=(\S+) disabled_seen=(\d)"
)


def _log(message):
    unreal.log("[bioshock-game-movement] %s" % message)


def _run_game_movement(timeout_s=600):
    os.makedirs(os.path.dirname(LOG_PATH) or ".", exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifymovement",
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
        result = {"ok": False, "reason": fail.group(1)}
        if fail.group(2) is not None:
            result["displacement"] = float(fail.group(2))
            result["mode_start"] = fail.group(3)
            result["mode_end"] = fail.group(4)
        end = END_RE.search(text)
        if end:
            result["disabled_seen"] = int(end.group(10))
        return result, "fail:%s" % fail.group(1)
    match = OK_RE.search(text)
    if not match:
        return None, "BIOSHOCK_MOVEMENT_OK not in log"
    result = {
        "ok": True,
        "displacement": float(match.group(1)),
        "mode_start": match.group(2),
        "mode_end": match.group(3),
    }
    end = END_RE.search(text)
    if end:
        result["start"] = {
            "x": float(end.group(1)),
            "y": float(end.group(2)),
            "z": float(end.group(3)),
        }
        result["end"] = {
            "x": float(end.group(4)),
            "y": float(end.group(5)),
            "z": float(end.group(6)),
        }
        result["disabled_seen"] = int(end.group(10))
    return result, None


def main(schema_path, report_path, map_path=MAP_PATH):
    report = {
        "map": map_path,
        "schema": schema_path,
        "reportPath": report_path,
        "logPath": LOG_PATH,
        "error": None,
    }
    failures = []

    out_dir = os.path.dirname(os.path.abspath(report_path))
    possess_out = os.path.join(out_dir, "movement_possess_report.json")
    verify_possess.main(schema_path, possess_out, map_path=map_path)
    report["possessPrep"] = "ok"

    exit_code = _run_game_movement()
    report["gameExitCode"] = exit_code

    parsed, err = _parse_log()
    if parsed is None:
        failures.append(err or "parse failed")
    else:
        report["movement"] = parsed
        if not parsed.get("ok"):
            failures.append(err or "movement fail")
        else:
            if parsed["displacement"] < 10.0:
                failures.append("displacement %.1f too small" % parsed["displacement"])
            if parsed["mode_start"] == "MOVE_None" or parsed["mode_end"] == "MOVE_None":
                failures.append(
                    "mode %s -> %s" % (parsed["mode_start"], parsed["mode_end"])
                )
            if parsed.get("disabled_seen") == 1:
                failures.append("bMovementDisabled seen during drive window")

    report["failures"] = failures
    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("game movement failed:\n- " + "\n- ".join(failures))
    _log(
        "PASS movement displacement=%.1f %s -> %s"
        % (parsed["displacement"], parsed["mode_start"], parsed["mode_end"])
    )
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_RUNTIME_SCHEMA"],
        os.environ.get(
            "BIOSHOCK_GAME_MOVEMENT_OUT",
            os.path.join(os.environ.get("TEMP", "."), "game_movement_report.json"),
        ),
    )
