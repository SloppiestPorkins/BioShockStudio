"""Game-mode ragdoll coverage: every Medical archetype key, not just SliceEnemy0 / BabyJane.

Prep possess, collect archetype names from the level manifest (or BIOSHOCK_RAGDOLL_KEYS),
then -game -bioshockverifyragdollcoverage -bioshockragdollkeys=...
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
LOG_PATH = os.path.join(os.environ.get("TEMP", "."), "ragdoll_coverage_run.log")
OUT_DEFAULT = os.path.join(os.environ.get("TEMP", "."), "ragdoll_coverage_report.json")
DEFAULT_MANIFEST = os.path.join(
    r"C:\Users\Jack\Documents\BioShockUE5",
    "Exports",
    "slice",
    "1-Medical",
    "1-Medical.ue5-level.json",
)

OK_RE = re.compile(r"BIOSHOCK_RAGDOLL_COVERAGE_OK pass=(\d+) fail=0")
FAIL_RE = re.compile(
    r"BIOSHOCK_RAGDOLL_COVERAGE_FAIL(?: pass=(\d+) fail=(\d+) unavailable=(\d+)| archetype=(\S+) reason=(\S+)| reason=(\S+))"
)
ARCH_OK_RE = re.compile(
    r"BIOSHOCK_RAGDOLL_COVERAGE_OK archetype=(\S+) dead=(\d+) active=1 physics=(\S+)"
)
ARCH_FAIL_RE = re.compile(
    r"BIOSHOCK_RAGDOLL_COVERAGE_FAIL archetype=(\S+) dead=(\d+) active=0 mesh=(\d+) physics=(\d+)"
)
UNAVAILABLE_RE = re.compile(r"BIOSHOCK_RAGDOLL_UNAVAILABLE ai=(\S+)(?: mesh=(\S+))? physicsAsset=0")


def _log(message):
    unreal.log("[bioshock-ragdoll-coverage] %s" % message)


def _manifest_archetype_keys(manifest_path):
    if not os.path.isfile(manifest_path):
        return []
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    keys = []
    for entry in manifest.get("archetypes") or []:
        name = entry.get("name") or entry.get("key") or entry.get("aiType")
        if name:
            keys.append(str(name))
    # Fallback: mesh names used by combat-looking actors when archetypes array is empty.
    if not keys:
        for entry in manifest.get("actors") or []:
            mesh = entry.get("skeletalMesh")
            cn = entry.get("className") or ""
            if mesh and ("Agg_" in str(mesh) or "Splicer" in cn or "Aggressor" in cn):
                keys.append(str(mesh))
    # Stable unique order.
    seen = set()
    out = []
    for key in keys:
        if key not in seen:
            seen.add(key)
            out.append(key)
    return out


def _resolve_keys():
    env_keys = os.environ.get("BIOSHOCK_RAGDOLL_KEYS", "").strip()
    if env_keys:
        return [part.strip() for part in env_keys.split(",") if part.strip()]
    manifest = os.environ.get("BIOSHOCK_RAGDOLL_MANIFEST", DEFAULT_MANIFEST)
    keys = _manifest_archetype_keys(manifest)
    if keys:
        return keys
    return [
        "Agg_BabyJane",
        "ThuggishSplicer",
        "LeadheadSplicer",
        "MachineGunMutant",
        "RangedAggressor",
    ]


def _run_game(keys, timeout_s=600):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifyragdollcoverage",
        "-bioshockragdollkeys=%s" % ",".join(keys),
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
    ok_arch = [
        {
            "archetype": m.group(1),
            "ok": True,
            "dead": int(m.group(2)),
            "physics": m.group(3),
        }
        for m in ARCH_OK_RE.finditer(text)
    ]
    fail_arch = [
        {
            "archetype": m.group(1),
            "ok": False,
            "dead": int(m.group(2)),
            "mesh": int(m.group(3)),
            "physics": int(m.group(4)),
        }
        for m in ARCH_FAIL_RE.finditer(text)
    ]
    unavailable = [
        {"ai": m.group(1), "mesh": m.group(2)} for m in UNAVAILABLE_RE.finditer(text)
    ]
    summary_ok = OK_RE.search(text)
    summary_fail = FAIL_RE.search(text)
    result = {
        "okArchetypes": ok_arch,
        "failArchetypes": fail_arch,
        "unavailable": unavailable,
    }
    if summary_ok:
        result["pass"] = int(summary_ok.group(1))
        result["fail"] = 0
        return result, None
    if summary_fail:
        result["pass"] = int(summary_fail.group(1) or 0)
        result["fail"] = int(summary_fail.group(2) or 1)
        result["unavailableCount"] = int(summary_fail.group(3) or 0)
        result["reason"] = summary_fail.group(4) or summary_fail.group(6)
        return result, "coverage fail"
    return result, "BIOSHOCK_RAGDOLL_COVERAGE_OK not in log"


def main(schema_path, report_path, map_path=MAP_PATH):
    report = {
        "map": map_path,
        "schema": schema_path,
        "reportPath": report_path,
        "logPath": LOG_PATH,
        "failures": [],
    }
    failures = report["failures"]
    keys = _resolve_keys()
    report["archetypeKeys"] = keys

    out_dir = os.path.dirname(os.path.abspath(report_path))
    possess_out = os.path.join(out_dir, "ragdoll_coverage_possess_report.json")
    verify_possess.main(schema_path, possess_out, map_path=map_path)
    report["possessPrep"] = "ok"

    report["gameExitCode"] = _run_game(keys)
    parsed, err = _parse_log()
    report["result"] = parsed
    if err:
        failures.append(err)
        for entry in (parsed or {}).get("failArchetypes") or []:
            failures.append(
                "%s dead=%s mesh=%s physics=%s"
                % (entry["archetype"], entry["dead"], entry["mesh"], entry["physics"])
            )
        for entry in (parsed or {}).get("unavailable") or []:
            failures.append("BIOSHOCK_RAGDOLL_UNAVAILABLE ai=%s mesh=%s" % (
                entry.get("ai"), entry.get("mesh")))

    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ragdoll coverage failed:\n- " + "\n- ".join(failures))
    _log("PASS ragdoll coverage for %d archetype keys" % len(keys))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_RUNTIME_SCHEMA",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json",
        ),
        os.environ.get("BIOSHOCK_RAGDOLL_COVERAGE_OUT", OUT_DEFAULT),
    )
