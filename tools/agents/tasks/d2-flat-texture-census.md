---
worker: chatgpt
base: main
verify: python -c "import os,sys; sys.exit(0 if os.path.exists('docs/research/flat-textures.md') else 1)"
lane: docs/research/**, tools/*.py
---
# Census: which exported textures are flat because the ART is flat, and which are decode failures

## Why

90 of 1132 exported textures for 1-Medical decode to a FLAT RGB image (per-channel stddev < 3 on a
32x32 downsample). Some of those are certainly correct: `BlackTexture.png`, `white_texture.png`
and `Transparent_O.png` are supposed to be flat, and a flat normal map is a legitimate "no bumps"
map. Others are almost certainly wrong. `Wall_Leak_diff.png` is 581,089 bytes and perfectly flat
in RGB, but its detail is in ALPHA, which is correct for a decal. `glasscon_diffuse.png` is 64x64,
228 bytes, flat RGB (0,40,46) AND flat alpha - and it is bound as the base colour of
`MI_Exterior_Window_02_Glass_Shader`, i.e. it is the window glass the user reports as broken.

Nobody has separated those three cases. That is this task: a census, not a fix.

## What to do

Write `tools/audit_flat_textures.py` - pure Python plus Pillow, with NO `unreal` import, because
it must run outside the editor. It walks an exported textures directory and classifies every PNG:

  legit-flat     tiny file AND flat RGB AND flat alpha, and the name says so
                 (black / white / transparent / default)
  alpha-carrier  flat RGB but alpha stddev > 5, so a correct decal or cutout, NOT a fault
  flat-normal    a normal map whose RGB is about (128,128,255), so legitimate
  suspect        flat RGB AND flat alpha AND a file size out of all proportion to being flat.
                 A genuinely uniform 1024x1024 PNG compresses to a couple of KB; anything much
                 larger has content that did not survive decode.

Take the directory as `sys.argv[1]`, defaulting to
`C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/Textures`.

Print a summary table, and write `docs/research/flat-textures.md` containing:
  - the counts per class
  - the full list of `suspect` entries with size, dimensions, mean RGB and alpha range
  - for each suspect, which material binds it, where you can determine that from
    `<export-dir>/../1-Medical.ue5-level.json` (its `materials` array carries `diffuse`,
    `normalMap` and `specular` paths)

## Concrete checks

- `glasscon_diffuse.png` must land in `suspect`.
- `Wall_Leak_diff.png` must land in `alpha-carrier`, NOT in `suspect`. It is correct.
- `BlackTexture.png` and `white_texture.png` must land in `legit-flat`.

## Do not touch

Anything under `src/**`, `tests/**` or `tools/ue5/**`. This task adds ONE python script and ONE
markdown document and changes nothing else. Do not commit; the orchestrator captures the diff.
