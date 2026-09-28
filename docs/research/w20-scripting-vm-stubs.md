# w20 — scripting VM remaining stubs (28 Sept 2026)

Roadmap priority 2. Lane: `tools/ue5/**`, `docs/research/**`. Headless verify:
`tools/ue5/verify_scripting_vm_stubs.py` (Claude builds + runs; this worker did not launch Unreal).

Re-verified each item against current code before building — the brief's quest-stub claim was
already corrected in `docs/ROADMAP.md` (quests are real at `ShockPlayer.cpp` ~3112–3188).

## 1. Watchers — was unbuilt, now built

**Confirm:** no `ShockActionCreateWatcher` / `ShockWatcher` / `EnableWatcher` / `DisableWatcher`
existed under `tools/ue5/BioShockRuntime/Source/` before this change (grep empty).

**UC semantics** (`tmp/uc_scripting/ActionCreateWatcher.uc`, `Watcher.uc`, `ActionSetWatcherEnabled.uc`,
`Script.uc:233–260`, `MessageWatcher.uc`):

- `Script.watchers[]`; `ActionCreateWatcher` adds a `Watcher` with `watchedExpression` and, when
  `enabled`, enters `LookAtExpression` (Sleep 1.0 then `execute()`).
- `execute()`: if expression true → `enabled=false` (one-shot) and dispatch `MessageWatcher`
  (`scriptName`, `watcherName`).
- Enable/Disable target `scriptName` (or parent when `None`) and restart `LookAtExpression` on enable.

**Built:**

| Piece | Where |
|---|---|
| `UShockActionCreateWatcher` / `EnableWatcher` / `DisableWatcher` | new `ShockAction*Watcher.*` |
| `FShockWatcherState` + poll on runner | `ShockScriptRunner.h` (`Watchers`), `.cpp` `AddWatcher` / `SetWatcherEnabled` / `TickWatchers` |
| Message | `DispatchMessageWithFields("MessageWatcher", …)` with `scriptName`/`watcherName` fields |
| Schema defaults | `ShockSchemaLibrary.cpp` Cast blocks for the three actions |
| Import nesting | `import_scripts.py` `ActionCreateWatcher` childArrays (`newWatcher` / `watchedExpression`) |

Expression eval reuses `UShockActionBool::EvaluateInWorld` (same entry `ActionIf` uses) — no parallel
boolean engine. Poll interval is 1.0s from `Watcher.uc:44` (`__NFUN_256__(1.0)`).

**Census note:** zero `ActionCreateWatcher` / Watcher rows across all exported
`*.script-actions.json` under `BioShockUE5/Exports` — Medical never exercises this, but the VM
gap was real. Import wiring is ready if a later map ships one.

## 2. Critical / immediate on level travel — was unbuilt, now built

**Confirm:** zero `bIsGameCritical` / `bExecuteCriticalActionsImmediately` in
`tools/ue5/BioShockRuntime/Source/` before this change.

**Schema + instance data:** `Scripting.schema.json` `Action.defaults.bIsGameCritical=true`;
`ActionWait` / `ActionPlayEffect` / `ActionCinematicFadeView` / `ActionPrintClientMessage` default
`false`. Medical sidecar has 22 instance rows carrying `bIsGameCritical` (mixed true/false) —
wired through `import_scripts.apply_instance_props` and schema `Lookup` in `ApplyActionDefaults`.

**Built:**

- `UShockAction::bIsGameCritical` (default true); constructors of Wait / PlayEffect /
  CinematicFadeView / PrintClientMessage set false.
- `UShockScriptRunner::ExecutePendingCriticalActions` — walks remaining `RunQueue` from the
  current index, applies critical leafs (including `VariableAssign*` via `ApplyToScope`), skips
  latent waits / non-critical, then `FinishExecution`.
- `UShockScriptSubsystem::ExecutePendingCriticalActions` — every registry runner via new
  `UShockScriptRegistry::GetAllRunners`.
- `AShockGameMode::TravelToLevel` calls the subsystem flush **before** carry capture /
  `OpenLevel` (`ShockGameMode.cpp` TravelToLevel). `FaceActor` / `LogPromptFailDiagnostics`
  lambdas untouched.

## 3. `TestFact` boolean eval — was a honest stub, now wired

**Confirm:** `ShockActionTestFact.cpp:21–24` returned hardcoded `false` with the "Native TestFact
not ported" comment. `AssertFact` / `RetractFact` / `HasFact` on `AShockPlayer` (`ShockPlayer.cpp`
3085–3109) already real against `Facts` / `MakeFactKey`.

**Built:** `EvaluateInWorld` → `AShockPlayer::FindLocalOrFirst(World)->HasFact(Slot1,Slot2,Slot3)`
(same player resolve as `ShockActionAssertFact.cpp:29–38`). `EvaluateBool()` stays false without a
world (same convention as `UShockActionPropertyTest`). `ActionIf::ChooseBranch` already calls
`EvaluateInWorld` when a world is present (`ShockActionIf.cpp`), so TestFact now feeds If branches.

## 4. Training-message HUD — was store-only, now displayed

**Confirm:** `SetTrainingMessage` only wrote `LastTrainingMessage` (`ShockPlayer.cpp:3229`).
`ShockHudWidget` already had an unused `ToastText` (constructed, always Collapsed) plus the live
`InteractPromptText` pattern in `RefreshDisplay`.

**Built:** `RefreshDisplay` binds `ToastText` to `Player->GetTrainingMessage()` the same way
`InteractPromptText` binds `GetInteractionPrompt` — show name string, collapse when `NAME_None`.
`GetDisplayedTrainingMessageText()` for headless checks. `UShockActionClearTrainingMessage` now
has `ApplyInWorld` that calls `SetTrainingMessage(NAME_None)`.

No new UI subsystem — reused the existing toast slot. `ActionEnableOrDisableTrainingMessages`
remains a request-record stub (no training-manager gate yet; out of this task's four items).

## Verify coverage (`verify_scripting_vm_stubs.py`)

- Watcher: no fire before 1s / while false / while disabled; fires on true; one-shot disable;
  re-enable then fire; `ActionEnableWatcher` on a create-disabled watcher.
- Critical: blocked on Wait, flush runs critical assign, skips non-critical assign, ends run.
- TestFact: false → Assert → true → Retract → false; feeds `ActionIf` true branch.
- Training HUD: Show sets toast text; Clear empties it.

## Landing fixes (Claude, same day)

Three bugs found while building + verifying, all fixed before landing:

1. **UHT parameter-shadow build error.** `AddWatcher`/`SetWatcherEnabled` (both `UFUNCTION`) took a
   `bool bEnabled` parameter, which UHT rejects because `UShockScriptRunner` already has its own
   `bEnabled` member (`ShockScriptRunner.h:93`) — "shadowing is not allowed" is a hard UHT error,
   not a warning. Renamed both parameters to `bInEnabled` (header + `.cpp` + all internal uses).
2. **Verify script used the wrong Python reflection name for `bIsGameCritical`.** UE's Python
   binding strips the `b` Hungarian prefix from a bool property name (`bActive` → `"active"`,
   already established convention, see `verify_gameplay_fidelity.py:501`), so `bIsGameCritical` is
   `"is_game_critical"` in Python, not `"b_is_game_critical"` as the verify script guessed.
3. **The property is legitimately read-only from Python** (`VisibleAnywhere` + `BlueprintReadOnly`,
   correct for gameplay code) but the verify needed to force one test action non-critical to
   exercise the "skip on flush" path. Added `UShockAction::SetGameCriticalForVerify(bool)`, a
   `BlueprintCallable` test-only setter, rather than loosening the property's real access level.
4. **`is_executing` is a bool `UPROPERTY`, not a `UFUNCTION`** (`ShockScriptRunner.h:96`, vs. the
   separate C++-only `IsExecuting()` getter at line 225, which isn't Python-visible at all) — the
   verify script called it as `.is_executing()`, which fails with `TypeError: 'bool' object is not
   callable`. Fixed to plain attribute access.

Rebuilt, reran `verify_scripting_vm_stubs.py`: 31/31 checks pass. Regression sweep (
`verify_scripting_movers.py`, `verify_gameplay_fidelity.py`, `run_verify_interact_trace.py`) all
clean — interact-trace stays at the known 36 (unchanged from before this task, confirming the
`TravelToLevel` edit didn't disturb the `FaceActor`/`LogPromptFailDiagnostics` lambdas in the same
file).

## Intentionally not done

- Multi-map script IMPORT (priority 3) — Medical-only scope.
- Building / launching Unreal in this sandbox (Claude's job).
- `ActionEnableOrDisableTrainingMessages` global mute.
- Full UC loop critical-sub-action expansion inside `ActionLoop` during flush (flush walks the
  flat remaining `RunQueue` only; nested loop bodies already expanded into the queue by the
  normal runner when entered).
