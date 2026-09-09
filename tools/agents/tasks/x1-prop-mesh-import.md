---
worker: chatgpt
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# R0.1 — import the real prop meshes (kill the placeholder spheres)

> **Run mode:** non-interactive, sandboxed to this worktree — no UE launch, no build. Research
> from the manifest + `dotnet run --project src/BioShockStudio.Cli` catalog tools + the shipped
> packages, then WRITE the exporter/importer/docs changes and stop. Verify every engine/base
> member against the headers before use. Thorough, compiling, complete.

`docs/research/runtime-brain.md` §8 + `mesh_census.py`: the slice has 284 `/Engine/BasicShapes`
placeholder meshes. 40 door blockers + 27 water planes are intentional invisible proxies —
LEAVE THOSE. The ~217 real eyesores are `AShockConsumablePickup` (147), `AShockSearchableContainer`
(55), `AShockAnimatedProp` (8), `AShockStationBase` (7) carrying a marker sphere because their
real BioShock mesh was never imported into slice content.

## What to build

1. **`export-staticmesh` coverage.** The pickup/prop meshes named in the 1-Medical manifest
   (`staticMesh` field on each `*Pickup` / `*Container` / `ScriptableMover` / `Placeable*Station`
   actor) — e.g. `bio_bandages`, `Ammo_Pickup_JHP`, `Ammo_HighExplosiveBuck`, `hypo`,
   `EVE_hypo`, the ADAM/AutoHack/PowerBar props, the food/drink props, `WP_*` weapon-pickup
   props, the plasmid-bottle props, `dyn_med_wheelchair`, `CashRegister`, `FlowerVase`, the
   `DeadBodyContainer` corpse mesh, the `Resurrection` machine mesh. Confirm the C# exporter
   resolves each from the package (or the bulk catalog — `BulkTextureCatalog` / mesh catalog)
   and writes an FBX/OBJ + textures. Extend `ResolveMesh` where a name doesn't resolve.
2. **`tools/ue5/import_slice_prop_meshes.py`** (mirror `import_slice_pickups.py`): import each
   exported mesh to `/Game/BioShockSlice/Content/Meshes/<name>` with materials, then walk the
   placed actors and call `SetPickupMesh` / `SetContainerMesh` / set `AShockAnimatedProp.PropMesh`
   / `AShockStationBase.Mesh` by className→mesh map (reuse the `import_slice_pickups.PICKUPS`
   className list). Reset the marker scale to 1. Idempotent. Wire into `setup_playable_slice`
   STEPS AFTER `import_slice_pickups` / `_stations` / `_animated_props`.
3. Where a mesh genuinely can't be recovered from the shipped data, say so in the doc and leave
   the marker — don't invent geometry.

## Deliverable

- `docs/research/prop-meshes.md` — the manifest mesh list, which resolved / which didn't, the
  className→mesh map, the STEPS placement.
- `export-staticmesh` fixes (C#, additive, Fast tests green) + `import_slice_prop_meshes.py` +
  STEPS wiring.
- Headless: `verify_prop_meshes.py` — after the step, 0 `/Engine/BasicShapes` meshes on
  `AShockConsumablePickup` / `AShockSearchableContainer` / `AShockAnimatedProp` /
  `AShockStationBase` actors that had a manifest `staticMesh`; each resolves a real material.
- `-game` capture: a shelf of health kits, a looted-corpse spot, the incinerator wheelchair.

## Constraints

- `tools/ue5/**` + `src/**` (additive) + `docs/research/**` + `tmp/**`.
- Don't touch h11 compiled-world mobility/collision or the everything-complex-as-simple policy.
- Don't re-import the door blockers or water planes as visible meshes.
- Do NOT commit. Diff + RESULT.json for review.
