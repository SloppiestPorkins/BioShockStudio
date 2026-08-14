# First-person animation — the hand-side blocker

**Implementation:** `src/BioShockStudio.Core/Assets/AnimationPackage.cs`, `Core/Coordinates/GameBasis.cs`
**Tests:** `tests/BioShockStudio.Tests/FirstPersonHandTests.cs`
**Status:** **OPEN — this is the Phase 1 blocker.**

The first-person rig's **bind pose is correct** and **every animation puts the hands on the wrong
sides**. The right hand ends up left of the left hand.

## 1. How "which side" is decided

`CONFIRMED`. Earlier attempts at this question were all fooled — by a rolled camera, by a rig whose
local axes are not world axes, by bone names. The measurement now used is naming-free, view-free and
basis-free, and is built from the skeleton itself:

```
up      = spine -> neck
forward = shoulders -> hands          (orthogonalised against up)
left    = up x forward                (right-handed frame: forward, left, up)
```

A hand's side is the sign of its offset from the shoulders along `left`.

**Calibrated** against `ProtectorRosie`, whose left/right is independently proven from world anatomy
(feet near Z=0, toes ahead of ankles in X, `Bip01_L_*` at +Y after conversion). The method agrees.

## 2. The measurement

`CONFIRMED_BYTES`.

| | L_Hand | R_Hand | |
|---|---|---|---|
| First-person **bind pose** | **+25.95** | **−25.95** | correct |
| `FidgetCrossbow`, every frame | −15.6 | +15.6 | **swapped** |
| `EmptyFidgetCrossbow`, `EquipCrossbow`, `FireCrossbow`, `ReloadCrossbow`, the fidget accents | −11 to −16 | +11 to +16 | **swapped** |
| `ProtectorRosie`, 6 animations × 3 frames | +16 to +62 | — | correct throughout |

Rosie shows one transient negative frame at the end of `MG_AggToIdle`, which is an arm crossing
during a transition and is what a real crossed arm looks like. The first-person rig is swapped at
**every frame of every animation**, at a near-constant magnitude. That difference is what says the
method is sound and the fault is specific to the first-person animation path.

## 3. What this is NOT

Each ruled out by measurement, so that no future session repeats them:

- **Not a mirror, and not a bone-name swap.** Hand *chirality* — computed from each hand's own
  finger bones, and therefore independent of names — says `Bip01_L_Hand` is geometrically a left
  hand (+0.406) and `Bip01_R_Hand` a right hand (−0.406). Calibrated on Rosie, whose proven left
  hand measures +0.201. The geometry is not reflected and the names are not swapped.
- **Not the basis conversion.** The bind pose, which goes through exactly the same conversion, is
  correct.
- **Not the binding.** `TransformTrackToBoneIndex` is the identity, 0–46.
- **Not retargeting or additive blending.** `originalSkeleton` is empty and `blendHint` is 0.
- **Not channel misalignment.** No block in the entire game leaves its block unconsumed.
- **Not the socket or the weapon.** The weapon is parented under `Bip01_R_Hand` and follows it
  wherever it goes, so it can never disagree with the right hand — and equally can never be used as
  evidence that the right hand is correct.

## 4. The tempting fix, and why it is rejected

`REJECTED — do not do this.`

Applying the basis conversion **once more** to the decoded animation flips the sides back and makes
every animation measure correct. It is wrong:

The animation's fallback channels — the ones a track omits, which fall back to the bound bone's
reference pose — come out **exactly equal to the skeleton's bind translations**
(`Bip01_L_UpperArm` bind `(18.73, −25.12, −87.68)` against animated `(19.14, −25.12, −87.68)`; the Y
and Z match to the bit). That proves the decoded animation and the skeleton are **already in the
same basis**. Converting the animation again would put them in *different* bases, and the sides
would only look right by coincidence.

This is exactly the "make the screenshot look right" fix the project forbids. It is recorded here so
the next session recognises it as a dead end rather than rediscovering it as a breakthrough.

## 4b. Two more candidates, both rejected

`REJECTED.`

**Tracks as model-space rather than parent-local.** Composing each track as an absolute
model-space transform instead of a parent-local one collapses `Bip01_L_Forearm → Bip01_L_Hand` from
29.98 cm to 13.32 cm and puts both hands at 0.00. The tracks are parent-local; local composition
reproduces every bone length exactly.

**Applying the animation as a delta on the bind pose** (`anim_local * bind_local`) makes the
first-person sides come out correct (+62.41 / −62.41) and preserves bone lengths. It is **not**
applied, because there is no evidence for it and real evidence against:

- `blendHint` is 0 (NORMAL), not additive.
- It materially changes **every character animation too** — Rosie's `MG_AggToIdle` goes from +32.48
  to +6.60 — and her animations are currently correct, validated through FBX and Blender.

**A warning for the next session:** the side test is a *sign* test, and at least three different
wrong changes satisfy it (a second basis conversion, model-space composition, additive
application). A candidate fix must therefore also be checked against:

1. Rosie's animations, whose magnitudes must not move much;
2. bone rigidity — every bone length must stay at its bind value;
3. the fallback channels, which must keep matching the bind translations exactly.

Satisfying the sign test alone proves nothing.

## 4c. Localised: `Bip01_L_UpperArm` is the one bone that breaks the rig's mirror symmetry

`CONFIRMED_BYTES`. This is the sharpest result so far and the place to start.

**Both rigs are mirror-symmetric about the Z=0 plane.** For a quaternion, reflection about Z=0 is
`q = (x,y,z,w) → (−x,−y,z,w)`; for a translation it is `(x,y,z) → (x,y,−z)`. Testing every
`Bip01_L_*` / `Bip01_R_*` pair's **bind local**:

| | rotations mirroring about Z=0 | translations breaking the Z=0 mirror |
|---|---|---|
| `ProtectorRosie` | 24 of 25 | **0** |
| First-person hands | 19 of 21 | **1** |

The single translation outlier, and one of the two rotation outliers, is the same bone:

```
Bip01_L_UpperArm   L = (18.73, -25.12, -87.68)
                   R = (24.50, +27.57, +85.63)
   mirror of L about Z=0 predicts R = (18.73, -25.12, +87.68)      error 53.05
```

Z is nearly right (87.68 against 85.63). **Y is sign-flipped** (−25.12 against +27.57). So this pair
is related by a 180° rotation about X rather than by the reflection every other pair uses.

Two independent lines point at this same bone:

- It is the **only** bone in either rig whose bind local breaks the Z=0 mirror.
- Substituting the **bind** local for `Bip01_L_Clavicle` — its parent — flips the left hand back to
  the correct side (−15.62 → +14.17), and `Bip01_L_UpperArm` is the joint that chain drives.

It is also one of only four bones in the whole rig whose translation the animation actually drives,
so it takes the channel path rather than the reference-pose fallback path.

**Not yet established** whether this is a decode fault or genuinely authored that way. The decoder
handles Rosie's 25 pairs perfectly, so it is not uniformly broken; if it is a fault it is one that
only this bone's particular channel combination reaches. **Do not simply negate this bone's Y** —
that is a per-bone hack, and it must first be shown from the Havok bytes whether the stored value is
what we decode.

## 4d. The reference pose is not the pose the animations build on

`CONFIRMED_BYTES`. Across all 13 crossbow animations the clavicle rotations are **pinned to a single
value** — `Bip01_L_Clavicle` is byte-identical in 11 of 13, `Bip01_R_Clavicle` in 10 of 13, the rest
differing in the fourth decimal — and that value is nothing like the bind pose:

```
Bip01_L_Clavicle   bind (-0.5756, +0.0579, -0.8146, +0.0414)
                   every animation (-0.4837, -0.4439, -0.6861, -0.3134)
```

So the `hkaSkeleton` reference pose is an authoring pose, and every animation re-establishes its own
viewmodel base orientation on top of it. This matters because it undermines the assumption that
"bind correct, animation wrong" means the animation is faulty — the two are simply different poses,
and only one of them is what the game ever displays.

## 4e. Raw bytes: the reference pose is decoded correctly

`CONFIRMED_BYTES`. Read straight from the `hkQsTransform` records:

- the hierarchy is right — `Bip01_L_Clavicle` → `Bip01_L_UpperArm`, both clavicles under `Bip01_Neck`;
- every scale is exactly `(1,1,1)`, so there is no hidden negative scale;
- the clavicles mirror about Z=0 exactly, and the forearms do too once `q ≡ −q` is taken into
  account.

The `Bip01_L_UpperArm` asymmetry is therefore **what the file contains**, not a decode fault. Both
upper arms sit ~93 units from their clavicle (|L| 93.11, |R| 93.24) — the same distance, in
non-mirrored directions. Their *global* positions come out mirror-symmetric about Y=0
(`±26.51`), while the clavicles are mirror-symmetric about Z=0. The upper-arm local transform is the
joint that bridges those two conventions, which is why it is the one that breaks the test.

## 4f. Caveat on the side metric — read before trusting it further

`IMPORTANT.` The metric builds `forward` from `shoulders → hands`, so the hand positions feed into
the axis that then judges the hands. On a large, consistent rig like Rosie's that is harmless. On
this rig the clavicle line runs along Z while the arms splay along Y, so the clavicles supply no
usable lateral axis and `forward` is dominated by the arms themselves — the measurement is partly
circular.

Two things argue the finding survives anyway: the derived `left` stays 0.86 aligned with the bind
pose's `left` under animation, so the frame is not flipping; and the weapon — which hangs off the
right hand — ends up on the anatomical left, where the game plainly puts it on the right.

## 4g. Independent confirmation — the weapon's own left/right

`CONFIRMED_BYTES`. The circularity above is now settled with a reference that involves neither the
torso nor the hands: **the crossbow rig names its own limbs `X_Larm` and `X_Rarm`.** Their
difference points along +Y in weapon space, agreeing with the weapon mesh's lateral extent (48.8 cm
on Y against 81.9 on X and 30.3 on Z), so the sign is trustworthy even though the two bones sit only
2.86 cm apart.

Projecting each player hand onto that axis, about the limb midpoint:

| | L_Hand | R_Hand |
|---|---|---|
| **Bind pose** | **+45.48** — weapon-left | −4.56 — weapon-right |
| `FidgetCrossbow`, `ReloadCrossbow`, `FireCrossbow`, `EmptyFidgetCrossbow` | **−54.86** — weapon-**right** | −4.56 — weapon-right |

The left hand swings **100 cm across the weapon** and ends up on the same side as the right one.
`R_Hand` reads −4.56 in every case because the weapon is parented to it and cannot move relative to
it, which is the same reason it is never evidence about the right arm.

**So the swap is real and is not an artifact of the body-frame metric.** The bind pose puts one hand
either side of the weapon; every animation puts both on the same side.

## 5. Where to look next

`HYPOTHESIS`. The animation and the skeleton are in the same basis, the binding is the identity, and
the bind pose is right — so the swap has to come from how the animated locals compose, not from what
basis they are in. Unexplained facts that a correct explanation must account for:

- In the first-person **bind pose**, the clavicles separate along **Z** (`L − R = +17.31 Z`) while
  the hands separate along **Y** (`L − R = +51.89 Y`). One symmetric rig cannot mirror about two
  different planes. On Rosie, both separate along Y, consistently.
- The derived `left` axis for the first-person rig comes out along Y, which makes the clavicle
  separation nearly parallel to `forward` — anatomically the clavicle line should be the lateral
  axis, not the forward one.
- `Bip01_L_UpperArm` sits **93 cm** from its clavicle. For a viewmodel rig that is not obviously
  wrong, but it is not obviously right either, and it is the same joint whose local translation is
  one of only four in the whole rig that the animation actually drives.

Together these suggest the first-person rig's clavicle/upper-arm chain does not mean what a Biped
chain normally means, and that the animation drives it in a way the straight parent-child
composition does not reproduce. That is the thread to pull.

## 6. Reproducing the measurement

`FirstPersonHandTests` holds all three cases: the Rosie calibration and the first-person bind pose
both pass; `FirstPersonAnimationsKeepTheHandsOnTheCorrectSides` is **skipped with a reason** rather
than deleted or weakened, so the blocker stays visible in the suite. Remove the `Skip` to see it
fail.
