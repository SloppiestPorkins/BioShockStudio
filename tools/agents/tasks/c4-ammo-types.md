---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C4 — ammo-type switching for the hitscan/shotgun weapons. Deferred twice (c4-weapons-2,
c3-inventory) as a stretch; do it now as its own slice. Pistol, Machine Gun (TommyGun), Shotgun
each get their real alternate ammo types with real numbers from `weapons-config`.

## Context (already shipped, do not rewrite)
- `UShockWeaponDef` (UDataAsset): `FireMode` (Hitscan/Projectile/Melee/Shotgun/Beam), `Damage`,
  `PelletCount`/`PelletSpreadDeg`, etc. `Resolve(FName)` has TommyGun/Wrench/GrenadeLauncher/
  Pistol/Shotgun/ChemicalThrower/Crossbow.
- `AShockWeapon::ApplyDef` copies def fields onto the weapon; `FireAt` dispatches
  `FireAtHitscan`/`FireAtShotgun`/etc., both read `HitscanDamage` for the shot.
- Status effects already built and reusable: `ABaseShockAI::Ignite(seconds, dps, instigator)`
  (burn), `ReactToPlasmidStun(duration, instigator)` (stun/shock), `ApplyChill(seconds)`
  (slow). `UShockDamageLibrary::ApplyDamage(target, amount, instigator, damageType)`.
- Real numbers (`bioshock-tool weapons-config`, do NOT touch src) — per weapon, per ammo,
  resolved stimuli:
  - Pistol: Pistol Rounds `GenericPiercing 40` (current default) / Armor-piercing
    `ArmorPiercing 40` / Antipersonnel `AntiPersonnel 40`.
  - Machine Gun (TommyGun def): MG Rounds `GenericPiercing 40`(*) / Antipersonnel Auto
    `AntiPersonnel 18` / Armor-piercing Auto `ArmorPiercing 30`. (*TommyGun's shipped def
    damage is 25, slice-tuned — keep the base round at the existing 25, scale variants
    relative to the 40-baseline ratio or use the raw config numbers, your call, PLAUSIBLE
    either way — just say which.)
  - Shotgun: 00 Buck `GenericPiercing 35` (current) / Electric Buck `Electric 35` + `Shocked`
    / Exploding Buck `Explosive 49` + `Heat 1` + `Burning 6`.

## Do
1. **`FShockAmmoType`** (USTRUCT): `Name` (FName), `Damage` (float), `EAmmoEffect` (None /
   ArmorPiercing / AntiPersonnel / Electric / Incendiary / Explosive), `ReserveAmmo` (int32,
   its own pool — switching ammo types does not share reserve). Add
   `TArray<FShockAmmoType> AmmoTypes` to `UShockWeaponDef`; `Resolve("Pistol")`,
   `Resolve("TommyGun")`, `Resolve("Shotgun")` populate 2-3 entries each from the table above
   (index 0 = the current default, unchanged).
2. **`AShockWeapon`**: `TArray<FShockAmmoType> AmmoTypes` + `int32 ActiveAmmoTypeIndex` (copied
   from the def in `ApplyDef`, each type gets its own `ReserveAmmo` bucket — a
   `TArray<int32> AmmoReserves` parallel array, or a `TMap<FName,int32>`, your call).
   `CycleAmmoType()` — advance to the next type with reserve > 0 (or just advance; wrapping
   with 0 reserve is fine, it'll dry-fire), refill `ReserveAmmo`/`MagazineSize`-facing fields
   from the new type's numbers, does **not** touch `RoundsInMagazine` (still-chambered rounds
   stay the old type until the mag empties — PLAUSIBLE, note if you simplify to
   "swap instantly"). `HandleAmmoCycleInput()` bound to a key.
3. **On-hit effect in `FireAtHitscan` / `FireAtShotgun`** (the two fire paths these three
   weapons use): after `ApplyDamage`, if the victim is an `ABaseShockAI` and the active ammo
   type has an effect:
   - `AntiPersonnel` → PLAUSIBLE bonus multiplier vs "organic" targets (everything in the
     slice qualifies for now — note the "vs mechanical" split as TODO) — e.g. ×1.3 damage
     already folded into `Damage` per the table, so this may just be the base damage; only
     add a *behavioural* effect if you have one (e.g. slightly longer stagger). If there's no
     extra behaviour beyond the damage number, say so and skip a no-op branch.
   - `ArmorPiercing` → same: mostly a damage-number effect already in the table; add a
     PLAUSIBLE armor-ignore behaviour only if a mechanical/armored target concept exists
     (it doesn't yet in the slice) — otherwise just the number.
   - `Electric` → `ReactToPlasmidStun(~1s, instigator)` (PLAUSIBLE shorter than Electro Bolt's
     2s), and if the target is in water (`AShockWaterVolume::IsActorInWater`) apply the
     Electro Bolt water-chain pattern (reuse, don't duplicate — call into
     `UShockElectroBoltPlasmid`'s chain helper if it's exposed, or a small shared static).
   - `Incendiary` → `Ignite(~3s, ~5dps, instigator)` PLAUSIBLE (reuse the Incinerate tuning
     as a reference, don't rewrite the burn system).
   - `Explosive` → PLAUSIBLE small radial tick via `UShockDamageLibrary::ApplyRadialDamage`
     around the impact point (small radius ~150uu) in addition to the direct hit.
   Log `BIOSHOCK_AMMO_TYPE weapon=<def> type=<name> effect=<e>` on cycle,
   `BIOSHOCK_AMMO_EFFECT type=<e> target=<n>` when an effect fires.
4. **Slice**: no change to starting loadout numbers — index 0 (the existing default ammo) must
   still be what `EquipStarterWeapon` hands out, so **the slice stays 100 → 75 on one hit**.
   Bind `AmmoTypeCycle` to a key (`C`, or note if taken) in `setup_playable_slice.py`.
5. `run_ammo_types.py` / `verify_ammo_types.py` — headless: `Resolve("Pistol")` has 3 ammo
   types with the table's numbers; `CycleAmmoType` moves index + swaps reserve; firing the
   Electric type at a pawn in water triggers the chain (reuse the water-chain verify pattern);
   firing Incendiary ignites the target (burn ticks, matches the `Ignite` contract already
   verified by `run_plasmid`); firing Explosive does extra radial damage to a second nearby
   pawn; the default (index 0) ammo type reproduces today's base damage exactly — Pistol 40 /
   TommyGun (slice value) / Shotgun per-pellet unchanged. `Success - N error(s)`. Use the
   `verify_plasmid.py` teardown pattern (guarded `_destroy_all` + reset per section).
6. `docs/FULL_GAME_CONVERSION.md` C4: tick ammo-type switching for Pistol/MachineGun/Shotgun;
   note Crossbow/GrenadeLauncher/ChemicalThrower ammo variants still TODO, and the
   organic-vs-mechanical split for AntiPersonnel/ArmorPiercing as a fidelity gap.

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`) + one C4 doc edit. No `src/**`, `tests/**`.
  No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged at the default ammo type**: `run_game_possess.py` still logs
  **100 → 75, fire=1, failures []** (I run the `-game` possess at a checkpoint — you need
  `-CleanModule` + headless `run_*` only). `run_weapon_def` / `run_weapon_slots` /
  `run_weapon_beam` / `run_plasmid` / `run_ai_brain` / `run_ai_combat` / `run_hacking` /
  `run_research_camera` / `run_inventory` stay green.
- Don't touch Crossbow / Grenade Launcher / Chemical Thrower defs, the AI, hacking, research,
  inventory, level travel, or the HUD's existing rows. Reuse `Ignite` / `ReactToPlasmidStun` /
  the water-chain pattern — do not fork new copies of that logic.
- Real numbers from `weapons-config`; every invented value (durations, dps, radii) gets a
  `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md` — smallest correct change.
- **Partial is fine**: `FShockAmmoType` + `Resolve` populating the 3 weapons + `CycleAmmoType`
  + at least the Electric and Incendiary effects wired + the verify, with ArmorPiercing/
  AntiPersonnel/Explosive behaviour reduced to "damage number only, no extra effect" (clearly
  noted, not silently dropped) — as long as it compiles and every existing `run_*` verify
  stays green.
