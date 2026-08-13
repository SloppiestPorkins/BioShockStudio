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

`UNKNOWN`. 201 `BulkChunk0_*.blk` files, ~8 GB. The name table contains `CachedBulkDataSize`, so
packages reference bulk data rather than embedding it — this is almost certainly where
high-resolution texture data lives (brief §17). Not yet parsed, and not on the critical path for
the pistol animation target.

## Related installs available for cross-referencing

`Alien: Isolation` is installed on the same machine. It is a documented user of Havok
2012.2.0-r1 and is the most useful nearby reference for the container format — while remembering
that its game-specific structures are its own. See [external-projects.md](external-projects.md).


## Most textures are stripped, and the rest lives in the bulk store (CONFIRMED_BYTES)

A `Texture` export says how big it really is and how much of itself is missing.
`ChemThrow_Pickup_Kero_Diffuse` in `1-Medical`:

| Property | Value |
|---|---|
| `USize`, `VSize` | 2048, 2048 |
| `UBits`, `VBits` | 11, 11 |
| `HasBeenStripped` | true |
| `StrippedNumMips` | 5 |
| `MinLOD` | 5 |
| `CachedBulkDataSize` | 0 |
| Mips actually in the package | 5, topping out at **64x64** |

2048 down five levels — 1024, 512, 256, 128, 64 — is exactly the 64-square top mip the package
holds. The texture is not low resolution; the package is carrying its tail.

`Hand_DIFF`, which really is 2048 in the package, has no `HasBeenStripped` and no `StrippedNumMips`;
it has `bStreamable` false instead.

**How much of the game this is:** in `1-Medical`, of ~1,937 textures, **1,639 top out at 64x64**.
Only 11 are 2048 and 13 are 1024. So the great majority of what the tool draws is the bottom of a
mip chain.

### The bulk store is indexed and looks readable

`ContentBaked/pc/BulkContent/` holds 201 `BulkChunk*_*.blk` files, ~8 GB, and — the part that had
been missed — a **`Catalog.bdc`** of 516,961 bytes.

The catalog is not opaque. It opens with a header, then UTF-16 strings with a length prefix, and the
first entries read plainly:

```
BulkChunk0_0.blk
  HarvestSlugFish_Diff   HarvestSlugfish   ... 00000080  00000aa0  00000aa0  00000001
  HarvestSlugFish_Norm   HarvestSlugfish   ... 00000b80  00000aa0  00000aa0  00000002
```

Each entry names the texture, names its group, and carries what look like an offset into the chunk
(128, then 2944), a size twice over (2720), and a sequential index. The offsets advance by the size,
which is what a flat blob store looks like.

`UNKNOWN`: the exact record layout and the header. But this is a name-to-(chunk, offset, size) table,
not a compressed archive, so recovering the stripped mips looks tractable rather than speculative.
