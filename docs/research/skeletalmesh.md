# SkeletalMesh

**Implementation:** `src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`
**Tests:** `tests/BioShockStudio.Tests/SkeletalMeshTests.cs`
**Status:** header, sockets, bone map, geometry and skinning all decoded and exporting to Blender.

962 `SkeletalMesh` exports ship across the 21 packages, 46 of them in `0-Lighthouse.bsm`.

## Payload header

`CONFIRMED_BYTES`, verified across every `SkeletalMesh` in `0-Lighthouse.bsm`.

```
+0   23 bytes    header; its first 18 are shared with AnimationPackageWrapper payloads
+23  FBox        bounds min (float3), bounds max (float3)
+47  byte        bounds valid flag
+48  FSphere     centre (float3), radius (float)
+64  9 bytes     fixed tag block: int32 4, int32 5, byte 1
     FCompactIndex  material reference -> a Shader   (see materials.md)
     float3      scale
     float3      origin
     int3        rotation
     float, float, int32
     zero padding
```

The shared 18-byte prefix narrows the previously unexplained gap ahead of the Havok magic in an
`AnimationPackageWrapper` from 34 bytes to 16.

**The offsets above are `NEWPlayerHands`'; they are not universal.** The tag block sits at 64 there
and at 54 in `WP_PistolMesh`, so the leading header is not a fixed length. Anything that needs a
field after the bounds — the material reference does — must find the tag block by searching rather
than by adding up the offsets above. `ReadHeader` and `ReadSockets` still use the fixed offset and
so are only reliable for meshes shaped like the hands; both validate their result and return nothing
rather than garbage when it does not check out.

For `NEWPlayerHands` the bounds are `(-16, -67.9, -64)` to `(120, 67.9, 23.33)`, which contains
every decoded vertex position and is in the same centimetre space as the skeleton.

## Socket table

`CONFIRMED_BYTES`. Two parallel `FCompactIndex`-counted `FName` arrays: socket names, then the bone
each socket attaches to.

`NEWPlayerHands` declares 19 sockets:

| Socket | Bone |
|---|---|
| `Wrench`, `Pistol`, `Launcher`, `Crossbow`, `TommyGun`, `FireballSocket`, `IrritantBall`, `butt`, `WrenchRibbonSocket`, `PlayerGathererGun` | `R_Grip` |
| `Chem`, `FirePlasmid`, `IceShards`, `ParasiteSocket` | `Bip01_L_Hand` |
| `PustuleBirth`, `bip01_headnub` | `bip01_head` |
| `GatherSave` | `Bip01_R_Hand` |
| `GathererAttach` | `Bip01_Spine` |
| `CSphoto` | `IKbindLhandDummy` |

`ProtectorRosie` (Big Daddy) declares `RivetGunSocket`, `SmokeStack`, `SteamLeakA/B/C`, `eyes` and
`HeadGear`, so the table is not specific to the first-person mesh.

**Every weapon socket resolves to `R_Grip`**, a bone the hand skeleton also carries. That closes the
weapon-attachment half of the first-person requirement: the pistol hangs off `R_Grip`, which the
animations drive.

Note the case difference — the mesh writes `R_Grip`, the skeleton writes `R_grip` — so bone lookup
must be case-insensitive.

The socket-table offset is currently found by skipping the zero padding after the header's fixed
fields. That is a weak locator, so the reader validates the result and returns **nothing** rather
than emitting `None` entries when the table does not check out. A regression test asserts that no
mesh ever yields a garbage socket.

## Vertex format

`CONFIRMED_BYTES` for the record layout; the containing arrays are not yet parsed.

Skinned vertices are 64 bytes:

```
+0   float3            position
+12  float3            tangent      (unit)
+24  float3            binormal     (unit)
+36  float3            normal       (unit)
+48  float, float      u, v
+56  4 x (uint8 bone, uint8 weight)  interleaved influences, weights summing to 255
```

Rigid vertices are 57 bytes: the same through the UVs, then a single `uint8` bone index and no
weights. `FireSpread_Mesh` uses this form.

Evidence: scanning `NEWPlayerHands` for records whose tangent, binormal and normal are all unit
length **and** whose four weights sum to exactly 255 yields 6,629 vertices in 42 contiguous runs,
the largest being 3,469 vertices. Positions land inside the declared bounds and the UVs occupy a
sensible 0..1 range.

Index buffers are `uint16` and sit immediately before their vertex block — confirmed on
`FireSpread_Mesh`, whose 36 indices form the expected `0,1,2 / 2,3,0` quad pattern over 24 vertices.

## Bone map

`CONFIRMED_BYTES`. Vertex bone indices are **mesh-local**, not skeleton indices. A `uint16` bone map
translates them.

For `NEWPlayerHands` it has 38 entries:

```
4, 25, 5, 23, 26, 46, 6, 27, 7, 28, 29, 8, 30, 9, 13, 34, 10, 31, 19, 40, 37, 16, 32, 20, ...
```

which resolves to `Bip01_L_UpperArm`, `Bip01_R_UpperArm`, `Bip01_L_Forearm`, `Bip01_L_ForeTwist1`,
`Bip01_R_Forearm`, … — left and right interleaved, exactly what a two-armed viewmodel would use.

Validated geometrically, by mean distance from a vertex to its dominant bone:

| Mapping | Mean distance |
|---|---|
| Through the bone map | **6.73** |
| Identity | 56.87 |
| Shuffled bone map | 31.0 – 40.0 |

## Geometry container

`CONFIRMED_BYTES`. A chain of `FCompactIndex`-counted arrays that fit together exactly:

```
FCompactIndex boneMapCount,  boneMapCount x uint16    38 entries, ends on the index count
FCompactIndex indexCount,    indexCount   x uint16    26,178 indices, ends on the vertex header
4 bytes                                               unknown, observed as 1
FCompactIndex skinnedCount,  skinnedCount x 64 bytes  3,469 skinned vertices
FCompactIndex rigidCount,    rigidCount   x 57 bytes  1,383 rigid vertices
```

The largest index (4851) is exactly one less than the combined pool (3469 + 1383 = 4852).

### Index pool ordering

`CONFIRMED_BYTES`, and the subtlest detail in the format. The index buffer addresses the **rigid
block first**, even though the skinned block is stored ahead of it in the file.

Every count-based check passes under either ordering — index count divisible by three, no degenerate
triangles, every vertex referenced, max index equal to pool size minus one. What separates them is
triangle size: median edge 0.87 with rigid-first versus 44.04 with skinned-first, on a mesh only
~140 units across. Rendering the wrong order gives visibly shattered geometry, which is how the bug
was actually caught; the regression test now asserts the median edge directly.

## Result

`NEWPlayerHands` decodes to 4,852 vertices, 8,726 triangles, 38 vertex groups, UVs and per-vertex
skin weights summing to 1. Exported to Blender it deforms correctly under the pistol animations.

## An empty skinned block (CONFIRMED_BYTES)

A weapon's parts are hinged, not deformed, so **every vertex is bound rigidly to one bone**. Those
meshes still write the skinned block — with a count of zero — and the rigid block follows it:

```
FCompactIndex 0          skinned count, an empty block rather than an absent one
FCompactIndex rigidCount
rigidCount x 57 bytes
```

The reader treated a count of zero as "no vertex block here" and gave up, which is why the weapon
viewmodels resolved their sockets, skeletons, animations and materials and then drew nothing.
Accepting the zero took `SkeletalMesh` decoding from **370 of 972 exports (38.1%) to 954 (98.1%)**,
and `ShockGame.U` from 5 of 10 to all 10.

`WP_GrenadeLauncherMesh` decodes to 5,386 rigid vertices, `TommyGunMESH` to 4,985,
`WP_CrossbowMesh` to 10,151 and `WP_ChemicalThrowerMesh` to 7,936. All render as recognisable,
textured weapons.

The 18 exports that still fail are all doors — `LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`,
`Atlas_labs_doorAnim` and `GathererDoorAnimMesh`, four distinct meshes across the packages.

## UModel has the whole payload, and it says there IS a section table

`CONFIRMED_EXTERNAL`, from `UModel-master/Unreal/UnMeshBioshock.cpp`. **Not implemented — recorded so
the next session starts from it rather than from bytes.** Full detail and cross-checks in
[reference-comparison.md](reference-comparison.md) §3.

Two things it settles that this note and `HANDOFF.md` currently record as unknown:

1. **A skeletal mesh carries a per-material section table.** `FStaticLODModelBio` begins
   `TArray<FSkelMeshSection> Sections` — nine `uint16`s each, `MaterialIndex, MinStreamIndex,
   MinWedgeIndex, MaxWedgeIndex, NumStreamIndices, BoneIndex, fE, FirstFace, NumFaces` — with the
   comment "1 section = 1 material". That is the same pairing the `StaticMesh` path already uses, and
   it is the **153** meshes the diagnostic sweep reports as
   `mesh-materials-without-sections`, which today draw entirely in one material.
2. **The payload can be walked from the front.** The order is bounds, versioned header, `Textures`
   (the material array), scale/origin/rotation, four unknown scalars, `RefSkeleton`, `Animation`,
   `SkeletalDepth`, the three socket arrays, then the LOD models. This project locates the vertex
   chain by *search*, and open question 4 records byte-exact accounting as the thing that would
   settle the container outright.

**Caveat, and it is a real one.** UModel targets the **original** game. The Remastered static vertex
is already 48 bytes against the original's 24, so a field-by-field check against shipped Remastered
bytes is required before any of this becomes a parser. `t3_hdrSV` (§below) is what selects layout
variants and is the first thing to read.

## The "tag block" is a versioned object header

`CONFIRMED_EXTERNAL`. `MaterialReader` searches for `04 00 00 00 05 00 00 00` and calls it a tag
block whose position varies between meshes. It is UModel's `TRIBES_HDR` (`UnCore.h:2219`): an
`int32 check` — 3 means two version fields follow, 4 means one — then the version(s). So the pattern
is `check = 4`, `t3_hdrSV = 5`; the static mesh's `int32 4, int32 8` is the same header with
subversion 8. Its position varies because the data before it does.

`t3_hdrSV` **gates the layout** in UModel's reader (`< 4` selects BioShock 1's vertex blocks, `>= 3`
and `>= 5` add fields), so reading it as a version rather than matching it as a pattern is the
precondition for a forward walk.

## More than one LOD per payload (LIKELY)

`WP_CrossbowMesh`'s payload is 1,405,352 bytes and the geometry chain ends at 655,675, leaving
749,677 bytes. The 12-byte pattern `int32 4, int32 3, int32 2` appears both just before the first
bone map and again just after the chain ends, which reads as a second copy of the same structure —
almost certainly a further LOD. The reader takes the first chain it finds, which is the highest
detail one.

## Still unknown

- **Per-triangle material sections.** Three of `ShockGame.U`'s ten meshes name two materials —
  `WP_CrossbowMesh` uses `Crossbow_Shader` and `group_02_mat`, `TommyGunMESH` uses
  `tommygun2_diffuse` and `ammostandard_diffuse_shader`, `PlasmidEquipMESH` two of its own. Which
  triangles use which is not decoded, so only the first is applied and part of the mesh is textured
  wrongly. Searching the payload for a table of (firstIndex, triangleCount) pairs that tiles the
  index buffer finds nothing at either 16- or 32-bit width, so the sections are stored some other
  way. **The preview and the details panel now say so** rather than showing it silently.
- LODs. See above: there is more than one, and only the first is read.
- The declared bounds cover the animated range rather than the bind pose, so they are not a hull of
  the rest-pose geometry.
- Whether other meshes use additional vertex strides. The reader validates each block's tangent,
  binormal and normal before accepting it, so an unknown stride yields no geometry rather than
  garbage.

---

## Section table — `CONFIRMED_BYTES`

**Implementation:** `Core/Mesh/SkeletalMeshSections.cs` · **Tests:** `SkeletalMeshSectionTests.cs`

A skeletal mesh **does** carry a table pairing triangle runs with material slots, and it is now
read. 153 meshes were drawing entirely in their first material because it was not.

```
AttachCoords            // the socket table, already decoded
CI  LODCount
8 B TRIBES_HDR          // int32 check = 4, int32 subversion
CI  SectionCount
18 B x SectionCount     // FSkelMeshSection: nine uint16
CI  BoneMapCount        // ← the geometry chain this project already reads
```

`FSkelMeshSection` is UModel's, from `UnMeshBioshock.cpp`'s `FStaticLODModelBio`, commented there as
"1 section = 1 material":

```
uint16 MaterialIndex, MinStreamIndex, MinWedgeIndex, MaxWedgeIndex,
       NumStreamIndices, BoneIndex, fE, FirstFace, NumFaces
```

### Why it was reachable after all

The handoff called this "the biggest single piece of work left in Phase 1" and said it needed the
payload walked from the front. It turned out to be much shorter: **the socket table already sits
immediately before it**, and the socket reader already walks there. `RefSkeleton` — the record this
project has never decoded — is empty in every shipped mesh, because BioShock keeps its skeletons in
Havok packfiles, and the existing reader steps over it as a run of zeros.

### What makes it a decode

**The section array must end exactly where the bone map begins**, and the bone map is found by a
completely unrelated route: `SkeletalMeshReader.DescribeGeometry` searches for the vertex chain from
the other end of the payload. Two independent walks agreeing on one byte offset is the evidence; a
wrong section count lands anywhere else.

| measured over all 21 map packages | |
|---|---|
| Skeletal meshes with geometry | **944** |
| …yielding a section table | **331 (35%)** |
| Sections | **392** |
| Meshes with more than one material | **61** |

The 35% is a property of the route, not a failure: a mesh whose socket table does not validate
cannot be reached this way and draws in one material exactly as before. `WP_CrossbowMesh` and
`TommyGunMESH` — both named in the handoff — now report 2 sections each, materials 0 and 1.

### ~~An unexplained discrepancy~~ — CLOSED. Nothing was short; `FirstFace` is not where a section starts

The note here used to read: *"4 meshes of 331 have sections reaching past the end of the index buffer
this project found, by 2, 5, 5 and 8 faces… `UNKNOWN` which side is short. This project locates the
index buffer by search rather than by walking the payload, which makes it the more likely
candidate."*

**That suspicion is refuted, and the index buffer was never short.** Swept over every shipped section
table — the 21 map packages plus `ShockGame.U`:

| claim, over 337 tables | agrees | disagrees |
|---|---|---|
| The sections' `NumFaces` add up to **exactly** the index buffer's face count | **337** | **0** |
| `MinStreamIndex` equals the running index total (sections are contiguous) | 336 | 1 |
| `FirstFace` equals the running face total | 333 | **4** |
| The largest `MaxWedgeIndex` is the vertex pool's last index | 337 | 0 |

The first row settles it. If a buffer were short by 8 faces, the section counts could not add up to
its length; they do, on every mesh in the game. **The sections tile the buffer with no gaps**, and
the four "overrunning" meshes are the ones whose stored `FirstFace` is a few faces larger than where
the section actually begins:

| mesh | `FirstFace` | where the section starts | drift |
|---|---|---|---|
| `TommyGunMESH` | 4,926 | 4,924 | 2 |
| `TunnelCollapse_Mesh` | 14,493 | 14,487 | 6 |
| `SubAnim_Mesh` | 9,525 | 9,519 | 6 |
| `WP_CrossbowMesh` | 7,148 | 7,140 | 8 |

`MinStreamIndex` confirms the true position independently: on `WP_CrossbowMesh` it is 21,420, which
is 7,140 × 3, not 7,148 × 3. Its single exception is arithmetic rather than semantic —
`CoreTop_Mesh`'s second section stores 10,244 where the running index total is 75,780, and
**75,780 − 65,536 = 10,244**: the field is a `uint16` and it wrapped.

**What `FirstFace` means on those four is `UNKNOWN`** and it is preserved rather than corrected —
plausibly a face index in a pre-optimisation triangle list, which is a hypothesis with no evidence
behind it yet.

**The clamp is gone.** A section is now placed at the running total of the sections before it, which
cannot overrun by construction, and the reader instead asserts the sum identity above. A table that
fails it is reported as no table rather than clamped into agreement: a wrong material pairing is
invisible to every count, while drawing in one material is a visible, honest degradation.
