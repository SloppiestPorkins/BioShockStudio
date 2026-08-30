---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Add visible firing feedback — muzzle flash, tracer, hit marker, light recoil — so shooting reads
as shooting. Asset-free (no Niagara / no sound assets); use engine primitives.

## Context
`AShockWeapon::FireAt(InstigatorActor, Start, Direction)` does the hitscan + `ApplyDamage`
(`5e822ec` / `afa34d6`). The AI ranged branch (`101ba14`) calls the same `FireAt`. `AShockPlayer`
has a `CameraComponent`. No visual/audio feedback on any of it.

## Do — all engine primitives, no imported assets
1. **Muzzle flash:** on a successful shot, briefly enable a small `UPointLightComponent` at the
   muzzle (`Weapon->Mesh` socket if one exists, else the trace `Start`) — warm colour, high
   intensity, ~0.04 s via a timer, then off. Create the component lazily, reuse it.
2. **Tracer:** `DrawDebugLine(World, Start, HitOrEnd, FColor(255,220,150), false, 0.05f, 0, 1.5f)`
   from muzzle to the impact point (or trace end on a miss). Debug draw is visible in PIE and
   needs no asset. Gate behind a `bDrawTracers` UPROPERTY (default true).
3. **Hit marker:** on a pawn hit, `DrawDebugPoint` / a tiny `DrawDebugSphere` at
   `Hit.ImpactPoint` for ~0.15 s, red-ish. On a world hit (add a world-static trace channel to
   the query so misses that hit geometry still register a spark), a small yellow one.
4. **Recoil:** on the *player's* weapon only, a small camera kick — add pitch to the controller
   rotation (~-0.6°) that eases back over ~0.12 s, or `APlayerController::ClientStartCameraShake`
   with a minimal C++ `UCameraShakeBase` subclass. Keep it subtle. AI fire = no camera effect.
5. **Dry click / reload** already log (`BIOSHOCK_WEAPON_DRY`) — optionally flash the muzzle light
   dim-red on a dry trigger. Optional.
6. `run_weapon_feedback.py` / `verify_weapon_feedback.py` — headless: fire once, assert the
   muzzle light component exists and toggled, a tracer draw was issued (a counter you increment),
   and player recoil offset applied then decayed; AI fire issues a tracer but no camera kick.
   `Success - N error(s)`.
7. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.**
- Do NOT change hitscan damage, range, the ammo gate, the AI FSM, or `ApplyDamage`. This is
  presentation bolted onto the existing `FireAt` result.
- No imported assets, no new module unless a camera-shake base needs `GameplayCameras` (prefer
  the manual pitch kick to avoid it).
- `docs/ENGINEERING_RULES.md`: smallest correct change, keep it subtle, verify each claim.
