---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase 4 execution wiring — batch 3. Same as batches 1 (`6f7d029`) and 2 (`d805533`): move the
next set of the most-used `ShockAction*` stubs from "record the request" to executing in-world.

## Already wired — do NOT redo
Batch 1: RemoveGoal, ShowTrainingMessage, FadeVolumeOverride, EnableOrDisableLevelSaving,
SetAIVulnerability. Batch 2: ActivateResurrectionStation, ToggleAIAttachmentVisibility,
SetHUDDisplayState, ToggleAIWeaponVisibility, EnableOrDisableLevelSwitching. Earlier:
ToggleAIReactions, DisplayOnScreenDebugMessage, SetPlayerInvincibility, SetAIPatrol,
ChangePawnPhysics, SetPawnInvincibility, SetAINormalLODOverrideTime, DisplayMapHUDRegion,
SetTipPriority, ToggleAIAttacking.

## Do
1. Rebuild the census-ranked shortlist of record-only stubs that are self-contained in-world
   state changes (no latent/coroutine infra, no new asset type, no new subsystem), excluding
   everything above. Write it in the result.
2. Wire the top **5**. `ApplyInWorld()` mirroring batches 1-2 exactly + matching
   `UShockScriptRunner` dispatch. Minimal supporting state.
3. Extend `verify_script_world_state_exec.py` (or `_3`) with before/after asserts. Run headless
   (`rebuild_runtime_fast.ps1` works — HostProject seeded, and it now purges stale files).
4. `docs/UE5_FULL_PORT_PLAN.md` §9: dated batch-3 line, action names, refs, cumulative %.

## Skip list
PlayAnimation; Open/Close/Lock/UnlockDoor; ChangeSkin; CinematicFade; AISpeech; ChangeLevel;
ActionWait / latent / timed; ActionIf / Loop / For / control flow; NonBlocking/BlockingExecuteScript;
ActionSpawnReactiveActor, ActionInitiateDamage, ActionTriggerHavokForceActor,
ActionChangeQuestArrowActor (flagged as needing infra).

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit, no push. Scratch to `$env:TEMP`.
- Cap 5. Drop any needing infra, record why, take the next.
- **`rebuild_runtime_fast.ps1` MUST compile your C++ before you finish** — a non-compiling
  BioShockRuntime is a failed task, fix it.
- `docs/ENGINEERING_RULES.md`: smallest correct change, verify each, confidence labels. Fast green.
