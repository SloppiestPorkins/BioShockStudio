---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C3, plasmids round 3 — Winter Blast + Insect Swarm + Enrage on the `UShockPlasmid`
framework (`920b193`, extended in `6baa3c0`). Same rule as rounds 1-2: generalise the framework,
do NOT touch its core, Electro Bolt / Incinerate / Telekinesis behaviour, the damage library,
the c2 brain goals, the encounter, weapons, HUD rows.

## Context (already shipped, do not rewrite)
- `UShockPlasmid` base (`ShockPlasmid.{h,cpp}`): `EveCost` / `CastCooldown` / `ETargetingMode`,
  virtual `Cast(AShockPlayer*, const FHitResult& Aim)`, virtual `GetCastEveCost()` /
  `EnforcesCastCooldown()`, `static ResolvePlasmidClass(FName)`.
- `AShockPlayer`: `CurrentEve`/`MaxEve` (100), `ConsumeEve`/`RefillEve`, `EquippedPlasmids[3]`,
  `ActivePlasmidSlot`, `EquipPlasmid(cls, slot)`, `CastActivePlasmid()` (EVE + cooldown +
  `PerformPlasmidAimTrace`), `GetActivePlasmid()`, `CycleActivePlasmid()` (`Tab`).
- `UShockElectroBoltPlasmid` — reference impl. Its shared static
  `ApplyElectricStunAndWaterChain(...)` (added in c4-ammo-types) is the pattern for
  "plasmid effect reusable by an ammo type".
- `ABaseShockAI` status effects (mirror these — do NOT touch them):
  `ReactToPlasmidStun(Seconds)` + `PlasmidStunRemaining`; `Ignite(Seconds, Dps, Instigator)` +
  `BurningRemaining` + `TickStatusEffects(Dt)`; `ApplyChill(Mult, Seconds)` (c4-weapons-3 beam
  Freeze — 0.4x speed via `TickCombatMovementSpeed`); `ReactToHit` (a20); `HitReactRemaining`.
  All decremented/ticked from one place (`TickStatusEffects` / the combat tick).
- `UShockAIBrain` on `ABaseShockAI` (`bUseBrain` default true): goal/ability selection,
  `NotifyAggroFromPlayer`, target selection. `EShockDeviceAllegiance` { Neutral, Hostile,
  Friendly, Disabled } + `AShockSecurityDevice::IsOpposingSide` model from c3-hacking /
  c3-hacking-2 (Friendly fights `ABaseShockAI`).
- `UShockPhysicsLibrary` (a12): `ApplyImpulse` / `ApplyRadialImpulse` /
  `SetActorPhysicsFrozen(Target, bFrozen, bForceSim)` / `FindActorByLabel`.
- `UShockDamageLibrary::ApplyDamage` / `ApplyRadialDamage` (honour invincibility; the ONE
  damage path).
- `AShockWaterVolume` / `AShockOilSlickVolume` — trigger-volume + per-pawn effect pattern to
  copy if a new volume is needed (it isn't for this task).
- Real EVE costs (decompiled `tmp/uc_shockgame/`): Winter Blast **`BioAmmoCost=13`**
  (`IcicleAssaultAbility.uc` — BioShock's Winter Blast is class `IcicleAssault`), Insect Swarm
  **`BioAmmoCost=8`** (`InsectSwarmAbility.uc`). Enrage — no ability file with a cost survived
  decomp; **PLAUSIBLE ~8**. All damage/duration numbers are native stimuli sets → PLAUSIBLE.

## Do
1. **Frozen-solid status on `ABaseShockAI`** (new, alongside `ApplyChill` — chill is a slow, this
   is a hard freeze): `float FrozenSolidRemaining`, `AActor* FrozenInstigator`.
   `FreezeSolid(float Seconds, AActor* Instigator)` sets/refreshes. While `FrozenSolidRemaining
   > 0`: movement fully stopped (zero the combat move like `bToldToWait`, do NOT permanently
   flip that flag — use a dedicated gate), attack/brain tick suppressed, `SetActorPhysicsFrozen`
   on the mesh if simulating, blue mesh tint / `BIOSHOCK_FROZEN ai=<n> remaining=<s>` throttled
   ~1/s. Decrement in `TickStatusEffects`. **Shatter**: if the AI takes any `ApplyDamage` while
   `FrozenSolidRemaining > 0`, apply a large PLAUSIBLE shatter multiplier (~3x) to that hit and
   log `BIOSHOCK_SHATTER ai=<n>`. Clear on death / when timer elapses.
2. **`UShockWinterBlastPlasmid`** (`extends UShockPlasmid`): `PlasmidName="WinterBlast"`,
   `EveCost=13`, `ETargetingMode::Trace`, short cone/radius PLAUSIBLE. On cast: small burst
   `ApplyDamage` (~5 PLAUSIBLE) + `FreezeSolid(~4s PLAUSIBLE)` to every `ABaseShockAI` in a
   short forward cone (PLAUSIBLE ~45deg, ~600uu — Winter Blast is close-range AoE). Light-blue
   debug. Log `BIOSHOCK_PLASMID name=WinterBlast eve=13 frozen=<n>`.
3. **`UShockInsectSwarmPlasmid`** (`extends UShockPlasmid`): `PlasmidName="InsectSwarm"`,
   `EveCost=8`, trace-targeted. On cast: spawn one `AShockInsectSwarm` actor (new — a simple
   homing effect actor, NOT an `ABaseShockAI`) at the aim hit / nearest enemy AI:
   - Self-ticks (`Tick` or an `AdvanceForVerify(Dt)` like `AShockProjectile`): tracks its
     current victim (nearest `ABaseShockAI` that is not Friendly-to-player, re-pick if it dies),
     applies `ApplyDamage(victim, SwarmDps * Dt, Instigator, "InsectSwarm")` (~4 dps PLAUSIBLE)
     and forces the victim's brain off the player — reuse `ReactToPlasmidStun(short)` each tick,
     or add a lightweight `DistractFrom(AActor*)` hook that makes the brain ignore the player
     and swat (PLAUSIBLE; note which you did). Lifetime PLAUSIBLE ~6s
     (`InsectSwarmProjectile.uc` scales `InsectSwarmLifespan_Bonus` off a base — base not in
     decomp), then `Destroy` + `BIOSHOCK_SWARM_END`.
   - Does NOT target the player or player-Friendly AI.
   Log `BIOSHOCK_PLASMID name=InsectSwarm eve=8 victim=<n>`.
4. **`UShockEnragePlasmid`** (`extends UShockPlasmid`): `PlasmidName="Enrage"`, `EveCost=8`
   (PLAUSIBLE), trace-targeted, `AShockProjectile`-delivered if easy (decomp has
   `EnrageProjectile extends ShockProjectile`) else hitscan trace — your call, justify. On pawn
   hit: for `EnrageDuration` (~12s PLAUSIBLE) the struck `ABaseShockAI` treats other
   `ABaseShockAI` as hostile and the player as neutral — reuse the brain's target selection /
   the `IsOpposingSide` allegiance idea (add an `bEnraged` + `EnragedRemaining` on the AI,
   ticked in `TickStatusEffects`; while set, `UShockAIBrain` picks the nearest *other* AI as
   target and does not aggro the player). Revert cleanly on expiry. Log
   `BIOSHOCK_PLASMID name=Enrage eve=8 target=<n>` + `BIOSHOCK_ENRAGE_END ai=<n>`.
5. **Wire**: `ResolvePlasmidClass` += `"WinterBlast"`/`"IcicleAssault"` → WinterBlast,
   `"InsectSwarm"` → InsectSwarm, `"Enrage"` → Enrage. These are slots beyond the 3 the slice
   grants — **bump `EquippedPlasmids` to 6 slots** (BioShock has 6 active-plasmid slots) and
   have `CycleActivePlasmid` skip nulls as it already does. `EquipStarterWeapon` grants
   WinterBlast slot 3, InsectSwarm slot 4, Enrage slot 5 for the slice (Electro Bolt still slot
   0 → cast parity unchanged). HUD active-plasmid name row already exists — no HUD change.
6. **`run_plasmid.py` / `verify_plasmid.py`**: extend, do NOT replace existing cases. Add a
   section per plasmid:
   - WinterBlast: cast at 2 AIs in the cone → both `FrozenSolidRemaining > 0` + move speed 0;
     an AI hit while frozen takes ~3x → `BIOSHOCK_SHATTER`; timer elapses → unfrozen, speed
     restored.
   - InsectSwarm: cast → swarm spawns, victim AI health drops over ticks, victim stops
     damaging a nearby player dummy; swarm expires → damage stops, actor gone.
   - Enrage: cast at AI-A with AI-B nearby → AI-A damages AI-B (not the player) for the
     duration; expiry → AI-A reverts (no longer damages AI-B, re-aggros player on sight).
   Use the `_destroy_all` guarded-teardown pattern + per-section `spawned = []` (the fix from
   c3-plasmids-2). `Success - N error(s)`.
7. `docs/FULL_GAME_CONVERSION.md` C3 plasmid bullet: tick Winter Blast + Insect Swarm + Enrage;
   remaining plasmids TODO: Security Bullseye, Sonic Boom, Cyclone Trap, Target Dummy (decomp
   has `DecoyHuman*`), Hypnotize; and note frozen-solid/swarm/enrage durations + damage are
   PLAUSIBLE (native stimuli sets).

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py` only if you add a key — you shouldn't need one,
  `Tab`-cycle already covers 6 slots) + one C3 doc bullet. No `src/**`, `tests/**`. No
  commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged**: `bEnableSliceSecurity` / `bEnableSliceTurret` / `bEnableSlicePickup`
  stay untouched and off; the 3-enemy encounter count and `BIOSHOCK_SLICE_OK enemy=SliceEnemy0`
  are untouched. `run_game_possess.py` still logs possess + slice **health 100 → 75, fire=1,
  failures []** (warm the cook with a direct `-game` launch first, then verify — I run the
  `-game` possess at the checkpoint, you need `-CleanModule` + the headless `run_*` only).
  `run_plasmid` (existing cases) / `run_ai_brain` / `run_ai_combat` / `run_hit_reaction` /
  `run_weapon_def` / `run_weapon_slots` / `run_weapon_beam` / `run_hacking` / `run_security` /
  `run_research_camera` / `run_inventory` / `run_level_travel` / `run_ammo_types` stay green.
- Do NOT touch: `UShockPlasmid` core, Electro Bolt / Incinerate / Telekinesis, `ApplyChill` /
  `Ignite` / `ReactToPlasmidStun` existing bodies, `UShockDamageLibrary` math (add a shatter
  multiplier at the *call site* / via a pre-mult hook, not by changing `ApplyDamage`'s formula
  — or if a hook is cleanest, gate it so it's identity unless `FrozenSolidRemaining > 0`), the
  c2 brain goal list, the encounter, weapons, HUD rows, `SetSecurityAlarmOn`.
- Real EVE costs: Winter Blast 13, Insect Swarm 8. Enrage 8 and every duration/damage/radius
  gets a `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md` — smallest correct change.
- **Partial is fine**: Winter Blast (freeze-solid + shatter) + Insect Swarm (spawn, homing
  DoT, distract) fully working, with Enrage reduced to "struck AI stops aggroing the player for
  the duration" (the other-AI-targeting half noted TODO) — as long as it compiles and every
  existing verify stays green.
