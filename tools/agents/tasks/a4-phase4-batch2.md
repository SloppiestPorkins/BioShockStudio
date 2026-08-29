---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase 4 execution wiring — batch 2. Same as the just-landed batch 1 (`6f7d029`): move the next
set of the most-used `ShockAction*` stubs from "record the request" to executing in-world.

## Already wired — do NOT redo
Batch 1 (`6f7d029`): RemoveGoal, ShowTrainingMessage, FadeVolumeOverride,
EnableOrDisableLevelSaving, SetAIVulnerability. Earlier: ToggleAIReactions,
DisplayOnScreenDebugMessage, SetPlayerInvincibility, SetAIPatrol, ChangePawnPhysics,
SetPawnInvincibility, SetAINormalLODOverrideTime, DisplayMapHUDRegion, SetTipPriority,
ToggleAIAttacking.

## Do
1. From the action-usage census (`ActionUsageCensusTests` / the probe batch 1 used), rebuild the
   ranked shortlist of stubs that (a) still only record a request, (b) are NOT in the skip list,
   (c) are a self-contained in-world state change or simple call — no latent/coroutine infra, no
   new asset type, no new subsystem. Exclude everything in "already wired" above.
2. Wire the top **5**. `ApplyInWorld()` mirroring batch 1's pattern exactly. Minimal supporting
   state on ShockPlayer / BaseShockAI / ShockPawn as needed.
3. Extend `verify_script_world_state_exec.py` (or add `_2`) with before/after asserts for each.
   Run it headless (`rebuild_runtime_fast.ps1` works now — HostProject is seeded).
4. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line, 5 actions, ref count, cumulative %.

## Skip list (do NOT wire here)
PlayAnimation; Open/Close/Lock/UnlockDoor; ChangeSkin; CinematicFade; AISpeech; ChangeLevel;
ActionWait / any latent or timed action; ActionIf / Loop / For / control flow;
NonBlockingExecuteScript / BlockingExecuteScript; ActionInitiateDamage,
ActionTriggerHavokForceActor, ActionChangeQuestArrowActor (batch 1 flagged these as needing
infra — skip unless you can do them trivially and self-contained).

## Constraints
- `tools/ue5/**` + the one §9 line only. No `src/**`, `tests/**`. No commit, no push.
- Scratch/build output to `$env:TEMP`. Cap: 5 actions — drop any that needs infrastructure,
  record why, take the next.
- `docs/ENGINEERING_RULES.md`: smallest correct change, verify each, confidence labels. Fast
  tier stays green. If `rebuild_runtime_fast.ps1` fails to compile your change, FIX IT before
  finishing — a non-compiling BioShockRuntime is a failed task.
