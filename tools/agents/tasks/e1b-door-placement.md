---
worker: chatgpt
base: main
verify: python -m py_compile tools/ue5/import_level.py
lane: tools/ue5/import_level.py, docs/research/**
---
# Place the door geometry the manifest now carries in `door.attachments`

## Context

Commit `ea5f0cc` fixed the *exporter*: `<map>.ue5-level.json` now populates
`actors[].door.attachments` from the door class default. On 1-Medical, 31 of 44 door
actors carry two attachments each — `Med_DoorRight` or `Med_DoorSolidRight`, on sockets
`LeftDoor` and `rIGHTdOOR`, with zero location/rotation offsets. Before this, doors rendered
grey because the pipeline placed only `Med_DoorAnim`, a 26-vertex animation proxy whose one
material slot is `None` by design. See `docs/research/door-and-import-materials.md`.

`tools/ue5/import_level.py` currently contains **zero** references to `door` or `attachment`,
so the geometry is exported but never placed.

## What to do

Add a function `_import_door_attachments(manifest, meshes, existing, report, handled)` and call
it from `main()` immediately AFTER `_import_instances(...)` and before `_import_region_volumes`.

For each entry in `manifest["actors"]` that has a non-empty `entry["door"]["attachments"]`:

1. Resolve the door actor's world transform. Use `_instances_by_actor_key(manifest)` to find the
   instance list for `entry["key"]`; take the first instance's `transform` and run it through
   `_decompose(...)` for `(location, rotation, scale)`. If the actor has no instance, fall back to
   `entry["transform"]` if present, else skip it and bump `report["doorAttachmentsSkipped"]`.
2. Build a name→StaticMesh map once: for each `asset` in `manifest["assets"]`, if
   `asset["key"]` is in `meshes`, map `asset["name"] -> meshes[asset["key"]]`.
3. For each attachment `att`:
   - `mesh = byName.get(att["staticMesh"]["objectName"])` — `staticMesh` may be a dict or null;
     if it doesn't resolve, bump `report["doorAttachmentsSkipped"]` and continue.
   - Spawn a `unreal.StaticMeshActor` at the door `location` (+ `att["attachLocationOffset"]` if
     present and non-null — it is `{x,y,z}` or a 3-list) and `rotation` (+ `attachRotationOffset`
     similarly; treat missing as zero).
   - `actor.static_mesh_component.set_static_mesh(mesh)`;
     `set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)` (same as `_import_instances`).
   - `actor.set_actor_scale3d(scale)`.
   - Deterministic owned-actor key: `dkey = "door:" + entry["key"] + ":" + att["attachSocket"] + ":" + att["staticMesh"]["objectName"]`.
     Reuse `existing.get(dkey)` if it is already a `StaticMeshActor` (move it); else spawn, and on
     failure bump `report["skipped"]` and continue. Same create/update bookkeeping as
     `_import_instances`.
   - `actor.set_actor_label(...)`, `actor.tags = [unreal.Name(KEY_TAG_PREFIX + dkey)]`,
     `existing[dkey] = actor`, `handled.add(dkey)`.
   - `report["doorAttachmentsPlaced"] = report.get("doorAttachmentsPlaced", 0) + 1`.

Add `doorAttachmentsPlaced` / `doorAttachmentsSkipped` to the summary `_log(...)` line at the
end of `main()`.

**Socket transforms are deliberately out of scope.** All the 1-Medical offsets are zero, so both
door leaves sit at the door origin — a closed double door. Driving the open animation from the
proxy skeleton's sockets is a later change; do not attempt it, and do not touch
`_import_skeletal_rigs`.

## Concrete checks

- `python -m py_compile tools/ue5/import_level.py` passes.
- The new function is called exactly once from `main()`, after `_import_instances`.
- A door entry whose `staticMesh` is null or unresolved does not raise — it counts as skipped.
- Nothing outside `_import_door_attachments` + its one call site + the summary log line changes.

## Do not touch

`src/**`, `tests/**`, any other file. Do not commit.
