---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter "FullyQualifiedName~Package"
lane: src/BioShockStudio.Core/Packages/**, tests/BioShockStudio.Tests/**, docs/research/**
---
# Read the ORIGINAL BioShock 1 (UE2.5) packages, not just Remastered

## Why this matters

The Remastered `.bsm` packages ship textures **upscaled** and stripped to their bottom 64x64 mip.
The BSP wall UVs were authored against the ORIGINAL texture sizes, so the exporter has been
GUESSING the upscale factor (`RemasterTextureUpscale = 4` in `LevelSceneExporter.cs`, measured
from texture content). It is wrong: checked against the original game,
`med_wall_public_dirt` is 1024 in original vs 2048 Remastered (2x), while
`Med_Tile_white_Dirty_Diffuse` is 512 vs 2048 (4x). The factor is per-texture, not constant.

The original game is installed at:
`G:/SteamLibrary/steamapps/common/Bioshock/Content/Maps/*.bsm`
Its packages carry the real authored `USize`/`VSize` and un-stripped textures. Reading them
directly is the fix. Right now `BioShockPackage.Open` refuses them:

    error: Unsupported package version 141/56. This tool targets BioShock 1 Remastered only (142/56).

## What to do

In `src/BioShockStudio.Core/Packages/BioShockPackage.cs`:

1. Accept **both** `141/56` (original BioShock 1) and `142/56` (Remastered). Add
   `public const ushort OriginalFileVersion = 141;` and widen the gate. Keep rejecting anything
   else with the same clear message (list both supported versions).
2. Expose which one was opened -- `PackageSummary` already carries `FileVersion`; make sure a
   caller can branch on `summary.FileVersion == BioShockPackage.OriginalFileVersion`.
3. Walk `ReadSummary`, `ReadNames`, `ReadImports`, `ReadExports` and the export-payload path and
   handle any field that is version-gated between 141 and 142. UE packages commonly gate:
   `ExportFlags`, a second export-flags dword, `NetObjectCount`/`PackageGuid` arrays,
   compression flags, the `GenerationInfo` shape. Compare a 141 header against a 142 header byte
   for byte using the CLI (`properties <path> --raw`, or a tiny throwaway) and only change what
   actually differs. **If the export table layout differs and it is more than a small delta,
   STOP and write what you found in `docs/research/packages.md` rather than guessing** -- a
   half-right export table reads every payload at the wrong offset.
4. If original packages parse cleanly, add a `[RequiresGameFact]` test in
   `tests/BioShockStudio.Tests/` (pattern-match the existing package tests) that opens
   `G:/SteamLibrary/steamapps/common/Bioshock/Content/Maps/1-Medical.bsm`, asserts
   `FileVersion == 141`, and resolves a known texture export
   (`med_wall_public_dirt`) reading its `USize`/`VSize` as 1024/1024.

## Concrete checks

- `BioShockPackage.Open("G:/SteamLibrary/steamapps/common/Bioshock/Content/Maps/1-Medical.bsm")`
  succeeds.
- A texture export's `USize`/`VSize` read back as the original (smaller) dimensions.
- All existing `~Package` tests still pass -- Remastered parsing must be untouched.

## Do not touch

`tools/**`, `src/BioShockStudio.Core/Export/**`, `src/BioShockStudio.Core/Level/**`,
`src/BioShockStudio.Core/Materials/**`. Header/table parsing only. Do not commit.
