# SkeletalMesh

**Status:** not implemented. This document records the reconnaissance done so far so the work starts
from evidence rather than from scratch.

962 `SkeletalMesh` exports ship across the 21 packages, 46 of them in `0-Lighthouse.bsm`.

## Candidate first targets

`CONFIRMED_BYTES`. Smallest instances in `0-Lighthouse.bsm`, which are the right place to start
rather than the 777 KB hands mesh:

| Object | Payload |
|---|---|
| `FireSpread_Mesh` | 4,170 |
| `PlayerCameraAnim` | 4,318 |
| `GrenadeFuse_Mesh` | 6,504 |
| `IcePileOp` | 7,479 |
| `NEWPlayerHands` | 777,635 |

## Shared 2K payload header

`CONFIRMED_BYTES`. `SkeletalMesh` and `AnimationPackageWrapper` payloads begin with the same
18-byte prefix:

```
04 00 00 00  03 00 00 00  04 00 00 00  00 22  cd cd cd cd
```

The `cd cd cd cd` filler is characteristic of uninitialised MSVC debug heap memory, which suggests a
serialised struct with padding rather than a meaningful field. This partly answers the question of
what sits ahead of the Havok magic in an `AnimationPackageWrapper`: the first 18 bytes are this
shared header, leaving 16 bytes still `UNKNOWN` before the packfile begins at offset 34.

## Bounds

`LIKELY`. Immediately after the shared header, `NEWPlayerHands` reads as a bounding volume:

```
min   (-16.000, -67.902, -64.000)
max   (120.000,  67.902,  23.330)
flag  0x01
radius 42.83
```

That is a plausible `FBoxSphereBounds` for a first-person arms mesh in the same centimetre space as
the skeleton, whose root sits at x = 14.4. Not yet parsed in code, and not relied upon.

## What is not known

Everything past the bounds: vertex buffers, index buffers, LOD chunking, material sections, bone
maps, skin weights, and the link from the mesh to its skeleton. `HkMeshProxy` (8,961 instances) is
the most promising candidate for that last link and has not been examined.

## Validation plan

Per the project's testing rule, none of this becomes a parser without byte evidence:

1. Start with `FireSpread_Mesh`, the smallest instance.
2. Cross-check vertex and bone counts against UEViewer where it succeeds on the same asset.
3. Validate skin-weight bone indices against the already-decoded skeleton — indices must land inside
   the bone array and weights must sum to 1.
4. Validate bounds against the vertex positions actually decoded.
