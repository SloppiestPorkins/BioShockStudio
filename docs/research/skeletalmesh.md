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
