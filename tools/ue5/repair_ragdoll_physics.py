"""Generate physics assets for Medical combat/corpse rigs and reactivate placed corpses.

UE5.7 exposes skeletal auto-generation through SkeletalMeshEditorSubsystem in commandlets; unlike
StaticMesh Auto Convex, generated PhysicsAsset bodies and constraints persist after reload.

Env:
  BIOSHOCK_RAGDOLL_MAP       map (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_RAGDOLL_MANIFEST  level manifest (defaults to the slice export)
  BIOSHOCK_RAGDOLL_COMBAT    comma-separated imported combat rig names
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_bioshock

MAP = os.environ.get("BIOSHOCK_RAGDOLL_MAP", "/Game/BioShockSlice/1-Medical")
MANIFEST = os.environ.get("BIOSHOCK_RAGDOLL_MANIFEST", "")
COMBAT = [name.strip() for name in os.environ.get(
    "BIOSHOCK_RAGDOLL_COMBAT", "AggressorBabyJane").split(",") if name.strip()]
IMPORT_RIG = os.environ.get("BIOSHOCK_RAGDOLL_IMPORT_RIG", "").strip()
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_ragdoll_physics.json")
KEY_PREFIX = "BioShockKey=instance:"


def _physics_asset(mesh):
    existing = mesh.get_editor_property("physics_asset")
    if existing is not None:
        return existing, False
    subsystem = unreal.get_editor_subsystem(unreal.SkeletalMeshEditorSubsystem)
    generated = subsystem.create_physics_asset(mesh, True, 0)
    if generated is None:
        return None, False
    unreal.EditorAssetLibrary.save_loaded_asset(generated)
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)
    return generated, True


def _body_count(asset):
    if asset is None:
        return 0
    try:
        return len(asset.get_editor_property("skeletal_body_setups") or [])
    except Exception:  # noqa: BLE001
        return -1


def _load_mesh(name):
    folder = "AggressorBabyJane" if name in ("AggressorBabyJane", "Agg_BabyJane") else name
    path = "/Game/BioShockCharacters/%s/AggressorBabyJane" % folder
    mesh = unreal.EditorAssetLibrary.load_asset(path)
    return mesh if isinstance(mesh, unreal.SkeletalMesh) else None, path


def _source_keys(actor):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith(KEY_PREFIX):
            parts = text[len(KEY_PREFIX):].split(":", 1)
            return parts[0], parts[1] if len(parts) > 1 else None
    return None, None


def main():
    manifest_path = MANIFEST or os.path.join(
        os.path.dirname(unreal.Paths.get_project_file_path()),
        "Exports", "slice", "1-Medical", "1-Medical.ue5-level.json")
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    if IMPORT_RIG:
        rig_dir = os.path.join(os.path.dirname(manifest_path), "Rigs", IMPORT_RIG)
        imported = import_bioshock.main(
            rig_dir,
            content_root="/Game/BioShockCharacters",
            rig_name_override=None if IMPORT_RIG == "Agg_BabyJane" else IMPORT_RIG,
            import_animations=False)
        mesh = next((value for value in imported.values()
                     if isinstance(value, unreal.SkeletalMesh)), None)
        asset, created = _physics_asset(mesh) if mesh else (None, False)
        report = {
            "importRig": IMPORT_RIG,
            "mesh": mesh.get_path_name() if mesh else None,
            "physicsAsset": asset.get_path_name() if asset else None,
            "created": created,
            "bodies": _body_count(asset),
        }
        with open(OUT, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)
        if mesh is None or asset is None:
            raise RuntimeError("failed to import/generate %s" % IMPORT_RIG)
        return report

    actors = {entry["key"]: entry for entry in manifest.get("actors") or []}
    corpse_classes = {
        key for key, entry in actors.items()
        if (entry.get("className") or "").endswith(
            ("DeadBodyContainer", "KeyframedDeadBodyContainer"))
    }
    corpse_names = {
        entry.get("skeletalMesh") for entry in actors.values()
        if entry.get("key") in corpse_classes and entry.get("skeletalMesh")
    }
    assets = {entry["key"]: entry for entry in manifest.get("assets") or []}
    for instance in manifest.get("instances") or []:
        if instance.get("actorKey") in corpse_classes:
            name = (assets.get(instance.get("asset")) or {}).get("name")
            if name:
                corpse_names.add(name)

    report = {
        "map": MAP, "manifest": manifest_path, "rigs": [], "corpsesConfigured": [],
        "unresolvedManifestRigNames": [], "failures": [],
    }
    target_meshes = {}
    target_by_manifest_name = {}
    for name in COMBAT:
        mesh, path = _load_mesh(name)
        if mesh is None:
            report["failures"].append("missing skeletal mesh %s" % path)
            continue
        target_meshes[mesh.get_path_name()] = (name, mesh)

    for name in sorted(corpse_names):
        mesh, _ = _load_mesh(name)
        if name == "Agg_BabyJane" and mesh is None:
            mesh, _ = _load_mesh("AggressorBabyJane")
        if mesh is not None:
            target_by_manifest_name[name] = mesh
            target_meshes[mesh.get_path_name()] = (name, mesh)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    corpse_actors = []
    if not level.load_level(MAP):
        report["failures"].append("could not load %s" % MAP)
    else:
        for actor in unreal.get_editor_subsystem(
                unreal.EditorActorSubsystem).get_all_level_actors():
            source, asset_key = _source_keys(actor)
            if source not in corpse_classes:
                continue
            asset_name = (assets.get(asset_key) or {}).get("name")
            desired_mesh = target_by_manifest_name.get(asset_name)
            if not isinstance(actor, unreal.SkeletalMeshActor):
                if desired_mesh is None:
                    report["failures"].append(
                        "%s is not skeletal and %s has no imported rig"
                        % (actor.get_actor_label(), asset_name))
                    continue
                old_actor = actor
                actor = unreal.get_editor_subsystem(
                    unreal.EditorActorSubsystem).spawn_actor_from_class(
                        unreal.SkeletalMeshActor,
                        old_actor.get_actor_location(),
                        old_actor.get_actor_rotation())
                actor.set_actor_scale3d(old_actor.get_actor_scale3d())
                actor.set_actor_label(old_actor.get_actor_label())
                actor.tags = list(old_actor.tags)
                unreal.get_editor_subsystem(
                    unreal.EditorActorSubsystem).destroy_actor(old_actor)
            mesh = desired_mesh or actor.skeletal_mesh_component.get_skeletal_mesh_asset()
            if mesh is None:
                report["failures"].append("%s has no skeletal mesh" % actor.get_actor_label())
                continue
            actor.skeletal_mesh_component.set_skeletal_mesh_asset(mesh)
            corpse_actors.append(actor)
            manifest_name = asset_name or actors[source].get("skeletalMesh") or mesh.get_name()
            target_meshes[mesh.get_path_name()] = (manifest_name, mesh)

    resolved_names = set(target_by_manifest_name)
    report["unresolvedManifestRigNames"] = sorted(corpse_names - resolved_names)

    for _, (name, mesh) in sorted(target_meshes.items()):
        path = mesh.get_path_name()
        asset, created = _physics_asset(mesh)
        bodies = _body_count(asset)
        report["rigs"].append({
            "name": name, "mesh": path, "physicsAsset": asset.get_path_name() if asset else None,
            "created": created, "bodies": bodies,
        })
        if asset is None or bodies == 0:
            report["failures"].append("%s physics generation produced no bodies" % name)

    if corpse_actors:
        for actor in corpse_actors:
            comp = actor.skeletal_mesh_component
            mesh = comp.get_skeletal_mesh_asset()
            asset, _ = _physics_asset(mesh) if mesh else (None, False)
            if asset is None:
                report["failures"].append("%s has no physics asset" % actor.get_actor_label())
                continue
            comp.set_physics_asset(asset, True)
            comp.set_collision_profile_name("Ragdoll")
            comp.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
            comp.set_simulate_physics(True)
            comp.set_enable_gravity(True)
            sleep = getattr(comp, "put_all_rigid_bodies_to_sleep", None)
            if sleep is not None:
                sleep()
            report["corpsesConfigured"].append(actor.get_actor_label())
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if report["failures"]:
        raise RuntimeError("ragdoll physics:\n- " + "\n- ".join(report["failures"]))
    unreal.log("[ragdoll-physics] wrote %s" % OUT)
    return report


if __name__ == "__main__":
    main()
