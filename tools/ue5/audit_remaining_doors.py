"""Census Medical door-field actors vs live AShockDoor placement after import.

Run after `import_slice_doors` (or alone — it does not mutate the map). Writes a JSON
report classifying every manifest `door` actor: placed / missing, placement transform
source, attachment leaf count, and whether a skeletal proxy mesh resolved.

The 30 Sept 2026 "31 other doors still skipped" note was wrong — this script is the
measured replacement. Medical has 44 door-field actors; only 4 were whole-door skips
(no matrix transform, now fixed via location/rotation fallback). Residual gaps are
attachment-leaf misses and the known `LowRentDoor_Mesh` decode failure.
"""

from __future__ import annotations

import json
import os
import sys
from collections import defaultdict

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_level  # noqa: E402

DEFAULT_MANIFEST = (
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json"
)
SLICE_MAP = "/Game/BioShockSlice/1-Medical"
# Permanent cut line — see docs/QUALITY.md / ROADMAP Havok/door mesh note.
KNOWN_UNDECODED_DOOR_MESHES = {
    "LowRentDoor_Mesh",
    "Sliding512SingleDoorMesh",
    "Atlas_labs_doorAnim",
    "GathererDoorAnimMesh",
}


def _log(message):
    unreal.log("[bioshock-audit-doors] %s" % message)


def main(manifest_path=None, map_path=SLICE_MAP):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    existing = import_level._existing_by_key()
    instances = import_level._instances_by_actor_key(manifest)

    # Same proxy path import_slice_doors uses.
    proxies = {}
    for asset in manifest.get("assets") or []:
        if asset.get("kind") != "SkeletalMesh":
            continue
        rig_name = asset.get("group") or asset.get("name")
        path = "/Game/BioShockCharacters/%s/%s" % (rig_name, rig_name)
        mesh = (
            unreal.EditorAssetLibrary.load_asset(path)
            if unreal.EditorAssetLibrary.does_asset_exist(path) else None)
        if isinstance(mesh, unreal.SkeletalMesh):
            proxies[asset["key"]] = mesh

    leaf_names = {
        asset["name"]
        for asset in (manifest.get("assets") or [])
        if asset.get("name")
    }
    # Presence in the slice Content folder (what by_name can resolve).
    meshes_on_disk = {}
    for asset in manifest.get("assets") or []:
        rel = asset.get("file")
        if not rel:
            continue
        stem = os.path.splitext(os.path.basename(rel))[0]
        path = "/Game/BioShockSlice/Content/Meshes/" + stem
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            meshes_on_disk[asset.get("name")] = path

    rows = []
    tallies = defaultdict(int)
    for entry in manifest.get("actors") or []:
        door_data = entry.get("door")
        if not door_data:
            continue
        label = entry.get("label") or entry.get("name") or entry["key"]
        dkey = "door:" + entry["key"]
        actor = existing.get(dkey)
        actor_instances = instances.get(entry["key"]) or []
        transform = (
            actor_instances[0].get("transform") if actor_instances
            else entry.get("transform"))
        if transform is not None:
            place_source = "matrix"
        elif entry.get("location") is not None:
            place_source = "location_rotation"
        else:
            place_source = "none"

        attachments = door_data.get("attachments") or []
        missing_leaves = []
        for att in attachments:
            static_mesh = att.get("staticMesh")
            object_name = (
                static_mesh.get("objectName") if isinstance(static_mesh, dict) else None)
            if object_name not in meshes_on_disk:
                missing_leaves.append(object_name)

        skel = entry.get("skeletalMeshReference") or {}
        skel_name = skel.get("objectName")
        proxy_key = skel.get("sourceKey")
        proxy_loaded = proxy_key in proxies
        undecoded = skel_name in KNOWN_UNDECODED_DOOR_MESHES

        placed = actor is not None
        tallies["door_actors"] += 1
        tallies["placed" if placed else "missing"] += 1
        tallies["place_" + place_source] += 1
        if undecoded:
            tallies["undecoded_proxy"] += 1
        if proxy_loaded:
            tallies["proxy_loaded"] += 1
        if missing_leaves:
            tallies["doors_with_missing_leaves"] += 1
            tallies["missing_leaf_events"] += len(missing_leaves)
        if not attachments:
            tallies["no_attachments"] += 1

        rows.append({
            "label": label,
            "className": entry.get("className"),
            "key": entry["key"],
            "placed": placed,
            "placeSource": place_source,
            "locked": bool(door_data.get("locked") or False),
            "attachmentCount": len(attachments),
            "missingLeaves": missing_leaves,
            "skeletalMesh": skel_name,
            "proxyLoaded": proxy_loaded,
            "undecodedProxy": undecoded,
            "actorClass": (
                str(actor.get_class().get_name()) if actor is not None else None),
        })

    report = {
        "manifest": manifest_path,
        "map": map_path,
        "tallies": dict(tallies),
        "doors": rows,
        "knownUndecodedDoorMeshes": sorted(KNOWN_UNDECODED_DOOR_MESHES),
    }
    _log(
        "door_actors=%s placed=%s missing=%s place_matrix=%s place_locrot=%s "
        "undecoded_proxy=%s proxy_loaded=%s missing_leaf_events=%s"
        % (
            tallies["door_actors"],
            tallies["placed"],
            tallies["missing"],
            tallies["place_matrix"],
            tallies["place_location_rotation"],
            tallies["undecoded_proxy"],
            tallies["proxy_loaded"],
            tallies["missing_leaf_events"],
        )
    )
    return report


if __name__ == "__main__":
    out = os.environ.get(
        "BIOSHOCK_ACTION_OUT",
        os.path.join(os.environ.get("TEMP", "."), "audit_remaining_doors.json"),
    )
    result = main()
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
