# Materials

**Implementation:** `src/BioShockStudio.Core/Materials/MaterialReader.cs`, `Export/MaterialExporter.cs`
**Tests:** `tests/BioShockStudio.Tests/MaterialTests.cs`
**Status:** the mesh-to-shader link is decoded and meshes export textured.

## Every material class is an ordinary property list, and a texture binding is not a name on a list

`CONFIRMED_EXTERNAL` then `CONFIRMED_BYTES`. Nyko's
`Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Materials_And_Shaders.md` states it
plainly: **a material has no custom binary serialisation.** Every material class — `Shader`,
`FacingShader`, `FluidShader`, `PlantShader`, `LightBeamShader`, `MaterialSwitch`,
`MaterialSequence`, `LayeredShader` and the rest — is a stock UE2 object header plus a tagged
property block, and "texture references are objrefs" resolved through the package tables.

This reader already parsed all of them. What it got wrong was **which properties count as a texture
binding**: it held a list of thirteen slot names taken from `Shader` and `FacingShader`, and every
other class names its slots differently. Read off shipped objects:

| class | base colour | other bindings |
|---|---|---|
| `Shader` | `Diffuse` | `NormalMap`, `SpecularColorMap`, … |
| `FacingShader` | `FacingDiffuse` / `EdgeDiffuse` | — |
| `PlantShader` | **`AliveDiffuse`** | `AliveNormalMap`, `AliveSpecularColorMap` |
| `FluidShader` | **`WaterDiffuseMap`** | `NormalMap` |
| `LightBeamShader` | none | **`FalloffMap`**, `DustMap` |

So the rule is now the one the note describes rather than a list: **a texture binding is an `Object`
property whose reference resolves to an object of class `Texture`.** That is strictly more permissive
than the old list — every binding it used to find, it still finds — and it cannot invent one, because
the reference has to actually name a `Texture`.

**The class check is load-bearing, not decoration.** A `FluidShader` also carries `Object` properties
naming `TextureRotator` and `TexturePanner` objects — `CoverageMaskAnimator`,
`DiffuseTextureAnimator1`, `NormalTextureAnimator1`, `SpecularAnimator2` and more. Those are
`TexModifier`s, the UV/colour modifier branch of the class tree, **not** textures. A rule of "any
object property is a texture" would bind seven animators as textures on one `FluidShader` alone.

`DiffuseTexture` — which of the bound slots is the base colour — tries the known names above in
order, then any slot whose name contains "Diffuse". **There is deliberately no "first texture"
fallback**: a `LightBeamShader` binds `FalloffMap` and `DustMap` and has no base colour, and picking
one arbitrarily would put a normal map on a mesh as its colour, which renders as a blue-purple
surface and passes every count.

## A `Texture` named in a material slot is a material, and draws as itself

`CONFIRMED_EXTERNAL`. The class tree has three branches, and one of them is `BitmapMaterial →
Texture`: a texture *is* a material, drawn by `MaterialFactory_BitmapMaterial`, which the note
describes as "diffuse + alpha straight from one texture". **162 meshes name one in a material slot
instead of a shader** — `Rock_A` uses `SmallRock`, `newspaper_old_05` uses `newspaper_diffuse` — and
reading those as if they were a `Shader` finds no `Object` properties at all, so the material
reported that it bound nothing while its texture sat there as the object itself.

The reader now binds such a material to itself, under the slot name `Self`. That name is not a
property the data declares, and is called `Self` rather than `Diffuse` for exactly that reason: the
binding is the object, not a slot it names.

**Rendered and checked**, which is the only way this class of fault shows: `kelp_01` (a `PlantShader`)
draws as green-gold seaweed fronds and `newspaper_old_05` (a `Texture` material) as three crumpled
newspapers with legible print. Both drew flat grey before. `StaticMeshRenderingTests.Static_Snapshot`
writes them.

## A Shader is an ordinary property list

`CONFIRMED_BYTES`. `Shader` needed no new container work. Its payload is the same tagged Unreal
property list that prefixes every export, and the texture bindings are plain `Object` properties
naming `Texture` exports or imports:

```
Shader PistolShader  [11322] 128 bytes  outer=export Package 'WP_Pistol'
  Diffuse             Object   export Texture 'Pistol_DIFF'
  NormalMap           Object   export Texture 'Pistol_NORM'
  SpecularColorMap    Object   export Texture 'WP_Pistol_Spec'
  Glossiness          Float    30
  SpecularBrightness  Float    10
  SpecularMask        Struct   MaskMaterial
  MaterialVisualType  Byte     8
```

That was never the hard part. The hard part was the mesh side.

## Where a mesh names its material

`CONFIRMED_BYTES`. A `SkeletalMesh`'s **own property list is empty** — it holds only the
`CheckpointTypePadding` tag every export carries — so nothing in the tagged section says which shader
the mesh uses. The reference is in the binary payload.

It is the `FCompactIndex` immediately after the fixed tag block, the field
[skeletalmesh.md](skeletalmesh.md) had recorded as unexplained:

```
...bounds...
int32 4, int32 5              the tag block
FCompactIndex count           how many materials        <- was read as part of the tag
count x FCompactIndex         -> Shader objects
float3 scale
float3 origin
```

**The count was originally recorded as a fixed `byte 1`.** It is not fixed. Meshes with two
materials read 2 there, and reading it as part of the tag meant their second material was never
seen — and worse, meshes that happened to sit at a different alignment resolved nothing at all:

```
WP_PistolMesh           04000000 05000000 01 7BB001          one material
TommyGunMESH            04000000 05000000 02 6FB201 7F49     two
WP_GrenadeLauncherMesh  04000000 05000000 01 5848            one
PlasmidEquipMESH        04000000 05000000 02 57B101 7A49     two
```

For `WP_PistolMesh` the bytes at the tag block are

```
04 00 00 00  05 00 00 00  01  7b b0 01  00 00 80 3f ...
                              ^^^^^^^^  FCompactIndex 11323 = export 11322 = PistolShader
```

**The tag block's position varies between meshes** — 64 in `NEWPlayerHands`, 54 in `WP_PistolMesh` —
so the reader searches the first 256 bytes for it rather than using a fixed offset. The result is
accepted only if it resolves to a material class; anything else returns nothing. A regression test
asserts that no mesh in `0-Lighthouse` ever resolves to a non-material.

## FacingShader, and why the hands looked untextured

`CONFIRMED_BYTES`. `NEWPlayerHands` does not use a `Shader`. It uses a **`FacingShader`**, a Fresnel
shader with a different property set entirely: there is no `Diffuse`, and the base colour lives in
`FacingDiffuse` and `EdgeDiffuse`, the specular map in `FacingSpecularColorMap` and
`EdgeSpecularColorMap`.

A reader that knew only the `Shader` slots resolved the hands' material correctly and then reported
it as binding one texture — the normal map — which reads as a partly-broken decode rather than as a
missing slot table. The three textures it actually binds are exactly the three the asset context
lists for the hands group: `Hand_DIFF`, `Hand_NORM`, `Hand_SPEC`.

`BioShockMaterial` exposes `DiffuseTexture`, `NormalTexture` and `SpecularTexture`, which pick
whichever slot the shader class puts them in, so callers do not have to know about this.

## Coverage

**Whole game, from `diagnose` (`docs/QUALITY.md`):** 13,545 material objects, **0 partial** and 0
unreadable — the table below predates the nested-struct-size fix and is kept for the record. Of
9,684 mesh exports, **8,822 (91.1%) draw with a base colour**; of the 862 that do not, **522 resolve
a material of a class this reader does not know** — `FluidShader`, `PlantShader`, `LightBeamShader`,
`MaterialSwitch`, `MaterialSequence`, `LayeredShader` — and so find none of its properties. That is
open question 11b and the largest remaining gap in materials.

Measured against the installed game, before that sweep:

| Package | Meshes resolving to a material | Material objects decoding |
|---|---|---|
| `ShockGame.U` (weapon viewmodels) | **10 / 10** | 58 / 58, 11 partial |
| `0-Lighthouse` | **41 / 46** | 499 / 499, 43 partial |
| `1-Medical` | 40 / 55 | 819 / 819, 432 partial |
| `6-Slums` | 40 / 54 | 797 / 797, 418 partial |

`TommyGunMESH`, `WP_GrenadeLauncherMesh`, `PlasmidEquipMESH` and `WP_CrossbowMesh` now all resolve
their materials. The earlier note that they failed "for the same reason the vertices are" was
**wrong**: their materials were missed because of the count above, and their geometry fails for a
separate reason that is still open. The correlation was a coincidence of the same four meshes.

## `HkMeshProxy` is not the material link

`CONFIRMED_BYTES`, and it closes an open question that had been recorded the other way. 8,961
instances, and the guess was that they bridged an Unreal mesh to Havok data or to a material. They do
neither. Their outer is a `StaticMesh`, their property list is empty, and their payload is physics
data — a restitution/friction triple (0.33, 0.33, 0.33) followed by a transform:

```
HkMeshProxy HkMeshProxy0  [11336] 136 bytes  outer=export StaticMesh 'Wasp'
  +23  00000000 C3F5A83E C3F5A83E C3F5A83E 00000000 ... 0000803F ...
```

They are collision proxies. Nothing in the material path uses them.

## The partial decodes — CLOSED

`CONFIRMED_BYTES`. **A struct property's declared size omits the size-encoding bytes of its own
nested properties.** A nested property with an explicit size — encoding 5, 6 or 7 — costs 1, 2 or 4
bytes on the wire that the declared size does not count. The outer walk therefore advanced that many
bytes too few, landed inside the next property's name and stopped.

The two shaders the rule was read off, one on each side:

```
PistolShader.SpecularMask          declared 20, content 20
  26 00000000  05 00               Material, size encoding 0 — implicit size, no size byte
  4D01 00000000  01 01             Channel
  00 00000000                      None
                                   5+1+1 + 6+1+1 + 5 = 20   exact

Resurrection_Shader.Opacity        declared 22, content 23
  36 00000000  55 03 7EA301        Material, size encoding 5 — one size byte, uncounted
  6B01 00000000  01 01             Channel
  00 000000                        None, its number field one byte short
                                   5+5 + 6+2 + 5 = 23   declared 22
```

**Census of every struct-valued property on every material in the game:** of **14,610
`MaskMaterial` structs, 9,152 declare their size exactly — every one of them having no nested
property with an explicit size — and the remaining 5,458 are short by exactly the number of
size-encoding bytes their nested properties carry. There are no other cases.**

Not every struct is a property list. `Color` is a plain four-byte BGRA value with no nested list at
all, and the game ships 6,329 of them. So `UnrealPropertyReader` does **not** correct on the strength
of the rule: it corrects only when walking the nested list **lands exactly on a terminator** at the
corrected length, and the declared length does not contain one. A struct that is not a property list
cannot satisfy that and is returned untouched.

| | before | after |
|---|---|---|
| Materials decoding | 13,532 | 13,532 |
| **Partial** | ~half in the larger packages (432 of 819 in `1-Medical`) | **0** |
| Binding at least one texture | — | 13,304 |

`StructSizeTests` holds it: both shaders above field by field, a game-wide sweep asserting no
material is partial, and a check that no property name or texture slot reported by any material is
absent from the package's own name table — because a wrong correction resumes the outer walk
mid-property and produces plausible rubbish.

This also closes the second instance of the same shape recorded below, and it is the same family of
off-by-one as the `Materials` array's cut-off terminator, though that one has a different cause: the
array's own declared size is short, not its elements'.

## The partial decodes — how it looked before (kept for the record)

`UNKNOWN`, with the byte evidence recorded here so it can be closed rather than guessed at.

Roughly half the shaders in the larger packages stop early. The walk always loses alignment at the
same place: immediately after a `Struct` property of type `MaskMaterial` **whose nested list contains
a reference**. `MaskMaterial` is itself a property list, and the declared size is one byte short of
its content when it does.

`Resurrection_Shader` in `1-Medical`, the `Opacity` property. The header declares 22 bytes; the
content decodes to 23:

```
36 00 00 00 00        FName                       5 bytes
55 03 7e a3 01        Object, size 3 -> a Texture 5 bytes
6b 01 00 00 00 00     FName                       6 bytes
01 01                 Byte, size 1                2 bytes
00 00 00 00 00        None terminator             5 bytes
                                                 23 bytes, declared 22
```

The same structure in `PistolShader` fits its declared size exactly — and there the inner `Object`
property is null, encoded with an implicit size and **no size byte**. The difference between the two
cases is exactly that one byte, which is suggestive and is not enough to justify a parser change.

What the reader does instead: an `FName` whose base name is `None` terminates the list even when it
carries a number, because a real terminator never does. That turns a runaway walk into a clean stop,
and the result is flagged `Truncated` so a partial material is reported as partial rather than
presented as a whole one. Nothing is invented; a test asserts no property name in any decoded
material is one the walk made up.

In practice the texture bindings come before the masks, so a truncated material still carries its
maps: in `1-Medical` all 40 meshes that resolve to a material bind at least one texture.

## Export

`bioshock-tool export-fbx` and `export-blender` write the bound textures as PNG into a `Textures/`
directory beside the scene, and the scene carries the material with paths relative to itself. An
image bound to several slots — the hands bind `Hand_DIFF` as both the facing and the edge diffuse —
is written once and shared.

- **FBX** gets a `Material` (phong), plus a `Texture` and `Video` pair per map, with both the
  relative and the absolute path, since importers disagree on which they read first.
- **Blender** gets a Principled BSDF with base colour, a normal map through a Normal Map node, and
  the specular map on specular tint. Slots the shader leaves empty are left empty rather than
  defaulted, so a missing map stays visible as one.

Uninterpreted shader properties travel with the material by name, in the scene JSON and as a custom
property on the Blender material, so what was dropped is visible.  The scene material also preserves
`EmissiveBrightness`, `EmissiveColor`, and the raw `OutputBlending` byte.  The latter is deliberately
not translated to a UE5 blend mode until its ordinal mapping is established from shipped bytes.

`UNKNOWN`: `OutputBlending` (blend mode), `MaterialVisualType`, and the internals of the `MaskMaterial`
struct beyond the fact that it can name a texture. All are carried through, none are interpreted.

## MaterialSwitch default child

`CONFIRMED_BYTES`. A `MaterialSwitch` has a `Materials` candidate array and a separate `Material`
object property. On `med_quarantine_switch`, the array begins with two material references while the
separate property resolves to `med_quarantine_sign_diffuse_scroll_shader`; `SteinmanTVSwitch` and
`Resurrection_Switch` have the same shape. The reader follows only that explicit default child for
static reconstruction. It does **not** infer runtime selection from the candidate array, and it does
not apply the rule to `MaterialSequence`, whose `SequenceItems` structs still need their own walk.

## MaterialSequence items

`CONFIRMED_BYTES`, corroborated by the UE2 `MaterialSequenceItem` declaration. `SequenceItems` is a
counted array of nested tagged structs containing `Material` (object reference), `Time` (float), and
`Action` (byte: 0 show, 1 fade in the UE2 declaration). `drip_sequence` declares 30 items; each is
walked to its own `None` terminator, including the final item whose bytes extend past the array's
declared size. The source item timeline is now retained, but the viewer does not choose a frame or
pretend to emulate its runtime transition behaviour yet.


## A StaticMesh names its material in a property (CONFIRMED_BYTES)

**Closed.** The section below records how it looked before it was decoded; the answer is here.

`Materials` is an array of `FStaticMeshMaterial`, and each element is itself a property list. The
game names its own fields, so nothing had to be guessed:

```
Materials   Array, size 23 on ConeDrill
  FCompactIndex count                     1
  per element, a property list:
    EnableCollision  Bool     value in the info byte's array bit, no payload
    Material         Object   FCompactIndex -> Shader or FacingShader
    None                      terminator
```

For `ConeDrill` the `Material` reference is 10571, which is `ConeDrillRimShader`, a `FacingShader`.

### A slot may be empty, and its position is load-bearing

`CONFIRMED_BYTES`. Since the section table chooses a material by ordinal, the `Materials` list must
be exactly as long as the array's own count, with unread or null entries kept in place. Forty of the
game's 10,198 slots are empty, from two distinct causes — a declared null reference with an implicit
size, and a reference truncated by the one-byte-short array size. Both are shown byte by byte in
[staticmesh.md](staticmesh.md).

`ReadMeshMaterialSlots` is the slot-ordered list and is what `MeshSurfaceResolver` indexes.
`ReadMeshMaterialReferences` compacts it to what resolves and **must not** be indexed by a section
ordinal: closing up one empty slot shifts every later section onto the wrong material.

**The array's declared size is one byte short of its content**, so the final terminator is cut off.
That is the same off-by-one `MaskMaterial` shows below, and this is a second independent case of it:
both contain a nested property carrying an explicit size byte. The walk therefore treats running out
of bytes as the end of an element rather than as an error.

Two things had made this look harder than it was:

- The property walk reports `truncated` on every static mesh, because the outer list's terminator is
  a **numbered** `None`. That is not misalignment here — the walk is exact, and the header follows
  immediately after it.
- Reading an `FCompactIndex` at a fixed offset inside the value resolves to a material on 71.3% of
  meshes, which is close enough to look like a field and is really the rate at which a fixed offset
  lands on the `Material` property. Parsing the element properly resolves it on **87%** of the
  meshes in `1-Medical`, and the rest are meshes with no material at all.

This took textured meshes from **7% of the game to most of it**.

## How it looked before (kept for the record)

`ReadMeshMaterialReferences` finds a mesh's material by searching for the tag block
`int32 4, int32 5, byte 1` and reading the counted array after it. **A `StaticMesh` does not have
that tag block.** Its equivalent is `int32 4, int32 8, int32 1` — the second field appears to
distinguish the two containers — and no material reference follows it.

The consequence is measurable and large: of 630 meshes that draw in `1-Medical`, only **22 resolve a
diffuse texture**. The Bouncer's body is textured; its drill, cage and backpack draw flat grey.

Unlike a `SkeletalMesh`, whose property list is empty, a `StaticMesh` has a real one holding
`Materials`. That is where the answer should be, and the walk currently ends `truncated` — on a
numbered `None` — so what it returns for that property is not trustworthy.

The 23 bytes it currently yields for `ConeDrill`:

```
01 58 02 00 00 00 00 d3 00 36 00 00 00 00 55 03 4b a5 01 00 00 00 00
                                              ^^^^^^^^
```

`Plane`, in the same package, yields the same bytes except for those three:

```
01 58 02 00 00 00 00 d3 00 36 00 00 00 00 55 03 67 c8 01 00 00 00 00
```

Read as an `FCompactIndex`, `4b a5 01` is 10571, which is export `ConeDrillRimShader`, a
`FacingShader` — the right class, and a name that matches the mesh. `67 c8 01` is 12839.

**This is suggestive, not established.** The surrounding bytes being identical across meshes means
the walk is almost certainly misaligned and this value spans more than one property, so the position
of that index within it is an artefact rather than a field offset. Nothing has been changed on the
strength of it.

**How to close it:** hand-decode the property list of a `StaticMesh` from offset 8 and find where
the walk loses alignment — the same failure mode as the `MaskMaterial` size above, and possibly the
same cause. Until then static meshes export and draw without materials, and say so rather than
guessing.
