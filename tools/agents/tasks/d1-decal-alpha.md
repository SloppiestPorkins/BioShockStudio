---
worker: chatgpt
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter "FullyQualifiedName~Texture"
lane: src/BioShockStudio.Core/Textures/**, tests/BioShockStudio.Tests/**, docs/research/**
---
# Blood decals export with no alpha, so they render as solid squares

## The symptom, measured

The user reports blood splatters in-game as "a big red square". They are right, and the cause is
in the exported PNG, not in the UE5 material.

Exported to `<BioShockUE5>/Exports/slice/1-Medical/Textures/` (re-export with
`dotnet run --project src/BioShockStudio.Cli -- export-level 1-Medical <out-dir>`):

    BloodSplat1.png  1024x1024 RGBA   50,680 bytes  alpha 255..255  (stddev 0.00)
    BloodSplat3.png  1024x1024 RGBA  137,728 bytes  alpha 255..255  (stddev 0.00)
    RGB of BloodSplat3: red channel 24..41, green 0..0, blue 0..0

So the splatter SHAPE is present only as a faint variation in the red channel, and the alpha
channel — which is what cuts the splat out of its quad — is uniformly opaque. A decal quad with a
fully opaque alpha renders as a rectangle of flat dark red. That is exactly what is on screen.

Compare a texture that came out RIGHT, in the same export:

    Wall_Leak_diff.png       2048x512  RGB stddev 0.00, ALPHA stddev 81.79, range 0..242
    Kelp_01_Diffuse.png      1024x1024 RGB stddev ~15, ALPHA stddev 113.1, range 0..255

Both carry their shape in alpha and decode correctly. So the decoder CAN produce alpha; something
about the blood textures' source format or path loses it.

## What to do

1. Find out WHY. Start at `src/BioShockStudio.Core/Textures/TextureReader.cs` and the format
   handling around `BioShockTextureFormat`. Likely suspects, in order:
   - the source is DXT1 (no alpha, or 1-bit alpha) and the real alpha lives in a separate
     texture or a second mip chain that is not being read;
   - an alpha-bearing format is being decoded as its opaque sibling;
   - alpha is decoded but overwritten/flattened when the PNG is written.
   `MaterialReader.DeclaresTransparency` and its remarks are relevant background: this game
   often does NOT use the diffuse alpha as opacity, and the code already knows that.
2. Report the finding in `docs/research/decal-alpha.md`: which format these are, what the bytes
   actually contain, and whether the alpha exists in the source at all. **If the source genuinely
   has no alpha, say so and stop** — that is a real and useful answer, and the fix would then be a
   material-side one that is NOT in this task's lane.
3. If alpha IS being lost, fix the decode and add a test in `tests/BioShockStudio.Tests/` that
   asserts a known blood texture decodes with non-uniform alpha. Use `RequiresGameFact` like the
   existing texture tests, since it needs the shipped game data.

## Concrete checks

- `BloodSplat3` (1-Medical) must end up with alpha stddev > 5 if the source carries alpha.
- Do not regress `Wall_Leak_diff` or `Kelp_01_Diffuse` — both currently decode correctly and their
  alpha ranges above are the reference values.

## Do not touch

`tools/ue5/**` (that is the UE5 side and is being worked on concurrently in the main tree),
`src/BioShockStudio.Core/Export/MaterialExporter.cs`, `src/BioShockStudio.Core/Materials/**`.
Do not commit; the orchestrator captures the diff.
