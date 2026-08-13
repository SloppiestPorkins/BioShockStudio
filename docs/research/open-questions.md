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

## 4. ~~`SkeletalMesh` payload layout~~ — MOSTLY CLOSED

`CONFIRMED_BYTES` for the header, socket table, bone map, index buffer and both vertex blocks. See
[skeletalmesh.md](skeletalmesh.md).

**954 of 972 exports (98.1%) now decode.** The blocker was a skinned block with a count of zero: a
weapon's vertices are all rigidly bound, so it writes an empty skinned block and the rigid block
follows, and the reader read that zero as "no block here". See [skeletalmesh.md](skeletalmesh.md).

This entry previously said roughly 40% decoded and blamed a stride or container variant, and
claimed the same meshes failed to resolve a material too, "consistent with one cause rather than
two". **Both were wrong.** The stride was the ordinary 57-byte rigid one all along, and the material
failure was the counted material array being read as a fixed `byte 1`.

`UNKNOWN` remains: 18 exports still fail, all doors — `LowRentDoor_Mesh`,
`Sliding512SingleDoorMesh`, `Atlas_labs_doorAnim`, `GathererDoorAnimMesh`.

## 4c. Per-triangle material sections

`UNKNOWN`. A mesh may name several materials — `WP_CrossbowMesh` names two — and which triangles use
which is not decoded, so only the first is applied and part of the mesh is textured wrongly. The
preview and the details panel report this rather than showing it silently.

**How to close it:** the obvious encoding is a table of (firstIndex, triangleCount) pairs tiling the
index buffer, and scanning every offset at 16- and 32-bit width finds no such table, so it is stored
another way. Note there is more than one LOD per payload, so a section table may belong to a
per-LOD header rather than sitting near the chain.

## 4b. ~~`StaticMesh` geometry~~ — CLOSED

`CONFIRMED_BYTES`. A shorter chain than the skinned one: a single 48-byte vertex block with no UVs
inline, then one or more separate UV streams, then the index buffer. No bone map, no skin weights.
All 8,668 shipped exports decode, and every decoded position falls inside the mesh's own declared
bounding box. See [staticmesh.md](staticmesh.md).

`UNKNOWN` remains: the trailing block on every mesh (almost certainly the kDOP collision tree), and
which triangles belong to which material when a mesh has more than one.

## 5. ~~`HkMeshProxy`~~ — CLOSED, and the guess was wrong

`CONFIRMED_BYTES`. Not a mesh-to-Havok or mesh-to-material bridge. Their outer is a `StaticMesh`,
their property list is empty, and the payload is collision data — a friction/restitution triple and a
transform. Nothing in the mesh, skeleton or material path uses them. See
[materials.md](materials.md).

## 6. ~~The first-person pistol mesh~~ — CLOSED

`CONFIRMED_BYTES`. It is `WP_PistolMesh` in `Build/Final/BakedScripts/pc/ShockGame.U`, not in any map
package, and it has a skeleton and animations of its own. See [firstperson.md](firstperson.md).

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

## 10. `MaskMaterial` nested struct sizes

`UNKNOWN`, and it is what limits material coverage. A `MaskMaterial` struct is itself a property
list, and its declared size is one byte short of its content when that content includes a sized
reference — so the walk of the containing shader loses alignment there. Roughly half the shaders in
the larger packages stop at that point and are reported as partial.

The byte evidence for both the working and the failing case is in [materials.md](materials.md).

**How to close it:** decode `MaskMaterial` as a nested list on a sample of both shapes and find what
the declared size is actually counting. The one-byte difference lines up exactly with the inner
`Object` property's explicit size byte, which is suggestive and not sufficient.

## 10b. A `StaticMesh`'s material reference

`UNKNOWN`, and it is why only 22 of 630 drawable meshes in `1-Medical` resolve a diffuse texture.
The tag-block search that works for a `SkeletalMesh` does not apply: a static mesh's tag block is
`int32 4, int32 8, int32 1` and carries no material reference after it. Its `Materials` array
property is the right place to look, and the property walk currently ends truncated there. Byte
evidence, including a candidate reading that resolves to the right class and name, is in
[materials.md](materials.md).

## 11. `OutputBlending` and `MaterialVisualType`

`UNKNOWN`. A blend mode and a shader-variant selector, both single bytes on `Shader` objects, both
carried through the exporter uninterpreted.

`OutputBlending` is absent on 687 of `1-Medical`'s 819 materials and is 1, 2 or 3 on the rest
(57, 61 and 14). That distribution invites reading it as Unreal's `EBlendMode` — masked, translucent,
additive — but correlating each value against the alpha actually present in that material's diffuse
texture does not support it: materials with no blend value are the ones most likely to have graded
alpha. **So the renderer does not use it.** Transparency is driven by the texture's observed alpha
instead, which is a fact rather than an interpretation.

## 12. Unreal import

`UNKNOWN`. The FBX the exporter writes is validated by round trip through Blender, but nothing has
been imported into Unreal Engine 5 and `tools/ue5/import_bioshock.py` has never been run. Two things
would be settled by one import: whether Unreal takes the `SOCKET_*` null nodes as sockets or as
bones, and whether the notify API in that script exists under the name it uses.

## 13. ~~Bulk content (`.blk`)~~ — CLOSED

`CONFIRMED_BYTES`. It is the high-resolution textures, and it was on the critical path after all:
most of the game's art ships with its top mips stripped out, so the packages carry chains topping
out at 64 square. `Catalog.bdc` indexes the 201 chunks by texture name, and every one of its 5,777
entries has a 32,768-aligned offset and a size that is an exact mip-chain sum. Recovered mips are
verified against the level the package kept — typical agreement 1-2%. See
[bulkcontent.md](bulkcontent.md).

`UNKNOWN` remains: the 23-byte header, and the nine textures per package whose size does not
decompose against their declared dimensions.

## 14. ~~Third-person packages lack per-weapon sections~~ — CLOSED

`CONFIRMED_BYTES`. See [firstperson.md](firstperson.md).
