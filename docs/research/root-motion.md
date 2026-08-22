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

## Field meaning — `CONFIRMED_EXTERNAL`, correcting an earlier over-hedge in this file

**X, Y, Z is a 3D translation and W is a yaw rotation around the up axis** — stated directly by the
SDK header's own field-level comment on `m_referenceFrameSamples`, not inferred: "We store the motion
track as a vector4 since we only need a translation and a rotational (w) component around the up
direction." This is a literal reading of the source, not a guess dressed up as one.

**Corrected: this was previously written as "2 live components, 2 dead" — that was wrong.** All four
sample components examined so far (six animations, hundreds of frames, all on `AggressorBabyJane`)
have non-zero X and Y and exactly zero Z and W. The right reading is not "two of the four slots are
unused" — the class's own comment says all four carry meaning by design — it is that *these
particular animations* (death and getup clips) don't move vertically or turn while playing, which is
physically ordinary for that content. `Z` and `W` being reserved-but-unexercised in the six samples
checked is not evidence they're structurally dead.

## Z and W are live — `CONFIRMED_BYTES`, three more skeleton families

**Not a dead field.** A breadth sweep this session found real, meaningful non-zero values in both
slots this file previously called "unexercised":

| Character | Root-motion animations | Samples with non-zero Z | Samples with non-zero W |
|---|---|---|---|
| `AggressorBabyJane` (splicer) | 6 checked in detail | 0 | 0 |
| `GathererGirl` (Little Sister) | 77 | **1,766** | **2,451** |
| `ProtectorRosie` (Big Daddy) | 59 | 0 | **1,261** |
| `NewProtectorBouncer` (Big Daddy) | 60 | 0 | **1,273** |

`RootMotionTests.ZAndWAreLiveOnOtherSkeletonFamilies` holds this, plus 0 sample-count mismatches
across all 196 animations — the same `NumFrames`-agreement cross-check from the layout section,
now validated on three more rigs, not one.

**W (yaw) is live on every character checked.** `GA_BouncerToss` (a Big Daddy throwing a Little
Sister) samples grow smoothly from `w=0` to `w=-0.23` over its first five frames — a real, continuous
curve, not noise. The whole-game W range is `[-3.70, 7.59]` — **beyond ±π**, which is not a bug: an
"absolute offset from the start of the animation" (the SDK's own phrase) is an *unwrapped* angle that
can exceed a full turn if the character spins more than once, which is exactly what an accumulating
reference frame should do.

**Z (vertical) is live on `GathererGirl` specifically, and the reason is legible from the animation
names.** `GA_EnterVentAlone`/`GA_EnterVentProtectorBouncer`/`GA_EnterVentProtectorRosie` — a Little
Sister climbing into a ceiling vent — carry smoothly growing Z (up to ~5.5 units by frame 4) and
exactly **zero** W, while `GA_BouncerToss` carries W and no Z. Different clips exercise different
slots depending on what the motion actually is, which is the shape a correctly-decoded field should
have and a misread one should not.

**A genuinely new finding this reveals, not previously flagged: root-motion values are not in the
same units as `hkpCapsuleShape`'s physics geometry.** Z ranges as wide as `[-144, 187]` were observed
on `GathererGirl` — implausible as metres (a 144–187 *metre* vertical vent climb), entirely plausible
in the same centimetre-ish units the rest of this project's mesh/animation/bone data already uses.
Root motion lives in `hkaAnimation` (the animation subsystem, same object family as the spline tracks
that already decode in mesh/bone units) rather than `hkpRigidBody`/`hkpShape` (the physics subsystem,
confirmed metre-scaled in `docs/research/havok-physics.md`) — two different Havok subsystems, two
different authored scales, and this project now has confirmed evidence for both rather than assuming
one convention applies everywhere.

## What is `PLAUSIBLE`, not yet `CONFIRMED_BYTES`

**Whether X is "forward" and Y is "right" in some fixed world/local convention, or track something
else entirely** (e.g. X/Y as two arbitrary in-plane axes with no fixed forward/right meaning until
combined with the animation's own facing). `m_forward` defaults to `(1,0,0)` — the same axis (X) that
carries the largest magnitude in most samples checked — which is suggestive, but nothing here
cross-validates it against an independent source (e.g. a displacement measured from the skeleton's
own root bone track over the same animation), so promoting a specific "X is forward, Y is right"
reading would still be a guess. `AnimatedReferenceFrame.Samples` is exposed as raw `Vector4`s rather
than as interpreted "translation" and "yaw" fields for exactly this reason.

## What is genuinely `UNKNOWN`

**Whether the remaining ~6,150 root-motion animations (of 6,356) outside these four skeleton
families look the same shape.** Four families and 202 animations is a real breadth check, not one
sample — but creatures (whale/shark/squid swim paths, already flagged by `audit-animations`' own
"largest single-frame bone jumps" list) and other doors/props/turrets have not been checked and could
still surprise.

## What is explicitly out of scope here

**Wiring this into the exporter (FBX/scene JSON) or applying the game's `C = diag(1,-1,1)` basis
reflection.** This note is a decode record (Gate 2 item 1 of `docs/ROADMAP.md`): the field is read
and its shape is confirmed. Whether and how a UE5 import should apply per-frame root displacement is
an export-pipeline decision (Gate 5 territory) that has not been made, and the raw sample values here
are in Havok's native space — untested against `docs/research/ANIMATION_COORDINATE_SYSTEM.md`'s basis
policy, which every other decoded transform in this project goes through before it is trusted.
