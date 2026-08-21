# BSP — `Model` and `Polys`

**Implementation:** `Core/Level/BspPolys.cs`, `BspWorld.cs`, `BspGeometry.cs`, `ModelReader.cs`
**Tests:** `BspGeometryTests.cs`, `BspWorldTests.cs`, `BspUvTests.cs`, `BspRenderingTests.cs`, `ModelReaderTests.cs`
**Status:** **Both containers are `CONFIRMED_BYTES`** — the designer's source brushes
(`Polys`/`FPoly`, §2) and the compiled world (`Model`'s node tree, §5). What is still not read is
lightmaps (§5.5) and CSG.

This is the container 230 actors in `0-Lighthouse` reference and nothing decoded, and the same one
`AtlasLabsDoorAnim` ships in place of a drawable mesh (HANDOFF §6.2).

**There are two different things called BSP here and confusing them wastes a session:**

| | what it is | where | state |
|---|---|---|---|
| **Source brushes** | the designer's convex solids, as authored | a `Polys` export per brush | **decoded, §2** |
| **The compiled world** | the built level — nodes, surfaces, a vertex pool, lightmaps | inside one large `Model` export | **decoded, §5** (lightmaps are not) |

**The compiled world is the one that matters for looking at a level.** It holds the floors, walls
and ceilings a player stands on; the source brushes are what the designer drew before CSG. A level
carrying only the brushes and the placed meshes reads as a skyline and props with the rooms missing,
which is exactly how it looked before §5 was implemented.

`0-Lighthouse` ships **285 `Model` exports and 285 `Polys` exports**. 284 of the models are about
1,700 bytes — the source brushes — and **one, `Model1`, is 312,400 bytes**: the built world. On
`1-Medical` the built world is 8.6 MB. The size distribution is what separates them, and it is not
subtle.

---

## 1. Where this came from

**`Unreal-Library-master` and `Bioshock1REMSDK-WIP--main`, in that order**, before any byte was
guessed. That is project policy (`ENGINEERING_RULES.md` §60) and it paid again:

- **UELib** supplied the field list for `UPolys` and `FPoly` with version gates. Resolving every
  gate against this game's file version — **142** — gave a candidate layout that was one field wrong.
- **Nyko's SDK** then supplied the whole thing independently, including the correction, plus the
  entire built-world layout that this project had recorded as `UNKNOWN`.

`Unreal-Library-master` was listed in the handoff as the one reference project **entirely unmined**.
It is now the source of a finding. Of Nyko's `bioshock1-bsm.md`, only §C.4 had ever been read;
§C.1, §C.2, §C.5 and §C.6 were all unopened and all four are directly about Phase 2.

---

## 2. `UPolys` — the source brushes. `CONFIRMED_BYTES`

```
UPolys:  [Vengeance object header + tagged property list]
         int32 Num
         int32 Max
         FPoly[Num]
```

`Num` and `Max` are **raw int32, not `FCompactIndex`** — unusual in this container format and
confirmed by both references and by the bytes.

**`UPolys` has no Vengeance class header of its own.** UModel (sv=7) and UStaticMesh (sv=8) do;
`UPolys` does not, so the property list is followed immediately by `Num`.

### 2.1 `FPoly`

```
FCompactIndex  NumVertices            // version < 227 stores a count, not an array
FVector        Base, Normal, TextureU, TextureV     // 4 × 12 bytes
FVector        Vertex[NumVertices]
uint32         PolyFlags
FCompactIndex  Actor                  // object reference
FCompactIndex  Material               // object reference
FName          ItemName               // FCompactIndex index + int32 number
FCompactIndex  Link                   // FBspSurf index, or -1
FCompactIndex  BrushPoly              // source brush polygon index, -1 in shipped data
float          LightMapScale          // version >= 106 and < 300
```

**The one field UELib's version gates got wrong, and why.** UELib reads `ItemName` as a bare name
index. This game writes an `FCompactIndex` **plus a four-byte number**, and that is not a
BioShock oddity — it is the same shape `PropertyValues.AsName` already reads for every `Name`
property in the package. Nyko's §C.2.2 gives the reason: in-memory `sizeof(FPoly)` is `0x14C` here
against UE2.5's `0x148`, and the extra 4 bytes are exactly this widening, applied by the linker's
`FName` operator when `Ar.Ver() >= 141`.

**Found from the bytes before the reference confirmed it.** The tail of a polygon is 17 bytes and
`PolyFlags(4) + 3 single-byte indices + Link(1) + BrushPoly(1) + LightMapScale(4)` is 13. The
missing 4 is the number field. `BrushPoly` decoding as `0x81` = −1 and `LightMapScale` as
`0x42000000` = 32.0 — UELib's documented default — is what identified the tail from the other end.

### 2.2 What makes this a decode rather than a fit

**The walk must consume each export to its exact final byte.** A wrong field list cannot land on the
boundary across exports whose polygon counts, vertex counts and sizes all differ, because every
surplus or missing byte accumulates.

| | measured |
|---|---|
| Map packages containing brushes | **21 of 161** |
| `Polys` exports walked | **16,926** |
| …landing on the exact final byte | **16,926 (100%)** |
| Polygons | **93,264** |
| Vertices | **374,372** |

`BspGeometryTests.EveryPolysExportInEveryMapWalksToItsExactEnd` sweeps all 21 map packages, not one
— HANDOFF §7 rule 3, "a parse that looks right once is not a result".

**Cross-check against Nyko, who counted independently:** Lighthouse 284/284 exports and 1,687
polygons, against this project's **285 and 1,717**. The difference is one export — this project
counts a `Polys` with **zero** polygons that Nyko's figure appears to exclude — and one 30-polygon
brush. Not reconciled; recorded because an unexplained difference is worth more written down than
rounded away. Note also that Nyko's doc says "Bioshock = 141" where this project's packages report
file version **142**.

### 2.3 The material field — `CONFIRMED_BYTES`, and it was worth checking

`Actor` and `Material` are adjacent object references and the arithmetic constrains only the total
size of the group, not the order within it — `Actor` is **null in all 93,264 shipped polygons**, so
no decoded value distinguishes them. The discriminator is what the non-null one resolves to:

| the second reference resolves to | count |
|---|---|
| `Shader` | 42,772 |
| `Texture` (7,579 export + 8,774 import) | 16,353 |
| `FluidShader` | 249 |
| `MaterialSwitch` | 101 |
| `LayeredShader` | 16 |
| `FluidSurfaceShader` | 4 |
| **an actor class** | **0** |

**59,495 of 93,264 polygons name a material and every one of them is a material class.** That is a
positive measurement rather than an argument from silence, and it agrees with UELib's field order
and Nyko's §C.2.2 independently. `BspGeometryTests.EveryMaterialAPolygonNamesResolvesToAMaterialClass`
holds it.

**So a brush carries its own surface.** Brush geometry can be textured by the same material resolver
the meshes use rather than drawing bare, which is more than the actor layer knew.

---

## 3. Winding — BSP is the opposite of the meshes. `CONFIRMED_BYTES`

**This is the part most likely to be got wrong by reasoning quickly, so it was measured twice by
independent means.**

`ANIMATION_COORDINATE_SYSTEM.md` §6 establishes that the game's **meshes** are front-face clockwise:
their shipped triangle winding disagrees with their shipped normals, the basis reflection negates
that agreement, and therefore the index buffer must be **left alone**. Brushes are the other way
round.

| measured over all 21 maps | agree | disagree |
|---|---|---|
| shipped vertex order vs the polygon's own `Normal`, after conversion | **0** | **93,264** |
| the fan `Triangles()` emits vs the same `Normal` | **93,264** | **0** |

Since the reflection negates agreement, the game's own brush data **agrees** — Unreal computes an
`FPoly`'s normal from its stored vertex order with its own left-handed cross product, so the two
agree by construction. Meshes carry authored per-vertex normals instead, which is why the two
containers differ.

**Measured with the Newell normal, not a single cross product.** The first attempt used
`(B−A)×(C−A)` on the first three vertices and put **4 of 93,264 polygons** on the wrong side of the
answer — all slivers whose first three vertices are nearly collinear, so the probe was reading its
own numerical noise. Newell sums every edge and the result is unanimous.

### 3.1 Confirmed a second way, by enclosed volume

The divergence theorem gives a closed surface's volume from its faces alone, and the sign is
positive **only** for consistently outward winding. On `0-Lighthouse`'s 285 brushes:

| | |
|---|---|
| Enclosing a **positive** volume | **254** |
| Enclosing a **negative** volume | **0** |
| Sheets (fewer than 4 faces — Nyko documents single-poly brushes as real content) | 27 |
| Closed-surface check still failing | 4 |

Two independent properties — normal agreement and volume sign — give the same answer, so the
reversal in `BspPolygon.TriangleIndices()` is not a fudge fitted to one metric.

**The shipped vertex order is never altered.** `Vertices` is what the package holds; only the fan
projection is wound. The reversal lives in exactly one method so a consumer cannot undo it by
building its own fan.

### 3.2 A trap this check walked into first

The closure test originally compared vertex positions **bit-exactly** and reported 88 of 285 brushes
as open. That was the check's own artefact: a brush corner is where three authored planes meet and
is evaluated per face, so the same corner arrives with different values on each face. In the first
brush inspected, one face's two "equal" Z values are `-219.98438` and `-220.0` — **0.016 apart**, far
coarser than float noise suggests. A rounding bucket at two decimal places was still too fine. It is
a tolerance search at 0.05 cm now, checking neighbouring cells so a pair straddling a boundary still
welds, and the residual is 4 rather than 88.

---

## 4. UVs — texels, not normalised. `CONFIRMED_EXTERNAL`

An `FPoly` parameterises its surface with `Base`, `TextureU` and `TextureV`:

```
u = dot(vertex − Base, TextureU)
v = dot(vertex − Base, TextureV)
```

and the engine **divides by the bound texture's own dimensions**. Nyko's editor does exactly this
and does it at upload time (`viewport.cpp`: `invW = 1.0f/texW; v.u *= invW`), which is what confirms
the two-stage shape rather than a single baked value.

The same applies to a compiled surface, except that its origin and axes are *indices* into the
model's points and vectors rather than being carried on the polygon.

`BspGeometry.ToGeometry` emits the projection in **texels** and says so; `NormaliseUvs` divides,
once the material has resolved and the dimensions are known. The split is deliberate: the geometry
layer does not resolve materials, so it cannot know the sizes and does not invent them.

> **The division was written and then never called, and a user found it by looking at the render.**
> Every BSP surface in the game drew with UVs in texel space — a 512-pixel texture on a wall tiling
> 512 times — producing a dense moiré, while the static meshes beside them looked perfect because
> their UVs come from their own vertex data and never went through this path.
>
> **Nothing in the suite could see it.** Counts agreed, surfaces bound textures, and the
> textured-vs-untextured comparison passed at 51% — a wrong UV *scale* is still a texture reaching
> every pixel. `BspUvTests` measures the quantity itself now: raw brush UVs peak at **348,160**, and
> after normalisation the median is **0.68** with the 90th percentile at **1.0**. It also asserts
> the *premise* — that the raw values are large — so that normalising twice, which would shrink
> every surface to a single texel, fails rather than merely looking odd.

**`TextureU` and `TextureV` are zero on some polygons** — the first brush in `0-Lighthouse` has all
four axes zero — so a zero UV is real data, not a decode failure.

**Counted, across every shipped map: 17,802 of 93,264 brush polygons (19.1%) carry no texture axes**,
and the two axes are always absent *together* — no polygon carries half a parameterisation. **None of
the 17,802 names a material.** So the brush set has no polygon that would be drawn with a collapsed
UV: missing axes and missing texture are the same polygons, which is what makes this content rather
than a decode gap. `BspGeometryTests.HowManyBrushPolygonsCarryNoTextureAxesIsCounted`, which asserts
both halves.

---

## 5. `Model` — the compiled world. `CONFIRMED_BYTES`

**Status: `CONFIRMED_BYTES`.** Nodes, surfaces and the vertex pool are decoded and drawn;
`BspWorldReader` reads them and `BspGeometry.ToGeometry(world)` triangulates them.

### 5.-1 What it measures

| | measured across all 21 maps |
|---|---|
| Compiled worlds read | **21** |
| Polygons | **81,566** |
| Triangles | **227,911** |
| Polygons more than 1 cm off their own plane | **12 of 81,566 (0.015%)** |

**The planarity check is what says the layout is right**, and it is three independent arrays — the
nodes, the vertex pool and the points — having to agree. A wrong field offset cannot produce
coplanar polygons by accident.

**It matches Nyko's independently measured figures exactly.** `1-Medical`: **7,125 nodes, 3,386
surfaces, worst plane distance 0.25, zero polygons off-plane** — the same numbers his editor
prints, including the worst distance. `2-Fisheries` 3,724 surfaces and `3-Arcadia` 2,906 agree too.

The 12 off-plane polygons are on two maps (`0-Lighthouse` 2, `7-Gauntlet` 10) and reach 7.4 cm.
Recorded, not explained: at 80,000 units from the origin a float carries about 8 mm, so this is
larger than precision alone accounts for. `UNKNOWN` whether they are authored that way.

**The winding is the same as the source brushes'** — 0 of 758 polygons agree with their plane in
stored order after conversion, so the emitted fan reverses, exactly as `Polys` does (§3). Normals
come from the node's plane rather than from the winding, because a BSP polygon is planar by
construction and the plane stays correct on slivers.

**Surfaces the game does not draw are excluded** — `PF_Invisible`, `PF_FakeBackdrop`, `PF_Portal`.
On `0-Lighthouse` that is 15 of 370. Including them fills the level with invisible walls.

### 5.0 The container walk

**Both halves are now `CONFIRMED_BYTES`.**

From Nyko's §C.1, validated there at 283/284 byte-exact on `0-Lighthouse` and cross-checked against
his editor's own parser (`tools/level_editor/src/bsp_parser.cpp`), which renders it.

### 5.0 What this project has now verified itself

`ModelReader` walks the layout below **as far as the `Polys` object reference** and stops. That is
enough to close actor → model → polygons, which is the link a level needs, and it is what promotes
the front half of §C.1.1 from someone else's source to this project's own measurement.

| measured across all 21 map packages | |
|---|---|
| `Model` exports walked | **16,926** |
| …landing on a reference that resolves to a `Polys` export | **16,926 (100%)** |
| Brush actors in `0-Lighthouse` reaching their polygons | **230 of 230** |

**Why that is a decode and not a fit:** every array length ahead of the reference is read from the
data, so one wrong field size puts the final read at an arbitrary offset. An arbitrary
`FCompactIndex` resolving to an export of exactly the right class, 16,926 times, is not a
coincidence available to a wrong layout.

**The counts match Nyko's independently-measured figures exactly**, which is a second, stronger
check — these are numbers neither project could have got right by accident:

| map | this project | Nyko |
|---|---|---|
| `1-Medical` | 7,125 nodes, 3,386 surfs, 11,652 points | 7,125 nodes, 3,386 surfs, 11,652 points |
| `2-Fisheries` | 3,724 surfs | 3,724 surfs |
| `3-Arcadia` | 2,906 surfs | 2,906 surfs |

**The export table does not state the model → polys link**, which is why this walk is necessary at
all: of `0-Lighthouse`'s 285 `Polys` exports, only **60** have a `Model` as their outer, **54** have
a `SkeletalMesh`, and **171** have none; no `Model` is immediately followed by its `Polys` either.

**Identifying the built world is a comparison, not a threshold** — the rule is Nyko's own ("find the
largest UModel by node count"). A first attempt here defined it as `NodeCount > 0` and was wrong: a
source brush carries its own small node tree, six nodes for a six-sided box, so that test called all
285 of Lighthouse's models the built world. The separation within a package is nonetheless enormous:

| map | world | next largest |
|---|---|---|
| `0-Lighthouse` | 758 nodes | 6 |
| `1-Medical` | 7,125 nodes | 6 |
| `7-Science` | 7,951 nodes | 10 |

### 5.1 The layout

```
Super::Serialize                       // UObject — Vengeance header + tagged properties
FBox(25) + FSphere(16)                 // UPrimitive base — 41 bytes
8 B     Vengeance class header (check=4, sv=7)
TArray<FVector>  Vectors               // texture axes and normals, indexed by surfaces
TArray<FVector>  Points                // the vertex pool
CI NumNodes    + 100 B × N             // FBspNode
CI NumSurfs    + (8 B header + 52 B) × N   // FBspSurf
CI NumVerts    + 8 B × N               // FVert
int32 NumSharedSides, int32 NumZones, FZoneProperties[NumZones]
CI    Polys                            // the object reference back to the UPolys export
TArray<int> Bounds, TArray<int> LeafHulls
CI NumLeaves   + 12 B × N              // FLeaf
CI NumLights   + CI × N                // light references
int32 RootOutside, int32 Linked
[lightmap arrays — FLightMapIndex, LightBits, LightMapTextures]
```

### 5.2 `FBspNode` — 100 bytes, and one field is a landmine

```
+0   FPlane Plane (16)          +52  FVector BoundOrigin (12)   — Vengeance addition
+16  ZoneMask (16, 128-bit)     +64  float BoundRadius          — Vengeance addition
+32  int32 iVertPool            +68  int32 iCollisionBound
+36  int32 iSurf                +72  int32 iRenderBound
+40  int32 iBack                +76  byte  NodeFlags
+44  int32 iFront               +77  byte  iZone[0]
+48  int32 iPlane               +78  byte  NumVertices   ← see below
                                +79  byte  iZone[1]
                                +80  int32 iLeaf[0], +84 iLeaf[1]
                                +88  int32 UNKNOWN
+92  int32 iContentBound
+96  int32 iLightMap
```

**`NumVertices` is a byte at +78, not an int32 at +88.** Nyko's initial Ghidra analysis had it at
+88; reading it there gives 64% planarity failures. He settled it by an exhaustive probe of all 68
candidate byte offsets across 800 nodes, scoring each by whether the referenced vertices actually
lie on the node's own plane — **+78 scores 100% (0 of 7,125 failures)**. That probe is still in his
source and its output is in `editor_output.txt`.

**Worth noting for when this is implemented: +97 also scored 100%.** Two offsets pass; the
distinguishing evidence is the field layout, not the score. This is the same shape of problem as
"agreement at one layer is not evidence at the layer below it" (`reference-comparison.md` §1).

**`+96` is now settled as `iLightMap`.** On the 11 maps with the verified descriptor variant, all
**42,887** in-range node values satisfy `LightMap[node.+96].iSurf == node.iSurf`; offsets +88 and
+92 produce only 81/42,887 and 46/37,918 accidental matches respectively. It is a descriptor
index, not a surface index: the descriptor table is not surface-ordered.

Vengeance uses `MAX_ZONES = 128`, so `ZoneMask` is 128-bit where stock UE2.5 is 64.

### 5.3 `FBspSurf`

```
8 B    per-element Vengeance header (check=4, sub_ver=1)
CI     Material            // UShader / UTexture
int32  PolyFlags
int32  pBase               // index into Points  — the texture origin
int32  vNormal             // index into Vectors
int32  vTextureU           // index into Vectors
int32  vTextureV           // index into Vectors
int32  iBrushPoly          // version >= 101   ← contested, see below
CI     Actor               // ABrush reference
FPlane SurfNormal (16)     // version > 86
float  LightMapScale (4)   // version >= 106 — 8.0 / 16.0 / 32.0
```

**PanU/PanV are not serialised** at version >= 78; the pan offsets are baked into `pBase`.

**+20 is `iBrushPoly`. `CONFIRMED_BYTES`, and it settles a three-way contest.** Nyko's spec called it
`iBrushPoly`; his own editor's parser reads the same position as `iLightMap` and picks a lightmap
atlas with it; his lightmap note puts `iLightMap` on the *node* instead. **The spec is right.**

The discriminator is the normal. A surface names the brush actor it was cut from (§5.7), and that
brush's `Polys` export holds its faces with their own normals — so if +20 indexes those faces, the
face it names must be the one this surface came from.

| measured over `0-Lighthouse`, `1-Medical`, `3-Arcadia` | |
|---|---|
| surfaces resolving to a brush actor | **6,372** |
| …whose +20 is inside that brush's polygon list | **6,372 (100%)** |
| …**and names a polygon whose normal matches the surface's** | **6,372 (100%)** |

An unrelated index would agree by chance about a sixth of the time on a six-sided brush. The value
range says the same from the other side: `0..31` on Lighthouse, `0..9` on Medical, **ten distinct
values across 3,386 surfaces**. A lightmap index needs roughly one value per surface; a
brush-polygon index needs one per face of a brush.

**So the lightmap index is not on the surface**, and the note that puts it on the node is where to
look next. `SurfaceBrushPolyTests`.

### 5.4 `FVert` — 8 bytes

`int32 pVertex` (index into `Points`) + `int32 iSide`. **Raw int32 where UE2.5 uses `FCompactIndex`.**

### 5.5 Lightmaps

`FLightMapIndex` is one descriptor per surface: `iSurf`, `SizeX`, `SizeY` (1..512), a 4×4
`WorldToLightMap` matrix, and a list of `FLightMapLight` entries carrying `iAtlas`, `TileX`, `TileY`.
The atlases are ordinary DXT textures in the `LightMaps_BSP` group, resolving through the bulk
pipeline this project already reads (`bulkcontent.md`). The UV build:

```
(U', V') = WorldToLightMap × vertexWorldPos
U = U' × (SizeX/1024) + (TileX + 0.5)/1024
V = V' × (SizeY/1024) + (TileY + 0.5)/1024
```

**Where the index is not: the surface.** §5.3 settles `FBspSurf +20` as `iBrushPoly`, so the
editor's reading of it as a lightmap atlas index is wrong and this is one fewer place to look. The
remaining candidate from the same reference is the **node**.

**A lead, recorded as a lead.** A scan of every int32-aligned field of `0-Lighthouse`'s 100-byte node
record found two index-shaped fields the reader does not interpret: **+92** (0..1,619, 539 distinct
over 758 nodes) and **+96** (0..369, exactly 370 distinct against 370 surfaces). Neither is confirmed
as anything. **The scan does not yet generalise** — it locates the node array by searching for an
`FCompactIndex` equal to the node count, and on `1-Medical` that lands on a false positive, so the
Medical columns are not comparable. Fixing the locator, so the same field can be read on several
maps at once, is the first step of the lightmap work rather than part of it.

### 5.5b What the unread tail starts with — `NumSharedSides`, then `NumZones`. `CONFIRMED_BYTES`

The reader stops at the vertex pool, and **13.9% of the compiled worlds' bytes are still unread** —
7,928,056 of 57,108,008 across the 21 maps, and 698,916 bytes on `1-Medical` alone. §5.5's
descriptors are expected to be in there, so the tail is now walked from a known offset rather than
searched: `BspWorld.Layout` reports where each array began and where the decode stopped.

**The first two int32s of the tail are UE2's `NumSharedSides` and `NumZones`**, and the second is
confirmed by a field this project already decodes independently: a node's `Zone` byte indexes the
zone array, so `max(node.Zone)` must equal `NumZones − 1`.

| | |
|---|---|
| maps checked | **21** |
| where `max(node.Zone) + 1` equals the declared zone count | **21 (100%)** |
| range | `Entry` 2 zones, `4-Recreation` 125 |

An arbitrary int32 does not track a byte field across 21 independent maps.
`BspWorldTests.TheTailAfterTheVertexPoolStartsWithTheZoneCount`.

**The zone record itself is `UNKNOWN`, and this is a negative result worth keeping.** Its zone-actor
references are real — they resolve to `ZoneInfo` and `SkyZoneInfo` exports, which is what a zone
points at — and within any one map they sit exactly **38 bytes** apart. But a fixed 38-byte stride
lands on the `Polys` reference that UE2 serialises after the array on only **2 of 21** maps, because
the reference is an `FCompactIndex` whose width varies with the export index. So the record is
variable-width, its field order is not established, and **guessing it was rejected rather than
shipped**. Settling it is what stands between this and `FLightMapIndex`: after the zones come
`Polys`, then `LightMap`, then `LightBits`.

### 5.5c The zone record, and the array after it. `CONFIRMED_BYTES` — with a correction

**A zone record is an `FCompactIndex` actor reference followed by 36 fixed bytes.** Found by reading
the bytes rather than by trying strides: the fixed part starts with the zone's own bit mask — `1`,
`2`, `4` for zones 0, 1, 2 — and the references resolve to `ZoneInfo` and `SkyZoneInfo` exports.

**A fixed 38-byte stride was tried first and is wrong**, landing correctly on only 2 of 21 maps: the
reference's width varies with the export index, so only a walk works.

**The anchor is what UE2 writes next.** After the zones comes the `Polys` object reference, and
walking the zones lands on a reference resolving to a `Polys` export on **21 of 21 maps**.

> **A correction, recorded because it is the exact mistake this project's rules exist to prevent.**
> The array after `Polys` was first written up here as `LightMap`, on the strength of UE2's
> serialisation order — inherited ordering promoted to a fact without reading a record. **It is
> `Bounds`, a `TArray<FBox>`.** `Entry`'s first record is `min(−128,−128,−128) max(128,128,128)`,
> which is a box and not a lightmap descriptor. One dump of the bytes settled what one plausible
> ordering had asserted.

| measured over all 21 maps | |
|---|---|
| zone walks landing on a `Polys` reference | **21 of 21** |
| records after it | **30,578** |
| …that are valid `FBox`es — `min ≤ max` on all axes, in world range, `IsValid = 1` | **30,578 (100%)** |
| record stride | **25 bytes** — six floats and a byte |

A wrong record size cannot hold that across arrays of 5 to 2,949 elements.

`BspWorld.Layout` reports `Zones`, `ZoneCount`, `Bounds` and `BoundCount`.
`BspWorldTests.TheZoneWalkLandsOnPolysAndTheArrayAfterItIsBoxes`.

**Where the lightmaps are, then.** Still further on: `LeafHulls`, `Leaves` and `Lights` follow the
bounds, and **between 879 and 628,534 bytes remain unread after them** on each map. The next step is
to walk those three arrays the same way — measure a record, anchor it against something already
decoded, and only then name it.

### 5.5d The descriptor table is real, and the atlas binding now is too. `CONFIRMED_BYTES`

The complete structural tail now walks from the bounds through `LeafHulls`, 12-byte `FLeaf` records,
the two compact-reference arrays and `RootOutside`/`Linked`. On all **21 map packages** it lands on a
compact count equal to the number of surfaces, followed by `ObjHeader(4,2)`. All **39,288**
descriptors map one-to-one onto their worlds’ surface lists, with **45,851** baked-light layers.
The apparent ten-map decode failure was a reader bug: it had already walked the variable records
correctly, then discarded them when an unrelated post-table array did not match the reference.

**The matrix and UV packing are `CONFIRMED_BYTES`.** The matrix is row-major and applies to the raw
game-space position (reverse the studio Y reflection first). Against eleven independently located
`LightMaps_BSP` atlas pools, that puts **234,404/234,404** polygon vertices inside the declared tile;
the transposed matrix puts only 1,096 there. `BspWorld.LightMapUv` then applies `(Size × UV + Tile +
0.5) / 1024`.

**Atlas pools are proven on all 20 map packages that carry a `LightMaps_BSP` group — 19 Aug 2026,
up from 11.** Each is a compact array of Vengeance v1 entries, every one a local 1024×1024
`Texture` in the package-declared `LightMaps_BSP` group. The gap was the pool-search's count floor:
it required at least 8 entries, a range read off the first 11 proven maps rather than a real format
constraint. `0-Lighthouse` turned up a genuine 5-entry pool — smaller than anything checked so far,
not evidence the location or shape was wrong — so the floor is 1 now: `3-Market` and `5-Ryan` carry
pools of only 4 and 3. All 20 pass the same validation the first 11 did (every reference resolves to
an actual export, is genuinely class `Texture`, sits in `LightMaps_BSP`, and decodes to 1024×1024),
with zero regressions on the original 11's counts or offsets. **`Entry` is the one map package with
no atlas pool, and correctly so**: it has no `LightMaps_BSP` group at all — a 40-export, ~20 KB
trivial package, not a real level. `BspWorldTests.LightmapAtlasPoolsAreVengeanceWrappedLightMapsTextures`.

### 5.6 Surfaces that must not be drawn

`PolyFlags` carries `PF_Invisible 0x1`, `PF_FakeBackdrop 0x80`, `PF_Portal 0x04000000`. Nyko's editor
skips all three: they are zoning, portal and backdrop surfaces, not architecture. **Any level
exporter has to honour these or the level comes out full of invisible walls.**

### 5.6b The twelve off-plane polygons are snapped corners. `HIGH CONFIDENCE`, and not a decode fault

Twelve of 81,566 compiled polygons (0.015%) sit more than 1 cm off their own node's plane, worst
7.381 cm, all on `0-Lighthouse` (2) and `7-Gauntlet` (10). Every one has the same shape:

- **Part of the polygon is exactly on the plane** — 0.000 cm, not nearly — and the rest is off it.
  All twelve keep at least one exact vertex, which is the measurement that exonerates the decode.
- **The deviation equals the plane's off-axis slope times the distance travelled.** `7-Gauntlet`
  node 755: the normal is `(−0.9966, 0.0819, 0)`, a wall 4.7° off the Y axis, and all four corners
  are stored at `x = 32`; the two at `y = −2252` are exact and the two at `y = −2208` are 3.603 cm
  out — `0.0822 × 44 = 3.61`. `0-Lighthouse` node 360: slope `0.000459` across 8,704 units of
  polygon gives 4.00 cm, and it is 4.001 cm out.
- **The off-plane corners are the round ones.** On `7-Gauntlet` node 591 the exact vertices sit at
  `x = −107.43` and the 7.38 cm ones at `x = −96`.

That is the editor's grid snap: a brush corner moved to a round coordinate, after which the CSG
fragment no longer lies on the face it was cut from. It is shipped data.

**What it is not.** Not float precision — a float at 5,000 units resolves under a millimetre, not
7 cm. Not the basis conversion, which is a sign flip and exact. Not the node layout: the same three
arrays produce 81,554 polygons that are exactly on plane, and a wrong offset cannot be selective.

**Rejected on the way:** that the polygon belongs to its *surface's* plane rather than its node's.
Measured — the surface normal is within 0.04° of the node normal, and `pBase` is a texture origin
that is itself up to 1,433 cm off the polygon, so it is not a point on the plane at all.

`BspWorldTests.TheOffPlanePolygonsAreSnappedCornersAndKeepAVertexOnTheirPlane` holds the ceiling and
the discriminator: snapping moves corners, a decode fault moves whole polygons.

### 5.7 The surface's `Actor` is the link back to the source brush — and it settles the placement

`FBspSurf.Actor` was read and discarded until now. It is the only stated correspondence between the
compiled world and the brushes it was built from, and it turns a question that had no ground truth
into a measurement: **the same polygon exists twice**, once in brush space in a `Polys` export and
once in world space in the `Model`, so the placement rule is whatever maps one onto the other.

The metric is the **plane**, not the vertices: CSG clips a brush against its neighbours, so vertices
do not survive and areas do not match, but a clipped polygon stays in the plane it was cut from.

Measured over six maps — `0-Lighthouse`, `1-Medical`, `2-Fisheries`, `3-Arcadia`, `6-Slums`,
`7-Science` — **33,632 world polygons**, each matched against the planes of the brush its surface
names:

| candidate placement | polygons within 1 cm of a plane of their own brush |
|---|---|
| **`Location − PrePivot`, no rotation or scale** | **33,631 / 33,632 = 100.0%** |
| the full actor transform | 33,631 / 33,632 = 100.0% |
| `Location` alone | 982 / 33,632 = 2.9% |
| no placement at all | 297 / 33,632 = 0.9% |

Worst matched offset **0.82 cm**. The single miss is `0-Lighthouse Brush12`, whose nearest parallel
plane sits **2.09 cm** away — unexplained, and recorded rather than tuned away.

**So the translation is `CONFIRMED_BYTES`**, and the pre-pivot is load-bearing: dropping it costs
97% of the match. **The rotation and the scale are not**, because the first two rows are identical
for a reason — *no CSG brush carries either*. Across all shipped maps, **0 of 13,443 brush actors are
scaled and 17 are rotated**, and all 17 are `ShockDamageVolume`s: gameplay regions, never drawn,
never in the built world. For those 17 the composition order stays `UNKNOWN`, and no shipped byte
distinguishes it.

**A subtracted brush's face points the other way.** 25,726 of the 33,632 matched polygons oppose the
normal of the source poly they came from and 7,905 agree with it — Rapture is mostly carved out of
solid, and the match is made on the plane precisely so that this does not look like a failure.

---

## 6. What is NOT established

- **How a rotated or scaled brush actor's transform composes.** The translation is settled — §5.7,
  `CONFIRMED_BYTES` against the compiled world — but rotation and scale are not, because no brush
  that reaches the built world carries either. The 17 rotated brushes in the game are all damage
  volumes and there is no shipped geometry to check them against. `UNKNOWN`.
- **Whether the 27 sheet brushes and 4 non-manifold brushes are content or a decode gap.** They walk
  to the exact byte, so the bytes are read correctly; what they *are* is unmeasured.
- **CSG.** A level is brushes added and subtracted. This reader returns each brush's raw solid, which
  is the source geometry, not the resulting world. `CsgOper` sits in `UninterpretedProperties`.

---

## 7. Lights — the answer is in the same document. `CONFIRMED_EXTERNAL`, not implemented

Not BSP, but it is Phase 2 item 3 and §C.6 of the same unread file answers it outright. BioShock
writes light parameters with **different types** from stock UE2.5, which is why they sit unread in
`UninterpretedProperties`:

| field | BioShock | stock UE2.5 |
|---|---|---|
| `LightBrightness` | **FloatProperty**, 0.0–3.1, median 1.0 | byte 0–255 |
| `LightColor` | **StructProperty `Color`** — FColor BGRA | `LightHue` + `LightSaturation` bytes |
| `LightRadius` | **FloatProperty**, 0–120,000 world units, median 2048 | byte, radius = 25 × (b+1) |

`bStatic` and `bNoDelete` are **never written to disk** — a probe across all 184 Light actors on
Lighthouse. The class default applies.

`0-Lighthouse` has 318 light actors. Reading three float/struct properties is the whole job.
