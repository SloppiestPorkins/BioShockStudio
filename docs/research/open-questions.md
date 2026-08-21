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

`UNKNOWN` remains: the exact 12-bit quantisation midpoint (error under 0.0005).

**`m_blendHint` is settled** — `CONFIRMED_EXTERNAL`, `hkaAnimationBinding.h`:
`enum BlendHint { NORMAL = 0, ADDITIVE = 1 }`. Every shipped animation is 0, by census, so additive
blending is ruled out as an explanation for anything.

**`m_partitionIndices` is now read and is empty everywhere it was checked.** Havok lets a binding
name the skeleton partitions an animation is sampled against, and `hkaSkeleton` lets a skeleton
declare them. On `AggressorBabyJane`: 457 bindings, **0 partition indices**; six skeletons,
**0 partitions**. That eliminates the partial-body reading of the §6.0c fire animations.
`SkeletonPartitionTests`.

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

## 4c. Per-triangle material sections — CLOSED for `StaticMesh`, located for `SkeletalMesh`

**`StaticMesh`: closed.** `CONFIRMED_BYTES` — `CI NumSections` then 14 bytes per section, before the
vertex block, from Nyko's SDK and verified field by field. Section *N* draws with `Materials[N]` on
all 8,668 shipped static meshes, through one shared `MeshSurfaceResolver`.

**`SkeletalMesh`: the table exists and this note's guess about where was wrong.** It is not near the
chain — it is the first array of the LOD model, `TArray<FSkelMeshSection>`, and the guess that it
"may belong to a per-LOD header" was right in spirit. See §11d. The scan for (firstIndex,
triangleCount) pairs failed because the record is nine `uint16`s, not a pair.

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

## 10. ~~`MaskMaterial` nested struct sizes~~ — CLOSED

`CONFIRMED_BYTES`. **A struct property's declared size omits the size-encoding bytes of its own
nested properties.** Census of every struct-valued property on every material in the game: of 14,610
`MaskMaterial` structs, 9,152 declare their size exactly — all of them having no nested property with
an explicit size — and the other 5,458 are short by exactly their nested size bytes, with no other
cases. The correction is applied only when the nested walk lands exactly on a terminator, so a struct
that is not a property list (`Color` is four raw BGRA bytes, and the game ships 6,329) is left alone.

**Every material in the game now decodes to its terminator: 13,545 materials, 0 partial.** Held by
`StructSizeTests`. Nyko's material note corroborates the shape independently — a `MaskMaterial` is
`{ Material Material; EMaskChannel Channel }`, a nested property list.

## 10b. ~~A `StaticMesh`'s material reference~~ — CLOSED

`CONFIRMED_BYTES`. It is an ordinary `Materials` tagged property, read forwards from the start of the
payload; the walk used to end truncated there because of §10, which is now fixed. **10,158 of 10,198
slots resolve**, and the 40 that do not are declared nulls or references truncated by a short array
size — those keep their position so the section table still indexes correctly.

The "tag block" mentioned here, `int32 4, int32 8`, is not a tag at all: it is the Vengeance
versioned object header (`check = 4`, subversion 8). See [skeletalmesh.md](skeletalmesh.md).

## 11. `OutputBlending` and `MaterialVisualType` — half CLOSED

**`MaterialVisualType` is settled: `CONFIRMED_EXTERNAL`, and it is not a rendering field at all.**
Nyko's material note names it as the **physical-surface class** — Stone, Glass, Flesh, Water — which
drives footstep, impact and decal selection, and explicitly *not* the shader. So the renderer is
right to ignore it, and the guess that it was "a shader-variant selector" was wrong. It is still
carried through the exporter uninterpreted, which is now the correct treatment rather than an
admission.

The same note names the field that *is* the class discriminator, **`MaterialType`**, a byte enum
whose ordinals it gives verbatim (`9 Shader`, `10 FluidShader`, `16 FacingShader`, `18 PlantShader`,
and the `*Start`/`*End` sentinels that let the engine range-check "is this a RenderedMaterial?").
**No shipped material serialises it** — checked on `PlantShader`, `FluidShader` and `LightBeamShader`
objects, which carry `MaterialVisualType` but never `MaterialType` — so it is a class default and
there is nothing to read. The class name in the export table is the discriminator this reader has.

`OutputBlending` remains `UNKNOWN`. A blend mode, a single byte on `Shader` objects, carried through
the exporter uninterpreted.

`OutputBlending` is absent on 687 of `1-Medical`'s 819 materials and is 1, 2 or 3 on the rest
(57, 61 and 14). That distribution invites reading it as Unreal's `EBlendMode` — masked, translucent,
additive — but correlating each value against the alpha actually present in that material's diffuse
texture does not support it: materials with no blend value are the ones most likely to have graded
alpha. **So the renderer does not use it.** Transparency is driven by the texture's observed alpha
instead, which is a fact rather than an interpretation.

## 11b. Material classes other than `Shader` — MOSTLY CLOSED

**`CONFIRMED_EXTERNAL` then `CONFIRMED_BYTES`, and it took reading one file.** Nyko's
`BioShock_Materials_And_Shaders.md` states that every material class is a plain tagged-property
object with no custom serialisation, and that texture references are ordinary objrefs. The reader
already parsed all of them; what it got wrong was deciding a texture binding by **slot name**, from a
list of thirteen taken off `Shader` and `FacingShader`. Every other class names its slots
differently — `PlantShader` uses `AliveDiffuse`, `FluidShader` `WaterDiffuseMap`, `LightBeamShader`
`FalloffMap`. See [materials.md](materials.md) for the byte evidence and the new rule.

Measured by the same sweep that found it — `mesh-no-diffuse`, over all 9,684 mesh exports:

| material class | before | after |
|---|---|---|
| **total** | **755** | **240** |
| `FluidShader` | 249 | 83 |
| `PlantShader` | 183 | **0** |
| `Texture` named directly | 165 | **0** (the second fix, below) |
| `LightBeamShader` | 64 | 64 |
| `Shader` | 51 | 51 |
| `MaterialSwitch` | 38 | 38 |
| `MaterialSequence` | 4 | 4 |
| `LayeredShader` | 1 | **0** |

Since this table was measured, the `MaterialSwitch` default child has been decoded: its explicit
`Material` object property is followed, while its candidate-array runtime selection remains
uninterpreted. A whole-game container sweep now accounts for **45** such rendered defaults (14,251
rendered material defaults total), all decoded with zero failures. Re-run `diagnose` before changing
the historical per-mesh `mesh-no-diffuse` figures above.

Counting meshes that end up with **no base colour at all** — no diffuse, or every surface unresolved —
that is **862 → 347 of 9,684**, so **96.4% of the game's meshes now carry a base colour**, against
91.1% before and 73.9% two sessions ago.

**A `Texture` named in a material slot is a material** — the `BitmapMaterial` branch of the class
tree, drawn by `MaterialFactory_BitmapMaterial` as "diffuse and alpha straight from one texture" —
and its base colour is itself. That is the second fix and it accounts for the 162.

**What is left, and why each is not simply a bug:**

- **`LightBeamShader` (64) genuinely has no base colour.** It binds `FalloffMap` and `DustMap` and
  its look comes from `BeamColor`/`BeamBrightness`. Reporting "no diffuse" is correct; what the
  exporter should do with a light shaft is a separate question.
- **`FluidShader` (83)** — 63 bind textures but no `WaterDiffuseMap`, 20 bind none. Worth one look at
  what a water material with no diffuse map actually declares.
- **`MaterialSequence` is a Modifier**: it serialises `SequenceItems` structs, whose item layout,
  timing and runtime child-selection semantics have not been decoded. `MaterialSwitch` is no longer
  in this bucket: its explicit default child is followed, but its candidate-array selection remains
  intentionally unresolved.
- **`Shader` (51)** — the only group where "no base colour" may be intended. `FireSpread_Mesh`'s
  `invisible_shader` is one, and is correct.

## 11c. Texture `Format` ordinal 12 — CLOSED, and two sources disagreed

`CONFIRMED_EXTERNAL` (UModel) then `CONFIRMED_BYTES`. Ordinal 12 is **DXT5N** — an ordinary DXT5
block carrying the normal in **alpha and green** — and *not* 3DC/BC5 as Nyko's texture note states.
UModel's BioShock branch remaps it with the comment "Bioshock used 3DC name, but real format is
DXT5N", and the decoded pixels agree: X and Y both centre on 128 and **0 of 4,096 texels violate
`x² + y² ≤ 1`**, where the BC5 reading puts green at 57 and produces a magenta image.

**274 exports, 64 distinct names, all normal maps, all now decoding.** `texture-undecodable` fell
from 320 to 46 game-wide. See [bulkcontent.md](bulkcontent.md) and
[reference-comparison.md](reference-comparison.md) §1; `NormalMapFormatTests` holds it.

What remains under this heading is the **46 exports with no `Format` property at all**, whose 42
distinct names are all editor sprites or engine placeholders. Whether they are meant to hold pixels
is `UNKNOWN` and one hand-decode would settle it.

## 11d. A `SkeletalMesh` section table — the `UNKNOWN` is closed, the work is not

`CONFIRMED_EXTERNAL`, from `UModel-master/Unreal/UnMeshBioshock.cpp`. HANDOFF item 6 and
`docs/QUALITY.md` §2 both record it as unknown whether the skeletal container carries a per-material
run table. **It does:** `FStaticLODModelBio` opens with `TArray<FSkelMeshSection> Sections`, nine
`uint16`s each — `MaterialIndex, MinStreamIndex, MinWedgeIndex, MaxWedgeIndex, NumStreamIndices,
BoneIndex, fE, FirstFace, NumFaces` — commented "1 section = 1 material".

That is the **153** meshes `diagnose` reports as `mesh-materials-without-sections`, including
`TommyGunMESH`, `PlasmidEquipMESH` and `WP_CrossbowMesh`.

**Nothing is implemented on the strength of this.** It requires walking the payload from the front
rather than searching for the vertex chain, and UModel targets the *original* game — the Remastered
static vertex is already 48 bytes against 24, so every field needs checking against shipped bytes
first. The same source also gives the full payload order and shows that the "tag block" this project
searches for is a versioned object header whose subversion selects the layout. See
[skeletalmesh.md](skeletalmesh.md) and [reference-comparison.md](reference-comparison.md) §3–§4.

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
