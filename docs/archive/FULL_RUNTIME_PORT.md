# Full BioShock runtime port — roadmap

User directive (9 Sept 2026): *"dig into the entirety of BioShock's brain, how it does story
events, how things are triggered, how animations are triggered. I also want no more untextured
meshes. Basically I want the full BioShock runtime ported."*

The dig is `docs/research/runtime-brain.md`. This is the execution plan built from it.

**Where we are:** the vertical slice (`/Game/BioShockSlice/1-Medical`) boots menu → play →
possess → HUD → weapons → plasmids → AI encounter → pickups → vendors → death/Vita-Chamber, and
~55 of the 199 script Actions really change the world. The port is broad and shallow. This plan
makes it deep on Medical first, then generalises.

**Principle (unchanged from `UE5_FULL_PORT_PLAN.md`):** port data mechanically, reimplement
behaviour by hand from the decompiled source as spec. No transpiler.

**Dispatch:** one agent at a time (shared `BioShockUE5` project). Cursor quota resets 9/25;
codex (`chatgpt` worker, reasoning=high) resets nightly — it is the current worker. Claude does
all build/verify/capture/commit QC.

---

## Phase R0 — no untextured meshes  *(smallest, fully specified, do first)*

The whole gap is ~62 assets (`runtime-brain.md` §8), not thousands.

- **R0.1 — bulk prop-mesh import.** Extend `export-staticmesh` + a new
  `import_slice_prop_meshes.py` to bring in the real meshes for the placeholder-sphere actors:
  `bio_bandages`, `Ammo_Pickup_JHP` / `_Buck` / `_MG` / …, `hypo`, `EVE_hypo`, `AdamPickup`
  mesh, `AutoHackDevice`, `PowerBar`, the food/drink props, `WP_*` weapon pickup props, the
  plasmid-bottle props, `dyn_med_wheelchair`, `CashRegister`, `FlowerVase`, the
  `DeadBodyContainer` corpse mesh. Wire the importer to `AShockConsumablePickup::SetPickupMesh`
  / `AShockSearchableContainer::SetContainerMesh` / `AShockAnimatedProp::PropMesh` /
  `AShockStationBase::Mesh` by className. STEPS step. `verify`: 0 `/Engine/BasicShapes` on
  pickup/container/mover/station actors.
- **R0.2 — material-slot fixes for the 22.** Fix the rig / weapon-def / compiled-world export
  paths so they emit + bind the real materials (`tommygun_ammo_*`, `SecCameraSmall*`,
  `WP_AI_Pistol`, `Resurrection`, Steinman `banner*`, `PU_TommyGunMESH`). This is the
  `_import_textures` dual-intent / material-export gap (`d2` / `g4` / `h9`). `verify`: 0 null
  material slots in the slice.
- **R0.3** — bake the fidelity-pass Part B defects here too (blood-decal alpha, empty ad
  frames, window glass slots) — `docs/research/fidelity.md`.

Deliverable: a `-game` walk of Medical with no visible placeholder geometry.

---

## Phase R1 — the event VM to completeness

Make `UShockScriptRunner` a faithful `Scripting.Script` VM.

- **R1.1 — parameter resolution.** Implement `resolveInfoList`: an action param binds to a
  script `Variable` (by name) or a `Property` on a sibling action's return `Variable`. Thread
  it through `import_scripts.py` (the sidecar already carries the resolve info) and the runner.
  Unblocks every computed-value script.
- **R1.2 — Watchers.** `UShockWatcher` holding a statement tree (`And`/`Or`/`Not`/`Truth`/
  `Arithmetic` over `Variable`s and actor properties), ticked by the subsystem, publishing a
  `MessageWatcher` on change. `ActionCreateWatcher` / `Enable` / `Disable` become real.
- **R1.3 — script Timer + typed Messages.** `Script.StartTimer` → `MessageTimerExpired`; a real
  `UShockMessage` object with fields + `messageFilter` matching, so `scriptMessageClass` /
  `messageFilter` gate correctly.
- **R1.4 — critical/immediate mode.** On level travel, run every `bIsGameCritical` action
  synchronously before unload (matches `executeCriticalActionsImmediately`).
- **R1.5 — `ActionSendTriggerMessage`** real (script publishes a message onto the bus).

`verify_import_scripts` extended: a Watcher fires on a variable change; a computed distance
drives an `ActionIf`; a timer message starts a second script.

---

## Phase R2 — the Action library (drive them by Medical frequency)

Turn the ~145 stubs real, ordered by Medical usage. Each is small; batch them.

- **R2.1 — reflection: `SetProperty` / `GetProperty` / `PropertyTest`** (134 uses). Generic
  `FProperty` set/get on `FindByLabel(target)` by property path, with type coercion from the
  script string. One implementation, 134 beats unlocked.
- **R2.2 — visibility/collision: `HideOrShowActor` (48), `ChangeCollision` (41),
  `ChangeStaticMesh` polish, `SetActorLabel`.** Trivial `SetActorHiddenInGame` /
  `SetActorEnableCollision`.
- **R2.3 — AI script control: `SpawnAI` completeness, `AttackTarget`, `TeleportPawnToLocation`
  (16), `Tweak AI Vision/Hearing` (60), `ToggleAIReactions` (11), `MuteAI` (9),
  `Post/RemoveGoal`, `WaitForGoal` (11), `DestroyAIs` (27).** Most map onto `ABaseShockAI` /
  the w13 SM knobs.
- **R2.4 — items/HUD: `GiveItemsToPlayer` (31), `PlaceItemInContainerSlot` (21),
  `ShowTrainingMessage` (41), `SetTipPriority` (29), `WaitForQuestLogToFinish` (17),
  `DisableOrEnableConcept` (18), `SetOrUnsetInputContext` (10).**
- **R2.5 — world sim: `ChangePressure` (11), `FreezeHavokActor` (18) / `TriggerHavokForceActor`
  (10) / `EnableOrDisableHavokForceActor`, `Deal*Damage` completeness (17),
  `EnableOrDisableCascadingWaterVolume` / `DamageVolume`.**

`verify`: a headless "run every Medical script to completion, assert 0 actions return
'unimplemented'" pass, plus targeted checks per batch.

---

## Phase R3 — the EffectsSystem  *(the single biggest visual gap — 167 Medical uses)*

- **R3.1 — `UShockEffectsSubsystem`**: an event → bundle registry. Bundle =
  {Niagara/Cascade system, sound cue, decal, camera-shake, light pulse}. Keyed by
  `(EventName, ContextName, SurfaceType)`. Seeded from the decompiled EffectsSystem tables +
  `ActionSetEffectsSystemContext` (10 uses).
- **R3.2 — `ActionPlayEffect` / `PlayEffectAndWaitForStart` / `StopEffect`** real: spawn/track/
  stop the bundle at the target actor/bone/location.
- **R3.3 — stand-in FX pack**: where the shipped particle can't be recovered, author a
  Niagara stand-in under `/Game/BioShockFX/` (steam, sparks, blood spray, drips, dust, water
  spray, electrical arc) — same pattern as `author_impact_decal_standins.py` /
  `author_plasmid_fx_standins.py`. Fold in the w15 impact particles and w9 plasmid VFX here so
  there is one system.
- **R3.4 — skeletal-prop idle animation**: a repair step that sets `AccGateAnim`,
  `WallTechAnim_*`, `LiveWireAnim`, `IceBulge*`, the fish/whale rigs to play their loop clip,
  and makes `ActionPlayAnimation` / `ChangeAnimationRate` drive skeletal targets too.

---

## Phase R4 — scripted sequences / cinematic AI

- **R4.1 — `LatentAIAction` port**: the AI-side action list — MoveTo, PlayAnim, FaceActor,
  Say, Wait, EquipWeapon, SetPose — that puppets a pawn during a scene.
- **R4.2 — `ActionControlScriptedSequence` / `Cinematic{Enter,Exit,FadeView}`**: the scene
  driver — take input, move the camera, run the `LatentAIAction` lists, restore.
- **R4.3 — the Medical set-pieces**: the doctor-killer intro (splicer through the window),
  the Steinman surgery, the first Big Daddy sighting behind glass. Data is in the scripts;
  this makes them play.

---

## Phase R5 — security & ecology

- **R5.1 — turret / camera / bot goals**: camera inspect→alert→summon, bot patrol/protect/
  return-home, the alarm state. `AShockTurret` / `AShockSecurityBot` gain a goal path.
- **R5.2 — Gatherer / Protector ecology** *(XL — its own project)*: Little Sister harvest
  loop, carry, vent traversal; Big Daddy protect/patrol/rage; the ADAM economy; the
  rescue/harvest choice. `ActionSpawnLinkedGathererAndProtector` and the ~15 `AssignNext*` /
  Gatherer actions become real.

---

## Phase R6 — generalise off Medical

Re-run R0–R4 pipeline steps against the other 20 story maps (already imported to
`/Game/BioShockLevel/*`, `78a55b8`). Each map: prop-mesh import, script import, effects, scene
set-pieces, per-map PlayerStart + nav. This is the `docs/FULL_GAME_CONVERSION.md` breadth pass,
now with a real runtime under it.

---

## Task queue (feeds `tools/agents/tasks/`)

| id | phase | worker | size |
|---|---|---|---|
| `x1-prop-mesh-import` | R0.1 | chatgpt | M |
| `x2-material-slot-fixes` | R0.2 | chatgpt | M |
| `x3-vm-param-resolution` | R1.1 | chatgpt | M |
| `x4-vm-watchers-timers` | R1.2–1.4 | chatgpt | L |
| `x5-actions-reflection` | R2.1 | chatgpt | S |
| `x6-actions-visibility-ai-items` | R2.2–2.4 | chatgpt | L |
| `x7-effects-subsystem` | R3.1–3.2 | chatgpt | L |
| `x8-effects-standin-pack` | R3.3 | chatgpt | M |
| `x9-skeletal-prop-anim` | R3.4 | chatgpt | S |
| `x10-latent-ai-and-scenes` | R4 | cursor (when back) | XL |
| `x11-security-goals` | R5.1 | cursor | L |
| `x12-gatherer-ecology` | R5.2 | — | XL / own project |

Also carried: w4 (HUD liquid-fill), w5 (weapon/plasmid icons), w8 (shotgun grip),
w12-B (fidelity defects) — retargeted to chatgpt, dispatch between phases.
