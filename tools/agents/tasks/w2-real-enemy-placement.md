---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Real enemy placement — Medical has no splicers

The debug slice encounter is gone (v4/`68c9bb8` gated `SpawnSliceEncounter` behind verify
flags). Nothing replaced it, so a normal spawn into `/Game/BioShockSlice/1-Medical` has **zero
enemies**. The level's own manifest (`1-Medical.ue5-level.json`) places:
- **`AggressorSpawner` ×19** — where splicers spawn, with archetype + trigger conditions.
- **`TurretSpawner` ×5** and there's a `_import_turret_spawners` path already.
- Possibly `AISpawnPoint` / `AggressorSpawnPoint` markers.

BioShock spawns splicers on script triggers / spawn-zone repopulation, not all at level start.

## What to build

1. **Decode the spawner records.** `dotnet run --project src/BioShockStudio.Cli -c Release --
   properties 1-Medical <AggressorSpawner actor>` — archetype key, spawn count, trigger (script
   message / proximity / immediate), repopulation flag, patrol link. Document in
   `docs/research/` (extend `scripted-sequences.md` or a new `enemies.md`).
2. **Import path.** `tools/ue5/import_slice_enemies.py` (mirror `import_slice_doors.py`): place
   each `AggressorSpawner` as an `AShockAggressorSpawner` actor (new runtime class, or extend
   `AShockTurret`'s spawner if one exists) carrying the archetype + trigger. Wire it so:
   - immediate spawners populate a few frames after `BeginPlay` (floor-traced, on the navmesh —
     reuse the floor-snap from `SpawnOneSliceEnemy`);
   - triggered spawners hook the script system (`ShockActionSpawnAI` /
     `ManipulateSpawnZoneRepopulation` already exist as request-record stubs — make them drive
     the real spawner).
3. Wire `TurretSpawner` the same way (turrets hostile + hackable by default).
4. Add to `setup_playable_slice.py` STEPS.

Keep it faithful to the manifest — spawn where and what the level says, not a hand-picked set.
If a trigger condition can't be decoded, spawn on proximity to the spawner and say so.

## Deliverable

- `docs/research/enemies.md` (or extended `scripted-sequences.md`) — spawner record layout,
  trigger types, what's approximated.
- `import_slice_enemies.py` + runtime spawner class + STEPS wiring.
- Headless: `verify_enemies.py` — N spawners placed, each resolves an archetype; a `-game` check
  that spawning into Medical and walking the bathysphere→Pavilion route encounters ≥1 live
  hostile splicer (reuse the movement-route harness from `verify_collision.py`).
- `run_encounter` (verify flag) still passes.

## Constraints

- `tools/ue5/**` only (read `src/**` / run the CLI, don't modify it). Editor CLOSED for headless.
  `-run=pythonscript` → JSON out. MSYS forward-slash + `MSYS_NO_PATHCONV=1`.
- Don't reintroduce the un-floor-traced `AlwaysSpawn` bug — trace + nav-project every spawn.
- Do NOT commit. Diff for review.
