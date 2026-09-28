"""Game-mode interact-trace coverage on the live 1-Medical slice map.

Enumerates placed AShockConsumablePickup / AShockSearchableContainer / AShockStationBase,
teleports a possessed player in front of each, runs TickInteractionTrace, asserts prompt +
HandleInteractInput effect. Zero placed actors of a type is reported plainly (not a false fail).

w19: PROMPT_FAIL lines are paired with BIOSHOCK_INTERACT_TRACE_HIT diagnostics that record the
raw Visibility hit (hitActor / hitDist) and FaceActor stand placement, so a miss can be
classified as no-hit / wrong-mesh / wrong-interactable without guessing.
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
LOG_PATH = os.path.join(os.environ.get("TEMP", "."), "interact_trace_run.log")
OUT_DEFAULT = os.path.join(os.environ.get("TEMP", "."), "interact_trace_report.json")

COUNTS_RE = re.compile(
    r"BIOSHOCK_INTERACT_COUNTS pickups=(\d+) containers=(\d+) stations=(\d+)"
)
OK_RE = re.compile(
    r"BIOSHOCK_INTERACT_OK (?:placed=0 note=(\S+)|targets=(\d+) promptOk=(\d+) actionOk=(\d+))"
)
FAIL_RE = re.compile(
    r"BIOSHOCK_INTERACT_FAIL targets=(\d+) promptFail=(\d+) actionFail=(\d+) "
    r"pickupsInteract=(\d+) containers=(\d+) stations=(\d+)"
)
PROMPT_FAIL_RE = re.compile(
    r"BIOSHOCK_INTERACT_PROMPT_FAIL kind=(\S+) actor=(\S+)"
)
# w19 diagnostic emitted immediately after each PROMPT_FAIL.
TRACE_HIT_RE = re.compile(
    r"BIOSHOCK_INTERACT_TRACE_HIT kind=(?P<kind>\S+) target=(?P<target>\S+) "
    r"hit=(?P<hit>[01]) hitActor=(?P<hitActor>\S+) hitDist=(?P<hitDist>-?[\d.]+) "
    r"stand=\((?P<sx>-?[\d.]+),(?P<sy>-?[\d.]+),(?P<sz>-?[\d.]+)\) "
    r"targetAim=\((?P<tx>-?[\d.]+),(?P<ty>-?[\d.]+),(?P<tz>-?[\d.]+)\) "
    r"standToTarget=(?P<standToTarget>-?[\d.]+) awayDegenerate=(?P<awayDegenerate>[01]) "
    r"cached=(?P<cached>\S+) prompt=(?P<prompt>.*)$",
    re.MULTILINE,
)


def _log(message):
    unreal.log("[bioshock-interact-trace] %s" % message)


def _run_game(timeout_s=600):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifyinteract",
        "-unattended",
        "-nopause",
        "-nosplash",
        "-log",
        "-abslog=%s" % LOG_PATH,
    ]
    return subprocess.run(cmd, timeout=timeout_s).returncode


def _classify_trace_hit(entry):
    """Bucket a TRACE_HIT row for the report summary (no Unreal required)."""
    if entry.get("hit") != 1:
        return "no_hit"
    hit_actor = entry.get("hitActor") or "None"
    target = entry.get("target") or ""
    cached = entry.get("cached") or "None"
    if hit_actor == "None":
        return "hit_null_actor"
    if hit_actor == target:
        return "hit_target_but_no_prompt"
    if cached not in ("None", "", None) and cached != target:
        return "wrong_interactable"
    # Hit something that is not the target and did not become CachedInteractActor.
    return "wrong_mesh_or_blocker"


def _parse_log():
    if not os.path.isfile(LOG_PATH):
        return None, "log missing"
    text = open(LOG_PATH, encoding="utf-8", errors="replace").read()
    counts = COUNTS_RE.search(text)
    trace_hits = []
    class_counts = {}
    for match in TRACE_HIT_RE.finditer(text):
        entry = match.groupdict()
        entry["hit"] = int(entry["hit"])
        entry["hitDist"] = float(entry["hitDist"])
        entry["standToTarget"] = float(entry["standToTarget"])
        entry["awayDegenerate"] = int(entry["awayDegenerate"])
        entry["stand"] = [
            float(entry.pop("sx")),
            float(entry.pop("sy")),
            float(entry.pop("sz")),
        ]
        entry["targetAim"] = [
            float(entry.pop("tx")),
            float(entry.pop("ty")),
            float(entry.pop("tz")),
        ]
        entry["classification"] = _classify_trace_hit(entry)
        class_counts[entry["classification"]] = class_counts.get(entry["classification"], 0) + 1
        trace_hits.append(entry)

    result = {
        "pickups": int(counts.group(1)) if counts else None,
        "containers": int(counts.group(2)) if counts else None,
        "stations": int(counts.group(3)) if counts else None,
        "promptFails": [m.group(0) for m in PROMPT_FAIL_RE.finditer(text)],
        "traceHits": trace_hits,
        "traceHitClasses": class_counts,
    }
    ok = OK_RE.search(text)
    fail = FAIL_RE.search(text)
    if ok:
        if ok.group(1):
            result["note"] = ok.group(1)
            result["targets"] = 0
        else:
            result["targets"] = int(ok.group(2))
            result["promptOk"] = int(ok.group(3))
            result["actionOk"] = int(ok.group(4))
        return result, None
    if fail:
        result.update(
            {
                "targets": int(fail.group(1)),
                "promptFail": int(fail.group(2)),
                "actionFail": int(fail.group(3)),
                "pickupsInteract": int(fail.group(4)),
                "containers": int(fail.group(5)),
                "stations": int(fail.group(6)),
            }
        )
        return result, "interact fail"
    return result, "BIOSHOCK_INTERACT_OK not in log"


def main(schema_path, report_path, map_path=MAP_PATH):
    report = {
        "map": map_path,
        "schema": schema_path,
        "reportPath": report_path,
        "logPath": LOG_PATH,
        "failures": [],
        "knownGaps": [
            "No generic DoorSwitch / lever / valve actor class is wired; "
            "ShockActionEnableOrDisableLevelSwitching only gates level travel. "
            "Switches are a known-missing feature, not this interact-trace bug."
        ],
    }
    failures = report["failures"]

    out_dir = os.path.dirname(os.path.abspath(report_path))
    possess_out = os.path.join(out_dir, "interact_trace_possess_report.json")
    verify_possess.main(schema_path, possess_out, map_path=map_path)
    report["possessPrep"] = "ok"

    report["gameExitCode"] = _run_game()
    parsed, err = _parse_log()
    report["result"] = parsed
    if err:
        failures.append(err)
        for line in (parsed or {}).get("promptFails") or []:
            failures.append(line)
        # Surface the classification histogram so a fail report names the dominant mode
        # (wrong_mesh vs no_hit vs wrong_interactable) without grepping the raw log.
        classes = (parsed or {}).get("traceHitClasses") or {}
        if classes:
            failures.append("traceHitClasses=%s" % json.dumps(classes, sort_keys=True))
        for hit in (parsed or {}).get("traceHits") or []:
            failures.append(
                "TRACE_HIT kind=%s target=%s class=%s hitActor=%s hitDist=%s awayDegenerate=%s"
                % (
                    hit.get("kind"),
                    hit.get("target"),
                    hit.get("classification"),
                    hit.get("hitActor"),
                    hit.get("hitDist"),
                    hit.get("awayDegenerate"),
                )
            )
    else:
        # Plain census: zero of a type is information, not failure.
        for kind in ("pickups", "containers", "stations"):
            count = (parsed or {}).get(kind)
            if count == 0:
                report.setdefault("censusNotes", []).append(
                    "%s count is 0 in the loaded slice — nothing of that type to interact with"
                    % kind
                )

    os.makedirs(out_dir, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("interact trace failed:\n- " + "\n- ".join(failures))
    _log(
        "PASS interact trace (pickups=%s containers=%s stations=%s)"
        % (
            (parsed or {}).get("pickups"),
            (parsed or {}).get("containers"),
            (parsed or {}).get("stations"),
        )
    )
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_RUNTIME_SCHEMA",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json",
        ),
        os.environ.get("BIOSHOCK_INTERACT_TRACE_OUT", OUT_DEFAULT),
    )
