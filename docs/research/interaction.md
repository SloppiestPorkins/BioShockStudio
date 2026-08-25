# Movers, doors, and trigger wiring

Gate 4 item 4 asks for "interaction metadata (movers, doors, triggers, plasmid/weapon effects) once
the source object graph backing them is known." This note covers `Mover`/`ScriptableMover` (what
triggers them, their start pose), the game's ~50 door classes plus `DoorSwitch` (portal, lock,
animation and interaction-verb state), triggers' own trigger-wiring field, and the weapon/plasmid
effect shapes in §6.

**Status.** Movers' and doors' state fields, and `DoorSwitch`'s reaction arrays, are all
`CONFIRMED_BYTES`, and a mover's `TriggeredBy` is resolved against `Label` in code (§2). Triggers'
own `TriggeredBy` turned out to be a class filter, not an object reference, and is closed rather
than open (§4). A mover's keyframe motion path (`KeyPos`/`KeyRot`) is deliberately not decoded —
see §3. Weapon classes' `OnFiredEffects`/`TracerEffects`, `EmitterAmmo`'s flat `EmitterClass`/
`HighPressureEmitterClass`, plasmid ability Object/Class properties via `ResolveEffectProperty`, and
`DecoyHumanAbility.TargetIndicatorClassString` (Str path via `ResolveEffectClassString`) are all
`CONFIRMED_BYTES` — see §6. Where the named `FXClass.DecoyHumanTarget` class bytes live is
`UNKNOWN` (not a local `ShockGame.U` export).

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

## 4. Triggers' own `TriggeredBy` — closed, and not a name at all

Checked at whole-game scale, 24 Aug 2026, since the single `1-Medical` instance found earlier
already looked different from movers': across every package, `RegionActorData.TriggeredBy` (the
same property name, on `TriggerVolume`/`TriggerRadius`/`ZoneInfo`) has exactly **one distinct
value across all 25 occurrences it has: the literal string `"Player"`.** It is a class filter, not
an object reference — there is nothing to resolve, and the mover mechanism (§2) doesn't apply here
at all. Confirmed rather than assumed: 25/25, not "mostly".

**`TriggerOnlyByLabels` — despite its name, also not resolvable against `Label`.** It's a separate
already-decoded array field, mostly `"Player"` again but also carrying what read at first like
character names: `Steinman`, `Cohen`, `FinalAmbushDude`, `BerserkDude1`, and 21 others across the
game. All 62 non-`"Player"` occurrences were checked against every already-decoded name-shaped field
on every actor in the same package — `Tag`, `Label`, and `Spawner.InitialLabel` — and **none of the
three resolves more than 1 of 62.** `LIKELY` these are AI-archetype or character-identity filters
("only a Cohen-type enemy trips this"), resolved through a system this project hasn't decoded
rather than a placed-actor name lookup. Left open rather than guessed at further — this is a
different, unopened investigation, not a variant of §2's mechanism.

## 5. Doors — portal, lock and animation state

The game ships roughly 50 door-named classes (`MedicalDoors_Solid`, `BulkheadDoors`,
`AccordianGateDoor`, one-off transition doors like `ToArcadiaDoor`, ...) with no naming convention
consistent enough to enumerate. `DoorActorData` is gated on field presence instead: any actor
carrying `DoorPortal`, `bLocked`, `bInitiallyOpen`, `OpenAnimationRate`, `CloseAnimationRate`,
`DelayBeforeOpening` or `StayOpenDuration` gets a record. Verified whole-game rather than assumed —
every class that carries any of these fields has `"Door"` in its name, and no class outside that
family carries them, so the gate can't misfire onto or miss a real door.

Measured across the whole game, 24 Aug 2026 (`CONFIRMED_BYTES`, 18 packages, 353 door actors, 0
incomplete):

| Field | Actors | Meaning |
|---|---|---|
| `DoorPortal` | 260 | The `Brush` this door occludes/reveals when it opens |
| `bLocked` | 153 | Whether the door starts locked |
| `OpenAnimationRate` | 36 | |
| `DelayBeforeOpening` | 24 | |
| `bInitiallyOpen` | 18 | |
| `CloseAnimationRate` | 13 | |
| `StayOpenDuration` | 4 | |

`DoorKeypadControl` (10 shipped instances) is a real edge case the gate has to get right: its name
contains "Door" but it's a singleton interaction record, already decoded separately
(`InteractionActorData`), and correctly carries none of the seven fields above — confirmed by
reading its full property list, not assumed from the class name. `DoorActorSchemaTests` pins that it
gets no `DoorActorData`.

Like movers, almost every door also carries a mesh and is classified `GeometryInScene` before
`DoorPending` gets a chance — the same geometry-precedence pattern `EffectPending`/`MoverPending`
already document. The typed record is populated regardless of which bucket reports it.

**A bookkeeping fix landed alongside this**: `PathList`/`PathCollisionRadius`/
`AutoGeneratedFlyingPathNodes`/`bIsAutoGenerated` were already decoded generically by
`LevelAnalyzer.Navigation` for any actor that carries them (doors included), but weren't in the
`Interpreted` property-name set, so doors were showing these as "uninterpreted" in coverage reports
when they were already typed. Added to `Interpreted`; no behaviour changed, only the bookkeeping.

**`DoorSwitch`'s interaction-verb fields, decoded separately — and a real gating mistake caught
before it shipped.** `DamageResistanceSetName`, `UseVerbText` and `OverlayMaterial` were first
implemented with the same field-presence gate as `DoorActorData`, on the assumption that a
door-scoped census (which had only looked at classes with `"Door"` in the name) meant these fields
were door-specific too. A whole-game check told a different story: **all three are generic
interaction/combat properties** — `OverlayMaterial` alone is carried by 16 classes including
`BandagesPickup`, `ArmorPiercingBulletPickup`, `Cabinet`, `Desk` and a generic `Switch` class, none
of them doors. A field-presence gate would have silently attached a `DoorSwitchActorData` to 98
actors in `1-Medical` alone, 94 of them not door switches at all. Fixed before landing: `DoorSwitch`
is gated on the exact class name instead. **37 `DoorSwitch` actors across 8 packages, 0 incomplete**
— `DamageResistanceSetName` 11, `UseVerbText` 9, `OverlayMaterial` 14. `UseVerbText` is genuinely
useful: it's the on-screen interaction prompt (`"Look"`, `"TURN LATCH"`), and empty string is a real
shipped value on most switches, not an absent one.

**`DamagedReactions`/`UsedReactions` decoded, 25 Aug 2026 — turned out to be the same
`ReadStructArrayElements` shape `OnFiredEffects`/`TracerEffects` already use (§6), not the
`KeyPos`/`KeyRot`-style `FixedArray` risk this note originally worried about.** Both are plain
dynamic `Array` properties whose elements are tagged property lists — found by adding a
struct-array-unpacking mode to the `properties` CLI command itself (now a permanent reconnaissance
feature, not a one-off), which showed the real field shape directly rather than guessing from raw
hex. Every element carries the same 17 fields, a generic engine reaction-framework record, not
door-specific: `Reaction` (the handler class that actually fires — `ReactionNotifyScriptingSystem`,
`ReactionTriggerEffectEvent`, ... — resolved the identical way any other class reference in this
project is), `OnceOnly`, `SkipSubsequentReactions`, `Bool1`–`Bool4`, `Done`, `Name1`/`Name2`,
`Float1`/`Float2`, `Int1`/`Int2`, `OtherActor`, `DamageType`, `Mode`, and two nested
`StaticMeshes`/`Materials` arrays (empty in every observed sample, presence recorded, contents not
decoded). `DoorSwitchReactionData` in `LevelModel.cs`; `LevelAnalyzer.ReadReactions`;
`DoorActorSchemaTests.MedicalDoorSwitchesDecodeTheirInteractionVerbFields`, `CONFIRMED_BYTES` against
`DoorSwitch3` (1 `DamagedReactions`, 2 `UsedReactions`).

**The generic `Bool1`–`Bool4`/`Name1`/`Name2`/`Float1`/`Float2`/`Int1`/`Int2` slots' meaning is
UNKNOWN** — it depends on which `Reaction` class is referenced, and is carried raw rather than
guessed, the same convention `UpgradeType`/`EmitterAction` already use in §6.

**A real, separate display bug caught along the way.** The `properties` CLI command's own `Bool`
case had always printed the literal string `"true"` for every boolean property, regardless of its
actual value — not a decode bug (`UnrealProperty.BoolValue` itself was always read correctly), a
display bug in this one reconnaissance command. It produced a specific wrong test assertion here
(`OnceOnly` looked `true` in the tool's own output; the real, decoded value is `false`) before the
test run itself caught the contradiction. Fixed to print `property.BoolValue`/`field.BoolValue`
directly. Worth remembering when trusting any *older* raw `properties` output examined before this
fix landed.

**Still not decoded**: `Attachments`, `ScriptedSequence`. Worth a dedicated pass, not this one.

## 6. Weapon effects — `OnFiredEffects`/`TracerEffects`, decoded from class defaults

A weapon class (`MachineGun`, `Pistol`, `Shotgun`, ...) is never a placed level actor, so this is
the one interaction-metadata source in this note that isn't `ActorPayload` at all — it's a `Class`
export's own defaults, read via the existing `ClassDefaults` reader. Each weapon declares two
array-of-struct properties: `OnFiredEffects` (muzzle flash, shell eject) and `TracerEffects` (a
strict subset of the same shape). Each element names an `EmitterClass` — another class,
`Emitter`-derived, decoded with the *identical* `LevelAnalyzer.ReadEmitterTemplate` reader a placed
actor's own `Emitters` array already uses (they are the same shape of export either way) — and,
`OnFiredEffects` only, an optional `LightClass` (`DynamicLightEffect`-derived, a different shape:
`LightBrightness`/`LightColor`/`LightRadius`/`LifeSpan` read directly, not through the emitter
reader). `WeaponEffects.For(package, className)` in `src/BioShockStudio.Core/Assets/WeaponEffects.cs`;
CLI: `weapon-effects <package> <class>`. `WeaponEffectsTests`, `CONFIRMED_BYTES` against
`MachineGun` (4 `OnFiredEffects`, 3 `TracerEffects`), `Pistol` (1), `Shotgun` (12) — every count
matches the independently-derived UELib decompile of the same classes exactly.

**A real bug caught before landing.** The first working draft only accepted `EmitterClass`/
`LightClass` fields typed `UnrealPropertyType.Class`, and every emitter/light silently resolved to
null — no exception, a clean build, wrong answer. `Class'...'` is only how the UELib decompiler
*renders* the reference; the wire property tag is `UnrealPropertyType.Object`, the same as any other
object reference, confirmed by reading the actual field rather than trusting the decompiled
UnrealScript syntax. `PropertyValues.AsReference`'s own doc comment already said "an `Object` *or*
`Class` property's reference" — the bug was narrowing that, not the shared helper being wrong.

**Not decoded: `UpgradeType`/`EmitterAction`'s meanings.** Both are small integers (0–4 observed),
carried raw. `UpgradeType` plausibly correlates with the weapon upgrade tiers `WeaponUpgrades.cs`
already resolves by mesh name, and `EmitterAction` plausibly distinguishes "spawn" (0, the common
case) from "shell eject" (1, seen once on `MachineGun`'s fourth `OnFiredEffects` entry) — both
`PLAUSIBLE`, neither cross-referenced against independent evidence yet.

**The `EmitterClass`/`HighPressureEmitterClass` flat shape on `EmitterAmmo`, decoded too, 25 Aug
2026.** `ChemicalThrower_LiquidNitrogen` and its siblings (`_IonicGel`, `_Kerosene`) declare
`EmitterClass`/`HighPressureEmitterClass` directly on the ammo class's own defaults, not inside an
`OnFiredEffects`-shaped array — resolved via the identical `ResolveEmitter` helper `OnFiredEffects`
elements already use, exposed as `WeaponEffectsData.EmitterClass`/`.HighPressureEmitterClass`.
`CONFIRMED_BYTES`: `ChemicalThrower_LiquidNitrogen` → `LiquidNitrogen_Player`/`LiquidNitrogenUp_Player`,
`_IonicGel` → `IonGel`/`IonGelUp`, matching the UELib decompile exactly. A weapon that declares the
array shape instead (`MachineGun`) correctly reports neither flat property —
`WeaponEffectsTests.AnEmitterAmmoClassResolvesItsFlatEmitterClassPairInsteadOfTheArrayShape`.

**The same mechanism, generalized for an arbitrary property name, 25 Aug 2026 —
`WeaponEffects.ResolveEffectProperty(package, className, propertyName)`.** Three of the plasmid
ability classes resolve cleanly, `CONFIRMED_BYTES`, matching the UELib decompile exactly:
`SecurityBeaconAbility.ProjectileClass` → `BeaconProjectile`, `SpringBoardTrapAbility.
TargetIndicatorClass` → `SpringBoard_Cursor`, `TrapBoltProjectile.BeamEffectClass` → `TrapBoltBeam`.

**`ClassDefaults` mid-stream gap — diagnosed and fixed, 25 Aug 2026.** Earlier reading: the true
start seemed unable to walk cleanly, and a later `FriendlyName` start won. Actual cause: **several
offsets produce a clean walk to EOF**, and the reader returned the *earliest*. On
`BerserkRageAbility` the earliest is a 10-property false positive starting at a numbered `Text…`
name; the true list is 14 properties from offset 164 starting at `ProjectileClass` (includes the six
previously "missing" leading defaults). On `ShockPlayer` the earliest is a bogus `GetNumberOfItems`
Float; the longest clean walk (119 properties from `BasePlasmidSlots`) includes
`SanctuaryModelClass`. Fix: prefer the longest clean walk. Census: 17 of 654 `ShockGame.U` classes
differ; longest is strictly longer on all 17. Not an `Object`/`Class` size bug — that hypothesis is
refuted. `WeaponEffectsTests` pins `BerserkRageAbility` → `EnrageProjectile` and
`ShockPlayer.SanctuaryModelClass` present / `GetNumberOfItems` absent.

**`DecoyHumanAbility.TargetIndicatorClassString` decoded, 25 Aug 2026 — the third plasmid-effect
shape.** Plain `Str` default naming a class by Unreal path (`"FXClass.DecoyHumanTarget"`), not an
Object/Class reference. `WeaponEffects.ResolveEffectClassString(package, className, propertyName)`
reads it via `ClassDefaults` + `PropertyValues.AsString`, and sets `Resolved` only when a local
`Class` export's `GetFullPath` matches (in-package only, same convention as
`ResolveEffectProperty`). `CONFIRMED_BYTES`: the string is exactly `"FXClass.DecoyHumanTarget"`.
The named class is **not** a `Class` export in `ShockGame.U` (absent from the name table and from
`FXClass`'s 24 local children — contrast `FXClass.SpringBoard_Cursor`, which does ship and is what
`SpringBoardTrapAbility.TargetIndicatorClass` references as an Object). `Resolved` is therefore
null: the string decoded correctly; where the `DecoyHumanTarget` class bytes live is `UNKNOWN`.
The same Str-path shape also appears as `DecoyHumanAbility.DecoyHumanClassString`
(`"ShockAIClasses.SpawnedDecoyHumanAI"`) — same API, same local-resolution outcome.
`WeaponEffectsTests.DecoyHumanAbilityTargetIndicatorClassStringDecodesToTheClassPath`.

## 7. What this note does not claim

- **`DoorSwitch`'s reaction arrays remain undecoded** — see §5's "Still not decoded" paragraph.
  `DamagedReactions`/`UsedReactions` are complex nested arrays, not simple scalars.
- **`TriggerOnlyByLabels`' real reference mechanism remains unidentified** — see §4. Not `Tag`,
  `Label`, or `Spawner.InitialLabel`; genuinely open, not merely unchecked.
- **A `ClassDefaults` earliest-vs-longest false positive was fixed 25 Aug 2026** — see §6. Prefer
  the longest clean walk to EOF; do not reopen as an Object-size bug.
- **Where `FXClass.DecoyHumanTarget` (and `ShockAIClasses.SpawnedDecoyHumanAI`) ship as class
  bytes remains `UNKNOWN`** — the Str path on `DecoyHumanAbility` is decoded; the named classes
  are not local exports of `ShockGame.U`. See §6's last paragraph.
- **`KeyPos`/`KeyRot` remain `UNKNOWN`** — see §3. Deliberately deferred pending a render check.
- **`Attachments` / `ScriptedSequence` on doors** — still open; dedicated pass, not this one.
