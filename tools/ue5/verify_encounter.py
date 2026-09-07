"""Game-mode encounter on 1-Medical: possess prep, then -game -bioshockverifyencounter.

Waits for the asynchronously generated navmesh and staggered slice spawns, then asserts three
labeled enemies, one armed,
all targeting SlicePlayer.
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
LOG_PATH = os.path.join(os.environ.get("TEMP", "."), "encounter_run.log")
ENCOUNTER_RE = re.compile(
    r"BIOSHOCK_ENCOUNTER spawned=(\d+) armed=(\d+) targeting=(\d+)"
)
ENCOUNTER_FAIL_RE = re.compile(r"BIOSHOCK_ENCOUNTER_FAIL reason=(\S+)")
ENEMY_RE = re.compile(
    r"BIOSHOCK_ENCOUNTER_ENEMY label=(\S+) weapon=(\d) target=(\d+)"
)
EXPECTED_LABELS = ("SliceEnemy0", "SliceEnemy1", "SliceEnemy2")


def _log(message):
    unreal.log("[bioshock-encounter] %s" % message)


def _run_encounter_verify(timeout_s=360):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifyencounter",
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
    fail = ENCOUNTER_FAIL_RE.search(text)
    if fail:
        return None, None, "fail:%s" % fail.group(1)
    match = ENCOUNTER_RE.search(text)
    if not match:
        return None, None, "BIOSHOCK_ENCOUNTER not in log"
    summary = {
        "spawned": int(match.group(1)),
        "armed": int(match.group(2)),
        "targeting": int(match.group(3)),
    }
    enemies = []
    for enemy_match in ENEMY_RE.finditer(text):
        enemies.append(
            {
                "label": enemy_match.group(1),
                "weapon": int(enemy_match.group(2)),
                "target": int(enemy_match.group(3)),
            }
        )
    return summary, enemies, None


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
    possess_out = os.path.join(out_dir, "encounter_possess_report.json")
    verify_possess.main(schema_path, possess_out, map_path=map_path)
    report["possessPrep"] = "ok"

    exit_code = _run_encounter_verify()
    report["gameExitCode"] = exit_code

    summary, enemies, err = _parse_log()
    if summary is None:
        failures.append(err or "parse failed")
    else:
        report["encounter"] = summary
        report["enemies"] = enemies
        labels = [enemy["label"] for enemy in enemies]
        report["labels"] = labels

        if summary["spawned"] != 3:
            failures.append("spawned %d (want 3)" % summary["spawned"])
        if len(enemies) != 3:
            failures.append("enemy log lines %d (want 3)" % len(enemies))
        if sorted(labels) != sorted(EXPECTED_LABELS):
            failures.append("labels %s" % labels)
        if summary["armed"] < 1:
            failures.append("no armed enemy")
        if summary["targeting"] != 3:
            failures.append("targeting %d (want 3)" % summary["targeting"])
        for enemy in enemies:
            if enemy["target"] != 1:
                failures.append("%s not targeting player" % enemy["label"])

    report["failures"] = failures
    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("encounter verify failed:\n- " + "\n- ".join(failures))
    _log("PASS slice encounter (3 enemies, staggered)")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_RUNTIME_SCHEMA"],
        os.environ.get(
            "BIOSHOCK_ENCOUNTER_OUT",
            os.path.join(os.environ.get("TEMP", "."), "encounter_report.json"),
        ),
    )
