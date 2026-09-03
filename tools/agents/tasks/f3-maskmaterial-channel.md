---
worker: aider
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter "FullyQualifiedName~Material"
lane: src/BioShockStudio.Core/Materials/**, tests/BioShockStudio.Tests/**, docs/research/**
---
# Decode the channel selector in a Shader's `Opacity` / `SpecularMask` / `EmissiveMask` MaskMaterial

## The problem

`MaterialReader.ReadMaskTexture` grabs the FIRST object property inside a `MaskMaterial` struct
that resolves to a Texture, and reports it as a plain coverage mask. That is wrong: the struct
also carries a **channel selector** (which of R/G/B/A is the mask), and the texture it names is
often a PACKED map, not a single-channel cutout.

Measured with `src/BioShockStudio.Cli/bin/Release/net8.0/BioShockStudio.Cli.exe properties 1-Medical <shader>`:

    bloodsplat3_shader     Opacity  Struct MaskMaterial  360000000055035CEE036B010000000001010000000000
       -> resolves to bloodsplat3opa  (a real grey single-channel mask -- correct)

    marble_ceiling_damage2_diffuse_shader
       Opacity   Struct MaskMaterial  360000000055037C80046B010000000001010000000000
       HeightMap Struct MaskMaterial  360000000055037E80046B010000000001010000000000
       -> Opacity resolves to marble_ceiling_damage2_AlphaSpecGloss  (packed -- alpha is opacity)

    Exterior_Window_Glass_Shader
       Opacity      Struct MaskMaterial  3600000000550356FE036B010000000001000000000000  (ends 01 00)
       SpecularMask Struct MaskMaterial  360000000005006B010000000001020000000000        (ends 01 02)
       EmissiveMask Struct MaskMaterial  360000000015706B6B010000000001020000000000       (ends 01 02)

Note the trailing byte before the zero run: Opacity=`01`(bloodsplat, marble) or `00`(glass),
SpecularMask=`02`, EmissiveMask=`02`. That is very likely `{0,1,2,3}` = channel, or a mask-type
enum. Decode it.

## What to do

1. Decode the `MaskMaterial` struct fully. It is a fixed small shape: an object reference to the
   texture, plus (at least) a channel/type byte. Use `UnrealPropertyReader.Read` on the struct
   value (`ReadMaskTexture` already does) and identify every field. Dump several with the CLI --
   `Opacity`, `SpecularMask`, `EmissiveMask`, `HeightMap`, `CoverageMask` across a handful of
   shaders -- and find what varies.
2. Extend `MaterialTexture` (or a small new record `MaskBinding`) with a `Channel` (enum
   `Red|Green|Blue|Alpha`, or `byte` if the mapping is unclear) so `ReadMaskTexture` returns it.
3. Surface it on `BioShockMaterial` -- e.g. `OpacityChannel` beside `OpacityTexture`.
4. Write the finding to `docs/research/materials.md` (a `## MaskMaterial` section): the struct
   byte layout, what the channel byte means, and which shaders use which channel. State clearly
   what is `CONFIRMED_BYTES` vs still `UNKNOWN`.
5. Add a `[RequiresGameFact]` test: `bloodsplat3_shader` opacity channel, and
   `Exterior_Window_Glass_Shader` opacity channel, read as whatever the bytes say -- the test
   pins the decode, it does not need to know the "right" answer in advance.

## Concrete checks

- `dotnet build src/BioShockStudio.Core` is clean.
- The new test passes and asserts a specific channel value for at least two shaders.
- `docs/research/materials.md` gains a MaskMaterial section with the byte layout.
- Existing `~Material` tests still pass.

## Do not touch

`src/BioShockStudio.Core/Export/**`, `tools/**`. Reader + docs + test only. Do not commit.
