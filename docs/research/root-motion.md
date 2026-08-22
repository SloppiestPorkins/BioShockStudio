# Havok root motion (`m_extractedMotion`)

**Implementation:** `HkaDefaultAnimatedReferenceFrameReader`, `AnimatedReferenceFrame`
**Tests:** `RootMotionTests`

## What was missing

`HkaSplineCompressedAnimationReader`'s own byte-layout doc comment already named the field:

```
hkaAnimation
+8   hkInt32   m_type
+12  hkReal    m_duration
+16  hkInt32   m_numberOfTransformTracks
+20  hkInt32   m_numberOfFloatTracks
+24  hkaAnimatedReferenceFrame* m_extractedMotion
+28  hkArray<hkaAnnotationTrack> m_annotationTracks
```

— but the reader's `Read` method jumped from `+20` straight to `+28`, so `+24` was never read. This
is the same shape of gap as the skeletal mesh section table (§4c in `open-questions.md`): documented
in a comment, silently skipped by the code that walks past it.

## Is it ever present? — `CONFIRMED_BYTES`, censused across the whole game

**6,356 of 16,031 animations (39.6%) carry root motion.** Not a theoretical field. `audit-animations`
now reports this figure directly (`AnimationAuditReport.WithExtractedMotion`). Every one of
`NEWPlayerHands`' 130 first-person animations carries none, which is the expected shape for a
viewmodel that never itself moves through the world (`RootMotionTests.FirstPersonHandsCarryNoRootMotion`)
— the field distinguishes stationary rigs from ones that travel, exactly as it should.

## What it resolves to — `CONFIRMED_BYTES`

`m_extractedMotion` is an `hkRefPtr`, so it is a local (within-section) or global (cross-section)
fixup depending on where the target object happens to live; both are checked
(`HkaDefaultAnimatedReferenceFrameReader.ResolveTarget`). Read back through the packfile's own
virtual fixup table (`HavokPackfile.EnumerateObjects`), the resolved object's class is always
`hkaDefaultAnimatedReferenceFrame` — the only concrete subclass of `hkaAnimatedReferenceFrame` in
this SDK build. Not assumed: the class name comes from the same fixup table this project already
uses to resolve every other object in the graph.

## Layout — `CONFIRMED_BYTES`, four independent cross-checks

```
hkaDefaultAnimatedReferenceFrame : hkaAnimatedReferenceFrame : hkReferencedObject
+0   hkReferencedObject                (vtable + refcount, zero on disk)
+16  hkVector4          m_up           (padded from +8 to a 16-byte SIMD boundary; hkaAnimatedReferenceFrame's
                                         own m_frameType is marked //+nosave in the SDK header and is not
                                         written to the packfile at all, so nothing occupies +8..+15)
+32  hkVector4          m_forward
+48  hkReal             m_duration
+52  hkArray<hkVector4> m_referenceFrameSamples
```

Checked against six of `AggressorBabyJane`'s animations (`Death_GrabHead`, `Death_SpinLeft`,
`Death_StumbleBWD`, `Death_StumbleFWD`, `GetUpKneeling_A`, `GetUpSitting_A`), every one agreeing on
all four counts:

1. **`m_up` decodes to `(0, 0, 1, 0)` and `m_forward` to `(1, 0, 0, 0)`** — exactly the class's own
   documented defaults (`hkaDefaultAnimatedReferenceFrame.h`: "Specified which direction in world
   \[...] is up. Default is (0,0,1) \[Z]" / "forward. Default is (1,0,0) \[X]").
2. **`m_duration` equals the owning animation's own `hkaSplineCompressedAnimation::m_duration`
   exactly**, every time (`1.9`, `0.5543478`, `1.3`, `1`, `1.2`, `1.3333334`).
3. **`m_referenceFrameSamples.Count` equals the owning animation's own `NumFrames` exactly**, every
   time (`58`, `17`, `40`, `31`, `37`, `41`) — the same cross-validation shape the project already
   uses for `m_duration == (numFrames - 1) * frameDuration` elsewhere.
4. **Sample `[0]` is always the origin**, matching the SDK header's own description: "the motion
   \[...] represents the absolute offset from the start of the animation."

`RootMotionTests.SampleCountTracksFrameCountAcrossSeveralAnimations` holds points 3 and 4 across ten
animations, not one.

## What is `PLAUSIBLE`, not yet `CONFIRMED_BYTES`

**Which of a sample's four components carry meaning.** Every sample examined so far — six animations,
hundreds of frames — has non-zero X and Y and exactly zero Z and W. That is consistent with
ground-plane translation and no extracted yaw, but nothing here has cross-validated *which* axis is
which against an independent source (e.g. a displacement measured from the skeleton's own root bone
track over the same animation). `AnimatedReferenceFrame.Samples` is exposed as raw `Vector4`s rather
than as interpreted "translation" and "yaw" fields for exactly this reason — the class's own comment
suggests XY-plane translation plus a W-slot yaw component
(`MotionExtractionOptions.m_allowFrontBack`/`m_allowRightLeft`/`m_allowTurning`), but BioShock's
authored data does not obviously match that packing (both X and Y are live, not one plus a separate
W), so promoting a specific "X is forward, Y is right" reading would be a guess.

## What is genuinely `UNKNOWN`

**Whether the non-`AggressorBabyJane` root-motion animations (6,350 of the 6,356) look the same
shape.** All six checked here are one character's death/getup clips. `docs/ENGINEERING_RULES.md`'s
"never trust a single sample" is about a single *animation*; six is better than one but is still one
*skeleton family*. A wider sweep (several different characters/creatures, not just one splicer) would
strengthen or correct the pattern above before anything downstream depends on it.

## What is explicitly out of scope here

**Wiring this into the exporter (FBX/scene JSON) or applying the game's `C = diag(1,-1,1)` basis
reflection.** This note is a decode record (Gate 2 item 1 of `docs/ROADMAP.md`): the field is read
and its shape is confirmed. Whether and how a UE5 import should apply per-frame root displacement is
an export-pipeline decision (Gate 5 territory) that has not been made, and the raw sample values here
are in Havok's native space — untested against `docs/research/ANIMATION_COORDINATE_SYSTEM.md`'s basis
policy, which every other decoded transform in this project goes through before it is trusted.
