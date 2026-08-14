# First-person animation — the hand-side blocker

**Implementation:** `src/BioShockStudio.Core/Assets/AnimationPackage.cs`, `Core/Coordinates/GameBasis.cs`
**Tests:** `tests/BioShockStudio.Tests/FirstPersonHandTests.cs`
**Status:** **OPEN — this is the Phase 1 blocker.**

The first-person rig's **bind pose is correct** and **every animation puts the hands on the wrong
sides**. The right hand ends up left of the left hand.

## 1. How "which side" is decided

`CONFIRMED_BYTES`. **The lateral axis is the head bone's local +Z.**

```
left = the head bone's local +Z, in skeleton space
side = dot(L_Hand - R_Hand, left)
```

Verified on **every** shipped character that has a `Bip01_Head` and feet: that axis is world left
(+Y after conversion) at **dot 1.00**, and it coincides with the character's own clavicle axis at
**dot 1.00**. No exceptions anywhere in the game, so it is a Biped convention rather than one
character's quirk. It is measured on a bone the arms do not drive, which is the property both
earlier metrics lacked.

Sanity, with `replace` composition: `AggressorBabyJane` 18 of 592 sampled frames on the wrong side,
`GathererGirl` 34 of 1,217 — real, shallow crossings from melee and reaching.

### 1b. Two earlier metrics, both invalid — do not reinstate either

`REJECTED.` Both read green on data that is not, and each cost a session.

**The body frame** (`up = spine→neck`, `forward = shoulders→hands`, `left = up × forward`) feeds the
hands into the axis that then judges them. Its `left` is **perpendicular** to the rig's real lateral
axis under animation (0.08 alignment for the pistol against 1.000 in the bind pose — so the bind
pose's "pass" was true by construction and never a result). It calls `ProtectorRosie`'s hands
swapped on **2,415 of her 7,982 frames**.

**The arm-root axis** (`L_UpperArm − R_UpperArm`) takes the upper arms as the reference — but the
upper arms are precisely what is on the wrong side, so it defines the fault as correct and reports
94% of first-person frames fine. Worse, on this rig that axis is the **forward** direction: the
51.89 cm of "hand separation" it measured in the bind pose is front-to-back, and laterally the two
hands sit **0.01 cm** apart.

Both are pinned as invalid by tests in `FirstPersonHandTests` so they cannot come back.

## 2. The measurement

`CONFIRMED_BYTES`. Lateral position of each bone in the player's own view frame, `FidgetCrossbow`
frame 0. Positive is the player's left.

| bone | lateral | |
|---|---|---|
| `Bip01_L_Clavicle` | **+8.65** | correct |
| `Bip01_L_UpperArm` | **−18.76** | wrong side |
| `Bip01_L_Forearm` | −30.49 | |
| `Bip01_L_Hand` | **−49.59** | wrong side |
| `Bip01_R_Clavicle` | **−8.65** | correct |
| `Bip01_R_UpperArm` | **+4.62** | wrong side |
| `Bip01_R_Hand` | −1.61 | |
| `R_grip` | +1.87 | on the centreline |

**The clavicles are on the correct sides and the chain crosses the midline at the upper arm.** The
clavicle translations are never animated — they are the bind offsets `(0,0,±8.654)` in every frame —
so everything above the upper arm is beyond suspicion.

**Both arms cross, not just the left.** That is new, and it overturns the framing the rest of this
note was written under. Substituting the whole left chain with the exact Z-mirror of the right chain
gives `L_UpperArm −4.78` against `R_UpperArm +4.62` — perfectly mirror-symmetric, and still with the
right arm on the wrong side. So the fault is **upstream of both arms**, and the long hunt for what
was wrong with `Bip01_L_UpperArm` specifically was looking one level too low.

The scale of it is weapon-dependent: on the pistol everything collapses onto the centreline
(`L_UpperArm +1.08`, `L_Hand +0.59`, `R_Hand +0.73`), on the crossbow the left hand is thrown 50 cm
across. That matches the long-standing "the left hand does not touch the weapon" measurement in
`docs/QUALITY.md`; they are the same fault seen two ways.

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

**Applying the animation as a delta on the bind pose** (`anim_local * bind_local`). ~~Preserves bone
lengths and makes the first-person sides come out correct.~~ **Both halves of that were wrong**, and
the original rejection was argued on the body-frame metric, which is itself invalid — so it has been
re-taken on the head-frame axis and on bone rigidity:

| | hands on the wrong side | worst bone-length drift |
|---|---|---|
| `AggressorBabyJane`, replace | 18 / 592 frames | 2.017 cm |
| `AggressorBabyJane`, **additive** | **437 / 592** | **44.826 cm** |
| `GathererGirl`, replace | 34 / 1,217 | 0.034 cm |
| `GathererGirl`, **additive** | **843 / 1,217** | **20.602 cm** |
| first-person, additive | — | **71.967 cm** (`Bip01_Neck`) |

Additive tears the skeleton apart and breaks three quarters of a proven character's frames. It also
does not fix the first person: `FidgetPistol` goes to `L_UpperArm −50.3`, `R_UpperArm +104.9`.
`blendHint` is 0 (NORMAL) as well. Dead on every count.

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

**Update — this localisation is too low in the chain.** See §2: the *right* arm crosses the midline
as well, and mirroring the left chain onto the right leaves it crossed. Whatever is wrong is above
both upper arms, so `Bip01_L_UpperArm`'s broken mirror symmetry is a real oddity but not the cause.

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

## 4h. The track data is not transposed left/right

`REJECTED.` Swapping the animated tracks between each `Bip01_L_*` and its `Bip01_R_*` partner — both
for the clavicles alone and for the whole rig — leaves both hands on the same side of the weapon
(−40.56 and −12.55 against −54.86 as decoded, where the bind pose gives +45.48). Bone lengths stay
rigid throughout. So the swap is not a left/right transposition in the binding or the channel data.

One measurement note for whoever continues: on the weapon axis `R_Hand` reads −4.56 no matter what
is done to the tracks, because the weapon is parented to it and the projection is invariant by
construction. Only the **left** hand's reading carries information there; compare its bind value
(+45.48) against its animated value (−54.86).

## 4j. The sharpest result: the arm pair is a translated DUPLICATE, not a MIRROR

`CONFIRMED_BYTES`. This supersedes §4c as the localisation, and it is a structural statement about
the rig rather than about one bone.

For each `Bip01_L_*` / `Bip01_R_*` pair, take the two bones' **global rotations** in the bind pose
and ask which relation holds, reflecting in the plane whose normal is the rig's own clavicle axis:

| pair | first person | `AggressorBabyJane` | `GathererGirl` |
|---|---|---|---|
| Clavicle | **mirror 2.000** | mirror 2.000 | mirror 2.000 |
| UpperArm | **duplicate 0.084** | mirror 2.000 | mirror 2.000 |
| Forearm | **duplicate 0.085** | mirror 2.000 | mirror 2.000 |
| Hand | neither (4.07 / 6.00) | mirror 2.000 | mirror 2.000 |

A proper Biped is a mirror on every pair, and scores exactly 2.0. **The first-person rig is a mirror
only at the clavicle.** From the upper arm down the two chains carry effectively *identical* global
orientation — the arms were copied, not mirrored — and their lateral separation is **0.00 cm**: they
are 53.03 cm apart entirely front-to-back.

Across every skeleton the game ships that has both clavicles and both upper arms:

```
skeletons with clavicles and upper arms   6
arm pair is a MIRROR                      5
arm pair is a DUPLICATE                   1     UAPW_NEWPlayerHands
```

So the rig has no left/right distinction below the clavicle to inherit, and the animation does not
supply one either — it produces separation of the **wrong sign**. Lateral separation `L − R` down
the chain, in each rig's own lateral axis:

```
AggressorBabyJane / Fidget_Burning   clav  +6.93   upper +26.65   fore +33.03   hand +34.77
NEWPlayerHands   / FidgetCrossbow    clav +17.31   upper -23.38   fore -22.40   hand -47.98
NEWPlayerHands   / FidgetPistol      clav +17.31   upper  -4.74   fore  -1.42   hand  -0.14
```

The character fans out to the left monotonically. The first-person rig flips sign immediately after
the clavicle, and on the pistol it collapses onto the midline instead.

**One lead, measured but NOT applied and NOT verified:** substituting the whole left chain with the
Z-mirror of the right gives `L_UpperArm −4.78` against `R_UpperArm +4.62` — mirror-symmetric, but
with the two arms swapped. That hints that the arm data may be both mirrored and transposed relative
to the rest of the game. Transposition **alone** is already rejected (§4h) and a per-asset mirror is
forbidden by the coordinate policy, so this is recorded as an observation to explain, not a fix to
apply.

## 4k. The `SkeletalMesh` carries no second copy of the bind pose

`CONFIRMED_BYTES`. An Unreal `SkeletalMesh` normally ships a `RefSkeleton`, which would be an
independent statement of the same bind pose and would settle whether the arm chain is authored the
way it decodes. `NEWPlayerHands` does not have one that can be found: searching all 777,635 bytes of
its payload for the Havok bind translations in the game's basis finds no coherent run — `Neck.x
71.967`, `Forearm.x 43.297`, `L_UpperArm.z −87.677`, `R_UpperArm.y −27.574` and `R_UpperArm.z
+85.631` have **zero** hits, and the values that do hit are scattered single matches in vertex data.
Only 11 of the 47 Havok bone names appear in the package's name table at all.

The Havok `hkaSkeleton` is therefore the only statement of this rig's bind pose, and there is
nothing in the shipped files to cross-check it against.

## 4i. The clavicle rotations are decoded exactly as stored

`CONFIRMED_BYTES`. The clavicles are the only per-side structure above the upper arms, so if
anything above the arms is wrong it is these. It is not the decode. Read straight out of block 0 of
`FidgetCrossbow`, both are fully static rotations (mask `0x0F`, one packed `ThreeComp40`):

```
Bip01_L_Clavicle  rotation at +228:  78 AD 2F 74 24     c0=3448 c1= 762 c2=1140 omitted=2 negate=0
Bip01_R_Clavicle  rotation at +708:  15 E1 4F 97 2A     c0= 277 c1=1278 c2=2711 omitted=2 negate=0
```

Decoding those fields by hand — `(raw − 2047.5)/2047.5 × 1/√2`, missing component from unit length,
then the basis conversion `(x,y,z,w) → (−x,y,−z,w)` — reproduces the decoder's output to four
decimals on both. The translations alongside them read `8.6536` and `−8.6536`, the bind values.

So the asymmetry is **authored**: the bind clavicle pair mirrors about Z=0 exactly, and the animated
pair does not (residual 0.9027), and that is what the file says. The animated values are also pinned
across all 13 crossbow animations. A pinned constant that never varies looks like a base
orientation, and a base orientation would normally be symmetric — but it is what shipped.

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
