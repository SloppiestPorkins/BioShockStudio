# AI spawning and archetypes

What an AI-archetype name points at — the gap `interaction.md` §4 left open and Phase 2.3's fourth
ask (`UE5_FULL_PORT_PLAN.md` §5 Phase 2.3).

## The archetype name → an `AIArchetype` record

`Spawner.OverriddenAiArchetypeNames`, `ActionSpawnAI.OverriddenAIArchetypeNames`, and the
character-name-shaped `TriggerOnlyByLabels` entries (`Steinman`, `Cohen`, `BerserkDude1`, …) are all
**`AIArchetype` object names**. They resolved against no placed-actor field because they were never
meant to — an archetype is a data record, not an actor.

- **`class AIArchetype extends Object native config(Spawning) perobjectconfig;`** — a per-object
  config class. `SpawningManager.uc`'s `defaultproperties` lists **313 archetype names** in
  `ArchetypeNames[]` (the master roster), and `SpawningManager.PopulateArchetypes()` (native) loads
  each name's data into `LoadedAIArchetypes[]`.
- **Each map ships the subset it uses as real `AIArchetype` exports**, outer'd to the map's
  `SpawningManager`. Census: **267 across the 21 base maps** (`4-Recreation` the most at 29;
  `Entry` and `museum` none). `AiArchetypeCatalog.Read` walks them; `AiArchetypeTests` pins the
  census.

## What an `AIArchetype` export carries

A plain tagged-property list. Serialized names (note: the loadout slots drop the underscore the
decompiled struct fields carry):

| Property | Type | Notes |
|---|---|---|
| `AIType` | `Class<ShockAI>` | The behaviour class — `SpawnedMeleeThug`, `SpawnedGrenadier`, `SpawnedRangedAggressorPistol`, `SpawnedBouncer`, `SpawnedGatherer`, `SpawnedAssassin`, `SpawnedMagicAssassin`, … Resolved name. |
| `Mesh` | `SkeletalMesh` | `Agg_BabyJane`, `Agg_Doctor_Mesh`, `Agg_LadySmith`, `GathererGirl`, `ProtectorBouncerMESH`, `SanderCohen`, … |
| `Health`, `FrozenHealth` | float | **Authored on ~45% of archetypes.** The map-tuned names (`MedicalDoctorMelee`) carry them; the base names (`DoctorMelee`) usually don't and take the `AIType` class's own default. Not a decode miss — the property is genuinely absent. Seen values: 50–2500 (`UltimateCohen` 2500, grenadiers 400, melee 80, pistol 160). |
| `DamageResistanceSetName` | name | `MedicalMeleeThugResistanceSet` etc. — keys a resistance table (not decoded here). |
| `RequiredAnimationGroups`, `VoiceTypes` | name array | Animation-package groups to retain; voice-line set keys. |
| `MaterialSlot` | `array<{ AIMaterial: Material, Chance: float }>` | Skin variants and their chance weights. Decodes — e.g. `AggDoctorRimShader` @ 100. |
| `AttachmentSlot1..4` | `array<{ AIAttachmentClass: Class<AIAttachment>, Chance: float }>` | Masks, pipes (`RabbitMask_White`, `ScriptedAI_Pipe`). Four slots. |
| `WeaponSlot1..4` | `array<{ CurrentAIWeaponClass, ReplacementAIWeaponClass: Class<AIWeapon>, Chance: float }>` | Weapon swaps. |
| `CollisionHeight` (`CollisionRadius` unseen) | float | `76` on the doctor. |
| `MaxBurningEfficacy`, `bDoNotDoBurningBehavior`, `bDoNotDoBurningAnimations`, … | float / bool | Status-effect tuning. |
| `CheckpointTypePadding` | int | The `structdefaultproperties` padding constant, on every record. Ignore. |

`AiArchetypeCatalog` surfaces `AIType`, `Mesh`, `Health`, `FrozenHealth`, `DamageResistanceSetName`,
`CollisionHeight`, the two name arrays, and the loadout-slot **entry counts**. The
class/mesh references *inside* the slot ChancePairs, and the resistance/status-tuning fields, are
not yet extracted — a follow-up, not a blocker.

## The reader gap this exposed

The loadout slots are `array<struct>` where each element is a nested property list
(`{ ref, float Chance, None }`). The array tag's declared size undercounts its elements' own
size-encoding bytes — the same shortfall `UnrealPropertyReader.CorrectedStructSize` handles one
level down for single structs — so a walk that trusts it lands mid-element and truncates, losing
every property authored after the first slot (`Health` for ~40% of archetypes, in config order).

`AiArchetypeCatalog` carries **its own property walk** that re-measures an `array<struct-proplist>`
by walking all `count` elements to their terminators, conservatively (only when the declared size
is demonstrably wrong — the byte at its end is not a property tag). Medical went 12 → 23 archetypes
parsing clean.

**Why not fix `UnrealPropertyReader` itself:** a first attempt did, and it shifted
`DocumentedFiguresTests` (the diagnose sweep) and `EmitterTemplateCensusTests` — emitter templates
carry `array<struct>` too, and correcting them there changes pinned figures. That correction is
worth doing but needs the classify-before-touching pass (`ENGINEERING_RULES.md` §24) on those
figures first. Scoped to the archetype reader for now; the slot arrays are only ever seen on
archetypes.

## Still open

- **Three archetypes hit a *different*, pre-existing reader gap** — `EngineeringWadersSMG`,
  `EngineeringWadersCeilingCrawler`, `EngineeringWadersTeleport` (5-Hephaestus) fail with
  "Property 'Min' overruns" — an unhandled `Range { float Min; float Max; }` nested struct. Not
  caused by the array fix (fails on the old reader too), not chased here.
- **The per-archetype `Spawning.ini` values** for archetypes that ship no export (or fields an
  export omits) — the file is declared in `Default.ini` (`PerObjIniFile=Spawning.ini`) but not
  present as a loose file in the Remastered install. The native `PopulateArchetypes()` sources them
  somewhere this project's tooling has not located. The export data covers the 267 that ship one.
- **The ChancePair inner references** (`AIMaterial`, `AIAttachmentClass`, weapon classes) — parse
  as struct rows; the refs inside aren't resolved to names yet.
