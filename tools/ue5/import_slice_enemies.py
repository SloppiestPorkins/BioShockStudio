"""Import Medical's authored AggressorSpawner and TurretSpawner records.

The source actors remain runtime spawners. Initial/global AI entries populate after BeginPlay;
repopulation entries activate on player proximity or the imported spawn-zone script actions.
"""

from __future__ import annotations

import json
import os
import struct

import unreal

import import_level
import import_slice_doors

DEFAULT_MANIFEST = (
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical"
    r"\1-Medical.ue5-level.json"
)
SLICE_MAP = "/Game/BioShockSlice/1-Medical"
PROXIMITY_RADIUS = 1200.0

# CONFIRMED_BYTES for 1-Medical. These manifest strings are accidental FName decodes of compact
# object references. The object references resolve one export index earlier in the CLI:
# Creator/01 44 03 -> export 195 SpawnedMeleeThug;
# MaxLightsDynamic/01 4D 03 -> export 204 SpawnedRangedAggressorPistol;
# Context/01 55 03 -> export 212 SpawnedGrenadier.
_MEDICAL_AI_TYPE_DECODE = {
    "Creator": "SpawnedMeleeThug",
    "MaxLightsDynamic": "SpawnedRangedAggressorPistol",
    "Context": "SpawnedGrenadier",
}
_MEDICAL_TURRET_LABELS = {
    8335: "SteinmanTurretTrap",
    9934: "StunTurret",
    11538: "TurretToBeHacked",
}


def _log(message):
    unreal.log("[bioshock-slice-enemies] %s" % message)


def _names(values):
    return [unreal.Name(str(value)) for value in values if value]


def _property_present(entry, name):
    return any(prop.get("name") == name for prop in (entry.get("properties") or []))


def _float_property(entry, name, default):
    prop = next(
        (value for value in (entry.get("properties") or [])
         if value.get("name") == name),
        None,
    )
    try:
        return struct.unpack("<f", bytes.fromhex(prop["valueHex"]))[0]
    except (KeyError, TypeError, ValueError, struct.error):
        return default


def _archetypes_by_ai_type(manifest):
    result = {}
    for archetype in manifest.get("archetypes") or []:
        name = archetype.get("name")
        ai_type = archetype.get("aiType")
        if name and ai_type:
            result.setdefault(ai_type, []).append(name)
    return result


def _phase_archetypes(spawner, fields, archetypes_by_type):
    source_types = []
    for field in fields:
        source_types.extend(spawner.get(field) or [])

    overrides = spawner.get("overriddenAiArchetypeNames") or []
    if overrides:
        count = max(1, len(source_types))
        return [overrides[index % len(overrides)] for index in range(count)]

    resolved = []
    for encoded_name in source_types:
        ai_type = _MEDICAL_AI_TYPE_DECODE.get(encoded_name)
        candidates = archetypes_by_type.get(ai_type) or []
        if not candidates:
            raise RuntimeError(
                "spawner AI type %r (%r) resolves to no manifest archetype"
                % (encoded_name, ai_type)
            )
        # The native weighted selection is unavailable. Preserve the authored class and source
        # count, choosing the first same-class archetype in manifest order.
        resolved.append(candidates[0])
    return resolved


def _replace_with_class(entry, actor_class, existing):
    key = entry["key"]
    actor = existing.get(key)
    if actor is not None:
        current_class = actor.get_class()
        if current_class != actor_class and not unreal.MathLibrary.class_is_child_of(
                current_class, actor_class):
            import_level._actor_subsystem().destroy_actor(actor)
            actor = None

    location = unreal.Vector(*(entry.get("location") or [0.0, 0.0, 0.0]))
    rotation = import_level._rotation(entry.get("rotation") or [0, 0, 0])
    created = actor is None
    if actor is None:
        actor = import_level._actor_subsystem().spawn_actor_from_class(
            actor_class, location, rotation)
        if actor is None:
            raise RuntimeError("could not spawn runtime spawner for %s" % key)
    else:
        actor.set_actor_location(location, False, False)
        actor.set_actor_rotation(rotation, False)

    label = entry.get("label") or entry.get("name") or key
    actor.set_actor_label(str(label))
    actor.tags = [
        unreal.Name(import_level.KEY_TAG_PREFIX + key),
        unreal.Name("BioShockClass=" + entry["className"]),
    ]
    existing[key] = actor
    return actor, created


def _import_aggressors(manifest, existing, report):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockAggressorSpawner")
    if cls is None:
        raise RuntimeError("ShockAggressorSpawner missing - rebuild BioShockRuntime")
    by_type = _archetypes_by_ai_type(manifest)

    for entry in manifest.get("actors") or []:
        if entry.get("className") != "AggressorSpawner":
            continue
        spawner = entry.get("spawner") or {}
        initial = _phase_archetypes(
            spawner, ("globalAiTypes", "initialAiTypes"), by_type)
        repopulation = _phase_archetypes(
            spawner, ("repopulationAiTypes",), by_type)
        if not initial and not repopulation:
            raise RuntimeError("%s has no resolvable AI entries" % entry["key"])

        actor, created = _replace_with_class(entry, cls, existing)
        actor.configure(
            unreal.Name(entry["key"]),
            unreal.Name(entry.get("label") or entry.get("name") or entry["key"]),
            _names(initial),
            _names(repopulation),
            _names(spawner.get("spawnZones") or []),
            unreal.Name(spawner.get("initialPatrol") or spawner.get("globalPatrol") or ""),
            unreal.Name(spawner.get("repopulationPatrol") or ""),
            PROXIMITY_RADIUS,
        )
        report["created" if created else "updated"] += 1
        report["aggressorSpawners"] += 1
        report["initialSlots"] += len(initial)
        report["repopulationSlots"] += len(repopulation)
        report["resolvedArchetypes"] += len(initial) + len(repopulation)


def _import_turrets(manifest, existing, report):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockTurretSpawner")
    if cls is None:
        raise RuntimeError("ShockTurretSpawner missing - rebuild BioShockRuntime")

    for entry in manifest.get("actors") or []:
        if entry.get("className") != "TurretSpawner":
            continue

        # Remove the previous import_level path's eager live turret. The runtime marker below owns
        # both immediate and script-driven spawning now.
        old_key = "turret:" + entry["key"]
        old_turret = existing.pop(old_key, None)
        if old_turret is not None:
            import_level._actor_subsystem().destroy_actor(old_turret)
            report["legacyTurretsRemoved"] += 1

        actor, created = _replace_with_class(entry, cls, existing)
        label = entry.get("label") or entry.get("name") or entry["key"]
        spawned_label = _MEDICAL_TURRET_LABELS.get(entry.get("exportIndex"), label)
        turret_type = (
            "SpawnedDeck1MaximumSecurityTurret"
            if entry.get("skeletalMesh") == "TurretGrenadeLauncher"
            else "SpawnedDeck1MinimumSecurityTurret"
        )
        actor.configure(
            unreal.Name(entry["key"]),
            unreal.Name(label),
            unreal.Name(spawned_label),
            unreal.Name(turret_type),
            _names((entry.get("spawner") or {}).get("spawnZones") or []),
            _property_present(entry, "ForScriptedSpawn"),
            True,
            _float_property(entry, "SightDistance", 1000.0),
        )
        report["created" if created else "updated"] += 1
        report["turretSpawners"] += 1
        if _property_present(entry, "ForScriptedSpawn"):
            report["scriptedTurretSpawners"] += 1


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get(
        "BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    if not os.path.isfile(manifest_path):
        raise RuntimeError("missing manifest %s" % manifest_path)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    import_slice_doors._open_slice_map(map_path)
    existing = import_level._existing_by_key()
    report = {
        "manifest": manifest_path,
        "map": map_path,
        "created": 0,
        "updated": 0,
        "aggressorSpawners": 0,
        "turretSpawners": 0,
        "scriptedTurretSpawners": 0,
        "legacyTurretsRemoved": 0,
        "initialSlots": 0,
        "repopulationSlots": 0,
        "resolvedArchetypes": 0,
    }
    _import_aggressors(manifest, existing, report)
    _import_turrets(manifest, existing, report)

    if save and not unreal.get_editor_subsystem(
            unreal.LevelEditorSubsystem).save_current_level():
        raise RuntimeError("could not save %s" % map_path)
    _log(
        "aggressors=%d turrets=%d archetypes=%d"
        % (
            report["aggressorSpawners"],
            report["turretSpawners"],
            report["resolvedArchetypes"],
        )
    )
    return report


if __name__ == "__main__":
    out = os.environ.get(
        "BIOSHOCK_ENEMIES_OUT",
        os.path.join(os.environ.get("TEMP", "."), "slice_enemies_import.json"),
    )
    result = main()
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
