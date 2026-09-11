# BioShock's runtime brain — event system, triggers, AI, animation

Written 9 Sept 2026 at the user's request ("dig into the entirety of BioShock's brain… I want
the full BioShock runtime ported"). Grounded in the decompiled UnrealScript under
`tmp/uc_scripting` (99 files / 7.4k lines), `tmp/uc_shockai` (540 / 65k), `tmp/uc_shockgame`
(654 / 56k) and measured against the current `tools/ue5/BioShockRuntime` port (284 `.cpp`).

The decompiled function bodies are degraded (control-flow artifacts, `__NFUN_<id>__`
placeholders — see `docs/UE5_FULL_PORT_PLAN.md` §1). Class layout, `var` declarations and
`defaultproperties` are clean. So this doc reads the *structure* off the source and the
*intent* off the names + defaults; behaviour is reconstructed, not transpiled.

---

## 1. The three brains

BioShock's runtime logic is three cooperating systems on one message bus:

| System | Package | What it decides | Port entry point |
|---|---|---|---|
| **Script / event VM** | `Scripting` | Story beats: "when X happens, do A, B, C" | `UShockScriptRunner`, `AShockScript`, `UShockScriptSubsystem` |
| **AI brain** | `ShockAI` | Per-character behaviour: perceive → pick a goal → act | `UShockAIBrain` + `ABaseShockAI` behaviour SM (w13) |
| **Effects / animation** | `ShockGame` `EffectsSystem` | What plays visually/audibly for a given event in a given context | `UShockAudioLibrary`, `ShockActionPlayEffect` (stub), `AShockAnimatedProp` |

They meet at `Level.MessageDispatcher` — a global publish/subscribe bus. Everything that
"happens" is a `Message` object; everything that "reacts" is a subscriber.

---

## 2. The message bus (`Level.MessageDispatcher`)

**`Message`** (`Engine.Message`, ~40 subclasses in `Scripting`): a small value object.
`specificTo` (a pawn class), `passesFilter(otherMessage)` for field matching, `Allocate()` /
pool. Key subclasses:

- `MessageTrigger`, `MessageTriggerEnter`, `MessageTriggerExit` — a `Trigger` / `TriggerRadius`
  fired.
- `MessageTriggerVolume`, `…Enter`, `…Exit` — a `TriggerVolume` overlap.
- `MessageMover`, `…Opened/Closed/Opening/Closing/Bump/PlayerBump` — a `ScriptableMover` state
  change.
- `MessageTimerExpired` — a script's own `StartTimer`.
- `MessageWatcher` — a `Watcher` expression changed value.
- `MessageCriticalMessage*` — the level-travel / cinematic "must finish now" channel.

**Dispatch**: `registerMessage(class, sourceLabel)` subscribes; `dispatchMessage(msg)` fans
to every subscriber whose `(class, sourceLabel)` matches, calling `onMessage(msg)`.
`deleteMessage(msg)` returns it to the pool.

**Sources that publish**:
- `Trigger` / `TriggerRadius` / `TriggerVolume` — on touch/overlap.
- `ScriptableMover` — on each door/lift state transition.
- `Watcher` — polls an expression (`AndStatement` / `OrStatement` / `TruthStatement` /
  `ArithmeticStatement` tree) every tick, publishes on change.
- `Script.StartTimer` → `Timer()` → `MessageTimerExpired`.
- `ActionSendTriggerMessage` — a script publishing a message by hand (script→script chaining
  beyond `ExecuteScript`).
- Gameplay code: AI death, weapon fire, pickup, quest state, hack — all publish typed messages.

### Port state — bus
`UShockScriptSubsystem` (`UWorldSubsystem`) owns one `UShockScriptRegistry`. `import_level`
attaches `UShockTriggerRelayComponent` on every imported `TriggerVolume` → `TriggerBox`; on
overlap it calls `Registry->DispatchMessage("MessageTrigger", <label>)`. Level-entry labels
(`<mapname>`, `All`) dispatch once on `OnWorldBeginPlay`.

**Gaps**: no real `Message` objects (dispatch is `(FName class, FString source)` only, so
`messageFilter` / typed fields are ignored); no `Watcher`; no script `Timer`; `ScriptableMover`
state-change messages not published (w3 placed the movers but they don't emit
`MessageMoverOpened` etc.); AI/weapon/pickup gameplay messages not on the bus.

---

## 3. The Script / event VM

**`Script`** (`Scripting.Script`, `extends Actor placeable`): a level-placed node.

```
var Class<Message> scriptMessageClass;      // which message class starts me
var Message messageFilter;                   // field-match filter on that message
var array<Action> Actions;                   // ordered program
var bool enabled;
var array<Variable> variables;               // script-local, travel-persistent
var array<Watcher> watchers;
Actor.TriggeredBy  (inherited, string)       // comma list of source labels
```

**Lifecycle** (`Script.uc`):
1. `BeginPlay` → `setParentScript()` on every action → if `TriggeredBy != ""`,
   `registerMessage(scriptMessageClass, TriggeredBy)`.
2. `onMessage(msg)` → reject if `!enabled`, wrong message class, or `messageFilter` fails →
   else `execute(msg)`.
3. `execute` copies the message (`msgCopy`), sets `CurrentMessage`, enters state
   `ExecuteScript`; if already executing, appends to `MessageQueue`.
4. State `ExecuteScript` → `executeActions()` → `doActions()` → for each action:
   `CurrentlyExecutingActionIndex = i; Actions[i].latentExecute()`.
5. When done, drains `MessageQueue`.

**Execution modes**:
- **Latent** (default): actions can block (`ActionWait`, `ActionWaitForCriticalMessage`,
  `ActionBlockingExecuteScript`). The script yields until the block clears.
- **Critical / immediate** (`executeCriticalActionsImmediately`): on level travel, runs every
  `bIsGameCritical` action to completion synchronously so the world state is consistent before
  the map unloads. `Action.bIsGameCritical` defaults **true**.

**Control flow**: `bExitScript` (`ActionExitScript`), `bExitLoop` (`ActionExitLoop`),
`ActionIf` (statement tree → run/skip the next N), `ActionLoop` / `ActionFor` (repeat a body),
`ActionExecuteScript` / `ActionNonBlockingExecuteScript` / `ActionBlockingExecuteScript`
(call another `Script` by label; blocking sets `BlockedParentScript`).

**`Action`** (`Scripting.Action`, `Object editinlinenew`):
```
var array<ParameterResolveInfo> resolveInfoList;   // param ← Variable | another Action's Property
var Class<Variable> returnType;                     // actions can return a Variable
var bool bIsGameCritical;
latent function Variable latentExecute() { return execute(); }
```
`resolveParameters()` (native) walks `resolveInfoList`: each entry binds a property on *this*
action to either a script `Variable` (by name) or a `Property` on a sibling action's return
value. This is how `ActionIf` reads `ActionCalcDistance`'s result, how a spawned actor's label
flows into the next action, etc.

**`Variable`** — `VariableBool`/`Float`/`Name`/`String`. Scope: `variables` (script-local),
`tempVariables` (per-run), or `Global_*` prefix → `Level.GetGlobalTravelContainer()`
(persists across level travel). `ActionVariable*` = the arithmetic/assign ops.

**`Watcher`** (`WatcherBase`): holds a statement tree + a `LookAtExpression`. Ticks, evaluates,
publishes `MessageWatcher` (with old/new value) when it changes. `ActionCreateWatcher` /
`ActionEnableWatcher` / `ActionDisableWatcher` manage them. This is BioShock's "when this
condition becomes true" primitive (e.g. "when player HP < 25%", "when all 3 enemies dead").

### Port state — VM
`UShockScriptRunner` (591 lines) implements: authored `Actions` → run queue → `TickExecution`
advancing `ActionWait`, `ActionIf`, `ActionLoop`/`ExitLoop`, `ActionFor`, `ExitScript`,
`ScriptNote`, `Blocking`/`NonBlocking` child scripts (by label), `TriggeredBy` start +
`MessageQueue`. `UShockVariableScope` holds `ActionVariableAssign*`. `import_scripts.py`
decodes the serialized `Script` actors + the `.script-actions.json` sidecar into
`AShockScript` + `UShockAction` objects (`new_object(cls, runner)` — outered correctly since
`14b2157`).

**Parameter resolution (R1.1):** `resolveInfoList` is carried by script-actions sidecar v3 and
applied before runtime actions execute. Scope `Variable.Value` and an action expression's returned
`Variable.Value` both type-coerce into the destination action property; see
`docs/research/script-vm.md` for shipped-byte evidence and the implemented producer set.

**Gaps**:
- **No `Watcher`** — condition-becomes-true scripts never fire.
- **No script `Timer`** (`StartTimer` → `MessageTimerExpired`).
- **No critical/immediate mode** on level travel (all-or-nothing runs, no `bIsGameCritical`
  gate).
- **No typed `Message`** — `messageFilter` and message fields ignored.
- **`ActionSendTriggerMessage`** records only → script→script message chaining is limited to
  `ExecuteScript`.

---

## 4. The Action library — real vs stub

**199 `ShockAction*` classes exist. Medical's scripts use 111 distinct ones.** By behaviour:

**Real (≈55) — actually change the world:**
`OpenDoor` / `CloseDoor` / `LockDoor` / `UnlockDoor` (→ `AShockDoor`), `PlayAnimation`
(→ door / `AShockAnimatedProp`), `SpawnAI` (→ `AShockAggressorSpawner::SpawnForScript`),
`SpawnTurret` / `SpawnSecurityBot`, `AttackTarget` (→ `ABaseShockAI::ScriptedAttackTarget`),
`DealDamage` / `DealDamageInRadius` / `DealShockingDamageInRadius`, `TeleportPawnToLocation`,
`GiveItemsToPlayer` / `RemoveItemsFromPlayer`, `EquipPlasmid` / `UnEquipAllPlasmids`,
`Activate/DisableOrEnableResurrectionStation`, `HackSecuritySystem` / `HackTurret`,
`InitiateQuest` / `CompleteQuest` / `CompleteQuestObjective` / `FailQuest`, `AISpeech`,
`SetAIPatrol` / `SetAIState` / `MuteAI` / `ToggleAIAttacking` / `TweakAIVision`/`Hearing`,
`SetPlayerInvincibility` / `SetPawnInvincibility`, `DisablePlayerMovement` / `ForcePlayerMove`
/ `ForcePlayerCrouch`, `SetPlayerFOV`, `PlayHUD` / `StopHUD` / `ShowTrainingMessage` /
`SetHUDDisplayState`, `ChangeLevel`, `Wait`, `If` / `Loop` / `For` / `ExitScript` /
`ExitLoop`, the `Variable*` ops, `ExecuteScript` variants, `ChangeStaticMesh`,
`SetLightProperties`, `AutoSave`, `RunConsoleCommand`.

**Stub (≈145) — validate params, record `Last*`, return true, no world effect:**
`PlayEffect` / `PlayEffectAndWaitForStart` / `StopEffect` **(167 uses in Medical — the single
biggest gap)**, `SetProperty` / `GetProperty` / `PropertyTest` **(134 uses — reflection set/get
on arbitrary actor properties)**, `HideOrShowActor` **(48)**, `ChangeCollision` **(41)**,
`SetTipPriority`, `PlaceItemInContainerSlot`, `AttachToBone` / `ApplyScriptedHandAttachment` /
`ChangeSkinAtIndex` / `ChangeResistanceSet`, `PlayMovie`, `ControlPlant`,
`GathererCrawlThroughDoor`, `CinematicFadeView`, `FreezeHavokActor` / `TriggerHavokForceActor`
/ `EnableOrDisableHavokForceActor` **(havok force-field props)**, `ChangePressure`,
`SetEffectsSystemContext`, `PlayScriptedHandAnimation` / `Start/StopScriptedHandAnimationSequence`,
`WaitForGoal` / `PostMovementGoal` / `RemoveGoal` (AI goal injection),
`SendTriggerMessage`, `SetMovableSpotlightState`/`Target`, most `AssignNext*` (Gatherer/Protector
sequencing), the achievement/DLC/training-concept toggles.

The stubs are why "certain scripts don't visibly do anything" — the graph runs, actions log,
nothing moves. The **highest-leverage fixes** by Medical usage: `SetProperty`/`PropertyTest`
(generic reflection — unlocks 134 uses at once), `PlayEffect`/`StopEffect` (167 — needs the
EffectsSystem, §6), `HideOrShowActor` (48 — trivial: `SetActorHiddenInGame` + collision),
`ChangeCollision` (41 — `SetActorEnableCollision`).

---

## 5. The AI brain

BioShock AI is **goal-based**, not a behaviour tree or FSM. Structure (from `tmp/uc_shockai`):

- **`Goal`** subclasses (~60): `AlertGoal`, `AttackTargetGoal`, `AttackReactionGoal`,
  `BurningGoal`, `AlertGoal`, `CameraInspectGoal`, `BotProtectTargetGoal`, `BotReturnHomeGoal`,
  `FleeGoal`, … each with a priority and a `CanAchieve` gate.
- **`MovementGoal`** sub-goals: `BioshockMovementGoal`, `BotNavigateToActorLocationMovementGoal`,
  `CameraPanMovementGoal` — a Goal spawns a MovementGoal to get into position.
- **`BehaviorAction` / `BehaviorGoal` interfaces** — the actual motor acts (fire a burst, melee
  swing, take cover, crawl).
- **`LatentAIAction`** (`tmp/uc_shockai`) — the AI-side equivalent of `Scripting.Action`, used
  by `ActionAI*` script actions to puppet a character during a cutscene ("walk here, play this
  anim, say this line").
- **Perception**: layered vision cones + hearing with per-stimulus gain/decay
  (`Aggressor.uc` — see `docs/research/ai-behaviour.md` for the constants).
- **`EcologyFighter` / `Aggressor` / `SpawnerBase`** — archetype + spawn-population layer
  (`docs/research/enemies.md`).

Loop: perceive → `BuildCandidateGoals` (each subsystem contributes goals with priorities) →
pick highest → goal drives movement sub-goal + behaviour actions → repeat.

### Port state — AI
`UShockAIBrain` (279 lines): a fixed 7-ability priority list (`HitReact`, `Flee`, `Melee`,
`Ranged`, `MoveTo`, `Patrol`, `Idle`) — `BuildCandidateGoals` maps AI state → a `UShockAIGoal`,
`Think` runs the first ability whose `CanAchieve` passes. w13 added `ABaseShockAI`'s
`EShockAIBehaviourState` SM (Idle/Patrol/Alert/Investigate/Search/Combat/Flee) *above*
`TickCombat`, plus real perception, group alert, vocal hooks, cover-strafe, melee lunge.

**Gaps vs the real system**:
- No goal *stack* / interruption model — one ability at a time, no "resume the previous goal".
- Missing goal types: cover use is a strafe stand-in (no cover-point graph), no
  take-cover/peek/blindfire, no coordinated group tactics, no `AttackReactionGoal` variety
  (dodge, roll, stagger-back), no ceiling/wall crawler locomotion, no `AlertGoal` escalation
  ladder.
- **Turrets / security cameras / security bots** run a much thinner combat path (`AShockTurret`
  205 lines, `AShockSecurityBot`) — camera inspect/alert/summon and bot protect/patrol goals
  are not modelled.
- **Little Sisters / Big Daddies** — `Gatherer` / `Protector` ecology (harvest loop, carry,
  protect, the ADAM economy) is entirely absent (`ActionSpawnLinkedGathererAndProtector` etc.
  are stubs).
- **Scripted-sequence puppeting** — `LatentAIAction` / `ActionControlScriptedSequence` is a
  stub, so the doctor-killer intro, the Steinman surgery, and every "AI does a scripted
  performance" beat don't play.

---

## 6. Effects & animation triggering

BioShock routes *every* audiovisual response through an **EffectsSystem context lookup**:
`(EventName, EffectsSystemContext, SurfaceType/Material)` → a bundle of particle + sound +
decal + camera-shake + light pulse. `ActionSetEffectsSystemContext` swaps the active context
(e.g. "underwater", "on fire", "in the medical wing"), `ActionPlayEffect` fires a named event
into it.

Animation triggering has three paths:
1. **Prop transform animation** — `ScriptableMover` keyframes + `Fan` spin, driven by
   `ActionPlayAnimation` / `ActionChangeAnimationRate`. **Ported** as `AShockAnimatedProp`
   (w3 places Medical's 8 movers).
2. **Skeletal prop animation** — `AccGateAnim`, `WallTechAnim_*`, `LiveWireAnim`, `IceBulge*`,
   fish schools, the whale — a `SkeletalMeshActor` playing a looping `AnimSequence`.
   **Not driven** — the rigs import but nothing plays their clips.
3. **Character scripted animation** — `LatentAIAction` telling a pawn to play a full-body clip
   in a scripted sequence; `PlayScriptedHandAnimation` for the first-person hands during a
   scene. **Stub.**

### Port state — effects/anim
`UShockAudioLibrary` (w1) resolves `SourceClassName + event` → a `USoundCue` and is wired into
weapon fire, footsteps, AI vocals, impacts, ambience. There is **no particle/decal/camera-shake
EffectsSystem** — `ActionPlayEffect`'s 167 Medical uses do nothing visible. w9/w15 authored
ad-hoc stand-in FX (`AShockPlasmidFx`, impact decals) but not a general context→bundle system.

---

## 7. Where the gaps hurt most (Medical, by script frequency)

| Gap | Medical uses | Effort | Unlocks |
|---|---|---|---|
| `ActionPlayEffect`/`StopEffect` + a minimal EffectsSystem | 167+29 | L | steam, sparks, blood spray, water FX, the surgery-room set dressing |
| `ActionSetProperty`/`PropertyTest`/`GetProperty` (reflection) | 134+ | M | 134 script beats that flip an actor flag / read a value |
| `ActionSpawnAI` completeness + `LatentAIAction` puppeting | 60+ | L | the doctor-killer intro, Steinman, every scripted-enemy beat |
| `ActionHideOrShowActor` + `ActionChangeCollision` | 48+41 | S | reveal/hide set pieces, open blocked paths |
| `Watcher` + parameter resolution in the VM | — | M | condition-driven scripts, computed values |
| `ActionAISpeech` context + the missing `ShockAI__*` cues | 22 | S | Investigate/TargetLost/Terrified vocals (w13 gap) |
| Skeletal-prop looping animation | ~15 rigs | S | fans, wall-tech, water bulge, fish, whale visibly alive |
| Turret/camera/bot goal behaviour | — | M | security actually reads as BioShock |
| Gatherer/Protector ecology | — | XL | Little Sisters + Big Daddies (whole subsystem) |

---

## 8. The mesh / material gap ("no more untextured meshes")

Slice census (9 Sept, `mesh_census.py`): 4560 static-mesh components, **4251 clean (93%)**.
The 309 that aren't:

| Bad | Count | Cause | Fix |
|---|---|---|---|
| `/Engine/BasicShapes` marker | 284 | pickup/container/mover/station real meshes never imported (147+55+8+7); door blockers (40) + water surface planes (27) are *intentional* invisible proxies | import the ~40 real prop meshes; leave proxies |
| null material slot | 22 | `tommygun_ammo_*`, `SecCameraSmall*`, `WP_AI_Pistol`, `Resurrection`, Steinman `banner*`, `PU_TommyGunMESH`, `Model1` — the rig / weapon-def / compiled-world import paths skip material export | fix those exporters to emit + bind the real materials (`d2`/`h9`/`g4` territory) |
| WorldGrid checkerboard | 0 | previously fixed (`repair_null_slot_materials`) | — |

So "no untextured meshes" ≈ **~62 assets**: ~40 prop meshes to bulk-import + ~22 material-slot
fixes. Not thousands. The visible eyesores in play are the pickup/container marker spheres
(from w10/w11) — those need `bio_bandages`, `Ammo_Pickup_*`, `dyn_med_wheelchair`, the corpse
meshes, cash register, flower vase, and the weapon/plasmid pickup props.
