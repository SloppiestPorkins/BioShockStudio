---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**, docs/research/**
---

# y5 — `Global_` script variables (SDK audit SCR-B03, SCR-G06, SCR-G18)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.
> **Copyright:** the SDK guide is unlicensed and this repo is public — never copy its prose.
> Facts only, own words. The guide (read-only, if you need it) is at
> `C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test\c7be037f-fb45-4801-8732-1d5df17a8bb3\scratchpad\unrealed-guide-mirror`
> (chapter 21 "Variables"/"Scopes", chapter 23 "Variables" + examples 3, 6, 9, 14).

## The bug (verified by the reviewer — re-verify yourself first, and say so if any part is wrong)

`docs/research/sdk-crossref-scripting.md` SCR-B03. The runtime has **no** global-variable support:
`grep -ri global_ tools/ue5/BioShockRuntime/Source` returns nothing. Every
`UShockVariableScope` is per-`UShockScriptRunner`, so a `Global_*` name written by one script is
invisible to every other. Medical alone uses **65 distinct `Global_` names, 201 mentions**
(`C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical.script-actions.json`, e.g.
`Global_SteinmanBotAlive`, `Global_Med_OpenedMedicalGate`, `Global_TenLogsCompleted`), almost all
written by one script and tested by another. So cross-script story logic is silently broken.

## What the original does (facts)

- A variable name starting `Global_` (any case) belongs to every script, and survives level changes
  and saves. A name without the prefix is local to the script that created it.
- Values are text. Existing type inference (`UShockVariable::InferVariableClass`) stays as is.
- `ActionVariableAssign` / `AssignIfNotExist` / `Increment` / `Decrement`, the arithmetic actions,
  `BooleanStatement`/`TruthStatement` operands, and `resolveInfoList` variable bindings all read
  and write "a variable by name" — every one of those must route a `Global_*` name to the shared
  store, transparently (no new script-side syntax).
- (SCR-G06) A script can read another script's LOCAL variable as `ScriptLabel.varname`; assigning
  to a dotted name is not allowed. Implement the read via the registry (`FindScript`) if cheap; if
  not, leave a clear documented gap.
- (SCR-G18) Temporary return values of value actions die when the action list ends. Check
  whether anything leaks; fix only if it is small.

## Build

1. A shared store, case-insensitive on the name. Home: the game instance (`ShockGameInstance.*`
   already carries state across `TravelToLevel` — look at how it and `AShockPlayer`'s
   `RestoreInventoryStacksForTravel`/travel snapshot work and follow that pattern) so it survives
   travel. If a save/load system exists in the codebase (`ShockSaveLoadMenu.*` — check what it
   actually persists), include the globals in it; if saves don't persist script state yet, do NOT
   invent a save format — document it as a follow-up.
2. `UShockVariableScope` (`ShockVariableScope.h/.cpp`): the smallest change that routes
   `Global_*` names to the shared store while keeping every existing caller working
   (`TryGet/GetValueOrEmpty/Set/Find/...`). A runner constructed with no game instance (headless
   tests spawn bare runners with `unreal.new_object`) must still work: fall back to a
   process/world-level store, never crash, never silently drop.
3. Make sure new script-created variables via the C# sidecar/importer path
   (`tools/ue5/import_scripts.py`) need no change; if any importer step lowercases or namespaces
   variable names, say so.
4. `docs/research/script-vm.md`: add a short "Global_ variables" section (own words).

## Deliverable

- The runtime change.
- `tools/ue5/verify_global_variables.py` (headless, `-run=pythonscript`-compatible, no sibling
  imports; house style: `verify_reflection_actions.py` / `verify_script_trigger.py`, bare
  `unreal.new_object(ShockScriptRunner)` runners sharing a `ShockScriptRegistry`). Cases: script A
  assigns `Global_X`, script B (a different runner) reads it in an `ActionIf` and branches
  correctly; case-insensitive name (`global_x`); a non-`Global_` name is NOT shared between two
  runners; arithmetic/increment on a global from two scripts accumulates; a global survives a
  simulated travel (if you can drive the game-instance path from Python, do; else test the store
  object directly and say what is untested).
- Don't regress: `verify_script_runner.py`, `verify_script_trigger.py`, `verify_reflection_actions.py`,
  `verify_import_scripts.py`, `verify_action_batch_r22.py`.
