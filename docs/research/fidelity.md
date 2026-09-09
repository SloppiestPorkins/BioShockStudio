# Fidelity pass — the Rapture look

Status: **look scaffolding shipped 9 Sept 2026; final grade is a live-editor tuning job.**

## Finding: the slice already reads as BioShock

After the earlier fixes — BSP UV scale, compiled-world materials, the lighting-falloff /
practical-intensity repair, the god-ray beams, walkable collision, the full-res rig textures —
a `-game` capture at the bathysphere spawn shows the Medical Pavilion doorway with warm
practical light on the "Beautified!" poster, deep art-deco shadow, black-and-white marble, the
brass airlock wheel, and the ocean outside the porthole. The "doesn't look like BioShock"
impression predates that stack of fixes.

## What was tried and rejected

`repair_slice_look.py` first applied a heavy grade + an `ExponentialHeightFog` with volumetric
fog. **An exponential height fog floods a high-Z interior (Medical floor ≈ Z 7800) to flat
white** unless density is near zero and the falloff is very sharp — and even then the
volumetric term smears the god-ray beams into a milky haze. A strong colour grade on top of the
already-tuned exposure PPV washed the scene the same way.

## What shipped

`repair_slice_look.py` (STEPS, after `import_slice_stations`) spawns two `BioShockSliceLook`-
tagged actors so they are trivial to find, tune, or delete:

- an **unbound `PostProcessVolume`** (priority 2, above the exposure PPV) with a deliberately
  *gentle* grade: `ColorSaturation` 0.94, `ColorContrast` 1.03, a slight warm-shadow /
  cool-highlight split via `color_gamma_shadows` / `color_gamma_highlights`, `VignetteIntensity`
  0.3, `FilmGrainIntensity` 0.1. Bloom and chromatic aberration are **not** overridden by
  default (0 = keep project default).
- an **`ExponentialHeightFog`** at the floor Z with density 0.0009 / falloff 1.0 / max-opacity
  0.14 — a barely-there depth haze, volumetric fog **off**.

Every value is an env-var knob (`BIOSHOCK_LOOK_SAT`, `BIOSHOCK_LOOK_FOG`, `BIOSHOCK_LOOK_VOLFOG`,
`BIOSHOCK_LOOK_VIGNETTE`, …). `BIOSHOCK_LOOK_CLEAR=1` removes both actors. The intent is that the
final grade is dialled in **with the editor open**, watching the Pavilion, not headlessly.

`verify_slice_look.py`: the two tagged actors exist and the PPV is unbound with saturation
overridden.

## Part B — remaining import defects (NOT done here)

These are surgical, itemised, and lower-risk done one at a time:

1. **Blood decals render as opaque red squares** — decal material blend mode / alpha binding
   (`d1-decal-alpha` / `h15` territory); re-check it applied to the Medical blood decals.
2. **Ad frames empty** — `dyn_eve_hypo_ad` ×9 and other ad boards; textures not imported or the
   material slot is unhooked. Locate in the bulk catalog + bind.
3. **Window glass shows the exterior window texture** — wrong material-slot assignment on the
   window meshes; audit + remap so the glass section gets a translucent glass material.
4. **Pickup / station / impact meshes** (w10/w11/w15) render as placeholder spheres and boxes —
   their real meshes were never imported into slice content. A bulk pickup-mesh import pass
   would clean up all three at once.
5. **God-ray beam wedge** reads a touch strong/opaque from the spawn vantage
   (`repair_light_beams.py` `BeamIntensity` 0.8) — a candidate for ~0.4 once the live grade is set.
