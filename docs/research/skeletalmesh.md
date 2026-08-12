# SkeletalMesh

**Implementation:** `src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`
**Tests:** `tests/BioShockStudio.Tests/SkeletalMeshTests.cs`
**Status:** header and sockets implemented; geometry decoded but not yet exported; bone table unknown.

962 `SkeletalMesh` exports ship across the 21 packages, 46 of them in `0-Lighthouse.bsm`.

## Payload header

`CONFIRMED_BYTES`, verified across every `SkeletalMesh` in `0-Lighthouse.bsm`.

```
+0   23 bytes    header; its first 18 are shared with AnimationPackageWrapper payloads
+23  FBox        bounds min (float3), bounds max (float3)
+47  byte        bounds valid flag
+48  FSphere     centre (float3), radius (float)
+64  9 bytes     fixed tag block: int32 4, int32 5, byte 1
+73  FCompactIndex
     float3      scale
     float3      origin
     int3        rotation
     float, float, int32
     zero padding
```

The shared 18-byte prefix narrows the previously unexplained gap ahead of the Havok magic in an
`AnimationPackageWrapper` from 34 bytes to 16.

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

## What blocks a skinned export

`UNKNOWN`: **the mesh bone table.** Vertex bone indices are mesh-local (0..37 in the hands mesh) and
do **not** index the Havok skeleton directly. Tested geometrically: mapping mesh index *n* to
skeleton bone *n* gives a mean vertex-to-dominant-bone distance of 55.6 units, which is *worse* than
random permutations (43–50). So a bone table or bone map exists and has not been found.

It is not an `FName` array of bone names in the package name table: only 27 bone-like names exist
there against 47 skeleton bones, and no run of them appears in the payload.

Until that table is decoded, exporting the geometry would produce a mesh skinned to the wrong bones,
which is worse than exporting no mesh at all. The armature and animations export correctly today.

## Next steps

1. Find the bone table or per-chunk bone map. Likely candidates: a `uint16` bone-map array adjacent
   to each vertex chunk, or `HkMeshProxy` (8,961 instances), whose name suggests it bridges the
   Unreal mesh and the Havok skeleton.
2. Parse the LOD/section container so vertex and index blocks are located structurally rather than
   by scanning for geometric invariants.
3. Then: skinned mesh export to Blender, and FBX for UE5.
