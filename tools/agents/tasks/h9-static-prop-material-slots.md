---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Static prop material slots: first material renders on every slot (windows, ad frames, etc.)

## User report (live PIE, 4 Sept 2026)

> material slots for windows, ad frames that kind of stuff is broken. the first texture is
> used for all other material slots even though they shouldn't [be]

Multi-material static props (window frames, ad boards — likely others, these are just the
ones noticed) render every material slot with the first slot's texture, instead of each
slot showing its own assigned material.

## Where this almost certainly comes from — read this function in full first

`import_level.py`, `_assign_asset_material()` (~line 449-487). Its own docstring states the
load-bearing assumption plainly:

```
`BuildAssetObj` now writes one "usemtl BioShock_{index}" group per entry in the manifest's
own `sections` list, in that same order -- both are built by iterating the same geometry
section table -- so imported material slot N is assumed to correspond to `sections[N]`.
```

The Python side of this looks correct on inspection: it builds one `StaticMaterial` slot
per manifest section, in order, each with its own resolved `material_interface` (or an
empty slot when unresolved — not a neighbour's material), and assigns the whole array to
`mesh.static_materials` in one shot. **The bug, if this is where it lives, is that the
assumption doesn't hold**: `mesh.static_materials` defines what material each *slot index*
means, but which slot index each *triangle* actually uses comes from the mesh's own
per-section `MaterialIndex`, baked in by UE's OBJ importer from the file's own
`usemtl`/`g` groups — not from anything this Python function controls. If UE's importer
orders, merges, or reindexes sections differently than the manifest's `sections` list
order (a real possibility: multiple sections with identical geometry topology can get
merged, or import order can differ from file order), every triangle could end up pointing
at `MaterialIndex 0` regardless of a correctly-populated 67-slot array — which would look
exactly like "first texture on every slot."

**Confirmed unrelated to today's `reimport_compiled_world_only.py` reimport** — user
confirms (4 Sept 2026) windows show this and windows are not part of the compiled-world
mesh, and the bug "has been here since the start." This is a genuine, pre-existing,
systemic bug in `_assign_asset_material`/the static prop import pipeline, not a
regression from anything touched this session. It means the fix needs to touch
already-imported assets project-wide (a re-run of material assignment against existing
props), not just change behaviour for future imports — scope the fix accordingly from
the start rather than discovering this halfway through.

## What to do

1. **Reproduce and confirm the actual mechanism, don't assume the docstring's own
   caveat is the bug** — pick one affected asset (a window or ad frame the user can name,
   or find one via the manifest that has 2+ resolved material keys), and read its actual
   imported `StaticMesh`'s per-section `MaterialIndex` values headlessly
   (`mesh.get_num_sections(0)`, then each section's `MaterialIndex` via whatever Python
   API exposes `FStaticMeshSection` — check `mesh.get_editor_property("render_data")` or
   an equivalent; this project's own `verify_collision.py` already reads
   `body_setup`/`agg_geom` structures this way, follow that precedent for whatever the
   mesh-section equivalent is). Confirm whether MaterialIndex is genuinely 0 for every
   section (confirms the theory) or something else entirely (wrong theory — say so).
2. If confirmed: the fix is either (a) reading the mesh's *actual* per-section material
   index after import and assigning materials against *that* order instead of the
   manifest's assumed order, or (b) finding and setting whatever import option controls
   section ordering/preservation so it matches the manifest — whichever is the smaller,
   more correct change. Don't reorder the manifest to match a guessed import order; find
   the real mapping.
3. **Scope**: does this affect only multi-material props, or also single-material ones
   (which wouldn't show the bug even if MaterialIndex were wrong, since there's only one
   slot to be wrong about)? Since this is confirmed project-wide and pre-existing, once
   the root cause is fixed for future imports, also work out the safest way to re-apply
   correct material slots to every already-imported multi-material static prop without a
   full reimport (ideally: re-run just the section/material-index correction against
   existing mesh assets) — say clearly what that repair script does and does not touch
   before it's run against the live project.

## Tests / verify

Add a headless verify script (model on `verify_collision.py`'s shape: structural check
against the actual mesh data, not just "did assignment run without error"): for a known
multi-material prop, assert each section's resolved material differs appropriately (not
all pointing at slot 0's material) after a fresh import via `_import_asset_meshes`. This
needs a real per-section check against the mesh's own data, the same category of mistake
`verify_collision.py`'s docstring describes for the collision regression it exists to
catch — an assignment-succeeded check without checking what actually renders would have
the same blind spot.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- No live UE session in this worktree — headless assertions on actual mesh section data
  are the evidence; a human confirms the visual result (windows, ad frames) in the editor
  afterward.
- If fixing this requires touching already-imported assets (not just future imports), say
  so explicitly and describe the safest way to re-apply it project-wide rather than doing
  it unprompted across the whole level — this session already regressed collision once
  from an insufficiently careful reimport, be the extra bit more careful here.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
