# R2.1 — generic property reflection (`ActionSetProperty` / `ActionGetProperty` / `ActionPropertyTest`)

`docs/FULL_RUNTIME_PORT.md` R2.1, dispatched as `tools/agents/tasks/x5-actions-reflection.md`,
landed by Claude directly (11 Sept). This is the highest script-frequency single fix in
`docs/research/runtime-brain.md` §4/§7 — before this, all three actions validated their
parameters, recorded `Last*` fields, and did nothing.

## The mechanism (`ShockScriptReflection.h/.cpp`)

One shared, generic implementation used by all three actions:

- **`ResolveTargetActor(World, Label)`** — forwards to the existing
  `UShockPhysicsLibrary::FindActorByLabel`, which already chains editor label →
  `ABaseShockAI::GetScriptLabel()` → `BioShockKey=`/plain tag fallback. No new lookup was
  written; this is the "shared `ResolveTargetActor` helper" the task asked for, reused rather
  than duplicated a fourth time (SetProperty/PropertyTest each had their own ad hoc
  `TActorIterator` loop before this — both now call the shared resolver).
- **`ResolvePropertyContainer(Target, PropertyPath, OutPropertyName)`** — BioShock's
  `Object.Property` path is flat; our port is component-based, so a path may step into ONE
  component first: `"StaticMeshComponent.Mobility"` matches a component by class name
  (`Comp->GetClass()->GetName()`) or instance name, case-insensitively. A bare `"Property"`
  (the 1:1 BioShock case) resolves directly on the actor. A dotted path naming a component that
  doesn't exist on the target actor is a hard failure, not a silent fall-back to the actor —
  wrong-object writes are worse than a logged miss.
- **`SetPropertyFromText` / `GetPropertyAsText`** — `FProperty::ImportText_Direct` /
  `ExportTextItem_Direct` on `Property->ContainerPtrToValuePtr`. This is UE's own property-text
  grammar, so it covers bool/int/float/FName/FString/struct (FVector, FRotator, …)/byte-enum for
  free — no per-type branch to hand-maintain.
- **`IsPropertyWritable`** — refuses `RF_ClassDefaultObject`/`RF_ArchetypeObject` containers, a
  non-level-actor owner, and `CPF_Transient`/`CPF_EditorOnly`/`CPF_Deprecated` properties. Script
  data should never poke a shared CDO or a property with no gameplay meaning.

`ActionSetProperty` and `ActionPropertyTest` keep their existing special-cased fast paths
(`Label`/`ActorLabel`, `bHidden`/`Hidden`) ahead of the reflection fall-through — those already
had real side-effecting behaviour (`SetActorLabel`, `SetActorHiddenInGame`) that a raw property
write wouldn't trigger, so they stay first-class, not folded into reflection.

`ActionGetProperty` is a **new class** — it didn't exist in the port at all (empty `.h`/`.cpp`
stub files). It reads via the same reflection path and stores the text on the new base-class
return-value carrier.

## The return-value carrier (`UShockAction::ReturnValueText` / `bHasReturnValue`)

R1.1 (x3, dispatched to codex in parallel with this task) needs every producing action
(`ActionGetProperty`, `ActionCalcDistance`, `ActionRandomNumber`, …) to expose its result so a
sibling action's `resolveInfoList` can read it as a parameter. Rather than block R2.1 on R1.1's
design for that carrier, `UShockAction` gained the smallest possible one now: a plain
`FString ReturnValueText` + `bool bHasReturnValue`, set via `SetReturnValueText`. Deliberately
NOT a typed `UShockVariable` object — one carrier, not two, and R1.1's resolver can read this
field directly (or build a richer typed wrapper around it) when it lands. `ActionGetProperty`
sets it from the read value; `ActionPropertyTest` also sets it from its own bool result
(`"True"`/`"False"`) since a property test result is exactly the kind of value a later action
would want to consume.

Read it from Python via `get_editor_property("return_value_text")` /
`get_editor_property("has_return_value")` — the `GetReturnValueText(FString&) const` UFUNCTION's
bool-return-plus-out-param signature does not bind to a clean 2-tuple through the Python
reflection layer; the plain properties are the reliable path (`verify_reflection_actions.py`
found this the hard way — see Gotchas below).

## A bug found and fixed along the way

`ActionPropertyTest`'s `ComparePropertyStrings` compared `Equals`/`NotEqual` (op 2/3) as bare
strings even when both sides were numeric — only the ordering ops (`<`/`<=`/`>=`/`>`) took the
numeric path. `ExportTextItem_Direct` formats a `float` as `"12.500000"`; a script author (or
this task's own headless test) writing `Value="12.5"` would string-compare unequal and silently
misfire every float-property equality test. Fixed to use the same `FMath::IsNearlyEqual` path
as the ordering ops when both sides parse as numeric. This was a real, pre-existing defect,
not something this task introduced — it just never mattered while every `PropertyTest` target
was the `Label`/`bHidden` special cases, neither of which is numeric.

## Spot-check against real Medical script data — an honest finding

The task asked for 3-4 real examples from the sidecar. The slice's
`1-Medical.script-actions.json` (`bySourceKey`) has **134 `ActionSetProperty` uses, 0
`ActionGetProperty`, 0 `ActionPropertyTest`** — so in Medical specifically, this phase's payoff
is entirely `ActionSetProperty`. Property-name frequency across those 134:

| Property | Count | Example `Object` label |
|---|---|---|
| `enabled` | 74 | `ReopenGate`, `SwapSteinmanPatientBodyViewTrig` |
| `Disabled` | 36 | — |
| `bShowHudElements` | 10 | — |
| `bTelekinesisDisabled` | 2 | — |
| `HasBeenSavedOrPacified` | 2 | — |
| `LifeSpan`, `bCanBeUsed`, `MinimumDistance`, `bEnabled`, `OpenAnimationRate`, `Tag`, `ActorSpecificTextureWeight`, `bCanBeHacked` | 1 each | — |

**The mechanism built here is real and generic — but 110 of 134 (82%) target a property named
`enabled`/`Disabled`/`bEnabled` on whatever class the labeled actor is, and none of our current
`ShockTriggerRelayComponent`/`AShockDoor`/etc. classes expose a literal `FProperty` by that
exact name** (`FindPropertyByName` is an exact match, case-folded only — `"enabled"` will not
resolve to `bDisabled` or any differently-named field). So today, most of Medical's 134
`ActionSetProperty` calls will now run cleanly (no crash, a clean `BIOSHOCK_SETPROP ... ok=0`
log line) rather than silently doing nothing — that is real, verifiable progress over the
previous "always returns false with no trace" stub — but they will not yet *change gameplay
state* until a follow-up pass adds a matching literal property (or an aliased one) to the
specific target classes each label resolves to. **That per-class exposure pass is scoped
separately, deliberately not folded into this task** — it requires cross-referencing each of
the ~15 distinct target labels against the level manifest to find out which actor class each
one actually is, which is real research, not "small but exact" plumbing. Tracked as a R2.1
follow-up, not claimed done here.

## Verify

`tools/ue5/verify_reflection_actions.py` (spawns one throwaway `StaticMeshActor`, no script
graph needed — same pattern as `verify_action_property_test.py`): plain actor-level float write
+ read-back, one dotted component write (`StaticMeshComponent.bVisible`), `PropertyTest` →
`ActionIf` branch selection, the CDO guard, a missing-property clean failure. 7/7 green. Did not
regress `run_action_property_test.py` (the pre-existing `Label`/`bHidden` suite) or
`run_script_runner.py`/`run_script_doors.py`/`run_script_movement.py`.

## Gotchas hit this session (adding to `docs/ENGINEERING_RULES.md`-style notes)

- A `UFUNCTION` with a non-void return AND a non-const reference out-param
  (`bool Get(FString& Out) const`) does not reliably unpack as a 2-tuple through the Python
  binding — read the underlying `UPROPERTY`s directly instead
  (`obj.get_editor_property("field_name")`).
- `unreal.get_default_object(cls)` is the correct call for a class default object in Python —
  `cls.get_default_object()` does not exist and instead nativizes the `Class` object itself into
  the next call, producing a `NativizeObject: Cannot nativize 'Class' as 'Object'` TypeError one
  level down the call stack (at the *consumer* of the bad value, not at the point that produced
  it — confusing to debug).
- `import_slice_scripts.py` (and the other `import_slice_*.py` modules) are not standalone
  `-run=pythonscript -script=` entrypoints — they `import import_scripts` with no `sys.path`
  setup of their own, relying on being driven through `setup_playable_slice.py`'s STEPS runner.
  Direct invocation fails `ModuleNotFoundError` even when the module itself is unchanged and
  correct; this is an invocation-harness fact, not a code bug (matches the existing "use the
  `run_*` driver" note in `docs/ENGINEERING_RULES.md`).
