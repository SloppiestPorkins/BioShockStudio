# BSP — `Model` and `Polys`

**Implementation:** `src/BioShockStudio.Core/Level/BspPolys.cs`, `BspGeometry.cs`
**Tests:** `tests/BioShockStudio.Tests/BspGeometryTests.cs`, `BspRenderingTests.cs`
**Status:** `Polys` / `FPoly` is **`CONFIRMED_BYTES`**. `Model`'s own binary body is
**`CONFIRMED_EXTERNAL`, not implemented** — see §5.

This is the container 230 actors in `0-Lighthouse` reference and nothing decoded, and the same one
`AtlasLabsDoorAnim` ships in place of a drawable mesh (HANDOFF §6.2).

**There are two different things called BSP here and confusing them wastes a session:**

| | what it is | where | state |
|---|---|---|---|
| **Source brushes** | the designer's convex solids, as authored | a `Polys` export per brush | **decoded, §2** |
| **The built world** | the compiled level — nodes, surfaces, a vertex pool, lightmaps | inside one large `Model` export | **documented, §5** |

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

`BspGeometry.ToGeometry` emits the projection in **texels** and says so; `NormaliseUvs` divides.
The split is deliberate: this layer does not resolve materials, so it cannot know the dimensions and
does not invent them.

**`TextureU` and `TextureV` are zero on some polygons** — the first brush in `0-Lighthouse` has all
four axes zero — so a zero UV is real data, not a decode failure. How many is not yet counted.

---

## 5. `Model` — the built world. `CONFIRMED_EXTERNAL`, **not implemented**

From Nyko's §C.1, validated there at 283/284 byte-exact on `0-Lighthouse` and cross-checked against
his editor's own parser (`tools/level_editor/src/bsp_parser.cpp`), which renders it.

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

### 5.1 `FBspNode` — 100 bytes, and one field is a landmine

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
                                +96  int32 iRenderZone
```

**`NumVertices` is a byte at +78, not an int32 at +88.** Nyko's initial Ghidra analysis had it at
+88; reading it there gives 64% planarity failures. He settled it by an exhaustive probe of all 68
candidate byte offsets across 800 nodes, scoring each by whether the referenced vertices actually
lie on the node's own plane — **+78 scores 100% (0 of 7,125 failures)**. That probe is still in his
source and its output is in `editor_output.txt`.

**Worth noting for when this is implemented: +97 also scored 100%.** Two offsets pass; the
distinguishing evidence is the field layout, not the score. This is the same shape of problem as
"agreement at one layer is not evidence at the layer below it" (`reference-comparison.md` §1).

Vengeance uses `MAX_ZONES = 128`, so `ZoneMask` is 128-bit where stock UE2.5 is 64.

### 5.2 `FBspSurf`

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

**A contested field, recorded rather than resolved.** Nyko's spec calls +20 `iBrushPoly`; his own
editor's parser reads the same position as `iLightMap` and uses it as a lightmap atlas index. His
lightmap note takes a third position, putting `iLightMap` on the *node* rather than the surface. The
two sources disagree and this project has not measured it. `UNKNOWN`.

### 5.3 `FVert` — 8 bytes

`int32 pVertex` (index into `Points`) + `int32 iSide`. **Raw int32 where UE2.5 uses `FCompactIndex`.**

### 5.4 Lightmaps

`FLightMapIndex` is one descriptor per surface: `iSurf`, `SizeX`, `SizeY` (7..512), a 4×4
`WorldToLightMap` matrix, and a list of `FLightMapLight` entries carrying `iAtlas`, `TileX`, `TileY`.
The atlases are ordinary DXT textures in the `LightMaps_BSP` group, resolving through the bulk
pipeline this project already reads (`bulkcontent.md`). The UV build:

```
(U', V') = WorldToLightMap × vertexWorldPos
U = U' × (SizeX/1024) + (TileX + 0.5)/1024
V = V' × (SizeY/1024) + (TileY + 0.5)/1024
```

### 5.5 Surfaces that must not be drawn

`PolyFlags` carries `PF_Invisible 0x1`, `PF_FakeBackdrop 0x80`, `PF_Portal 0x04000000`. Nyko's editor
skips all three: they are zoning, portal and backdrop surfaces, not architecture. **Any level
exporter has to honour these or the level comes out full of invisible walls.**

---

## 6. What is NOT established

- **The built world is not implemented.** §5 is read from two external sources and has not been
  verified against a single shipped byte by this project. It stays `CONFIRMED_EXTERNAL` until it is.
- **`FBspSurf +20`** — `iBrushPoly` or `iLightMap`. The references disagree. `UNKNOWN`.
- **How a brush actor's transform composes.** A `Polys` holds brush-local geometry; the `Brush`
  actor carries `Location`, `Rotation`, `PrePivot` and scale, and the order they compose in has not
  been measured. Nothing in this project places a brush in the world yet.
- **Whether the 27 sheet brushes and 4 non-manifold brushes are content or a decode gap.** They walk
  to the exact byte, so the bytes are read correctly; what they *are* is unmeasured.
- **CSG.** A level is brushes added and subtracted. This reader returns each brush's raw solid, which
  is the source geometry, not the resulting world. `CsgOper` sits in `UninterpretedProperties`.
- **How many polygons carry zero texture axes**, and therefore how much of the brush set has no UV.

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
