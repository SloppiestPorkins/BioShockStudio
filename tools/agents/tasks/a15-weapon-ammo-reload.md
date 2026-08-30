---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Give `AShockWeapon` a magazine, reload, and a reserve ammo pool, and an ammo pickup — so the
slice TommyGun plays like a gun instead of an infinite hitscan.

## Context
`AShockWeapon` does hitscan `FireAt` (→ `UShockDamageLibrary`), configured by
`ConfigureHitscan(damage, range)` in `AShockGameMode::EquipStarterWeapon`. `AShockPlayer` binds
Fire input. There's no ammo model. `ActionGiveItemsToPlayer` / `ActionSpawnPickup` exist as stubs.

## Do
1. `AShockWeapon`: `MagazineSize` (~50 for TommyGun), `RoundsInMagazine`, `ReserveAmmo`
   (~150 start), `FireRate` (rounds/sec, ~10), `ReloadSeconds` (~2.5). `FireAt` refuses when the
   magazine is empty (play a dry click / log `BIOSHOCK_WEAPON_DRY`), decrements on each shot,
   respects `FireRate` (min interval between shots). `Reload()`: moves up to `MagazineSize -
   RoundsInMagazine` rounds from reserve into the magazine over `ReloadSeconds` (timer, not
   polled), blocks firing while reloading. Auto-reload on empty if `bAutoReload` and reserve > 0.
2. `AShockPlayer`: bind an **R** key to `Reload()`. Keep the existing Fire binding; Fire now
   goes through the ammo gate. HUD-less is fine — log the counts
   (`BIOSHOCK_AMMO mag=%d reserve=%d`) so the verify can read them.
3. `AShockGameMode::EquipStarterWeapon`: set the TommyGun's magazine full + the reserve.
4. An ammo pickup: a small `AShockAmmoPickup` actor (or reuse an existing pickup base if one
   exists — check) that on player overlap adds `PickupAmount` (~60) to `ReserveAmmo` and
   destroys itself. Spawn one in `SpawnSliceEnemy`'s vicinity or near `MedicalStart` so it's
   reachable. Wire `ActionSpawnPickup` / `ActionGiveItemsToPlayer` to it if trivial; otherwise
   leave those and just place one directly.
5. `run_weapon_ammo.py` / `verify_weapon_ammo.py` — headless: fire until empty (assert shots ==
   MagazineSize, then dry), Reload (assert magazine refills from reserve, reserve drops), fire
   again; overlap the pickup (assert reserve rises); `FireRate` caps shots-per-second.
   `Success - N error(s)`.
6. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.**
- Don't change hitscan damage (100→75 on the enemy stays), the damage path, or AI code.
- Fire goes through the ammo gate but the *feel* (LMB to fire) is unchanged.
- `docs/ENGINEERING_RULES.md`: smallest correct change, timer not poll for reload, verify each claim.
