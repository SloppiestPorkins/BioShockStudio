"""Shared physics path: UShockPhysicsLibrary + scripted physics actions via ApplyInWorld.

Editor -run=pythonscript has no Chaos body sim (Null/editor world). Physics assertions run
under standalone -game via RunHeadlessSelfTest; this script drives that subprocess and checks
the log for BIOSHOCK_PHYSICS_OK.
"""

import json
import os
import re
import subprocess

import unreal

UE_CMD = r"G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
PROJECT = r"C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
GAME_URL = "/Game/BioShockSlice/1-Medical?game=/Script/BioShockRuntime.ShockGameMode"
OK_RE = re.compile(r"BIOSHOCK_PHYSICS_OK")
FAIL_RE = re.compile(r"BIOSHOCK_PHYSICS_FAIL reason=(\S+)")


def _log(m):
    unreal.log("[bioshock-script-physics-exec] %s" % m)


def _run_game_physics(log_path, timeout_s=360):
    os.makedirs(os.path.dirname(os.path.abspath(log_path)), exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifyphysics",
        "-unattended",
        "-nopause",
        "-nosplash",
        "-log",
        "-abslog=%s" % log_path,
    ]
    return subprocess.run(cmd, timeout=timeout_s).returncode


def _parse_log(log_path):
    if not os.path.isfile(log_path):
        return False, "log missing"
    text = open(log_path, encoding="utf-8", errors="replace").read()
    if OK_RE.search(text):
        return True, "ok"
    fail = FAIL_RE.search(text)
    if fail:
        return False, fail.group(1)
    return False, "BIOSHOCK_PHYSICS_OK not in log"


def main(out):
    report = {"failures": []}
    f = report["failures"]

    log_path = os.path.join(os.environ.get("TEMP", "."), "physics_exec_game.log")
    exit_code = _run_game_physics(log_path)
    if exit_code != 0:
        f.append("game exit %s" % exit_code)
    ok, detail = _parse_log(log_path)
    if not ok:
        f.append("game physics %s" % detail)
    report["physics_exec"] = "ok" if not f else "fail"
    report["game_log"] = log_path

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("physics-exec:\n- " + "\n- ".join(f))
    _log("PASS physics-exec")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "script_physics_exec_report.json"),
        )
    )
