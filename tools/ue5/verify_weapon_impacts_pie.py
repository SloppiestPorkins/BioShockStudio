"""Game-mode wall-impact coverage on 1-Medical: possess prep, then -game -bioshockverifyweaponimpacts.

Fires Pistol / TommyGun / Shotgun / GrenadeLauncher / ChemicalThrower / Crossbow at a real
WorldStatic face (not SimulateWorldImpactForVerify) and asserts ImpactDecalCount advances.
"""

from __future__ import annotations

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
LOG_PATH = os.path.join(os.environ.get("TEMP", "."), "weapon_impacts_pie_run.log")
OUT_DEFAULT = os.path.join(os.environ.get("TEMP", "."), "weapon_impacts_pie_report.json")

OK_RE = re.compile(r"BIOSHOCK_WEAPON_IMPACTS_OK pass=(\d+) fail=0")
FAIL_RE = re.compile(r"BIOSHOCK_WEAPON_IMPACTS_FAIL(?: pass=(\d+) fail=(\d+)| reason=(\S+))")
WEAPON_OK_RE = re.compile(
    r"BIOSHOCK_WEAPON_IMPACT_OK weapon=(\S+) fired=1 decalDelta=(\d+) surface=(\S+)"
)
WEAPON_FAIL_RE = re.compile(
    r"BIOSHOCK_WEAPON_IMPACT_FAIL weapon=(\S+)(?: fired=(\d+) decalDelta=(\d+)| reason=(\S+))"
)
EXPECTED = (
    "Pistol",
    "TommyGun",
    "Shotgun",
    "GrenadeLauncher",
    "ChemicalThrower",
    "Crossbow",
)


def _log(message):
    unreal.log("[bioshock-weapon-impacts-pie] %s" % message)


def _run_game(timeout_s=600):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifyweaponimpacts",
        "-unattended",
        "-nopause",
        "-nosplash",
        "-log",
        "-abslog=%s" % LOG_PATH,
    ]
    return subprocess.run(cmd, timeout=timeout_s).returncode


def _parse_log():
    if not os.path.isfile(LOG_PATH):
        return None, "log missing"
    text = open(LOG_PATH, encoding="utf-8", errors="replace").read()
    fail = FAIL_RE.search(text)
    ok = OK_RE.search(text)
    weapons = []
    for match in WEAPON_OK_RE.finditer(text):
        weapons.append(
            {
                "weapon": match.group(1),
                "ok": True,
                "decalDelta": int(match.group(2)),
                "surface": match.group(3),
            }
        )
    for match in WEAPON_FAIL_RE.finditer(text):
        weapons.append(
            {
                "weapon": match.group(1),
                "ok": False,
                "fired": int(match.group(2) or 0),
                "decalDelta": int(match.group(3) or 0),
                "reason": match.group(4),
            }
        )
    if ok:
        return {"pass": int(ok.group(1)), "fail": 0, "weapons": weapons}, None
    if fail:
        return {
            "pass": int(fail.group(1) or 0),
            "fail": int(fail.group(2) or 1),
            "reason": fail.group(3),
            "weapons": weapons,
        }, "fail:%s" % (fail.group(3) or ("pass=%s fail=%s" % (fail.group(1), fail.group(2))))
    return {"weapons": weapons}, "BIOSHOCK_WEAPON_IMPACTS_OK not in log"


def main(schema_path, report_path, map_path=MAP_PATH):
    report = {
        "map": map_path,
        "schema": schema_path,
        "reportPath": report_path,
        "logPath": LOG_PATH,
        "failures": [],
    }
    failures = report["failures"]

    out_dir = os.path.dirname(os.path.abspath(report_path))
    possess_out = os.path.join(out_dir, "weapon_impacts_possess_report.json")
    verify_possess.main(schema_path, possess_out, map_path=map_path)
    report["possessPrep"] = "ok"

    report["gameExitCode"] = _run_game()
    parsed, err = _parse_log()
    report["result"] = parsed
    if err:
        failures.append(err)
    else:
        names = [w["weapon"] for w in (parsed or {}).get("weapons", []) if w.get("ok")]
        for expected in EXPECTED:
            if expected not in names:
                failures.append("missing OK for %s" % expected)

    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("weapon impacts pie failed:\n- " + "\n- ".join(failures))
    _log("PASS weapon impacts on compiled-world / WorldStatic")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_RUNTIME_SCHEMA",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json",
        ),
        os.environ.get("BIOSHOCK_WEAPON_IMPACTS_OUT", OUT_DEFAULT),
    )
