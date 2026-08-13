# Materials

**Implementation:** `src/BioShockStudio.Core/Materials/MaterialReader.cs`, `Export/MaterialExporter.cs`
**Tests:** `tests/BioShockStudio.Tests/MaterialTests.cs`
**Status:** the mesh-to-shader link is decoded and meshes export textured.

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

Measured against the installed game:

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

## The partial decodes

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
property on the Blender material, so what was dropped is visible.

`UNKNOWN`: `OutputBlending` (blend mode), `MaterialVisualType`, and the internals of the `MaskMaterial`
struct beyond the fact that it can name a texture. All are carried through, none are interpreted.


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
