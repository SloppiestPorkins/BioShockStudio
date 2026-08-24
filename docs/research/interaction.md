# Movers and trigger wiring

Gate 4 item 4 asks for "interaction metadata (movers, doors, triggers, plasmid/weapon effects) once
the source object graph backing them is known." This note is the first piece of that: `Mover` and
`ScriptableMover`, what triggers them, their start pose, and the census that scopes the rest of the
item.

**Status.** The trigger-wiring and start-pose fields are `CONFIRMED_BYTES`, and `TriggeredBy` is
resolved against `Label` in code (§2). The keyframe motion path itself (`KeyPos`/`KeyRot`) is
deliberately not decoded — see §3.

## 1. The shape

`Mover` and `ScriptableMover` are ordinary placed actors — no special header, same tagged-property
list every other actor uses. `LevelAnalyzer.Mover` resolves the typed subset, and `LevelCoverage`
classifies any actor carrying it as `MoverPending`. In practice almost every mover also carries a
`StaticMesh` and gets classified `GeometryInScene` first — the same geometry-precedence
`EffectPending` already documents for emitter-bearing actors. The typed record is populated either
way; only the reporting bucket differs.

Measured across the whole game on 24 Aug 2026 (`CONFIRMED_BYTES`, all 161 shipped `.bsm` packages;
`MoverActorSchemaTests` pins one map, and the full-game figures below are a census rather than a
pinned test):

| Figure | Value |
|---|---|
| `ScriptableMover` actors | **94**, across 15 packages |
| `Mover` actors | **15**, across the same 15 packages |
| Property walks that failed to complete | **0** of 109 |
| `TriggeredBy` present (`ScriptableMover` only) | 94 of 94 |
| `KeyPos` present | 86 of 109 |
| `KeyRot` present | 31 of 109 |

This is gated on the exact class name, not a substring match. `Int_FireMover` (`0-Lighthouse`, 1
actor) shares the word "Mover" but not the shape — no `BasePos`, `TriggeredBy`, or any other field
this note decodes — confirmed by reading its full property list rather than assumed from the name.
`MoverActorSchemaTests.AnUnrelatedMoverNamedClassIsNotGivenAnEmptyMoverRecord` pins that it gets a
null `Mover` record rather than an empty one.

## 2. `TriggeredBy` is the object graph the roadmap item asks for

The comma-separated string names the Script/Tag names that trigger this mover. Real examples, read
straight from `1-Medical`:

```
MeatLockerDoorScript, MeatLockerOn
SteinmanIntro,TurretControlSwitchScript
ElevatorDoorOpen, ElevatorDoorClose
none
```

It's kept as the raw string rather than split into a list, the same convention
`RegionActorData.TriggeredBy` already uses for `TriggerVolume`/`ZoneInfo` — neither this project nor
any reference source has confirmed the separator is always a plain comma (note the inconsistent
spacing above: `"X, Y"` in one sample, `"X,Y"` in another). Splitting now would be guessing a rule
not yet verified.

`"none"` is a real value, not an absent field (`withTriggeredBy` above counts it as present).
`LIKELY` a literal placeholder meaning "this mover never receives an external trigger" — some
movers with that value still carry `MoveTime`/keyframes, so they presumably animate on their own
cue (a state machine, a cinematic, a scripted `GotoState` call) rather than a level-editor
`Trigger`.

**The name resolves against `Label`, not `Tag`.** Every `ScriptableMover.TriggeredBy` was split on
commas — 103 names across all 15 packages that have movers, `"none"` excluded — and each name was
looked up against every other actor's already-decoded `Tag` and `Label` in the same package:

| Match | Count |
|---|---|
| Matched another actor's `Label` | **88 (85.4%)** |
| Matched another actor's `Tag` | **0** |
| Matched neither | 15 (14.6%) |

Zero matches against `Tag` rules out the obvious hypothesis — UE1/2's classic `Trigger`→`Tag`
convention — outright, rather than leaving it assumed. The actual mechanism is `Label`, BioShock's
own editor-assigned display name, not the engine's native tag field. That's a real, useful, and
non-obvious finding, exactly the kind this census exists to catch rather than guess at.

**Every one of the 88 resolved matches is a `Script` actor — no exceptions.** A mover's
`TriggeredBy` never names a door, a switch, or anything else directly; it always names a `Script`
by its `Label`. Movers are triggered exclusively through the level's script layer.

Resolution is also unambiguous across the whole game: `Label` is otherwise far from unique in this
game (auto-numbered names like `Light3` repeat up to 962 times in one package), but checked against
every actor in every package that has a mover, **all 88 resolved names match exactly one actor's
`Label`, never more than one.** Nothing here had to pick an arbitrary match among several — the
resolver still checks for that case and leaves an ambiguous name unresolved rather than guessing,
but it has never actually had to.

The 15 unresolved names read as UnrealScript state names rather than object references —
`LIKELY`, not confirmed. `MoveMe` (`1-Welcome`, on a mover labelled `Lift`) matches no actor's `Tag`
or `Label` in its package at all, and the pattern generalises: `MoveMe2`, `MoveMeFontaine`,
`MoveMeBathy`, `shadowmover`, `quarantineactive` all read as state or event names a script calls
directly — `GotoState('MoveMe')` on the mover itself, say, or a broadcast the mover's own state
machine listens for — rather than a level-editor object reference. `TurretControlSwitchScript`
(unresolved in both `1-Medical` and `Autoplay`) is the one repeat name and reads the same way. This
lines up with `InitialState` already being a state name in its own right (`TriggerToggle` in the
pinned example): movers plausibly run their own state machine, and only some of what triggers them
turns out to be a named level object.

**Wired into code, 24 Aug 2026 — `MoverActorData.ResolvedTriggers`.** This turned out to be a
research finding over already-decoded fields (`Label`/`TriggeredBy`), not a new byte format, so
implementing it didn't need any new byte-level reverse engineering. It does need a second analysis
pass, though: `LevelAnalyzer.ResolveMoverTriggers` runs once per package after every actor is built,
indexes every actor by `Label`, then updates each mover's `ResolvedTriggers` in place — the one
piece of "interaction metadata" in this project so far that needs the whole package's actors, not
just its own bytes, to resolve. Each `MoverTriggerTarget` carries the raw name, whether it resolved,
and (if so) the target's export index and class name. Pinned against real bytes by
`MoverActorSchemaTests`, including a game-wide regression that no resolved name is ever ambiguous.

## 3. What is typed today, and what is deliberately deferred

Typed: `InitialState`, `TriggeredBy`, `BasePos`, `BaseRot`, `MoveTime`, `StayOpenTime`,
`UseTriggered`, `TriggerOnceOnly`, and the two byte enums `MoverEncroachType`/`MoverGlideType` (raw
values only — meanings `UNKNOWN`, not in `Bioshock1REMSDK-WIP--main`).

Not typed: `KeyPos`/`KeyRot`, the actual keyframe motion path. These are UE1/UE2 static, fixed-size
array properties, serialised as one tagged property entry per element and distinguished only by
`ArrayIndex` — a different shape from a counted array like `Emitters` or a curve like `SizeScale`.
What's been observed so far:

- `KeyPos`/`KeyRot` indices seen start at **1**, never 0. `HYPOTHESIS`: consistent with classic
  Unreal `Mover` semantics, where key 0 is implicitly the actor's placed position/rotation
  (`BasePos`/`BaseRot`) and only the additional keys get serialised — but this project hasn't
  verified that against UE2's own `Mover.uc` source or a rendered comparison.
- `KeyPos` max index seen: 1 (71 movers), 2 (12), 3 (3) — up to 4 total keys including the implicit
  key 0.
- `KeyRot` max index seen: 1 (25 movers), 2 (3) — up to 3 total keys.
- A `NumKeys` byte property exists on 9 of 109 movers and hasn't been cross-checked against the
  observed index ranges above.

This is deferred rather than decoded now for a few reasons. Reading a fixed-array property by
collecting repeated same-name entries has no precedent anywhere in this codebase — every other
array so far has been either a counted reference array or a nested-struct curve with its own count
prefix. The implicit-key-0 hypothesis is unverified against any external source. And a wrong key
order or count would be exactly the "numeric validation passes on visibly wrong output" failure
mode this project has already hit more than once — a mover's motion path is precisely the kind of
thing that needs rendering, not just parsing, to confirm.

## 4. What this note does not claim

- **No door decode is included here**, despite the roadmap item naming it. Doors
  (`AccordianGateDoor`, `MedicalDoors_Solid`, ...) are skeletal-mesh actors with their own undecoded
  fields — `DoorPortal`, `bLocked`, `PathList`, `OpenAnimationRate`.
- **Triggers already have their configuration typed** (`RegionActorData`, Gate 3 item 3), including
  their own `TriggeredBy`, but that hasn't been resolved against `Label` the way movers' now is.
  One instance was seen in `1-Medical` (`"Player"`), and it reads as a class-filter value rather
  than a name — so triggers may use this property differently than movers do. Not checked at
  whole-game scale.
- **Plasmid/weapon effects weren't investigated in this pass.** A first grep of `ShockGame.U`'s
  decompiled output shows classes like `LiquidNitrogen_Player` and `MachineGun_MuzzleFX` that read
  as script-side class defaults — a different decode mechanism from everything else in this note,
  since `ActorPayload` reads *placed* actors and these are unplaced class templates.
- **`KeyPos`/`KeyRot` remain `UNKNOWN`** — see §3.
