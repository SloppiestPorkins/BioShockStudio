# BioShock 1 Remastered — install layout

`CONFIRMED_BYTES` / directly observed on a Steam install.

```
BioShock Remastered/
├── Build/Final/                  executables
├── 2KLauncher/
└── ContentBaked/pc/
    ├── Maps/                     21 packages (+ 7 localised variants each) and Catalog.bdc
    ├── BulkContent/              201 BulkChunk0_*.blk, ~8.0 GB total
    ├── Sounds_Windows/           .fsb banks
    ├── System/                   .debug configs
    ├── FlashMovies/, BinkMovies/
    └── Localized*.lbf
```

## Packages

21 non-localised `.bsm` packages, 20 KB to 230 MB, ~4.8 GB total.

```
0-Lighthouse   1-Medical   1-Welcome   2-Fisheries   2-SubBay
3-Arcadia      3-Market    4-Recreation 5-Hephaestus 5-Ryan
6-Resi         6-Slums     7-BossFight 7-Gauntlet   7-Science
Autoplay       Entry       museum
ChallengeRoomCombat  ChallengeRoomDecoy  ChallengeRoomElectric
```

Each also ships as `_chn`, `_deu`, `_esp`, `_fra`, `_int`, `_ita`, `_jpn`. These are localisation
variants of the same maps and are skipped by the scanner.

`Entry.bsm` (20,649 bytes, 40 exports) is the smallest and is used as the primary parser fixture.

`0-Lighthouse.bsm` holds the first-person hands assets and is the fixture for the Havok tests.

## Bulk content

`CONFIRMED_BYTES`, fully decoded — see [bulkcontent.md](bulkcontent.md). 201 `BulkChunk0_*.blk`
files, ~8 GB, indexed by `Catalog.bdc`; this is where the high-resolution texture data most
packaged textures are stripped down from actually lives.

## Related installs available for cross-referencing

`Alien: Isolation` is installed on the same machine. It is a documented user of Havok
2012.2.0-r1 and is the most useful nearby reference for the container format — while remembering
that its game-specific structures are its own. See [external-projects.md](external-projects.md).


## Most textures are stripped, and the rest lives in the bulk store

`CONFIRMED_BYTES`, fully decoded, catalogue format and all — see [bulkcontent.md](bulkcontent.md).
Short version: a `Texture` export's `StrippedNumMips`/`HasBeenStripped` say how much of itself is
missing (in `1-Medical`, 1,639 of ~1,937 textures top out at 64×64 in-package), `Catalog.bdc`
indexes the 8 GB bulk store by name to a `(chunk, offset, size)` triple, and the recovered mips
verify against what the package kept.

---

## Original (non-Remastered) BioShock 1 — installed, but the packages are COMPRESSED

`G:/SteamLibrary/steamapps/common/Bioshock/` (6.1 GB) is the 2007 UE2.5 game.

- Package version **141/56** (Remastered is 142/56). `BioShockPackage.Open` rejects it.
- **The `.bsm` files are compressed.** `Entry.bsm` is 4,038 bytes on disk but its summary declares
  `names@10065`, `imports@15987`, `exports@16422` — offsets well past the end of the file. UE2.5
  `FCompressedChunk` (LZO / zlib) package compression; Remastered ships them decompressed. Reading
  original packages directly means implementing the chunk decompressor first — a real task, not a
  version-gate widen. `f1-bsm-version-141`'s "identical layout" assumption failed exactly here
  (`ReadNames` → `EndOfStreamException`).
- **`Builds/Release/umodel_win32/`** — UModel is bundled and has already been run once:
  `Builds/Release/UmodelExport/1-Medical/` holds 1,714 texture PNGs at their **original** sizes
  (`med_wall_public_dirt` 1024, `Med_Tile_white_Dirty_Diffuse` 512 — vs Remastered's 2048). UModel
  handles the decompression.

### What the original sizes are used for

The BSP UV normaliser (`LevelSceneExporter.AuthoredTextureSize`) reads these PNG dimensions via
`BIOSHOCK_ORIGINAL_TEXTURE_DIR` and divides texel UVs by **`AuthoredTextureScale` × original size**
(default scale **2**; `BIOSHOCK_BSP_UV_AUTHORED_SCALE=1` restores the old divide-by-original). When
the directory is unset it falls back to `AuthoredTextureScale × (shipped / BIOSHOCK_BSP_UV_UPSCALE)`
(defaults 2 × shipped/4 = shipped/2).

**Why ×2 (measured 7 Oct 2026 against the live Remaster, Medical):**

| material | remaster `\|TextureU\|` | original | shipped `USize` | period @ original | period @ ×2 original | live |
|---|---|---|---|---|---|---|
| `Bathroom_Tile_BW_Diffuse_shader` | 4.0 | 512 | 2048 | 128 | **256** | autocorrelation vs export: **exactly 2×** |
| `Medical_ceilling_Diffuse_shader` | 4.0 | 512 | 512 (not upscaled) | 128 | **256** | large plaster panels vs tiny export grid |
| `med_wall_public_shader` | 2.667 | 1024 | 2048 | 384 | **768** | trim band mid-wall under ÷original (texture is ~70% plaster / ~30% base trim) |

Dividing by shipped `USize` alone fails the floor (would give period 512 = 4× original, not 2×).
2007 `1-Medical` is **not** on the install used for this measurement (only compressed
`0-Lighthouse.rbd` remains; `BioShockPackage` is Remastered 142-only), so remaster-vs-2007
`TextureU` vector equality is **unverified** — the ×2 rule is pinned to live Remaster output, not
to a proven “remaster vectors = 2007 × k” identity.
