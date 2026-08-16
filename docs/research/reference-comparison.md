# What the reference projects say, compared field by field

**Purpose.** Four reference projects sit in the repo root, gitignored. This file records what each
one says about the structures this project reads, **where they agree, where they disagree, and which
one the shipped bytes side with**. It exists because two of them have already contradicted each
other on a live question, and the disagreement was worth more than either source alone.

| folder | what it is |
|---|---|
| `hk2012_2_0_r1` | Havok Physics/Animation 2012.2.0-r1 SDK. Headers and `.inl` only — "NO SOURCE PC DOWNLOAD", so no `.cpp`. |
| `Bioshock1REMSDK-WIP--main` | Nyko's in-engine Remastered SDK/WIP. Knows the *engine's* structures. |
| `UModel-master` | UEViewer source, with a real `#if BIOSHOCK` branch throughout. Knows the *shipped bytes* of the original game. |
| `Unreal-Library-master` | UELib (C#). **Now mined for `UPolys`/`FPoly` — see §7.** |

**Reading these first is project policy.** Three faults have been settled by them in minutes after
long byte-level dead ends. Two more were settled this session.

---

## 1. Texture `Format` ordinal 12 — the two sources disagree, and UModel is right

The single clearest example of why this file exists.

| source | claim |
|---|---|
| Nyko, `BioShock_Reading_Textures.md` §3 | `12 = 3DC`, `ceil(w/4)*ceil(h/4)*16` bytes, "**3DC** is BC5/ATI2 (two BC4 alpha blocks giving R and G; reconstruct B as a unit normal's Z)". |
| UModel, `UnTexture2.cpp:21` | `if (Ar.Game == GAME_Bioshock && Format == 12) Format = TEXF_DXT5N;` with the comment *"remap format; note: Bioshock used 3DC name, but real format is **DXT5N**"*. |

**They agree on the block size and disagree on what is inside the block**, and the difference is not
cosmetic: BC5 is two BC4 blocks (X, Y), while DXT5N is an ordinary DXT5 block carrying the normal in
**alpha and green**.

**The bytes side with UModel.** Decoded as BC5, `Cheese_Mould_Normal` comes out magenta with its
green channel averaging **57**; decoded as DXT5N it averages **128**, X averages 127, Z averages 252,
and **0 of 4,096 texels violate `x² + y² ≤ 1`**. nvtt, which UModel calls, makes the distinction
explicit:

```cpp
if (fourcc == FOURCC_ATI2)  c = buildNormal(c.r, c.g);   // real BC5
else if (fourcc == FOURCC_DXT5) c = buildNormal(c.a, c.g);   // DXT5N
```

**Why Nyko's note was still worth reading:** it gave the ordinal, the name and the exact block size,
which is what made the format findable at all. It was wrong about one layer down. **Corroboration is
not agreement — check the layer you actually depend on.**

Implemented as `BioShockTextureFormat.ThreeDc`, `BlockCompression.DecodeThreeDcBlock`, pinned by
`NormalMapFormatTests`. Result: **274 texture exports that decoded to nothing now decode**, and
`texture-undecodable` fell from 320 to 46 game-wide.

---

## 2. Material classes — Nyko settles it outright

`BioShock_Materials_And_Shaders.md`, and nothing contradicts it.

| claim | our state before | after |
|---|---|---|
| Every material class is a stock UE2 object: tagged properties, **no custom binary blob** | assumed, never stated | confirmed |
| The class tree: `Material → {Modifier, RenderedMaterial, BitmapMaterial}`; `Texture` and `Cubemap` are `BitmapMaterial`s, i.e. **materials** | a `Texture` in a material slot looked like a fault | 162 meshes fixed |
| Texture references are ordinary objrefs | we matched **slot names** from a list of 13 | rule is now "objref resolving to a `Texture`" — 353 more meshes |
| `EMaterialType` ordinals (`9 Shader`, `10 FluidShader`, `16 FacingShader`, `18 PlantShader`, …) | unknown | **not serialised** by any shipped material, so unusable; the export's class name is the discriminator |
| `MaterialVisualType` is the **physical-surface** class (Stone/Glass/Flesh/Water) driving footsteps and impacts, *not* rendering | `UNKNOWN`, guessed as a "shader-variant selector" | open question 11 half closed; the guess was wrong |
| `ShaderTag` names an HLSL factory `MaterialFactory_<Tag>`; `shaders.spk` holds all 40 HLSL sources | unknown | recorded, not needed yet |
| `MaskMaterial` is `{ Material Material; EMaskChannel Channel }` | size rule reverse-engineered from bytes | **agrees** with what we derived independently |

**Unused so far and worth knowing:** `shaders.spk` is a trivial `Version/FileCount/Flags/Cooker` +
`[nameLen, UTF-16 name, srcLen, ANSI source]` pack holding the complete HLSL for every material
factory. If the project ever wants to reproduce a surface's actual look rather than its texture
bindings, that is where the answer is, in source form.

---

## 3. `SkeletalMesh` — UModel has the whole payload, and we search for parts of it

**This is the largest unexploited finding in the repo.** `UnMeshBioshock.cpp` is 788 lines and
contains a complete serialisation of the BioShock 1 skeletal mesh. Our reader locates the vertex
chain **by search** and open question 4 records that byte-exact accounting "is what would settle it
outright" and that "this project does not have" it. UModel does.

```cpp
void USkeletalMesh::SerializeBioshockMesh(FArchive &Ar)
{
    UPrimitive::Serialize(Ar);          // bounds
    TRIBES_HDR(Ar, 0);                  // the Vengeance versioned header — see §4
    Ar << Textures << MeshScale << MeshOrigin << RotOrigin;
    Ar << unk90 << unk94 << unk98 << unk9C;                       // 2 floats, 2 ints
    Ar << RefSkeleton << Animation << SkeletalDepth
       << AttachAliases << AttachBoneNames << AttachCoords;       // the socket arrays
    Ar << bioLODModels;                 // geometry, and the SECTION TABLE
    Ar << fCC;
    Ar << Points << Wedges << Triangles << VertInfluences;
    Ar << CollapseWedge << f1C8 << bioNormals;
    SkipLazyArray(Ar); SkipLazyArray(Ar); SkipLazyArray(Ar);
    Ar << f68 << f104 << f110 << f128 << f11C;
    Ar << HkMeshProxy;                  // UHkMeshProxy* — Havok data
    if (t3_hdrSV <= 5) Ar << drop1;
    if (t3_hdrSV >= 4) Ar << havokObjects;
    if (t3_hdrSV >= 5) Ar << f134;
}
```

Cross-checks against what this project already established independently — **all four agree**:

- **`Textures` is the first array after the header.** That is the counted material array we found by
  searching for a tag block; UModel names it and confirms the count-then-references shape, and adds
  `Materials[i].TextureIndex = i` — one material slot per entry, in order. Consistent with our
  "an empty slot must keep its position".
- **`AttachAliases`, `AttachBoneNames`, `AttachCoords`** are three parallel arrays immediately after
  `SkeletalDepth` — exactly the socket decode in §6.6b, including the `FCompactIndex` count that
  cost two wrong readings.
- **`HkMeshProxy` is a `UObject*`**, not a material link. We overturned that claim from bytes; UModel
  agrees.
- **Smooth (skinned) verts are serialised before rigid verts.** Our landmine says the index buffer
  addresses the rigid block first though the skinned block is stored ahead of it. Same ordering.

### 3a. A skeletal mesh **does** have a section table — `UNKNOWN` closed

`FStaticLODModelBio` opens with:

```cpp
TArray<FSkelMeshSection> Sections;   // 1 section = 1 material
TArray<int16>            Bones;
FRawIndexBuffer          IndexBuffer;
TArray<FSmoothVertexBio> SmoothVerts;
TArray<FRigidVertexBio>  RigidVerts;
```

and `FSkelMeshSection` (`UnMesh2.h:699`) is nine `uint16`s:

```cpp
uint16 MaterialIndex, MinStreamIndex, MinWedgeIndex, MaxWedgeIndex,
       NumStreamIndices, BoneIndex, fE, FirstFace, NumFaces;
```

**HANDOFF item 6 and `docs/QUALITY.md` §2 both record it as `UNKNOWN` whether the skeletal container
carries a run table. It does.** `MaterialIndex` + `FirstFace`/`NumFaces` is precisely the pairing the
static path already uses. That is the **153** meshes currently reported as
`mesh-materials-without-sections` — `TommyGunMESH`, `PlasmidEquipMESH`, `WP_CrossbowMesh`,
`PearlsAnim_Mesh` and 149 more — which today draw entirely in one material.

**Not implemented yet, deliberately.** It needs the payload walked from the front rather than
searched, which is a real piece of work and is the obvious next task. Nothing here should be
hardcoded on the strength of this note alone: UModel targets the **original** game, and the
Remastered vertex record already differs (48-byte static vertices against 24). Expect the same kind
of divergence and verify field by field against shipped bytes.

---

## 4. `TRIBES_HDR` — the "tag block" we search for is a versioned object header

`UnCore.h:2219`:

```cpp
#define TRIBES_HDR(Ar,Ver)                                  \
    int t3_hdrV = 0, t3_hdrSV = 0;                          \
    if (Ar.Engine() == GAME_VENGEANCE && Ar.ArLicenseeVer >= Ver) { \
        int check; Ar << check;                             \
        if (check == 3)      Ar << t3_hdrV << t3_hdrSV;     \
        else if (check == 4) Ar << t3_hdrSV;                \
        else appError(...);                                 \
    }
```

`MaterialReader` searches for the byte pattern `04 00 00 00 05 00 00 00` and calls it "the tag block
that separates a `SkeletalMesh`'s bounds from its material list", noting that its position varies
between meshes (64 in `NEWPlayerHands`, 54 in `WP_PistolMesh`). §6.1 records the static mesh's
equivalent as `int32 4, int32 8, int32 1`.

**Those are not magic numbers.** They are `check = 4` (one version field follows) and then
`t3_hdrSV = 5` for `SkeletalMesh` and `= 8` for `StaticMesh`. The position varies because the
variable-length data *before* it varies, not because the block moves.

This matters beyond tidiness: **`t3_hdrSV` gates the layout**. UModel branches on it repeatedly
(`if (t3_hdrSV < 4)` selects BioShock 1's vertex layout, `>= 3` adds a field, `>= 5` adds another).
Reading it as a version rather than matching it as a pattern is what makes a forward walk possible.

---

## 5. Havok — what the SDK adds, and one lead §6.0c has never considered

The SDK settled the Phase 1 blocker (`recompose` fills an omitted component from **identity**). What
else it holds, checked this session:

| header | finding | our state |
|---|---|---|
| `hkaAnimationBinding.h` | `BlendHint { NORMAL = 0, ADDITIVE = 1 }` | matches our census: all 15,998 animations are 0. Additive stays ruled out. |
| `hkaAnimationBinding.h` | **`hkArray<hkInt16> m_partitionIndices`** at +40 — "(Optional) A list of the partitions used to sample the animation" | **documented in our header comment and never read.** See below. |
| `hkaAnimationBinding.h` | `isMonotonic()` — "does this binding animate a **subset** of the bones in the same order in which they appear in the skeleton?" | The 54-track fire clips map to bones 3..56, all distinct, ascending — i.e. monotonic, a subset. Havok has a *name* for what they are. |
| `hkaSkeleton.h` | `struct Partition { const char* m_name; hkInt16 m_startBoneIndex; hkInt16 m_numBones; }`, and `hkArray<Partition> m_partitions` on the skeleton | never read |

**The §6.0c lead.** The four collapsing fire animations drive a *contiguous, ascending subset* of
`AggressorBabyJane`'s bones (3..56 of 73). Havok's word for a named contiguous bone range is a
**partition**, and a binding records which partitions it samples. That is a description of a
partial-body animation — an upper-body fire clip meant to be sampled against a partition rather than
played over the whole skeleton.

**Measured, and the lead is dead.** Both fields are now read (`HkaSkeletonReader.ReadPartitions`,
`HkaAnimationBindingReader.ReadPartitionIndices`). On `AggressorBabyJane`:

| | measured |
|---|---|
| `hkaAnimationBinding` objects | **457** |
| …carrying any partition index | **0** |
| skeletons in the wrapper | 6 — three `Bip01` (73 bones), three ragdolls (17) |
| …declaring any partition | **0** |
| bindings driving a subset of the skeleton | 9 of 457 |

There is nothing for a partial animation to be sampled against, so the partial-body reading is
eliminated — the fourth cause struck off §6.0c, and the first struck off by a *positive measurement*
rather than by reasoning about the decompressor. `SkeletonPartitionTests` pins both zeros so the
elimination cannot quietly stop being true.

The 9-of-457 figure is worth keeping: it confirms how unusual a subset-driving binding is on this
rig, and says nothing about why four of them collapse.

**The value here was the measurement, not the idea.** Reading two documented fields cost less than
arguing about them, and this project has already lost three sessions to a claim that was never
tested against something that could fail.

### Still unread in the Havok SDK

- `Docs/…User_Guide.pdf`, `…Quickstart_Guide.pdf`, `…Migration_Guide.pdf` — **never opened**. The
  user guide is the documented place for the animation/blending contract.
- `hkaSkeletonMapper.h`, `hkaSkeletonMapperData.h` — we carry `LockTranslation` as a retargeting
  hint on inference.
- `sampleTranslation` is **not in this build** and remains the single most likely home of the §6.0c
  answer. `hkaSignedQuaternion` ships declarations only — a confirmed dead end, do not re-check.

---

## 7. BSP — all four projects have something, and two of them disagree

Full detail in `bsp.md`. Recorded here because this is the first structure where the *fourth*
reference project contributed, and because two sources contradict each other on a live field.

| source | what it gave |
|---|---|
| `Unreal-Library-master` | `UPolys.cs` / `Poly.cs` — the `FPoly` field list with version gates. Resolved against this game's file version 142 it is **correct but for one field**. First finding ever taken from this project. |
| `Bioshock1REMSDK-WIP--main` §C.2 | The same layout derived independently from the shipped executable, **including the field UELib gets wrong**, and the reason for it. |
| `Bioshock1REMSDK-WIP--main` §C.1 + `tools/level_editor/src/bsp_parser.cpp` | The **built world BSP** — `FBspNode`, `FBspSurf`, `FVert`, zones, leaves, lightmaps. A container this project had recorded as `UNKNOWN`. The editor renders it, so the layout is exercised rather than merely written down. |
| `UModel-master` | Nothing for BSP. UEViewer is a model viewer and does not read levels. Checked, so the next session need not. |

### 7a. `FPoly.ItemName` — UELib's gates are one field short, and the bytes say so first

UELib reads `ItemName` as a bare name index. This game writes an `FCompactIndex` **plus a four-byte
number**. Found by arithmetic before either reference was consulted on it — the polygon tail is 17
bytes and the field list without the number totals 13 — and confirmed afterwards by Nyko's §C.2.2,
which gives the cause: `sizeof(FPoly)` is `0x14C` here against UE2.5's `0x148`, the linker's `FName`
operator widening at `Ar.Ver() >= 141`.

**The useful part is that UELib was still worth reading.** It supplied the field list, the ordering
and every version gate; one field was wrong and the exact-end arithmetic caught it in one run. That
is the same pattern as the DXT5N contest in §1 — a reference gets you to the right structure, and
the bytes settle the layer you actually depend on.

### 7b. A contested field, left contested

`FBspSurf +20`, in the built world:

| source | claim |
|---|---|
| Nyko, `bioshock1-bsm.md` §C.1.3 | `int32 iBrushPoly`, version >= 101 |
| Nyko, `tools/level_editor/src/bsp_parser.cpp` | `int32 iLightMap`, a lightmap atlas index, and uses it as one |
| Nyko, `BioShock_Texture_Lightmap_Format.md` §5 | `iLightMap` is on the **node**, not the surface |

Three statements from one project and they do not agree. This project has measured none of them —
the built world is not implemented — so it stays `UNKNOWN` rather than being resolved by picking the
most recent. **Recorded because the next session will otherwise re-derive the same contradiction.**

### 7c. A count that does not reconcile

Nyko reports `0-Lighthouse` as 284 `UPolys` exports / 1,687 `FPoly` elements. This project measures
**285 / 1,717** — including one `Polys` export holding zero polygons. Both walk to the exact byte.
Not reconciled; his note also says "Bioshock = 141" where these packages report file version **142**,
which may or may not be the same difference.

## 6. Scorecard — where each project has paid off

| finding | source | what it was worth |
|---|---|---|
| Omitted channel component = identity | Havok SDK | the Phase 1 blocker, after 3 sessions |
| `StaticMesh` section table | Nyko | per-section materials, 8,668 meshes |
| Socket `FCompactIndex` count | UModel | sockets decoded after two wrong readings |
| Material classes are plain property lists | Nyko | 515 meshes textured |
| `Texture` is a material | Nyko | 162 of those |
| Format 12 = DXT5N, **not** 3DC/BC5 | UModel, over Nyko | 274 normal maps |
| Skeletal mesh **has** a section table | UModel | 153 meshes, not yet implemented |
| `TRIBES_HDR` is a version header | UModel | not yet implemented |
| `m_partitionIndices` / skeleton partitions | Havok SDK | a §6.0c lead, unmeasured |
| `UPolys`/`FPoly` field list and version gates | **UELib**, corrected by bytes, confirmed by Nyko | 93,264 brush polygons across 21 maps |
| The built world BSP layout | Nyko's SDK **and its level editor** | a container recorded as `UNKNOWN`; not yet implemented |
| BioShock light property *types* | Nyko §C.6 | Phase 2 item 3, answered before it was started |

**Every one of the four projects has now paid off.** `Unreal-Library-master` was listed as
"**Nothing**" mined until this session. Of Nyko's `bioshock1-bsm.md` only §C.4 had been read; §C.1,
§C.2, §C.5 and §C.6 were unopened and all four turned out to be about Phase 2. **The pattern is now
five for five: read the reference projects first.**

**And read a project's *code* as well as its documents.** Nyko's `tools/level_editor/` renders BSP
and its parser carries measurements his prose does not — the exhaustive offset probe that settled
`FBspNode.NumVertices`, and the UV division at upload time. It also contradicts his own spec in one
place (§7b), which is only visible if both are read.
