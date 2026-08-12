# Animation binding

**Implementation:** `HkaAnimationBindingReader`, `AnimationBinding`, `AnimationPackage.Decode`
**Tests:** `AnimationPackageTests`, `SplineDecompressionTests`

Binding is the subsystem the project treats as critical, because a wrong track-to-bone mapping
produces an animation that plays but is silently wrong.

## Where the mapping comes from

`CONFIRMED_BYTES`. Havok stores it explicitly, in `hkaAnimationBinding`:

```
+16  hkArray<hkInt16>  m_transformTrackToBoneIndices
```

Element `i` is the skeleton bone that transform track `i` drives. Nothing else is used — not names,
not array position, not filenames, not alphabetical order.

## What the shipped data looks like

For the first-person hands, every animation binds 47 tracks onto the 47-bone skeleton, one apiece:
the mapping is a permutation, not a subset. Tested by asserting that the mapping is injective and
that every index lands inside the skeleton.

That it is currently a full permutation is **not** relied upon. `BoneForTrack` returns -1 for an
unbound track and `TrackForBone` returns -1 for an unanimated bone, so partial bindings — which
third-person characters may well use — degrade rather than corrupt.

## Why binding has to be resolved before decoding

`CONFIRMED_BYTES`. Channels a track omits fall back to the bound bone's **reference pose**, so the
decoder cannot run without knowing which bone each track drives. See
[havok-compression.md](havok-compression.md) for the evidence.

The consequence is an ordering constraint in the pipeline:

```
AnimationPackageRoot  ->  binding  ->  bone  ->  reference pose  ->  decode  ->  sampled track
```

An implementation that decodes first and binds afterwards will silently produce broken limbs for
every track with a partial mask — 4,452 of them in the hands package alone.

## Other binding fields

```
+8   const char*        m_originalSkeletonName          empty in the shipped data
+12  hkaAnimation*      m_animation                     cross-section pointer, global fixup
+28  hkArray<hkInt16>   m_floatTrackToFloatSlotIndices  empty; there are no float tracks
+40  hkArray<hkInt16>   m_partitionIndices              empty
+52  hkInt8             m_blendHint
```

`UNKNOWN`: the meaning of `m_blendHint`'s values in BioShock. It is carried through to
`AnimationBinding.BlendHint` unchanged rather than interpreted.

## Blender rest-pose orientation (CONFIRMED)

The single largest source of visually wrong animation, found after the animations already "worked":
bones must be created by assigning `EditBone.matrix`, not by setting head and tail.

Blender derives a bone's roll from its head, tail and roll value. Building bones from head/tail
alone lets Blender choose an arbitrary roll, so the rest matrix it stores is **not** the game's
reference-pose matrix. Measured against `NEWPlayerHands`, rest orientations differed by up to
**2.0** in individual matrix elements — a full axis flip — while bone *positions* were exact.

That matters because the pose conversion is

```
basis = restMatrix⁻¹ · animatedWorld
```

which is only correct when `restMatrix` is the same matrix the animation's local transforms are
composed against. With a mismatched rest basis the rig still animates, the mesh still deforms and
the timing is still right — it is simply the wrong motion.

After assigning `EditBone.matrix`:

| Check | Before | After |
|---|---|---|
| Worst rest-matrix element error | 2.0 | 0.00002 |
| Worst posed bone position error | — | 0.000006 m |

The second row is measured across all ten pistol animations at the first, middle and last frame,
against world transforms composed independently from the game's own track data.

`tools/blender/validate_scene.py` performs both checks and exits non-zero on failure.
