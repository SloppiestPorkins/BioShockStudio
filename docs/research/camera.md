# First-person camera reactions (8 September 2026)

`AShockPlayer::TickViewEffects` writes the camera component's relative location every frame:
`FVector(0, BobY, CurrentEyeHeight + BobZ + LandDipOffset)`. `ViewHands` (and the weapon on its
grip socket) is attached to the camera, so the viewmodel rides the same offset.

## Walk / run bob

- Phase `ViewBobPhase` advances at `(1.75 + 0.9 * speedAlpha)` Hz (×2π), where
  `speedAlpha = clamp(horizontalSpeed / MaxWalkSpeed)` and is forced to 0 in the air.
- Vertical: `abs(sin(phase)) * Amp - Amp/2`, `Amp = 1.6 * ViewBobScale * speedAlpha` — two dips
  per stride.
- Lateral: `sin(phase * 0.5) * 1.1 * ViewBobScale * speedAlpha` — one sway per stride.
- No roll: the camera component runs `bUsePawnControlRotation`, which overwrites relative
  rotation each frame, so a roll term would be fought by the controller. Left out deliberately.

Amplitudes are feel-tuning, not decoded — `tmp/uc_shockgame` `ShockPlayerController` exposes
`ShakeOffsetRate`/`ShakeRotRate` for weapon/damage shake but no walk-bob constants (BioShock's
head bob is in the native `PlayerCamera`).

## Landing dip

- `TickViewEffects` samples `LastFallZSpeed` on every `MOVE_Falling` frame.
- `Landed()` converts it (180..1400 uu/s → 1..9 uu) into an impulse on `LandDipVelocity`.
- A critically-damped spring (`k = 170`) returns `LandDipOffset` to 0 over ~0.3 s.

## Crouch

- `CurrentEyeHeight` `FInterpTo`s between `BaseEyeHeight` (60) and `CrouchedEyeHeight` (36) at
  speed 10 while `bIsCrouched` toggles — UE lerps the capsule half-height over the same
  transition, this matches it on the camera instead of snapping.

## Knobs

- `bViewEffectsEnabled` (default true) — master off switch; also suppressed while
  `bMovementDisabled` (cutscene/lock).
- `ViewBobScale` (default 1) — scales bob amplitude only; land dip and crouch always apply.
