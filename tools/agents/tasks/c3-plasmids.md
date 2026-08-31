---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C3 first slice of `docs/FULL_GAME_CONVERSION.md`: the plasmid system + Electro Bolt.
Framework first, one working plasmid, placeholder tuning labelled PLAUSIBLE.

## Context
- Decompiled: `tmp/uc_shockgame/Plasmid.uc` → `ActivePlasmid.uc` → `ElectricBolt.uc`
  (`FriendlyName="Electro Bolt"`, "STUNS both man and machine, DEVASTATING against enemies in
  WATER"). Numbers are sparse in `defaultproperties` — mostly in `Plasmids.ini` (`config(Plasmids)`)
  and the `ElectricBolt*Ability.uc` classes (levels 0-3). `src/` already has
  `PlasmidConfig.cs` / `bioshock-tool plasmids-config` for the *shop* metadata (do NOT touch src).
- Runtime today: `AShockPlayer` (health, weapon, no EVE). `UShockDamageLibrary::ApplyDamage`.
  `ABaseShockAI` + `UShockAIBrain` with a `HitReactAbility` stagger (c2). Aggro hook
  `NotifyAggroFromPlayer`. `ActionEquipPlasmid` / `ActionUnEquipAllPlasmids` are record-only stubs.

## Do
1. **`AShockPlayer` EVE**: `CurrentEve` / `MaxEve` (~100), `EveHypoAmount`, `bInfiniteEve`
   (default false). `ConsumeEve(float) -> bool`, `RefillEve(float)`. HUD (`UShockHudWidget`)
   shows EVE under health — small, same style.
2. **`UShockPlasmid`** (UObject base): `PlasmidName`, `EveCost`, `CastCooldown`,
   `ETargetingMode` (Instant / Trace / Self / AoE), `virtual bool Cast(AShockPlayer* Caster,
   const FHitResult& Aim)`. `AShockPlayer` gets `EquippedPlasmids[3]`, `ActivePlasmidSlot`,
   `EquipPlasmid(TSubclassOf<UShockPlasmid>, int32 Slot)`, `CastActivePlasmid()` (checks EVE +
   cooldown, does the aim trace, calls `Cast`, spends EVE).
3. **`UShockElectroBoltPlasmid`**: trace-targeted. On a pawn hit — `ApplyDamage` (~15, PLAUSIBLE)
   + trigger the target AI's stagger (reuse c2 `HitReactAbility` / a20 `ReactToHit` — a "stunned"
   window, longer than a normal flinch, ~2s) + a debug spark. **Water synergy**: if the aim hit
   or the target is tagged/overlapping a `bIsWater` volume/actor, double the damage and chain to
   other pawns within a radius (PLAUSIBLE ~400uu). Log `BIOSHOCK_PLASMID name=ElectroBolt
   eve=<cost> hit=<n> water=<0/1>`.
4. **Wire the actions**: `ActionEquipPlasmid::ApplyInWorld` (the c1 virtual) → find the player,
   `EquipPlasmid` the named class into the slot. `ActionUnEquipAllPlasmids` → clear the array.
   Map `"ElectroBolt"` / `"ElectricBolt"` name → `UShockElectroBoltPlasmid`.
5. **Input + slice**: bind a key (`Q` or `F`) → `CastActivePlasmid`. In
   `AShockGameMode::EquipStarterWeapon` (or possess), also give the slice player Electro Bolt in
   slot 0 with a small EVE pool so it's testable. Add the Reload-style mapping in
   `setup_playable_slice.py` (`ActionName="Plasmid"` → `Q`).
6. **Pull real numbers where cheap**: grep `Plasmids.ini` (via the game install path used
   elsewhere) and `ElectricBolt*Ability.uc` for EVE cost / damage / stun / level scaling; use
   what's found, PLAUSIBLE-label the rest, list the gaps in the C3 doc section.
7. `run_plasmid.py` / `verify_plasmid.py` — headless: equip Electro Bolt, cast at an AI →
   EVE drops by cost, AI takes damage + is stunned (attack interrupted longer than a flinch);
   cast with no EVE → no-op; cast on cooldown → no-op; water case → 2x + chain. `Success - N`.
8. `docs/FULL_GAME_CONVERSION.md` C3: tick the plasmid-framework + Electro Bolt slice, list the
   tuning gaps.

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`) + one C3 line. No `src/**`, `tests/**`. No
  commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- Do NOT change the damage numbers on weapons, the AI brain's goal logic, the encounter, or
  the possess path. `run_game_possess.py` must still log `BIOSHOCK_SLICE_OK` + `BIOSHOCK_POSSESS_OK`
  (run the `-game` launch directly once to warm the cook, then verify). `run_ai_brain` /
  `run_ai_combat` / `run_hit_reaction` stay green.
- One plasmid. Don't build Incinerate/Telekinesis/etc. — note them as the next C3 slice.
- Every invented number gets a `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md`.
- **Partial is fine**: EVE + `UShockPlasmid` base + Electro Bolt (no water chain) + the equip
  action wired + a passing verify, with water-synergy and input binding noted TODO.
