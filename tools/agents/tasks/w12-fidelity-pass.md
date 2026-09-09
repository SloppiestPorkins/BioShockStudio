---
worker: chatgpt
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# Fidelity pass — the slice doesn't read as BioShock yet

User (8 Sept 2026): "a fidelity pass as it does not look like bioshock at the moment."

A lot of the underlying decode is right (BSP UV scale `ce68731`, compiled-world materials
`292dba0`, walkable collision, the lighting-falloff fix, god-ray beams). What's missing is the
**overall Rapture look**: the moody art-deco atmosphere, wet grimy surfaces, warm practical
pools against deep shadow, neon bloom, particulate haze, water everywhere. Right now it looks
like an untinted UE5 scene with BioShock geometry.

## Do this in two parts: (A) the look, (B) the remaining import defects.

## A. The Rapture look

1. **Post-process / colour grade.** One well-tuned unbound `APostProcessVolume` (or extend the
   one `repair_level_lighting.py` adds): a warm-shadows / cool-highlights split-tone, slightly
   crushed blacks, gentle S-curve, low saturation with the neon and practicals allowed to pop,
   film grain, subtle vignette, chromatic aberration at the edges (light touch), bloom tuned so
   the "Beautified!" sign and neon glow. Reference Medical Pavilion screenshots. Expose the
   knobs (env / a `UDataAsset`) so it's tunable without a rebuild.
2. **Volumetric fog / atmosphere.** A thin `UExponentialHeightFogComponent` + volumetric fog so
   the god-ray shafts (v4) actually catch, distance reads hazy, and the air feels heavy and wet.
   Keep it subtle — Medical is interior.
3. **Surface wetness / grime.** Medical is a flooded hospital. A detail-normal + roughness pass
   on the floor/wall masters for puddled reflections and grime streaks; wet-edge darkening near
   the water volumes. Where the shipped material already has a spec/gloss map, make sure it's
   bound and weighted (the rig-texture fix `def7a4b` showed how many were stubs — re-check the
   BSP/prop masters the same way).
4. **Reflections.** Confirm the `CubemapProbe` → `SphereReflectionCapture` import (`import_level.py`,
   "code 25 Aug, not visually confirmed") actually placed captures and they're capturing; add a
   `SkyLight` / screen-space fallback so wet floors and glass reflect something.
5. **Water surfaces** — E3/v4 did 27 surfaces; confirm they read as water (caustics, panning
   normal, depth fade, foam at edges) and that the window-exterior water (#9 below) is applied.

## B. Remaining import defects (from the 1 Sept fidelity punch list)

4. **Blood decals render as big opaque red squares** — decal materials imported opaque / no
   decal blend mode / alpha ignored. Fix the decal import (blend mode `Translucent` or
   `AlphaComposite`, alpha bound, `DBuffer` domain) — `d1-decal-alpha` / `h15` touched this;
   check it actually applied to the Medical blood decals.
5. **Ad frames are empty** — ad-board textures didn't import or the material slot is unhooked.
   Locate the ad textures (bulk catalog / a slot audit like `audit_level_materials.py`) and bind
   them. The `dyn_eve_hypo_ad` ×9 actors are the eve-hypo billboards.
6. **Window glass shows the exterior window texture** — wrong material-slot assignment on window
   meshes (glass section resolves to the frame/exterior key). Audit + remap the window mesh
   slots so the glass section gets a translucent glass material and the frame gets the frame
   material.
7. **`repair_placeholder_base_colours` ran with the wrong content root** in
   `setup_playable_slice` (it used `/Game/BioShockLevel`, not the slice) — pass
   `BIOSHOCK_PLACEHOLDER_CONTENT_ROOT=/Game/BioShockSlice/Content` and re-run.
8. **Checkerboard meshes (`WorldGridMaterial`).** `repair_null_slot_materials.py` (`630f1f5`) put
   a stopgap `alan_metal` / ammo master on the 18 meshes with a null slot 0
   (SecurityCameraSmall, tommygun ammo, AI pistol / TommyGun pickup, Steinman banners) — their
   real materials were never exported (rig / weapon-def import paths skip material export). Fix
   properly: export + bind their actual materials. Also the user still reports checkerboard
   panels in the incinerator / camera room (`~-26300,6100,8200`) after that stopgap — likely a
   compiled-world BSP section on the intentionally-null zoning slot, or a mesh whose MI itself
   is broken; run `audit_level_materials.py` there and either bind the real material or apply
   the `fix_compiled_world_materials.py` mtllib treatment.

## Deliverable

- `docs/research/fidelity.md` — the post-process/fog/wetness/reflection choices with the knobs,
  the punch-list items closed and how, before/after evidence.
- The look wired into `setup_playable_slice` (a `repair_slice_look.py` step or extend
  `repair_level_lighting`).
- The import-defect fixes (decals, ads, glass) as scripts + STEPS wiring.
- Headless: existing verifies stay green; a check that the slice has a PPV + height fog + N
  reflection captures + bound ad/glass materials.
- **`-game` before/after captures** from 3-4 vantage points (bathysphere spawn, the Pavilion,
  a corridor, a window) — this task lives or dies on the captures looking like BioShock.

## Constraints

- `tools/ue5/**` + `src/**` (additive, Fast tests green) + `docs/research/**` + `tmp/**`.
- Editor CLOSED for headless. `-run=pythonscript` → JSON. MSYS forward-slash + `MSYS_NO_PATHCONV=1`.
- Don't touch h11 compiled-world mobility/collision. Don't undo the `ce68731` UV scale or the
  `292dba0` mtllib fix.
- Do NOT commit. Diff for review; a human does the final visual QC — captures are necessary but
  not sufficient.
- Read the 1 Sept fidelity punch list context, `docs/research/*.md`, and reference screenshots
  before deriving anything.
