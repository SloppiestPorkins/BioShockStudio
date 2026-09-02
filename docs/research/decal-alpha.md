# Blood-decal alpha

## Finding

**Status: CONFIRMED_BYTES (1-Medical shipped package and recovered bulk mip).**

`Gen_BattleDebris.BloodSplat1`, `BloodSplat2`, and `BloodSplat3` do not contain an
alpha channel that the texture decoder is losing. They declare texture format ordinal `3`, which
is DXT1/BC1. Their splatter coverage is authored separately rather than in the diffuse texture's
alpha. Consequently no texture-decoder change is justified by these assets.

This stops at the texture boundary. Applying the separately authored opacity data is a material-side
task and is outside this investigation's lane.

## Reproduction

The package properties for texture export `12911`, `Gen_BattleDebris.BloodSplat3`, are:

```text
bAlphaTexture       Bool  True
HasBeenStripped     Bool  True
StrippedNumMips     Byte  5
Format              Byte  3
UBits / VBits       Byte  10 / 10
USize / VSize       Int   1024 / 1024
SourcePath                ...\Gen_BattleDebris\01_Bio01_Textures\BloodSplat3.tga
```

`bAlphaTexture` is therefore an intent declaration, not proof that these particular BC1 blocks
select transparent texels. This agrees with `MaterialReader.DeclaresTransparency`: declarations and
stored channel contents are deliberately separate facts.

Reading the package-resident mip tail and writing its shipped DXT1 blocks to DDS gives 2,728 bytes:
64x64 + 32x32 + 16x16 + 8x8 + 4x4. Its SHA-256 is
`608D52B0EDB47C93F0020ADBAC4D47DA9B5A84A71420F265BA2CD1841037D2B1`. The first 32 bytes are:

```text
00 28 00 20 FF FF FF FF  00 28 00 20 FF FF FF FF
00 28 00 20 FF FF FF FF  00 28 00 20 FF FF FB FE
```

For the first block, the little-endian RGB565 endpoints are `0x2800 > 0x2000`, selecting BC1's
four-colour opaque mode. Across all 341 blocks in the resident mip chain, 25 blocks have
`colour0 <= colour1`, where BC1 permits a transparent palette entry, but **zero texels select index
3**. Thus the stored tail has no 1-bit alpha either.

Re-exporting the level with bulk recovery reproduces the reported 1024x1024 `BloodSplat3.png` with
alpha `255..255` and standard deviation `0.00`. `BlockCompression.Decode` supplies BC1 transparency
when index 3 is actually selected, and `PngWriter` receives the resulting RGBA buffer unchanged;
the uniform exported alpha reflects the recovered source blocks rather than a PNG write flattening
step.

## Where the shape is

The same package contains a distinct texture export `31643`,
`Gen_BattleDebris.bloodsplat3opa`:

```text
Format              Byte  3
UBits / VBits       Byte  11 / 11
USize / VSize       Int   2048 / 2048
SourcePath                ...\Gen_BattleDebris\01_Bio01_Textures\bloodsplat3opa.tga
```

Equivalent `bloodsplat1opa` and `bloodsplat2opa` exports sit beside the other two blood textures.
These opacity maps are also DXT1: the mask is stored as RGB intensity, not as alpha. For
`bloodsplat3opa`, the package-resident 64x64 mip chain is again 2,728 bytes, with SHA-256
`EEBFBD24752DCD0E2BBB620AC45D7F2D7EFA582859A51D145288E1287EE60857`; it likewise selects zero BC1
transparent texels. Its first 32 bytes begin:

```text
00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
20 00 00 00 55 55 55 F5  20 00 00 00 55 55 D5 7D
```

Shader export `12769`, `Gen_BattleDebris.bloodsplat3_shader`, independently confirms the authored
split. It names `BloodSplat3` as `Diffuse`, carries a nested `Opacity` value of struct type
`MaskMaterial`, names `bloodsplat3nor` as `NormalMap`, and declares `OutputBlending = 1`.

## Conclusion

**VERIFIED:** diffuse alpha does not exist in the shipped `BloodSplat1/2/3` BC1 data. The visible
shape is supplied through separate opacity-mask material data. A regression test requiring
`BloodSplat3` alpha standard deviation greater than 5 would assert something the source bytes do not
contain, so no such test and no texture decode change were added. `Wall_Leak_diff` and
`Kelp_01_Diffuse` use their existing alpha-bearing paths and are unaffected.
