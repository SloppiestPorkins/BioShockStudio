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
