---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C3 — inventory & consumables: first-aid kits, EVE hypos, world pickups, and (stretch)
ammo-type switching. Builds on the health / EVE / weapon-def work already shipped.

## Context (already shipped, do not rewrite)
- `AShockPawn` (base of `AShockPlayer`): `CurrentHealth` / `MaxHealth`, `ApplyAuthoredDamage`.
- `AShockPlayer`: EVE pool (`CurrentEve` / `MaxEve` / `EveHypoAmount=50` / `RefillEve` /
  `ConsumeEve`), inventory stand-in (`TMap<FName,int32> InventoryStacks` +
  `AddStackToInventory(FName, int32)` / `RemoveStackFromInventory` / `GetInventoryStack`),
  holster `WeaponSlots[8]`, HUD (`UShockHudWidget` — health bar, EVE bar, ammo panel, weapon
  name, plasmid name).
- `AShockWeapon` + `UShockWeaponDef::Resolve` (7 weapons + camera). `bEnforceAmmo`,
  `RoundsInMagazine` / `ReserveAmmo` / `MagazineSize`, `AddReserveAmmo(int32)`,
  `TryReloadEquippedWeapon`. a15 built the ammo model; `AShockAmmoPickup` already exists.
- `ABaseShockAI::Ignite` (burn DoT), the a20 hit-react, `UShockDamageLibrary::ApplyDamage`.
- `weapons-config` (`bioshock-tool weapons-config`, do NOT touch src) — per weapon an
  `AvailableAmmoTypes` list, each with a `DamageStimuliSetName` and resolved stimuli
  (type/amount/chance): e.g. Pistol → Pistol Rounds `GenericPiercing 40`, AP Pistol Rounds
  `ArmorPiercing 40`, Antipersonnel `AntiPersonnel 40`; Machine Gun → MG Rounds 40, AP Auto 30.
- `tmp/uc_shockgame/` — `FirstAidKit*.uc`, `EveHypo*.uc` / `Hypo*.uc`, `Ammo*.uc`,
  `HealthStation*.uc` (heal amounts, max carry) where the `defaultproperties` carry them.

## Do
1. **Consumables on `AShockPlayer`**:
   - `Heal(float Amount)` — clamp to `MaxHealth`, no-op at full. `int32 MaxFirstAidKits`
     (PLAUSIBLE ~9), `int32 MaxEveHypos` (PLAUSIBLE ~9) — carry caps applied in
     `AddStackToInventory` for those two item keys (`"FirstAidKit"`, `"EveHypo"`).
   - `bool UseFirstAidKit()` — if `GetInventoryStack("FirstAidKit") > 0` and health < max:
     `RemoveStackFromInventory("FirstAidKit", 1)`, `Heal(FirstAidHealAmount)` (PLAUSIBLE full
     heal, or a fixed ~60 — label it). Log `BIOSHOCK_CONSUMABLE item=FirstAidKit health=<h>`.
   - `bool UseEveHypo()` — if stack > 0 and EVE < max: consume 1, `RefillEve(EveHypoAmount)`.
     Log `BIOSHOCK_CONSUMABLE item=EveHypo eve=<e>`.
   - Optional PLAUSIBLE auto-use: if `bAutoFirstAid` (default false) and a damage event drops
     health below `AutoFirstAidThreshold` and a kit is held → `UseFirstAidKit()`. Off by
     default so no verify/slice behaviour changes.
2. **`AShockConsumablePickup`** (AActor): `EPickupKind` { FirstAidKit, EveHypo, Money, Ammo },
   `Amount`, sphere overlap → on an `AShockPlayer` overlap, apply:
   FirstAidKit/EveHypo → `AddStackToInventory`; Money → a `PlayerMoney` int on the player
   (`AddMoney` / `GetMoney`, PLAUSIBLE); Ammo → `AddReserveAmmo` on the active weapon (or a
   named weapon). Destroy on pickup, `BIOSHOCK_PICKUP kind=<k> amount=<n>` log. Headless
   `PickupForVerify(AShockPlayer*)` that runs the same effect without needing real overlap.
3. **HUD**: show first-aid-kit and EVE-hypo counts (small, near the health/EVE bars) and the
   money total. Reuse the existing widget style.
4. **Input**: `UseFirstAid` → a key (e.g. `Q`? taken — use `Z`), `UseEveHypo` → `X`. Add the
   mappings in `setup_playable_slice.py` (extend a step or a new one).
5. **Slice**: in `EquipStarterWeapon` / possess, give the player 1 FirstAidKit + 1 EveHypo so
   the keys do something, and spawn one `AShockConsumablePickup` (FirstAidKit) near the
   encounter behind a `bEnableSlicePickup` (default **false**) so the possess verify is
   untouched. **The slice still opens on the TommyGun, one hit 100 → 75, and the player still
   starts at full health.**
6. **(Stretch) Ammo-type switching**: `UShockWeaponDef` gets `TArray<FShockAmmoType>`
   (`Name`, `Damage`, `EBeamStatus`-style `OnHitStatus` None/Burning/ArmorPierce/AntiPersonnel,
   `ReserveAmmo`). `AShockWeapon::SelectAmmoType(int32)` / `CycleAmmoType()` swaps the active
   `HitscanDamage` + a per-type reserve pool + an on-hit effect (ArmorPierce = ignore an
   `ArmorMitigation` if any / +mult PLAUSIBLE; AntiPersonnel = +mult vs non-`bIsRobotic` AI
   PLAUSIBLE; Incendiary = `Ignite` on hit). Pistol/MachineGun/Shotgun get their real
   ammo-type damage from `weapons-config`. `WeaponAmmoCycle` → a key (`V`). If this is too
   much for one pass, **skip it and note it TODO** — the consumables half is the deliverable.
7. `run_inventory.py` / `verify_inventory.py` — headless: player at 50 health + 1 kit →
   `UseFirstAidKit` heals + consumes the kit; at full health → no-op, kit kept; 0 kits →
   no-op. EVE hypo: at 40 EVE + 1 hypo → refills, consumes. `AShockConsumablePickup`
   (`PickupForVerify`) adds the stack / money / ammo. Carry cap: adding past `MaxFirstAidKits`
   clamps. (If stretch done: `SelectAmmoType` swaps damage; AP round vs a normal round differ;
   the default ammo type reproduces the base weapon damage.) `Success - N error(s)`. Use the
   `verify_plasmid.py` teardown pattern.
8. `docs/FULL_GAME_CONVERSION.md` C3 inventory bullet: what shipped, PLAUSIBLE numbers, TODOs
   (U-Invent, Gene Banks, ADAM / Gene Tonics, Vita-Chambers vs kits, ammo crafting, the money
   economy / vending machines, whichever of ammo-types you deferred).

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`) + one C3 doc bullet. No `src/**`, `tests/**`.
  No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged**: player starts full health / full EVE / TommyGun active, one hit
  100 → 75. `run_game_possess.py` still logs possess + slice pass, failures []. The slice
  pickup + auto-first-aid are OFF by default. All existing `run_*` verifies stay green —
  including every damage one (`run_weapon_*`, `run_plasmid`, `run_ai_*`, `run_hit_reaction`,
  `run_hacking`, `run_research_camera`).
- Don't change base damage, the AI, plasmids, hacking, the research multiplier, weapon defs
  (except *adding* the optional `AmmoTypes` array), or the HUD's existing rows.
- Real numbers from `weapons-config` / decompiled `.uc`; every invented value gets a
  `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md`.
- **Partial is fine**: `Heal` + `UseFirstAidKit` + `UseEveHypo` + `AShockConsumablePickup` +
  the verify, with money / HUD counts / ammo-types noted TODO — as long as it compiles and
  every existing `run_*` verify stays green.
