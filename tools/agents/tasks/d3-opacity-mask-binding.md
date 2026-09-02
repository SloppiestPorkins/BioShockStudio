---
worker: chatgpt
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter "FullyQualifiedName~Material"
lane: src/BioShockStudio.Core/Materials/**, src/BioShockStudio.Core/Export/**, tests/BioShockStudio.Tests/**, docs/research/**
---
# Export the opacity mask a Shader binds through its `Opacity` MaskMaterial

## What was already established

`docs/research/decal-alpha.md` (task d1) proved that `BloodSplat1/2/3` are DXT1 with NO alpha, so
the "big red square" the user sees is not a decode fault. It also found where the shape actually
lives. Shader export `12769`, `Gen_BattleDebris.bloodsplat3_shader`:

  - names `BloodSplat3` as `Diffuse`
  - carries a nested **`Opacity` value of struct type `MaskMaterial`**
  - names `bloodsplat3nor` as `NormalMap`
  - declares `OutputBlending = 1`

and the package holds a separate `Gen_BattleDebris.bloodsplat3opa`, 2048x2048 DXT1, whose mask is
stored as RGB INTENSITY (not alpha). `bloodsplat1opa` and `bloodsplat2opa` sit beside it.

So the coverage is authored in its own texture, reached through a property the exporter does not
currently follow. Nothing downstream can cut the splat out until that binding is exported.

This is the same shape of bug as `FalloffMap` on `LightBeamShader` (commit 5c2d8b5): a
class-specific binding that no slot list knew about, so the material exported incomplete and the
UE5 side substituted something wrong.

## What to do

1. In `src/BioShockStudio.Core/Materials/MaterialReader.cs`, follow the `Opacity` property when it
   is a `MaskMaterial` struct and resolve the texture it names. Read the existing remarks in that
   file first: the reader deliberately accepts a binding only when it resolves to a `Texture`, and
   it deliberately keeps NO fixed slot-name list for what a texture binding is called. Stay
   consistent with both. `MaterialSequenceReader` and `MaterialAnimatorReader` are the precedents
   for following a nested object/struct binding.
2. Surface it on `BioShockMaterial` as an `OpacityTexture` (nullable), beside `DiffuseTexture` /
   `NormalTexture` / `SpecularTexture`.
3. In `src/BioShockStudio.Core/Export/MaterialExporter.cs`, write that texture like the others and
   add an `Opacity` path to `SceneMaterial`. Then carry it through
   `LevelSceneExporter.MaterialDocument` and `LevelMaterialDocument` as `opacity`, exactly the way
   `diffuse` / `normalMap` / `specular` are carried.
4. Test in `tests/BioShockStudio.Tests/`, `[RequiresGameFact]` like its neighbours: reading
   `bloodsplat3_shader` out of 1-Medical must yield an opacity texture named `bloodsplat3opa`, and
   `MaterialExporter.ResolveMaterial` must write that file.

## Concrete checks

- `bloodsplat3_shader` -> opacity texture `bloodsplat3opa`, written as a PNG beside the scene.
- The exported `bloodsplat3opa.png` must NOT be uniform: its RGB stddev must be > 5, because the
  mask is stored as RGB intensity. That is what proves the shape is really there.
- Materials with no `Opacity` property must still export with `opacity` null and be otherwise
  unchanged - do not regress `Light_Beam_01` (diffuse `Light_beam_LowFalloff.png`) or any
  `FluidShader`, which correctly has no diffuse at all.

## Do not touch

`tools/ue5/**` - the UE5 import side is being changed concurrently in the main tree, and wiring
this into the UE5 master material is a SEPARATE task. Stop at the manifest. Do not commit.
