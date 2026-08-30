---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Handle player death. The AI combat loop (`8556d17`) can now bring the player's health to 0 via
`UShockDamageLibrary::ApplyDamage`, but nothing happens at 0 — close that gameplay loop.

## Context
`AShockPlayer` has health (`CurrentHealth`, `bIsDead`, invincibility). `UShockDamageLibrary::
ApplyDamage` already sets `bIsDead` when a pawn's health reaches 0. `ShockGameMode` owns the
slice (spawn, possess, `MedicalStart`). BioShock 1's real behaviour is a Vita-Chamber respawn;
a simple respawn-at-start is the faithful-first slice version.

## Do
1. `AShockPlayer::OnDied()` (or a delegate `FOnPlayerDied`) fired once when `bIsDead` flips true
   — from `ApplyDamage`'s death path, not polled. On death: disable player input
   (`DisableInput` / an input-mode switch), stop the combat/movement, optionally ragdoll or just
   freeze + drop to the floor.
2. `AShockGameMode` handles it: after a short delay (`RespawnDelaySeconds`, ~3s), either
   - reset the player — full health, `bIsDead=false`, clear invincibility, teleport back to the
     `MedicalStart` / `PlayerStart`, re-enable input — and (faithful-ish) leave already-spawned
     enemies as they are; OR
   - if a `bReloadLevelOnDeath` flag is set, `UGameplayStatics::OpenLevel` the current map.
   Default to the in-place reset (faster to verify, no level-load flakiness).
3. A minimal "You Died" UMG overlay (reuse the menu widget infrastructure from `f5300fe` /
   `ShockMainMenuWidget` patterns): shows on death, fades before respawn. Keep it a C++
   `UUserWidget` subclass, no asset required.
4. Also give enemies a death reaction: when `ABaseShockAI::bIsDead` flips, stop its combat tick,
   disable capsule collision, and (simple) hide after `CorpseFadeSeconds` or just leave the body.
   Wire this off the same ApplyDamage death path. Small.
5. `run_player_death.py` / `verify_player_death.py` — headless: damage the player to 0, assert
   `OnDied` fired once, input disabled; advance `RespawnDelaySeconds`, assert health restored,
   location back at start, input re-enabled. Also: an AI to 0 stops ticking combat.
   `Success - N error(s)`.
6. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line — death + respawn loop.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.**
- Fire on the state transition, never poll health in Tick.
- Keep the slice's existing possess / spawn / fire behaviour intact.
- `docs/ENGINEERING_RULES.md`: smallest correct change, verify each claim, confidence labels.
