# Medical glass materials — opacity wiring bug (29 Sept 2026)

Live PIE report: "glass has no textures." Investigated directly (not delegated) after a live
screenshot and a follow-up report. Roadmap/STATUS previously called glass "not yet built" — that
was wrong; it's built and mostly correct, with one specific, now-fixed wiring bug.

## What was actually true before this fix

All 25 distinct glass/window materials in `1-Medical` were correctly identified as translucent,
correctly two-sided, and correctly bound to real, non-degenerate textures (64×64 to 2048×2048,
confirmed via a stdlib PNG parse — no `PIL` in UE5's embedded Python, so
`tools/ue5/import_bioshock.py`'s `_diffuse_png_alpha_extrema`/`_png_chunks`/`_png_unfilter` hand-roll
an 8-bit RGBA/LA reader, same convention `author_water_material.py` already used for PNG writing).
So "no textures" was not literally true. The real bug, found by reading the actual material graph
node-by-node on the live slice:

**`_load_or_create_master`'s `elif kind == "translucent":` branch always read the *diffuse*
texture's own alpha channel for Opacity, even when a genuinely separate, correctly-exported
Opacity-slot texture existed for that material and had already been resolved
(`_material_texture_bindings`/`_create_material_instances` correctly found it — the resolved
`opacity_texture` parameter was just never used in this one code path, only in `_wire_opacity_mask`
for the unrelated "mask" kind).** A diffuse map's own alpha channel is very often uniformly 255
(packed spec/gloss/self-illum data, not coverage) — measured on 9 of 18 sampled diffuse textures.
BLEND_TRANSLUCENT with Opacity locked at 1.0 renders as a flat, fully-opaque pane: visually reads
as "just base color, no glass look" — close enough to the live report's "no textures" that this is
almost certainly what was seen.

## The fix

Three changes to `tools/ue5/import_bioshock.py`, all Python/data-only (no C++, no rebuild):

1. **Use the resolved `opacity_texture` for the Opacity sampler, not the diffuse texture**, in
   both the new-master creation path and a new `_repair_translucent_opacity_texture()` for
   already-created masters (most of Medical's materials were already imported).
2. **`_has_usable_transparency()` guard** on the two rendering-kind signals that are inferred
   rather than authoritative (`declaresAlphaTexture`, the bare "window"/"glass" name heuristic,
   and `outputBlending in (1, 2)` — this function's own docstring already said "OutputBlending
   ordinals are still UNKNOWN individually"). A material with no dedicated Opacity-slot texture
   (correctly excluding a slot entry that just points at the same file as Diffuse — measured on
   `glass_shader`, which declares an "Opacity" slot bound to its own `glass_diffuse.png`) *and* a
   diffuse texture whose decoded alpha turns out to be degenerate now renders opaque instead of
   fake-translucent. `FluidShader`/`WindowShader` class markers and `outputBlending == 3`
   (additive) are deliberately **not** gated — those are either an explicit engine-class signal
   (not inferred) or a mode where a flat alpha still looks correct (additive decays to nothing on
   a black base colour; opaque-alpha straight translucent does not).
3. Fixed the repair-vs-split **ordering bug** found while landing this: an existing master whose
   Opacity node still shares one node with BaseColor (the pre-4-Sept-2026 shape
   `_repair_translucent_opacity_sampler` exists to split) must be split *before*
   `_repair_translucent_opacity_texture` runs, or the split reproduces the diffuse-as-opacity bug
   from whatever the shared node already held. Also found the Opacity node on some existing
   masters is a plain `MaterialExpressionTextureSample`, not the `...Parameter2D` variant new
   masters use — `_repair_translucent_opacity_texture` accepts either (confirmed
   `MaterialExpressionTextureSampleParameter2D` is a Python-visible subclass of
   `MaterialExpressionTextureSample`).

## Applied to the live slice, measured result

Re-ran material creation only (`_create_material_instances` + `_configure_medical_fluid_materials`
— **not** the full `import_level.main()`, which crashed on an unrelated skeletal-rig import step
earlier this session; material-only reimport is a narrower, already-proven-safe operation, same
pattern as `z1`'s water fix). Final state, all 25 glass materials:

```
opaque (no real coverage data anywhere): 6
translucent, now using a real distinct opacity texture (the fix): 12
translucent, correctly using diffuse's own real alpha (unchanged, already correct): 7
```

The 6 downgraded to opaque: `Interior_Window_diffuse_shader`, `exterior_window`,
`Exterior_Window_02`, `Window_Material`, `walltech_03_glass_diffuse`, `glass_shader` — none had a
genuinely separate opacity source anywhere in the exported data.

First attempt at applying this also **broke water rendering** as a side effect:
`_create_material_instances` reparents every material to its generic per-instance master,
including `FluidShader` materials, and the initial landing script called it without the follow-up
`_configure_medical_fluid_materials` (z1's specialised `M_ShockWater` reparenting pass) —
`verify_water.py` caught it immediately (`medicalSurfaces count: 0`). Fixed by calling both in the
same order `import_level._import_level_materials` already uses. Re-verified clean:
`verify_water.py` passes (101 surfaces, 11 distinct textures — same as z1's landing), plus
`verify_import_scripts.py`, `verify_light_import.py`, `verify_gameplay_fidelity.py`,
`verify_scripting_movers.py`, `verify_vita_chamber.py`.

## Not done here

- **Decals** (the separate half of "check decals, check glass" from the live report): confirmed
  genuinely textureless by design, not a bug — `author_impact_decal_standins.py` builds a
  procedural radial-falloff mask (`MaterialExpressionSphereMask`) with a flat constant colour, no
  texture sample anywhere in the graph, because the real BioShock decal/Cascade art was never
  recovered. This is the fidelity gap already named in `docs/STATUS.md`/`docs/ROADMAP.md`
  ("particle/effects stand-ins for shipped particle systems that can't be recovered
  byte-for-byte") — fixing it for real means authoring or sourcing actual bullet-hole imagery, not
  a wiring bug, and wasn't attempted here.
- Did not extend the alpha-degeneracy guard to non-Medical maps' materials or re-run this fix
  against any other map — Medical-scoped per the standing "medical first" directive.
