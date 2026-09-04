---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Firing any weapon once snaps the camera straight up to the ceiling

## User report (verbatim, live PIE, 4 Sept 2026)

> the moment i shoot one bullet with any gun it goes straight to the ceiling

Immediate, on the first shot, with every weapon tried. This is **not** the sustained-
automatic-fire accumulation case the code's own comments already describe and claim
to have fixed (`WeaponRecoilKickRemaining += KickDegrees` instead of resetting, see
`ShockPlayer.cpp` ~line 649-654) — that mechanism only adds 0.6 degrees per shot,
nowhere near enough to explain a single shot snapping the view to the ceiling. Something
else is happening on the very first call.

## Why this was never caught: the existing test doesn't check the thing that's broken

`tools/ue5/verify_weapon_feedback.py` (~line 61-83) fires a real shot via
`shooter.try_fire_equipped_weapon()` and asserts `WeaponRecoilKickRemaining`
increased. It never reads `GetControlRotation()` — the actual camera pitch — before or
after. It also never confirms the spawned player has a valid `AController` at all in
that headless context (`ApplyWeaponRecoil()`'s pitch-changing block is gated behind
`if (AController* C = GetController())` — if that's null in the existing test's
context, the whole camera-affecting code path has **never been exercised by any test,
headless or otherwise**, until the user found it live in PIE just now). Passing that
test only proves the internal counter increments; it says nothing about what the
player actually sees.

## Where to look

`AShockPlayer::ApplyWeaponRecoil()` (`ShockPlayer.cpp` ~line 645-678):

```cpp
if (AController* C = GetController())
{
    FRotator Rot = C->GetControlRotation();
    Rot.Pitch = FMath::Clamp(Rot.Pitch - KickDegrees, -89.0f, 89.0f);
    C->SetControlRotation(Rot);
}
```

Investigate what `GetControlRotation().Pitch` actually holds at the moment of firing in
a real, possessed PIE player. Some concrete things to check (this task should verify
rather than assume):

1. **Representation range.** `FMath::Clamp` is a raw numeric clamp with no angle
   normalization — unlike `FMath::ClampAngle`, which `APlayerCameraManager::LimitViewPitch`
   uses internally (engine default `ViewPitchMin=-89.9`, `ViewPitchMax=89.9`, both
   signed, confirmed by reading `PlayerCameraManager.cpp` directly this session). If
   `Rot.Pitch` from `GetControlRotation()` is ever outside roughly [-90, 90] — including
   a technically-equivalent wrapped value like 350 for "-10 degrees" — a raw `Clamp`
   against `[-89, 89]` snaps it straight to a bound instead of adjusting it by
   `KickDegrees`, on the very first call. Confirm what range this project's actual
   input pipeline leaves `ControlRotation.Pitch` in (log it, don't assume) before
   deciding this is or isn't the cause.
2. Whether `bUseControllerRotationPitch = false` (set in the constructor, ~line 36)
   changes what `GetControlRotation()` reflects versus what the camera actually renders
   — these can diverge from each other by design when a pawn doesn't slave its own
   rotation to the controller.
3. Whether firing triggers *any other* code path that also touches pitch/control
   rotation/camera on the same frame (a second write racing or compounding with this
   one) — grep for other `SetControlRotation` / camera-rotation writers reachable from
   the fire path before concluding this is the only place involved.

## Fix

Once the actual mechanism is confirmed (not guessed), the fix likely belongs in
`ApplyWeaponRecoil()`'s pitch arithmetic — probably normalizing before clamping (mirror
what `APlayerCameraManager::LimitViewPitch` does with `FMath::ClampAngle`, or read/write
pitch through a path that's already known-safe) rather than a raw `FMath::Clamp` on a
value whose representation wasn't actually verified. Do not just widen the clamp bounds
or scale `KickDegrees` down — if the root cause is a representation mismatch, those
would only make the symptom less obvious, not fix it.

## Tests / verify

Extend `verify_weapon_feedback.py` (or add a companion) to do what it currently doesn't:
possess the spawned shooter with a real controller (`ensure_controller_for_verify()` is
the existing pattern for AI in `verify_ai_brain.py` — confirm the equivalent exists or
is needed for `AShockPlayer`), record `GetControlRotation()`'s pitch before firing, fire
once via `try_fire_equipped_weapon()`, and assert the pitch changed by a small,
bounded amount (order of `KickDegrees`, not tens of degrees) — not merely that the
internal kick counter moved. This is the assertion that's been missing; it should fail
against current `main` and pass after the fix.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- This worktree has no live UE session — headless assertions on `GetControlRotation()`
  are the evidence; a human confirms the actual feel in the editor afterward.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified,
  same style as the existing `h1`/`h2` entries.
