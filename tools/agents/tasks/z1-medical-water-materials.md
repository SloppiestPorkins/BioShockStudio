---
worker: chatgpt
base: main
verify: git status --short
lane: tools/ue5/*.py, docs/research/**
---

# z1 — parameterize Medical's water surfaces from their own decoded material data (roadmap item 6)

> **Run mode:** non-interactive, sandboxed. Do NOT launch the Unreal editor GUI, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5` directly except through the headless `-run=pythonscript`
> commandlet the way every existing `run_*.py`/`verify_*.py` in `tools/ue5/` already does. Do NOT
> commit. **Scope is `1-Medical` only** (`/Game/BioShockSlice/1-Medical`) — do not touch any other
> map. **Do not touch `tools/ue5/BioShockRuntime/**` (C++)** — another task may be running in that
> lane concurrently; this round is Python/asset-only.

## The gap

`tools/ue5/author_water_material.py` builds one generic stand-in (`M_ShockWater` + one cascading
variant) — "Deco-era Rapture pool water: translucent blue-green, panning normal ripples" — and
`import_level.py` applies it to every water volume's surface plane uniformly. But the level export
already decoded each water surface's OWN real material data. Confirmed in
`Exports/slice/1-Medical/1-Medical.ue5-level.json` `materials[]`: **19 distinct `FluidShader`
materials** in Medical alone, each with its own `diffuse`/`normalMap` texture path and real
`animators[]` pan values (e.g. `WaterSpreadA`: `Textures/waterspread2.png` +
`Textures/waterspreadNORM.png`, two diffuse panners at `(panU=-0.25,panV=0.15,duration=0.87)` and
`(panU=-0.2,panV=-0.1,duration=1.13)`, matching normal-map panners). Every one of Medical's water
surfaces currently looks identical because none of this per-instance data is used.

## What to do

1. **Find which water volume/actor in `1-Medical` uses which of the 19 `FluidShader` materials.**
   The manifest's `instances[]`/`actors[]` should link a water-volume actor to its material via the
   same asset-reference convention `import_level.py` already uses elsewhere (check how a regular
   StaticMesh actor resolves its material slots first — the pattern should be analogous). Confirm
   this link exists in the exported data before assuming it does.
2. **Decide how to carry the per-surface texture + panner values onto the water render.** Two
   reasonable approaches, pick whichever fits the existing `M_ShockWater` graph better (open it and
   look, don't guess its node structure):
   - Extend `M_ShockWater` with material-instance-scalar/vector parameters for pan speed/direction
     and a texture parameter for diffuse/normal, then create one `MaterialInstanceDynamic` (or a
     saved `MaterialInstanceConstant`) per distinct `FluidShader` seen in Medical, driven by that
     material's own decoded values — not the generic hand-authored look.
   - If `M_ShockWater`'s existing panning-normal-ripple approach can't cleanly take a second
     diffuse/normal pair (there are 2 diffuse + 2 normal panners per shader in the sample above,
     not 1), extend the master's node graph to actually blend two panned diffuse layers and two
     panned normal layers, matching what `FluidShader`'s own animator slots represent
     (`DiffuseTextureAnimator1/2`, `NormalTextureAnimator1/2`).
   - Import the referenced textures (`waterspread2.png`/`waterspreadNORM.png` etc.) the same way
     `import_bioshock`/`import_level` import any other referenced texture — check the existing
     texture-import helper rather than writing a new one.
3. **Apply per-surface, not globally.** After this, two different water surfaces in Medical with
   different `FluidShader` source materials should visibly differ (different texture, different pan
   speed/direction) rather than all reading as one identical material instance.
4. Re-verify `verify_water.py` still passes (it tests generic mechanics — overlap detection, PP
   fade — which this change must not break) and extend it (or add a new check) asserting that at
   least two distinct water surfaces in the live `1-Medical` slice now carry two distinct texture
   parameter values.

## What this is NOT

Not a request to build a from-scratch caustic/refraction/reflection water shader, and not a request
to touch `CascadingWaterVolume`'s enable/disable action behaviour (already handled separately, see
`docs/research/w-cascading-water.md` if it exists, or `ShockActionEnableOrDisableCascadingWaterVolume.cpp`
— read-only reference, don't change it). Scope is: make Medical's water surfaces use their own real
decoded material data instead of one identical stand-in everywhere.

## Deliverable

- The material/import changes (`tools/ue5/author_water_material.py` and/or `import_level.py`'s water
  handling — whichever actually needs it, check both before assuming).
- `docs/research/z1-medical-water-materials.md`: which 19 (or however many you actually find)
  `FluidShader` materials exist in Medical, which water actors use which, what you built to carry
  the per-instance data, own words, cite file:line.
- Updated/extended `verify_water.py`.
- Don't regress: `verify_water.py`, `verify_import_scripts.py`, `verify_light_import.py` (textures
  you import should not disturb unrelated texture-import behaviour).
