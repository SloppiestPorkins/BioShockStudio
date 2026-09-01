---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C3 hacking round 2 — security camera + security bot + alarm-summons-bot. Builds directly
on `AShockSecurityDevice` / `AShockTurret` from `a3c5575`. Pipe minigame / hack-tool UI still TODO.

## Context (already shipped, do not rewrite)
- `EShockDeviceAllegiance` { Neutral, Hostile, Friendly, Disabled } + `AShockSecurityDevice`
  (`ShockSecurityDevice.{h,cpp}`): perception cone (`DetectionRange` 3000, `DetectionHalfAngleDeg`
  90), LoS via `ECC_Visibility`, `Health` + `ApplyAuthoredDamage` / `OnDeviceKilled`,
  `ApplySecurityShutdown(Duration)` (Disabled then restore), `GetEffectiveDetectionRange`
  (×`AlarmRangeMultiplier` 1.5 when `AShockPlayer::IsSecurityAlarmOn()`), `IsOpposingSide`
  (Hostile fights player, Friendly fights `ABaseShockAI`), `CanDetectActor`, virtual
  `TickDevice(float)`, `static FindByLabel` / `ForEachDevice`. `AShockSecurityDevice(RootMesh)`.
- `AShockTurret : AShockSecurityDevice` — `TickDevice` acquires nearest opposing pawn in
  cone+LoS, hitscans it via a spawned `AShockWeapon` on `FireInterval`.
- `AShockPlayer`: `SetSecurityAlarmOn(bool, FName)` / `IsSecurityAlarmOn()` (`bSecurityAlarmOn`),
  `TryHackDevice(AShockSecurityDevice*, float difficulty01)` (deterministic `HackSkill` 0.7),
  `UnHackDevice`. `HackTool` → `H`.
- `ABaseShockAI` — the AI base (perception a9, brain c2, `NotifyAggroFromPlayer`,
  `ConfigureIdentity`, `Ignite`/`ReactToPlasmidStun`/`ApplyChill`). `ABaseShockAI` spawns
  today via `AShockGameMode::SpawnSliceEnemy` / `SpawnSliceEncounter`.
- Actions: `ShockActionStartSecurityAlarm` (`Player->SetSecurityAlarmOn(true, label)`),
  `ShockActionStopSecurityAlarm`, `ShockActionSpawnSecurityBot`,
  `ShockActionActivateSecurityBot`, `ShockActionMakeBotsAttack` (stubs — wire the bot ones),
  `ShockActionAssignNextSecurityBotSpawnLocation`.
- `AShockGameMode::bEnableSliceTurret` (false) pattern for slice-only spawns.
- Decompiled: `tmp/uc_shockai/SecurityCamera.uc`, `SecurityBot*.uc`, `MinimumSecurityBot.uc`,
  `Camera*Goal/Action.uc` — hierarchy + `defaultproperties` (detection times, spotlight cone,
  bot health/speed) where present.

## Do
1. **`AShockSecurityCamera : AShockSecurityDevice`**: no weapon. `TickDevice` — if it detects
   an opposing pawn (reuse `CanDetectActor`), accumulate `AlertBuildupSeconds`; once it
   exceeds `AlertThreshold` (PLAUSIBLE ~1.5s — check `SecurityCamera.uc` for a real value),
   raise the alarm: find the local `AShockPlayer`, `SetSecurityAlarmOn(true, DeviceLabel)`,
   log `BIOSHOCK_CAMERA_ALERT label=<n>`, and request a bot spawn (step 3). Decay the buildup
   when LoS breaks. A hacked (Friendly) camera does the reverse — alerts on `ABaseShockAI`,
   and does NOT raise the player alarm. Disabled = inert. Optional spotlight cone: a
   `USpotLightComponent` toggled by `ActionToggleSecurityCameraSpotlight` (wire that stub) —
   cosmetic, note if fiddly.
2. **`AShockSecurityBot : ABaseShockAI`** (mobile — subclass the AI, not the device, so it
   gets the brain + navigation for free) OR `: AShockSecurityDevice` with movement bolted on
   — **your call, but justify it**. It must: patrol/idle when no target, chase + attack the
   player when the alarm is on or it directly perceives them (reuse the c2 brain / a9 chase +
   a hitscan `AShockWeapon` like the turret, PLAUSIBLE `BotHealth` ~30, faster than a splicer),
   despawn (or go Disabled) `BotLifetimeSeconds` (PLAUSIBLE ~30s) after the alarm clears.
   `BIOSHOCK_BOT_SPAWN` / `BIOSHOCK_BOT_DESPAWN` logs. If it subclasses `ABaseShockAI`, make
   sure it does NOT get caught by the slice encounter's enemy counting / verify (tag it or
   check `SpawnSliceEncounter` only counts its own spawns).
3. **Alarm → bot spawn** on `AShockGameMode` (or a lightweight `UShockSecuritySubsystem`):
   when `SetSecurityAlarmOn(true, ...)` fires (hook it), spawn up to `MaxActiveBots` (PLAUSIBLE
   2) `AShockSecurityBot`s at the nearest `AShockBotSpawnPoint` / `ATargetPoint` /
   `AssignNextSecurityBotSpawnLocation` label, or near the alerting camera if none. Wire
   `ActionSpawnSecurityBot` / `ActivateSecurityBot` / `MakeBotsAttack` → the same path.
   When the alarm clears (`SetSecurityAlarmOn(false)` / `ApplySecurityShutdown` on the
   security system), despawn the bots.
4. **Hacking interactions**: `TryHackDevice` already works on any `AShockSecurityDevice` —
   confirm it flips a camera to Friendly (stops it alerting on the player). A hacked *bot*
   (via `ActionHackTurret`-style or a new path) becomes `Friendly`/allied and fights
   `ABaseShockAI` — reuse the turret allegiance model. `ActionHackSecuritySystem`'s
   `ApplySecurityShutdown` should already Disable cameras + bots (it does `ForEachDevice`) —
   verify bots are covered (if a bot is an `ABaseShockAI` not a device, add it to the
   shutdown sweep).
5. **Slice**: behind a new `bEnableSliceSecurity` (default **false**) — spawn one
   `AShockSecurityCamera` watching the encounter approach; when it alerts, a bot spawns. Off
   by default so `run_game_possess` is unchanged.
6. `run_security.py` / `verify_security.py` — headless: a Hostile camera builds alert on a
   player in its cone → raises `IsSecurityAlarmOn` + spawns a bot; the bot chases + damages
   the player; hacking the camera (`TryHackDevice`, easy) stops it alerting on the player;
   `ActionHackSecuritySystem` / `ApplySecurityShutdown` Disables the camera AND the bot and
   stops the damage; alarm-clear despawns the bot; a killed bot → Disabled/despawned.
   `Success - N error(s)`. Use the `verify_plasmid.py` teardown pattern.
7. `docs/FULL_GAME_CONVERSION.md` C3 hacking bullet: tick camera + bot + alarm-summons-bot;
   remaining TODO: pipe minigame / hack-tool UI, RPG turret variants, U-Invent auto-hack
   darts, real bot navmesh patrol routes, camera spotlight visuals, `ActionUnHackSecuritySystem`.

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py` if a key/step) + one C3 doc bullet. No `src/**`,
  `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Slice unchanged**: `bEnableSliceSecurity` off by default → `run_game_possess.py` still
  logs the possess + slice pass, **100 → 75, fire=1, failures []** (I run the `-game` possess
  at a checkpoint — you need `-CleanModule` + headless `run_*` only). `run_hacking` /
  `run_ai_brain` / `run_ai_combat` / `run_hit_reaction` / `run_weapon_def` / `run_plasmid` /
  `run_ammo_types` / `run_research_camera` / `run_inventory` / `run_level_travel` stay green.
  If `AShockSecurityBot : ABaseShockAI`, the slice's 3-enemy encounter count and
  `BIOSHOCK_SLICE_OK enemy=SliceEnemy0` must be untouched.
- Don't change `AShockSecurityDevice` / `AShockTurret` core logic, `TryHackDevice`, the AI
  brain's goals, the damage library, plasmids, weapons, research, inventory, level travel, or
  the HUD's existing rows. New actors + an alarm→spawn hook + action wiring only.
- Real numbers from the decompiled `.uc` where present; every invented value gets a
  `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md` — smallest correct change.
- **Partial is fine**: `AShockSecurityCamera` (alert → alarm) + `AShockSecurityBot`
  (spawn on alarm, chase, damage, despawn on clear) + `TryHackDevice` confirmed on the camera
  + the verify, with the spotlight visuals / `MakeBotsAttack` niceties noted TODO — as long as
  it compiles and every existing `run_*` verify stays green.
