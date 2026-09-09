---
worker: chatgpt
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# R2.1 — make ActionSetProperty / GetProperty / PropertyTest real (reflection)

> **Run mode:** non-interactive, sandboxed — no UE launch/build. Read
> `tmp/uc_scripting/ActionSetProperty.uc` / `ActionGetProperty.uc` / `ActionPropertyTest.uc`,
> the existing `ShockActionSetProperty.cpp` / `ShockActionPropertyTest.cpp` (stubs),
> `docs/research/runtime-brain.md` §4 (this is the highest-leverage action fix — 134 Medical
> uses), and how other actions resolve `FindByLabel`. Then implement. Small but exact.

`ActionSetProperty` sets a named property on a `FindByLabel(target)` actor to a value string;
`ActionGetProperty` reads one into the action's return `UShockVariable*`; `ActionPropertyTest`
compares one against a value and returns bool (drives `ActionIf`). Currently all three
validate + record `Last*` and do nothing — 134 Medical script beats that flip a flag or read a
value are dead.

## What to build

1. **`ResolveTargetActor(FShockActionContext, FName Label)`** helper (shared) — `FindByLabel`
   over the world (label OR name OR `BioShockKey=` tag), matching the existing action
   resolution.
2. **`ShockActionSetProperty::ApplyInWorld`**: `FProperty* P = Actor->GetClass()->FindPropertyByName(PropName)`
   (support dotted paths into a component: `StaticMeshComponent.Mobility`), then
   `P->ImportText_Direct` / `SetPropertyText` with the string value. Bool/float/int/name/string/
   FVector/FRotator/enum coercion. Log `BIOSHOCK_SETPROP target=%s prop=%s value=%s ok=%d`.
3. **`ShockActionGetProperty`**: read the property, format to string, store on the action's
   return `UShockVariable*` (add the return path — coordinate with x3 if it lands first; if not,
   add a minimal `GetReturnValue()`).
4. **`ShockActionPropertyTest`**: read + compare (`==`, `!=`, `<`, `>`, `contains`) → return a
   `UShockVariableBool`; `ActionIf` already reads a bool return.
5. Guard: never write to Engine/CDO objects; only level actors. Skip `Transient`/`EditorOnly`.

## Deliverable

- `docs/research/reflection-actions.md` — the property-path grammar, coercion table, the guard,
  which Medical scripts this lights up (spot-check 3-4 from the sidecar).
- The 3 actions real + the shared `ResolveTargetActor` helper.
- Headless: `verify_reflection_actions.py` — set a bool/float/vector on a spawned test actor
  and read it back; a dotted component path; `PropertyTest` → `ActionIf` branch; the guard
  rejects a CDO write.

## Constraints

- `tools/ue5/**` + `docs/research/**` + `tmp/**`. Additive.
- Do NOT commit. Diff + RESULT.json.
