# Script VM parameter resolution (`resolveInfoList`)

Status: **VERIFIED** for the serialized `ParameterResolveInfo` shape and Medical sample below;
**IMPLEMENTED and HEADLESS-VERIFIED** for the UE5 runtime path (see Verify below — codex drafted
this through the C++/Python layers and ran dry on quota before launching the editor itself;
Claude built + ran it, fixed the reconciliation with the concurrently-landed R2.1 reflection
actions, and confirmed green).

## Source model

`tmp/uc_scripting/Action.uc` declares the native atomic struct exactly as:

```text
Action Action
name   Variable
name   PropertyName
pointer Property       // transient native cache; not serialized
```

`Action.execute()` calls native `resolveParameters()` when the array is non-empty. Producer
actions return a `Variable` object and every concrete UE2 variable type exposes a property named
`Value`. `ActionCalcDistance` and `ActionRandomNumber` return `VariableFloat`; `ActionGetProperty`
chooses a variable class from the reflected property text; `ActionVariableAdd` and its arithmetic
siblings clone the left variable and return the calculated temporary value.

The serialized record therefore has two mutually exclusive source forms:

| Destination | Source | Meaning |
|---|---|---|
| `PropertyName` | non-null `Action` | copy the source action return variable's `Value` property |
| `PropertyName` | non-`None` `Variable` | copy that script-scope variable's `Value` property |

`sourcePropertyName` in the UE5 sidecar is `Value`. It is explicit in the interchange format and
runtime structure even though UE2's serialized struct does not store a separate source-property
field. This preserves the actual `Variable.Value` operation and leaves the runtime able to read a
different named return property if later evidence establishes one.

## Shipped-byte evidence

**CONFIRMED_BYTES — `1-Medical`, export 24453, `BooleanStatement90`.** Its
`resolveInfoList` is an exact two-element tagged-struct array:

```text
Offset in property value: 0x00
Bytes:
02
32 00000000 55 03 47FE02
33 00000000 56 05 00000000
34 00000000 56 06 5203 00000000
0000000000
32 00000000 05 00
33 00000000 56 06 7F14 00000000
34 00000000 56 06 5603 00000000
0000000000
```

The map name table identifies tag-name indices `0x32`, `0x33`, and `0x34` as `Action`,
`Variable`, and `PropertyName`. The first record's compact object reference `47 FE 02` resolves to
export 24454, `ActionGetLevelLabel54`, whose outer is `BooleanStatement90`; its `Variable` is
`None`. The second record has a null `Action` and a non-`None` variable name. This independently
exhibits both source forms in one shipped consumer. It also proves resolver producer actions are
not necessarily members of `Script.Actions` or an `ActionIf` child array: an expression action may
be outered directly to its consumer.

## Sidecar v3 and import

`export-script-actions` now writes `formatVersion: 3`. Each `bySourceKey` action bag may contain:

```json
{
  "resolveInfo": [
    {
      "propertyName": "lhs",
      "sourceKind": "actionProp",
      "variableName": null,
      "sourceActionIndex": 24454,
      "sourcePropertyName": "Value"
    },
    {
      "propertyName": "rhs",
      "sourceKind": "variable",
      "variableName": "Global_Example",
      "sourceActionIndex": null,
      "sourcePropertyName": "Value"
    }
  ]
}
```

`sourceActionIndex` is the package's zero-based export index, the same identity already emitted as
each sidecar entry's `exportIndex`. The exporter enqueues action sources reached only through
`resolveInfoList`, so they receive their own `bySourceKey` entry and scalar configuration.

`import_scripts.py` builds an export-index-to-source-key map and one action-object cache per script.
It constructs resolver-only source actions with the same runner outer, reuses an object if the same
source is also present in a normal action array, then calls `add_variable_resolver` or
`add_action_property_resolver`. Readers remain compatible with v2 sidecars because absent
`resolveInfo` is an empty list.

## Runtime execution

`UShockVariableScope` now owns `UShockVariable` objects rather than bare strings while preserving
its original string getters/setter. `UShockAction` retains a transient return variable and exposes
`GetReturnValue()`.

Immediately before a queue action executes, `UShockScriptRunner` asks it to resolve parameters.
Variable sources read the named scope object. Action sources read the source action's last return;
when a resolver-only expression has not run, it is evaluated once on first use. The destination
`FProperty` is found by name and assigned with type-aware coercion for string, name, bool, and
numeric properties, falling back to UE's reflected text importer for other supported types. A
missing source/property leaves the literal imported value intact and logs an incomplete resolution
instead of fabricating a value. Latent waits resolve once on entry, not again on every blocked tick.
`ActionIf.testsOr` entries are resolved before evaluation because those expression objects do not
appear as queue entries.

Implemented return producers are `ActionCalcDistance`, `ActionRandomNumber`, `ActionGetProperty`,
`ActionGetMessageValue` (for the lightweight bus metadata currently retained), and the
`ActionVariableAdd`/`Subtract`/`Multiply`/`Divide` family.

### Worked `CalcDistance -> If` flow

1. `ActionCalcDistance(actorOne=A, actorTwo=B)` finds both labelled actors and returns a
   `UShockVariable(Value="300", VariableClassName="VariableFloat")`.
2. A nested `BooleanStatement(lhs <= 350)` carries an `actionProp` resolver for `lhs` pointing to
   the distance action's export index.
3. Before `ActionIf` evaluates `testsOr`, the runner copies the producer's `Value` text into the
   statement's `Lhs` `FString`.
4. The numeric comparison passes and the true action list is inserted into the run queue.

## R2.1 reflection interop

`ActionGetProperty` landed twice, concurrently: R2.1 (`x5`, Claude direct) built
`ShockScriptReflection` — a shared `ResolveTargetActor`/dotted-component-path/CDO-guarded
property reader used by `ActionSetProperty`/`ActionGetProperty`/`ActionPropertyTest` — while R1.1
(`x3`, codex) independently drafted a simpler single-component `ActionGetProperty` to prove the
return-value plumbing. Reconciled onto R2.1's version (dotted paths + guards are strictly more
capable) wired to R1.1's typed `UShockVariable` return carrier
(`SetReturnValueText(Text, UShockVariable::InferVariableClass(Text))` in place of R2.1's
original plain-string `ReturnValueText`/`bHasReturnValue` fields, which were retired in favour of
this richer design before either landed on `main`). `ActionPropertyTest` also now returns a
`VariableBool`, matching the decompiled `Scripting.U` return type.

`verify_reflection_actions.py` reads the return value via `action.get_return_value().get_value()`
(a `UShockVariable*`), not the retired plain properties.

## Verify

`verify_import_scripts.py` exercises the full flow: a script-scope variable feeds
`ActionRandomNumber.Minimum`, the roll feeds an `ActionVariableAssignOverwrite.Rhs`,
`ActionCalcDistance`'s result feeds a `BooleanStatement` that drives `ActionIf`'s branch. Built
entirely on real production classes (`ShockScript`/`ShockScriptRunner`/`ShockActionIf`), not a
synthetic double. 5/5 parameter-resolution checks green; did not regress
`run_script_runner.py`/`run_script_doors.py`/`run_script_movement.py` or
`run_action_property_test.py` (R2.1's baseline suite).

## Known boundary

**VERIFIED GAP:** the port's message bus retains only message class and source label, not arbitrary
typed `Message` UObject fields. `ActionGetMessageValue` can therefore return that retained metadata;
other message properties correctly fail until typed message objects are ported.
