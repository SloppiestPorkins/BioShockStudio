# Medical mask-kind materials — classification gap + a second SM5 compile bug (29 Sept 2026)

Live report, in-editor screenshots with the Details panel open: `MI_Wall_Leak_diff_shader` and
`..._WallTech_01_Shader`/`MI_WallTechAnim_Fan` both visibly wrong on the selected actors.

## Two separate, real bugs, found by direct investigation (not guessed)

### 1. `WallTechAnim_Fan` misclassified as opaque — a real cutout signal was being ignored

`_material_rendering_kind`'s existing rule: `masked=True` alone isn't trusted as a real cutout
signal (35 — now known to be exactly 15 — of Medical's 55 `masked=True` materials are solid
surfaces whose alpha channel packs spec/gloss data, not coverage); it only trusted `masked=True`
when the material's *name* matched a hardcoded cutout-word list (foliage, grate, fence, …).
`WallTechAnim_Fan` — a spinning fan blade, rendered the old BioShock way via a rotating UV texture
animator on a static mesh, `animators[]` confirmed in the manifest — has genuinely varying diffuse
alpha (0–255, confirmed via the stdlib PNG reader already built for the glass-opacity fix) but no
"fan" pattern in the name list, so it fell through to `opaque`: the whole square texture rendered
as a solid block instead of a blade shape with real gaps.

**Better signal than a name guess, checked against the whole set before trusting it**: a texture
entry the exporter itself tagged `usage == "Mask"` for that material. Cross-referenced against all
55 `masked=True` materials in Medical: 40 have one, and that list is a coherent, plausible
"genuinely needs a cutout" set — `Walltech_01/03_Shader`, `WallTechAnim_Fan/Cog/Lattice/Wheel/Cam/
ShaftB`, `wallHole_*`/`Grate_Flat`, `Broken_Stairs_Diffuse_shader`, carpets, dripping stains,
debris/trash, torn-paper signs/newspapers, oil slicks, ice patches. The 15 without it are exactly
the solid-surface set the original heuristic was protecting (rim-shaders, corpses, security bots,
a chained door — plus foliage/kelp, which the existing name list already caught separately).
`_material_rendering_kind` now trusts `masked=True` when *either* signal is present.

### 2. "mask" kind materials never got the SM5 sampler-type fix "translucent" kind got on 4 Sept

Confirmed live in-editor 4 Sept 2026 (an existing code comment, itself now cross-checked as
accurate): reading `MP_OPACITY`/`MP_OPACITY_MASK` from the same `TextureSampleParameter2D` node
`MP_BASE_COLOR` also reads is a **hard SM5 compile error** in this project — "Sampler type is
Color, should be Masks" — not a benign warning, and it makes the whole material fall back to
Default Material (the grey/pink checkerboard) in game. That was fixed for `kind == "translucent"`
on 4 Sept by giving Opacity its own dedicated Masks-sampler node. **The identical bug existed in
`kind == "mask"`'s branch the entire time and was never given the same fix** — it was just never
exercised much, because so few materials were ever actually classified `mask` before fix #1 above
widened that gate. Once `WallTechAnim_Fan` got correctly reclassified to `mask`, it would have hit
this exact compile failure and stayed visibly broken regardless of fix #1.

Fixed the same way: `OpacityMask` gets its own `SAMPLERTYPE_MASKS` node in
`_load_or_create_master`'s new-master path, plus a new `_repair_mask_opacity_sampler()` (mirroring
`_repair_translucent_opacity_sampler`, gated on `BLEND_MASKED`/`MP_OPACITY_MASK` instead of
`BLEND_TRANSLUCENT`/`MP_OPACITY`) for the masters that already existed before this fix.

## Verified, not assumed

Applied to the live `1-Medical` slice (material-only reimport, same safe pattern as the earlier
glass fix — not the full `import_level.main()`). Directly inspected the actual node graphs
afterward, not just re-run the classification:

- `WallTechAnim_Fan` and `Walltech_01_Shader`: now `..._mask_V5` masters, `BLEND_MASKED`,
  `OpacityMask` and `BaseColor` confirmed as separate nodes (no shared-sampler compile error).
- `Wall_Leak_diff_shader`: `BLEND_TRANSLUCENT` (its own diffuse alpha genuinely varies, 0–242 —
  it was never part of either bug; correctly translucent both before and after this pass).
- **All 44 `BLEND_MASKED` masters in the live level** (not just the two reported ones): zero have
  the shared-node shape or a missing OpacityMask node.

Regression-verified clean: `verify_gameplay_fidelity`, `verify_scripting_movers`,
`verify_vita_chamber`, `verify_import_scripts`, `verify_water`.

## Not investigated here

Whether `WallTechAnim_Fan`/`Cog`/`Lattice`/`Wheel`/`Cam`/`ShaftB` actually *animate* (the UV
rotation the manifest's `animators[]` describes) is the separate, already-known "skeletal-prop
idle animation" gap in `docs/ROADMAP.md` — this pass only fixes the *static* appearance (correct
cutout shape, correct compile), not the spin.
