# Open questions

Priority order, driven by the pistol definition of done. Each entry names the evidence that would
close it, so none of them get closed by guessing.

## 1. ~~`AnimationPackageRoot` layout~~ — CLOSED

`CONFIRMED_BYTES`. A skeleton reference plus a flat table of
{animationName, ownerName, hkaAnimationBinding*}. See [animationpackage.md](animationpackage.md).

`UNKNOWN` remains: bytes +4..+15 of the root, zero in every sample. Not read, not assumed to be
padding.

## 2. ~~Packfile fixups~~ — CLOSED

`CONFIRMED_BYTES`. Local 8 bytes, global and virtual 12 bytes, regions padded to 16 with `0xFF`.
Virtual fixups are the object table. See [havok.md](havok.md).

## 3. ~~Havok spline decompression~~ — CLOSED

`CONFIRMED_BYTES`. See [havok-compression.md](havok-compression.md). All 130 hands animations and
all third-person character animations decode with zero failures.

`UNKNOWN` remains: the exact 12-bit quantisation midpoint (error under 0.0005), and the meaning of
`m_blendHint`.

## 4. `SkeletalMesh` payload layout — blocking for a complete asset

962 instances, nothing decoded yet. This is now the largest remaining gap: the animation pipeline is
complete end to end, but there is no mesh to attach it to.

Reconnaissance is recorded in [skeletalmesh.md](skeletalmesh.md): the payload opens with a shared
2K header and what reads as an `FBoxSphereBounds`.

**How to close it:** start with `FireSpread_Mesh` (4,170 bytes) rather than `NEWPlayerHands`, and
cross-check vertex and bone counts against UEViewer where it succeeds. The skeleton is already
decoded, so skin-weight bone indices have something to validate against.

## 5. `HkMeshProxy` — high value

8,961 instances. The name suggests the bridge between an Unreal mesh and Havok data, which would be
the non-name-based mesh-to-skeleton link the resolver needs.

**How to close it:** dump payloads for a few instances and look for object references into
`SkeletalMesh` and `AnimationPackageWrapper` exports.

## 6. The first-person pistol mesh

`UNKNOWN`. Not located. It is not a `SkeletalMesh` named `Pistol`; `WP_AI_Pistol` is the
third-person `StaticMesh` carried by NPCs.

**How to close it:** the hands package proves the weapon association is structural (the `pistol`
Havok section). Follow object references out of the weapon's Unreal objects rather than searching by
name.

## 7. The 34-byte Unreal prefix on `AnimationPackageWrapper`

`CONFIRMED_BYTES` that it is 34 bytes for all three wrappers tested. The first 18 bytes are a header
shared with `SkeletalMesh` payloads (see [skeletalmesh.md](skeletalmesh.md)); the remaining 16 are
`UNKNOWN`. Preserved, not skipped by a hardcoded constant — detection is by magic search.

## 8. Export record `Unknown32` and `TrailingUnknown32`

Two int32s in every export record. `Unknown32` is zero in every sample inspected;
`TrailingUnknown32` is 0 or 1.

**How to close it:** correlate against object flags and class across all 812,435 indexed exports.

## 9. Section tag numeric suffixes

`chemical200249441`, `grenadel1663367201`. `HYPOTHESIS`: a hash appended after 19-byte truncation.
Corroborated in that the root table's owner names are the untruncated `ChemicalThrower` and
`GrenadeLauncher`. Nothing depends on this.

## 10. Bulk content (`.blk`)

~8 GB across 201 chunks, referenced via `CachedBulkDataSize`. Almost certainly the high-resolution
textures. Not on the critical path for animation.

## 11. ~~Third-person packages lack per-weapon sections~~ — CLOSED

`CONFIRMED_BYTES`. See [firstperson.md](firstperson.md).
