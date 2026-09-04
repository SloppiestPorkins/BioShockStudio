# Havok 2012.2.0-r1 in BioShock 1 Remastered

**Implementation:** `src/BioShockStudio.Core/Havok/`
**Tests:** `tests/BioShockStudio.Tests/HavokPackfileTests.cs`

## Where Havok data lives

`CONFIRMED_BYTES`. BioShock does not ship standalone `.hkx` files. Havok packfiles are embedded
**inside Unreal export payloads**, at arbitrary byte offsets — the hands package starts its packfile
at byte 34 of the payload, not on a 4-byte boundary. Any detector that steps by 4 will miss them.

Counts of embedded packfiles, by owning export class (`0-Lighthouse.bsm`, 1,151 total):

| Count | Owning class |
|---|---|
| 1,107 | `Level` |
| 44 | `AnimationPackageWrapper` |

`1-Medical.bsm` alone contains 7,088. A single map therefore holds thousands of packfiles, which is
why detection and lazy access matter more than raw parse speed.

## Packfile header (`hkPackfileHeader`, 64 bytes)

`CONFIRMED_BYTES`.

| Offset | Type | Field | Value |
|---|---|---|---|
| 0 | uint32 | Magic0 | `0x57E0E057` |
| 4 | uint32 | Magic1 | `0x10C0C010` |
| 8 | int32 | UserTag | `0` |
| 12 | int32 | FileVersion | `9` |
| 16 | uint8[4] | LayoutRules | `04 01 00 01` |
| 20 | int32 | NumSections | content-dependent |
| 24 | int32 | ContentsSectionIndex | `NumSections - 1` |
| 28 | int32 | ContentsSectionOffset | |
| 32 | int32 | ContentsClassNameSectionIndex | `0` |
| 36 | int32 | ContentsClassNameSectionOffset | |
| 40 | char[16] | ContentsVersion | `hk_2012.2.0-r1` |
| 56 | int32 | Flags | |
| 60 | int32 | Padding | |

`LayoutRules` decodes as 4-byte pointers, little-endian, no padding reuse, empty-base-class
optimisation on.

### Correction to a prior assumption

The project brief recorded `numSections = 3` and `absoluteDataStart = 208` as confirmed facts.
Those hold for **simple** payloads but are **not universal**: the first-person hands package ships
**12** sections, giving a data start of `64 + 12 × 48 = 640`. The invariant that is actually true and
now tested is the arithmetic:

```
AbsoluteDataStart = 64 + NumSections * 48
```

## Section header (`hkPackfileSectionHeader`, 48 bytes)

`CONFIRMED_BYTES`.

| Offset | Type | Field |
|---|---|---|
| 0 | char[19] | SectionTag, null-padded |
| 19 | uint8 | `0xFF` pad |
| 20 | int32 | AbsoluteDataStart |
| 24 | int32 | LocalFixupsOffset |
| 28 | int32 | GlobalFixupsOffset |
| 32 | int32 | VirtualFixupsOffset |
| 36 | int32 | ExportsOffset |
| 40 | int32 | ImportsOffset |
| 44 | int32 | EndOffset |

Offsets are relative to the section's `AbsoluteDataStart`, and each "offset" doubles as the end of
the preceding region, so region sizes are successive differences. `DataSize == LocalFixupsOffset`.

### Section tag truncation

`CONFIRMED_BYTES` for the bytes; `HYPOTHESIS` for the cause. Tags are capped at 19 bytes. Names that
would collide once truncated carry a numeric suffix in the shipped data:

```
chemical200249441      (probably "chemicalthrower…")
grenadel1663367201     (probably "grenadelauncher…")
scripted2306259077
```

The suffix looks like a hash of the untruncated name. Not relied upon anywhere in code.

## Class-name table

`CONFIRMED_BYTES`. The `__classnames__` section is a sequence of:

```
uint32   type signature
uint8    0x09 separator
char[]   ASCIIZ class name
```

The offset recorded per class is the offset of the **text**, which is what the header's
`ContentsClassNameSectionOffset` and the virtual fixups reference.

Classes observed in the first-person hands package:

```
AnimationPackageRoot          <- 2K-specific; see animationpackage.md
hkaSkeleton
hkaAnimationBinding
hkaSplineCompressedAnimation
hkClass, hkClassEnum, hkClassEnumItem, hkClassMember
```

Notably **absent**: `hkRootLevelContainer`. A whole-package scan of `1-Medical.bsm` found zero
occurrences of that string against 46 occurrences of `hkaSplineCompressedAnimation`. BioShock
replaces the stock root container with its own, which is exactly why generic Havok tooling fails.

## Compression

`hkaSplineCompressedAnimation` is the game's dominant — and, whole-game, only — animation class; see
[havok-compression.md](havok-compression.md) for the format, the quantisation census, and the block
layout. That file is now the canonical home for this fact; kept here only as a pointer.

## What is implemented

Everything this file's earlier "not yet implemented" list named is now decoded, elsewhere in this
directory — this section is a container-format reference, not a status page:

- Packfile detection inside arbitrary buffers, byte-granular; header and section headers;
  class-name table; root class resolution (this file).
- Fixups (local/global/virtual) — [open-questions.md](open-questions.md) item 2.
- Spline decompression — [havok-compression.md](havok-compression.md).
- `hkaSkeleton` / `hkaAnimationBinding` — [animationpackage.md](animationpackage.md),
  [binding.md](binding.md).
- Object graph reconstruction (walking the fixups to real objects) —
  [havok-physics.md](havok-physics.md), [root-motion.md](root-motion.md).
