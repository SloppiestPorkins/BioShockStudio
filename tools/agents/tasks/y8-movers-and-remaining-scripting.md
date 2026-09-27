---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**, docs/research/**
---

# y8 — ScriptableMover messages + remaining scripting gaps (SDK audit follow-up to y6)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.
> **Copyright:** the SDK guide is unlicensed and this repo is public — never copy its prose.
> Facts only, own words. Guide (read-only): `C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test\c7be037f-fb45-4801-8732-1d5df17a8bb3\scratchpad\unrealed-guide-mirror`.

Context: `docs/research/sdk-crossref-scripting.md` (GAP table + "Status (25 Sept)"). y5/y6/y7 are
landed (`Global_` variables, nested statements, per-runner timers, message payloads, `FShockRunnerList`
registry). Build on `UShockScriptRegistry::DispatchMessageWithFields`,
`UShockScriptSubsystem::DispatchMessageLoggedWithFields`, `ShockScriptReflection::CollectActorsByLabel`.
Do NOT touch `ShockVariableScope.*` global handling. **For each item re-verify the audit claim
against current code FIRST; if it's wrong, don't change it and say why in RESULT.**

## Items

1. **SCR-G01 ScriptableMovers [L].** Medical has 12 `ScriptableMover` actors imported as
   `AShockAnimatedProp` (keyframe move helpers exist). Make a mover (a) listen for
   `MessageTrigger` sent to its `TriggeredBy` label and toggle open/close along its keyframes
   (respect the mover's existing keyframe/`OpenTime`-style props — read the guide chapter on
   ScriptableMover for which UE2 properties matter, e.g. keyframe count, move time, whether it
   returns), (b) emit `MessageMoverOpening` / `MessageMoverOpened` / `MessageMoverClosing` /
   `MessageMoverClosed` under the mover's own label via the subsystem bus when a move starts/ends
   (the subclass table already maps Mover* → MessageMover). Importer: check
   `import_level._import_animated_props` carries `TriggeredBy` (label) — add it if not. Ignore
   triggers while mid-move unless the guide says otherwise.
2. **SCR-G11 [S].** Level load from a save dispatches `MessageSavegameRestored` (not
   `MessageLevelStarted`) so `_Resume` ambient scripts restart. Find the load path
   (`UShockSaveGame` / carry-state restore / `DispatchLevelEntryMessages`) and dispatch the right
   class; a fresh start must still send `MessageLevelStarted`.
3. **SCR-G18 [S].** Value-producing action temp results die when the script list ends: clear
   expression temporaries in `FinishExecution` (only temps; not script/global variables).
4. **SCR-G20 [M].** `UShockTriggerRelayComponent` + importer: honour `MaxEnterCount`,
   `RequireClearTrace`(if cheaply expressible), and the volume's filter class list where the
   export carries them; check what `import_level.py` actually exports for TriggerVolume /
   TriggerRadius first and only wire what exists.
5. **SCR-G12 remainder [M].** Item pickup / vending / reward messages: `MessageReceivedInventory`
   etc. should carry `ActualClass`, `Amount`, `Reason`, and door-keypad messages carry `Keycode`
   where the guide lists them. Find the existing senders (grep `DispatchMessageLoggedWithFields`)
   and add the missing fields; add a message-value assertion per field.
6. **SCR-G07 [M].** `ActionSetLightProperties` with ChangeProperty set applies light type /
   flicker→steady (map UE2 light effect enums onto UE5 light component: static steady vs a
   simple timeline flicker driven by a stored flag on the light actor, or at minimum steady
   apply + record). Keep the current brightness/colour behaviour.

Skip: watchers (G04), critical mode (G05), quests/facts/training (G08-G10), G13 stubs.

## Deliverable

- The fixes.
- `tools/ue5/verify_scripting_movers.py` (headless, `-run=pythonscript`-compatible, no sibling
  imports; house style `tools/ue5/verify_scripting_fidelity.py`): a case per item, each with a
  positive AND negative assertion. Gotchas: `is_executing` is a property not a method; spawn a real
  `AShockScript`/prop actor (a bare `new_object` runner has no world); use
  `unreal.SystemLibrary.is_valid(actor)`; UHT forbids `TArray` as a `TMap` value (wrap in a USTRUCT).
- `docs/research/sdk-crossref-scripting.md`: append "Status (27 Sept, y8)" listing each id as
  FIXED / NOT-A-BUG / DEFERRED with reason.
- Don't regress: `verify_scripting_fidelity.py`, `verify_script_trigger.py`, `verify_script_doors.py`,
  `verify_script_movement.py`, `verify_message_senders.py`, `verify_reflection_actions.py`,
  `verify_action_batch_r22.py`, `verify_import_scripts.py`, `verify_animated_props.py` (if present).
