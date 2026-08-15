# Bulk content

**Implementation:** `src/BioShockStudio.Core/Textures/BulkTextureCatalog.cs`
**Tests:** `tests/BioShockStudio.Tests/BulkTextureTests.cs`
**Status:** catalogue decoded, stripped mips recovered and verified against the shipped ones.

Most of BioShock's textures are not in its packages. They ship with their top mip levels removed —
the packages carry the tail of the chain — and the removed levels live in
`ContentBaked/pc/BulkContent`: 201 `BulkChunk*_*.blk` files, about 8 GB, indexed by a
`Catalog.bdc` of 516,961 bytes.

## A texture says it has been stripped (CONFIRMED_BYTES)

`ChemThrow_Pickup_Kero_Diffuse` in `1-Medical`:

| Property | Value |
|---|---|
| `USize`, `VSize` | 2048, 2048 |
| `UBits`, `VBits` | 11, 11 |
| `HasBeenStripped` | true |
| `StrippedNumMips` | 5 |
| `MinLOD` | 5 |
| `CachedBulkDataSize` | 0 |
| Mips in the package | 5, topping out at **64x64** |

2048 down five levels is 64, which is exactly what the package holds. A texture that was *not*
stripped — `Hand_DIFF`, one of eleven at 2048 in its package — has no `HasBeenStripped` and no
`StrippedNumMips`, and carries `bStreamable` instead.

**Scale of it:** in `1-Medical`, of ~1,937 textures, **1,639 top out at 64 square**. Eleven are 2048
and thirteen are 1024. Before this was read, the tool drew the bottom of the mip chain for most of
the game and there was no way to tell from inside a package that anything was missing.

`CachedBulkDataSize` is zero and there is no offset in the texture object: the addressing is all in
the catalogue.

## Catalog.bdc (CONFIRMED_BYTES)

```
23 bytes                        header, UNKNOWN
per chunk:
  FString  chunk file name      "BulkChunk0_0.blk"
  byte                          UNKNOWN, 0x17 on the first
  per texture:
    FString  texture name       "HarvestSlugFish_Diff"
    FString  group name         "HarvestSlugfish"
    int32    zero
    int32    offset into the chunk
    int32    size
    int32    the same size again
    int32    index
```

An `FString` here is a **byte** unit count followed by that many UTF-16 units, the last a null
terminator — so `0x11` introduces 17 units, which is `BulkChunk0_0.blk` plus its terminator.

5,777 entries across all 201 chunks.

### Why this reading is trusted

Two invariants hold across every single entry, and neither is something a misparse produces:

- **Every offset is a multiple of 32,768.** 5,777 of 5,777.
- **Every size is exactly the sum of a run of mip levels** for a square power of two. 5,777 of
  5,777. `2,793,472` is precisely DXT1 at 2048 + 1024 + 512 + 256 + 128; `696,320` is DXT1 at
  1024 + 512 + 256 + 128.

### And the images match

Sizes adding up proves the record layout, not that the bytes belong to the texture whose name is
attached — a wrong offset into 8 GB can still be the right *number* of bytes.

What settles that is the seam. The last level recovered sits directly above the first level the
package already had, so halving it should reproduce that level. Across `1-Medical`, **1,526 of 1,530
recovered textures agree to under 10%**, and typical agreement is **1–2%**, which is DXT
quantisation noise rather than a difference. `ChemThrow_Pickup_Kero_Diffuse` agrees to **1.67%**.

The reader will not splice anything that fails either check: the blob's size must decompose into an
exact chain, and the chain's last level must be exactly twice the width of the package's own top
mip.

## `StrippedNumMips` is not reliable; the size is

Deriving the chain from `StrippedNumMips` recovers only 542 of `1-Medical`'s 1,539 stripped
textures. Deriving it from the blob size — find the run of levels that adds up to it exactly —
recovers **1,530**. The property is right on about a third of textures and the arithmetic is right
on all of them, so the arithmetic is what the reader uses.

## Result

`1-Medical`: 1,530 of 1,539 stripped textures restored to their declared size. The nine that are not
have a size that does not decompose against their declared dimensions, and are left as they shipped
rather than guessed at.

## The group name is load-bearing — it is not descriptive

`CONFIRMED_BYTES`. **This note used to say the group was probably only descriptive, "because the
packages repeat the same art rather than varying it". That was wrong**, and it produced one of the
most visible faults in the tool.

A texture name is not unique across groups, and the duplicates are **different art**:

| | |
|---|---|
| Catalogue entries | 5,777 |
| Distinct names | 5,622 |
| Names appearing in more than one group | **112** |
| …of those, pointing at different bytes | **112 — all of them** |

Not one of the 112 is a duplicate copy. Resolving a name without its group therefore silently picks
another group's texture, and it did so on **340 of the game's 30,831 texture exports**.

The clearest case is the final boss. `Atlas_Diffuse` exists twice, in the same chunk 2.8 MB apart:

```
Atlas_Diffuse   Gen_Graffiti  BulkChunk1_41.blk +37781504  2793472    the "ATLAS IS WATCHING" wall decal
Atlas_Diffuse   Atlas         BulkChunk1_41.blk +40599552  2793472    the boss's skin
```

Both are 2048×2048 DXT1 with identical sizes, so **every check the reader has passed on the wrong
one** — the offset is 32,768-aligned, the size decomposes into an exact mip chain, and the seam
lands exactly on the package's own top mip. `Atlas_MESH` rendered as a black figure with white paint
strokes over it, which reads as a shader or lighting fault and is neither.

### Where the group comes from

The export's own **outer**. It resolves to a catalogue group for **24,950 of the 30,831** texture
exports, and it is the package stating the group rather than anything inferred.
`TextureReader.Read` takes it from there when a caller does not supply one, so the preview, the
extraction service, the material exporter and the CLI all get it without knowing about any of this.

`BulkTextureCatalog.Find` still falls back to the first candidate when the group matches nothing —
a texture whose outer names no group has to resolve to something, and for the 5,510 unambiguous
names it is the only candidate anyway.

Pinned by `BulkTextureGroupTests` against real bytes: that the catalogue really does hold different
art under one name, that the boss resolves his own skin and not the graffiti, and that game-wide no
texture whose outer names a group resolves to a different one.

## Still unknown

- The 23-byte header, and the byte between a chunk's name and its first entry.
- The nine textures per package whose size does not decompose.
- 46 texture exports carry **no `Format` property at all**, and all 42 of their distinct names are
  editor sprites (`S_Actor`, `S_Camera`, …) or engine placeholders (`DefaultTexture`,
  `WhiteTexture`, `MaterialBackdrop`). Whether they are meant to hold pixels is `UNKNOWN`; their
  payloads run 438 to 22,267 bytes and none has been hand-decoded. They are the whole of what
  `diagnose` still reports as `texture-undecodable`.

## Pixel formats, and the one that took two sources to settle — CLOSED

`CONFIRMED_EXTERNAL` and `CONFIRMED_BYTES`. The `Format` property is a byte holding an
`ETextureFormat` ordinal. Four were established here by measuring bytes per pixel; the fifth came
from the reference projects and is the reason
[reference-comparison.md](reference-comparison.md) exists.

| ordinal | format | bytes for `w × h` | state |
|---|---|---|---|
| 3 | DXT1 | `ceil(w/4)*ceil(h/4)*8` | decoded |
| 5 | RGBA8 | `w*h*4` | decoded, stored BGRA on disk |
| 7 | DXT3 | `ceil(w/4)*ceil(h/4)*16` | decoded |
| 8 | DXT5 | `ceil(w/4)*ceil(h/4)*16` | decoded |
| **12** | **DXT5N** — the game *calls* it 3DC | `ceil(w/4)*ceil(h/4)*16` | **decoded** |

Nyko's texture note lists ordinals 0, 2, 6, 9, 10 and 11 as well (P8, R5G6B5, NODATA, A8, A16,
ABGR16F). **None of them appears on any shipped texture** — the census of undecodable exports found
only ordinal 12 and the property-less sprites — so they are recorded here and deliberately **not**
added to the enum, which is what gates the reader.

### Ordinal 12 is DXT5N, not 3DC/BC5

The two reference projects disagree. Nyko's note says "3DC — BC5/ATI2, two BC4 alpha blocks giving R
and G". UModel's BioShock branch remaps it: `Format = TEXF_DXT5N`, commented *"Bioshock used 3DC
name, but real format is DXT5N"*, and nvtt then rebuilds the normal from `(alpha, green)` rather than
`(red, green)`.

**The bytes side with UModel**, and the check is an invariant rather than a preference:

| | as BC5 | as DXT5N |
|---|---|---|
| X (red) mean | 127 | 127 |
| **Y (green) mean** | **57** | **128** |
| Z (blue) mean | 209 | 252 |
| texels with `x² + y² > 1` | many | **0 of 4,096** |

A tangent-space normal map's X and Y both centre on 128 and every texel is a unit vector. Read as
BC5, the second half of the block — which is really the DXT5 colour block — is parsed as a BC4
endpoint pair, and the image comes out magenta. `NormalMapFormatTests` asserts the invariants, so it
fails on the wrong reading rather than merely describing the right one.

**274 exports, 64 distinct names, every one a normal map.** They decoded to nothing before this, so
every mesh using one had no normal map at all.
