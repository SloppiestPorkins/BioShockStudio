# Vita-Chamber death and respawn

## Runtime result

Status: **VERIFIED SOURCE / RUNTIME REQUIRES HUMAN CAPTURE**

`ResurrectionStation` now imports as `AShockVitaChamber`. The two `1-Medical` records are:

| label | source actor | manifest location | shipped machine mesh |
|---|---|---:|---|
| `ResStation_Foyer` | `ResurrectionStation0` export 11304 | `(-16744, 1887.9994, 7698)` | `Resurrection` export 7302 |
| `ResStation_Surgery` | `ResurrectionStation2` export 13812 | `(-31584.004, 3480.002, 8074)` | `Resurrection` export 7302 |

These values are **CONFIRMED_BYTES** through the real `1-Medical.ue5-level.json` manifest. Both
records also resolve the class-default skeletal mesh `ResStationAnim` (export 23538). The current
level exporter supplies that as a reference rather than an imported animated rig, so the slice
draws the shipped `Resurrection` static mesh, adds an active cyan machine glow and overlap volume,
and represents materialisation with a short high-intensity glow pulse.

## Shipped sequence

The following is **CONFIRMED_EXTERNAL** from the decompiled UnrealScript in
`tmp/uc_shockgame/ShockPlayer.uc` and `BaseResurrectionStation.uc`:

1. `ShockPlayer.PrepareToDie` stops firing/ability use, cancels forced movement and zoom, closes
   containers, pushes `NullInput`, hides/interupts the hands, quits Havok and stores
   `BaseResurrectionStation.GetClosestStation(self)`.
2. `ShockPlayer.Dying` waits `ResurrectionDelay=4.8000002`, closes every station door and then
   transitions through the death UI to `Dead`.
3. `BaseResurrectionStation.ResurrectShockPlayer` moves the same player pawn to the selected
   station's `PlayerStart` bone, closes its doors, applies the bone rotation, restores health,
   optionally consumes the configured credit cost, calls `PrepareToResurrect`, pushes the
   `InResurrectionStation` input context and triggers `ResurrectedPlayer`/`WasResurrected`.
4. `ShockPlayer.PrepareToResurrect` reinitialises Havok, restores EVE to its configured floor,
   extinguishes fire, calls `SpawningManager.ResetAIAggressionTowards(self)`, restores UI/hands and
   records that the player used a Vita-Chamber.

The UE5 slice follows that order at its available level of fidelity: lethal authored damage fires
one death notification, disables input/movement, ragdolls a player body when one with a physics
asset exists, fades to black, waits 4.8 seconds, moves the same pawn, restores its vitals, fades in,
and grants two seconds of invulnerability. It does not reload or reconstruct the world.

## Selection and restore values

- Health is **50% of max**. `BaseResurrectionStation.defaultproperties` sets
  `ResurrectionHealthPercentage=0.5`; resurrection adds
  `min(MaxHealth * percentage, ResurrectionHealthMax)` from zero. Its default max is 9999, so the
  cap does not affect the slice.
- EVE is raised to a **75% of max floor**, not blindly added. `ShockPlayer.defaultproperties` sets
  `EveBarPercentageToRestoreOnRessurection=0.75`; `PrepareToResurrect` computes the amount missing
  from that floor and adds only that amount. EVE already above 75% therefore remains unchanged.
- Availability and activation are separate, matching `bIsAvailable` and `bIsActivated`.
  `ActionActivateResurrectionStation` changes activation;
  `ActionDisableOrEnableResurrectionStation` changes availability. **Fixed 28 Sept (audit B12):**
  the slice previously defaulted both Medical chambers active on import, which the audit flagged —
  the guide's machine chapter treats an un-activated chamber as ignored entirely. `AShockVitaChamber`
  now spawns `bActive=false`; it flips true the moment the player enters its own ~230uu
  `ActivationVolume` (self-contained proximity activation), and `1-Medical`'s own scripted
  `ResStation_FoyerActiveTV` / `ResStation_SurgeryActiveTV` trigger volumes independently fire
  `ActionActivateResurrectionStation` for the same effect — both paths were already present in the
  runtime and level export; only the importer's forced `set_active(True)` and the class default were
  wrong. A death with no chamber ever approached falls back to `RespawnStartSpot`
  (`ShockDeathRespawnHandler.cpp`), not the main menu — an already-known, separately tracked
  deviation. `bAvailable` (`ActionDisableOrEnableResurrectionStation`) is unaffected and still
  defaults true.
- `GetClosestStation` and `CanResurrectHere` are native and their bodies are absent from the
  decompiled UC. The exact shipped path-cost/line-distance algorithm is therefore **UNKNOWN**.
  The slice uses three-dimensional straight-line distance between the death point and each active,
  available chamber's player-start point. This is an explicit approximation, not a claim about the
  native implementation.
- The original `PlayerStart` bone transform is unavailable because only the machine's static mesh
  is imported. The slice uses a **PLAUSIBLE** explicit local start offset `(190, 0, 88)`: just
  outside the UC station's `CollisionRadius=175`, at the player capsule's standing half-height.

## Persistence and fallback

The same UE world remains loaded. Living `ABaseShockAI` instances keep their exact current health,
inventory and existence; only their dead-player target/navigation is cleared and a previously
alerted AI returns to Search (otherwise Idle). Doors, pickups, scripts and other world actors are
not reset.

The decompiled no-chamber branch presents the death screen and ultimately executes `open entry`;
the shipped save/reload operation behind that UI is outside the available UC. For this playable
slice the default, documented fallback is the level's authored `PlayerStart`, preserving the
current world. Setting `bReloadLevelOnDeath` opts into reloading the current map when no active
chamber exists.

`ResurrectionCreditCost` is config-backed and has no value in the decompiled class defaults.
Charging credits is therefore **UNKNOWN** and deliberately not invented for the slice.

## Effects and verification

The w1 `1-Medical` audio event table resolves
`BaseResurrectionStation.Alive -> machines_rez_idle`,
`OnActivated/OnDeactivated -> machines_rez_use`, and the two door events. It does not contain a
resolved `ResurrectedPlayer` response. Runtime first requests that authored event and falls back to
the located `machines_rez_use` machine cue; this limitation is explicit in code.

`tools/ue5/verify_vita_chamber.py` reimports Medical, requires the two source keys to be
`AShockVitaChamber`, kills a simulated player near one station, and checks nearest selection,
50% health, 75% EVE, brief invulnerability and unchanged pre-damaged AI health. It writes JSON to
`%TEMP%\vita_chamber_report.json`. Visual evidence is:

```powershell
powershell -Command "& tools/ue5/capture_shot.ps1 -Out `$env:TEMP\vita-respawn.png -SettleTicks 16 -Extra @('-bioshockshotdeathrespawn')"
```

The expected log line is
`BIOSHOCK_RESPAWN chamber=<name> dist=<x> healthRestored=<h> eveRestored=<e>`.
