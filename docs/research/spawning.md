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
`CollisionHeight`, the two name arrays, and the loadout slots **with their contents resolved** —
each entry is `{ name, chance, replacement? }` (`AggDoctorRimShader` @ 100, `GrenadeBox` @ 100,
weapon swaps). Not yet extracted: the resistance table `DamageResistanceSetName` keys, and the
status-effect tuning fields (`MaxBurningEfficacy`, the `bDoNotDo*` bools).

## The reader gap this exposed

The loadout slots are `array<struct>` where each element is a nested property list
(`{ ref, float Chance, None }`). The array tag's declared size undercounts its elements' own
size-encoding bytes — the same shortfall `UnrealPropertyReader.CorrectedStructSize` handles one
level down for single structs — so a walk that trusts it lands mid-element and truncates, losing
every property authored after the first slot (`Health` for ~40% of archetypes, in config order).

`AiArchetypeCatalog` carries **its own property walk** that re-measures an `array<struct-proplist>`
by walking all `count` elements to their terminators. Non-heuristic, like
`UnrealPropertyReader.CorrectedStructSize` one level down: it corrects **only** when the walked span
exceeds the declared size by *exactly* the number of size-encoding bytes its elements carry between
them. **All 267 archetypes across the 21 maps parse clean** — including the `EngineeringWaders*`
family whose 7-entry `MaterialSlot` under-declares by 6 bytes and made the shared reader throw
outright ("Property 'Min' overruns").

**Why it stays scoped to the archetype reader — §24 classification done, 29 Aug 2026.** Porting the
same correction into `UnrealPropertyReader` was tried twice: first with a heuristic guard, then with
the exact `measured == declared + sizeBytes` test above. **Both are a net regression.** With the
exact test:

- `DiagnosticCodes.TextureUndecodable` **1 → 9** — eight textures that decoded fine no longer do.
- `EmitterTemplateCensusTests` **1859 → 1858** — one emitter template no longer walks clean.
- `TheDiagnosticTotalsStillHold` **333 → 341**, consistent with the eight broken textures.

The equation `measured == declared + sizeBytes` balances **by coincidence** for some legitimately
sized `array<struct>` in the texture and emitter payloads whose nested content the re-walk
misreads. A viable shared fix needs a tighter gate — e.g. only correct when the *corrected* offset
lands on a valid FName that the *declared* offset does not — which is real design work, not a quick
port. The archetype reader's copy is safe because it only ever runs on `AIArchetype` payloads,
verified against all 267.

## Coverage — the shipped exports are enough for the port

Two cross-checks against the shipped exports, whole-game:

| Consumer | References | Resolve to a shipped export in the same map |
|---|---|---|
| `Spawner.OverriddenAiArchetypeNames` (placed actors) | 36 | **36 / 36** |
| `ActionSpawn*.Overridden*ArchetypeNames` (scripts) | 326 | **316 / 326** |

The 10 script misses are one name — `PlayerEscortedGathererDLCCombat`, in `ChallengeRoomCombat` and
`ChallengeRoomElectric` only. It is in `SpawningManager.ArchetypeNames` (a real archetype) but ships
as no export in those two DLC maps; runtime loads it from `Spawning.ini`. Everything else the game
actually spawns is in hand. `Spawning.ini` (declared in `Default.ini` as `PerObjIniFile`, not
shipped as a loose file — `PopulateArchetypes()` sources it somewhere native) only matters for that
one DLC archetype and the ~46 `ArchetypeNames` entries no map references at all.

## Still open

- **The resistance table.** `AIArchetype.DamageResistanceSetName` / `ShockPawn.DamageResistanceSetName`
  name a `DamageResistanceSet` (`MedicalMeleeThugResistanceSet`, `DefaultResistanceSet`). The set
  itself is **not in the packages** — no `DamageResistanceSet` export anywhere, no class in Shock*/
  VengeanceShared (it is in `Engine.U`, which the decompiler cannot read, or purely native), and
  `ShockPawn.GetResistanceSet()` is a native function. Same shape as `Spawning.ini`: config/native
  data. The name is recoverable (and surfaced); the resistance values are not.
- **`PlayerEscortedGathererDLCCombat`** — the one referenced archetype with no shipped export.

Now extracted: the elemental-efficacy caps (`MaxBurningEfficacy` / `MaxFrozenEfficacy` /
`MaxShockedEfficacy`), the fire-immunity flag (`bDoNotDoBurningBehavior` — set on grenadiers holding
live grenades), `bCanRunAway`, `bCannotBeShattered`, and the burning/frozen decay timers. On the
manifest too.
