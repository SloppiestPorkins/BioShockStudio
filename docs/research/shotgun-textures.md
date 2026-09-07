# Shotgun viewmodel textures — empty mips / flat green

**Status:** `CONFIRMED_BYTES` (7 Sept 2026). Fixed in Content by bulk recover + reimport;
durable CLI fix landed — `ResolveMesh` now passes `BulkTextureCatalog.Load(root)` into
`MaterialExporter.Resolve`, so a clean `export-fbx` no longer writes stubs.

## Symptom

First-person `WP_Shotgun` drew as a flat unlit green blob after the viewmodel architecture
rework. Hands and `Launcher` socket attach were correct; only paint was wrong.
Before: `Content/.../WP_Shotgun/Textures/Shotgun_NoUpgrades_*.uasset` ≈ 10 KB.
After: same assets ≈ 5 MB (2048×2048).

## Root cause

Not a wrong texture name and not a format the decoder cannot read.

| Check | Result |
|---|---|
| Material / texture names | `Shotgun_NoUpgrades_{Diffuse,Normal,Specular}` — matches mesh shader and `.uc` base (no-upgrade) set |
| Package outer / bulk group | `WP_Shotgun` |
| Formats | Diffuse/Normal `Dxt1`, Specular `Dxt5`, declared 2048, `StrippedNumMips=5`, package top 64×64 |
| Bulk catalog | Present (`BulkChunk0_17/57/34.blk`, sizes 2793472 / 2793472 / 5586944) |
| `TextureReader.Read(..., bulk)` | Recovers 2048×2048 |
| `TextureReader.Read` without bulk | Leaves 64×64 — what `export-fbx` wrote |

`export-fbx` → `ResolveMesh` → `MaterialExporter.Resolve(...)` never loads
`BulkTextureCatalog`. Contrast: `Pistol_DIFF` has `StrippedNumMips=0` (full mips in
package, no catalog entry) so the same path still produced a good PNG. `WP_Pistol_Spec`
is stripped and was also a 64×64 stub for the same reason — out of shotgun scope.

Landmine this matches: HANDOFF §4 "Most textures are not in the packages" /
`docs/research/bulkcontent.md`.

## Fix applied (UE5 lane)

```text
python tools/ue5/recover_stripped_textures.py --out %TEMP%/bioshock-shotgun-tex-fixed \
  --group WP_Shotgun Shotgun_NoUpgrades_Diffuse Shotgun_NoUpgrades_Normal Shotgun_NoUpgrades_Specular
# copy PNGs over the stub export (or write them there directly):
copy %TEMP%\bioshock-shotgun-tex-fixed\Textures\* %TEMP%\recover-weapons\WP_Shotgun\Textures\

set BIOSHOCK_FORCE_IMPORT=1
UnrealEditor-Cmd <proj> -run=pythonscript \
  -script=tools/ue5/run_reimport_shotgun_full.py -unattended -nopause -nosplash
# (or textures-only: run_reimport_shotgun_textures.py)

tools/ue5/capture_shot.ps1 -Out %TEMP%/bioshock_shotgun_textured_idle.png \
  -Extra '-bioshockstartslot=3'
```

Evidence (7 Sept 2026):
- Content uassets: Diffuse/Normal/Specular ≈ 5.4 / 4.8 / 5.3 MB (was ≈ 10 KB)
- MI `BaseColor`/`Normal` → those 2048² assets (`%TEMP%/shotgun_material_probe.json`)
- Recovered diffuse atlas shows wood, rusted metal, gold receiver engraving
  (`tmp/diffuse_preview.png`)
- Capture: `%TEMP%/bioshock_shotgun_textured_idle.png` (also `tmp/3_shotgun_idle_textured.png`);
  gun-region mean abs RGB delta vs prior green stub ≈ 66 (frames not identical). Medical's
  green underwater lighting still washes weapons — healthy pistol crops look similarly green.

## Durable fix (landed 7 Sept 2026)

`Program.cs` `ResolveMesh` now passes `BulkTextureCatalog.Load(root)` into
`MaterialExporter.Resolve` when an output directory is given. The next clean
`export-fbx UAPW_WP_Shotgun` picks up the 2048² mips from `BulkContent` instead of the
64×64 package tail. `recover_stripped_textures.py` remains as a standalone recovery tool
and as the path that fixed the live Content this time.
