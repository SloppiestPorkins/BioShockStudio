"""Verify imported AI archetype assets and spawn-time health against the level manifest."""

from __future__ import annotations

import json
import os
import subprocess
import sys

import unreal

import import_ai_archetypes


def _log(message):
    unreal.log("[bioshock-verify-ai-archetypes] %s" % message)


def _repo_root():
    here = os.path.abspath(os.path.dirname(__file__))
    return os.path.abspath(os.path.join(here, "..", ".."))


def _export_manifest_to_temp(package_bsm):
    out_dir = os.path.join(os.environ.get("TEMP", "."), "bioshock-ai-archetype-verify")
    os.makedirs(out_dir, exist_ok=True)
    cli = os.path.join(_repo_root(), "src", "BioShockStudio.Cli")
    cmd = [
        "dotnet",
        "run",
        "--project",
        cli,
        "--",
        "export-level",
        package_bsm,
        out_dir,
    ]
    subprocess.run(cmd, check=True, cwd=_repo_root())
    level_dir = os.path.join(out_dir, os.path.splitext(os.path.basename(package_bsm))[0])
    manifest = os.path.join(level_dir, os.path.basename(level_dir) + ".ue5-level.json")
    if not os.path.isfile(manifest):
        raise RuntimeError("export-level did not write %s" % manifest)
    return manifest


def _resolve_manifest(manifest_path):
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    if manifest.get("archetypes"):
        return manifest_path, manifest

    package_bsm = os.environ.get("BIOSHOCK_MEDICAL_BSM")
    if not package_bsm:
        package_bsm = (
            r"G:\SteamLibrary\steamapps\common\BioShock Remastered"
            r"\ContentBaked\pc\Maps\1-Medical.bsm"
        )
    if not os.path.isfile(package_bsm):
        raise RuntimeError(
            "manifest %s has no archetypes and BIOSHOCK_MEDICAL_BSM is missing"
            % manifest_path
        )
    fresh = _export_manifest_to_temp(package_bsm)
    with open(fresh, "r", encoding="utf-8") as handle:
        return fresh, json.load(handle)


def _asset_path(folder, name):
    return "%s/%s" % (folder, name)


def _load_archetype_asset(path):
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if asset is None:
        return None
    return asset


def _expected_health_for_mesh(manifest, mesh_name):
    matches = [
        archetype
        for archetype in (manifest.get("archetypes") or [])
        if archetype.get("mesh") == mesh_name and archetype.get("health") is not None
    ]
    if not matches:
        return None
    for archetype in matches:
        if str(archetype.get("name", "")).startswith("Medical"):
            return float(archetype["health"])
    return float(matches[0]["health"])


def main(out, manifest_path=None):
    report = {"failures": [], "error": None}
    failures = report["failures"]

    # The spawn-test below needs a real level open (NavMesh, ground collision) -- this script never
    # loaded one itself, relying on whatever the editor's default/last-open map happened to be.
    # Confirmed live 29 Sept 2026: on a fresh -run=pythonscript process (no prior script in the same
    # run left Medical open), the spawn silently failed on the project's empty default map.
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level("/Game/BioShockSlice/1-Medical")

    manifest_path = manifest_path or os.environ.get(
        "BIOSHOCK_LEVEL_JSON",
        r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
    )
    try:
        manifest_path, manifest = _resolve_manifest(manifest_path)
    except Exception as exc:
        failures.append("manifest: %s" % exc)
        _write_report(out, report)
        raise RuntimeError("verify-ai-archetypes:\n- " + "\n- ".join(failures))

    report["manifest"] = manifest_path
    report["archetypesInManifest"] = len(manifest.get("archetypes") or [])

    imported = import_ai_archetypes.import_ai_archetypes(manifest_path)
    report["import"] = imported
    folder = imported.get("folder") or import_ai_archetypes._package_folder(manifest)

    for archetype in manifest.get("archetypes") or []:
        name = archetype.get("name")
        if not name:
            continue
        path = _asset_path(folder, name)
        if not unreal.EditorAssetLibrary.does_asset_exist(path):
            failures.append("missing asset %s" % path)
            continue
        asset = _load_archetype_asset(path)
        if asset is None:
            failures.append("load failed %s" % path)
            continue

        if str(asset.get_editor_property("mesh_path")) != (archetype.get("mesh") or ""):
            failures.append("%s mesh_path" % name)
        manifest_health = archetype.get("health")
        if manifest_health is not None:
            if not bool(asset.get_editor_property("has_health")):
                failures.append("%s missing has_health" % name)
            elif abs(float(asset.get_editor_property("health")) - float(manifest_health)) > 0.01:
                failures.append("%s health %.2f != %.2f" % (
                    name,
                    float(asset.get_editor_property("health")),
                    float(manifest_health),
                ))

    expected_health = _expected_health_for_mesh(manifest, "Agg_BabyJane")
    report["expectedBabyJaneHealth"] = expected_health
    if expected_health is None:
        failures.append("no authored health for mesh Agg_BabyJane in manifest")

    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")
    spawn_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnAI")
    if not ai_cls or not spawn_cls:
        failures.append("runtime classes missing")
    else:
        spawn = unreal.new_object(spawn_cls)
        spawn.configure("Agg_BabyJane", "SpawnMarker", "VerifyBabyJane", 0.0, 0.0, True)
        world = unreal.EditorLevelLibrary.get_editor_world()
        spawned = spawn.spawn_at_location(world, unreal.Vector(500.0, 0.0, 100.0))
        if not spawned:
            failures.append("spawn Agg_BabyJane failed")
        else:
            health = float(spawned.get_current_health())
            report["spawnedHealth"] = health
            if expected_health is not None and abs(health - expected_health) > 0.01:
                failures.append("spawn health %.2f != %.2f" % (health, expected_health))

    _write_report(out, report)
    if failures:
        raise RuntimeError("verify-ai-archetypes:\n- " + "\n- ".join(failures))
    _log("PASS verify ai archetypes")
    return report


def _write_report(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "ai_archetypes_report.json"),
        )
    )
