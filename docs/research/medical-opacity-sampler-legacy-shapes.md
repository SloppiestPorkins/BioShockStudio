# Opacity-node legacy shapes — sampler type + missing node (29 Sept 2026)

> **Correction, same day**: this doc's "Re-swept clean" and "Standing limitation" sections were
> also incomplete. The 88-material sweep here only ever checked a node's own `sampler_type`
> property, never whether the TEXTURE ASSET it references is actually compressed to match that
> sampler type — a texture asset's compression is exactly as load-bearing as a node's sampler_type,
> and the two can independently disagree. The user's OWN editor still showed
> `Wall_Leak_diff_shader`'s compile error after this doc's fixes were believed complete, which is
> what surfaced this. See `docs/research/medical-opacity-sampler-texture-compression-mismatch.md`
> for the real root cause (a texture-asset naming collision) and three further legacy shapes it
> exposed.

Follow-up to `docs/research/medical-mask-material-fix.md` and `medical-glass-opacity-fix.md`. Both
of those passes only ever checked whether a master's Opacity/OpacityMask node was *structurally
separate* from BaseColor (`opacityNodeName != baseNodeName`). Live evidence from the user's own
UE5 editor proved that check was not sufficient.

## The evidence

The user sent a screenshot of the real Material Editor's own SM5 compile-error banner for
`Wall_Leak_diff_shader` (not a headless log — nullrhi headless runs never trigger real shader
compilation, so this class of bug is invisible to every verify script in this repo):

```
[SM5] (Node TextureSample) Sampler type is Color, should be Masks for
  /Game/BioShockSlice/Content/1-Medical/Textures/Wall_Leak_diff.Wall_Leak_diff
[SM5] (Node TextureSampleParameter2D) Sampler type is Color, should be Masks for
  /Game/BioShockSlice/Content/1-Medical/Textures/Wall_Leak_diff.Wall_Leak_diff
Warning: Opacity samples /Game/BioShockSlice/Content/1-Medical/Textures/Wall_Leak_diff.Wall_Leak_diff
  as Color.
```

Direct property inspection (`get_material_property_input_node` + `get_editor_property
("sampler_type")`, not a class/name check) confirmed: `Wall_Leak_diff_shader`'s Opacity node was
*already* a separate node from BaseColor — built by a code path that predates every repair
function in `import_bioshock.py` — but its `sampler_type` had simply never been set to
`SAMPLERTYPE_MASKS`, still sitting at the `SAMPLERTYPE_COLOR` default. Neither existing repair
function catches this: `_repair_translucent_opacity_sampler`/`_repair_mask_opacity_sampler` only
fire when the node is *shared* with BaseColor, and `_repair_translucent_opacity_texture` only
touches the `texture` property, never `sampler_type`.

## Fix 1 — `_repair_opacity_sampler_type`

New function in `import_bioshock.py`: loads the Opacity (`MP_OPACITY`) or OpacityMask
(`MP_OPACITY_MASK`) input node, and if it's a `MaterialExpressionTextureSample` whose
`sampler_type` isn't already `SAMPLERTYPE_MASKS`, sets it and recompiles. Wired into
`_load_or_create_master`'s existing-master repair sequence for both properties, run *after* the
structural-split repairs (a still-shared node has to be split first) and *before* the
texture-repointing repair.

Verified directly on the live slice: `Wall_Leak_diff_shader`'s master now reads
`sampler_type: SAMPLERTYPE_MASKS` (was `SAMPLERTYPE_COLOR`).

## Sweeping for more instances — a fourth shape

Rather than trust that fixing the one reported material was complete, swept all 88
translucent/mask masters actually in use in the live `1-Medical` slice, checking each one's
Opacity/OpacityMask node for: missing entirely, wrong node class, or wrong `sampler_type`.

Found 2 flagged:

- `/Game/BioShock/Water/M_ShockWater` — "unexpected node type: MaterialExpressionMultiply". **False
  positive**: this master's Opacity input is a legitimate multi-node expression graph from the
  z1 water-materials work, not a simple texture sample, so the sweep's "only look for
  TextureSample nodes" check doesn't apply. No action needed.
- `M_BioShock_WindowShader_Exterior_Window_02_Glass_Shader_translucent_TwoSided_V5` — "no opacity
  node at all". A genuine fourth legacy shape: `MP_OPACITY` has **no node connected whatsoever**,
  not a wrong one. The manifest confirms this material has a real, distinct opacity texture
  available (`Exterior_Window_02_Glass_Diffuse.png`, a different file from the diffuse's
  `glasscon_diffuse.png`, tagged `usage: "Mask"`) — the master was simply never wired to use it.

## Fix 2 — create-on-missing in `_repair_translucent_opacity_texture`

Extended the existing texture-repointing repair: when `opacity_node is None`, instead of bailing
out, it now creates a fresh `MaterialExpressionTextureSampleParameter2D` node
(`parameter_name="Opacity"`, `sampler_type=SAMPLERTYPE_MASKS`, `texture=opacity_texture`),
connects its Alpha output to `MP_OPACITY`, recompiles, and saves — mirroring the exact node-build
pattern the new-master-creation path already uses for `kind == "translucent"`.

Verified directly on the live slice: `Exterior_Window_02_Glass_Shader`'s master now has an
`MP_OPACITY` node of class `MaterialExpressionTextureSampleParameter2D`, `sampler_type
SAMPLERTYPE_MASKS`, texture `Exterior_Window_02_Glass_Diffuse`.

## Re-swept clean

Same 88-material sweep after both fixes: `totalChecked: 88`, `brokenCount: 1` — only the
`M_ShockWater` false positive remains, which needed no fix. Zero real sampler-type or
missing-opacity-node issues remain among the materials actually placed in `1-Medical`.

Regression-verified clean: `verify_gameplay_fidelity`, `verify_scripting_movers`,
`verify_vita_chamber`, `verify_import_scripts`, `verify_water` (all PASS / 0 errors).

## Standing limitation, now documented in code

`-nullrhi` headless commandlets never trigger real SM5 shader compilation — there is no rendering
hardware interface to compile against. **No headless verify script in this project can catch a
wrong-sampler-type or similar shader-compiler-level bug.** The only ways to catch this class of bug
are: (a) reading a node's actual property values back directly (what this fix's sweep does), or
(b) the user's real, non-nullrhi editor session showing the live compile-error banner, as happened
here. This is now called out directly in `_repair_opacity_sampler_type`'s docstring.
