---
worker: chatgpt
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# R1.1 — script VM parameter resolution (resolveInfoList)

> **Run mode:** non-interactive, sandboxed — no UE launch/build. Research from
> `tmp/uc_scripting/Action.uc` (`ParameterResolveInfo`, `resolveParameters`), `Variable.uc`,
> `ActionCalcDistance.uc` / `ActionGetProperty.uc` / `ActionIf.uc` / `ActionRandomNumber.uc`
> (the actions that CONSUME resolved params), `docs/research/runtime-brain.md` §3, and the
> `.script-actions.json` sidecar shape (`import_scripts.py`). Then implement. Thorough.

Per `docs/research/runtime-brain.md` §3, `UShockScriptRunner` runs control flow but **actions
only get literal config** — `Action.resolveInfoList` is not ported. In `Scripting.Action`,
`resolveParameters()` binds each entry: a property on THIS action ← a script `Variable` (by
name) OR a `Property` on a sibling action's return `Variable`. This is how a script computes a
distance / spawns an actor / rolls a number and then USES the result in the next action.

## What to build

1. **Sidecar decode.** `AudioExporter` / the level exporter already serialize `resolveInfoList`
   per action (verify — `1-Medical.script-actions.json` `actions[].resolveInfo` or similar). If
   not, add it to the C# level exporter: `{ propertyName, sourceKind: "variable"|"actionProp",
   variableName, sourceActionIndex, sourcePropertyName }`.
2. **Runner.** Before executing an action, `ResolveParameters(Action)`:
   - `variable` → read the `UShockVariableScope` value, `SetPropertyText` on the action's
     `FProperty` by name (type-coerce).
   - `actionProp` → read the named property off the sibling action's last return value
     (`UShockAction` should expose its return `UShockVariable*` / a `GetReturnValue()` — add it;
     actions like `ActionCalcDistance`, `ActionRandomNumber`, `ActionGetProperty`,
     `ActionGetMessageValue` set a return).
3. **`import_scripts.py`** threads the resolve info onto each imported `UShockAction`.
4. Make `ActionCalcDistance`, `ActionRandomNumber`, `ActionGetProperty`, `ActionVariableAdd`
   family return a real `UShockVariable*` so downstream resolution has something to read.

## Deliverable

- `docs/research/script-vm.md` — the `ParameterResolveInfo` model, the two source kinds, how
  `import_scripts` carries it, worked example (CalcDistance → If).
- Runner + `UShockAction` return-value plumbing + `import_scripts.py` + the ~4 producing actions.
- Headless: extend `verify_import_scripts` — a script that assigns a variable, an action reads
  it as a param; `ActionCalcDistance` result drives an `ActionIf` branch; a `RandomNumber`
  result feeds `ActionVariableAssign`.

## Constraints

- `tools/ue5/**` + `src/**` (additive, Fast tests green) + `docs/research/**` + `tmp/**`.
- Don't regress the existing `verify_import_scripts` / `verify_script_doors` /
  `verify_script_movement` suites.
- Do NOT commit. Diff + RESULT.json.
