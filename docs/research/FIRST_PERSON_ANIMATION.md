# First-person animation — the hand-side blocker

**Implementation:** `src/BioShockStudio.Core/Havok/Animation/SplineCompression/SplineDecompressor.cs`
**Tests:** `tests/BioShockStudio.Tests/FirstPersonHandTests.cs`
**Status:** **SOLVED.** `CONFIRMED_EXTERNAL` against Havok 2012.2.0-r1's own source.

The first-person hands sat on the wrong sides in every animation. The cause was not in the rig, the
basis, the binding or the compression: **a channel component that a track omits is Havok's identity,
and this reader filled it from the bound bone's reference pose.**

## 1. The cause

Havok's `hkaSplineCompressedAnimation::recompose`, from the 2012.2.0-r1 SDK:

```cpp
/// \param S Static values
/// \param I Identity values
void hkaSplineCompressedAnimation::recompose( hkUint8 mask, const hkVector4& S, const hkVector4& I, hkVector4& inOut )
{
    int stat = mask & 0x0F;                       // statically stored components
    int iden = ~mask & ( ~mask >> 4 ) & 0x0F;     // neither static nor spline

    int shift = 0x01;
    for ( int i = 0; i < 4; i++ )
    {
        if ( stat & shift )      inOut( i ) = S( i );
        else if ( iden & shift ) inOut( i ) = I( i );
        shift <<= 1;
    }
}
```

Identity is `0` for a translation, `1` for a scale and `(0,0,0,1)` for a rotation, which is why
Havok passes it as a parameter rather than hard-coding it.

**Why it hid for three sessions:** the two readings agree for every bone whose bind translation is
zero in the components the track omits — which is nearly every bone in the game, because a Biped's
bone offsets run along one axis. On the first-person arm chain:

| bone | mask | bind translation | identity vs reference |
|---|---|---|---|
| `L_Clavicle` | `0x04` static Z | `(0, 0, 8.654)` | X,Y → 0 — **same** |
| `L_Forearm` | `0x01` static X | `(43.297, 0, 0)` | Y,Z → 0 — **same** |
| `L_Hand` | `0x01` static X | `(29.98, 0, 0)` | Y,Z → 0 — **same** |
| **`L_UpperArm`** | `0x01` static X | `(18.732, −25.116, −87.677)` | Y,Z → 0 — **differs by 91.20 cm** |

The upper arm is the only bone in the chain whose bind translation is not axis-aligned, so the
reference pose was injecting the authoring pose's Y and Z into every animated frame. That put each
arm root 93 cm from its clavicle instead of 19 cm and threw both arms across the body.

## 2. The refinement: an empty channel is not an identity channel

`LIKELY`. `recompose` is reached through `readNURBSCurve`, which is only called when a channel
actually stores something. A channel with no components at all is never read, so `out` keeps what
the caller had — the reference pose. The reader therefore uses:

- **component omitted from a channel that stores something** → identity;
- **channel that stores nothing at all** → the bound bone's reference pose.

This is not idle: filling an entirely absent channel with identity collapses 44 of
`AggressorBabyJane`'s bones onto their parents in `smg/smg_fire`. The refinement rescues 42 of the
44. The SDK build shipped here has headers and `.inl` only — no `.cpp` — so `sampleTranslation`
itself cannot be read, and this is inference from the call graph rather than from the source.

## 3. What it fixed

`CONFIRMED_BYTES`.

| | before | after |
|---|---|---|
| `L_UpperArm` local translation | `(19.142, −25.116, −87.677)` len 93.19 | `(19.142, 0, 0)` len **19.14** |
| `R_UpperArm` local translation | `(19.142, 27.574, 85.631)` len 91.98 | `(19.142, 0, 0)` len **19.14** |
| Lateral chain, `FidgetCrossbow` | `+17.31 / −23.68 / −22.70 / −48.21` | `+17.31 / +38.96 / +39.94 / +14.43` |
| Lateral chain, `FidgetPistol` | `+17.31 / −4.73 / −1.41 / −0.16` | `+17.31 / +53.02 / +56.33 / +57.59` |
| Left hand on the wrong side | **3,384 of 5,984 frames** | **48 of 5,984** |
| Closest the left hand gets to the grip | 11.08 cm | **4.36 cm** |

The two arm roots become the *same* offset. That dissolves the anomaly that dominated the previous
session's notes — that this rig's arm pair was a translated **duplicate** rather than a mirror,
alone among the game's six armed skeletons. There was no 93 cm phantom shoulder bone; it was the
authoring pose leaking into every frame. With it gone the roots are symmetric and the mirrored
clavicles do the left/right work.

Rendered: both hands are on the crossbow, the left supporting the fore-end and the right on the grip.

## 4. Blast radius

`CONFIRMED_BYTES`, A/B over every animation in the game on identical bytes: **30,680 of 827,598
tracks change (3.707%)**, and outside the viewmodel the change is small:

| package | tracks changed | worst |
|---|---|---|
| `UAPW_NEWPlayerHands` | 11,539 | **91.20 cm** — the fix |
| `UAPW_AggressorBabyJane` | 12,549 | 25.05 cm, all in `smg/smg_fire` — see §5 |
| `UAPW_Ryan` | 4 | 53.10 cm |
| `UAPW_ProtectorRosie` | 1,502 | 4.51 cm, root only |
| `UAPW_GathererGirl` | 3,863 | 0.23 cm |

The whole-game audit is unchanged on every headline figure — 33 packages, 883 wrappers, 399
skeletons, 16,031 animations, 100% playable, 47,560 events, 0 blocks unconsumed. The single-frame
jump counts all went **down**: 9,564 → 9,504 at ≥10 cm, 3,664 → 3,644 at ≥25 cm, 1,212 → 1,211 at
≥50 cm, 273 → 272 at ≥100 cm. A pinned injected component no longer fights the stored ones.

## 5. `smg/smg_fire` — one animation, still anomalous

`UNKNOWN`. `AggressorBabyJane`'s `smg_fire` is 6 frames and **54 tracks against 73** for her other
animations, and 41 of those 54 omit the translation channel entirely while 37 omit rotation. After
the refinement in §2, two bones still collapse: `Bip01_R_Forearm` and `Bip01_R_ForeTwist`, both bind
`(25.05, 0, 0)`, whose tracks store Y and Z and omit X. Havok would collapse them too.

It is not additive — **every one of the game's animations carries `blendHint` 0 (NORMAL)**, so the
additive explanation is ruled out by census rather than assumed. Nothing else in the game looks like
this: **0 of 15,998 animations omit translation on every track.** Recorded as a data anomaly rather
than fixed, because inventing a rule to rescue one animation of 16,031 is how the original fault got
in.

## 6. The evidence that was circular

`CORRECTED.` The reference-pose reading was recorded as `CONFIRMED_BYTES` on this basis: across all
130 hands animations, 4,452 tracks omit at least one translation component, and filling from the
reference pose "keeps 4,442 of them at their rigid bone length, versus 4,160 when filling with zero".

That measures its own assumption. Filling a component from the bind pose preserves the bind pose's
bone length **by construction**. The test could only ever favour the reading it was testing.

## 7. Two side metrics that were also wrong

Both are pinned as invalid by tests in `FirstPersonHandTests` so they cannot be reinstated.

- **The body frame** — `up = spine→neck`, `forward = shoulders→hands`, `left = up × forward` — feeds
  the hands into the axis that judges them. Even against the now-correct decode it calls a proven
  character's hands swapped on hundreds of frames.
- **The arm-root axis** — `L_UpperArm − R_UpperArm` — took as its reference the very bones that were
  misplaced, so it defined the fault as correct and reported 94% of frames fine. On the first-person
  bind pose that axis is the rig's **forward** direction: the 51.89 cm of "hand separation" it
  measured is front-to-back, and laterally the hands are 0.01 cm apart.

**The lateral axis now used is the head bone's local +Z.** `CONFIRMED_BYTES`: on every shipped
character with a `Bip01_Head` and feet it is world left (+Y after conversion) at dot 1.00, and it
coincides with that character's own clavicle axis at dot 1.00. It is measured on a bone the arms do
not drive, which is the property both earlier metrics lacked.

## 8. The lesson

The decode was checked against itself for three sessions. What broke it open was **an external
authority** — the Havok SDK — and the question that authority answered was not the one being asked.
Nobody was looking at the fallback; it had a `CONFIRMED_BYTES` label and a supporting measurement,
and both were wrong. A confidence label is only as good as the test behind it, and that test has to
be able to fail.
