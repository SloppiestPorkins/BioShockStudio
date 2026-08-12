# Open questions

Priority order, driven by the pistol definition of done. Each entry names the evidence that would
close it, so none of them get closed by guessing.

## 1. `AnimationPackageRoot` layout — blocking

The Havok root object's class. Everything downstream (skeleton, animations, binding) hangs off it,
and it is where UEViewer stops.

**How to close it:** parse the `__data__` section's virtual fixups to find the root object's byte
range, then diff that range across several `AnimationPackageWrapper` instances of differing size
(`UAPW_HandInsectAnim` at 11,698 bytes vs `UAPW_NEWPlayerHands` at 920,658) to separate fixed
header fields from per-content arrays.

## 2. Packfile fixups — blocking

Local, global and virtual fixup tables are located but not parsed. Without them there is no object
graph, and pointers inside section data cannot be resolved.

**How to close it:** stock Havok 2012 layout, verifiable directly — every local fixup's source and
destination must land inside the section's data region.

## 3. Havok spline decompression — blocking

`hkaSplineCompressedAnimation` is confirmed as the compression in use.

**How to close it:** study DSAnimStudio and HavokLib for the 2012-era block layout, then validate
against a decoded pistol animation whose duration matches its `SharedSkeletonAnimationMetadata`.

## 4. `SkeletalMesh` payload layout — blocking for Stage 1

962 instances. Nothing decoded yet.

**How to close it:** start with the smallest `SkeletalMesh` rather than `NEWPlayerHands`, and
cross-check vertex and bone counts against UEViewer where it succeeds (brief §20).

## 5. `HkMeshProxy` — high value

8,961 instances. The name suggests the bridge between an Unreal mesh and Havok data, which could be
the real, non-name-based mesh↔skeleton link the resolver needs.

**How to close it:** dump payloads for a few instances and look for object references into
`SkeletalMesh` and `AnimationPackageWrapper` exports.

## 6. The 34-byte Unreal prefix on `AnimationPackageWrapper`

Between the export payload start and the Havok magic. Preserved, not skipped by a hardcoded
constant — detection is by magic search.

**How to close it:** compare the prefix across wrappers of differing size.

## 7. Export record `Unknown32` and `TrailingUnknown32`

Two int32s in every export record. `Unknown32` (after the outer index) is zero in every sample
inspected; `TrailingUnknown32` is 0 or 1.

**How to close it:** correlate `TrailingUnknown32` against object flags and class across all
812,435 indexed exports — cheap, since the index already exists.

## 8. Section tag numeric suffixes

`chemical200249441`, `grenadel1663367201`, `scripted2306259077`. `HYPOTHESIS`: a hash of the
untruncated name appended after 19-byte truncation. Nothing depends on this.

## 9. Bulk content (`.blk`)

~8 GB across 201 chunks, referenced via `CachedBulkDataSize`. Almost certainly the
high-resolution textures. Not on the critical path for animation.

## 10. ~~Third-person packages lack per-weapon sections~~ — CLOSED

`CONFIRMED_BYTES`. `UAPW_AggressorBabyJane` ships 4 sections
(`__classnames__`, `__types__`, `default`, `__data__`) with no per-weapon partitioning, and its
class table additionally carries `hkaRagdollInstance`, `hkaSkeletonMapper`, `hkpRigidBody`,
`hkpRagdollConstraintData` and `hkpCapsuleShape` — none of which appear in the first-person hands
package. Two independent structural first-person/third-person discriminators, neither name-based.
Tested in `HavokPackfileTests`.
