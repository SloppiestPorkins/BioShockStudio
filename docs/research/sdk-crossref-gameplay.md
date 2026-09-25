# SDK cross-reference: chapters 24–32 (gameplay)

**RESULT:** Chapters 24–32 audited against runtime + importers (read-only). **BUG 12 / GAP 28 / OK 18 / UNKNOWN 6.** Highest-impact silent wrongs: device-hack success shuts the whole security system; alarm bots spawn ~250 uu from the player instead of 3000–6000 out of sight; non-scripted turrets refuse to exist while the player is nearby; hack boards/buy-out/fail damage ignore `Hacking.ini`; vending stock ignores authored `VendingTableName`. Already-fixed items and known-open items from the brief are not re-listed as new finds; ecology gaps are ranked for Medical only.

Guide source: UnrealEd guide mirror chapters 24–32 (cite by chapter + section heading only). Code inspected in `tools/ue5/BioShockRuntime` and related importers/C# exporters. Medical actor counts from `1-Medical.level.json` (8089 actors).

---

## BUG (player-visible impact order)

| id | what the guide says (own words) | guide ref | our code | what we do instead | proposed fix | effort |
| --- | --- | --- | --- | --- | --- | --- |
| B01 | Winning a device hack only flips that device (turret/camera/bot friendly, or machine discounts). System-wide security shutdown is a separate station/script path. | 32-Hacking.md §What a hack does; 31-Security.md §Place a Bot Shutdown Panel | `ShockHackingMinigame.cpp:731-748` → `ShockPlayer.cpp:3385-3408` | `ApplyHackSuccessToWorld` always calls `SetSecurityHacked`, which clears the alarm and runs `ApplySecurityShutdown` on **every** security device for `HackShutdownSeconds` (default 8). Instant-hack path (`TryHackDevice`) does **not** do this — minigame wins are worse. | On device win: allegiance + station `SetHacked` only. Call `SetSecurityHacked` only from `ActionHackSecuritySystem` / shutdown panel. | S |
| B02 | Alarm bots appear at a nav point the player cannot see, 3000–6000 uu away (1500–4000 if alarm is vs AI). | 31-Security.md §The alarm; 26-AI-Paths.md §Place flying path nodes | `ShockSecuritySubsystem.cpp:56-78`, `:103` | `ResolveSpawnLocation` falls back to `NearLocation + (250,0,0)` beside the player/camera. No LOS / distance band. | Pick FlyingPathNode/PathNode in [3000,6000] with failed player LOS; honour `NextSpawnLocationLabel`. | M |
| B03 | Non-scripted turrets exist when the map starts (`ForScriptedSpawn` false). | 31-Security.md §Place a turret | `ShockEnemySpawner.cpp:454-486` | After a 3 s delay, spawn is **deferred while** the player is within `max(SightDistance, 1500)`. Turrets appear late or never in tight Medical rooms. | Spawn at map start (or bake-time). Gate AI fire with LOS/allegiance, not existence. | S |
| B04 | Camera FOV default 60°; SightDistance default 1000 (Medical often higher). | 31-Security.md §Place a security camera | `ShockSecurityDevice.h:30-34`; `ShockSecurityCamera` inherits them | Defaults are `DetectionRange=3000` and `DetectionHalfAngleDeg=90` (180° cone). Cameras are also **not imported** into the slice (no `SecurityCamera` importer). | Default half-angle 30; range 1000; import spawners and copy authored FOV/SightDistance/yaw limits. | M |
| B05 | Concurrent alarm bot stack can reach four; a second alarm while one runs adds one bot. | 32-Hacking.md §What a failure does | `ShockSecuritySubsystem.h:28`; `ShockSecuritySubsystem.cpp:148-165`; `ShockHackingMinigame.cpp:872-879` | `MaxActiveBots=2`. Hack alarm tile calls `SetSecurityAlarmOn(true)`; if alarm already on, `OnAlarmStateChanged` does **not** spawn extras. Camera path when already on does spawn. | Cap at 4; on re-alarm add +1; use section `AlarmBotCount` / camera `NumSecurityBotsSpawned`. | S |
| B06 | Overload / other fail damage comes from the puzzle section (`DamageDealtOnOverload` / `DamageDealtOnShortCircuit`, e.g. 150 / 50 on deck-1 health). Buy-out is derived from tile counts and floored by `MinimumPurchaseOptionCost`. | 32-Hacking.md §What a section holds; §The buy-out price | `ShockHackingMinigame.h:119-125`; `ShockHackingMinigame.cpp:533-541`, `:762-776` | Procedural board from a 0–1 difficulty. Buy-out `30+70*diff`. Overload damage flat 15; other fail 5. Non-lethal cap is already fixed — magnitudes are still wrong. | Parse `Hacking.ini` by `HackInfoName`; drive tiles, speeds, damages, buy-out, `AlarmBotType`/`Count`. | L |
| B07 | Alarm-tile failure releases `AlarmBotCount` of `AlarmBotType` from that section. | 32-Hacking.md §What a failure does | `ShockHackingMinigame.cpp:872-879` + `OnAlarmStateChanged` | Raises player alarm with pending count defaulting to 1; never reads section bot class/count. | Wire puzzle fields into `SetRequestedBotCount` + bot class spawn. | M |
| B08 | After the alarm ends (timeout or shutdown panel), bots are not described as auto-despawning; panel stops the alarm. | 31-Security.md §The alarm; §Place a Bot Shutdown Panel | `ShockSecuritySubsystem.h:30-32`; `:168-173`, `:210-248` | Clearing the alarm schedules `DespawnAllBots` after invented 30 s (`BotClearAfterAlarmClearSeconds`). | Stop inventing despawn; keep bots until killed or explicit shutdown action. | S |
| B09 | Vending rows come from `VendingTableName` → `LootTables.ini` (`CreditValue × CostAdjustment`, hacked vs unhacked row flags, optional `SupplySize`). | 25-Machines.md §The stock of a vending machine | `ShockStationActor.cpp:38-97`; `import_slice_stations.py:70-71` | `ConfigureVendingDefaults` hardcodes Circus stock/prices (e.g. first-aid 20/8). Medical’s `DeckOneVendingTable2` / `HackInfoName` are ignored. | Import vending + item `CreditValue`; filter by hack flags; apply `SupplySize`. | L |
| B10 | Hacked U-Invent uses 20% fewer components. | 25-Machines.md §U-Invent; 32-Hacking.md §What a hack does | `ShockStationMenu.cpp:565-590` | `CraftRecipe` always deducts full recipe counts; never consults `Station->bHacked`. | If hacked, `ceil(0.8 * count)` (or shipped rounding) per component. | S |
| B11 | `InitialAITypes` spawn when the map starts via the spawning manager. | 27-Spawning-AI.md §Place a spawner; §How the system works | `ShockEnemySpawner.cpp:107-127`, `:311-318` | No BeginPlay initial spawn; only proximity / script-zone later. Medical’s 19 aggressor markers stay empty until proximity heuristics fire. | Restore manager-driven initial spawn; keep proximity only for repopulation. | M |
| B12 | Vita-Chambers that are not activated are ignored; with none active, death returns to the main menu. | 25-Machines.md §Vita-Chamber | `ShockVitaChamber.h:45`; `ShockDeathRespawnHandler.cpp:116-144` | `bActive` defaults **true**; Medical chambers start usable without `ActionActivateResurrectionStation`. No-chamber path reloads/falls back to PlayerStart when `bReloadLevelOnDeath` — not main menu. | Default `bActive=false`; require activate action or overlap only if matching shipped `ActivateByPlayer` once verified. | S |

---

## GAP

| id | what the guide says (own words) | guide ref | our code | proposed fix | effort |
| --- | --- | --- | --- | --- | --- |
| G01 | Pickup world class ≠ inventory item; loot comes from `LootSlot` / `LootItemSpecification` / `LootTableSpecification`. Empty slot → prompt but no grant. | 24-Pickups-and-Loot.md §The loot slot; §Loot specifications | `ShockConsumablePickup.cpp`; `import_slice_pickups.py` class→amount map | Resolve exported `LootSlot` / table rolls into `Amount`/`ItemClass`. | L |
| G02 | Containers have three independent `LootSlots`. | 24-Pickups-and-Loot.md §Containers | `ShockSearchableContainer` money roll + optional one item | Three-slot roll model + table names. | M |
| G03 | AI corpse loot / Gatherer ADAM from manager `DefaultAILoot` by spawned class. | 24-Pickups-and-Loot.md §What an AI carries; 29-… §The ADAM that the player gets | No spawning-manager loot apply | Export `DefaultAILoot`; attach container on spawn. | L |
| G04 | Health station can be destroyed and drop medkits; `HackInfoName` selects puzzle. | 25-Machines.md §Health Station | Heal-only `TryInteract`; no damage break; no hack entry on stations | Destructible mesh + drop; station→minigame by `HackInfoName`. | M |
| G05 | Gene Bank / Power to the People / Bot Shutdown Panel placeable machines (PttP one-upgrade then closes; panel only while alarm on). | 25-Machines.md; 31-Security.md §Place a Bot Shutdown Panel | Gene Bank menu exists; **no** PttP kind; **no** `PlaceableSecurityStation` import (0 in Medical export under that name) | Add station kinds + Medical import; panel gates on `IsSecurityAlarmOn`. | M |
| G06 | Gatherer's Garden stock from growth tables (`SupplySize=1`, ADAM prices). | 25-Machines.md §Gatherer's Garden | Invented upgrade costs (`HealthUpgradeCost=20` etc.) | Drive menu from `VendingTableName` / growth section. | L |
| G07 | Machine hacking for vendors/health/U-Invent/safes/keypads via `HackInfoName`. | 32-Hacking.md §Which actors can be hacked | `TryHackDevice` only for `AShockSecurityDevice` | Unified hack target + success hooks per kind. | L |
| G08 | Safes open only after hack; keypad sends code message / optional non-hackable. | 32-Hacking.md §Safes; §Keypad-only doors | Combo-lock menu stand-in; safes as searchable | Hack-gated safe; `MessageDoorKeypadUsed` path. | M |
| G09 | Path build: 1200 link cap; Small/Tall/Wide reachspecs; FlyingPathNode rules; door nav points. | 26-AI-Paths.md | UE5 Recast nav mesh; PathNodes exported but not a BioShock reachspec graph | Either replay reachspecs or document permanent UE5 substitute + flying nav. | L |
| G10 | Spawning manager, spawn zones, archetype matching, bake registration. | 27-Spawning-AI.md | Partial spawners + archetype assets; **known open** full manager | Track under existing spawn-manager/archetype workstream. | L |
| G11 | PatrolList on manager: IdleTime/IdleChance/anims/run flags; walk out-and-back. | 28-Patrols.md | `ShockAIPatrolAbility.cpp:15-19` holds position; Medical has **127** PatrolPoints | Bind exported patrol names to MoveTo chain. | M |
| G12 | Ceiling crawler needs ceiling network path build does not create. | 27-Spawning-AI.md §Limits | No ceiling nav | Defer or special-case; low Medical urgency if unused in wired routes. | L |
| G13 | Little Sister ecology: vent knock, pair with protector, gather cycle, `MaxLootableGatherers` (default 3). | 29-Little-Sisters-and-Gatherer-Vents.md | Actions stubbed; **no** vent/LS runtime — **known open** | See Medical ranking below. | L |
| G14 | Path build cooks vent sockets + front PathNode (~110 / ~220 uu stand-off). | 29-… §What the path build does with the vent | No vent cooker | Editor/import step for vent sockets. | M |
| G15 | Rescue pays half stack (`SeaSlugAdamPercentage` 0.5); harvest full. | 29-… §The ADAM that the player gets | No harvest/rescue interact | Implement choice + ADAM grant from loot stack. | M |
| G16 | Booty corpses registered via ZoneInfo `SpawnZones`; pose/`StartingPose`; gather-once. | 30-Corpses.md | Booty → searchable money approx; no zone registration / LS gather | Zone link + gatherable flag; keep player search separate. | L |
| G17 | Security camera/bot spawners + manager registration; yaw/pan limits; spotlight actor. | 31-Security.md | Turret spawners imported; **cameras/bots not** | Import `SecurityCameraSpawner` / `SecurityBotSpawner`; copy limits. | M |
| G18 | Hacked camera alarms **against enemies**; green spotlight. | 31-Security.md §Hacking; 32-… §What a hack does | Friendly camera: no enemy alarm (`ShockSecurityCamera.cpp:95`) | Raise AI-targeted alarm + spotlight colour. | M |
| G19 | Dormant bot explodes after failed hack (except cancel). | 32-Hacking.md §What a failure does | No dormant-bot fail path | Explode / destroy on fail when dormant. | S |
| G20 | `MessagePlayerStartedHacking` / `FinishedHacking` with `SuccessfulHack`. | 32-Hacking.md §Scripting | No message emit from minigame | Send Shock messages for Medical scripts. | S |
| G21 | Patrol / spawn `ActionSetAIPatrol`, zone repopulation scripting. | 28 / 27 / 22 refs | Partial action stubs | Finish ApplyInWorld for Medical scripts. | M |
| G22 | Mimic corpse ambush fields on aggressor spawners. | 27-Spawning-AI.md §Spawner properties | Not applied | Pose + wake on perceive. | M |
| G23 | Protector `ProtectorGuardRange` / vent roaming. | 27 / 29 | No protector brain | Part of ecology. | L |
| G24 | Weapon upgrade station DrawScale 0.6; Garden 1.25. | 25-Machines.md | Import may not force scales | Apply DrawScale on import. | S |
| G25 | Auto-hack tool exists in our minigame; guide focuses on buy-out + pipe puzzle. | 32-Hacking.md | `TryAutoHack` | Keep; ensure item class matches shipped. | S |
| G26 | Nested loot `TableName=` entries. | 24-Pickups-and-Loot.md §The loot tables | C# reads field; runtime roll **known open** | Runtime weighted roller. | M |
| G27 | Flying path network for alarm bots (Medical: **283** FlyingPathNodes). | 26 / 31 | Unused by security spawn | Connect B02 to flying graph. | M |
| G28 | PlayerPathNode vs AI PathNode distinction. | 26-AI-Paths.md §Limits | Not modelled | Ignore for AI; optional player GPS later. | S |

### Ecology absence vs Medical dependence (chs 27–30)

Ranked by how much Medical’s shipped layout depends on the mechanic (counts from `1-Medical.level.json`):

1. **Aggressor/protector spawn + zones + archetypes** — 19 aggressor + 4 protector spawners, 23 archetypes in export. Without manager/initial spawn (B11/G10), Medical combat population is wrong. **Critical.**
2. **Patrols** — 127 PatrolPoints; spawners reference patrol names (e.g. `SurgeryEntryHall`). Patrol ability is a no-op (G11). **High** for non-scripted splicer motion.
3. **Path/flying graphs** — 495 PathNode + 283 FlyingPathNode. Recast substitutes ground walk; flying unused (G09/G27). **High** for bots/alarms once cameras exist.
4. **Gatherer vents + LS/BD pairing** — 7 `PlacedGathererVent`, 4 protectors; no LS class in-level (spawned from vents). Entire ecology missing (G13–G15,G23). **High** for ADAM economy / Garden (1 growth station).
5. **Booty / corpses** — ~39 booty/dead-body actors. Player search approx only; no LS gather registration (G16). **Medium–high** once LS exist; **medium** for player loot alone.
6. **DefaultAILoot / Gatherer ADAM tables** — required for non-zero rescue/harvest (G03/G15). **High** once G13 exists; useless before.
7. **Ceiling crawler network** (G12) — **Low** unless Medical routes spawn crawlers on authored ceiling paths.

---

## OK (verified match or intentional documented match)

- Health Station flat heal price 16 unhacked / 10 hacked (`ShockStationActor.cpp:163-167`) — 25 / 32.
- Hack failure never lethal (`FinishFail` / instant path clamp to health−1) — 32; magnitudes still B06.
- Alarm duration 60 s (`AlarmDurationSeconds`) — 31.
- Camera alert buildup threshold 4 s (`AlertThreshold`) — 31.
- Camera default bot count 1 (`NumSecurityBotsSpawned`) — 31 deck-1.
- Vita nearest active chamber selection exists (`FindNearestActive`) — 25.
- Vita activate/deactivate actions apply `SetActive` — 25.
- Turret spawner copies `SightDistance` into `DetectionRange` on spawn — 31.
- Turret `ForScriptedSpawn` → `bScriptOnly` skips BeginPlay spawn — 31.
- Security subsystem ticks from player (alarm expiry) — prior fix; still valid vs 31.
- Vending menu switches price field when `bHacked` — partial vs 25 (stock source still B09).
- Gene Bank equip/unequip UI path exists — 25.
- Pickup auto-touch vs interact split for weapons/plasmids/diaries — aligns with design intent in importer comments vs 24 use prompt.
- C# exports `VendingTableName` / `HackInfoName` / loot refs — 24/25 data available.
- C# `LootTableConfig` parses Chance/Min/Max/TableName — 24 (runtime roll still open).
- Medical station import covers health / Circus / Garden classes — 25 placement subset.
- PathNode/FlyingPathNode/PatrolPoint/Booty/vent counts present in Medical export — authoring side OK.
- `ActionStartSecurityAlarm` can request bot count — 31 scripting table.

---

## UNKNOWN

| id | question | what would resolve it |
| --- | --- | --- |
| U01 | Exact buy-out formula coefficients (tile weights × NormalSpeed). | Trace shipped hack UI code or controlled retail experiments with known boards. |
| U02 | Alarm bot placement LOS test details beyond distance band. | Native security manager / retail map instrumentation. |
| U03 | Whether alarm timeout removes bots or only clears the alarm flag. | Retail observe after 60 s with bots alive (guide silent → B08 assumes stay). |
| U04 | Vita `ActivateByPlayer` use-to-activate vs trigger-only. | Guide marks untested; try retail + compare to our overlap activate. |
| U05 | Camera “lose interest after 4 s without contact” vs continuous decay. | We decay at 1/s from buildup; confirm vs UC timer reset. |
| U06 | Hacked friendly-camera alarm targeting rules when multiple hostiles. | Retail / UC SecurityCamera follow-up. |

---

## Notes for reviewers

- Do **not** treat LootTables.ini runtime rolls, full spawn-manager/archetype system, or Gatherer ecology as newly discovered — they remain known-open; listed under GAP only for Medical planning.
- Prior session fixes (health 16/10, hack non-lethal cap, security tick + 60 s expiry, etc.) were re-checked as still present and counted under OK where relevant.
- Copyright: no guide prose copied; facts only.
