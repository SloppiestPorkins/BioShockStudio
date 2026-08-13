# Coordinate systems

**Implementation:** `src/BioShockStudio.Core/Coordinates/GameBasis.cs`
**Tests:** `tests/BioShockStudio.Tests/CoordinateSystemTests.cs`
**Status:** `CONFIRMED_BYTES` for the game's basis; `CONFIRMED_EXTERNAL` for the conversion's effect,
by round trip through Blender.

This note exists because every asset this project extracted before it — static meshes, skeletal
meshes, skeletons and animations alike — came out **mirrored**, and nothing in the pipeline was
wrong in a way that any single reader could be blamed for. The fault was that there was no
coordinate conversion at all.

## 1. The short version

| | Handedness | Forward | Right | Up |
|---|---|---|---|---|
| BioShock / Vengeance | **left** | +X | +Y | +Z |
| Havok, as shipped here | **left** | inherits the game's | | |
| BioShockStudio internal | **right** | +X | **-Y** | +Z |
| FBX as written, Blender, glTF | right | | | |

The conversion is one reflection, applied once:

```
C = diag(1, -1, 1)          det(C) = -1
```

`C` is the only handedness-changing operation in the codebase. Everything downstream — the preview
rasteriser, the FBX exporter, the Blender importer, the scene JSON — consumes data that has already
been through it and applies no further axis work of its own.

## 2. BioShock / Vengeance — `CONFIRMED_BYTES`

Vengeance is an Unreal 2.5 derivative and inherits Unreal's basis. That is stated everywhere, but
this project does not take conventions on trust, so it was measured from a shipped skeleton in world
space. `ProtectorRosie` and `AggressorBabyJane`, reference pose, composed to skeleton space:

| Bone | X | Y | Z |
|---|---|---|---|
| `Bip01_Pelvis` | 5.7 | 0.0 | 92.1 |
| `Bip01_Neck` | 14.2 | 0.0 | 158.9 |
| `Bip01_L_Clavicle` | 4.1 | **-10.7** | 156.6 |
| `Bip01_R_Clavicle` | 4.1 | **+10.7** | 156.6 |
| `Bip01_L_Foot` | **-14.2** | -37.8 | 16.9 |
| `Bip01_L_Toe0` | **+9.0** | -37.8 | 1.1 |

Three independent readings, each from anatomy rather than from convention:

- **Up is +Z.** Feet sit near Z=0 and the neck at Z=159; the mesh bounding box runs Z[1.1, 197.6],
  which is a person-shaped extent standing on the ground plane.
- **Forward is +X.** The toe is 23 units ahead of the ankle in X. Toes point forward.
- **Right is +Y.** Every `Bip01_L_*` bone sits at negative Y and every `Bip01_R_*` at positive Y.

And therefore the basis is **left-handed**. For any right-handed frame, forward × left = up. Here:

```
forward × left = X × (-Y) = -Z = -up          not +up
```

Units are centimetres — Rosie is 197 units tall.

### The first-person hands are a special case worth knowing about

`UAPW_NEWPlayerHands`' Havok skeleton is rooted at `Bip01 Spine`, not at `Bip01`, so its skeleton
space is that bone's own space: X runs up the spine, and left/right separates on Z. It is the same
data in the same handedness — only the root differs — and it needs no special handling. It is
mentioned here because reading the hands' numbers first suggests a different basis from the rest of
the game, and it is not one.

## 3. Havok

Havok's own convention is configurable at build time, and nothing in the shipped packfiles declares
it. What matters is what is actually stored, and that is settled without needing Havok's convention
at all: the reference pose composed above **is** the Havok `hkaSkeleton` reference pose, read
straight out of `hkQsTransform` records. So Havok here carries the game's basis, and:

- quaternions are `(x, y, z, w)`, as `hkQuaternion` stores them;
- transforms are stored decomposed as translation / rotation / scale, not as matrices, so no matrix
  row/column convention has to be settled;
- bone transforms are **parent-local**, and animation tracks are parent-local too, in exactly the
  same space — which is why they take exactly the same conversion.

`UNKNOWN`: whether the exporter that produced these packfiles was configured left-handed or
converted on the way in. It does not matter, because the shipped bytes are what is being read.

## 4. BioShockStudio internal — the target

Right-handed, **+X forward, +Y left, +Z up**, centimetres.

`C` was chosen to be the *minimal* reflection that fixes handedness: it keeps the game's forward and
up axes, and reflects only left/right. The alternatives were rejected on the following grounds
rather than by preference:

- `diag(-1, 1, 1)` also fixes handedness but leaves the character facing backwards along its own
  forward axis, so every downstream "which way does this face" question inverts.
- `diag(1, 1, -1)` puts the character upside down.
- Any rotation, of any kind, cannot fix it at all: `det = +1` preserves handedness. **This is the
  whole bug.** The exporter's axis declaration and Blender's importer conversion are both rotations,
  so no combination of them could ever have removed the mirror.

The resulting frame is Blender's own. That is not a coincidence and it is convenient: it means the
FBX header's existing axis declaration — `UpAxis` +Z, `FrontAxis` -Y, `CoordAxis` +X, described in
`fbx.md` as "the game's own basis" — now describes the data truthfully and makes Blender's importer
apply the identity. The declaration did not have to change; what changed is that it became correct.

## 5. FBX and Blender

FBX carries no handedness field of its own. It declares three signed axes, and Blender's importer
builds a conversion matrix from them — always a **rotation**. That is why the mirror survived every
previous round trip while every numeric validation passed: the round trip was faithful, and it was
faithfully carrying mirrored data.

One consequence worth stating plainly: because the declaration resolves to the identity, a character
imported into Blender **faces +X**, so Blender's front view (looking along +Y) shows its side. That
is an orientation, not a mirror, and it is what a UE→Blender pipeline normally produces. Rotating it
would be a presentation choice; it is deliberately not made here, so that one basis holds from the
decoder to the `.blend`.

Blender's V axis runs opposite to the game's, and the FBX exporter flips it. That is a texture
parameterisation, not a spatial basis, and `C` deliberately leaves UVs alone.

## 6. Triangle winding — derived, and the answer is "do nothing"

`CONFIRMED_BYTES`. This is the part that is easy to get wrong by reasoning too quickly, and the
first implementation here did get it wrong before the tests caught it.

The game's geometry is **front-face clockwise**: for every triangle, the geometric normal
`(B-A)×(C-A)` points *against* the shipped vertex normals. Measured over whole meshes:

| Mesh | Triangles | Disagreeing |
|---|---|---|
| `NEWPlayerHands` | 8,726 | 8,726 (100%) |
| `ProtectorRosie` | 17,602 | 17,601 (100%) |
| `AggressorBabyJane` | 10,996 | 10,996 (100%) |

Corroborated externally: Nyko's SDK viewer has to set `GL_CW` for BioShock geometry to front-face
correctly (`tools/level_editor/src/viewport.cpp`, `bioshock1-bsm.md`).

Now the derivation. Under a reflection, a cross product and a normal transform *differently*:

```
cross product:  (Cu) × (Cv) = det(C) · (C⁻¹)ᵀ (u × v) = -C(u × v)
normal:                                    n' = (C⁻¹)ᵀ n = +C n
```

so their agreement is negated:

```
dot(g', n') = dot(-Cg, Cn) = -dot(g, n)          C is orthogonal, so it preserves the dot product
```

The game's triangles disagree. After the reflection they **agree** — the converted mesh is
counter-clockwise front-facing, which is what FBX, Blender and Unreal all expect. So the correct
action on the index buffer is **none**.

Reversing the winding as well, which is the intuitive move and the one first taken here, undoes
exactly this and puts the geometry back the wrong way round. `CoordinateSystemTests` asserts the
agreement in both a synthetic clockwise triangle and every triangle of the shipped hands mesh, so
this cannot regress silently.

## 7. Normals, tangents and binormals

`C` is diagonal, orthogonal and symmetric, so `(C⁻¹)ᵀ = C`: a normal converts by the same map as a
position, and there is no separate normal transform to get wrong. Asserted rather than assumed in
`Normal_ConvertsByTheInverseTranspose`.

The game ships tangent **and** binormal explicitly, rather than a tangent plus a handedness sign, so
converting all three by `C` keeps the basis internally consistent with no sign bookkeeping. The
tangent frame's handedness relative to UV space does flip, which is correct and is not compensated:

- the preview rasteriser perturbs the normal as `T·x + B·y + N·z`, a linear combination with
  unchanged coefficients, so the perturbed normal converts by `C` exactly like every other normal;
- the FBX carries no tangent layer, so Blender recomputes tangents from the converted positions and
  the untouched UVs, which is correct by construction.

## 8. Rotations

Conjugation: `R' = C · R · C⁻¹`, and `C⁻¹ = C`.

Conjugating a rotation by a reflection reflects its axis and negates its angle. For `C = diag(1,-1,1)`
the axis goes `(x,y,z) → (x,-y,z)` and `θ → -θ`, which multiplies out to

```
q = (x, y, z, w)   →   (-x, y, -z, w)
```

`Rotation_MatchesConjugationByTheBasis` builds `C·R·C⁻¹` independently as matrices and compares,
over identity, +90° about each axis, a negative angle, an off-axis rotation and a composition.
`Rotation_ConvertsTheRotatedPointTheSameWayAsThePoint` asserts the compatibility condition that
actually matters downstream — converting then rotating equals rotating then converting — because
that is what keeps a converted mesh and a converted skeleton in step under animation.

Scale is carried through unchanged: a diagonal conversion commutes with a diagonal scale, so the
conversion never introduces a negative scale factor of its own. No shipped bone carries one either
(`Skeleton_HasNoMirroredReferenceBasis`), so an extracted asset's root scale is `(1,1,1)`.

## 9. Where the conversion is applied

Four places, all of them the boundary where a raw decode becomes the studio's internal
representation. There is no fifth, and adding one would be the bug this note exists to prevent.

```
StaticMeshReader.ReadGeometry        →  GameBasis.Convert(MeshGeometry)
SkeletalMeshReader.ReadGeometry      →  GameBasis.Convert(MeshGeometry)
HkaSkeletonReader.Read               →  GameBasis.Convert(BioShockSkeleton)
AnimationPackage.Decode              →  GameBasis.Convert(DecodedAnimation)
```

### The one place a double conversion could hide

A spline-compressed animation does not store every channel. The channels it omits fall back to the
**bound bone's reference pose**, which `AnimationPackage.Decode` takes from the skeleton — and the
skeleton has already been converted, while the compressed data about to be decoded has not.

So the fallback is taken back to the game's basis before decoding (`GameBasis.ToGameBasis`), and the
whole decoded animation is converted once afterwards. Without that, the fallback channels would be
converted twice and the stored channels once, within the same track: bones would sit on the wrong
side only when their motion happened to be missing a channel, which is about as hard a bug to see as
this project could produce.

`Animation_UsesTheSameBasisAsTheSkeleton` detects it directly — it looks for tracks whose constant
translation equals the reference translation with its Y negated, and requires that count to be zero
while requiring a non-zero number of correct matches, so the test cannot pass vacuously.

## 10. What is deliberately not done

- **No per-asset, per-weapon or per-animation adjustment.** An animation needing its own flip would
  mean the skeleton and the animation disagreed about their basis, and they do not.
- **No compensating negative scale** anywhere — in a root node, an FBX node, or a mesh transform.
- **No second conversion in an exporter.** The FBX, scene JSON and Blender paths receive converted
  data and add nothing.
- **UVs are not touched** by `C`. The FBX exporter's V flip is unrelated and stays where it is.

## 11. Evidence summary

| Claim | How it is established |
|---|---|
| The game is left-handed, +X/+Y/+Z = forward/right/up | Anatomy of two shipped skeletons in world space |
| The pipeline applied no handedness conversion | No reflection existed in the codebase; the preview uses right-handed `Matrix4x4` builders and the FBX declares a right-handed triple |
| The game's winding is clockwise-front | 100% of triangles across three meshes; Nyko's `GL_CW` |
| The reflection alone fixes the winding | Derived from `det(C)·(C⁻¹)ᵀ`; asserted synthetically and on 8,726 shipped triangles |
| The quaternion form is the conjugation | Compared against `C·R·C⁻¹` built as matrices |
| The converted skeleton is anatomically correct | `Skeleton_PutsTheLeftSideOnTheLeft` on shipped bytes |
| The export carries it faithfully | `validate_fbx.py` through Blender: worst rest error 0.000062 cm, worst posed 0.0017 cm |
| Blender agrees | `Bip01_L_Foot` at +Y, `Bip01_R_Foot` at -Y, 2.0 m tall on Z, after import |
