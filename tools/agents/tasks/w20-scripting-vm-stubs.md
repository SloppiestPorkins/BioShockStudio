---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**, docs/research/**
---

# w20 — scripting VM's remaining real stubs (roadmap priority 2)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.
> **Scope stays Medical-relevant** (these are engine-level VM features exercised by the live
> `1-Medical` slice, not a multi-map task) — do not touch script IMPORT for any of the other 20
> maps.

Context: `docs/ROADMAP.md` "Scripting VM and the Action library" + priority-2 line (corrected 28
Sept 2026 after re-checking current code — read the corrected wording, not an older cached
version). **For each of the four items below, re-verify against current code FIRST; the roadmap
line was already found wrong once this session (quests turned out to be real, not a stub) — don't
trust a description, trust the file.**

## 1. Watchers (`ActionCreateWatcher` family) — genuinely unbuilt, confirmed

No `ShockActionCreateWatcher.*`, `ShockWatcher.*`, or similar exists anywhere in
`tools/ue5/BioShockRuntime/Source/BioShockRuntime/`. Decompiled source (read-only reference):
`tmp/uc_scripting/ActionCreateWatcher.uc`, `WatcherBase.uc`, `Watcher.uc`, `MessageWatcher.uc`,
`ActionEnableWatcher.uc`, `ActionDisableWatcher.uc`, `ActionSetWatcherEnabled.uc`. Semantics
recovered from that source (decompilation is garbled around statement order in a few spots —
verified against `Script.uc:14,233,242,259-260`, which is clean):

- `Script` owns `watchers: array<WatcherBase>`. `ActionCreateWatcher.execute()` builds a `Watcher`
  object (a `watchedExpression` boolean-statement tree, same shape `ActionIf`/`BooleanStatement`
  already evaluate — check `ShockBooleanStatement.cpp`/`ShockActionIf.cpp` for the existing
  statement-eval entry point and reuse it, don't reinvent it), enters state `LookAtExpression`,
  and calls `parentScript.addWatcher(newWatcher)`.
- `LookAtExpression` polls once a second (`Watcher.uc:44`, `__NFUN_256__(1.0)` is a 1s
  Sleep/latent-wait, matching the existing `ScriptActionWait`/timer pattern already in
  `ShockScriptRunner.cpp`) while `enabled`, calling `execute()` each tick.
- `execute()`: if the watched expression evaluates true, set `enabled = false` (one-shot, not
  repeating) and dispatch a `MessageWatcher` message
  (`scriptName = parentScript.Label`, `watcherName = watcherName`) through the existing message
  bus (`UShockScriptRegistry::DispatchMessageWithFields`, same path used for
  `PawnDied`/`TookDamage`/etc. — `docs/research/` has prior write-ups of that path, e.g. from the
  y1/y5 tasks, if useful background).
- `ActionEnableWatcher`/`ActionDisableWatcher`/`ActionSetWatcherEnabled` (`ActionSetWatcherEnabled.uc`):
  target a script by label (`scriptName`, or the parent script itself if `scriptName == 'None'`),
  find the named watcher, set `enabled`, and restart `LookAtExpression` if re-enabled.

Implement as a `UShockAction`-family addition (`UShockActionCreateWatcher`,
`UShockActionEnableWatcher`, `UShockActionDisableWatcher`) plus whatever minimal watcher-state
object/struct lives on `UShockScriptRunner` (an array of pending watchers with their statement
tree + a per-runner 1s ticker is enough — this does not need to be a separate UObject class if a
plain struct is simpler given how the runner already owns its own timer,
`ShockScriptRunner.cpp:209-240`). Wire `ActionCreateWatcher`/`EnableWatcher`/`DisableWatcher` into
whatever the existing action-class registry/factory is (check `ShockSchemaLibrary.cpp` and how
any other recently-added `Action*` class registered itself, e.g. the y8 `ScriptableMover` actions,
for the exact registration convention — don't guess a new pattern).

## 2. Critical/immediate execution mode on level travel — genuinely unbuilt, confirmed

Zero occurrences of `bIsGameCritical` or `bExecuteCriticalActionsImmediately` anywhere in
`tools/ue5/BioShockRuntime/Source/`. Decompiled source: `tmp/uc_scripting/Action.uc:27,265`
(every `Action` has `bIsGameCritical`, default `true` on the base `Action` class itself —
check what overrides it false, e.g. `ActionWait.uc:60`, `ActionPlayEffect.uc:108` — so most
actions ARE critical by default; only latent/cosmetic ones opt out), `ActionLoop.uc:108,118`
(a loop honours the flag per-sub-action and also checks
`parentScript.bExecuteCriticalActionsImmediately`).

Real-world effect: when a level travel is about to happen
(`AShockGameMode::TravelToLevel`, `ShockGameMode.cpp:469`, right before the
`UGameplayStatics::OpenLevel` call at `~493`), any action flagged `bIsGameCritical` that's
still pending/queued on any live `UShockScriptRunner` should execute synchronously before the
level unloads, rather than being silently dropped or left to a latent tick that will never come.
Add: (a) a `bIsGameCritical` bool on `UShockAction` (check whether the schema/manifest already
carries a per-action-instance critical flag from the decoded `.script-actions.json` — if it does,
wire the import through instead of hardcoding a class-default table; if it doesn't, a per-
`ActionClassName` default table mirroring the `.uc` defaults above is the fallback), (b) a
`UShockScriptSubsystem` method (e.g. `ExecutePendingCriticalActions()`) that walks every live
runner's still-queued critical actions and runs them synchronously, (c) call it from
`TravelToLevel` before `OpenLevel`.

## 3. `TestFact`'s boolean evaluation — half-built, confirmed

`ShockActionTestFact.cpp:20-24`: `EvaluateBool()` is hardcoded
`// Native TestFact() is not ported yet — refuse a true result rather than invent one. return false;`
— an honest stub, not a silent bug. But `AssertFact`/`RetractFact`/`HasFact` on `AShockPlayer`
(`ShockPlayer.cpp:3085-3110`) are real and already store into `Facts` (`TSet<FString>`,
`ShockPlayer.h:1033`) via `MakeFactKey(Slot1, Slot2, Slot3)`. Wire `EvaluateBool()` to call
`AShockPlayer::FindLocalOrFirst(World)->HasFact(Slot1, Slot2, Slot3)` the same way
`ShockActionAssertFact.cpp:29-38`'s `ApplyInWorld` already resolves the player. Then confirm
`ActionTestFact`'s result actually feeds into whatever boolean-statement consumer calls
`EvaluateBool()` — grep for other `EvaluateBool` implementations (e.g. `ShockTruthStatement.cpp`)
to see the existing calling convention and match it, don't invent a new one.

## 4. Training-message HUD display — half-built, confirmed

`ShockActionShowTrainingMessage.cpp` → `AShockPlayer::SetTrainingMessage` (`ShockPlayer.cpp:3229`)
only stores `LastTrainingMessage`; nothing in `ShockHudWidget.cpp` reads it. Check how the HUD
already displays another transient/toast-style message (quest hint, pickup notification — grep
`ShockHudWidget.cpp` for whatever pattern already exists) and add a training-message display
following that same convention, bound to `LastTrainingMessage`. Also wire
`ShockActionClearTrainingMessage.cpp` (already exists, check its current `ApplyInWorld`) to clear
whatever you just added. If no existing toast/notification pattern exists in the HUD widget at
all, say so plainly in the research doc rather than inventing a new UI subsystem — that would be
a bigger scope call than this task.

## Deliverable

- Working, headless-verified implementations for all four items above, OR a plainly-stated finding
  for any item that turns out to need a design decision beyond this task's scope (say which, and
  why, don't guess a shape for something ambiguous).
- A new or extended verify script covering: a watcher firing its message on a true condition and
  NOT firing while disabled/before the condition is true; a critical action actually running
  synchronously before a simulated `TravelToLevel`; `TestFact` returning true only after a
  matching `AssertFact` and false after `RetractFact`; the training message HUD text changing on
  `ShowTrainingMessage`/`ClearTrainingMessage`.
- `docs/research/w20-scripting-vm-stubs.md`: what you found for each of the four items (including
  anything that contradicts this brief — re-verify, don't trust it blindly), what you built, cite
  file:line, own words.
- Don't regress: `verify_scripting_movers.py`, `verify_gameplay_fidelity.py`,
  `verify_interact_trace.py` (unrelated system, but touches the same `ShockGameMode.cpp` file this
  task's `TravelToLevel` change lands in — don't disturb the `FaceActor`/`LogPromptFailDiagnostics`
  lambdas landed in commit `5b6eb43`).
