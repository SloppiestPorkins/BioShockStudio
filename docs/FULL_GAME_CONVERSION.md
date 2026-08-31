# Converting BioShock to UE5 in full — the plan from here

> Supersedes the "prove one slice first" framing of `UE5_FULL_PORT_PLAN.md` §5 Phase 0.
> That precondition is now **met**: `1-Medical` runs end to end in UE5 — menu → possess →
> a 3-enemy encounter that navigates, shoots, staggers and dies → HUD → player death →
> respawn (`play_slice.ps1`, verified 31 Aug 2026: `possess=ok fire=1 health 100→75
> failures=[]`). The integration problems the old plan feared have been found and paid for
> on the slice. **So the strategy now flips to breadth: convert the whole game mechanically,
> then fix it as we go.**
>
> `UE5_FULL_PORT_PLAN.md` stays the reference for *why* (the three-layer argument, the
> decompiler-defect asymmetry, the risks). This document is *what next and in what order*.

---

## 0. The shape of the problem, restated

Three layers, and where each one actually stands:

| Layer | What it is | State | Method |
|---|---|---|---|
| **A — Assets** | meshes, skeletons, animations, textures, materials, BSP, lights | **decode complete; import proven on every rig category; only `1-Medical` actually imported** | mechanical — run the pipeline at scale |
| **B — Data** | class schemas, `defaultproperties`, placed actors, zones, script graphs, AI archetypes | **exporters built; manifest v4 carries it; script-graph import proven on Medical only** | mechanical — run at scale, fix per-map gaps |
| **C — Behaviour** | function bodies, the 103 `ShockAI` states, weapons, plasmids, hacking, the ~186 `Action*` classes | **~23 actions execute; a first-slice combat/weapon/damage/HUD/death runtime exists; the state machines are untouched** | hand-written against the decompiled source, census-ordered |

Layers A and B are a **grind, not research** — the hard decode work is done (see
`docs/research/open-questions.md`: almost everything CLOSED). Layer C is the multi-year part.

**"Make the runtime work"** is Layer C, phases C1–C5 below. It is not a separate track.

Permanent cut lines (do not spend time here): Havok joint limits (licence-blocked), the
18 door meshes that don't decode, exact original damage/balance numbers where a
`defaultproperties` value isn't present. Audio is blocked *pending* the data-location
find, not permanently — see D4.

---

## Phase A — Convert every map and asset into a real UE5 project

Goal: **you can open the UE5 project and walk through all 21 Rapture maps**, lit, textured,
with the placed static/skeletal geometry, even before any of it is a "game".

### A1. Batch level conversion — all 21 maps ✅ scaffolded (4-map proof, 31 Aug 2026)

**Status:** `tools/ue5/import_all_levels.py` + `run_import_all_levels.py` landed. Proof run on
four maps into `/Game/BioShockLevel/<map>` (geometry-only rig policy: `BIOSHOCK_IMPORT_RIGS=none`;
character rigs deferred to A2). Report: `%TEMP%/bioshock_import_all_levels.json`.

| Map | Imported | Idempotent re-run | Created / updated / skipped / unsupported | Notes |
|---|---|---|---|---|
| `0-Lighthouse` | ✅ | ✅ (~0 s second pass) | 1,865 / 436 / 0 / 395 | Matches prior single-map proof (1,274 instances, 0 mesh skipped). Unsupported = gameplay/dec FX classes → tagged `TargetPoint`s. |
| `1-Medical` | ✅ | ✅ (~0 s second pass) | 8,075 / 1,132 / 0 / 2,910 | Slice map; unsupported dominated by `Script`, spawners, FX emitters, Havok constraint stubs. |
| `2-Fisheries` | ✅ | — | 11,354 / 0 / 0 / 4,011 | Largest proof map (~11 min export+import). Extra unsupported vs Medical: door classes (`FishFreezerDoor*`), Fisheries-specific spawners/annotations. |
| `7-BossFight` | ✅ | — | 1,699 / 0 / 0 / 490 | Set-piece map; smallest unsupported tail of the four. |

**Decode gaps (expected, not blockers):** every map's `unsupported_classes` list is the same shape
— `Script`, `*Spawner`, `Light` (authored lights become real `PointLight`s; duplicate actor rows
still count unsupported), FX `Emitter`s, `Brush` CSG placeholders, navigation markers, Havok
constraint actors. No map failed import; no mesh-instance skips on these four.

**Lighting stopgap:** `--lighting-stopgap` (default on) applies `ShockGameMode::EnableDynamicLighting`
equivalent — force-no-precomputed-lighting, movable static meshes, fill directional + sky tagged
`BioShockSliceFill`.

**Full 21-map run needs:** ~hours unattended (export + import per map, largest ~10–15 min each);
run with editor closed; keep `BIOSHOCK_IMPORT_RIGS=none` unless doing A2 in the same pass.
`BIOSHOCK_IMPORT_RIGS=all` currently crashes UE 5.7 on large animation imports (narrowing assert
in `ImportAssetTasks` — recorded, not fixed here). One map per UE invocation recommended so a
crash does not lose the batch report.

Original scope:
`export-level` + `import_level.py` already do one map. This phase:
- A `tools/ue5/import_all_levels.py` that runs the pipeline for every shipped map into the
  project, idempotently, and writes a per-map report (`created / updated / skipped /
  unsupported`, decode-gap classes).
- Fix per-map decode gaps as they surface — most maps will "just work" (`0-Lighthouse`
  already imported clean at 1,274 instances / 0 skipped); the ones that don't get a
  targeted fix, not a rewrite.
- Bake or import-time lighting so each map is not pitch black (see D1 for the fidelity
  version; here, "good enough to see").

### A2. Bulk rig / character / weapon import
967 skeletal meshes + 8,668 static + 16,031 animations is ~140 GB fully expanded — the
plan has always deferred that as a lump. Do it as **tiers**:
- Tier 1 (do now): every character archetype the 21 maps actually *spawn* (~40–60 rigs),
  every weapon, every placed prop class. This is a bounded set from the level manifests.
- Tier 2 (later / on demand): the long tail. A content-addressed cache so a re-run is cheap.

### A3. Level-to-level travel
BioShock is a sequence of maps joined by bathyspheres and load-triggers. `ActionChangeLevel`
exists as a stub (currently skiplisted as "dangerous"). This phase makes it real:
- `AShockBathysphere` / load-trigger actors from the placed-actor data.
- `UGameplayStatics::OpenLevel` travel with player-state carry-over (health, EVE, inventory,
  plasmids, ADAM, research).
- A "New Game" flow: menu → `Welcome` (the plane-crash intro) → `1-Medical` → … in order.

### A4. Own the export — a persistent project, not the throwaway
Today everything targets `C:\Users\Jack\Documents\BioShockUE5` (the throwaway). Phase A
produces a **checked-in project skeleton** (`.uproject`, `Config/`, the plugin) plus a
`bioshock-tool export-ue5-project <dir>` that populates a fresh one reproducibly. This is
the `UE5_FULL_PORT_PLAN.md` §9 "app-facing export workflow" that was deliberately deferred
until the CLI import reproduced cleanly — it now does.

**Phase A exit:** a `BioShockUE5` project that opens, lists 21 maps, and lets you fly the
editor camera through any of them with geometry, materials and placeholder lighting.

---

## Phase B — Complete the data layer across all 21 maps

Layer B is built for Medical; this scales it.

### B1. Script-graph import on the 20 non-Medical maps
`export-script-actions` already runs clean on all 21 (`docs/research/interaction.md` §8:
3,932 scripts, 21,752 refs, 0 skipped). `import_scripts.py` is proven on Medical only. Run
it per map, record `nested_unmapped` / `unmapped_classes`, fix the mapper gaps (the last
census pass found 4 — `OrStatement`, `Hide/ShowNeedleElement`, `TrainingCondition`, fixed
`bb3fb2d`; expect a handful more across 20 maps).

### B2. AI spawner config → live spawns
`LevelSpawnerActorDocument` (global/initial/repopulation AI types, patrols, `SpawnZones`,
`Complete` flag) is in the v4 manifest and pinned for Medical's 19 `AggressorSpawner`s. This
phase makes `AShockAISpawner` actors spawn from that data on every map, on the real spawn
zones, with repopulation timing.

### B3. Archetype resolution — close the `UNKNOWN`
`OverriddenAiArchetypeNames` and `*AiTypes` are carried as raw name strings.
`AiArchetypeCatalog` resolves 267 shipped `AIArchetype` exports; the rest and the
resistance-set values live in `ConfigINI.IBF` (`IniBundle` reads it). Wire
`document.archetypes` + `Weapons.ini` `[*ResistanceSet]` → the `UShockAiArchetype` data
assets (`is_ranged`, health, mesh, loadout, resistances) for **all** archetypes, not just
Medical's 23.

### B4. `defaultproperties` → class defaults, game-wide
The class-schema exporter (Phase 2.1, done) emits every class's `defaultproperties` tree.
Phase B feeds those into the C++ classes' constructors / a data-asset per class, so
`RangedAggressor`'s collision size, `bPrefersRangedAttack`, damage-resistance-set, etc.
come from data rather than hand-typed constants. This is the bridge into Phase C.

**Phase B exit:** every map's scripts, spawners and archetypes are live data in the project;
opening any map and pressing Play spawns the right enemies in the right places (even if
their behaviour is still thin).

---

## Phase C — Make the runtime a game

The first-slice runtime (`BioShockRuntime`: combat FSM, hitscan weapon + ammo, damage
library, HUD, death/respawn, nav, hit reactions, ~23 actions) becomes the real thing.

### C1. Polymorphic action dispatch — stop editing the runner per leaf
There are ~199 `Action*` classes; ~100 already have `ApplyInWorld` overrides on
`UShockAction`, the rest inherit the base no-op (`applied=0`). **Done (2026-08):**
- `FShockActionContext` (`World`, `OwnerActor`, `Variables`, `Instigator`, `SourceLabel`)
  built once per leaf dispatch in `UShockScriptRunner::StepOne`.
- `UShockAction::ApplyInWorld(const FShockActionContext&)` — virtual, default `false`.
  Adding a leaf action = override only; flow control (Wait / If / Loop / For / variables /
  ExecuteScript / SendTriggerMessage) stays special-cased in the runner.
- Headless check: `run_script_action_vm.py` / `verify_script_action_vm.py`.
- **Still open:** handler *families* / data-driven registry for the remaining ~115 stubs
  (original “UShockActionVM” sketch below — census-ordered, not one class per handler).
- Keep the census order: the top 20 actions are 73% of all scripted behaviour, top 50 is
  90%.
- Latent actions (`Wait`, `FinishAnim`, latent `MoveTo`) → C++ coroutine-style tasks,
  not per-frame polling.

### C2. The AI brain — goals + abilities (architecture, corrected 31 Aug 2026)

**Tick (31 Aug 2026):** `UShockAIGoal`, `UShockAIAbility` base, `UShockAIBrain` on `ABaseShockAI`
(`bUseBrain=true`, FSM fallback when false). Ability set landed: `IdleAbility`, `PatrolAbility`
(PLAUSIBLE stub), `MoveToAbility`, `MeleeAttackAbility`, `RangedAttackAbility`, `FleeAbility`
(PLAUSIBLE stub), `HitReactAbility`. Slice combat migrated; `run_ai_brain.py` /
`verify_ai_brain.py` headless. Existing `run_ai_combat` / `run_ai_nav` / `run_hit_reaction` /
`run_game_possess.py` unchanged behaviour path.

**Reading the decompiled source changed the call.** `ShockAI` is *not* a big state machine —
`ShockAI.uc` has one `state` (`Dying`). The AI is **goal-oriented**: a `CharacterAI` holds an
**ability list** (`CharacterAI.addAbility_Class(Class'ShockAI.MoveToAction')`,
`HeadTrackingAction`, `FleeAction`, `MimicAction`, …), an `AI_Goal` names the current objective,
and an `achievingAction` (an `AIAction`/ability) works it. The `*Action` classes are the
behaviour units, and each is a small state machine. The decompiled *bodies* are degraded
(`function initAction(){}` — empty artifacts), so this is hand-written against the
hierarchy + ability lists + `defaultproperties` as spec, not a port of function bodies.

- **`UShockAIGoal`** — a named objective (`KillTarget`, `MoveTo`, `Patrol`, `Flee`, `Alert`,
  `Idle`) with parameters and a priority.
- **`UShockAIAbility`** — a behaviour that can achieve one or more goal types, with its own
  small state (Enter / Tick / Exit, latent-safe). First set: `MoveToAbility`,
  `MeleeAttackAbility`, `RangedAttackAbility`, `FleeAbility`, `PatrolAbility`, `IdleAbility`.
- **`UShockAIBrain`** (component on `ABaseShockAI`) — owns the ability list (seeded from the
  archetype / AI class defaults), picks the highest-priority satisfiable goal each think tick,
  runs the achieving ability. Perception feeds goals (see player → `KillTarget`; took damage →
  `KillTarget` the instigator; lost target → `Patrol`/`Idle`).
- **Migrate the a9 Idle/Chase/Attack FSM onto this**: Chase becomes `MoveToAbility` achieving
  `KillTarget`; Attack becomes `MeleeAttackAbility` / `RangedAttackAbility`. The slice enemies
  must fight exactly as they do now, just through the brain.
- Prove on the two slice enemies (melee splicer + Leadhead), then the Big Daddy, then the tail.
  Add abilities census-ordered — the ability list per AI class comes straight from its
  `addAbility_Class` calls in the decompiled `.uc`.

### C3. Player systems
Census/spec order, each its own sub-project:
- Health / EVE, first-aid kits, EVE hypos.
- **Plasmids** — **first slice (31 Aug 2026):** `UShockPlasmid` framework on `AShockPlayer`
  (`CurrentEve`/`MaxEve` ~100, `ConsumeEve`/`RefillEve`, 3 slots, `CastActivePlasmid` trace +
  cooldown + EVE spend). `UShockElectroBoltPlasmid` trace-targeted: `ApplyDamage` + ~2s plasmid
  stun via `ReactToPlasmidStun` / `HitReactAbility`, water 2× + chain through
  `AShockWaterVolume`. **Second slice (31 Aug 2026):** `UShockIncineratePlasmid` (EVE **8**,
  burst + `ABaseShockAI::Ignite` burn ticks, oil-slick synergy via `AShockOilSlickVolume`) and
  `UShockTelekinesisPlasmid` (EVE **2.5** on grab, freeze-in-place + throw impulse stand-in via
  `AShockGrabbableActor` / `UShockPhysicsLibrary`). `CycleActivePlasmid` + `Tab` cycle key;
  HUD shows active plasmid name beside EVE. `ActionEquipPlasmid` / `ActionUnEquipAllPlasmids`
  wired; slice possess equips slots 0–2; `Plasmid` → `Q` in `setup_playable_slice.py`.
  `run_plasmid.py` / `verify_plasmid.py` headless. **Tuning from shipped data:** Electro Bolt
  EVE **15** (`ElectricBoltAbility.uc`); Incinerate EVE **8** (`IncinerationAbility.uc`);
  Telekinesis EVE **2.5** (`TelekinesisAbility.uc`). **PLAUSIBLE / gaps:** bolt HP damage (~15),
  stun seconds (~2), Incinerate burst (~10) / burn (~4s @ ~6 dps), Telekinesis throw speed (~1500)
  / throw damage (~15) / no per-frame camera hold, oil burn multiplier, cast cooldown (~0.5s),
  water chain radius (~400uu), native stimuli factories (no damage in `.uc`), level scaling,
  VFX/audio, machine short-out. **Still missing:** Winter Blast, Security Bullseye, Enrage,
  Insect Swarm, Sonic Boom, Cyclone Trap, Target Dummy, Hypnotize.
- **Hacking — first slice (31 Aug 2026):** `EShockDeviceAllegiance` + `AShockSecurityDevice`
  (perception cone/LoS, `ApplyAuthoredDamage`, security-shutdown / alarm range boost) and
  `AShockTurret` (hitscan via `AShockWeapon`, idle yaw sweep). `AShockPlayer::TryHackDevice`
  deterministic skill check (`HackSkill` default **0.7**); `HackTool` → `H` in
  `setup_playable_slice.py`. `ActionHackTurret` / `ActionSpawnTurret` / `ActionHackSecuritySystem`
  wired to real devices; `ActionStartSecurityAlarm` / `StopSecurityAlarm` set the player alarm
  flag Hostile devices read. Slice turret behind `bEnableSliceTurret` (**false** default).
  `run_hacking.py` / `verify_hacking.py` headless. **From shipped data:** detection range
  **3000** (`ShockAI.uc` ViewDistance), turret fire rate **3/s** (`TurretMiniGun.uc`
  BaseFireRate), attack range **3000** (`TurretMiniGunAmmo.uc`). **PLAUSIBLE:** turret HP **40**,
  hitscan damage **8**, detection half-angle **90°**, alarm range ×**1.5**, hack-fail self-damage
  **5**, idle sweep **90°/s** (`Turret.uc` YawSpeed). **TODO (next slices):** pipe minigame /
  hack-tool UI, `AShockSecurityCamera` + alarm-summons-bot, `AShockSecurityBot`, RPG turret
  variants, U-Invent auto-hack darts, `ActionUnHackSecuritySystem` device restore, security-bot
  spawn actions.
- **Inventory / consumables — first slice (31 Aug 2026):** `AShockPlayer::Heal`,
  `UseFirstAidKit` / `UseEveHypo` (inventory stacks keyed `"FirstAidKit"` / `"EveHypo"`,
  carry caps **9** each PLAUSIBLE), `AddMoney` / `GetMoney`, optional `bAutoFirstAid` (**false**
  default). `AShockConsumablePickup` (`FirstAidKit` / `EveHypo` / `Money` / `Ammo` overlap +
  `PickupForVerify`). HUD row `Kit N  Hypo N  $M` beside health/EVE. `UseFirstAid` → **Z**,
  `UseEveHypo` → **X** in `setup_playable_slice.py`. Slice possess grants 1 kit + 1 hypo;
  world kit pickup behind `bEnableSlicePickup` (**false** default). `run_inventory.py` /
  `verify_inventory.py` headless. **PLAUSIBLE:** kit heal **60**, hypo refill **50** (existing
  `EveHypoAmount`). **TODO:** U-Invent UI, Gene Banks, ADAM / Gene Tonics, Vita-Chambers vs kits,
  ammo crafting, vending / money economy, ammo-type switching (AP / anti-personnel / incendiary per
  `weapons-config`), Health Stations.
- **Level travel — first slice (1 Sep 2026):** `UShockCarryState` on `UShockGameInstance`
  (`DefaultEngine.ini` `GameInstanceClass` via `setup_playable_slice.py`) survives
  `UGameplayStatics::OpenLevel`. **Captured fields:** `Health`, `MaxEve` / `CurrentEve`,
  `TArray<FShockCarriedWeapon>` (`DefName` or `ClassPath`, `Slot`, `Mag`, `Reserve`),
  `ActiveWeaponSlot`, `TArray<FShockCarriedPlasmid>` (`PlasmidName`, `Slot`),
  `ActivePlasmidSlot`, `TMap<FName,float> Research`, `TMap<FName,int32> Inventory`, `Money`,
  `ArrivalStartLabel`. `AShockGameMode::TravelToLevel` logs `BIOSHOCK_TRAVEL`; `PostLogin` /
  `ApplyArrivalLoadout` restores when `bHasPendingArrival` else unchanged `EquipStarterWeapon`
  (logs `BIOSHOCK_ARRIVED` on restore). `UShockActionChangeLevel::ApplyInWorld` wired.
  Hand-built `/Game/BioShockSlice/_TravelDest` map (`TravelDestStart`, `DestArrival`,
  `ReturnArrival` PlayerStarts) created by `setup_playable_slice.py`. `run_level_travel.py` /
  `verify_level_travel.py` headless (capture → restore; editor substitutes for OpenLevel).
  `AShockBathysphereStation` actor + unlock action stub; **Interact → F** mapping added but
  player-side interact hook still TODO. **TODO:** bathysphere route-map UI, save-on-travel to
  disk, per-level scripted intro beats, full 21-map import + travel graph, autosave on travel,
  real `0-Lighthouse` (or full map) destination instead of `_TravelDest`.
- Inventory, ammo types (AP / anti-personnel / incendiary per weapon), U-Invent, Gene Banks,
  the Research Camera, ADAM / Gene Tonics.

### C4. Weapons — all seven
Wrench, Pistol, Machine Gun, Shotgun, Grenade Launcher, Chemical Thrower, Crossbow, plus the
Research Camera and the Rivet Gun-adjacent bits. Each: fire modes, ammo types, the upgrade
stations.

- [x] **C4 slice — weapon defs + fire modes:** `UShockWeaponDef::Resolve` (TommyGun / Wrench /
  GrenadeLauncher / **Pistol** / **Shotgun** / **ChemicalThrower** / **Crossbow**) drives
  `AShockWeapon::ApplyDef`; hitscan (unchanged path), melee (Wrench), projectile +
  `AShockProjectile` (frag radial + Crossbow bolt), **shotgun pellet fan**
  (`EWeaponFireMode::Shotgun`, `PelletCount` / `PelletSpreadDeg`), **sustained beam**
  (`EWeaponFireMode::Beam`, `BeamTickInterval` / `BeamRange` / `EBeamStatus` — Napalm burn,
  Electric stun, Freeze chill). Slice TommyGun via def (25 dmg / 50 mag / 150 reserve).
  **All seven core weapons now have a def.** **`AShockPlayer` holster slots** (8-wide,
  `GiveWeaponByDef` / `SelectWeaponSlot` / `NextWeapon` / `PrevWeapon`); slice starts TommyGun
  active with Wrench / Pistol / Shotgun / Chemical Thrower / Crossbow in holster (slots 5–6).
  HUD shows active weapon name beside ammo. `run_weapon_def.py` / `verify_weapon_def.py`,
  `run_weapon_slots.py` / `verify_weapon_slots.py`, `run_weapon_beam.py` /
  `verify_weapon_beam.py` headless.
- [x] **C4 slice — Research Camera + per-archetype research:** `AShockResearchCamera` in holster
  slot 7 (`GiveWeapon` — no weapon def; `ResearchCamera.uc` uses film ammo, not hitscan defs).
  Photos score live `ABaseShockAI` subjects (centering + distance band + combat-target bonus;
  PLAUSIBLE thresholds `{0,100,300,700,1500}` vs UC per-track `ScoreRequired`). Research points
  keyed on `AITypeName`; `UShockDamageLibrary::ApplyDamage` multiplies player damage by
  `GetResearchDamageMultiplier` (PLAUSIBLE +10%/level). `run_research_camera.py` /
  `verify_research_camera.py` headless. **The C4 weapon list is complete (7 combat weapons +
  Research Camera).**
- **Still on inline `ConfigureHitscan` / `ConfigureAmmo`:** AI splicers (`BaseShockAI`), HUD ammo
  preview widget, slice encounter stand-in weapon — not `Resolve` yet.
- **Tuning gaps:** TommyGun slice values differ from weapons-config Machine Gun (40 dmg / 40 mag);
  spread not applied to hitscan traces; no upgrade stations;
  no ammo-type switching (chem Ionic/LiquidN / crossbow trap-incendiary bolts); **bolt retrieval
  TODO**; projectile gravity / mesh / sticky-RPG modes not ported.
- **Research Camera TODOs:** research rewards beyond the damage bonus (plasmid unlocks, one-time
  level-up item grants per UC `ResearchLevels[].AwardItemClass`), the research film / photo-subject
  variety (UC `CameraDamageFactory` centering/size/pose/dead/repeat scoring), upgrade stations,
  ammo-type switching (film types), HUD readout of centred-subject research level while camera is
  active.

### C5. The behaviour library — breadth then depth
Everything else `Action*` / native, worked from the census, most-used first, each verified
against the running game. This is the long pole and no tooling removes it — but by this
point the VM, the state machine and the data layer make each one small.

**Phase C exit:** you can start a New Game and play `Welcome` → `1-Medical` → `1-Welcome`
→ … through to the end, with real (if rough) enemy AI, working plasmids and weapons, hacking,
and the level-to-level story beats.

---

## Phase D — Fidelity

Runs *alongside* C once the game is playable end to end. Not blocking.

- **D1. Lighting & lightmaps.** The decode is done (39,288 descriptors, atlas binding on 20
  maps, `LayerLighting.hlsl` recovered — `docs/ROADMAP.md` Gate 0.3). Bring baked light into
  the UE5 maps properly instead of the dynamic-fill stopgap.
- **D2. Material graphs.** Panner / timeline / switch node values already copy onto the
  manifest; build the actual UE5 material graphs that consume them (water, force fields,
  screens, the `MaterialSwitch` chains).
- **D3. Animation.** Import the 16,031 `AnimSequence`s at scale (currently enemies slide —
  no anims), build the AnimBlueprints (locomotion blendspaces, upper/lower split, the
  weapon poses), wire `PlayAnimation` / scripted-hand animations for real.
- **D4. Audio.** Blocked on the data-location find (`docs/research/audio.md` §4). Placement
  is *ready* (`AmbientSound` / `SoundMarker` decoded). The day the FSB/bank location is
  found, this unblocks in bulk.
- **D5. Reflections, post, water, particles** — the Rapture look.

---

## How to run this — "fix as we go"

Every phase item is a task for `tools/agents/orchestrator.ps1`. The loop:

1. **Scaffold** — write the batch tool (`import_all_levels.py`, the VM skeleton, a state
   generator). One task.
2. **Run it wide** — over all 21 maps / all archetypes / the census head. It surfaces
   concrete gaps.
3. **Fan out the fixes** — one agent task per gap, in parallel worktrees, each with a
   headless verify.
4. **Land the green ones**, re-run wide, repeat until the gap list is dry.
5. **Play it** (`play_slice.ps1` generalised to `play_game.ps1`) and log what's wrong —
   that list is the next round.

Parallelism: Layer A/B tasks (Python, per-map) fan out freely. Layer C tasks touch
`BioShockRuntime` C++ and must be **serialised** (shared HostProject — see
`155d133`). Run non-C++ work alongside C++ work, not two C++ tasks at once.

Workers: `cursor` for `tools/ue5/**` + runtime, `codex` for `src/**` decode/exporter work
and report-only audits, local `qwen` for nothing multi-step (it can't drive these).

---

## Honest sizing

This is still, per `UE5_FULL_PORT_PLAN.md` §6, a **multi-year effort at hobby pace**. What
changes with this plan is the *order of visible payoff*:

- **Phase A** (weeks): the whole city is walkable in the editor.
- **Phase B** (weeks): every map spawns the right enemies and runs its scripts.
- **Phase C1–C2** (months): the AI actually fights across the game.
- **Phase C3–C5 + D** (years, tapering): plasmids, hacking, the full weapon set, animation,
  audio, the look.

"Done enough to play through" (rough AI, core plasmids, weapons, no audio) is a **Phase C2 +
partial C3/C4** milestone. "Faithful" is the whole thing and is a different project — decide
which one this is before Phase C3 (`UE5_FULL_PORT_PLAN.md` §6 "fidelity drift").

---

## Immediate next tasks (in order)

1. ~~`import_all_levels.py` + a first wide run~~ — **4-map proof done** (A1 above); full 21 next.
2. `import_scripts.py` wide run (B1) — the 20 non-Medical maps, record the gaps.
3. The Tier-1 archetype/weapon bulk import (A2) — bounded set from the manifests.
4. `UShockActionVM` skeleton + the state-setter and AI-command handler families (C1).
5. ~~`import_all_levels` lighting-stopgap~~ — shipped in A1 (`--lighting-stopgap`, default on).

1 and 2 are pure Python, fan out immediately, and turn "convert the game" into a concrete
gap list — same move that Phase 2.1/2.2 made for the AI.
