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

**`TriggerOnlyByLabels` — despite its name, also not resolvable against `Label`.** Mostly
`"Player"` again, but 62 occurrences across the game carry what read at first like character names
(`Steinman`, `Cohen`, `FinalAmbushDude`, `BerserkDude1`...) and matched none of `Tag`, `Label` or
`Spawner.InitialLabel` on any actor in the same package.

**Resolved, 28 Aug 2026 — they are `AIArchetype` names.** `Cohen`, `Steinman` and the rest are
entries in `SpawningManager.ArchetypeNames` (313 game-wide), each shipping as an `AIArchetype`
export in the maps that use it. `docs/research/spawning.md` has the full decode; `AiArchetypeCatalog`
reads them. So `TriggerOnlyByLabels` filters on *what kind of AI* trips the trigger, keyed by
archetype name — exactly the "Cohen-type enemy" reading, now confirmed rather than `LIKELY`.

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

**`Attachments` decoded, 25 Aug 2026.** Whole-game: **17 actors, all complete** — 13
`MedicalDoor` in `2-Fisheries` (one element, socket `"Door"`, mesh `Gate01solidPreviewMesh`, zero
offset) plus four in Challenge Room maps (`BlastdoorDoor` peephole, a two-element `MedicalDoors`
on `"LeftDoor"`, `GathererDoorSingle` on `"BigDoor"` with location offset Z=128). Same
`ReadStructArrayElements` shape as reactions. Each element: `StaticMesh`, `AttachSocket`,
`AttachLocationOffset`/`AttachRotationOffset`, `InteractWithPhysicalObjects`.
`DoorAttachmentData`; `DoorActorSchemaTests.FisheriesDoorsDecodeTheirSocketAttachments`.

**`ScriptedSequence` decoded, 25 Aug 2026.** Whole-game: **109 actors, 0 doors, 0 `DoorSwitch`s**.
It is an `Array` of structs (`ScriptedAnimations`, `LoopCount`, `RunNext`, `TotalChance`);
`ScriptedAnimations` is a nested struct array of `Chance` (int) + `Animation` (FName on the mesh,
not an object reference). `LoopCount` is the tagged `Min`/`Max` `Range` already used elsewhere.
`RunNext` is carried raw (`PLAUSIBLE` a next-entry index). Gated on field presence.
`ScriptedSequenceActorData`; `ScriptedSequenceActorSchemaTests`. Sample: `Wel_BHDoorBuckle0` in
`1-Medical` plays `BHBuckle_Bent` with `LoopCount` 3/3.

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

- **`ScriptedSequence` decoded 25 Aug 2026** — 109 actors, none of them doors; nested
  `ScriptedAnimations` is `Chance`+`Animation` (FName). See §5. `RunNext` meaning remains
  `PLAUSIBLE` only.
- ~~`TriggerOnlyByLabels`' real reference mechanism remains unidentified~~ — **resolved 28 Aug
  2026, see §4.** `AIArchetype` names via `SpawningManager.ArchetypeNames`.
- **A `ClassDefaults` earliest-vs-longest false positive was fixed 25 Aug 2026** — see §6. Prefer
  the longest clean walk to EOF; do not reopen as an Object-size bug.
- **Where `FXClass.DecoyHumanTarget` (and `ShockAIClasses.SpawnedDecoyHumanAI`) ship as class
  bytes remains `UNKNOWN`** — the Str path on `DecoyHumanAbility` is decoded; the named classes
  are not local exports of `ShockGame.U`. See §6's last paragraph.
- **`KeyPos`/`KeyRot` remain `UNKNOWN`** — see §3. Deliberately deferred pending a render check.

## 8. Script-action sidecar census — 30 Aug 2026

`CONFIRMED_BYTES`. `bioshock-tool export-script-actions` was run against every one of the 21
shipped, non-localised maps. Every JSON sidecar was written under `%TEMP%`; none is a repository
artifact. Counts below come directly from those format-version-2 sidecars. `refs` is the exporter’s
top-level `actions` count, `classes` is the number of distinct classes among all serialized
`bySourceKey` nodes (including nested nodes), and the five body columns count child references in
`trueActions` / `elseActions` / `loopActions` / `forActions` / `testsOr` respectively.

“Unmapped” applies the current `tools/ue5/import_scripts.py` class-name rule: `Action*` maps to
`ShockAction*`, plus the six explicit non-1:1 overrides. It is a measurement of the current UE5
import name mapping, not a claim that a mapped action’s gameplay behaviour is implemented.

| Map | Scripts | Refs | Classes | True | Else | Loop | For | Tests | `nested_unmapped` | `unmapped_classes` (sidecar nodes) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `0-Lighthouse` | 54 | 339 | 40 | 0 | 0 | 0 | 0 | 0 | 0 | — |
| `1-Medical` | 299 | 1,463 | 115 | 331 | 37 | 10 | 3 | 114 | 0 | — |
| `1-Welcome` | 319 | 2,195 | 97 | 306 | 21 | 24 | 0 | 89 | 0 | `TrainingCondition` 1 |
| `2-Fisheries` | 417 | 2,210 | 110 | 380 | 44 | 38 | 0 | 155 | 0 | — |
| `2-SubBay` | 74 | 510 | 67 | 39 | 10 | 5 | 0 | 20 | 0 | — |
| `3-Arcadia` | 366 | 2,150 | 106 | 619 | 85 | 47 | 0 | 274 | 0 | — |
| `3-Market` | 140 | 597 | 86 | 331 | 58 | 5 | 8 | 142 | 0 | — |
| `4-Recreation` | 438 | 3,072 | 117 | 2,024 | 150 | 18 | 0 | 612 | 15 | `OrStatement` 15 |
| `5-Hephaestus` | 190 | 760 | 96 | 478 | 60 | 7 | 0 | 165 | 0 | — |
| `5-Ryan` | 95 | 577 | 72 | 90 | 21 | 72 | 0 | 28 | 0 | — |
| `6-Resi` | 192 | 929 | 95 | 604 | 128 | 6 | 42 | 304 | 2 | `OrStatement` 2 |
| `6-Slums` | 117 | 553 | 79 | 546 | 118 | 5 | 12 | 264 | 2 | `OrStatement` 2 |
| `7-BossFight` | 71 | 379 | 64 | 77 | 11 | 25 | 0 | 21 | 0 | `HideNeedleElement` 2; `ShowNeedleElement` 2 |
| `7-Gauntlet` | 139 | 854 | 81 | 444 | 67 | 31 | 0 | 195 | 2 | `OrStatement` 2 |
| `7-Science` | 189 | 894 | 93 | 549 | 277 | 10 | 0 | 188 | 0 | — |
| `Autoplay` | 299 | 1,460 | 115 | 331 | 37 | 10 | 3 | 114 | 0 | — |
| `ChallengeRoomCombat` | 304 | 1,831 | 71 | 248 | 26 | 66 | 0 | 112 | 0 | — |
| `ChallengeRoomDecoy` | 90 | 378 | 61 | 42 | 26 | 20 | 0 | 26 | 0 | — |
| `ChallengeRoomElectric` | 139 | 601 | 80 | 278 | 78 | 6 | 0 | 78 | 2 | `OrStatement` 2 |
| `Entry` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — |
| `museum` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — |
| **Game** | **3,932** | **21,752** | **201** | **7,717** | **1,254** | **405** | **68** | **2,901** | **23** | **`OrStatement` 23; `HideNeedleElement` 2; `ShowNeedleElement` 2; `TrainingCondition` 1** |

All 21 exports reported `skipped = 0`. The 3,932 scripts and 21,752 top-level references exactly
match `ActionUsageCensusTests`; the sidecar exporter therefore retains **100% of the census’s
top-level action references**. Its 34,097 unique serialized nodes include the nested graph and 201
distinct classes, versus the top-level census’s 186 classes. The census head also agrees exactly:
`ActionWait` 2,209, `ActionSetProperty` 1,902, `ActionIf` 1,891, `ActionPlayEffect` 1,806, and
`ActionNonBlockingExecuteScript` 1,106 — 8,914 / 21,752 references (**40.98%**). This establishes
serialization coverage only; it does not raise the separate in-world execution percentage.

### Stop-condition finding: four shipped class names have no current importer mapping

`CONFIRMED_BYTES`. Ranked by serialized-node frequency, the current name mapper misses
`OrStatement` **23**, `HideNeedleElement` **2**, `ShowNeedleElement` **2**, and
`TrainingCondition` **1**. The latter three already have concrete UE5 runtime classes named
`UShockActionHideNeedleElement`, `UShockActionShowNeedleElement`, and
`UShockActionTrainingCondition`; the importer simply lacks their non-`Action` prefix overrides.
`OrStatement` is a `testsOr` boolean child alongside the explicitly mapped `AndStatement`,
`NotStatement`, `TruthStatement`, and `BooleanStatement`, but it has neither an override nor a
concrete `UShockOrStatement` class. Expected: retain/create the typed boolean-test node. Actual:
all 23 are serialized in the sidecars but fall through `shock_action_class_name`; import records
them as `nested_unmapped` and omits them from the `ActionIf` test body.

The 23 affected `OrStatement` source keys are:

- `4-Recreation` (15): `OrStatement_OrStatement1_24273`,
  `OrStatement_OrStatement2_31089`, `OrStatement_OrStatement3_31099`,
  `OrStatement_OrStatement29_33493`, `OrStatement_OrStatement189_28335`,
  `OrStatement_OrStatement204_20797`, `OrStatement_OrStatement240_35548`,
  `OrStatement_OrStatement261_28409`, `OrStatement_OrStatement267_37382`,
  `OrStatement_OrStatement276_41553`, `OrStatement_OrStatement321_28338`,
  `OrStatement_OrStatement372_29969`, `OrStatement_OrStatement393_29968`,
  `OrStatement_OrStatement401_44279`, `OrStatement_OrStatement606_45745`.
- `6-Resi` (2): `OrStatement_OrStatement2_32866`, `OrStatement_OrStatement3_32007`.
- `6-Slums` (2): `OrStatement_OrStatement7_33659`, `OrStatement_OrStatement39_29735`.
- `7-Gauntlet` (2): `OrStatement_OrStatement76_32409`,
  `OrStatement_OrStatement77_33255`.
- `ChallengeRoomElectric` (2): `OrStatement_OrStatement4_29985`,
  `OrStatement_OrStatement5_30045`.

The other exact unmapped source keys are
`TrainingCondition_TrainingCondition560_35453` (`1-Welcome`),
`HideNeedleElement_HideNeedleElement0_15307`,
`HideNeedleElement_HideNeedleElement8_7593`,
`ShowNeedleElement_ShowNeedleElement10_7569`, and
`ShowNeedleElement_ShowNeedleElement13_16838` (all `7-BossFight`). This is an importer mapping
defect, not an exporter traversal defect: every named node and every referenced nested source key
is present in its sidecar. Per the measurement-lane stop rule, no code was changed and the Phase
2.3 plan line was not marked complete.

**Resolved 30 Aug 2026 (`<a14>`).** `import_scripts.py` gained the three missing prefix
overrides (`HideNeedleElement` / `ShowNeedleElement` / `TrainingCondition` → their existing
`UShockАction*` classes). `OrStatement` got a new `UShockOrStatement` runtime class — an exact
`&&`→`||` mirror of `UShockAndStatement` (`UShockActionBool` base, `bLhs`/`bRhs`, `EvaluateBool()`
returns `bLhs || bRhs`); `ActionIf` already dispatches `EvaluateBool()` polymorphically on the
test node, so no runner change was needed. `ShockSchemaLibrary` applies its `lhs`/`rhs` defaults
alongside `NotStatement`'s. BioShockRuntime compiles clean. **Not re-verified by re-importing the
6 affected maps in a live editor** — the worker's Cursor-API connection dropped during that step;
the per-map `nested_unmapped` re-run is still owed.
