---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# AggressorBabyJane's skeletal mesh import is genuinely inverted — fix the import, not the display code

## This is measured, not suspected

`h2-ai-hostility-and-mesh` added `ABaseShockAI::GetMeshUprightDeltaForVerify()`
(world-space head-bone Z minus foot-bone Z after mesh assign) specifically so this
wouldn't be guessed at. Ran it for real against the live `/Game/BioShockSlice/TestArena`
map, 4 Sept 2026, after applying h2 and rebuilding:

```
Enemy_Melee     headZ-feetZ = -124.6
Enemy_Ranged_A  headZ-feetZ = -124.6
Enemy_Ranged_B  headZ-feetZ = -124.6
```

Consistently, reproducibly negative — a standing character should read strongly
**positive** (`docs/research/ANIMATION_COORDINATE_SYSTEM.md` line ~49 gives the
skeleton's own authored bounding box as `Z[1.1, 197.6]`, i.e. expect roughly +196
for this exact measurement, not -125). `ApplyCombatSkeletalMesh` (from h2) already
sets the mesh component's relative rotation to Identity — the yaw-only correction
`ACharacter` would otherwise apply doesn't touch this axis, and h2 was deliberately
built to *not* guess a compensating pitch/roll. The character is upside down before
any of that code runs. This is an import-time problem.

## Where to look

`tools/ue5/import_bioshock.py`, the skeletal mesh import path (~line 55-70):

```python
mesh_data.set_editor_property("import_rotation", unreal.Rotator(0.0, 0.0, 0.0))
...
mesh_data.set_editor_property("force_front_x_axis", False)
```

and the equivalent for animations a bit further down (~line 94-98) — both zero /
default, i.e. this import relies entirely on the FBX's own embedded axis metadata
for orientation, with no explicit correction.

`docs/research/ANIMATION_COORDINATE_SYSTEM.md` (read this file in full first, it's
short and it's already done the hard work) documents:
- BioShock/Vengeance source data is **left-handed**: `+X forward, +Y right, +Z up`
  (line 17).
- This project's own internal convention is right-handed: `+X forward, -Y right,
  +Z up` (line 19) — a **handedness flip**, not just an axis relabel.
- The FBX files themselves declare `UpAxis +Z, FrontAxis -Y, CoordAxis +X` (line 102).
- The doc identifies a specific minimal reflection, called **`C`** in the doc, that
  fixes the handedness while preserving forward/up (lines 88-95) — described there in
  the context this doc was written for (check whether that's BSP/level geometry, a
  different asset class, or already meant to be general-purpose; the doc says C "was
  chosen to be the minimal reflection that fixes handedness" but this task doesn't
  know without re-reading whether skeletal mesh import already receives it somewhere
  else in the pipeline, or never did).

Left-handed source data imported into a right-handed target with no explicit
handedness correction is exactly the shape of bug that flips a mesh upside down (a
single-axis sign flip on a left/right-handed conversion inverts one perpendicular
axis as a side effect) — consistent with the measured data above.

## What to do

1. Read `docs/research/ANIMATION_COORDINATE_SYSTEM.md` in full. Determine whether the
   `C` reflection (or an equivalent explicit `import_rotation` / pre-transform) is
   already applied anywhere in the skeletal mesh / animation import path, or only to
   some other asset class (BSP geometry, static meshes). If BioShock characters need
   the same handedness correction and it's simply missing from
   `import_bioshock.py`'s skeletal mesh branch, that is almost certainly the fix.
2. Apply the correction to AggressorBabyJane's import (and by extension every
   skeletal character/animation import this tool handles — this is a general
   import-pipeline bug, not something specific to one archetype).
3. **Re-import AggressorBabyJane** (mesh + skeleton; check whether existing imported
   animations need re-import too, or whether they're independent of this — the
   coordinate doc's own bone-level findings, e.g. the `L_UpperArm`/`R_UpperArm`
   before/after table in `FIRST_PERSON_ANIMATION.md`, may be relevant precedent for
   whether anims carry the same fault).
4. **Verify with the measurement already built for this**: rebuild the runtime, run
   `tools/ue5/setup_test_arena.py` then `tools/ue5/run_test_arena_verify.py` against
   the live `/Game/BioShockSlice/TestArena` map (same commands used to produce the
   numbers above) and confirm `GetMeshUprightDeltaForVerify()` reads strongly
   positive (target ~196, not just >0 — a small positive number sitting near zero is
   still suspicious) for all three enemies. Don't add a new compensating rotation in
   `ApplyCombatSkeletalMesh` to paper over a still-wrong import — if the import fix
   doesn't fully resolve it, say exactly what the residual delta is.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only. Asset re-imports land in
  `C:\Users\Jack\Documents\BioShockUE5\Content\...`, outside this repo.
- If fixing this generally (all skeletal imports) risks changing orientation for
  assets already imported and working correctly (e.g. `NEWPlayerHands`, which visibly
  displays right-side-up today per `AShockPlayer::EnsureViewHands`), investigate
  before changing shared code blindly — hands and full-body characters may not share
  the same source convention, or hands may already be getting a correction this task
  hasn't found yet. Say so if the fix is per-asset-class rather than universal.
- This worktree has no live UE session — headless assertions
  (`GetMeshUprightDeltaForVerify`) are the evidence; a human confirms the actual look
  in the editor afterward.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once
  verified, same style as the existing `h1`/`h2` entries.
