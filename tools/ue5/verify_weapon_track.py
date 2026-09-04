"""Game-mode weapon track on 1-Medical: prep map, then -game -bioshockverifyweapontrack.

Equips Pistol, triggers Reload(), samples the weapon actor's world transform over the
reload anim's GetPlayLength(), and logs BIOSHOCK_WEAPON_TRACK_OK / _FAIL.
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
LOG_PATH = os.path.join(os.environ.get("TEMP", "."), "weapon_track_run.log")
OK_RE = re.compile(
    r"BIOSHOCK_WEAPON_TRACK_OK samples=(\d+) range=([-\d.]+) "
    r"first_last=([-\d.]+) anim=(\S+)"
)
FAIL_RE = re.compile(
    r"BIOSHOCK_WEAPON_TRACK_FAIL reason=(\S+)(?: range=([-\d.]+) samples=(\d+))?"
)
END_RE = re.compile(
    r"BIOSHOCK_WEAPON_TRACK_END samples=(\d+) range=([-\d.]+) first_last=([-\d.]+) "
    r"first=\(([-\d.]+),([-\d.]+),([-\d.]+)\) last=\(([-\d.]+),([-\d.]+),([-\d.]+)\) "
    r"anim=(\S+) len=([-\d.]+)"
)
START_RE = re.compile(
    r"BIOSHOCK_WEAPON_TRACK_START anim=(\S+) len=([-\d.]+) socket=(\S+)"
)
SAMPLE_RE = re.compile(
    r"BIOSHOCK_WEAPON_TRACK_SAMPLE i=(\d+) x=([-\d.]+) y=([-\d.]+) z=([-\d.]+) "
    r"pitch=([-\d.]+) yaw=([-\d.]+) roll=([-\d.]+)"
)


def _log(message):
    unreal.log("[bioshock-weapon-track] %s" % message)


def _run_weapon_track(timeout_s=600):
    os.makedirs(os.path.dirname(LOG_PATH) or ".", exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifyweapontrack",
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
            result["range"] = float(fail.group(2))
            result["samples"] = int(fail.group(3))
        end = END_RE.search(text)
        if end:
            result["range"] = float(end.group(2))
            result["first_last"] = float(end.group(3))
            result["samples"] = int(end.group(1))
            result["anim"] = end.group(10)
            result["anim_len"] = float(end.group(11))
            result["first"] = {
                "x": float(end.group(4)),
                "y": float(end.group(5)),
                "z": float(end.group(6)),
            }
            result["last"] = {
                "x": float(end.group(7)),
                "y": float(end.group(8)),
                "z": float(end.group(9)),
            }
        start = START_RE.search(text)
        if start:
            result["socket"] = start.group(3)
        result["sample_count_logged"] = len(list(SAMPLE_RE.finditer(text)))
        return result, "fail:%s" % fail.group(1)
    match = OK_RE.search(text)
    if not match:
        return None, "BIOSHOCK_WEAPON_TRACK_OK not in log"
    result = {
        "ok": True,
        "samples": int(match.group(1)),
        "range": float(match.group(2)),
        "first_last": float(match.group(3)),
        "anim": match.group(4),
    }
    end = END_RE.search(text)
    if end:
        result["anim_len"] = float(end.group(11))
        result["first"] = {
            "x": float(end.group(4)),
            "y": float(end.group(5)),
            "z": float(end.group(6)),
        }
        result["last"] = {
            "x": float(end.group(7)),
            "y": float(end.group(8)),
            "z": float(end.group(9)),
        }
    start = START_RE.search(text)
    if start:
        result["socket"] = start.group(3)
        result["anim_len"] = result.get("anim_len", float(start.group(2)))
    result["sample_count_logged"] = len(list(SAMPLE_RE.finditer(text)))
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
    possess_out = os.path.join(out_dir, "weapon_track_possess_report.json")
    verify_possess.main(schema_path, possess_out, map_path=map_path)
    report["possessPrep"] = "ok"

    exit_code = _run_weapon_track()
    report["gameExitCode"] = exit_code

    parsed, err = _parse_log()
    if parsed is None:
        failures.append(err or "parse failed")
    else:
        report["weaponTrack"] = parsed
        if not parsed.get("ok"):
            failures.append(err or "weapon track fail")
        else:
            if parsed["range"] < 1.0:
                failures.append("weapon world range %.3f (static)" % parsed["range"])
            if parsed["samples"] < 3:
                failures.append("only %d samples" % parsed["samples"])

    report["failures"] = failures
    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("weapon track failed:\n- " + "\n- ".join(failures))
    _log(
        "PASS weapon track range=%.3f samples=%d anim=%s"
        % (parsed["range"], parsed["samples"], parsed["anim"])
    )
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_RUNTIME_SCHEMA"],
        os.environ.get(
            "BIOSHOCK_WEAPON_TRACK_OUT",
            os.path.join(os.environ.get("TEMP", "."), "weapon_track_report.json"),
        ),
    )
