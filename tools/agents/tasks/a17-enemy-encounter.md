---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Turn the single scripted BabyJane into a small encounter: spawn 2-3 enemies of mixed type
(melee + ranged), staggered, so the slice has an actual fight.

## Context
`AShockGameMode::SpawnSliceEnemy` spawns exactly one `ABaseShockAI` labelled `SliceBabyJane`
250 uu in front of the player, applies the `Agg_BabyJane` archetype, and is idempotent
(returns the existing one if present). The AI combat loop (`8556d17`), ranged attack (`101ba14`),
archetype spawn (`27bc69e`) are all in. `SpawnSliceAmmoPickup` already places one pickup.

## Do
1. Replace the single spawn with `SpawnSliceEncounter(Player, Start)`: spawn **3** AI:
   - 2 melee (`Agg_BabyJane` archetype), fanned out ~200 uu apart, ~300-450 uu ahead.
   - 1 ranged — pick an archetype whose `bIsRanged` resolves true (a Leadhead/Thug type from
     `document.archetypes`; if none imports cleanly, spawn a `Agg_BabyJane` and
     `EquipAIWeapon` it directly so it uses the ranged branch), placed further back ~800 uu.
   Each gets a unique label (`SliceEnemy0..2`), `ApplyArchetypeLookup`, `EnsureHealthInitialized`,
   the same capsule-collision setup the current code does, and `AddTargetToAttackOnSight` for
   the player so they engage without needing to be shot first.
2. Stagger: spawn enemy 0 immediately, enemies 1 and 2 on short timers (~1.5s, ~3s) so it reads
   as a wave, not a clump. Timer, not tick.
3. Keep it idempotent — if `SliceEnemy0` already exists, do nothing (same guard as today).
4. Keep `SpawnSliceAmmoPickup` — maybe bump to 2 pickups given 3 enemies.
5. `BIOSHOCK_ENCOUNTER spawned=%d` log line. Update `VerifySliceFire` / the possess-verify path
   if it asserts exactly one enemy.
6. `run_encounter.py` / `verify_encounter.py` — headless: possess, advance a few seconds,
   assert 3 AI spawned with distinct labels, at least one has a weapon, all target the player.
   `Success - N error(s)`.
7. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.**
- Don't change the AI combat loop, damage path, weapon, or HUD — only the spawn.
- Don't break the existing `BIOSHOCK_SLICE_OK` / possess-verify evidence (adjust its enemy-count
  expectation if needed, keep the fire→damage assertion).
- `docs/ENGINEERING_RULES.md`: smallest correct change, timer not tick, verify each claim.
