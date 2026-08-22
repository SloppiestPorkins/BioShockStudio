# StaticMesh

**Implementation:** `src/BioShockStudio.Core/Mesh/StaticMeshReader.cs`
**Tests:** `tests/BioShockStudio.Tests/StaticMeshGeometryTests.cs`, `StaticMeshExportTests.cs`,
`StaticMeshRenderingTests.cs`
**Status:** geometry decoded, exporting to scene JSON and FBX, drawing in the viewport.

8,668 `StaticMesh` exports ship across the 21 map packages and `ShockGame.U`. **All 8,668 decode.**

A static mesh is what hangs off a socket. The Bouncer's drill, its cage and its backpack; Baby
Jane's wig; the photo and wallet in the first-person hands; the wrench, which has no moving parts
and so ships as a prop rather than a rig. Until this reader existed those relationships resolved and
nothing could be drawn.

## Payload

`CONFIRMED_BYTES`.

The export begins with a real property list — unlike a `SkeletalMesh`, whose list is empty — holding
`Materials` as an array. After it comes a header of variable length, then the geometry chain.

```
+8   property list          Materials (array); ends around 44
     ...                    variable-length header
     FBox                   bounds min (float3), bounds max (float3)
     byte                   bounds valid flag
     FCompactIndex vertexCount
     vertexCount x 48       position, tangent, binormal, normal   (float3 each)
     FCompactIndex streamCount                                    UV streams: 1, 2 or 3 observed
       per stream:  FCompactIndex uvCount    always == vertexCount
                    uvCount x 8              u, v
                    int32                    stream ordinal, 0 for the first
     FCompactIndex indexCount
     indexCount x uint16    triangle indices
     ...                    collision tree, not read — see below
```

For `ConeDrill` in `1-Medical`: 561 vertices at offset 146, one UV stream, 1,686 indices
(562 triangles) at 31,571, and 16,417 bytes of tail.

### Differences from the skeletal container

| | `SkeletalMesh` | `StaticMesh` |
|---|---|---|
| Property list | empty | holds `Materials` |
| Bone map | `uint16` array | none |
| Vertex stride | 64 skinned / 57 rigid | 48, one block |
| UVs | inside the vertex record at +48 | separate streams after the vertices |
| Skin weights | four interleaved influences | none |
| Vertex blocks | two, index buffer addresses rigid first | one, no ordering trap |
| Tag block | int32 4, int32 5, byte 1 | int32 4, int32 **8**, int32 1 |

The tag block's second field appears to distinguish the two containers.

## Vertex format

`CONFIRMED_BYTES`. 48 bytes, and **no UV** — that is the part that breaks a reader written by
analogy with the skeletal format:

```
+0   float3   position
+12  float3   tangent
+24  float3   binormal
+36  float3   normal
```

**Any one of the three basis vectors may be degenerate.** `Turret_Cover` ships vertices whose
tangent and binormal are `(-0.0039, -0.0039, -0.0039)` with a good normal; `LS_Hat` ships the
reverse, a good tangent and binormal with a null normal. Requiring all three to be unit length —
which is what the skeletal reader does — drops 33 of the 610 meshes in `1-Medical` alone. The reader
therefore requires only that each sampled record carries **one** unit vector among the three.

## UV streams

`CONFIRMED_BYTES`. The stream count is an `FCompactIndex`, and each stream is a full-length array
followed by an `int32` that equals the stream's own ordinal.

| Streams | Meshes |
|---|---|
| 1 | 7,989 |
| 2 | 661 |
| 3 | 18 |

A `MeshVertex` carries one UV, so only the first stream reaches the export. The rest are counted
into `MeshGeometry.ExtraUvStreamCount` and reported in the details panel, rather than being dropped
silently — a mesh with a lightmap channel should not look like a mesh that never had one.

## Locating the chain

The header ahead of the geometry is not a fixed length: the vertex count sits at offset 144 on 337
of `1-Medical`'s meshes, at 142 on 94, at 152 on 65, at 181 on 36, and at a dozen other offsets
besides. So the chain is found by search, with every constraint required to hold at once:

- the UV stream is exactly as long as the vertex array;
- the index count is a whole number of triangles;
- the largest index is exactly `vertexCount - 1`;
- every sampled vertex carries at least one unit basis vector;
- **every decoded position falls inside the `FBox` stored immediately before the vertex count.**

The last one is the evidence. That box is never consulted while searching — it is read back
afterwards and used to accept or reject the candidate — so its agreeing with the geometry is an
independent statement that the block found is the mesh's own. Across all 8,668 shipped meshes the
worst overshoot is **0.0 units**.

Unlike the skeletal bounds, which cover the animated range and so sit well outside the bind pose,
a static mesh's box is a true hull of its vertices.

## Result

| Mesh | Vertices | Triangles |
|---|---|---|
| `ConeDrill` | 561 | 562 |
| `ConeDrillCage` | 617 | 924 |
| `ConeDrillBackpack` | 2,199 | 2,638 |
| `WP_WrenchMesh` | 3,153 | 3,696 |
| `Ammo_Pickup_Kerosene` | 3,265 | 3,641 |

All render as recognisable objects — the drill as a conical auger, the backpack as a banded tank,
the kerosene pickup as a canister with a valve wheel, hose and cage. Rendering was not optional:
this project has had numeric validation pass on visibly wrong geometry before.

## Export

A static mesh has no skeleton, so `AnimationSceneExporter.BuildStatic` produces a scene with an
empty bone list, no animations and no sockets, and `FbxSceneBuilder` writes no skin deformer for it.
Inventing a root joint so the file resembled the skinned exports would put a bone in the output that
the game does not have.

For the same reason the preview does **not** show the group's skeleton next to a selected static
mesh. The drill belongs to `NewProtectorBouncer` and hangs off a socket on its rig, but the two are
not bound, and drawing them in one space would imply they were.

## Still unknown

- **The tail.** Every mesh carries a large trailing block — 16,417 bytes on `ConeDrill`, over a
  megabyte on the largest — beginning with an `int32` and an `FCompactIndex` node count, then what
  look like 32-byte records of `FBox` plus two `uint16`. Almost certainly the kDOP collision tree.
  Not needed for geometry and not read.
- **The variable-length header.** Located by search rather than understood, exactly as with
  `SkeletalMesh`.
- ~~**LODs.** Whether further vertex blocks follow the tail has not been checked.~~ **Checked, 22 Aug
  2026 — there are none.** Across every shipped map, **8,668 static meshes yield 8,668 geometry
  chains: exactly one each**, with no mesh carrying a second. `StaticMeshLevelOfDetailTests` pins the
  census, and `StaticMeshReader.LevelsOfDetail` exposes the chains so the question can be re-asked
  rather than re-argued.

  **This also corrects the reader.** `TryLocateGeometry` scans past each chain and keeps the densest,
  under a comment asserting that "a payload holds several levels of detail" — it never has to choose,
  on any mesh in the game. The rule is kept (it costs nothing and would decode a second block at the
  right detail rather than the stored-first one) but the claim behind it was describing a container
  this game does not ship. **BioShock Remastered's static meshes are single-LOD**, which is worth
  knowing before a UE5 bridge is built expecting an LOD chain to carry across.

  **What it does not rule out:** a cruder level stored in a *different vertex format* would not
  satisfy the constraints this search uses and would not be found. Five independent constraints
  agreeing 8,668 times is strong evidence, not proof of absence.

## The section table — found via Nyko's SDK, verified here

`CONFIRMED_BYTES`. **This is the missing piece for multi-material meshes**, and it was found by
reading Nyko's `Bioshock1REMSDK-WIP--main/bioshock1-bsm.md` §C.4 rather than from these bytes.

A `UStaticMesh` carries a section table **before** the vertex block:

```
CI     NumSections
per section, 14 bytes:
    int32  f4            always 0   (UE2.5's IsStrip)
    uint16 FirstIndex
    uint16 FirstVertex               (UE2.5's MinVertexIndex)
    uint16 LastVertex                (UE2.5's MaxVertexIndex)
    uint16 fE                        alias of NumFaces on some paths
    uint16 NumFaces                  (UE2.5's NumTriangles / NumPrimitives)
25 B   FBox bounding box             serialized a second time
CI     NumVerts ...
```

A section is a run of the index buffer, and **the Nth section uses the Nth entry of the object's
`Materials` array**. That is what this project could not answer: 28 meshes name two or three
materials and are textured from the first only, because nothing said which triangles belong to
which.

Verified against Remastered bytes, reading backwards from the vertex block this reader already
locates, on meshes whose geometry was decoded independently:

| mesh | our decode | section says |
|---|---|---|
| `ConeDrill` | 561 verts, 1,686 indices | `NumSections 1`, `lastVertex 560`, `numFaces 562` |
| `Turret_Cover` | 45 verts, 72 indices | `NumSections 1`, `lastVertex 44`, `numFaces 24` |

`lastVertex` is exactly `vertexCount − 1` and `numFaces` exactly `indexCount / 3` on both, with
`f4`, `FirstIndex` and `FirstVertex` all zero as documented. Two independent fields agreeing with a
separately-decoded mesh is not a coincidence.

**Implemented.** `StaticMeshReader.ReadSections` reads the table backwards from the bounding box the
geometry search already locates, because the header ahead of the geometry is not a fixed length. A
candidate is accepted only when the compact count lands exactly on the start of the array, the
sections tile the index buffer in order from zero, every section stays inside the vertex array, and
the tiling accounts for **every** index. Anything else and the mesh reports no sections and is drawn
as before — nothing is invented.

`StaticMeshSectionTests` holds it: the two meshes above field by field, and a game-wide sweep
asserting that every table that does resolve tiles its own index buffer exactly, over more than
5,000 meshes, with the check refusing to pass vacuously.

### Consumed — the sections now choose the material

`CONFIRMED_BYTES` for the layout, `CORROBORATED` game-wide for the pairing.

`MeshSurfaceResolver` is the single place that pairs section *N* with `Materials[N]`. The preview,
the scene JSON, the FBX exporter and the Blender importer all go through it, so none of them can
form its own opinion about what a mesh looks like.

**The evidence for the pairing is now much stronger than the two meshes it was found on.** The
section table is read *backwards* from the geometry block that the geometry search located; the
`Materials` array is read *forwards* as an ordinary tagged property from offset 8. Neither reader
consults the other. Across **all 8,668 shipped static meshes the two counts are equal, with no
exceptions** — 1,179 of them declaring more than one section. Two independently-decoded structures
agreeing that many times is not a coincidence, and `MeshSurfaceTests` pins it.

| | |
|---|---|
| Static meshes decoded | 8,668 |
| With a section table | 8,668 |
| More than one section | 1,179 |
| Sections == material slots | **8,668 / 8,668** |
| Material slots declared | 10,198 |
| Slots resolving to a material | 10,158 |
| Empty or unreadable slots | 40 |

**A material slot may be empty, and an empty slot must keep its position.** Getting this right is
what took the count agreement from 8,632 to 8,668. Two distinct causes, both real:

- **A declared null.** `3-Arcadia/ad_01` declares two elements and the second's `Material` is an
  `Object` property with an *implicit* size and a null reference — a real, empty, second slot:
  ```
  02                                            count = 2
  5D02 00000000 D3 00                           EnableCollision (Bool, value in the array bit)
  37   00000000 55 03 7FD705                    Material -> 46591  ad_frame_shader
  00   00000000                                 None
  5D02 00000000 D3 00                           EnableCollision
  37   00000000 05 00                           Material, implicit size 1, reference 0  <- empty slot
  00   0000                                     None, cut short by the array's declared size
  ```
- **A reference cut off by the array's one-byte-short size.** `5-Hephaestus/Bomb` declares 7 and its
  seventh `Material` reference loses its last byte. The slot exists — the count says so — but its
  value cannot be read.

The reader therefore builds a list exactly `count` long and fills what it can, leaving anything
unread as null. **It never closes the list up**, because compacting shifts every later section onto
the wrong material. `ReadMeshMaterialSlots` returns that slot-ordered list;
`ReadMeshMaterialReferences` is the compacted view, and must not be indexed by a section ordinal.

The 13 meshes that used to disagree — `Bomb`, `DLC_Com_Door`, every `ad_01` and `ad_large` — all
agree now, which was a falsifiable prediction of the reading above rather than a fitted result.

Verified by rendering as well as by count: the Bathysphere (`bat_vehicle`, 8,200 hull faces +
88 lamp faces) draws a verdigris copper hull with its lamp housings in a different pale metal, and
`CityGate` (560 / 64 / 1,776) draws grey granite, blue-glass-and-brass lamp columns and a darker
gate as three visibly different surfaces. `Static_Snapshot` renders all three.

### Where Remastered diverges from the original game

`CONFIRMED_BYTES`, and worth recording because it is a real difference from the prior art rather
than a mistake on either side. Nyko's spec — cross-validated against UEViewer's
`UnMeshBioshock.cpp` — documents a **24-byte** vertex: `FVector` position plus three
`FPackedNormal` DWORDs. Remastered uses **48 bytes**: position plus three full `FVector` basis
vectors, which is what this reader has always read and what all 8,668 shipped exports decode with.
The section table's `lastVertex` confirms the vertex *count* independently, so the stride is not in
doubt. Anyone porting a finding from UEViewer or from the original game must expect the vertex
record to have been widened.
