# Havok spline compression as BioShock uses it

**Implementation:** `src/BioShockStudio.Core/Havok/Animation/SplineCompression/`
**Tests:** `tests/BioShockStudio.Tests/SplineDecompressionTests.cs`

BioShock stores every animation as `hkaSplineCompressedAnimation`. `CONFIRMED_BYTES`: no other
animation class appears in the shipped data, and `hkaInterleavedUncompressedAnimation` is absent.

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

## Absent channels fall back to the reference pose

`CONFIRMED_BYTES`, and the single most consequential detail for export correctness.

A channel a track does not store does **not** decode to identity. It takes the bound bone's
reference-pose value from `hkaSkeleton`. Evidence: 4,452 tracks across the 130 hands animations omit
at least one translation component. Filling from the reference pose keeps 4,442 of them at their
rigid bone length; filling with zero keeps only 4,160 and visibly detaches limbs whose parent offset
is not axis-aligned.

This is why `AnimationPackage.Decode` resolves the binding *before* decoding rather than after: the
decoder needs the skeleton to fill the gaps.

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
