# Enemy placement and spawner records

Scope: the shipped `1-Medical.bsm` and its v4 `1-Medical.ue5-level.json`. This note records the
evidence used by `tools/ue5/import_slice_enemies.py`; it does not claim a complete reconstruction
of the native `SpawningManager`.

## Placed population

**CONFIRMED_BYTES.** Medical contains 19 `AggressorSpawner` exports and five `TurretSpawner`
exports. It contains no actor whose class is `AISpawnPoint` or `AggressorSpawnPoint.`

`AggressorSpawner` inherits `EcologyFighterSpawner`, then `SpawnerBase`. The decompiled declarations
corroborate the tagged properties:

| Field | Encoding | Runtime meaning used here |
|---|---|---|
| `GlobalAITypes` | compact object-reference array | initial population; array count is spawn count |
| `InitialAITypes` | compact object-reference array | initial population; array count is spawn count |
| `RepopulationAITypes` | compact object-reference array | spawn-zone population; array count is spawn count |
| `OverriddenAIArchetypeNames` | FName array | exact archetype override |
| `SpawnZones` | FName array | zone keys used by repopulation script actions |
| `GlobalPatrol`, `InitialPatrol`, `RepopulationPatrol` | FName | authored patrol link for that phase |
| `InitialLabel` | FName | authored label for an initial AI |

`SpawnerBase` defaults repopulation enabled and carries
`MinDistanceToSpawnRepopulationAIIfPlayerLookingOtherWay=1000`. `SpawningManager.PostBeginPlay`
calls native `SpawnInitialAIs()`. Therefore **Global/Initial = immediate** and
**Repopulation = spawn-zone lifecycle**, not "spawn every actor when the map opens"
(**CONFIRMED_EXTERNAL** from the shipped UnrealScript declarations; the selection/timing bodies are
native and unavailable).

Representative real records, from
`BioShockStudio.Cli properties 1-Medical <actor> --raw`:

- export 7778 `AggressorSpawner3`, property span `+57..+281`:
  `InitialAITypes = 01 44 03`, override `MedicalBabyJaneMelee`, patrol
  `EternalFlameVictimPatrol`, zone `icu`.
- export 8734 `AggressorSpawner1`, property span `+58..+226`:
  `RepopulationAITypes = 04 4D 03 4D 03 44 03 55 03`, patrol
  `PainlessDentalPatrol`, zone `PainlessDental`. The leading `04` is the count.
- export 9427 `AggressorSpawner12`, property span `+58..+208`:
  `GlobalAITypes = 01 4D 03`, patrol `ICUUpperBackLookingUnderStuff`, zone `icu`.

### Important manifest limitation

**CONFIRMED_BYTES, package-specific.** The current v4 manifest reads the three class-reference
arrays as name-index arrays. That makes `01 44 03`, `01 4D 03`, and `01 55 03` appear as the
unrelated names `Creator`, `MaxLightsDynamic`, and `Context`. Reading them as compact object
references and resolving the referenced export (object reference N addresses CLI export N-1)
produces:

| Bytes after count | Referenced export | Class |
|---|---:|---|
| `44 03` | 195 | `SpawnedMeleeThug` |
| `4D 03` | 204 | `SpawnedRangedAggressorPistol` |
| `55 03` | 212 | `SpawnedGrenadier` |

The UE5 importer applies this correction only to Medical and then selects the first manifest
archetype whose `aiType` is that exact class. Exact `OverriddenAIArchetypeNames` always wins.
This preserves source location, class, phase, and count without inventing an encounter roster.

**APPROXIMATION.** Native weighted archetype selection is unavailable. Where no override is
authored, choosing the first same-class archetype in manifest order substitutes for that native
selection. Patrol names are carried on the runtime actor but patrol-path execution is not yet
implemented.

## Runtime trigger approximation

`AShockAggressorSpawner` implements the following:

- Global and Initial slots spawn 0.25 seconds after `BeginPlay`, retrying after nav generation.
- Every spawn must find a walkable downward trace and attempts to project that point onto the
  navmesh. Collision uses `AdjustIfPossibleButDontSpawnIfColliding`; there is no `AlwaysSpawn`
  fallback. **APPROXIMATION:** Medical's runtime Recast build can reject an authored marker while
  the floor beneath it is valid, so this follows the existing `SpawnOneSliceEnemy` policy: log
  `BIOSHOCK_AUTHORED_SPAWN_NAV_UNAVAILABLE` and retain the traced floor point.
- Repopulation slots spawn when the player enters a 1200 uu sphere. This is the requested fallback
  because the native spawn-zone timing and "player looking other way" decision are **UNKNOWN**.
- `ActionManipulateSpawnZoneRepopulation` enables/disables all imported aggressor spawners naming
  that zone; Enable also requests a population immediately.
- `ActionSetSpawnerRepopulationState` controls the named imported spawner.
- `ActionSpawnAI` resolves an imported spawner label first, then uses the same floor/nav spawn path.
- A living population suppresses duplicate proximity/repopulation spawns. A dead population can be
  replenished on a later trigger.
- Plain `-bioshockverifymovement` runs suppress authored enemies so the collision-only regression
  remains isolated. `verify_enemies.py` adds `-bioshockverifyenemies`; in that run an enemy may
  interrupt the route, which is itself consistent with encountering a live hostile.

## Turret spawners

**CONFIRMED_BYTES.** Export 8335 `TurretSpawner3` has `ForScriptedSpawn=True`,
`TurretType=SpawnedDeck1MinimumSecurityTurret`, `SightDistance=3000`,
`SpawnedTurretLabel=SteinmanTurretTrap`, and zone `surgery`. The other four are immediate:
four use the minimum-security machine-gun type and export 9937 uses
`SpawnedDeck1MaximumSecurityTurret` with `TurretGrenadeLauncher`.

Three records carry explicit spawned labels: `SteinmanTurretTrap`, `StunTurret`, and
`TurretToBeHacked`. All five inherit `TurretSpawner`'s `CanBeHacked=true` default.

`AShockTurretSpawner` now retains the source type, label, zone, scripted flag, and sight distance.
Immediate records spawn after `BeginPlay`; `ForScriptedSpawn` records wait for
`ActionSpawnTurret`. Turrets are hostile and hackable by default. Their spawn points use the same
floor trace and nav projection as aggressors.

**APPROXIMATION.** Both shipped turret classes currently instantiate the runtime's one
`AShockTurret` implementation. The source type remains recorded, but machine-gun versus grenade
launcher behavior is not differentiated by this change.
