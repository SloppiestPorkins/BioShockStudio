---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Wire the scripted-event system into the playable slice so doors open

When you spawn into `/Game/BioShockSlice/1-Medical` and play, **nothing scripted fires** —
no game events, no doors opening (the user's report: "the door on the load room is meant to
open"). Everything needed exists but the pieces aren't connected in the slice.

## What's already there (do not rebuild)

- **`UShockScriptRunner`** (`tools/ue5/BioShockRuntime/.../ShockScriptRunner.cpp`, 554 lines) —
  control flow, `TryStartFromMessage(MessageClassName, SourceLabel)` → `MatchesTriggeredBy` →
  `StartExecution`. `AShockScript` wraps a runner; `Tick` calls `TickScript`.
- **`UShockScriptRegistry`** — `RegisterScript`, `DispatchMessage(FName MessageClass, FString SourceLabel)`
  fans a message to every registered runner whose `TriggeredBy` matches.
- **`import_scripts.py`** / **`run_import_scripts.py`** — spawns `AShockScript` actors from the
  level JSON with Label, location, `TriggeredBy`, and nested `ShockAction*` children. Idempotent
  via `BioShockScriptKey`. **Not called by `setup_playable_slice.py`.**
- **`AShockDoor`** (`ShockDoor.cpp`, 284 lines) — proximity trigger, yaw-swing open/close,
  collision updates, `FindByLabel(World, Label)`, `OpenDoor(bStayOpen)`, `set_door_label`.
- **`import_level.py` `_import_door_attachments`** (line ~1047) — spawns `AShockDoor` per door
  actor with its label. **Only runs in the full level import, not the slice.**
- **`ShockActionOpenDoor::ApplyInWorld`** already does `AShockDoor::FindByLabel` → `OpenDoor`.
  The Medical export has 11 `ActionOpenDoor` with `DoorLabel` set ("MedicalHallwayDoor",
  "TenenbaumDoor", "GathererSceneDoor", …) — see
  `%USERPROFILE%/Documents/BioShockUE5/Exports/slice/1-Medical.script-actions.json` `bySourceKey`.
- **`ShockActionSendTriggerMessage::DispatchVia`** → `Registry->DispatchMessage("MessageTrigger", source)`.
- **`TriggerVolume` → `TriggerBox`** import mapping (`import_level.py` line ~681). Medical has 86.
- Verify scripts: `verify_script_doors.py`, `verify_script_runner.py`, `verify_script_trigger.py`,
  `verify_import_scripts.py`, `run_script_*.py` — the headless harness pattern.

## The gaps to close

1. **Slice has no scripts.** Add an `import_scripts` step to `setup_playable_slice.py`'s `STEPS`
   list (it runs against the slice map `/Game/BioShockSlice/1-Medical`). Check `import_scripts.py`
   resolves the slice's level JSON + the `.script-actions.json` sidecar path — it defaults to
   `Exports\slice`, which is right.
2. **Slice has no doors.** Either call `import_level._import_door_attachments` from the slice
   setup, or add a focused door-placement step. The slice needs the `MedicalDoors` /
   `MedicalDoors_Solid` actors placed as `AShockDoor` with their labels.
3. **No trigger→message bridge.** A player crossing a `TriggerBox` must call
   `Registry->DispatchMessage("MessageTrigger", <triggerVolumeLabel>)`. Build the smallest thing
   that does this: a `UShockTriggerRelayComponent` added to each imported `TriggerBox` (or a
   `AShockTriggerRelay` actor), `OnComponentBeginOverlap` → find the shared registry → dispatch
   the volume's label. One-shot vs repeatable per the source `TriggerVolume` props if they're in
   the export; otherwise one-shot is the safe default.
4. **Shared registry.** Right now each `AShockScript` calls `EnsureRegistry()` and gets its OWN
   registry, so `DispatchMessage` only reaches scripts sharing that instance. `import_scripts.py`
   must create ONE `UShockScriptRegistry` (or a level subsystem / a single well-known actor) and
   `SetRegistry` it on every spawned script, and the trigger relay must find that same one.
   A `UWorldSubsystem` is the clean home; a tagged singleton actor is acceptable if simpler.
5. **On-entry scripts.** Some scripts fire on level start, not a trigger (`TriggeredBy` empty or a
   startup label). Check `MatchesTriggeredBy` — it returns false for empty `TriggeredBy` (matches
   UnrealScript `BeginPlay` only registering when non-empty). Confirm whether the load-room door
   is trigger-driven (player crosses a volume just past the spawn) or start-driven, and make
   whichever path work. The `TrainingScript` actors (Medical has some) are the tutorial-flow
   scripts and likely drive early doors.

## Deliverable

Spawn into the slice (`capture_shot.ps1` / `play_slice.ps1` / a `-game` session), walk to the
load-room door, confirm it opens from the script (not just from `AShockDoor`'s own proximity
trigger — disable that temporarily to prove the script path if needed). A short
`docs/research/scripted-events.md` on how the pipeline is wired (registry home, trigger relay,
where `import_scripts` sits in the slice setup). Headless: extend/keep
`verify_import_scripts` + `verify_script_doors` green, and add a check that a dispatched
`MessageTrigger` reaches a spawned script and its `ActionOpenDoor` resolves a placed `AShockDoor`.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless `UnrealEditor-Cmd` / `rebuild_runtime_fast.ps1`
  (`tasklist //FI "IMAGENAME eq UnrealEditor.exe"` → 0). Kill stray `UnrealEditor-Cmd` / `dotnet`
  / `BioShockStudio.Cli` between runs.
- `-run=pythonscript` swallows `unreal.log` — write probe/verify output to JSON.
- MSYS: forward-slash Windows paths + `export MSYS_NO_PATHCONV=1`.
- Do NOT commit. Do NOT add a `docs/HANDOFF.md` claim-table row. Leave the diff for review.
- Scope to plain doors + `MessageTrigger`. Keypad/locked/broken door state, quest scripts, AI
  spawner scripts (E-series follow-ups) are out of scope unless trivially on the path.
