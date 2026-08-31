---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C4 round 2 — Pistol + Shotgun on the `UShockWeaponDef` framework (a29683a) + player
weapon-slot switching. Fills out "all seven" and gives the player more than one gun.

## Context (already shipped, do not rewrite)
- `UShockWeaponDef` (UDataAsset): `FireMode` (Hitscan/Projectile/Melee), `Damage` / `Range` /
  `Spread` / `FireRate` / `MagazineSize` / `ReserveAmmo` / `ReloadSeconds` / `bCanZoom` /
  projectile + melee fields. `static Resolve(FName)` has TommyGun / Wrench / GrenadeLauncher.
- `AShockWeapon::ApplyDef(UShockWeaponDef*)` copies onto the existing UPROPERTYs; `FireAt`
  dispatches on `FireMode` (`FireAtHitscan` / `FireAtProjectile` / `FireAtMelee`). a15 ammo,
  a19 feedback, the HUD ammo panel all read those fields.
- `AShockGameMode::EquipStarterWeapon` → `Weapon->ApplyDef(Resolve("TommyGun"))` +
  `InitializeAmmoFullMag(150)`; slice = one hit is 100 → 75 (25 dmg).
- `AShockPlayer::EquipWeapon(AShockWeapon*)` sets the single active weapon.
- Real numbers (`bioshock-tool weapons-config`, do NOT touch src):
  Pistol — mag 6, acc 0.5, rate 1, reload 1, zoom; Pistol Rounds `GenericPiercing 40`.
  Shotgun — mag 4, acc 0, rate 1, reload 1; 00 Buck `GenericPiercing 35`.
- `tmp/uc_shockgame/` — `Shotgun*.uc`, `Pistol*.uc`, `ShotgunAmmo.uc` (pellet count / spread
  cone if the defaults carry it) — hierarchy + `defaultproperties` usable.

## Do
1. **`EWeaponFireMode::Shotgun`** (new enum value) + `UShockWeaponDef` fields
   `PelletCount` (int) and `PelletSpreadDeg` (cone half-angle). `AShockWeapon::FireAtShotgun`:
   one `FireAt` press → `PelletCount` hitscan traces, each jittered within `PelletSpreadDeg`
   of the aim dir (deterministic jitter is fine — e.g. even fan + small per-index offset, so
   the verify is stable), each dealing `Damage` on an `AShockPawn` hit; consumes **one** round;
   a19-style tracer per pellet. Log `BIOSHOCK_SHOTGUN pellets=<n> hits=<n>`.
2. **`Resolve` +2 defs**:
   - `"Pistol"` — Hitscan, damage 40 (`GenericPiercing 40`), mag 6, reserve ~48, rate from
     `acc 0.5` → PLAUSIBLE spread, reload 1, `bCanZoom=true`.
   - `"Shotgun"` — the new Shotgun mode, per-pellet damage ~9 (PLAUSIBLE — `00 Buck` total is
     `GenericPiercing 35` across the spread; split across `PelletCount` ~8 → ~4.4, or keep 35
     as the *total* and divide — your call, label it), `PelletCount` 8 PLAUSIBLE (or the
     `ShotgunAmmo.uc` value if present), `PelletSpreadDeg` ~6 PLAUSIBLE, mag 4, reserve ~24,
     reload 1.
3. **Weapon slots on `AShockPlayer`**: `TArray<TObjectPtr<AShockWeapon>> WeaponSlots` (size 8,
   BioShock's holster order — Wrench, Pistol, Machine Gun, Shotgun, Grenade Launcher, Chemical
   Thrower, Crossbow, Camera), `ActiveWeaponSlot`. `GiveWeapon(TSubclassOf<AShockWeapon> or a
   def name, int32 slot)` spawns+`ApplyDef`+stores; `SelectWeaponSlot(int32)` /
   `NextWeapon()` / `PrevWeapon()` switch the active weapon (hide the old mesh, show the new,
   re-point `EquipWeapon`), skipping empty slots. Keep `EquipWeapon` working as the
   single-weapon path for AI / existing tests.
4. **Slice + input**: `EquipStarterWeapon` → give TommyGun (slot 2, as now, still the active
   one so **the slice still opens on the TommyGun and one hit is 100 → 75**), plus Wrench
   (slot 0), Pistol (slot 1), Shotgun (slot 3) so switching is testable. Bind `WeaponNext` /
   `WeaponPrev` (mouse wheel up/down) and `WeaponSlot1..4` (`1` `2` `3` `4`) in
   `setup_playable_slice.py` (new step). HUD: show the active weapon name by the ammo panel.
5. `run_weapon_slots.py` / `verify_weapon_slots.py` — headless: give a player Wrench/Pistol/
   TommyGun/Shotgun; `SelectWeaponSlot` switches which weapon `FireAt` uses and the mesh
   visibility; `NextWeapon` skips empty slots and wraps; Pistol `FireAt` → 40 dmg one shot;
   Shotgun `FireAt` at a close pawn → multiple pellet hits, one round consumed, total damage
   in the expected band; Shotgun at a far/oblique pawn → fewer/no hits (spread works).
   `Success - N error(s)`. Use the `verify_plasmid.py` teardown pattern (guarded `_destroy_all`
   + reset per section).
6. `docs/FULL_GAME_CONVERSION.md` C4: tick Pistol + Shotgun + weapon switching; update the
   "still on inline" / "missing" lists (Chemical Thrower, Crossbow, Research Camera, upgrade
   stations, ammo-type switching still to do).

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`) + one C4 doc edit. No `src/**`, `tests/**`.
  No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged**: the possess/encounter path must still open on the TommyGun and log
  **health 100 → 75, fire=1, failures []**. `run_weapon_def` / `run_plasmid` / `run_ai_brain` /
  `run_ai_combat` / `run_hit_reaction` / `run_hacking` stay green. (I run the `-game` slice
  possess at a checkpoint — you just need the headless `run_*` verifies + `-CleanModule`.)
- Don't change TommyGun/Wrench/GrenadeLauncher defs, the damage library, the AI, plasmids,
  hacking, or the HUD's existing rows. AI weapons (`EquipWeapon`, `bEnforceAmmo=false`) keep
  working unchanged.
- Real numbers from `weapons-config` / the decompiled `.uc`; every invented value gets a
  `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md`.
- **Partial is fine**: Shotgun mode + Pistol/Shotgun defs + the verify, with weapon-slot
  switching reduced to `SelectWeaponSlot` only (no wheel/number-key input) and noted TODO —
  as long as it compiles and every existing `run_*` verify stays green.
