# Medical texture census (7 September 2026)

Scope: `/Game/BioShockSlice/1-Medical`; 997 unique exported textures and 5,362 placed material
slots. Reports were written under `%TEMP%`.

## Fixed

`fix_clobbered_diffuse_textures.py` found and repaired 42 textures imported as linear masks even
though their primary use is sRGB base colour:

`0451_diffuse`, `CWS-Platform`, `Carpet_PatternC_WetDirt_Diffuse`,
`Carpet_patternB_Drydirt_diffuse`, `Drain_Diffuse`, `Freezer_Ice_Diffuse`,
`Gen_Exterior_Light_Diffuse_02`, `Loadroom_Glass_Diffuse`, `PersianCarpet_D`,
`Rubble_marble_diffuse`, `ScorchMark_diffuse`, `Tennis_raquet_diffuse`, `Transparent_O`,
`WallTechAnim_Cog_Diffuse`, `WallTechAnim_Fan_Diffuse`, `WallTechAnim_Lattice_Diffuse`,
`WallTechAnim_Wheel_Diffuse`, `Wall_Leak_diff`, `Whiskey_Diffuse`, `Window`,
`arrivals_board_diffuse`, `blast_corner_diffuse`, `damdec_01_diff`, `damdec_02_diff`,
`damdec_03_diff`, `damdec_04_diff`, `debrisPile2_diffuse`, `debrisPile_diffuse`,
`decor_paperstacks`, `glassShard`, `glass_condensation`, `glass_diffuse`,
`grate_flat_diffuse`, `newspaper_diffuse`, `reinforcedglass_diffuse`, `vendneon_diffuse`,
`walltech_01_diffuse`, `walltech_03_diffuse`, `walltechanim_smallcog_diffuse`,
`walltechanim_smallfan_diffuse`, and `waterspewDIF`.

These assets now use `sRGB=true`, default colour compression, and colour material samplers. Their
alpha remains available to opacity users.

`census_slice_textures.py` cross-checked low-resolution exports against shipped
`BulkContent/Catalog.bdc`. A conservative both-dimensions test found one clear stripped offender:
`CWS-Pole_normal` was 512x512 in the slice export while the shipped `Gen_Ambience` bulk entry is
2048x2048. It was recovered with `recover_stripped_textures.py` and reimported as a linear normal
map by `import_recovered_slice_textures.py`.

The manifest has zero base-colour/normal colour-space intent mismatches.

## Remaining suspects for visual confirmation

- 40 exports have at least one dimension at or below 128. Most are legitimate masks, gradients,
  particles, or narrow strips; they are listed in `%TEMP%/texture_census_1-Medical.json`.
- The material audit reports 89 engine-default slots and 23 unresolved slots. Most sampled
  defaults are `Element1` on old multi-slot props, while unresolved samples include pickup stand-in
  meshes. These need actor/mesh names from a user screenshot before a broad 793-asset reimport;
  slot count alone does not prove the visible section is wrong.
- 18 material instances still use `WhiteSquareTexture` because their manifest declares no diffuse.
  They are predominantly fluid, additive, sequence, and opacity materials
  (`CalmwaterCube_Midref`, puddles, dripping water, `StairSpreadA`, `FloorFlowA_Shader`,
  `tv_sequence_static`, etc.). No texture was guessed for them.
- Rectangular exports whose byte counts also resemble a square BulkContent mip chain
  (`Plasmid_Glass_diffuse`, `bronze_diffuse`, `bronze_normal`) were deliberately not replaced.
  The bulk parser cannot infer non-square dimensions from those bytes, so that evidence is
  insufficient.
