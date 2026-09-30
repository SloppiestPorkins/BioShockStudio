"""Place the 1-Medical vendors / health stations / Gatherer's Garden into the playable slice.

The station UIs (U5) and `AShockStationBase` already exist; `bEnableSliceStations` only spawns a
debug row next to the player. This places the real manifest records at their world positions so
you find a Circus of Values, a wall Health Station, and the Gatherer's Garden where BioShock put
them. Interact (F) opens the matching menu (or, for a Health Station, heals for a few dollars).

Idempotent (`BioShockKey=`), wired into `setup_playable_slice`. ResurrectionStation is handled
by import_level (`AShockVitaChamber`, w16), not here.

Duplicate-collider note (30 Sept 2026 audit, `task_977a74fe`): 7 of Medical's 10 Placeable*
stations also have an `instances[]` entry, and `_should_place_mesh_instance` does not denylist
them — so `_import_instances` leaves a generic `StaticMeshActor` under each. This script reuses
`import_slice_pickups._place`, which calls `import_level.destroy_instance_duplicates` (landed for
pickups in b0466aa), so re-running this import removes those duplicates. Stations are on the
player interact Visibility trace (`TickInteractionTrace` → `AShockStationBase`); a leftover
duplicate steals the prompt even though `HandleInteractInput` has a distance-based
`TryInteractNearbyStation` fallback.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import clear_interactable_placement as clear_place  # noqa: E402
import import_level  # noqa: E402
import import_slice_pickups as pk  # noqa: E402  (reuse _place / _load_mesh; destroys instance: duplicates)

SLICE_MAP = "/Game/BioShockSlice/1-Medical"
DEFAULT_MANIFEST = pk.DEFAULT_MANIFEST
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_stations.json")

def _kinds():
    K = unreal.ShockStationKind
    return {
        "PlaceableHealthStation": K.HEALTH_STATION,
        "PlaceableVendingStation": K.VENDING,
        "PlaceableGrowthStation": K.GATHERER_GARDEN,
    }


S_VENDING = None  # set at runtime for the vending-defaults check


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    station_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockStationBase")
    if station_cls is None:
        raise RuntimeError("AShockStationBase missing — build the plugin first")

    existing = import_level._existing_by_key()
    kinds = _kinds()
    vending = unreal.ShockStationKind.VENDING
    report = {"manifest": manifest_path, "stations": 0, "byClass": {}}

    for entry in manifest.get("actors") or []:
        cn = entry.get("className")
        if cn not in kinds:
            continue
        kind = kinds[cn]
        actor, _created = pk._place(station_cls, entry, existing)
        if actor is None:
            continue
        actor.set_editor_property("station_kind", kind)
        actor.set_editor_property(
            "station_label",
            unreal.Name(str(entry.get("label") or entry.get("name") or entry["key"])))
        actor.set_editor_property("interact_radius", 220.0)
        if kind == vending:
            actor.configure_vending_defaults(False)
        mesh = pk._load_mesh(entry.get("staticMesh"))
        comp = actor.get_editor_property("mesh")
        if mesh and comp:
            comp.set_static_mesh(mesh)
        report["stations"] += 1
        report["byClass"][cn] = report["byClass"].get(cn, 0) + 1

    # Same flush-overlap clearance as pickups/containers (w21). Re-scans all interactables so a
    # station that landed flush against decoration is nudged before the level save.
    clearance = clear_place.clear_overlaps(map_path=map_path, save=False, reload_map=False)
    report["placementClearance"] = {
        "nudged": len(clearance.get("nudged") or []),
        "skippedDeep": len(clearance.get("skippedDeep") or []),
        "checked": clearance.get("checked"),
    }

    if save:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[slice-stations] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
