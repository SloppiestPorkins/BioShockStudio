Supersedes docs/archive/ROADMAP.md, docs/archive/FULL_GAME_CONVERSION.md, docs/archive/FULL_RUNTIME_PORT.md, docs/archive/UE5_FULL_PORT_PLAN.md, docs/archive/DUAL_AGENT_ROADMAP.md, docs/archive/UI_ROADMAP.md.

# Roadmap

For "what's actually landed, verified, and open as bugs right now", see **[`docs/STATUS.md`](STATUS.md)**.
This file is the forward-looking plan: the target, the systems, and what's still open, ordered by
priority. It does not repeat finished work item-by-item — see STATUS.md and `docs/QUALITY.md` for
the evidence behind any "done" claim.

## The goal

A 1:1, faithful port of BioShock 1 (Remastered assets) into UE5.7 — playable, not just imported:
real assets, real levels, real scripted behaviour, real AI, real weapons/plasmids/hacking, real UI,
eventually the Rapture look. **Faithful to the source** (the decompiled UnrealScript and the shipped
data), not to observed runtime behaviour — there is no way to instrument the original game to compare
against, so behavioural fidelity is implemented from the decompiled `.uc` as spec, judgement calls
recorded, not verified against a live oracle. This was confirmed as the goal directly by the user
(23 Aug 2026) and has not changed since.

Two things feed this port and are otherwise unrelated to each other:

1. **BioShockStudio**, the C# extraction/decode tool (`src/**`) that turns the shipped game's raw
   package bytes into meshes, skeletons, animations, textures, materials, levels and audio the UE5
   pipeline can consume. This side is **essentially done** — see "Asset & decode pipeline" below.
2. **The UE5.7 runtime** (`tools/ue5/**`, `tools/ue5/BioShockRuntime/` C++ plugin) that imports that
   data and reimplements BioShock's game logic by hand against the decompiled source. This is where
   almost all of the remaining work is.

## Three layers, and where each stands

| Layer | What it is | State |
|---|---|---|
| **A — Assets** | Meshes, skeletons, animations, textures, materials, BSP, lights | **Decode complete for the whole game; imported for all 21 maps.** |
| **B — Data** | Class schemas, `defaultproperties`, placed actors, zones, script graphs, AI archetypes, config INI | **Exporters built and run at scale; the script-graph VM is substantially real (not just recorded).** |
| **C — Behaviour** | Function bodies, the 103 `ShockAI` states, weapons, plasmids, hacking, the ~199 `Action*` classes | **Most of the top of the usage census now executes in-world. AI is goal/ability-based, not state-machine ported. The long pole.** |
| **D — Fidelity** | Lighting, materials/water/glass, particles, animation blending, the Rapture look | **Runs alongside C. Several passes landed (light shape, lightmaps, UI art); several visible gaps remain (see STATUS.md's live bug list).** |

Layers A and B are mechanical — extend what exists, run it wide, fix per-map gaps. Layer C is
hand-written against the decompiled source, prioritized by measured usage (the action-usage census
below): this is the multi-year part and no tooling shortcuts it. Permanent cut lines: Havok joint
limits (Havok licence prohibits the reverse engineering needed to recover them — declined twice,
stays declined), the 3–4 door meshes that don't decode, exact original balance numbers where no
`defaultproperties` value exists.

## Priority order, top to bottom

This list is deliberately short — one line of "what's next" per system. Detail follows in the
per-system sections below.

1. **Close out the w18 live-PIE bug list** — see STATUS.md's bug table. Concrete, scoped, blocking a
   clean human playtest.
2. **The scripting VM's remaining stubs — done, 29 Sept 2026.** Watchers, critical/immediate
   execution mode on level travel, `TestFact`'s boolean evaluation, and training-message HUD
   display all landed (`w20`, 28 Sept); `ActionEnableOrDisableTrainingMessages`'s mute gate — the
   one piece `w20` left out — landed 29 Sept (`verify_scripting_vm_stubs.py` 37/37). Only remaining
   item in this family: nested-loop critical-sub-action expansion during a travel flush (the flush
   walks the flat remaining run queue only; a real fix means simulating `ActionLoop`'s up-to-1000-
   iteration exit-condition semantics synchronously, which is materially bigger scope than the rest
   of this list — deliberately not attempted blind). **Not a gap, contrary to earlier wording
   here**: the quest state machine (`InitiateQuest`/`CompleteQuestObjective`/`CompleteQuest`/
   `FailQuest`/`GetActiveQuestNames`, `ShockPlayer.cpp` ~3112–3188) is real —
   `ShockStatusMenu.cpp:412` reads live state, not a stub list. Corrected 28 Sept 2026 after
   checking current code before dispatching w20.
3. **Script-graph import on the 20 non-Medical maps — done, 29 Sept 2026.** Ran
   `import_scripts_all_maps.py` for real (never dispatched before): 20/20 succeeded, 0 unmapped
   top-level actions, 100 nested actions unmapped across 3 distinct classes out of many thousands
   mapped. Built `ActionSaveGame` (the best-scoped of the three, 3 occurrences); the other two need
   real systems priority 4/6 haven't built yet (an `Assassin` AI archetype;
   Research Camera photo storage) — see STATUS.md for the full breakdown. A new CLI verb,
   `export-level-manifest`, made running this batch practical at all (cut a real map's export from
   ~5.5 min to ~10s by skipping mesh/texture/cubemap writes script import never reads).
4. **AI**: generalize the goal/ability brain (`UShockAIBrain`) past the two slice archetypes to every
   placed archetype; close the remaining `Action*` handler families (state-setters, AI-command
   families) census-order. **First slice landed 29 Sept 2026**: real per-archetype ranged-weapon
   resolution (Grenadier/SMG/Pistol were all getting the same flat hitscan stand-in; also fixed a
   melee-splicer-flagged-ranged false positive in the same heuristic) — see STATUS.md. Still open:
   the brain/ability logic itself (`UShockAIBrain.cpp`) was already archetype-agnostic before this
   fix and needed no change; what's unverified is everything past Medical's 23 archetypes — the
   other 20 maps' archetype rosters are unaudited, and this pass only confirmed Pistol/SMG/
   Grenadier/Melee weapon-type resolution, not Shotgun/Crossbow/ChemicalThrower on an AI archetype.
5. **Content gaps with no system behind them yet**: ~~switches/levers as a dedicated actor~~ **done,
   29 Sept 2026** — `AShockSwitchActor` + `import_slice_switches.py`, all 10 of Medical's
   DoorSwitch/Switch/IncineratorSwitch/BathysphereSwitch/Med_MedicalGateSwitch/ChompersDentalButton
   actors are now real, interactive, message-dispatching props (see STATUS.md). Also **done, 30
   Sept 2026**: ~~NonPhysicalReactiveActor debris/set-dressing~~ — `import_slice_reactive_props.py`,
   all 54 of Medical's instances (TunnelBlock, CollapsedTunnel, broken glass, cremation props, ...)
   are now real, visible, `BlockAll`-collidable level geometry instead of invisible TargetPoints;
   confirmed not script-load-bearing (unlike switches, nothing gates on these labels), so this was a
   level-fidelity fix, not an unlocks-content one. Also **done, 30 Sept 2026**: ~~shootable/
   damageable reactive props~~ — `AShockDamageableProp` + `import_slice_damageable_props.py`, all
   17 of Medical's Padlock/dyn_grate64/NonPhysicalNonPathBlockingReactiveActor/OilSlick*_Reactive/
   TV_WallMounted instances now really react to a weapon hit and dispatch the MessageRAReacted
   scripts already gating on them (GatePadlock unlocks OpenSteinmanGate, KureAllGrate1 unlocks its
   own grate script, ...) — required extending `UShockDamageLibrary::ApplyDamage` and each
   `ShockWeapon.cpp` call site past their pawn-only assumption, not just a placement script (see
   STATUS.md). Also **done, 30 Sept 2026**: ~~InPlayerViewTrigger (look-at cutscene/tutorial
   gates)~~ — `AShockInPlayerViewTrigger` + `import_slice_in_player_view_triggers.py`, all 14 of
   Medical's instances now really detect the player looking at (or away from) them and dispatch
   the Scripts already gating on them (SteinmanIntro, Quarantine_PistolIntro, Ghost_TwoTwo,
   TrainingHackTurret, ...) — these had no line-of-sight/FOV logic behind them at all, so several
   of Medical's scripted narrative/tutorial beats were entirely dead, not degraded (see STATUS.md).
   Also **done, 30 Sept 2026**: ~~SecurityCrate_WallSafe/SecurityCrate_Safe unsearchable~~ — 5 real
   safes in Medical never matched `import_slice_pickups.py`'s own class-routing at all (not even as
   "unmapped"), now real `AShockSearchableContainer`s with real loot. Same pass also fixed the
   duplicate-collider bug (see the correctness-fix entry in STATUS.md) retroactively across the
   entire ~230-instance pickup/container economy. A follow-up task (`task_977a74fe`) is open to
   check whether stations/movers (doors, lifts) have the same duplicate-collider gap. Still open:
   Gene Bank tonics (no tonic system exists at all), U-Invent crafting components (runs against
   generic inventory stacks today).
   **Quests are not a gap** — see the "Inventory, economy, and player systems" section below; the
   state machine is real, only quest hint/objective text is missing.
6. **Fidelity pass**: water materials, glass, god rays, decal/particle gaps, weapon/plasmid icon art
   (never located in any SWF — brass ring + name only), the HUD liquid-fill material.
7. **Level-to-level travel at scale** — the carry-state mechanism works on one hand-built test map;
   the real 21-map bathysphere/load-trigger travel graph is unbuilt.
8. **The Gatherer/Protector ecology** (Little Sister harvest, Big Daddy protect/patrol/rage, the ADAM
   choice) — explicitly out of scope until the above lands; it is its own project-sized piece.
9. **Menus that are still stubs**: Options, Credits, Director's Commentary, Museum, Challenge Rooms.

---

## Asset & decode pipeline (BioShockStudio, the C# tool)

**Essentially complete.** All format-decode gates (package/Havok/mesh/material/texture/level/audio)
that this project tracked are closed or explicitly deferred by design (the Havok kDOP collision tail,
joint limits, `TextureCube` face order). Headline figures — 9,684 mesh exports (967 of them skeletal),
16,031 animations (0 decode failures), 14,328 materials, 31,106 textures, 21 maps' BSP/zones/portals/
actors, Havok ragdoll physics for 207 rigs — are measured and pinned by tests; see `docs/QUALITY.md`
for the current sweep and `docs/research/*.md` for the byte-level mechanism behind any one figure.
This side of the project is not where active work happens any more; treat further work here as
residual bug-fixing, not a track with its own roadmap.

**Bytecode / game logic decode**: `tools/uelib-bridge/` produces real UnrealScript source for 1,445
classes across 11 of 12 script packages, 0 hard failures (`Engine.U` doesn't decompile — a UELib
version-gating bug, mostly stock engine classes, not load-bearing so far). This decompiled source is
the specification the UE5 runtime work below is written against — never transpiled automatically
(see "The goal" above for why).

---

## UE5 level & asset import (Layer A/B mechanics)

**All 21 story maps are imported** into `/Game/BioShockLevel/*` with the current wall/UV/collision/
material pipeline, repaired (collision, lighting reach/exposure, PlayerStart snapping). A separate,
hand-curated slice, `/Game/BioShockSlice/1-Medical`, is the playable target for Layer C work and is
not the same asset as the raw import.

- **Character/weapon rigs**: every structurally distinct rig category (first-person weapon,
  mechanical door, static/rigid prop, humanoid enemy, quadruped, aquatic creature, enemy robot) has
  at least one verified member; the Tier-1 bounded set (every archetype the 21 maps actually spawn)
  is the next batch, the long tail is on-demand.
- **Script-graph export** (`export-script-actions`) runs clean on all 21 maps, 0 skipped. **Import**
  (`import_scripts.py`) is proven complete on `1-Medical` only (300 scripts, 1,463 actions mapped, 0
  nested-unmapped after the y-series fixes); the other 20 maps are unrun for the import half.
- **AI archetypes**: all 267 shipped `AIArchetype` exports plus the full `Spawning.ini`/`Weapons.ini`/
  `Ai.ini`/`Plasmids.ini` config bundle (`ConfigINI.IBF`, read via `IniBundle`) are decoded and on the
  level manifest. `UShockAiArchetype` data assets consume this for spawn-time tuning.
- **Lighting**: brightness/radius/falloff mapping done; `LightCone`/`LightType`/`LightEffect`/
  `LightPeriod` decoded from raw bytes and now drive real `SpotLight`/`DirectionalLight` shape and
  on/off or animated behaviour (landed 28 Sept 2026, see STATUS.md) — previously every light imported
  as an omnidirectional static `PointLight` regardless of its authored shape.
- **Still open**: cubemap `TextureCube` face-order assembly (`UNKNOWN`, low priority), a real UE5
  material *graph* for panner/timeline/switch-driven materials (values copy onto the manifest, nothing
  drives them at the graph level yet — this is most visible in water and force-field materials, see
  Fidelity below), an app-facing "export to UE5" workflow (deliberately deferred — product decision,
  not started).

---

## Scripting VM and the Action library

The event VM (`UShockScriptRunner` / `AShockScript` / `UShockScriptRegistry`) is a real, if partial,
implementation of `Scripting.Script`, not a stub that only records requests:

- **Done**: Wait (latent), If/nested If, Loop/For with nested bodies, VariableAssign/Increment/
  Decrement, ExitScript, message-triggered script start (`TriggeredBy`), a message queue while busy,
  `ActionSendTriggerMessage` → `DispatchMessage` under the sending script's own label, real message
  senders (`PawnDied`/`TookDamage`/`ReceivedInventory`/`AIWeaponFired`/`RAReacted` + trigger exit/
  radius relays), decoded and enforced `messageFilter` with carried message fields, shared `Global_`
  script variables, per-runner timers, `ScriptableMover` open/close messages and multi-match door
  triggers (the y6–y8 SDK-audit fixes, 25–27 Sept 2026).
- **Action classes**: every `Action*` class referenced in the 21-map probe (186 distinct classes) has
  at least a first-slice `UShockAction` (typed params, schema defaults, request-record). A large and
  growing share now genuinely change the world rather than just record intent — reflection
  (`SetProperty`/`GetProperty`/`PropertyTest`), visibility/collision, AI script control, items/HUD,
  world-sim (Havok force/pressure/damage volumes), the `EffectsSystem` subsystem
  (`ActionPlayEffect`/`StopEffect` actually spawn/track/stop a bundle now), shared damage and physics
  libraries used by both the runner and the weapons.
- **Deliberately still stubbed** (per the y8 audit): **watchers** (`ActionCreateWatcher`/Enable/
  Disable — a statement tree ticked by the subsystem, publishing on change), **critical/immediate
  execution mode** on level travel (`bIsGameCritical` actions should run synchronously before unload),
  and the quests/facts/training-message family (`AssertFact`/`RetractFact`, quest log, training UI).
  None of these are regressions — they were explicitly skipped in the most recent audit pass pending a
  concrete need.
- **Handler families not yet built as data-driven registries**: roughly the remaining long tail of the
  ~199 `Action*` classes beyond the census head — most-used-first is still the right order (the top 20
  actions cover ~73% of all scripted behaviour game-wide, top 50 ~90%).

## AI

The AI is **goal-oriented, not a state machine port** — `ShockAI.uc` itself has one `state` (`Dying`);
the real behaviour is an ability list per archetype (`CharacterAI.addAbility_Class(...)`) achieving a
current goal. The UE5 runtime mirrors that shape:

- `UShockAIGoal` (named objective + priority) and `UShockAIAbility` (Enter/Tick/Exit behaviour unit)
  on a `UShockAIBrain` component (`ABaseShockAI`, `bUseBrain` toggles it against an FSM fallback).
  Ability set landed: Idle, Patrol (stub), MoveTo, MeleeAttack, RangedAttack, Flee (stub), HitReact.
  The original a9 Idle/Chase/Attack FSM is migrated onto this for the two slice archetypes (melee
  splicer + Leadhead).
- **Navigation**: a runtime NavMesh via a player `NavigationInvokerComponent`; `-game` builds real
  tiles and enemies path around walls; straight-line direct-input remains the fallback when the
  navmesh isn't available (e.g. the headless `-Cmd` editor world).
- **Combat loop, hit reactions, archetype-driven spawning** (health/mesh/loadout/resistances from
  `document.archetypes`) are live and headless-verified.
- **Open, in priority order**: generalize the brain past the two proven archetypes to every archetype
  actually placed across all 21 maps; the remaining `Action*` families that are AI-facing (state-
  setters, AI-command handlers — the original "`UShockActionVM` skeleton" item); the Gatherer/
  Protector ecology (see below) is explicitly its own, later project.

## Weapons

**All seven core weapons plus the Research Camera have a real fire-mode definition** — Wrench
(melee), Pistol, Machine Gun (TommyGun), Shotgun (pellet fan), Grenade Launcher (projectile + radial),
Chemical Thrower (sustained beam with surface-status effects), Crossbow (projectile bolt) — driven by
`UShockWeaponDef::Resolve` → `AShockWeapon::ApplyDef`, with an 8-slot holster, ammo-type switching
(Electric/Exploding buck implemented; Incendiary wired for future types) and independent reserve
pools per ammo type.

**Open**: upgrade stations (none exist for any weapon), bolt retrieval (Crossbow), projectile gravity/
mesh/sticky modes not ported, TommyGun's slice tuning still disagrees with the shipped
`weapons-config` numbers (a known, tracked tuning gap, not a bug), AI splicers still configure hitscan/
ammo inline rather than through `Resolve`, Research Camera rewards beyond the flat damage-multiplier
bonus (plasmid unlocks, one-time level-up grants, the film/photo-subject scoring variety), ammo-type
fidelity for Crossbow/Grenade Launcher/Chemical Thrower (still TODO — Ionic/LiquidN/incendiary-trap
bolt variants).

## Plasmids

**Six implemented and tuned from shipped `defaultproperties`**: Electro Bolt, Incinerate,
Telekinesis, Winter Blast, Insect Swarm, Enrage — cycling, cooldown, EVE cost/spend, and
plasmid-specific effects (stun + water chain, burn + oil-slick synergy, grab/throw, freeze/shatter,
homing DoT swarm, other-AI-as-target aggro flip) are all live.

**Not implemented at all**: Security Bullseye, Sonic Boom, Cyclone Trap, Target Dummy (`DecoyHuman*`
in the decompiled source), Hypnotize. Several tuned values across the six that exist are `PLAUSIBLE`
placeholders rather than confirmed from shipped data (stun duration, burn DPS, throw speed/damage,
freeze duration/shatter multiplier, swarm DPS/lifespan, enrage duration) — see the plasmid research
note for which.

## Hacking and security

**Real, not a stand-in**: `AShockSecurityDevice`/`AShockTurret`/`AShockSecurityCamera`/
`AShockSecurityBot` with perception, alarm state, and a deterministic skill-check hack
(`AShockPlayer::TryHackDevice`); `UShockSecuritySubsystem` spawns/despawns bots off the alarm hook.
The hacking minigame is a real interactive UMG widget (difficulty-scaled board, flood-fill path, fluid
timer, hazard tiles, money buy-out, Auto-Hack Tool) bound to the same skill-check path.

**Open**: pipe tiles are text-labelled UMG shapes, not the game's pipe graphics (logic is complete,
art is not); RPG-variant turrets; U-Invent-driven Auto-Hack darts (Auto-Hack currently succeeds with
no tool check against inventory — a known, tracked gap, not a new regression); real bot navmesh
patrol routes (bots currently attack-only, no patrol/protect/return-home goal path); camera spotlight
polish; `ActionUnHackSecuritySystem` and a hacked-bot equivalent of `ActionHackTurret`.

## Inventory, economy, and player systems

**Live**: health/EVE, first-aid kits and EVE hypos (inventory stacks, HUD readout), money, consumable
pickups, a carry-state that survives `OpenLevel` (health, weapons, plasmids, research, inventory,
money) on one hand-built test map.

**Missing systems, not just missing content** — these need a system built, not a data fill:

- **Tonics.** No tonic system exists at all. The Gene Bank UI is plasmids-only.
- **Quests.** A real, if simple, state machine exists and is live (`InitiateQuest`/
  `CompleteQuestObjective`/`CompleteQuest`/`FailQuest`/`GetActiveQuestNames` on `AShockPlayer`,
  `ShockPlayer.cpp` ~3112–3188), consumed by the Status menu's Goals tab
  (`ShockStatusMenu.cpp:412`) — corrected 28 Sept 2026, this file previously said it was a stub.
  Still missing: quest *hint* text/objective descriptions beyond a bare name, and nothing in the
  script-actions import currently calls `InitiateQuest` from real Medical script data to prove the
  chain end-to-end against shipped content, not just headless verifies.
- **U-Invent crafting.** Runs against generic inventory stacks; there is no crafting-component bag
  (glue/rubber/screws/…) or recipe resolution.
- **ADAM economy / vending economy loop.** Money and ADAM are tracked scalars; the vending discount-
  when-hacked and Gatherer's Garden purchase flow are UI shells over that, not a real economy.

## Level travel

The mechanism works — `UShockCarryState` on the game instance survives `OpenLevel`, captures health/
EVE/weapons/plasmids/research/inventory/money, and `AShockGameMode::TravelToLevel` /
`ApplyArrivalLoadout` restore it on arrival — but it has only ever been exercised against one
hand-built test map (`/Game/BioShockSlice/_TravelDest`), not the real 21-map bathysphere graph.

**Open**: the real level-to-level travel graph over all 21 imported maps, `AShockBathysphereStation`
route-map UI, save-on-travel to disk, per-level scripted intro beats, a real `0-Lighthouse` (or
equivalent) destination in place of the synthetic `_TravelDest` map.

## Scripted sequences / cinematic AI

**Not started.** The `LatentAIAction` port (the AI-side puppet list — MoveTo/PlayAnim/FaceActor/Say/
Wait/EquipWeapon/SetPose that drives a pawn through a scene), the scene driver
(`ActionControlScriptedSequence`/`Cinematic{Enter,Exit,FadeView}`), and the actual Medical set-pieces
(the doctor-killer intro, the Steinman surgery, the first Big Daddy sighting behind glass) are all
unbuilt. The data for these is in the decoded scripts; this is pure Layer C hand-implementation work.

## Audio

**Runtime audio exists and is not a gap any more** — this contradicts a stale note that persisted in
`docs/ENGINEERING_RULES.md` (see STATUS.md's contradictions section). Weapon fire, footsteps, and
looping ambient sound (with distance falloff and a dedicated Ambient sound-mix class) are live in PIE.

**Open**: per-language routing, the `Chance`/`FilteredState` response-selection semantics (which
alternative wins at runtime is still engine-behaviour territory, deliberately undecided), music,
audio-diary playback (the Status → Messages tab is wired to nothing — "Audio diary collection is not
wired yet"), and locating every remaining effect-name-to-sample mapping (most resolve; a handful of
tail cases don't).

## UI

**Every BioShock UI screen has been recreated in UMG with the game's own decoded art** (SWF tag-512
DXT bitmap decode was the key unlock) and live data bindings: HUD, radial select, full weapon/plasmid
select screen, status/pause menus, all five station UIs (vending, Gene Bank, U-Invent, Gatherer's
Garden, combo lock), the hacking minigame widget, main menu/frontend (difficulty select, save/load
slots, loading screens), and a Deco-styled chrome pass across all of it.

**Open, in the gap list AUDIT_2026-09-06.md already named and nothing since has closed**:

- Weapon/plasmid icon bitmaps were never located in any SWF — HUD, radial and the select screen all
  show a brass ring/medallion plus name text, no icon.
- `M_Hud_LiquidFill` (the health/EVE liquid-gradient material) renders invisible; a flat tinted-mask
  fallback is forced (`bLiquidMaterialDisabled`).
- The shotgun's `FidgetShotgun` hand pose doesn't quite wrap the corrected gun placement (the proper
  fix — carrying `MeshSocket.Transform` through the FBX manifest — is scoped but not done).
- Status menu's Map tab is a coordinates placeholder, not a rendered level plan.
- Options, Credits, Director's Commentary, Museum and Challenge Rooms are stub panels.
- No Rapture still-plate or Bink loop behind the main menu (flat black background).

## World, lighting, and fidelity (Layer D)

Runs alongside Layer C, not gated on it. Landed: baked lightmap decode (atlas binding on 20 of 21
maps, `LayerLighting.hlsl` recovered and driving the software/GPU renderers in the C# tool), the
BSP texture-origin/UV fix (removed the visible seam at every panel edge), light shape/rotation import
(spot/sun/directional, 28 Sept 2026), the Rapture mood-layer scaffold (post-process volume + height
fog, exposed knobs).

**Open, roughly in visible-impact order** — this is the fidelity punch list a live in-editor pass
produced; treat items here as independent unless noted:

- **Water materials — done** (`z1`, 28 Sept 2026, corrected here 29 Sept 2026). Medical's 19
  `FluidShader` surfaces carry their own decoded textures/pan values. The bathysphere-room
  water/stairs bug in STATUS.md's live bug list stays **STATUS UNCLEAR — verify**; the water-graph
  gap this line used to blame it on no longer exists, so if the bug is still real live it needs a
  fresh look, not this explanation.
- **Glass — done** (corrected 29 Sept 2026, was wrongly listed as a gap). All 25 of Medical's glass
  materials were already correctly built; a wiring bug (Opacity reading the diffuse texture's own
  alpha instead of a real separate opacity texture when one existed) is fixed — see
  `docs/research/medical-glass-opacity-fix.md`. Decals remain genuinely unbuilt (procedural
  stand-in, no real bullet-hole art recovered) — that part of the gap is real.
- **God rays**, decal alpha and particle/effects stand-ins for shipped particle systems that can't be
  recovered byte-for-byte (a Niagara stand-in pack under `/Game/BioShockFX/`, following the same
  pattern as the existing impact-decal and plasmid-VFX stand-ins).
- **A UE5 material graph** for the level's panner/timeline/switch-driven surfaces generally (water is
  the most visible instance of this, not the only one).
- **Skeletal-prop idle animation** — a repair pass that makes looping-clip props (fans, wall tech,
  live wire, ice bulge, fish/whale rigs) actually play their loop, and makes `ActionPlayAnimation`/
  `ChangeAnimationRate` drive skeletal targets, not just static ones.
- **Animation at scale** — the 16,031 `AnimSequence`s import per-rig on demand today; importing at
  scale and building real AnimBlueprints (locomotion blendspaces, upper/lower body split, weapon
  poses) is unstarted breadth work.

## Enemy ecology (Gatherer/Protector)

**Explicitly out of scope until the above lands — its own project-sized piece.** Little Sister
harvest/carry/vent-traversal, Big Daddy protect/patrol/rage, the ADAM economy, and the rescue-vs-
harvest choice are all unbuilt. `ActionSpawnLinkedGathererAndProtector` and the ~15 `AssignNext*`/
Gatherer actions are still request-record stubs.

## Generalizing off Medical

Everything above that is proven only on `1-Medical` (script import, prop-mesh import, effects,
scripted set-pieces, per-map PlayerStart/nav) needs the same pipeline step re-run against the other 20
story maps, which are already asset-imported. This is breadth work, not research, and is the natural
next lane once Medical's own remaining gaps close.

---

## How this gets worked

One task at a time through `tools/agents/orchestrator.ps1`, most-used-action-first within whichever
system is active, each with a headless verify before landing. Layer A/B tasks (Python, per-map) fan
out freely in parallel; Layer C tasks touch the shared `BioShockRuntime` C++ plugin and must be
serialized — run non-C++ work alongside C++ work, never two C++ tasks at once. See
`docs/ENGINEERING_RULES.md` §60–61 for the standing process rules (roadmap discipline, test-run
economy, the file-ownership split between workers) — those are current and are not duplicated here.

## Honest sizing

Per the original full-port strategy: this is a multi-year effort at hobby pace. What the last several
weeks of work changed is *breadth* — asset import and the scripting VM went from "one slice" to
"substantially real across the top of the usage census" — not the overall size of Layer C, which is
still the long pole. "Playable through" (rough AI, core plasmids, all seven weapons, hacking, no
tonics/quests/switches) is closer than "faithful" (the whole thing, including the systems listed as
not-started above). Decide which one this is for any given session before picking up a Gatherer/
Protector-ecology-sized task.
