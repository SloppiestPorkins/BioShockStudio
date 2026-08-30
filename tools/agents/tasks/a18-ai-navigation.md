---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Give the slice AI real navigation so it paths around geometry instead of walking straight into
walls. Degrade cleanly to the current direct-input movement when there's no nav data.

## Context
`ABaseShockAI::TickCombat` currently does `AddMovementInput` straight at the target plus a
`SetActorLocation` straight-line fallback (`8556d17`, my note in the a9 commit). The slice has
no NavMeshBoundsVolume and the AI has `AutoPossessAI = Disabled` — no `AAIController`, no path
following. `AShockGameMode::SpawnSliceEncounter` spawns the 3 enemies.

## Do
1. **Nav data for the slice.** In `AShockGameMode` (or the encounter setup), ensure a
   `ANavMeshBoundsVolume` exists covering the play area around `MedicalStart` (spawn one sized
   ~6000×6000×3000 uu centred between the player start and the enemy spawns if none is present),
   and that the world has a `RecastNavMesh` / nav system rebuild is kicked
   (`UNavigationSystemV1::Build` or the editor's equivalent). Log
   `BIOSHOCK_NAV bounds=%d navmesh=%d`.
2. **Path following.** Give `ABaseShockAI` an `AAIController` (set `AIControllerClass`,
   `AutoPossessAI = PlacedInWorldOrSpawned`, or spawn+possess one in `BeginPlay`). In the Chase
   state, use `AAIController::MoveToActor(target, MeleeRange * 0.8)` / a
   `UPathFollowingComponent`, refreshed when the target moves more than ~150 uu or every ~0.5s.
   Keep facing + the melee/ranged range checks as they are.
3. **Fallback.** If `UNavigationSystemV1::GetCurrent(World)` is null, or `MoveToActor` returns
   `Failed`/`Invalid`, or `ProjectPointToNavigation` misses — fall back to the existing
   `AddMovementInput` + straight-line behaviour, unchanged. A slice with broken nav must still
   play exactly like it does today, not worse. Gate the whole nav path behind a
   `bUseNavigation` UPROPERTY (default true) so it can be turned off.
4. Remove the `Move->TickComponent` manual tick if the AIController path-following makes it
   redundant; keep `EnableFloorlessMovement()` for the headless verify.
5. `run_ai_nav.py` / `verify_ai_nav.py` — headless: build a tiny nav volume + navmesh, spawn AI
   + target with a wall between them, tick a few seconds, assert the AI's path length > straight
   line (it went around) OR — if nav can't build headless — assert the fallback still closes the
   distance and log `BIOSHOCK_NAV_FALLBACK`. `Success - N error(s)`.
6. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line — nav + the fallback contract.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.** May need `NavigationSystem` /
  `AIModule` in `BioShockRuntime.Build.cs` — add them if so.
- The fallback is not optional. If real nav can't be made to work in the time you have, ship the
  `bUseNavigation` flag defaulting to **false** with the nav code present but dormant, say so,
  and leave today's behaviour intact.
- Don't touch the damage path, weapon, HUD, encounter spawn counts, or the combat FSM's
  state transitions — only *how Chase moves*.
- `docs/ENGINEERING_RULES.md`: smallest correct change, PLAUSIBLE labels, verify each claim.
