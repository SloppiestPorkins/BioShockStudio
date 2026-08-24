# Particle emitters

What a placed effect actor's `Emitters` array points at, what those templates carry, and how much
of it is typed today. Gate 4 item 3 asks for "enough to build real UE5 Niagara placeholders, not a
static mesh standing in for an effect." This note is the census that has to come before that, not
the mapping itself.

**Status.** The container and the template property list are `CONFIRMED_BYTES`. The typed subset is
31 fields wide, widened 24 Aug 2026 from an initial 4. The byte-enum *meanings* are still `UNKNOWN`.
No Niagara mapping exists yet.

## 1. The shape

A placed actor may serialise an `Emitters` array of object references. `LevelAnalyzer.Emitters`
resolves each into an `EmitterTemplateData`, and `LevelCoverage` classifies any actor carrying the
property as `EffectPending`. The referenced export is the template itself — an ordinary
tagged-property object, read with the same `UnrealPropertyReader` walk everything else in this
project uses.

Measured across the whole game on 23 Aug 2026 (`CONFIRMED_BYTES`, all 161 shipped `.bsm` packages
opened, `EmitterTemplateCensusTests`):

| Figure | Value |
|---|---|
| Packages carrying emitter actors | **20** of 161 |
| Actors with an `Emitters` array | **1,859** |
| Template references | **3,211** |
| References that fail to resolve | **0** |
| References to another package (imports) | **0** |
| Templates whose property walk truncated | **0** |
| Distinct property names across all templates | **120** |

Two facts bound what a Niagara mapping can assume. First, every template is local to the map that
uses it — 0 of 3,211 references are imports, so an effect never crosses a package boundary the way
a material can. Whatever a level needs, that level ships. Second, every template walks cleanly — 0
of 3,211 truncate, so there's no unknown tail hiding behind a lost alignment. The 120 names in §4
are the whole vocabulary, not a readable prefix of it.

Of the 141 packages with no emitter actors, 140 are localised duplicates (their names carry a
language suffix). Exactly one is not: `Entry` — the same package that carries no `LightMaps_BSP`
group. That's measured, not inferred from the naming.

## 2. Which packages

| Package | Actors | With `Emitters` | Distinct templates |
|---|---|---|---|
| `0-Lighthouse` | 1,877 | 105 | 159 |
| `1-Medical` | 8,089 | 142 | 251 |
| `1-Welcome` | 6,635 | 108 | 148 |
| `2-Fisheries` | 10,302 | 169 | 262 |
| `2-SubBay` | 2,664 | 36 | 74 |
| `3-Arcadia` | 9,765 | 167 | 232 |
| `3-Market` | 5,789 | 67 | 123 |
| `4-Recreation` | 11,330 | 103 | 200 |
| `5-Hephaestus` | 7,563 | 183 | 359 |
| `5-Ryan` | 1,842 | 24 | 45 |
| `6-Resi` | 8,470 | 60 | 108 |
| `6-Slums` | 6,904 | 69 | 126 |
| `7-BossFight` | 1,384 | 21 | 53 |
| `7-Gauntlet` | 5,148 | 117 | 220 |
| `7-Science` | 9,757 | 117 | 187 |
| `Autoplay` | 8,077 | 148 | 266 |
| `ChallengeRoomCombat` | 7,634 | 139 | 220 |
| `ChallengeRoomDecoy` | 1,953 | 34 | 92 |
| `ChallengeRoomElectric` | 3,203 | 39 | 73 |
| `museum` | 528 | 11 | 13 |

## 3. The five emitter classes

| Class | Templates |
|---|---|
| `SpriteEmitter` | 3,084 |
| `MeshEmitter` | 57 |
| `BeamEmitter` | 50 |
| `MultipleRibbonEmitter` | 13 |
| `RibbonEmitter` | 7 |

`SpriteEmitter` accounts for 96.0% of the population, so a Niagara placeholder that handles sprites
and falls back honestly on the other four covers almost the whole game. "Almost" is doing real work
in that sentence, though: `MeshEmitter` is the one class whose visual is a mesh rather than a
texture — all 57 carry `StaticMesh`, and no other class does — so treating it as a sprite would be
exactly the "static mesh standing in for an effect" failure the roadmap item warns about, just
inverted.

## 4. What a template carries

Every property observed, with how many of the 3,211 templates serialise it and which classes do. An
absent property is the class default, not an undefined value — UE2 writes only what differs from
the class default, which is why these counts vary rather than all reading 3,211. That distinction
matters for the mapping: "not serialised" cannot be read as "off".

| Property | Templates | Type | Classes |
|---|---|---|---|
| `LastDeltaTime` | 3,211 | Float | SpriteEmitter:3084, MeshEmitter:57, BeamEmitter:50, MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `CheckpointTypePadding` | 3,201 | Int | SpriteEmitter:3074, MeshEmitter:57, BeamEmitter:50, MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `StartSizeRange` | 3,167 | Struct {RangeVector} | SpriteEmitter:3071, BeamEmitter:50, MeshEmitter:46 |
| `Material` | 3,074 | Object | SpriteEmitter:3004, BeamEmitter:50, MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `LifetimeRange` | 3,067 | Struct {Range} | SpriteEmitter:2940, MeshEmitter:57, BeamEmitter:50, MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `InitialParticlesPerSecond` | 3,054 | Float | SpriteEmitter:2952, BeamEmitter:50, MeshEmitter:39, MultipleRibbonEmitter:13 |
| `AutomaticInitialSpawning` | 3,038 | Bool | SpriteEmitter:2949, BeamEmitter:50, MeshEmitter:39 |
| `UseRegularSizeScale` | 3,010 | Bool | SpriteEmitter:2926, BeamEmitter:50, MeshEmitter:34 |
| `StartVelocityRange` | 2,966 | Struct {RangeVector} | SpriteEmitter:2895, MeshEmitter:56, MultipleRibbonEmitter:8, RibbonEmitter:7 |
| `SizeScale` | 2,923 | Array | SpriteEmitter:2873, BeamEmitter:50 |
| `ParticlesPerSecond` | 2,843 | Float | SpriteEmitter:2814, MeshEmitter:16, MultipleRibbonEmitter:8, BeamEmitter:5 |
| `MaxParticles` | 2,821 | Int | SpriteEmitter:2718, BeamEmitter:50, MeshEmitter:45, MultipleRibbonEmitter:8 |
| `ColorScale` | 2,790 | Array | SpriteEmitter:2725, BeamEmitter:50, MultipleRibbonEmitter:8, RibbonEmitter:7 |
| `SpinParticles` | 2,764 | Bool | SpriteEmitter:2707, MeshEmitter:57 |
| `StartLocationRange` | 2,718 | Struct {RangeVector} | SpriteEmitter:2625, BeamEmitter:50, MeshEmitter:43 |
| `UseSizeScale` | 2,655 | Bool | SpriteEmitter:2605, BeamEmitter:50 |
| `StartSpinRange` | 2,605 | Struct {RangeVector} | SpriteEmitter:2548, MeshEmitter:57 |
| `RespawnDeadParticles` | 2,580 | Bool | SpriteEmitter:2477, BeamEmitter:50, MeshEmitter:33, MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `UniformSize` | 2,486 | Bool | SpriteEmitter:2435, MeshEmitter:51 |
| `UseColorScale` | 2,415 | Bool | SpriteEmitter:2358, BeamEmitter:50, RibbonEmitter:7 |
| `SpinsPerSecondRange` | 1,914 | Struct {RangeVector} | SpriteEmitter:1891, MeshEmitter:23 |
| `Acceleration` | 1,886 | Struct {Vector} | SpriteEmitter:1871, MultipleRibbonEmitter:8, RibbonEmitter:7 |
| `Blending` | 1,843 | Byte | SpriteEmitter:1836, RibbonEmitter:7 |
| `VelocityScale` | 1,589 | Array | SpriteEmitter:1589 |
| `CoordinateSystem` | 1,498 | Byte | SpriteEmitter:1432, BeamEmitter:50, MeshEmitter:16 |
| `TextureUSubdivisions` | 1,329 | Int | SpriteEmitter:1329 |
| `TextureVSubdivisions` | 1,329 | Int | SpriteEmitter:1329 |
| `UseRotationFrom` | 1,232 | Byte | SpriteEmitter:1214, MultipleRibbonEmitter:12, MeshEmitter:6 |
| `UseDirectionAs` | 1,040 | Byte | SpriteEmitter:1040 |
| `RelativeWarmupTime` | 699 | Float | SpriteEmitter:665, MeshEmitter:34 |
| `WarmupTicksPerSecond` | 699 | Float | SpriteEmitter:665, MeshEmitter:34 |
| `BackFadeDistance` | 599 | Float | SpriteEmitter:599 |
| `BackFadeType` | 597 | Byte | SpriteEmitter:597 |
| `UseRandomSubdivision` | 573 | Bool | SpriteEmitter:573 |
| `UseVelocityScale` | 570 | Bool | SpriteEmitter:570 |
| `StartLocationOffset` | 434 | Struct {Vector} | SpriteEmitter:386, BeamEmitter:45, MultipleRibbonEmitter:3 |
| `EnableVertexLighting` | 345 | Bool | SpriteEmitter:332, MultipleRibbonEmitter:13 |
| `EnablePerPixelLighting` | 295 | Bool | SpriteEmitter:295 |
| `BlendBetweenSubdivisions` | 290 | Bool | SpriteEmitter:290 |
| `FadeOutStartTime` | 260 | Float | SpriteEmitter:220, MeshEmitter:40 |
| `FadeOut` | 252 | Bool | SpriteEmitter:212, MeshEmitter:40 |
| `VelocityLossRange` | 229 | Struct {RangeVector} | SpriteEmitter:229 |
| `InitialDelayRange` | 200 | Struct {Range} | SpriteEmitter:186, RibbonEmitter:7, MeshEmitter:5, BeamEmitter:2 |
| `FadeIn` | 166 | Bool | SpriteEmitter:126, MeshEmitter:40 |
| `FadeInEndTime` | 166 | Float | SpriteEmitter:126, MeshEmitter:40 |
| `CollisionType` | 123 | Byte | SpriteEmitter:110, MultipleRibbonEmitter:13 |
| `ExtentMultiplier` | 92 | Struct {Vector} | SpriteEmitter:92 |
| `FakeLightColor` | 86 | Struct {Color} | SpriteEmitter:86 |
| `InitialTimeRange` | 84 | Struct {Range} | SpriteEmitter:84 |
| `bHidden` | 65 | Bool | SpriteEmitter:65 |
| `DampingFactorRange` | 64 | Struct {RangeVector} | SpriteEmitter:51, MultipleRibbonEmitter:13 |
| `MinDistortionClipDistance` | 61 | Float | SpriteEmitter:61 |
| `FakeLightOffset` | 58 | Struct {Vector} | SpriteEmitter:58 |
| `EnableFakeLight` | 57 | Bool | SpriteEmitter:57 |
| `StaticMesh` | 57 | Object | MeshEmitter:57 |
| `BeamDistanceRange` | 50 | Struct {Range} | BeamEmitter:50 |
| `BeamEndPoints` | 50 | Array | BeamEmitter:50 |
| `BranchEmitter` | 50 | Int | BeamEmitter:50 |
| `BranchHFPointsRange` | 50 | Struct {Range} | BeamEmitter:50 |
| `BranchProbability` | 50 | Struct {Range} | BeamEmitter:50 |
| `BranchSpawnAmountRange` | 50 | Struct {Range} | BeamEmitter:50 |
| `DetermineEndPointBy` | 50 | Byte | BeamEmitter:50 |
| `HighFrequencyNoiseRange` | 50 | Struct {RangeVector} | BeamEmitter:50 |
| `LowFrequencyNoiseRange` | 50 | Struct {RangeVector} | BeamEmitter:50 |
| `RevolutionsPerSecondRange` | 50 | Struct {RangeVector} | MeshEmitter:34, SpriteEmitter:9, RibbonEmitter:7 |
| `UseRevolution` | 49 | Bool | MeshEmitter:34, SpriteEmitter:8, RibbonEmitter:7 |
| `LowFrequencyPoints` | 45 | Int | BeamEmitter:45 |
| `GetVelocityDirectionFrom` | 40 | Byte | SpriteEmitter:40 |
| `HighFrequencyPoints` | 40 | Int | BeamEmitter:40 |
| `StartLocationPolarRange` | 40 | Struct {RangeVector} | MeshEmitter:34, SpriteEmitter:6 |
| `StartVelocityRadialRange` | 40 | Struct {Range} | SpriteEmitter:40 |
| `DisableForceSoftParticles` | 36 | Bool | SpriteEmitter:36 |
| `StartLocationShape` | 34 | Byte | MeshEmitter:34 |
| `bInheritOwnerDeath` | 34 | Bool | SpriteEmitter:34 |
| `StartMassRange` | 26 | Struct {Range} | MeshEmitter:17, SpriteEmitter:9 |
| `AddLocationFromOtherEmitter` | 23 | Int | SpriteEmitter:23 |
| `ColorScaleRepeats` | 20 | Float | SpriteEmitter:20 |
| `InitialSegmentsPerSecond` | 20 | Float | MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `MaxSegmentLifetimeRange` | 20 | Struct {Range} | MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `RibbonWidth` | 20 | Float | MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `SegmentColorScale` | 20 | Array | MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `SegmentsPerSecond` | 20 | Float | MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `UseSegmentColorScale` | 20 | Bool | MultipleRibbonEmitter:13, RibbonEmitter:7 |
| `HavokDistanceBeforeActivatingCollisions` | 18 | Float | SpriteEmitter:11, RibbonEmitter:7 |
| `RevolutionCenterOffsetRange` | 16 | Struct {RangeVector} | SpriteEmitter:8, MeshEmitter:8 |
| `FadeOutFactor` | 15 | Struct {Plane} | SpriteEmitter:15 |
| `CollisionsTriggerEffectEvents` | 13 | Bool | SpriteEmitter:13 |
| `RibbonGroups` | 13 | Array | MultipleRibbonEmitter:13 |
| `bBillboardSheets` | 13 | Bool | MultipleRibbonEmitter:13 |
| `HavokRestitution` | 10 | Float | SpriteEmitter:10 |
| `AmbientColor` | 8 | Struct {Color} | SpriteEmitter:8 |
| `AnchorBaseParticleLocationToOwnerLocation` | 8 | Bool | MultipleRibbonEmitter:8 |
| `InheritOwnersVelocity` | 8 | Bool | RibbonEmitter:7, SpriteEmitter:1 |
| `UseSpawnLocationOffsetFromBaseParticle` | 8 | Bool | MultipleRibbonEmitter:8 |
| `UseSpawnVelocityOffsetFromBaseParticle` | 8 | Bool | MultipleRibbonEmitter:8 |
| `AddVelocityFromOtherEmitter` | 7 | Int | SpriteEmitter:7 |
| `BaseVelocity` | 7 | Struct {Vector} | RibbonEmitter:7 |
| `ClampUCoordToRibbonSegment` | 7 | Bool | RibbonEmitter:7 |
| `GetPointAxisFrom` | 7 | Byte | RibbonEmitter:7 |
| `MaxCollisions` | 7 | Struct {Range} | SpriteEmitter:7 |
| `MaxSegmentCollisions` | 7 | Struct {Range} | RibbonEmitter:7 |
| `NumPoints` | 7 | Int | RibbonEmitter:7 |
| `RibbonPoints` | 7 | Array | RibbonEmitter:7 |
| `RibbonSplineDegree` | 7 | Int | RibbonEmitter:7 |
| `RibbonTextureUScale` | 7 | Float | RibbonEmitter:7 |
| `SegmentFadeOutRange` | 7 | Int | RibbonEmitter:7 |
| `SegmentSizeScale` | 7 | Array | RibbonEmitter:7 |
| `SpawnedSegments` | 7 | Int | RibbonEmitter:7 |
| `UseMaxCollisions` | 7 | Bool | SpriteEmitter:7 |
| `UseSegmentSizeScale` | 7 | Bool | RibbonEmitter:7 |
| `VelocityDeviationRange` | 7 | Struct {RangeVector} | RibbonEmitter:7 |
| `SubdivisionScale` | 6 | Array | SpriteEmitter:6 |
| `bRemainAttachedWhenStopped` | 5 | Bool | MultipleRibbonEmitter:5 |
| `MaxSegmentsToSpawn` | 3 | Int | RibbonEmitter:3 |
| `AutoReset` | 2 | Bool | SpriteEmitter:2 |
| `CollisionShape` | 2 | Byte | SpriteEmitter:2 |
| `UseCollisionPlanes` | 2 | Bool | SpriteEmitter:2 |
| `ForceMinimumOneFrameLifetime` | 1 | Bool | SpriteEmitter:1 |
| `RevolutionScale` | 1 | Array | SpriteEmitter:1 |
| `UseRevolutionScale` | 1 | Bool | SpriteEmitter:1 |

## 5. What is typed today

`EmitterTemplateData` now exposes 31 of those 120 fields, widened 24 Aug 2026 from the four it
started with (`Material`, `MaxParticles`, `ParticlesPerSecond`, `InitialParticlesPerSecond`).
Everything below is `CONFIRMED_BYTES`, pinned against real templates by `EmitterTemplateFieldTests`.

| Need | Property | Templates | Type |
|---|---|---|---|
| Lifetime | `LifetimeRange` | 3,067 | `FloatRange` |
| Size | `StartSizeRange`, `UniformSize`, `UseSizeScale`, `UseRegularSizeScale`, `SizeScale` | 3,167 / 2,486 / 2,655 / 3,010 / 2,923 | `AxisRange`, `bool`, `IReadOnlyList<FloatCurveKey>` |
| Velocity | `StartVelocityRange`, `Acceleration`, `VelocityScale` | 2,966 / 1,886 / 1,589 | `AxisRange`, `Vector3`, `IReadOnlyList<VectorCurveKey>` |
| Spawn volume | `StartLocationRange`, `StartLocationOffset`, `StartLocationShape` | 2,718 / 434 / 34 | `AxisRange`, `Vector3`, raw byte |
| Colour | `UseColorScale`, `ColorScale` | 2,415 / 2,790 | `bool`, `IReadOnlyList<ColorCurveKey>` |
| Spin | `StartSpinRange`, `SpinsPerSecondRange`, `SpinParticles` | 2,605 / 1,914 / 2,764 | `AxisRange`, `bool` |
| Blend mode | `Blending` | 1,843 | raw byte |
| Space | `CoordinateSystem` | 1,498 | raw byte |
| Sprite sheet | `TextureUSubdivisions`, `TextureVSubdivisions` | 1,329 | `int` |
| Spawning | `AutomaticInitialSpawning`, `RespawnDeadParticles` | 3,038 / 2,580 | `bool` |
| Mesh visual | `StaticMesh` (`MeshEmitter` only) | 57 | reference |
| Ribbon segments | `SegmentSizeScale`, `SegmentColorScale` (`MultipleRibbonEmitter`/`RibbonEmitter` only) | 20 / 20 | `IReadOnlyList<FloatCurveKey>`, `IReadOnlyList<ColorCurveKey>` |

`Range` and `RangeVector` turned out to be nested tagged-property structs rather than fixed-size
packed floats, unlike `Vector`, `Color` and `Rotator`, which this project already reads as fixed
12/4/12 bytes. `Range` is `{ Min: Float, Max: Float }` at 25 bytes; `RangeVector` is
`{ X, Y, Z: Range }` at 116 bytes. Both read with the same nested
`UnrealPropertyReader.Read(value, names, start: 0)` call `LevelAnalyzer.ReadRegion` already used for
`FPointRegion` — see `ReadFloatRange` / `ReadAxisRange`.

The three curve arrays share that nested-struct shape rather than being packed floats either, and
were decoded the same day as the widening above. `SizeScale` is `[{ RelativeTime: Float,
RelativeSize: Float }]` at 25 bytes per key; `ColorScale`/`SegmentColorScale` are `[{ RelativeTime:
Float, Color: Struct{Color} }]` at 30 bytes per key; `VelocityScale` is `[{ RelativeTime: Float,
RelativeVelocity: Struct{Vector} }]` at 39 bytes per key. `ReadStructArrayElements` reads each
element by its own terminator — the same idiom the top-level property list already uses — rather
than by a computed stride, and only returns a curve when the compact count and every element
together consume the array's complete value. A curve whose shape doesn't match this yields null,
not a partial or misaligned read. See `ReadFloatCurve` / `ReadColorCurve` / `ReadVectorCurve`.

Absence is preserved, not defaulted. UE2 serialises only what differs from the class default, so a
field with 3,067 hits is null on the other 144 templates in this game — not zero, not the class
default, null. The pinned example (`1-Medical` export 9616, template export 25099,
`SpriteEmitter4`) has `MaxParticles`, `Acceleration` and `StartLocationShape` unserialised, and all
three read back null. Its `ColorScale` also shows why absence matters even inside a curve: two of
its four keys carry alpha 0 (invisible) and the other two carry alpha 30, not 255 — a placeholder
that assumed opaque would render this particular effect visibly wrong.

Two things were left out of this pass. `SubdivisionScale` and `RevolutionScale` (6 and 1 shipped
hits) remain undecoded — at that frequency they weren't worth a probe, though they're almost
certainly the same curve shape as `SizeScale`. `UseVelocityScale`, `UseRandomSubdivision` and the
other lower-frequency flags (under ~700 hits) were left for the same reason `RelativeWarmupTime` and
`WarmupTicksPerSecond` were: this pass targeted what a Niagara placeholder needs first, not the
whole 120.

## 6. Open — the byte enums

Eleven properties are single bytes whose *values* are readable but whose *meanings* are not,
because the enum declarations aren't in anything this project has read. That's `UNKNOWN`, and
deliberately so:

`Blending`, `CoordinateSystem`, `UseRotationFrom`, `UseDirectionAs`, `BackFadeType`,
`CollisionType`, `StartLocationShape`, `DetermineEndPointBy`, `GetVelocityDirectionFrom`,
`GetPointAxisFrom`, `CollisionShape`.

They aren't in `Bioshock1REMSDK-WIP--main` either — grepped, not assumed. The one real lead is Track
B's decompiler, and it's narrower than previously stated. Confirmed 24 Aug 2026: none of the five
emitter classes (`SpriteEmitter`, `MeshEmitter`, `BeamEmitter`, `MultipleRibbonEmitter`,
`RibbonEmitter`) or a `ParticleEmitter` base declaration appear anywhere in the 11 script packages
`tools/uelib-bridge/` decompiles cleanly. All of Core, ShockGame, ShockAI, Scripting,
VengeanceShared, Tyrion, FMODAudio, IGEffectsSystem, IGModEffectsSubsystem,
IGSoundEffectsSubsystem and IGVisualEffectsSubsystem were decompiled and grepped for the class names
and for `Blending`/`enum EParticle*`, with none found. That rules out a BioShock-side override and
pins the declarations to `Engine.U` specifically — the one package that crashes the decompiler
during initialization (`UClass.Dependency.Deserialize`, "Unexpected value for a boolean", a
version-gated field this UELib build reads incorrectly for BioShock's package version).
`Unreal-Library-master/src/Core/Classes/UClass.cs` already special-cases one other build the same
way for its `IsDeep` field, so the shape of a fix exists in the codebase, just not for this build.
That fix wasn't attempted here — patching a third-party decompiler's version branching and
re-verifying it doesn't regress the 11 packages that already work is Track B item 4's own scope,
not a smallest-correct-change for this note.

Until that resolves, a byte enum has to be carried through as its raw value, named for the property,
and a placeholder must not colour or blend from a guess. A wrong blend mode is precisely the class
of error that renders plausibly and is wrong — this project's documented failure mode.

## 7. What this note does not claim

- **No Niagara mapping is proposed here.** Choosing the UE5 representation is the rest of Gate 4
  item 3, and it should be chosen against the typed fields now that they exist, not against this
  table.
- **The parameter semantics are unchanged from what UE2 declares them as.** A `LifetimeRange` is
  exposed as the two floats it is, not interpreted into seconds-with-units or otherwise transformed.
  This note widens what is measured, not what is interpreted.
- **The byte enums' meanings are still open** — see §6. `SubdivisionScale` and `RevolutionScale`
  (6 and 1 shipped hits) also remain undecoded, per §5's "left out of this pass" paragraph.
- **`LastDeltaTime` (3,211 hits — the only property on every single template) is runtime state, not
  authored content.** It's the same shape of thing as `ShockAIScout`'s saved pathfinding timers:
  serialised because the editor saved a live object, meaningless to recreate. `LIKELY`, from its
  name and universality; it shouldn't reach a manifest as an authored parameter.
