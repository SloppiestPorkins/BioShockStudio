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
