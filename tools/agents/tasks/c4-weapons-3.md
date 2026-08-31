---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C4 round 3 — Chemical Thrower + Crossbow on the `UShockWeaponDef` framework. Finishes
"all seven" (Wrench / Pistol / Machine Gun / Shotgun / Grenade Launcher done → +these two).

## Context (already shipped, do not rewrite)
- `UShockWeaponDef` (UDataAsset): `FireMode` (Hitscan / Projectile / Melee / Shotgun),
  `Damage` / `Range` / `Spread` / `FireRate` / `MagazineSize` / `ReserveAmmo` /
  `ReloadSeconds` / `bCanZoom` / `ProjectileClass` / projectile + melee + pellet fields.
  `static Resolve(FName)` = TommyGun / Wrench / GrenadeLauncher / Pistol / Shotgun.
- `AShockWeapon::ApplyDef` copies onto the UPROPERTYs; `FireAt` dispatches on `FireMode`
  (`FireAtHitscan` / `FireAtProjectile` / `FireAtMelee` / `FireAtShotgun`). a15 ammo, a19
  feedback, the HUD read those fields.
- `AShockProjectile` (c4): sphere + `ProjectileMovementComponent`, `ConfigureFromWeapon`,
  radial or direct-hit damage on impact, `AdvanceForVerify(dt)` drives it headless.
- Status effects: `ABaseShockAI::Ignite(seconds, dps, instigator)` + `TickStatusEffects` (burn
  DoT), `ReactToPlasmidStun(duration, instigator)` (~2s stun), `ReactToHit` (a20 flinch).
- `AShockPlayer` holster: `WeaponSlots[8]` (Wrench0 / Pistol1 / MachineGun2 / Shotgun3 /
  GrenadeLauncher4 / **ChemThrower5** / **Crossbow6** / Camera7), `GiveWeaponByDef(name, slot)`,
  `SelectWeaponSlot` / `NextWeapon` / `PrevWeapon`.
- Real numbers (`bioshock-tool weapons-config`, do NOT touch src) — run it, capture Chemical
  Thrower + Crossbow rows (mag / acc / rate / reload + per-ammo damage stimuli).
- `tmp/uc_shockgame/` — `ChemicalThrower*.uc` / `ChemThrower*.uc` / `Napalm*.uc` /
  `Crossbow*.uc` / `CrossbowBolt*.uc` (`SteelTipBolt` / `TrapBolt` / `IncendiaryBolt`) —
  hierarchy + `defaultproperties` (beam range, tick rate, projectile speed) where present.

## Do
1. **`EWeaponFireMode::Beam`** (new) + `UShockWeaponDef` fields `BeamTickInterval`,
   `BeamRange`, `EBeamStatus` (None / Burning / Electric / Freeze). `AShockWeapon::FireAtBeam`:
   while the fire button is held (model it as: `FireAt` called repeatedly ticks the beam;
   add `StopBeam()` for release), each tick line-traces `BeamRange` from the muzzle and, on an
   `AShockPawn`, applies `Damage` (per tick, small) + the status:
   - Burning → `Ignite` (short refit each tick so it lingers ~1s after you stop).
   - Electric → `ReactToPlasmidStun` (brief, refreshed).
   - Freeze → a new `ABaseShockAI::ApplyChill(seconds)` (movement-speed scale ~0.4 while
     chilled; a light touch — do NOT rework the movement code, just a multiplier the combat
     tick already applies or a clamp in `TickCombatMovementSpeed`). Consumes ~1 ammo per N
     ticks (PLAUSIBLE). Beam tracer each tick. Log `BIOSHOCK_BEAM status=<s> hit=<0/1>`.
2. **`Resolve` +2 defs**:
   - `"ChemicalThrower"` / `"ChemThrower"` — Beam mode, `EBeamStatus::Burning` (Napalm
     default), per-tick damage ~3 PLAUSIBLE (or from `Napalm.uc` if it carries one),
     `BeamTickInterval` ~0.1 PLAUSIBLE, `BeamRange` ~800 PLAUSIBLE, mag/reserve from
     weapons-config (fuel tank), reload from config.
   - `"Crossbow"` — Projectile mode, high single-hit damage (`SteelTipBolt` GenericPiercing
     — use the weapons-config number, ~40+), `ProjectileImpactRadius` 0 (direct hit), fast
     `ProjectileInitialSpeed` ~6000 PLAUSIBLE, mag 1, reserve ~6, slow reload ~1.5 PLAUSIBLE,
     `bCanZoom=true`. Bolt retrieval = TODO (note it).
3. **Slice + input**: `EquipStarterWeapon` also `GiveWeaponByDef("ChemicalThrower", 5)` and
   `GiveWeaponByDef("Crossbow", 6)` so both are in the holster and reachable by
   `NextWeapon` / a slot key. Add `WeaponSlot5` / `WeaponSlot6` (`5` / `6`) mappings in
   `setup_playable_slice.py` (extend the existing `weapon_slot_key_mapping` step). Bind the
   beam-stop to the Fire key release if cheap; else note it. **The slice still opens on the
   TommyGun (slot 2) and one hit is 100 → 75.**
4. `run_weapon_beam.py` / `verify_weapon_beam.py` — headless: give a player the Chemical
   Thrower; repeated `FireAt` at a pawn in beam range → health drops per tick + the pawn is
   burning (health keeps dropping ~1s after the last tick), then stops; a pawn out of
   `BeamRange` → no damage; switch the def to Electric → the pawn is stunned; Freeze → the
   pawn's movement-speed multiplier drops. Crossbow: `FireAt` spawns an `AShockProjectile`
   that travels fast and deals the big single hit; `AdvanceForVerify` drives it. Ammo:
   Crossbow consumes 1 per shot, Chemical Thrower ~1 per N ticks. `Success - N error(s)`.
   Use the `verify_plasmid.py` teardown pattern (guarded `_destroy_all` + reset per section).
5. `docs/FULL_GAME_CONVERSION.md` C4: tick Chemical Thrower + Crossbow + the Beam fire mode;
   update the "missing" list (Research Camera, upgrade stations, ammo-type switching, bolt
   retrieval, chem-thrower Ionic/LiquidN ammo variants still to do). Note "all seven core
   weapons now have a def".

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`) + one C4 doc edit. No `src/**`, `tests/**`.
  No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged**: `run_game_possess.py` still opens on the TommyGun and logs
  **health 100 → 75, fire=1, failures []** (I run the `-game` possess at a checkpoint — you
  need `-CleanModule` + the headless `run_*` verifies only). `run_weapon_slots` /
  `run_weapon_def` / `run_plasmid` / `run_ai_brain` / `run_ai_combat` / `run_hit_reaction` /
  `run_hacking` stay green.
- Don't change existing weapon defs, the damage library, the AI brain's goal logic, plasmids,
  hacking, the encounter, or the HUD's existing rows. The chill movement-speed touch must be
  a multiplier/clamp only — no movement-mode changes, no floating enemies.
- Real numbers from `weapons-config` / the decompiled `.uc`; every invented value gets a
  `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md` — smallest correct change.
- **Partial is fine**: Beam mode + Chemical Thrower (Burning only) + Crossbow def + the
  verify, with Electric/Freeze beam variants and the slot keys noted TODO — as long as it
  compiles and every existing `run_*` verify stays green.
