# BioShock 1 player movement

Status: source constants **CONFIRMED_EXTERNAL** from the decompiled shipped
`tmp/uc_shockgame/ShockPawn.uc` / `ShockPlayer.uc`; feel remains subject to interactive PIE QC.

## Shipped values and mapping

`ShockPawn.defaultproperties` supplies:

| BioShock property | Value | UE5 mapping |
|---|---:|---|
| `GroundSpeed` | 450 | `MaxWalkSpeed = 450` |
| `JumpZ` | 525 | `JumpZVelocity = 525` |
| `CrouchedPct` | 0.45 | `MaxWalkSpeedCrouched = 202.5` |
| `MaxDistanceToFallWithoutDamage` | 500 | recorded only; see unknowns |
| `BaseEyeHeight` | 60 | `BaseEyeHeight = 60` and camera offset |
| `CrouchEyeHeight` | 36 | `CrouchedEyeHeight = 36` |

`ShockPlayer` overrides `CrouchHeight=40`, `CrouchRadius=34`, and
`MaxAllowCrouchAcceleration=700`. It exposes crouch press/release logic and
`ActionDisablePlayerMovement` explicitly toggles both `bCanJump` and `bCanCrouch`.
No separate walk/run speed is authored in these classes; `GroundSpeed` is the normal movement speed.

The exported UC does not serialize inherited native `Pawn` defaults for `AccelRate`, `AirControl`,
or `MaxStepHeight`, so claiming BioShock-specific values for those would be a guess. The UE5 pass
keeps direct, conventional equivalents (`MaxAcceleration=2048`, braking 2048, friction 8,
`AirControl=0.05`, zero falling lateral friction, 35 uu step, 44-degree walkable floor) as labelled
feel tuning rather than as decoded BioShock constants. This produces prompt ground starts/stops,
limited mid-air steering, and steps over Medical thresholds without accepting steep walls.

## Input and camera

The playable setup now binds Space to jump and Left Ctrl hold to crouch, and enables crouching on the
movement component. Previously neither action was bound in normal play. Mouse X/Y remain raw
one-to-one legacy axes; project mouse smoothing is disabled to avoid acceleration-like lag. UE's
camera-manager pitch limit remains in force, and weapon recoil separately clamps to ±89 degrees.

The constructor now sets eye heights before attaching the first-person camera. This avoids the
camera retaining `ACharacter`'s default eye offset while the imported schema later reports 60.
Crouch uses UE's capsule interpolation and `CrouchedEyeHeight=36`.

## Deliberately unresolved

BioShock's fall-damage implementation is native (`TakeFallingDamage`); only the 500-unit threshold
and a `FallingDamageLinearMultiplier=1.4` property are visible. No UE damage formula was invented.
Camera landing dip/headbob is also native camera-animation behavior. Mantle and ladder behavior are
not present in the inspected UC defaults and are rig/level-system work outside this pass.
