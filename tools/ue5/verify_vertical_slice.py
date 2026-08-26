"""The Phase 0 vertical slice, asset half: one level + one weapon in one saved UE5 level.

`docs/UE5_FULL_PORT_PLAN.md` section 5 Phase 0 and section 8 item 4. Every UE5 verification run
before this one was a *live, unsaved* pass — the actors existed in an editor session and vanished
with it. Nothing had ever been round-tripped through a `.umap` on disk, so "the pipeline produces a
UE5 level" was still an inference from an import report rather than something anyone had loaded.

What this does, in one pass:

1. Creates a persistent level and imports the whole manifest into it (`import_level.main`) —
   geometry, materials, lights, reflection probes and character rigs, not one subsystem at a time.
2. Imports one weapon rig (`import_bioshock.main`) and places it in the same level, so the slice
   covers the first-person path as well as the world.
3. **Saves the level, switches away from it, and loads it back off disk**, then counts and checks
   the actors in the *reloaded* level. That is the only step here that could not already be done,
   and the only one whose failure would be invisible in an import report.

Every check that fails raises `RuntimeError`. Under `-run=pythonscript` a script can report
"executed successfully" having produced no output at all (`tools/ue5/README.md`, "Headless
gotchas"), so absence of a traceback is the evidence, and the caller writes the report either way.
"""

import json
import os

import unreal

import import_bioshock
import import_level

# The arch this project already uses as its handedness canary: four abutting panels measure ~2422
# units across when assembled and ~4295 when mirrored apart. Actor bounds are a looser proxy than
# the C# test's per-vertex measurement, so the threshold is deliberately generous.
ARCH_ASSET_PREFIX = "StaticMesh_window_512_corner_4up"
ARCH_ASSEMBLED_MAX_DIAGONAL = 3500.0

# A scratch level to switch to before loading the saved one back. Without leaving the level first,
# a "reload" would just hand back the in-memory actors this run spawned, which proves nothing.
SCRATCH_MAP = "/Game/BioShockSlice/_Scratch"


def _log(message):
    unreal.log("[bioshock-slice] %s" % message)


def _disable_interchange():
    """Interchange asserts under -unattended (CurrentApplication.IsValid(), via Slate).

    Each translator registers its own CVar; these four are the ones this pipeline touches. See
    `tools/ue5/README.md`, "Headless gotchas" — the OBJ one only began firing once the OBJ writer
    started emitting UV/group data.
    """
    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag)


def _tag_value(actor, prefix):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith(prefix):
            return text[len(prefix):]
    return None


def _level_subsystem():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _place_weapon(rig_directory, content_root, report):
    """Import one weapon rig and stand it in the level, tagged so the reload can find it.

    The rig path is `import_bioshock.main` unchanged — the same one the pistol and TommyGun slices
    already pass `verify_bioshock_import.py` on. What is new is only that the result is placed as an
    actor in a level that then gets saved.
    """
    imported = import_bioshock.main(rig_directory, content_root=content_root)
    if not imported:
        raise RuntimeError("weapon rig %s imported no skeletal mesh" % rig_directory)

    # Idempotent for the same reason import_level is: a second run into the saved level must update
    # its own actors, not stack another copy of the weapon beside them.
    existing = {}
    for actor in import_level._actor_subsystem().get_all_level_actors():
        name = _tag_value(actor, "BioShockSliceWeapon=")
        if name is not None:
            existing[name] = actor

    placed = []
    for offset, (name, mesh) in enumerate(sorted(imported.items())):
        actor = existing.get(name)
        if actor is None or not isinstance(actor, unreal.SkeletalMeshActor):
            actor = import_level._actor_subsystem().spawn_actor_from_class(
                unreal.SkeletalMeshActor, unreal.Vector(0.0, offset * 150.0, 0.0))
        if actor is None:
            raise RuntimeError("could not spawn a SkeletalMeshActor for weapon mesh %s" % name)
        actor.skeletal_mesh_component.set_skeletal_mesh_asset(mesh)
        actor.set_actor_label("BioShockSlice_%s" % name)
        actor.tags = [unreal.Name("BioShockSliceWeapon=" + name)]
        placed.append({"name": name, "asset": mesh.get_path_name()})

    report["weapon"] = {"directory": rig_directory, "meshes": placed}
    _log("weapon rig %s: %d mesh(es) placed" % (os.path.basename(rig_directory), len(placed)))


def _open_slice_level(map_path):
    """Open the level to import into: a fresh one, or the existing one so a re-run stays idempotent.

    `import_level` updates the actors it already owns rather than duplicating them, so re-running
    into the saved level is the intended second-run behaviour. Creating a new level over the top
    would throw that away and re-measure a first run every time.
    """
    level = _level_subsystem()
    if unreal.EditorAssetLibrary.does_asset_exist(map_path):
        if not level.load_level(map_path):
            raise RuntimeError("existing level %s did not load" % map_path)
        return
    if not level.new_level(map_path):
        raise RuntimeError("could not create level %s" % map_path)


def _reloaded_actors(map_path):
    """Leave the level, load the saved one back off disk, and return its actors.

    Loading without leaving first would return the same in-memory actors this run just spawned, so
    the scratch level in between is what forces a genuine package load — and leaving is itself
    checked, because a `new_level` that quietly failed would turn this whole function into a
    self-fulfilling one.
    """
    level = _level_subsystem()
    if not level.new_level(SCRATCH_MAP):
        raise RuntimeError("could not switch away to %s; the reload would prove nothing" % SCRATCH_MAP)

    stranded = [actor for actor in import_level._actor_subsystem().get_all_level_actors()
                if _tag_value(actor, import_level.KEY_TAG_PREFIX) is not None]
    if stranded:
        raise RuntimeError(
            "%d imported actor(s) still present after switching levels; the editor did not leave "
            "the slice level" % len(stranded))

    if not level.load_level(map_path):
        raise RuntimeError("saved level %s did not load back" % map_path)
    return import_level._actor_subsystem().get_all_level_actors()


def _arch_diagonal(actors_by_key, manifest):
    """The combined bounding diagonal of the ceiling arch's four panels, from the reloaded level."""
    corners = []
    found = 0
    for instance in manifest.get("instances") or []:
        if not instance.get("asset", "").startswith(ARCH_ASSET_PREFIX):
            continue
        actor = actors_by_key.get("instance:" + instance["actorKey"] + ":" + instance["asset"])
        if actor is None:
            continue
        found += 1
        origin, extent = actor.get_actor_bounds(False)
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    corners.append((origin.x + sx * extent.x,
                                    origin.y + sy * extent.y,
                                    origin.z + sz * extent.z))

    if not corners:
        return {"instances": found, "diagonal": None}

    xs = [c[0] for c in corners]
    ys = [c[1] for c in corners]
    zs = [c[2] for c in corners]
    diagonal = ((max(xs) - min(xs)) ** 2
                + (max(ys) - min(ys)) ** 2
                + (max(zs) - min(zs)) ** 2) ** 0.5
    return {"instances": found, "diagonal": diagonal}


def _census(actors):
    """Actors by concrete class, plus the ones this pipeline owns, from whatever level is open."""
    by_class = {}
    by_key = {}
    weapons = []
    for actor in actors:
        name = type(actor).__name__
        by_class[name] = by_class.get(name, 0) + 1
        key = _tag_value(actor, import_level.KEY_TAG_PREFIX)
        if key:
            by_key[key] = actor
        weapon = _tag_value(actor, "BioShockSliceWeapon=")
        if weapon:
            weapons.append(actor)
    return by_class, by_key, weapons


def _skeletal_sample(actors, limit=10):
    """Bone counts off a sample of skeletal actors — a mesh reference that survived the save but
    resolves to nothing would otherwise still count as a placed SkeletalMeshActor."""
    sample = []
    for actor in actors:
        if len(sample) >= limit:
            break
        if not isinstance(actor, unreal.SkeletalMeshActor):
            continue
        mesh = actor.skeletal_mesh_component.get_editor_property("skeletal_mesh_asset")
        if mesh is None:
            sample.append({"label": actor.get_actor_label(), "mesh": None, "bones": 0})
            continue
        skeleton = mesh.get_editor_property("skeleton")
        bones = len(skeleton.get_editor_property("bone_tree")) if skeleton is not None else 0
        sample.append({
            "label": actor.get_actor_label(),
            "mesh": mesh.get_path_name(),
            "bones": bones,
        })
    return sample


def main(manifest_path, report_path, weapon_directory=None, rig_names=None,
         map_root="/Game/BioShockSlice", content_root="/Game/BioShockSlice/Content",
         character_content_root="/Game/BioShockCharacters",
         weapon_content_root="/Game/BioShockWeapons"):
    """Build and check the slice. `rig_names` is Phase 0's "one enemy archetype": the mesh names to
    import character rigs for, or None for every rig the level places.

    Narrowing it is a cost decision, not a coverage claim — a rig's animations are re-normalized and
    re-imported on every run (`import_bioshock` has no skip-on-exists), one splicer variant carries
    457 of them, and `1-Medical` places 32 rigs. The names asked for are recorded in the report so a
    filtered run cannot later be read as a whole-level one.
    """
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    package = manifest.get("package") or "Level"
    map_path = "%s/%s" % (map_root, package)

    report = {
        "package": package,
        "map": map_path,
        "manifest": manifest_path,
        "expected": {
            "lightsWithRadius": len([light for light in (manifest.get("lights") or [])
                                     if light.get("radius") is not None
                                     and float(light["radius"]) > 0]),
            "lightsTotal": len(manifest.get("lights") or []),
            "cubemapProbes": len([a for a in (manifest.get("actors") or [])
                                  if a.get("className") == "CubemapProbe"]),
            "instances": len(manifest.get("instances") or []),
            "actors": len(manifest.get("actors") or []),
            "skeletalAssets": len([a for a in (manifest.get("assets") or [])
                                   if a.get("kind") == "SkeletalMesh"]),
        },
        # Stated whether it was narrowed or not, so the report says what the run covered rather
        # than leaving "all rigs" to be assumed from silence.
        "rigsRequested": sorted(rig_names) if rig_names else "all",
        "error": None,
    }

    _disable_interchange()

    level = _level_subsystem()
    _open_slice_level(map_path)

    # The weapon goes first because it is the cheap half. A stale weapon export (one predating
    # manifest texture intent, say) raises, and doing it after the level import means paying 24
    # minutes to reach the failure — which is exactly what happened the first time this ran.
    if weapon_directory:
        _place_weapon(weapon_directory, weapon_content_root, report)

    report["import"] = import_level.main(
        manifest_path, content_root=content_root,
        character_content_root=character_content_root, rig_names=rig_names)

    before_save, _, _ = _census(import_level._actor_subsystem().get_all_level_actors())
    report["beforeSave"] = before_save

    if not level.save_current_level():
        raise RuntimeError("save_current_level() reported failure for %s" % map_path)
    if not unreal.EditorAssetLibrary.does_asset_exist(map_path):
        raise RuntimeError("saved level asset %s does not exist" % map_path)

    by_class, by_key, weapon_actors = _census(_reloaded_actors(map_path))
    report["afterReload"] = by_class
    report["ownedActorsAfterReload"] = len(by_key)
    report["skeletalSample"] = _skeletal_sample(by_key.values())
    report["arch"] = _arch_diagonal(by_key, manifest)
    report["weaponActorsAfterReload"] = len(weapon_actors)

    failures = []

    # The save/reload round trip is the claim this script exists to test: a level that loses actors
    # on the way to disk is not a level, however clean the import report was.
    total_before = sum(before_save.values())
    total_after = sum(by_class.values())
    if total_after != total_before:
        failures.append("actor count changed across save/reload: %d before, %d after"
                        % (total_before, total_after))

    lights = by_class.get("PointLight", 0)
    if lights != report["expected"]["lightsWithRadius"]:
        failures.append("PointLight %d != %d lights with a usable radius"
                        % (lights, report["expected"]["lightsWithRadius"]))

    captures = by_class.get("SphereReflectionCapture", 0)
    if captures != report["expected"]["cubemapProbes"]:
        failures.append("SphereReflectionCapture %d != %d CubemapProbe actors"
                        % (captures, report["expected"]["cubemapProbes"]))

    if by_class.get("StaticMeshActor", 0) <= 0:
        failures.append("no StaticMeshActor survived the reload")

    # The weapon is a SkeletalMeshActor too, so counting the class alone would pass on a level
    # whose every character silently fell back to a bind-pose static mesh.
    level_skeletal = by_class.get("SkeletalMeshActor", 0) - report["weaponActorsAfterReload"]
    report["levelSkeletalActors"] = level_skeletal
    if level_skeletal <= 0:
        failures.append("no level character reloaded as a SkeletalMeshActor")

    empty_meshes = [entry for entry in report["skeletalSample"]
                    if entry["mesh"] is None or entry["bones"] <= 0]
    if empty_meshes:
        failures.append("%d sampled SkeletalMeshActor(s) reloaded with no mesh or no bones"
                        % len(empty_meshes))

    diagonal = report["arch"]["diagonal"]
    if diagonal is None:
        failures.append("the ceiling-arch handedness canary found none of its instances")
    elif diagonal > ARCH_ASSEMBLED_MAX_DIAGONAL:
        failures.append("ceiling arch diagonal %.1f > %.1f — placement is mirrored, not assembled"
                        % (diagonal, ARCH_ASSEMBLED_MAX_DIAGONAL))

    if weapon_directory and report["weaponActorsAfterReload"] <= 0:
        failures.append("the weapon rig did not survive the reload")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    if failures:
        raise RuntimeError("vertical slice failed:\n- " + "\n- ".join(failures))

    _log("slice saved and reloaded: %d owned actors in %s" % (len(by_key), map_path))
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SLICE_MANIFEST"], os.environ["BIOSHOCK_SLICE_OUT"],
         os.environ.get("BIOSHOCK_SLICE_WEAPON"))
