---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Add a minimal in-game HUD: player health and weapon ammo on screen. Right now the only feedback
is log lines (`BIOSHOCK_AMMO`, health) — a playtester can't see either.

## Context
`AShockPlayer` has `CurrentHealth` / `AuthoredMaxHealth`. `AShockWeapon` has
`RoundsInMagazine` / `ReserveAmmo` / `bEnforceAmmo` (`afa34d6`). The menu / death overlays are
C++ `UUserWidget` subclasses (`ShockMainMenuWidget` `f5300fe`, `ShockDeathOverlayWidget`
`5be5e3a`) — follow that pattern, no asset required.

## Do
1. `UShockHudWidget` (C++ `UUserWidget`): bottom-left health readout (number + a simple bar),
   bottom-right ammo readout (`mag / reserve`, or just `mag` with reserve smaller). Deco-plain
   styling is fine — legible white/gold text, semi-transparent backing. Hidden automatically
   when `bEnforceAmmo` is false → show just health (AI-less test maps), or always show ammo and
   let it read `--` when the gun has no ammo model.
2. It pulls live values on a cheap timer (~0.1s) or via `NativeTick` — reading
   `GetOwningPlayerPawn()` → `AShockPlayer` → health, and the player's equipped `AShockWeapon` →
   ammo. No new delegates required, but if `AShockPlayer` / `AShockWeapon` already broadcast
   changes, bind to those instead of polling.
3. `AShockGameMode` (gameplay GameMode, not the menu one): create + add the HUD widget to the
   viewport on `PostLogin` / possess, after the existing possess path. Remove it on player death
   if the death overlay covers the screen, re-add on respawn — or just leave it under the
   overlay, whichever is simpler.
4. Flash / colour-shift the health number red briefly when it drops (optional, keep it cheap).
5. `run_hud.py` / `verify_hud.py` — headless: possess, assert the HUD widget exists in the
   viewport and its bound text matches the player's health + the weapon's ammo; damage the
   player and assert the readout updates. `Success - N error(s)`.
6. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.**
- Don't touch the menu GameMode, the death overlay, weapon/damage/AI logic — this is display only.
- Keep it one widget class + the GameMode hookup. No HUD framework, no settings menu.
- `docs/ENGINEERING_RULES.md`: smallest correct change, verify the readout matches real values.
