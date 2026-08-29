---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase 4 execution wiring — one batch. Move a small set of the most-used `ShockAction*` stubs
from "record the request" to "do it in-world", verified against the game.

## Context
`docs/UE5_FULL_PORT_PLAN.md` §5 Phase 4 + §9. The action-usage census (`ActionUsageCensusTests`,
Phase 2.2) is the priority order. Recently wired (do not redo): ToggleAIReactions,
DisplayOnScreenDebugMessage, SetPlayerInvincibility, SetAIPatrol, ChangePawnPhysics,
SetPawnInvincibility, SetAINormalLODOverrideTime, DisplayMapHUDRegion. Stubs live in
`tools/ue5/BioShockRuntime/Source/BioShockRuntime/Private/ShockAction*.cpp`; each currently
parses params + records a request. Verify scripts: `tools/ue5/verify_script_*.py` /
`run_script_*.py`.

## Do
1. From the census, list the action classes ranked by frequency that (a) still only record a
   request, (b) are NOT in the skip list below, (c) are a **self-contained in-world state change
   or simple call** — no latent/coroutine infrastructure, no new asset type, no new subsystem.
   Write that shortlist into the result.
2. Wire the top **5** from that shortlist to execute in-world in their `ShockAction*.cpp`
   (`ExecuteInWorld` / equivalent — match the pattern the already-wired ones use). Keep each
   change minimal and mirror an existing wired action's structure.
3. Rebuild: `tools/ue5/rebuild_runtime_fast.ps1` (needs the HostProject seeded — task
   `a1-hostproject-reseed`; if it still throws, stop with a clear message and list what you
   would have wired).
4. For each of the 5, run/extend the matching `run_script_*.py` + `verify_script_*.py` so there
   is headless evidence the action now takes effect (`Success - N error(s)`, state asserted
   before/after). If no verify script fits, add one following the existing pattern.
5. Update `docs/UE5_FULL_PORT_PLAN.md` §9 with a dated line naming the 5 actions wired and the
   verification, and the running "% of scripted behaviour executing" if the plan tracks it.

## Skip list (do NOT wire these here)
PlayAnimation (needs imported AnimSequences — Gate 5); Open/Close/Lock/UnlockDoor (need door
actors); ChangeSkin; CinematicFade; AISpeech; ChangeLevel (dangerous); ActionWait / any latent
or timed action; ActionIf / ActionLoop / ActionFor / control flow (already handled for Medical);
NonBlockingExecuteScript / BlockingExecuteScript (script-runner plumbing, separate).

## Constraints
- `tools/ue5/**` and the one `docs/UE5_FULL_PORT_PLAN.md` §9 line only. No `src/**`, `tests/**`.
- Do not commit, do not push. Scratch/build output to `$env:TEMP`.
- Cap: **5 actions**. If wiring one turns out to need infrastructure it doesn't have, drop it,
  record why, and pick the next from the shortlist — do not build the infrastructure here.
- `docs/ENGINEERING_RULES.md`: smallest correct change, verify each against real game state,
  confidence labels, "unknown" is allowed. Fast tier stays green.
