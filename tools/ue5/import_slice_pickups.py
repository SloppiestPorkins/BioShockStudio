"""Place the 1-Medical pickup + lootable-container economy into the playable slice.

The level manifest positions ~230 `*Pickup` / `*Container` / `*Booty` actors and NONE of them
are in the slice — you cannot grab a health kit, loot a corpse, or pick up ammo. This mirrors
`import_slice_doors.py`: read the manifest, spawn an `AShockConsumablePickup` /
`AShockSearchableContainer` per record with the manifest mesh + transform, configured by a
className map. Idempotent (keyed by `BioShockKey=`), wired into `setup_playable_slice`.

BioShock auto-collects ammo / health / EVE / money / ADAM on touch; weapons, plasmids, audio
diaries and keys are a keypress (`Interact` / F). Container loot amounts are a small money roll
where the manifest record carries no authored loot — flagged as an approximation.

Env: BIOSHOCK_LEVEL_JSON overrides the manifest path.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import clear_interactable_placement as clear_place  # noqa: E402
import import_level  # noqa: E402

SLICE_MAP = "/Game/BioShockSlice/1-Medical"
DEFAULT_MANIFEST = r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/1-Medical.ue5-level.json"
MESH_DIRS = [
    "/Game/BioShockSlice/Content/Meshes",
    "/Game/BioShockLevel/Content/Meshes",
]
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_pickups.json")

# EShockPickupKind
K_FIRST_AID, K_EVE, K_MONEY, K_AMMO, K_ADAM, K_ITEM, K_WEAPON, K_PLASMID, K_DIARY = range(9)

# className -> dict(kind, amount, weapon, item, plasmid, interact)
_AUTO = dict(interact=False)
_KEY = dict(interact=True)


def _p(kind, amount=1, weapon="", item="", plasmid="", interact=False):
    return {"kind": kind, "amount": amount, "weapon": weapon, "item": item,
            "plasmid": plasmid, "interact": interact}


PICKUPS = {
    "BandagesPickup": _p(K_FIRST_AID, 1),
    "MedHypoPickup": _p(K_FIRST_AID, 1),
    "EVEHypoPickup": _p(K_EVE, 1),
    "AdamPickup": _p(K_ADAM, 10),
    "StandardBulletPickup": _p(K_AMMO, 18, weapon="Pistol"),
    "ArmorPiercingBulletPickup": _p(K_AMMO, 14, weapon="Pistol"),
    "StandardBuckshotPickup": _p(K_AMMO, 8, weapon="Shotgun"),
    "IonicBuckshotPickup": _p(K_AMMO, 6, weapon="Shotgun"),
    "MachineGunBulletPickup": _p(K_AMMO, 40, weapon="TommyGun"),
    "MachineGunFrozenBulletPickup": _p(K_AMMO, 30, weapon="TommyGun"),
    "AutoHackDevicePickup": _p(K_ITEM, 1, item="AutoHackTool"),
    "PowerBarPickup": _p(K_ITEM, 1, item="PowerBar"),
    "ChipsPickup": _p(K_ITEM, 1, item="Chips"),
    "TwinkiePickup": _p(K_ITEM, 1, item="Twinkie"),
    "BeerPickup": _p(K_ITEM, 1, item="Beer"),
    "WhiskyPickup": _p(K_ITEM, 1, item="Whisky"),
    "WinePickup": _p(K_ITEM, 1, item="Wine"),
    "GinPickup": _p(K_ITEM, 1, item="Gin"),
    "CoffeePickup": _p(K_ITEM, 1, item="Coffee"),
    "CheapCigarettesPickup": _p(K_ITEM, 1, item="CheapCigarettes"),
    "ExpensiveCigarettesPickup": _p(K_ITEM, 1, item="ExpensiveCigarettes"),
    # keypress
    "PistolPickup": _p(K_WEAPON, 24, weapon="Pistol", interact=True),
    "ShotgunPickup": _p(K_WEAPON, 12, weapon="Shotgun", interact=True),
    "WrenchPickup": _p(K_WEAPON, 0, weapon="Wrench", interact=True),
    "MachineGunAndStandardBulletPickup": _p(K_WEAPON, 60, weapon="TommyGun", interact=True),
    "ActivePlasmidPickup": _p(K_PLASMID, 1, plasmid="ElectroBolt", interact=True),
    "EngineeringPlasmidPickup": _p(K_PLASMID, 1, plasmid="SecurityBullseye", interact=True),
    "PhysicalPlasmidPickup": _p(K_PLASMID, 1, plasmid="Telekinesis", interact=True),
    "WeaponsPlasmidPickup": _p(K_PLASMID, 1, plasmid="Incinerate", interact=True),
    "LogPickup": _p(K_DIARY, 1, interact=True),
    "ChompersDentalKeyPickup": _p(K_ITEM, 1, item="ChompersDentalKey", interact=True),
}

# className -> (moneyMin, moneyMax, item)
CONTAINERS = {
    "DeadBodyContainer": (1, 30, ""),
    "KeyframedDeadBodyContainer": (1, 30, ""),
    "CorpseMaleBooty": (1, 24, ""),
    "AggBabyJaneBooty": (2, 26, ""),
    "AggDoctorBooty": (4, 34, ""),
    "AggToastyBooty": (2, 22, ""),
    "CashRegister": (5, 45, ""),
    "FlowerVaseContainer": (1, 12, ""),
    # 5 instances in Medical (3 WallSafe + 2 Safe) never matched the "Pickup"/"Container"/"Booty"
    # substring fallback below, so they fell all the way through to an invisible, non-searchable
    # TargetPoint -- a real safe the player could never open. PLAUSIBLE range: higher than
    # CashRegister since a safe is the better-hidden container in BioShock's own loot tiering.
    "SecurityCrate_WallSafe": (10, 60, ""),
    "SecurityCrate_Safe": (10, 60, ""),
}


# className -> mesh name, for records whose manifest staticMesh is empty (class-default meshes
# BioShock resolves at runtime that the level export didn't capture).
_MESH_FALLBACK = {
    "MedHypoPickup": "Med",
}


def _mesh_name(entry):
    return entry.get("staticMesh") or _MESH_FALLBACK.get(entry.get("className"))


def _load_mesh(name):
    """The real pickup mesh if it has been imported into slice content, else None.

    Returning None keeps the pickup invisible-but-functional rather than dropping a 1 m grey
    engine sphere over it — the meshes (bio_bandages, Ammo_Pickup_*, …) were never imported.
    `_place` gives a missing-mesh pickup a small marker so it can still be spotted.
    """
    if not name:
        return None
    for base in MESH_DIRS:
        asset = unreal.load_asset("%s/%s" % (base, name))
        if asset:
            return asset
    return None


_MARKER = None


def _marker_mesh():
    global _MARKER
    if _MARKER is None:
        _MARKER = unreal.load_asset("/Engine/BasicShapes/Sphere.Sphere")
    return _MARKER


def _place(actor_cls, entry, existing):
    key = entry["key"]
    # _import_instances places a real, visible geometry-instance mesh for most of these keys
    # regardless of class (no denylist for pickup/container classes) -- remove it so this
    # dedicated pickup/container actor's own collider doesn't overlap a second one at the same
    # transform. Confirmed live 30 Sept 2026 for the switches/reactive-props/damageable-props
    # fixes (see import_level.destroy_instance_duplicates' docstring): a duplicate collider means
    # a search/interact trace can resolve to the dead duplicate instead of this actor.
    import_level.destroy_instance_duplicates(existing, key)
    actor = existing.get(key)
    if actor is not None and actor.get_class() != actor_cls:
        import_level._actor_subsystem().destroy_actor(actor)
        actor = None
    loc = unreal.Vector(*(entry.get("location") or [0.0, 0.0, 0.0]))
    rot = import_level._rotation(entry.get("rotation") or [0, 0, 0])
    created = actor is None
    if actor is None:
        actor = import_level._actor_subsystem().spawn_actor_from_class(actor_cls, loc, rot)
        if actor is None:
            return None, False
    else:
        actor.set_actor_location(loc, False, False)
        actor.set_actor_rotation(rot, False)
    actor.set_actor_label(str(entry.get("label") or entry.get("name") or key))
    actor.tags = [
        unreal.Name(import_level.KEY_TAG_PREFIX + key),
        unreal.Name("BioShockClass=" + entry["className"]),
    ]
    existing[key] = actor
    return actor, created


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    pickup_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockConsumablePickup")
    container_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockSearchableContainer")
    if pickup_cls is None or container_cls is None:
        raise RuntimeError("runtime pickup/container classes missing — build the plugin first")

    existing = import_level._existing_by_key()
    report = {"manifest": manifest_path, "pickups": 0, "containers": 0,
              "byClass": {}, "unmapped": {}}

    for entry in manifest.get("actors") or []:
        cn = entry.get("className")
        if cn in PICKUPS:
            cfg = PICKUPS[cn]
            actor, _created = _place(pickup_cls, entry, existing)
            if actor is None:
                continue
            diary_id = ""
            if cfg["kind"] == K_DIARY:
                diary_id = str(entry.get("label") or entry.get("name") or entry["key"])
            actor.configure_pickup(
                cfg["kind"], cfg["amount"],
                unreal.Name(cfg["weapon"]) if cfg["weapon"] else unreal.Name(),
                unreal.Name(cfg["item"]) if cfg["item"] else unreal.Name(),
                unreal.Name(cfg["plasmid"]) if cfg["plasmid"] else unreal.Name(),
                unreal.Name(diary_id) if diary_id else unreal.Name(),
                cfg["interact"])
            actor.set_pickup_mesh(_load_mesh(_mesh_name(entry)))
            report["pickups"] += 1
            report["byClass"][cn] = report["byClass"].get(cn, 0) + 1
        elif cn in CONTAINERS:
            money_min, money_max, item = CONTAINERS[cn]
            actor, _created = _place(container_cls, entry, existing)
            if actor is None:
                continue
            actor.configure_container(
                unreal.Name(str(entry.get("label") or entry.get("name") or entry["key"])),
                money_min, money_max,
                unreal.Name(item) if item else unreal.Name(), 1)
            actor.set_container_mesh(_load_mesh(entry.get("staticMesh")))
            report["containers"] += 1
            report["byClass"][cn] = report["byClass"].get(cn, 0) + 1
        elif cn and ("Pickup" in cn or "Container" in cn or "Booty" in cn):
            report["unmapped"][cn] = report["unmapped"].get(cn, 0) + 1

    # Flush-overlap clearance against neighbouring StaticMeshActors (w21). Runs before save so
    # the nudged transforms land in the same level write. Stations are cleared from
    # import_slice_stations after they are placed.
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
    unreal.log("[slice-pickups] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
