---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C3, plasmids round 2 — Incinerate + Telekinesis on the `UShockPlasmid` framework shipped
in `920b193`. Goal: prove the framework generalises past Electro Bolt without touching its core.

## Context (already shipped, do not rewrite)
- `UShockPlasmid` base (`ShockPlasmid.{h,cpp}`): `EveCost` / `CastCooldown` / `ETargetingMode`,
  virtual `Cast(AShockPlayer*, const FHitResult& Aim)`, `static ResolvePlasmidClass(FName)`.
- `AShockPlayer`: `CurrentEve`/`MaxEve`, `ConsumeEve`/`RefillEve`, `EquippedPlasmids[3]`,
  `ActivePlasmidSlot`, `EquipPlasmid(cls, slot)`, `CastActivePlasmid()` (EVE + cooldown +
  `PerformPlasmidAimTrace`), `GetActivePlasmid()`.
- `UShockElectroBoltPlasmid` — the reference implementation (trace → `ApplyDamage` +
  `ABaseShockAI::ReactToPlasmidStun` + water 2×/chain via `AShockWaterVolume`).
- `ABaseShockAI`: `ReactToHit` (a20), `ReactToPlasmidStun` (c3), `HitReactRemaining`.
- `UShockPhysicsLibrary` (a12): `ApplyImpulse(Target, Impulse, bVelChange)`,
  `ApplyRadialImpulse(...)`, `SetActorPhysicsFrozen(Target, bFrozen, bForceSim)`,
  `FindActorByLabel`.
- `UShockDamageLibrary::ApplyDamage` / `ApplyRadialDamage`.
- Real EVE costs (decompiled): Incinerate `BioAmmoCost=8` (`IncinerationAbility.uc`),
  Telekinesis `BioAmmoCost=2.5` (`TelekinesisAbility.uc`). Damage is native
  (`IncinerationStimuliSet`) — PLAUSIBLE.

## Do
1. **Burning status on `ABaseShockAI`** (mirror the plasmid-stun pattern): `float BurningRemaining`,
   `float BurningDps`, `AActor* BurningInstigator`. `Ignite(float Seconds, float Dps, AActor*)`
   sets/refreshes the timer. In the combat tick (or a dedicated `TickStatusEffects(Dt)` called
   from the same place `HitReactRemaining` is decremented), while `BurningRemaining > 0`: tick
   `ApplyDamage(this, BurningDps * Dt, BurningInstigator, "Burning")`, decrement, small mesh
   flash / `BIOSHOCK_BURNING ai=<n> remaining=<s>` log throttled to ~1/s. Clear on death.
   Do NOT touch `ReactToHit` / `ReactToPlasmidStun` / the a9 FSM / the c2 brain goal logic.
2. **`UShockIncineratePlasmid`** (`extends UShockPlasmid`): `PlasmidName="Incinerate"`,
   `EveCost=8`, trace-targeted. On pawn hit → `ApplyDamage` (~10 PLAUSIBLE burst) + `Ignite`
   (~4s @ ~6 dps, PLAUSIBLE) + orange debug spark. **Oil-slick synergy** mirroring water:
   if the aim hit or target overlaps an `AShockOilSlickVolume` (new, copy `AShockWaterVolume`
   almost verbatim — `bIsOil`), ignite the whole slick: every pawn in it takes the burst and
   burns, and the slick is consumed (one-shot `bIgnited` flag, longer burn). Log
   `BIOSHOCK_PLASMID name=Incinerate eve=8 hit=<n> oil=<0/1>`.
3. **`UShockTelekinesisPlasmid`** (`extends UShockPlasmid`): `PlasmidName="Telekinesis"`,
   `EveCost=2.5`, `ETargetingMode::Trace`. Stateful (the plasmid instance holds the grab):
   - Cast with nothing held → trace for a physics-simulating actor (or a small "grabbable"
     `AShockGrabbableActor` stand-in you spawn in the verify) within range → `SetActorPhysicsFrozen`
     + record it as `HeldActor`. While held, `AShockPlayer` (or the plasmid via a tick hook it
     registers) keeps `HeldActor` ~200uu in front of the camera each frame.
   - Cast with something held → unfreeze + `UShockPhysicsLibrary::ApplyImpulse` along the aim
     dir × a launch speed (~1500 PLAUSIBLE); if it strikes a pawn within a short time/þdistance,
     `ApplyDamage` (~15 PLAUSIBLE). Clear `HeldActor`.
   - EVE is spent on the grab, not the throw (or a small amount on both — match
     `TelekinesisAbility.uc` if the decompiled body says; else PLAUSIBLE: grab only).
   Log `BIOSHOCK_PLASMID name=Telekinesis eve=2.5 action=<grab|throw> hit=<0/1>`.
   If a per-frame "hold in front of camera" hook is too invasive for `AShockPlayer`, a simpler
   PLAUSIBLE stand-in is fine: freeze in place on grab, throw from wherever it is — note it.
4. **Wire**: `ResolvePlasmidClass` += `"Incinerate"` / `"Incineration"` → Incinerate,
   `"Telekinesis"` / `"TelePlasmid"` → Telekinesis. `EquipStarterWeapon` also puts Incinerate
   in slot 1 and Telekinesis in slot 2 for the slice. Add a **plasmid-cycle key** (`Tab` or
   `E`) → `AShockPlayer::CycleActivePlasmid()` (next non-null slot), bound in
   `setup_playable_slice.py` (new `plasmid_cycle_key_mapping` step). HUD: show the active
   plasmid name next to the EVE bar.
5. **`run_plasmid.py` / `verify_plasmid.py`**: extend (don't replace the Electro Bolt cases).
   Incinerate: cast at an AI → burst damage + health keeps dropping over the next ~2s of
   ticks (burning), then stops; oil case → all pawns in the slick ignite. Telekinesis:
   grab a spawned grabbable (it freezes), re-cast → it moves / a nearby pawn takes damage;
   grab with no EVE → no-op. `Success - N error(s)`.
6. `docs/FULL_GAME_CONVERSION.md` C3: add Incinerate + Telekinesis to the plasmid bullet,
   list what's still PLAUSIBLE and the plasmids still missing (Winter Blast, Security Bullseye,
   Enrage, Insect Swarm, Sonic Boom, Cyclone Trap, Target Dummy, Hypnotize).

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py`) + one C3 doc bullet. No `src/**`, `tests/**`.
  No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged**: `run_game_possess.py` still logs possess + slice with
  **health 100 → 75, fire=1, failures []** (warm the cook with a direct `-game` launch first,
  then verify). `run_plasmid` (Electro Bolt cases) / `run_ai_brain` / `run_ai_combat` /
  `run_hit_reaction` / `run_weapon_def` stay green.
- Electro Bolt behaviour, the damage library, the c2 brain, the encounter, weapons, and the
  HUD's existing rows are untouched — you're adding two plasmids + one AI status + two volume
  types, nothing else.
- Real EVE costs (8, 2.5). Every other number gets a `PLAUSIBLE` comment.
  `docs/ENGINEERING_RULES.md`.
- **Partial is fine**: Incinerate + burning status + oil synergy, with Telekinesis reduced to
  the freeze-in-place PLAUSIBLE stand-in (or noted TODO) — as long as it compiles and every
  existing verify stays green.
