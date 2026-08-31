---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C3 — hacking, first slice. Security turret as a real runtime actor + a hack flow that
flips its allegiance. Camera/bot and the pipe minigame are the next slices (note them).

## Context
- `AShockPlayer` already has `SetSecurityHacked(bool, time)` / `IsSecurityHacked()`,
  `SetTurretHacked(FName, bool)` / `IsTurretHacked(FName)` (a `TMap<FName,bool>`) — bookkeeping
  only, nothing acts on it.
- Stubs: `ShockActionHackTurret` (`Configure(FName turret, bool hacked)` →
  `Player->SetTurretHacked`), `ShockActionHackSecuritySystem` (`Player->SetSecurityHacked`),
  `ShockActionUnHackSecuritySystem`, `ShockActionSpawnTurret` (spawns a bare `ATargetPoint`
  placeholder — replace with the real actor), `ShockActionStartSecurityAlarm` /
  `StopSecurityAlarm`, `ShockActionMakeBotsAttack`, `ShockActionActivateSecurityBot`.
- Combat pieces to reuse: `AShockWeapon` (hitscan `FireAt`), `UShockDamageLibrary::ApplyDamage`,
  `ABaseShockAI` perception cone/LoS pattern (a9/a18), the a19 muzzle/tracer feedback.
- `tmp/uc_shockgame/` — `SecurityCamera*.uc`, `Turret*.uc`, `SecurityBot*.uc`,
  `HackableDevice*.uc`, `HackingComputer*.uc` — hierarchy + `defaultproperties` usable,
  bodies degraded. Grab real numbers (detection range/angle, fire rate, health, hack
  difficulty) where the `.uc` defaults carry them; PLAUSIBLE-label the rest.

## Do
1. **`EShockDeviceAllegiance`** enum { Neutral, Hostile, Friendly, Disabled } and
   **`AShockSecurityDevice`** (AActor base): `DeviceLabel` (FName), `Allegiance`,
   `DetectionRange` / `DetectionHalfAngleDeg`, `Health` + `ApplyAuthoredDamage` (reuse the
   pawn pattern), `virtual void TickDevice(float)` (perception + act), a
   `BIOSHOCK_DEVICE label=<n> allegiance=<s> target=<n>` log on state change. Sedate when
   `Disabled`. On death → `Disabled` + optional debris.
2. **`AShockTurret : AShockSecurityDevice`**: mount + barrel; each `TickDevice` — find the
   nearest pawn in range+cone+LoS whose "side" opposes `Allegiance` (Hostile turret shoots the
   player + friendlies; Friendly turret shoots `ABaseShockAI`), and fire a hitscan at it on
   `FireInterval` (reuse `AShockWeapon` or a direct `ApplyDamage` + a19-style tracer). Idle
   sweep when no target. `TurretHealth` ~40 PLAUSIBLE.
3. **Hack flow** on `AShockPlayer`: `bool TryHackDevice(AShockSecurityDevice*, float
   difficulty01)` — a PLAUSIBLE skill-check stand-in (deterministic for verify: succeeds when
   `difficulty01 <= HackSkill`, `HackSkill` default 0.7; or a seeded roll — your call, but
   the verify must be able to force pass/fail). On success → device `Allegiance = Friendly`,
   `SetTurretHacked(label, true)`, `BIOSHOCK_HACK label=<n> result=ok`. On failure →
   `BIOSHOCK_HACK label=<n> result=fail`, optional feedback shock (small self-damage /
   alarm). `UnHackDevice` / the security-shutdown timer flips Friendly→Neutral or
   Hostile→Disabled for `ShutdownTime`.
4. **Wire the actions**: `ShockActionHackTurret::ApplyInWorld` → find the `AShockTurret` by
   `TurretLabel`, set its `Allegiance` per `bSetHacked`. `ShockActionSpawnTurret` → spawn a
   real `AShockTurret` at the spawner (drop the `ATargetPoint`). `ShockActionHackSecuritySystem`
   → also flips every `AShockSecurityDevice` to `Disabled` for `ShutdownTime`.
   `StartSecurityAlarm` / `StopSecurityAlarm` → a world alarm flag every Hostile device reads
   (raises detection range while active).
5. **Input + slice**: a `HackTool` key (`H`) → line-trace for an `AShockSecurityDevice`, call
   `TryHackDevice`. In the slice, spawn one Hostile `AShockTurret` near the encounter (behind
   `bEnableSliceTurret` default **false** so `run_game_possess` is unaffected unless a verify
   opts in). `setup_playable_slice.py` new `hack_key_mapping` step (`HackTool` → `H`).
6. `run_hacking.py` / `verify_hacking.py` — headless: spawn a Hostile turret + a player + an
   AI. Assert: Hostile turret damages the player over a few ticks; `TryHackDevice` with
   easy difficulty → success, allegiance Friendly, turret now damages the AI not the player;
   `TryHackDevice` with hard difficulty → fail, still hostile; `SetSecurityHacked(true, t)` /
   `ActionHackSecuritySystem` → turret Disabled, stops firing; a killed turret → Disabled.
   `Success - N error(s)`. (Follow the `verify_plasmid.py` teardown pattern — guarded
   `_destroy_all` + reset the spawn list per section, so no "not part of the world editor".)
7. `docs/FULL_GAME_CONVERSION.md` C3 hacking bullet: what shipped, the PLAUSIBLE numbers,
   and the TODOs (pipe minigame / hack-tool UI, security camera + alarm-summons-bot,
   `AShockSecurityBot`, RPG-adjacent devices, U-Invent auto-hack darts).

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`) + one C3 doc bullet. No `src/**`, `tests/**`.
  No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged**: `run_game_possess.py` still logs possess + slice with
  **health 100 → 75, fire=1, failures []** (warm the cook with a direct `-game` launch first,
  then verify). `run_plasmid` / `run_ai_brain` / `run_ai_combat` / `run_hit_reaction` /
  `run_weapon_def` stay green. The slice turret is OFF by default.
- Don't touch the damage library's math, the plasmid framework, the c2 brain, the weapons,
  the HUD contract, or the encounter. New actors + a hack flow + action wiring only.
- Real numbers from the decompiled `.uc` where the defaults carry them; every invented value
  gets a `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md` — smallest correct change.
- **Partial is fine**: `AShockSecurityDevice` + `AShockTurret` + `TryHackDevice` +
  `ActionHackTurret` wired + the verify, with the alarm / security-shutdown / spawn-turret
  bits noted TODO — as long as it compiles and every existing verify stays green.
