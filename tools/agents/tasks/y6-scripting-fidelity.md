---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**, docs/research/**
---

# y6 — scripting fidelity batch (SDK audit `docs/research/sdk-crossref-scripting.md`)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.
> **Copyright:** the SDK guide is unlicensed and this repo is public — never copy its prose.
> Facts only, own words. Guide (read-only): `C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test\c7be037f-fb45-4801-8732-1d5df17a8bb3\scratchpad\unrealed-guide-mirror`.

Fix the audited scripting bugs below. **For each: re-verify the audit's claim against the current
code FIRST** (open the cited file:line). If the audit is wrong or the fix is not what the guide
says, do NOT change it — record why in your RESULT note. Already done (don't redo):
`ActionSendTriggerMessage` (MessageTrigger under the script label), subclass acceptance for
`scriptMessageClass`, `messageFilter`, `Global_` variables (a separate task, y5 — DO NOT touch
`ShockVariableScope.*` or add any `Global_` handling), `ActionExitScript` target, WaitForGoal.

## Items (audit ids; effort in brackets)

1. **SCR-B05 nested And/Or/Not [M].** Bindings use the names `lhs`/`rhs` but
   `ShockAndStatement`/`OrStatement`/`NotStatement` expose `bLhs`/`bRhs`, so the nested bind never
   lands (`ShockAction::ResolveParameters` uses `FindPropertyByName`). Also nested
   `UShockActionBool` results must feed `EvaluateBool`. Make compound statements with nested
   `BooleanStatement`/`ActionGetProperty`/`ActionGetMessageValue` operands actually evaluate
   (guide ch.23 Examples 12 and 14 are the acceptance tests — `OrStatement` of two
   `BooleanStatement`s over `ActionGetMessageValue`, and `AndStatement` over a numeric compare).
2. **SCR-B06 BooleanStatement type rules [M]** (`ShockBooleanStatement.cpp`): after variable
   substitution compare by inferred type — bool/name/string equality is case-insensitive; ordered
   operators on bool/name are always false; a numeric lhs coerces a non-numeric rhs to 0.
3. **SCR-B04 `ActionGetMessageValue` payload [M].** Messages now carry fields
   (`UShockScriptRegistry::DispatchMessageWithFields`, `UShockScriptRunner::TryStartFromMessageWithFields`;
   senders fill e.g. `Instigator`, `PawnLabel`, `RA`, `AILabel`, `DamagerLabel`). Make the runner
   retain the starting message's fields (a `LastMessageFields` map, cleared per start, queued
   messages keep theirs) and `ActionGetMessageValue.Property` read them (case-insensitive), falling
   back to the existing Source/Class aliases. A field absent -> empty return, no crash. Keep it
   valid only in the script that received the message (a callee started by ExecuteScript has none).
4. **SCR-B10 timers [M].** `ActionStartTimer` must start a timer on the RUNNING script (per
   runner, not `Player->SetPendingTimerSeconds`) and on expiry that script dispatches
   `MessageTimerExpired` under its own label; `ActionStopTimer scriptLabel=` cancels the named
   script's timer; a second start restarts. The runner needs to know world time (it gets
   `WorldTimeSeconds` in `TickExecution`). Guide ch.23 Example 7 (HammerLock/HammerUnLock and the
   self-listening PlasmidJuggler) is the acceptance test.
5. **SCR-B07 doors multi-match [S]:** Open/Close/Lock/Unlock door actions act on EVERY `AShockDoor`
   with the label, not the first. **SCR-B13 [S]:** a missing door label must not report success
   (return 0) — but check `verify_script_doors.py` and other verifies first for tests that rely on
   record-only success, and tell me which you changed.
6. **SCR-B08 label case-insensitivity [S]:** label equality is case-insensitive everywhere labels
   are matched (`ShockDoor.cpp`, `ShockDamageLibrary.cpp` FindActorByLabel, `ShockActionPlayEffect`,
   `BaseShockAI::CollectLabeled`, `ShockPhysicsLibrary::FindActorByLabel` ... grep
   `ESearchCase::CaseSensitive` near label compares). Don't blanket-replace; only label compares.
7. **SCR-B09 `#if WITH_EDITOR` label matching [M].** Many actions match actors by
   `GetActorLabel()` inside `#if WITH_EDITOR` and silently no-op otherwise (PlayEffect, SetProperty,
   ChangeCollision, HideOrShow, SetLightProperties, ...). PIE in the editor works, a packaged game
   would not. Introduce ONE shared label resolver that also works without WITH_EDITOR (actor tags
   the importer already writes — check `import_level.py`/`import_scripts.py` for an existing
   label-as-tag convention such as `BioShockKey=`/label tags — else `ShockScriptLabel` component/
   property) and route the WITH_EDITOR-gated actions through it. `ShockScriptReflection::ResolveTargetActor`
   / `UShockPhysicsLibrary::FindActorByLabel` are the existing shared helpers — extend those rather
   than inventing a third. If a fully non-editor label source does not exist yet, implement the
   resolver + make the importer write the tag, and document the re-import needed.
8. **SCR-B11 [S]:** `ActionBlockingExecuteScript`/`NonBlocking`: a callee that is already running
   refuses a second start (currently `StartExecution` restarts it). **SCR-B16 [S]:** disabling a
   script (`bEnabled` -> false via reflection) drops its `MessageQueue`.
9. **SCR-B12 `ActionCinematicFadeView` waits [M]** until the fade duration has elapsed (latent
   pending path like `ActionWait`).
10. **SCR-B17 `ActionDoorKeypadUsed` [M]:** tell the keypad control/door whether the typed code
    succeeded (Success binding) — resolve the keypad by label; if no keypad actor class exists in
    the runtime, say so and stop.
11. **SCR-G02 / SCR-G03 [S-M]:** `ArithmeticStatement` (produces a numeric value from lhs/rhs and
    ARITHMETICOP_*, usable as a nested binding) and `ActionGetLevelLabel` (lower-cased map file name).
12. **SCR-G19 [S]:** `ActionExitScript` stops EVERY script with the label (the registry is
    `TMap<FName, Runner>`, one per label — only do it if labels can really repeat in Medical:
    check the sidecar/level export for duplicate Script labels first).

Skip (bigger, tracked): SCR-B14 `DealDamage` empty-target class-wide, SCR-G01 movers,
SCR-G04 watchers, SCR-G05 critical mode, SCR-G07 light properties, quests/facts/training.

## Deliverable

- The fixes.
- `tools/ue5/verify_scripting_fidelity.py` (headless, `-run=pythonscript`-compatible, no sibling
  imports; house style `verify_script_trigger.py` / `verify_reflection_actions.py`): a case per
  item you changed, each with a positive AND a negative assertion.
- `docs/research/sdk-crossref-scripting.md`: append a "Status (25 Sept)" section listing each id as
  FIXED / NOT-A-BUG (with reason) / DEFERRED (with reason).
- Don't regress: `verify_script_runner.py`, `verify_script_trigger.py`, `verify_script_doors.py`,
  `verify_script_movement.py`, `verify_message_senders.py`, `verify_reflection_actions.py`,
  `verify_action_batch_r22.py`, `verify_import_scripts.py`.
