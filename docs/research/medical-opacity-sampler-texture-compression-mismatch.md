# Opacity sampler-vs-texture-compression mismatch — the real root cause (29 Sept 2026)

Follow-up to `docs/research/medical-opacity-sampler-legacy-shapes.md`, whose fixes were believed
complete but did not actually resolve the user's own reported case. The user re-sent the same
`Wall_Leak_diff_shader` SM5 compile-error screenshot after that doc's fixes were live, proving the
node's `sampler_type` alone was never the whole story.

## What every earlier pass in this saga got wrong

A material node's `sampler_type` (Color / Masks / Normal / …) is a *hint the shader compiler
checks against the referenced texture ASSET's own `compression_settings`/`srgb` properties* — not
a self-contained setting. Every repair in this file up to this point (`_repair_opacity_sampler_type`
and its predecessors) only ever read or wrote the *node's* `sampler_type`. None of them checked
whether the *texture asset* the node points at was actually compressed to match. A node correctly
set to `SAMPLERTYPE_MASKS` pointing at a texture asset still compressed `TC_DEFAULT` is exactly as
broken as a `SAMPLERTYPE_COLOR` node reading a `TC_MASKS` texture — the same SM5 error, symmetric.

## Root cause 1 — a texture-asset naming collision (Wall_Leak_diff_shader itself)

Direct inspection (`get_material_property_input_node` + reading `texture.compression_settings`
and `texture.srgb` on the ASSET, not just the node) found `Wall_Leak_diff_shader`'s `MP_OPACITY`
node correctly pointed at a distinct `TextureSampleParameter2D` with `sampler_type =
SAMPLERTYPE_MASKS` — but that node's *texture* was the exact same asset,
`/Game/.../Textures/Wall_Leak_diff`, that `MP_BASE_COLOR` also read. Checking that shared asset
directly: `compression_settings = TC_MASKS`, `srgb = False` — correct for the Opacity read, wrong
for BaseColor's.

Traced to `_import_textures` (`import_bioshock.py`): when the manifest's Diffuse slot and Opacity
slot for a material point at the same source file (a common, already-documented shape — see
`_material_has_opacity_slot_texture`), the function tried to import it twice under different
intents ("the same PNG can be bound twice with different intent... so neither binding has to
compromise on colour space", its own long-standing comment claimed) — but **both imports wrote to
the same destination asset path** (`{destination}/Textures/{stem}`, derived only from the source
filename). Whichever entry processed second silently overwrote the first's `srgb`/
`compression_settings`. For `Wall_Leak_diff_shader` the Opacity entry won the race, so the single
resulting asset ended up `TC_MASKS`/`srgb=False` — right for Opacity, wrong for BaseColor's read
of that same asset.

### Fix

Give the opacity-intent import of a colliding file its own destination name
(`{stem}_Opacity`, via `AssetImportTask.destination_name`), making it a genuinely separate asset
instead of overwriting the diffuse one. Two supporting fixes were needed to make this actually
work in practice, both found only by testing against the live slice rather than trusting the
isolated logic:

1. **`_opacity_entry_identities` had to replace the naive `_opacity_file_membership`.** A
   (material, file)-keyed check matches *every* entry sharing that file for a material, including
   the Diffuse-slot entry itself when Diffuse and Opacity share a file — so both got flagged
   opacity-intent, and the plain (non-suffixed) Diffuse import never ran at all, leaving the
   original asset frozen at its stale wrong settings. The fix keys identity by (material, *slot*)
   instead — resolving which specific manifest entry is the real Opacity source the same way
   `_material_texture_bindings` does (prefer a literal `"Opacity"`-named slot; fall back to a file
   match only when the material's top-level `opacity` field names a file with no such slot).
2. **`compression_settings` must be explicitly reset on every import, including the "neither
   Mask/NormalMap/Opacity" case.** `_import_textures` only ever set it inside the
   NormalMap/Mask/Height/opacity branches — the implicit assumption being that anything else
   would land at the factory default. Measured live: `replace_existing=True` re-imports pixel data
   but does **not** reset an existing asset's `compression_settings` — it preserves whatever was
   already there. A texture previously left at `TC_MASKS` by the bug above stayed `TC_MASKS`
   forever on every later re-import, even once the code correctly decided this entry was no longer
   opacity intent. Added an explicit `else: TC_DEFAULT` branch.
3. The downstream `diffuse_texture`/`opacity_texture` binding loop in `_create_material_instances`
   had the identical file-vs-slot ambiguity (matching by `file == opacity` when Diffuse and
   Opacity share a file matches both slots) — fixed to prefer the literal `"Opacity"`-slot's own
   texture whenever one exists.

## Root cause 2 — a genuinely shared texture, correctly so, with no separate opacity source at all

Fixing (1) surfaced something much bigger. A full sweep — for every material actually placed in
`1-Medical`, checking whether every `TextureSample`-family node's `sampler_type` actually matches
its referenced texture asset's real `compression_settings` (not just whether the node's own
property looks self-consistent) — found **30 further broken masters**, all "mask" kind, e.g.
`WallTechAnim_Fan`, `Walltech_01/03_Shader`, `PersianCarpet_shader`, `newspaper_diffuse_shader`,
`debrispile2_shader`, and 25 more.

These are architecturally different from `Wall_Leak_diff_shader`: they have **no separate Opacity
slot at all** — their cutout mask is meant to come from the diffuse texture's own alpha channel,
which is entirely legitimate (that is what BioShock's original shader authored). Their
`OpacityMask` node was already correctly split from BaseColor and already correctly
`SAMPLERTYPE_MASKS` — but it pointed at the SAME diffuse asset BaseColor reads, which is (rightly)
`TC_DEFAULT`/sRGB for BaseColor's own purposes. One texture asset cannot be both.

### Fix — `_masks_compressed_variant`

A new helper: given a texture asset, returns (creating once, then reusing) a sibling
`<Name>_Mask` asset — `unreal.EditorAssetLibrary.duplicate_asset` cloned from the original, then
explicitly set `srgb=False`, `compression_settings=TC_MASKS`. Wired into every place that was
previously handing an Opacity/OpacityMask node the shared diffuse texture directly:
`_repair_translucent_opacity_sampler`, `_repair_mask_opacity_sampler` (both structural-split
repairs, which previously just copied the shared node's existing texture reference across
unchanged), and both `kind == "mask"` / `kind == "translucent"` new-master creation branches in
`_load_or_create_master`.

A **fifth legacy shape** followed directly from this: the 30 broken masters already had a
*structurally separate*, *already-`SAMPLERTYPE_MASKS`* node — so neither structural-split repair
(gated on "still shares BaseColor's node") nor `_repair_opacity_sampler_type` (only checks the
node's own `sampler_type` property, never what its texture is actually compressed as) had any way
to reach them. Added `_repair_opacity_texture_compression_mismatch`: for an
already-`SAMPLERTYPE_MASKS` node whose texture is not actually `TC_MASKS`-compressed, repoint it
to `_masks_compressed_variant(texture)`.

## Root cause 3 — the inverse, on BaseColor itself

The same sweep, run once more after fixing the above, found exactly 2 remaining cases —
`glass_shader` and `Freezer_Ice_Translucent`, both `opaque` kind — where `MP_BASE_COLOR`'s own
node was stuck at `SAMPLERTYPE_MASKS` while its texture was ordinary `TC_DEFAULT`/sRGB. A **sixth
legacy shape**, and the only one running in the opposite direction of every other fix here. Most
plausibly a stale leftover from an earlier build where the material was briefly classified "mask"
kind and this node started life as that branch's OpacityMask node, before a reclassification pass
repointed `MP_BASE_COLOR` at it without ever resetting its `sampler_type`. BaseColor never
legitimately needs Masks sampling, so `_repair_base_color_sampler_type` fixes it unconditionally,
no kind/blend_mode gate needed.

## Verified, not assumed, this time

A full sampler-vs-texture-compression sweep (not just a sampler-vs-sampler one, unlike the
predecessor doc's) across all 427 masters actually referenced by placed static mesh actors in
`1-Medical`, checking `MP_BASE_COLOR`/`MP_OPACITY`/`MP_OPACITY_MASK`/`MP_METALLIC`/`MP_SPECULAR`/
`MP_ROUGHNESS`/`MP_EMISSIVE_COLOR` on each: **0 mismatches** after all three fixes (was 30, then 2,
then 0, tracked at each stage rather than assumed after one pass). Re-verified
`Wall_Leak_diff_shader` directly by property inspection: `MP_BASE_COLOR` → `Wall_Leak_diff`
(`TC_DEFAULT`, `srgb=True`); `MP_OPACITY` → `Wall_Leak_diff_Opacity` (`TC_MASKS`, `srgb=False`,
`sampler_type=SAMPLERTYPE_MASKS`) — two genuinely distinct, individually-correct assets.

Regression-verified clean: `verify_gameplay_fidelity`, `verify_scripting_movers`,
`verify_vita_chamber`, `verify_import_scripts`, `verify_water` (all PASS / 0 errors).

## Standing limitation, unchanged

`-nullrhi` headless commandlets still never trigger real SM5 shader compilation. This entire class
of bug — sampler/compression mismatches, in either direction, on either a node or its texture
asset — is invisible to every verify script in this repo. It can only be found by reading node AND
texture-asset properties back directly (what this fix's sweep does) or by a real, non-nullrhi
editor session showing the live compile-error banner, which is what actually surfaced both this
round's root cause and the previous doc's incompleteness.
