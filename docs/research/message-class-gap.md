# The message-class gap — `scriptMessageClass` gating LANDED; dispatch sources and `messageFilter` remain

> **Update, 25 Sept — receiver-side gating is done.** The earlier version of this doc scoped the
> fix as "real engineering" needing new FCompactIndex resolution. It wasn't: the C# side already
> had `UnrealProperty.TryAsObjectReference` + `BioShockPackage.ResolveName` (used by
> `MaterialAnimator`/`SoundEventReader`/`CubemapReader`). What landed:
>
> - `LevelSceneExporter`: every `Object`-typed property now also carries `resolvedObjectName`
>   in `level.json`/`ue5-level.json` (generic, not Script-specific). On `1-Medical` all 226
>   `scriptMessageClass` values resolve (0 unresolved) to the real taxonomy: `MessageTriggerVolumeEnter`
>   89, `Message` 21, `MessagePawnDied` 21, `MessageRAReacted` 19, `MessageLevelStarted` 16,
>   `MessageReceivedInventory` 8, ... `messageFilter` resolves to the filter *instance* name
>   (`MessagePawnDied0`, `MessageReceivedInventory2`, ...), i.e. an export whose own properties
>   (`PawnLabel`, `Instigator`, ...) are the actual filter fields — not yet decoded.
> - `import_scripts.py` reads it (`script_message_class_from_actor`) and calls
>   `runner.set_script_message_class`.
> - `UShockScriptRunner::ScriptMessageClass` + `MatchesMessageClass`; `TryStartFromMessage` now
>   requires it. `NAME_None` (unresolved) and `"Message"` (UE2's base class) are wildcards.
> - `verify_script_trigger.py`: the guide's elevator case — two scripts on `TriggeredBy="Lift"`,
>   `MessageMoverOpened` vs `MessageMoverClosing` vs `Message` wildcard; only the right ones fire.
>
> **Behaviour change to know about:** scripts whose class we don't dispatch yet no longer start.
> The runtime only dispatches `MessageLevelStarted`, `MessageTriggerVolumeEnter` and `Message`.
> Previously a `TriggeredBy="all"` `MessagePawnDied` script wrongly fired at level entry (the
> level-entry dispatch hits every `all` script); that's gone. The cost: `MessageTriggerEnter`
> (TriggerRadius, 4 scripts) and `MessageTriggerVolumeExit`/`TriggerExit` (4) no longer fire via
> the volume-enter relay. Those scripts' real events need real dispatch sources (below).
>
> **Still open:** (1) real dispatch sources for `MessagePawnDied` (21), `MessageRAReacted` (19),
> `MessageReceivedInventory` (8), `MessageAIWeaponFired` (5), `MessagePawnTookDamage` (5),
> `MessageMoverOpened/Closing`, `MessagePlayerFinishedHacking` (3), etc.; (2) TriggerRadius/exit
> relay classes; (3) `messageFilter` field decoding + a message payload to compare against.
> The historical analysis below is kept for the reasoning.

---
# The message-class gap — `scriptMessageClass` and `messageFilter` are not implemented

Found during a full cross-reference of the runtime against the shipped BioShock UnrealEd guide
(`bio4554/Unofficial-BioShock-Editor`). This is the single largest correctness gap found in that
pass — bigger than the `enabled`/`Disabled` reflection gap fixed the same day — but it is **not**
fixed here: a correct fix needs new UE2 object-reference resolution in the C# exporter (real
engineering, not a quick patch), and a wrong-but-plausible fix risks silently breaking scripts
that work today. Scoped as a follow-up with the evidence below.

## What's missing

A UE2 `Script` actor has **two** independent gates on whether it starts from a message, per
`21-Scripting-Logic-and-Variables.md` / `23-Scripting-Examples.md`:

1. **`TriggeredBy`** — which source label(s) the script listens to. **Implemented** —
   `UShockScriptRunner::MatchesTriggeredBy` already parses the comma-separated list correctly.
2. **`scriptMessageClass`** — which message *class* from that source it listens to.
   **Not implemented at all.** `UShockScriptRunner::TryStartFromMessage(FName MessageClassName,
   const FString& SourceLabel)` takes a `MessageClassName` parameter and silently ignores it —
   only `TriggeredBy` gates whether a script starts.

Plus a third, per-script refinement:

3. **`messageFilter`** — an inner object with message-class-specific fields (`Instigator=Player`,
   `PawnLabel=Friend`, `PawnClass=SpawnedMeleeThug`, `ActualClass=LiquorItems`, `Reason=Touch`,
   ...) that further narrows which instance of a message class a script accepts. **Not
   implemented at all** — and our message bus doesn't carry the payload fields most filters need
   in the first place (`docs/research/script-vm.md` already documents this boundary: "message
   bus only retains class+source label").

## Why this matters — real numbers, not a hunch

Counted directly against `1-Medical`'s own level export
(`C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.level.json`, 300 `Script`
actors):

| Field | Scripts that declare it | Share |
|---|---|---|
| `TriggeredBy` | 222 | 74% |
| `scriptMessageClass` | 226 | 75% |
| `messageFilter` | 64 | 21% |
| `enabled` (non-default) | 16 | 5% |

Three-quarters of Medical's own scripts specify a message class. The guide's own worked example
(`23-Scripting-Examples.md` Example 10, the elevator) shows exactly the failure mode this
enables: `ElevatorDoorOpen` (`TriggeredBy="Lift"`, `scriptMessageClass=MessageMoverOpened`) and
`ElevatorDoorClose` (`TriggeredBy="Lift"`, `scriptMessageClass=MessageMoverClosing`) are two
different scripts listening to the *same* label for *different* message classes. Without class
filtering, if both `MessageMoverOpened` and `MessageMoverClosing` were ever dispatched under
label `Lift`, both scripts would fire on both — the ding-and-open script would also run when the
lift starts closing, and vice versa.

**This has not manifested as an observed bug yet** because the runtime currently dispatches
*everything* through one undifferentiated path with no real per-source-type class distinction —
today's callers pass essentially one generic class for nearly every dispatch (see below), so
there's no actual class collision under a shared label to expose the missing filter. The gap is
latent, not (yet) an active symptom — but any future work that gives movers, AI deaths, item
pickups, etc. their own real distinct dispatch classes will need this fixed first, or every
shared-label script will start over-firing exactly like the elevator example.

## What was fixed this session (safe, zero behavior change)

`TryStartFromMessage` doesn't check message class, so the *sent* class name has never actually
gated anything — meaning renaming it to the real UE2 name is risk-free today (verified: full
regression pass green) and is forward-compatible groundwork for the real fix. Every dispatch call
site previously sent the same invented class, `"MessageTrigger"`:

- `ShockScriptSubsystem::DispatchLevelEntryMessages` → now sends `MessageLevelStarted` (the real
  UE2 class for the "level start" pattern: `TriggeredBy="<map name>"`).
- `ShockTriggerRelayComponent::DispatchNow` (wraps an imported TriggerBox / UE2 TriggerVolume) →
  now sends `MessageTriggerVolumeEnter` (the real class for that pattern).
- `ShockActionSendTriggerMessage::DispatchVia` → now sends `Message`, UE2's base class ("accepts
  every message from the listed labels" — matches how movers and generic scripts are wired).

This is **sender-side semantic correctness only**. No receiver anywhere checks the class yet, so
this change altered no script's actual firing behavior — confirmed by a full regression pass
(`verify_script_trigger`, `verify_script_doors`, `verify_script_movement`,
`verify_reflection_actions`, `verify_action_batch_r22`, all green).

## What a real fix needs (not attempted here)

1. **Decode `scriptMessageClass` per script.** It's an `Object`-type property (a raw
   `FCompactIndex` package reference, 2 bytes in the observed data — `CD06`, `DB02`, ...), not a
   plain string like `TriggeredBy` (which is `Str`-typed and already decoded directly in Python
   from `valueHex`). Resolving it to a class name needs the C# exporter to walk the level
   package's Export/Import tables the way `ActorPayload.cs`/`BioShockPackage.cs` already do for
   other object references (`ReadCompactIndex` exists; the actor's own `ClassName` and
   `Mover.ResolvedTriggers[].TargetClassName` are existing examples of this kind of resolution,
   but nothing currently resolves an *arbitrary* property's object reference generically) —
   real engineering, need to get the FCompactIndex sign/export-vs-import convention exactly
   right against known-good decoded values, not a guess.
2. **Add `ScriptMessageClass` (FName) to `UShockScriptRunner`**, decoded and passed through
   `Configure` from `import_scripts.py`, mirroring how `TriggeredBy` already flows.
3. **Gate `TryStartFromMessage` on it**: accept when the script's `ScriptMessageClass` is empty/
   `None` (safe default for anything we fail to decode — must never silently break an
   already-working script), equals `"Message"` (the wildcard base class, guide-confirmed), or
   exactly matches the dispatched `MessageClassName`.
4. **Give the runtime's own dispatch call sites the real distinct classes** the guide's taxonomy
   needs as those systems get built: `MessagePawnDied`, `MessageReceivedInventory`,
   `MessageRAReacted`, `MessageMoverOpened`/`MessageMoverClosing`/`MessageMoverClosed`,
   `MessageDoorKeypadUsed`, `MessageTimerExpired`, `MessageSavegameRestored` — most of these
   aren't dispatched as distinct events anywhere in the runtime yet regardless of the filtering
   gap, which is its own, separate, larger scope (each needs the underlying gameplay event to
   exist and dispatch in the first place).
5. **`messageFilter`** is a second, separable layer on top of (1)-(3): decode the inner filter
   object's fields (`Instigator`, `PawnLabel`, `PawnClass`, `ActualClass`, `Reason`, ... — the
   exact field set is message-class-specific), and — the harder part — enrich
   `FShockActionContext`'s message payload to actually carry those fields so a filter has
   something to compare against (today it only retains class + source label). Lower priority
   than (1)-(4): 21% of scripts vs. 75%, and it depends on (1)-(4) existing first.

## Verify

No new verify script for the gap itself (nothing to verify yet — it's unfixed). The rename's
zero-behavior-change claim is covered by the existing suite:
`verify_script_trigger.py` (updated: asserts the real `"Message"` class landed, not the old
invented `"MessageTrigger"`), `verify_script_doors.py` (updated: the relay-fallback path asserts
`"MessageTriggerVolumeEnter"`), `verify_script_movement.py`, `verify_reflection_actions.py`,
`verify_action_batch_r22.py` — all green.
