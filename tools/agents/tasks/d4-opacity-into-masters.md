---
worker: chatgpt
base: main
verify: python -m py_compile tools/ue5/import_bioshock.py tools/ue5/import_level.py
lane: tools/ue5/import_bioshock.py, tools/ue5/repair_opacity_masks.py, docs/research/**
---
# Wire the exported `opacity` mask into the generated UE5 master materials

## Where this picks up

Commit `ae4e793` made the exporter follow a Shader's nested `Opacity` / `MaskMaterial` binding, so
`<map>.ue5-level.json` now carries an `opacity` path beside `diffuse` / `normalMap` / `specular`.
Re-exporting 1-Medical writes masks that were previously dropped entirely:

    bloodsplat1/2/3opa        2048^2   RGB stddev 50.4 / 74.9 / 102.7
    wallhole01_opacity        2048^2   stddev 42.2
    wallhole03_opacity        2048^2   stddev 72.2
    wallHole_corner_Opacity   2048^2   stddev 71.0
    ConcreteWall_Hole_Opacity 2048^2   stddev 41.0
    Broken_Stairs_Opacity      512^2   stddev 56.7
    window_glass_opacity      1024x2048 stddev 44.0

All span the full 0..255 range. **The mask is stored as RGB INTENSITY, not in the alpha channel** —
that is how this game authors them. Nothing on the UE5 side reads `opacity` yet, so blood still
renders as an opaque quad, wall holes are not cut out, and window glass is solid.

## What to do

In `tools/ue5/import_bioshock.py`:

1. Import the `opacity` texture like the other maps, as a **Linear / masks** texture, NOT sRGB.
   It is a coverage mask, not colour. Find where `diffuse` and `normalMap` are imported and follow
   that path; `_material_texture_bindings` is the function that resolves which file goes to which
   slot.
2. When a material has an `opacity` path, the generated master must:
   - use blend mode `BLEND_MASKED`
   - sample that texture and feed **one channel** (R is fine — all three are equal on these) into
     the Opacity Mask input, via a `TextureSampleParameter2D` named `OpacityMask` so an instance
     can be re-bound later without regenerating the master
   - keep `opacity_mask_clip_value` at the engine default unless you have a reason
3. Materials with no `opacity` path must be **completely unchanged** — same blend mode, same
   graph, same parameters as today. This is the important constraint: 1-Medical has hundreds of
   opaque materials and they must not start being masked.
4. Write `tools/ue5/repair_opacity_masks.py` to apply the same binding to materials ALREADY
   imported, from a current manifest, so the level does not need a full re-import. Model it closely
   on the existing `tools/ue5/repair_placeholder_base_colours.py` — same env-var convention
   (`BIOSHOCK_OPACITY_MANIFEST`, `_CONTENT_ROOT`, `_DRY`), same `_reports/<name>.json` output, and
   **the same re-read-after-write discipline**: that file exists because an earlier repair in this
   project counted assignments it intended rather than effects it achieved, and reported success
   over a no-op.

## Headless gotchas that will bite you

These are established in this repo and not negotiable:
  - `save_current_level` and `AssetImportTask(save=True)` route through
    `InternalPromptForCheckoutAndSave`, whose Slate notification asserts under
    `-run=pythonscript`. Use `EditorLoadingAndSavingUtils.save_map` / `save_loaded_asset`.
  - Guard `load_asset` with `does_asset_exist` — a benign "LoadAsset failed" Error poisons the
    commandlet exit code.
  - Mutating a struct returned by `get_editor_property` does not persist. Build fresh structs.

## Concrete checks

- `MI_bloodsplat3_shader` ends up `BLEND_MASKED` with an `OpacityMask` texture parameter bound to
  `bloodsplat3opa`.
- `MI_loadroom_wall` (no `opacity` in the manifest) stays `BLEND_OPAQUE` with its graph unchanged.
- `repair_opacity_masks.py` reports what it changed by re-reading, not by counting intent.

## Do not touch

`src/**`, `tests/**`, `tools/ue5/BioShockRuntime/**`, and any other `tools/ue5/*.py` except the two
named in the lane. You cannot run the editor, so do not attempt to verify by importing — `verify`
is a syntax check only, and the change will be reviewed and run against UE5 by hand. Do not commit.
