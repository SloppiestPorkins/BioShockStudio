"""Verify authored Medical enemy spawners and a live hostile on the Pavilion route."""

from __future__ import annotations

import json
import os
import re
import subprocess

import unreal

MAP_PATH = "/Game/BioShockSlice/1-Medical"
MANIFEST = (
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical"
    r"\1-Medical.ue5-level.json"
)
UE_CMD = r"G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
PROJECT = r"C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
GAME_URL = "%s?game=/Script/BioShockRuntime.ShockGameMode" % MAP_PATH
ROUTE_OK_RE = re.compile(
    r"BIOSHOCK_COLLISION_ROUTE_OK route=bathysphere_pavilion\b")
MOVEMENT_START_RE = re.compile(r"BIOSHOCK_MOVEMENT_START\b")
HOSTILE_RE = re.compile(
    r"BIOSHOCK_ENEMY_SPAWN source=(\S+) archetype=(\S+) trigger=proximity "
    r"alive=1 hostile=1 distance=([-\d.]+)")


def _is_class(actor, cls):
    actor_cls = actor.get_class()
    return actor_cls == cls or unreal.MathLibrary.class_is_child_of(actor_cls, cls)


def _source_key(actor):
    return str(actor.get_editor_property("source_key"))


def _check_placed(report, manifest_path):
    if not unreal.get_editor_subsystem(
            unreal.LevelEditorSubsystem).load_level(MAP_PATH):
        return ["could not load %s" % MAP_PATH]
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    expected_ai = {
        actor["key"] for actor in manifest.get("actors") or []
        if actor.get("className") == "AggressorSpawner"
    }
    expected_turrets = {
        actor["key"] for actor in manifest.get("actors") or []
        if actor.get("className") == "TurretSpawner"
    }
    manifest_archetypes = {
        item.get("name") for item in manifest.get("archetypes") or []
        if item.get("name")
    }

    ai_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockAggressorSpawner")
    turret_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockTurretSpawner")
    if ai_cls is None or turret_cls is None:
        return ["runtime spawner classes missing"]

    actors = unreal.get_editor_subsystem(
        unreal.EditorActorSubsystem).get_all_level_actors()
    ai_spawners = [actor for actor in actors if _is_class(actor, ai_cls)]
    turret_spawners = [actor for actor in actors if _is_class(actor, turret_cls)]
    actual_ai = {_source_key(actor) for actor in ai_spawners}
    actual_turrets = {_source_key(actor) for actor in turret_spawners}

    failures = []
    if actual_ai != expected_ai:
        failures.append(
            "aggressor source keys differ: missing=%s extra=%s"
            % (sorted(expected_ai - actual_ai), sorted(actual_ai - expected_ai)))
    if actual_turrets != expected_turrets:
        failures.append(
            "turret source keys differ: missing=%s extra=%s"
            % (
                sorted(expected_turrets - actual_turrets),
                sorted(actual_turrets - expected_turrets),
            ))

    unresolved = []
    for actor in ai_spawners:
        initial = [
            str(value) for value in
            (actor.get_editor_property("initial_archetypes") or [])
        ]
        repop = [
            str(value) for value in
            (actor.get_editor_property("repopulation_archetypes") or [])
        ]
        names = initial + repop
        if not names or any(name not in manifest_archetypes for name in names):
            unresolved.append(_source_key(actor))
    if unresolved:
        failures.append("spawners with unresolved archetypes: %s" % unresolved)

    not_hackable = [
        _source_key(actor) for actor in turret_spawners
        if not actor.get_editor_property("can_be_hacked")
    ]
    if not_hackable:
        failures.append("turret spawners not hackable: %s" % not_hackable)

    report.update({
        "expectedAggressorSpawners": len(expected_ai),
        "placedAggressorSpawners": len(ai_spawners),
        "expectedTurretSpawners": len(expected_turrets),
        "placedTurretSpawners": len(turret_spawners),
        "resolvedAggressorSpawners": len(ai_spawners) - len(unresolved),
        "hackableTurretSpawners": len(turret_spawners) - len(not_hackable),
    })
    return failures


def _check_game_route(report):
    log_path = os.path.join(
        os.environ.get("TEMP", "."), "enemies_bathysphere_pavilion.log")
    cmd = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifymovement",
        "-bioshockverifyenemies",
        "-bioshockmovementroute=bathysphere_pavilion",
        "-bioshockmovementstart=-18096,2480,7794",
        "-bioshockmovementtarget=-19120,2224,7808",
        "-bioshockmovementduration=8.0",
        "-bioshockmovementminz=-20.0",
        "-bioshockmovementdelay=0.5",
        "-unattended",
        "-nopause",
        "-nosplash",
        "-log",
        "-abslog=%s" % log_path,
    ]
    proc = subprocess.run(cmd, timeout=600)
    text = (
        open(log_path, encoding="utf-8", errors="replace").read()
        if os.path.isfile(log_path) else ""
    )
    matches = list(HOSTILE_RE.finditer(text))
    report["gameRoute"] = {
        "exitCode": proc.returncode,
        "log": log_path,
        "movementStarted": bool(MOVEMENT_START_RE.search(text)),
        "routeCompleted": bool(ROUTE_OK_RE.search(text)),
        "proximityHostiles": [
            {
                "source": match.group(1),
                "archetype": match.group(2),
                "distance": float(match.group(3)),
            }
            for match in matches
        ],
    }
    failures = []
    if not MOVEMENT_START_RE.search(text):
        failures.append("bathysphere_pavilion movement harness did not start")
    if not matches:
        failures.append("route encountered no live hostile proximity-spawned splicer")
    return failures


def main(out_path, manifest_path=MANIFEST):
    report = {"map": MAP_PATH, "manifest": manifest_path, "failures": []}
    report["failures"] += _check_placed(report, manifest_path)
    if not report["failures"]:
        report["failures"] += _check_game_route(report)

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"]:
        raise RuntimeError(
            "enemy verification failed:\n- " + "\n- ".join(report["failures"]))
    unreal.log(
        "BIOSHOCK_ENEMIES_OK aggressors=%d turrets=%d route_hostiles=%d"
        % (
            report["placedAggressorSpawners"],
            report["placedTurretSpawners"],
            len(report["gameRoute"]["proximityHostiles"]),
        )
    )
    return report
