---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C — level-to-level travel with player-state carry-over. This is the Phase C exit
enabler: the game becomes more than one map, and everything built this session (health, EVE,
7 weapons + holster, 3 plasmids, research levels, inventory, money) survives the trip.

## Context (already shipped, do not rewrite)
- `AShockGameMode::PostLogin` -> possess path -> `EquipStarterWeapon(Player)` (weapons +
  plasmids + 1 kit + 1 hypo) + slice encounter. `-bioshockverifypossess` runs
  `VerifySliceFire` and logs `BIOSHOCK_SLICE_OK` / `BIOSHOCK_POSSESS_OK`.
- `UShockActionChangeLevel` (stub): `Configure(map, start, showLoading, persist)`,
  `RequestChange()` records `LastMapName`; `ApplyInWorld` just calls `RequestChange`.
  Also `UShockActionUnlockBathysphereDestination` / `ShowBathysphereUI` /
  `EnableBathysphereModeForPlayer` stubs.
- `AShockPlayer` state worth carrying:
  - health: `CurrentHealth` (`SetCurrentHealthForVerify`), `MaxEve` / `CurrentEve`
  - weapons: `WeaponSlots[8]` (each an `AShockWeapon` with a `GetWeaponDefName()`,
    `GetRoundsInMagazine()` / `GetReserveAmmo()` / `GetMagazineSize()`), `ActiveWeaponSlot`,
    `GiveWeaponByDef(name, slot)` / `GiveWeapon(class, slot)` / `SelectWeaponSlot`.
    `AShockResearchCamera` is slot 7 (spawned via `GiveWeapon(class)` — no def name).
  - plasmids: `EquippedPlasmids[3]` (each a `UShockPlasmid` with `PlasmidName`),
    `ActivePlasmidSlot`, `EquipPlasmid(TSubclassOf<UShockPlasmid>, slot)`,
    `UShockPlasmid::ResolvePlasmidClass(FName)`.
  - research: `ResearchPointsByArchetype` (`TMap<FName,float>`), `AddResearchPoints`.
  - inventory: `InventoryStacks` (`TMap<FName,int32>`), `AddStackToInventory` /
    `GetInventoryStack`; `PlayerMoney` (`AddMoney` / `GetMoney`).
- `UShockWeaponDef::Resolve(FName)` maps a name back to a def.
- `tools/ue5/import_all_levels.py` can import a real BioShock map into a project; `0-Lighthouse`
  is import-proven (b1). The slice project (`C:\Users\Jack\Documents\BioShockUE5`) currently
  has only `/Game/BioShockSlice/1-Medical` + `_Scratch` / `_ScratchPossess` throwaway maps.

## Do
1. **`UShockCarryState`** (UObject, or a `USaveGame` — your call, but it must survive
   `OpenLevel`, so store it on the **GameInstance** or a `USaveGame` slot): fields for
   everything in the list above — `float Health`, `float MaxEve` / `CurrentEve`,
   `TArray<FShockCarriedWeapon>` (`DefName` or `ClassPath`, `Slot`, `Mag`, `Reserve`),
   `int32 ActiveWeaponSlot`, `TArray<FShockCarriedPlasmid>` (`PlasmidName`, `Slot`),
   `int32 ActivePlasmidSlot`, `TMap<FName,float> Research`, `TMap<FName,int32> Inventory`,
   `int32 Money`, plus `FString ArrivalStartLabel`.
   `static UShockCarryState* Capture(AShockPlayer*)` and
   `void RestoreOnto(AShockPlayer*) const`.
2. **`UShockGameInstance`** (`UGameInstance` subclass — set as the project GameInstance in
   `DefaultEngine.ini` via `setup_playable_slice.py` if it isn't already, or a `-DEV` note if
   that's fiddly): `TObjectPtr<UShockCarryState> PendingCarryState`, `bool bHasPendingArrival`.
   If a project GameInstance override is too invasive, a `static` on `UShockCarryState` +
   a `UEngineSubsystem` is an acceptable PLAUSIBLE fallback — note which you used.
3. **`AShockGameMode::TravelToLevel(const FString& Map, FName StartLabel)`**: `Capture` the
   local player's state into the GameInstance, log `BIOSHOCK_TRAVEL to=<map> start=<label>`,
   then `UGameplayStatics::OpenLevel(this, FName(*Map))`. `AShockGameMode::PostLogin` /
   the possess path: if the GameInstance has a pending carry state, **`RestoreOnto` the new
   player instead of `EquipStarterWeapon`**, move them to the `ArrivalStartLabel` actor if one
   matches (else the normal start), clear the pending state, log
   `BIOSHOCK_ARRIVED start=<label> health=<h> weapons=<n> plasmids=<n>`. First load (no pending
   state) = the existing `EquipStarterWeapon` path, unchanged.
4. **Wire `UShockActionChangeLevel::ApplyInWorld`** -> resolve the `AShockGameMode` from the
   context world -> `TravelToLevel(MapName, FName(*StartLocationLabel))`. Keep `RequestChange()`
   (tests use it).
5. **`AShockBathysphereStation`** (AActor, stretch): a trigger box + `DestinationMap` /
   `DestinationStart` / `bUnlocked`; player overlap + an `Interact` key (`E`? taken by
   nothing player-side yet — or reuse `HackTool`'s pattern with a new `Interact` -> `F`) ->
   if `bUnlocked`, `GameMode->TravelToLevel(...)`. `UShockActionUnlockBathysphereDestination`
   -> set `bUnlocked` on the matching station. If the trigger/interact wiring is heavy, ship
   just `TravelToLevel` + the action and note the station TODO.
6. **Second map for the slice** (so travel has a real destination): run
   `import_all_levels.py --maps 0-Lighthouse` (or the smallest proven map) into the slice
   project as a one-off, OR — simpler and enough for the verify — a hand-built
   `/Game/BioShockSlice/_TravelDest.umap` with a `ShockGameMode`, a `PlayerStart`, and a
   couple of `TargetPoint`s named as arrival labels, created in `setup_playable_slice.py`
   (new step). Whichever you pick, the verify travels **1-Medical -> _TravelDest** (or the
   real map) and back.
7. `run_level_travel.py` / `verify_level_travel.py` — headless: configure a player on map A
   with distinctive state (health 55, EVE 30, TommyGun slot 2 mag 12 / Pistol slot 1, Electro
   Bolt + Incinerate, research `Agg_BabyJane`=250, 3 FirstAidKits, $175); `TravelToLevel` to
   map B; after the arrival possess, assert **every field restored** (health 55, EVE 30, the
   two weapons in the right slots with the right ammo, the two plasmids, research 250 -> still
   level 2, 3 kits, $175). Also: a fresh load with **no** pending state runs
   `EquipStarterWeapon` and the slice still logs 100 -> 75 / fire=1. `Success - N error(s)`.
   Use the `verify_plasmid.py` teardown pattern. (Headless map travel: if `OpenLevel` inside a
   `-run=pythonscript` commandlet is unreliable, capture -> store -> load map B -> restore ->
   assert is a valid substitute — note it.)
8. `docs/FULL_GAME_CONVERSION.md`: under Phase C (or a new "level travel" bullet) — what
   shipped, the carry-state field list, the GameInstance approach used, and TODOs (the
   bathysphere UI / route map, save-on-travel to disk, per-level scripted intro beats, the
   full 21-map import + travel graph, autosave).

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`, + a `Content/BioShockSlice/_TravelDest.umap` if
  you build one — that's a generated slice asset, gitignore it if it isn't covered) + one doc
  edit. No `src/**`, `tests/**`. No commit/push. Scratch -> `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **First-load slice unchanged**: with no pending carry state, `run_game_possess.py` still
  runs `EquipStarterWeapon` and logs the possess + slice pass, **100 -> 75, fire=1,
  failures []**. Every existing `run_*` verify stays green (they never set a pending state).
- Don't change `EquipStarterWeapon`, the damage path, the AI, the weapon defs, plasmids,
  hacking, research, inventory, or the HUD — this is a new travel path + a state blob, and one
  branch in `PostLogin` ("pending arrival? restore : equip-starter").
- Real map/label names where known; every invented number/threshold gets a `PLAUSIBLE`
  comment. `docs/ENGINEERING_RULES.md` — smallest correct change.
- **Partial is fine**: `UShockCarryState` (health + EVE + weapons + plasmids + inventory +
  money, research optional) + `TravelToLevel` + the `PostLogin` restore branch + `ActionChangeLevel`
  wired + the headless capture->load->restore verify, with the bathysphere station and the
  real-map destination noted TODO (use `_TravelDest.umap`) — as long as it compiles and every
  existing `run_*` verify stays green.
