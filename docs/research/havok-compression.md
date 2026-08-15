# Havok spline compression as BioShock uses it

**Implementation:** `src/BioShockStudio.Core/Havok/Animation/SplineCompression/`
**Tests:** `tests/BioShockStudio.Tests/SplineDecompressionTests.cs`

BioShock stores every animation as `hkaSplineCompressedAnimation`. `CONFIRMED_BYTES`: no other
animation class appears in the shipped data, and `hkaInterleavedUncompressedAnimation` is absent.

## What the SDK says about the binding, and what the game actually carries

`CONFIRMED_EXTERNAL` from `hkaAnimationBinding.h`, measured here.

| field | SDK | shipped game |
|---|---|---|
| `m_blendHint` | `enum { NORMAL = 0, ADDITIVE = 1 }` | **0 on all 15,998 animations.** Additive blending is ruled out, by census and not by inference. |
| `m_partitionIndices` | "(Optional) A list of the partitions used to sample the animation" | **empty on all 457 bindings** of `AggressorBabyJane`; her six skeletons declare **0 partitions**. |
| `isMonotonic()` | "does this binding animate a **subset** of the bones in the same order in which they appear in the skeleton?" | 9 of 457 bindings on that rig drive a subset. The four collapsing fire clips are among them. |

The last row is the useful one and it is a description, not a cause: Havok has a name for what the
54-track clips are, and the mechanism it provides for them — partitions — is not used by this game.
See `docs/HANDOFF.md` §6.0c, where this eliminates a fourth candidate cause.


## Animation header

`CONFIRMED_BYTES`. See `HkaSplineCompressedAnimationReader` for the field offsets. Cross-validating
evidence: `duration == (numFrames - 1) * frameDuration` holds for every animation, tying together
three independently stored fields.

`m_type` is `3`. That value is recorded as observed rather than mapped through a 2012-era
`AnimationType` enum we have not verified; the class name is what the decoder branches on.

## Block layout

`CONFIRMED_BYTES`. Walking every block of the first-person hands package with these rules consumes
all 132 of them to the exact byte, modulo 16-byte block padding.

```
TransformMask[numTransformTracks]         // 4 bytes each
per track, in order: translation, rotation, scale
```

### Transform mask

```
byte 0   quantization selectors:  bits 0-1 translation, 2-5 rotation, 6-7 scale
byte 1   translation components
byte 2   rotation components
byte 3   scale components
```

Component bytes use the low nibble for statically stored components (`0x01` X, `0x02` Y, `0x04` Z,
`0x08` W) and the high nibble for spline-encoded ones (`0x10`…`0x80`). A channel is spline-encoded
if any high bit is set, static if any low bit is set, and absent otherwise.

Byte 0 is `0x45` for all 6,110 tracks in the hands package: 16-bit scalars, `ThreeComp40`
rotations, 16-bit scales.

### Vector channel (translation, scale)

```
spline form:
  uint16 numItems
  uint8  degree
  uint8  knots[numItems + degree + 2]
  align to 4
  per axis, in X, Y, Z order:
      spline axis -> float min, float max
      static axis -> float value
  (numItems + 1) x splineAxisCount quantized values, interleaved per control point
  align to 4

static form:
  float per statically stored axis
  align to 4
```

### Rotation channel

```
spline form:
  uint16 numItems
  uint8  degree
  uint8  knots[numItems + degree + 2]
  (no alignment)
  (numItems + 1) packed quaternions
  align to 4

static form:
  one packed quaternion
  align to 4
```

The alignment asymmetry is real and load-bearing. Vector channels align after the knot vector
because floats follow; rotation channels do not, because packed quaternions are byte-aligned. Get
this wrong and every subsequent track in the block desynchronises.

## ThreeComp40 quaternions

`CONFIRMED_BYTES` for the bit positions, via two independent properties of the shipped data.

```
bits  0-11   component A   (12 bits)
bits 12-23   component B
bits 24-35   component C
bits 36-37   index of the omitted component
bit  38      sign of the omitted component
```

Stored components span ±1/√2; the omitted one is recovered from the unit-length constraint.

Evidence:

1. Decoding all 67,528 shipped control points this way yields unit quaternions.
2. Consecutive control points within a track differ by a mean of 0.0016, i.e. the tracks come out
   continuous. Placing the omitted-component index or sign bit elsewhere yields discontinuous
   tracks (mean 0.0055 for the sign bit at 39).

`UNKNOWN`: the exact 12-bit midpoint. 2047, 2048 and the symmetric 2047.5 are indistinguishable by
the continuity test; the symmetric midpoint is used and the resulting error is under 0.0005.

## An omitted component is IDENTITY; an entirely absent channel is the reference pose

`CONFIRMED_EXTERNAL` against Havok 2012.2.0-r1, and the single most consequential detail for export
correctness. **This note previously said the opposite** — see the correction below.

Havok's own `hkaSplineCompressedAnimation::recompose`:

```cpp
/// \param S Static values
/// \param I Identity values
int stat = mask & 0x0F;                       // statically stored components
int iden = ~mask & ( ~mask >> 4 ) & 0x0F;     // neither static nor spline
if ( stat & shift )      inOut( i ) = S( i );
else if ( iden & shift ) inOut( i ) = I( i );
```

A component that is neither static nor spline takes **identity** — `0` for a translation, `1` for a
scale, `(0,0,0,1)` for a rotation, which is why Havok passes it rather than hard-coding it.

`LIKELY`, and separate: `recompose` is reached through `readNURBSCurve`, which only runs when the
channel stores something. A channel storing *nothing* is never read at all, so the caller's value
survives — the bound bone's reference pose. The reader follows both rules. Filling an entirely
absent channel with identity instead collapses 44 of `AggressorBabyJane`'s bones onto their parents
in `smg/smg_fire`; the split rescues 42 of the 44. The SDK build here ships headers and `.inl` only,
so `sampleTranslation` cannot be read directly and this half is inference from the call graph.

`AnimationPackage.Decode` still resolves the binding *before* decoding, because the second rule
needs the skeleton.

### Correction — the old evidence was circular

This section used to read: *"A channel a track does not store does not decode to identity. It takes
the bound bone's reference-pose value. Evidence: 4,452 tracks omit at least one translation
component; filling from the reference pose keeps 4,442 of them at their rigid bone length, filling
with zero keeps only 4,160."*

That measures its own assumption. Filling a component from the bind pose preserves the bind pose's
bone length **by construction**, so the test could only ever favour the reading it was testing. The
error cost three sessions: it put the first-person arm roots 93 cm from their clavicles instead of
19 cm and threw both arms across the body, because `Bip01_L/R_UpperArm` is the only bone in that
chain whose bind translation is not axis-aligned. `docs/research/FIRST_PERSON_ANIMATION.md`.

## Curve evaluation

Standard NURBS: `numItems + 1` control points over a byte knot vector, evaluated with de Boor's
algorithm at the frame index within the block. Rotation control points are blended directly and
renormalised — matching Havok's runtime — rather than chained through slerps, with control points
hemisphere-aligned first.

Multi-block animations select their block as `frame / maxFramesPerBlock`.

## Validation

- All 130 hands animations and all third-person character animations decode with zero failures.
- Every decoded rotation is unit length.
- Over 99% of frame-to-frame rotation deltas exceed 0.99 dot. The worst single transition across the
  whole pistol set is 0.752, during the fast reload — a genuine fast wrist motion, not decoder noise.
- Under animation, 46 of 47 bones keep their rest length exactly. The exception is
  `Bip01_R_UpperArm`, whose shoulder offset the animation deliberately overrides (it stores X
  explicitly as 19.14 against a bind value of 18.73, a 5% change).


## Sampling a block (CONFIRMED_BYTES)

Two faults here were invisible on the first-person hands, whose animations are a few dozen frames
and fit in a single block. They only appear on long animations, and both were found on Ryan's
speeches — 2,352 and 2,613 frames, across ten and eleven blocks.

### Blocks overlap by one frame

A block's knot values are frame numbers within that block. A full block's knots run to
`maxFramesPerBlock - 1` (255), so it describes 256 frames — and the last of those is the first frame
of the next block. **A block therefore advances the animation by `maxFramesPerBlock - 1`, not by
`maxFramesPerBlock`.**

The evidence is the final block. `Ryan_Speech_B` has 2,613 frames in 11 blocks:

| | stride 255 | stride 256 |
|---|---|---|
| Frames left for the last block | 63 | 53 |
| Its knots should therefore stop at | 62 | 52 |
| Its knots actually stop at | **62** | — |

Advancing by the full count instead samples one frame further into the curve per block: nothing
visible in the first few, and nine frames early by block nine.

### The last knot span

`FindSpan` follows Piegl & Tiller A2.1. With `n = ControlPointCount - 1` and a knot vector of
`n + degree + 2` entries, the curve's domain is `[knots[degree], knots[n + 1]]`.

Both bounds were wrong: the clamp compared against `knots[n]` and returned span `n - 1`, and the
binary search ran to `n` rather than `n + 1`. The last span was therefore never selected, and every
sample inside it was evaluated against the span below — a basis extrapolated outside its own
interval. The error grew towards the end of each block and carried into the next.

On `Ryan_DoorLoop`, a quiet idle, the worst single-frame bone movement was **10.44 units on a
skeleton 130 units tall**; corrected, it is **0.25**. On the long speeches it stretched a quarter of
the skeleton at once, which is what folded Ryan's chest into his legs partway through.

### Prop bones are not the mesh

When measuring this, restrict to bones the mesh is actually skinned to. `Ryan` has 131 bones and only
98 of them are skinned; `Dummy02`, `putterPLACEHOLDER` and `R_Grip` carry his golf club and move
freely without ever being drawn. Measured over all bones they dominate every statistic and hide the
real signal.
