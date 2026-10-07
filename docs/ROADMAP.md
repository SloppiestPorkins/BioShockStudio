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

## Direction change, 6 Oct 2026: the original engine plays, UE5 renders

The goal is unchanged: a faithful BioShock 1 in UE5. The method changes. Until now this project has
rebuilt BioShock's game logic by hand in UE5 (Layer C), which this file calls "the multi-year part"
and which still has not got one map playable start to finish. Every map has also needed its own
hand repairs: 31 fix/repair scripts and a 51-step slice setup for Medical alone.

The new model is the one Oblivion Remastered uses (and, per the user, Halo: Campaign Evolved): the
**original engine keeps running the game** (AI, scripts, physics, weapons, plasmids, hacking, saves,
audio), and **UE5 only draws it**. Gameplay is then faithful by construction, every map works as
soon as the renderer does, and Layer C stops being needed.

The difference from those remasters: their studios had the engine source and wired the renderer in
directly. We don't. UE5 has to read the live game state from outside the running `BioshockHD.exe`
(BioShock Remastered, `G:/SteamLibrary/steamapps/common/BioShock Remastered/Build/Final/`). Whether
that is practical is the first thing to find out, before anything else is built.

Grounds for optimism, not yet evidence: BioShock is Unreal Engine 2 underneath, which keeps global
name and object tables in memory with reflective class metadata, and BioShockStudio already knows
every class's property layout and every map's placed actors (the export manifests give the ground
truth to match against).

Take items in order (§60 "Roadmap discipline").

### Phase 0 — Feasibility test (go / no-go) — PASSED 6 Oct 2026

Both steps pass; method, memory layout and evidence in
[`docs/research/live-game-bridge-2026-10-06.md`](research/live-game-bridge-2026-10-06.md), tools in
`tools/livegame/`.

1. **Read the running game.** Attach read-only to `BioshockHD.exe` with Medical loaded (no patching,
   no injection yet). Find the name and object tables; list live actors with class, name, Location
   and Rotation. **Pass:** the list matches Medical's export manifest by actor name, and the player's
   and enemies' positions change when they move. **Fail:** stop, and take the fallback below.
2. **Mirror it in UE5.** A small bridge streams the camera and every actor transform to UE5 each
   frame; the already-imported Medical map follows the real game as the player moves: camera, doors
   opening, enemies walking. **Pass:** a frame from the original and the UE5 frame from the same
   moment line up when captured side by side.

### Phase 1 — The renderer (only if Phase 0 passes)

**Status 7 Oct 2026** (detail in `docs/research/live-game-bridge-2026-10-06.md`). Done:

- **Live bridge:** the camera and every non-static actor stream at about 24 Hz.
- **Lighting:** the original's baked BSP lightmaps and per-vertex prop light render on a copy of the
  slice (`/Game/BioShockLive/1-Medical_Baked`), plus the zone ambient term.
- **Item 3 (animation):** skeletal actors are driven by the game's evaluated bones.
- **Item 4, partly (dynamic state):** stand-ins for runtime-spawned actors (340 of 382 in Medical,
  among them enemies, door leaves and pickups), spawned and destroyed as the game does.
- **Material overrides (Skins):** applied.

Open, in order:

1. Item 5, first person: viewmodel and hands, then the HUD.
2. Import the 20 meshes never imported (vending machine, Vita-Chamber parts, cameras, security bot,
   Baby Jane).
3. Material fidelity: the dirt-blend wall shaders, some ceilings.
4. Dynamic and animated lights.
5. The hemispheric ambient term.
6. Item 6, a single window.

3. **Animation:** skeletal poses follow the game (its current animation and time, or bone transforms
   read directly).
4. **Dynamic state:** actors spawned and destroyed, hidden/shown, lights switched and animated,
   animated material parameters, particle and impact effects mapped to UE5 equivalents.
5. **First person:** viewmodel, weapons, plasmid hands, and the HUD (the original HUD drawn as an
   overlay first; rebuilt later if it is worth it).
6. **One window:** the player sees UE5 and their input goes to the game; the original's own
   rendering is suppressed to free the GPU; the original game's audio is kept as-is.
7. **The comparison check:** automated side-by-side captures, original frame vs UE5 frame at the
   same moment. For the first time there is a live reference to test against, replacing the
   "no oracle" caveat under The goal.

### Phase 2 — All 21 maps through one converter

8. **No per-map hand work.** The 31 fix/repair scripts and Medical-specific setup steps get folded
   into the generic import, or dropped where they only patched the hand-ported logic. A map counts
   as done when the Phase 1 comparison passes along its route.

### Phase 3 — Fidelity, the point of the exercise

9. **The upgraded look:** materials, lighting, water, glass, god rays, decals, and particles, built
   on the asset import that already covers every map.

### Fallback if Phase 0 fails

Keep the UE5 runtime, but make it generic: the same Phase 2 rule (no per-map hand work, one
converter for all 21 maps), then Layer C prioritized by the action-usage census as before.

### Paused by this change

The Layer C hand port (AI states, weapons, plasmids, hacking, the Action library), finishing
`1-Medical` as a hand-built slice (the 30 Sept Phase 2), and refreshing the slice with the 442 actors
recovered on 4 Oct. The previous priority list (30 Sept) is in git history at commit 06f3b0e.
Still useful whatever happens: the asset import for all 21 maps, materials and lighting work, the
offscreen capture tooling, and the export manifests.

Unchanged cut lines: no reverse engineering of Havok (the original engine runs its own physics; we
only read the results). Nothing from the game's binaries or data goes into this public repo.

### Done under the previous priority list (detail in `docs/STATUS.md` and git history)

The scripting VM's remaining stubs (watchers, critical/immediate mode, `TestFact`, training-message
display and mute gate — 29 Sept); script-graph import on the 20 non-Medical maps (29 Sept, with the
new `export-level-manifest` CLI verb); first AI slice (per-archetype ranged-weapon resolution, 29
Sept); Medical content gaps closed 29–30 Sept — switches/levers, `NonPhysicalReactiveActor` debris,
shootable reactive props (padlocks/grates/ice/oil/TVs), `InPlayerViewTrigger` look-at gates, safes,
Tenenbaum's ADAM gift, `DoorKeypadControl`, the door-placement fallback (44/44 Medical doors place),
and a duplicate-collider correctness fix across switches, props, pickups, stations and vita chambers.
The quest state machine was confirmed real (28 Sept) — only hint/objective text is missing.

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
