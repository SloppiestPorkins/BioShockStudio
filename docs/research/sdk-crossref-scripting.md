# SDK cross-reference — scripting (guide ch. 20–23, 37)

Cross-check of the Unofficial BioShock SDK guide chapters on scripting basics, logic/variables,
the game-system action reference, worked map examples, and the glossary against the UE5 runtime
(`ShockScriptRunner` / `ShockAction*` / variable + boolean helpers). Read-only audit: no code
changed. Guide citations are chapter + section heading only; no guide prose is copied.

**Counts:** **BUG 17** · **GAP 22** · **OK 28** · **UNKNOWN 6**

**Summary.** The message bus, `TriggeredBy` parsing, `scriptMessageClass` gating (exact + base
`Message`), per-script queues, waits, loops, and several leaf actions already match the guide’s
control-flow shape. The player-visible failures cluster elsewhere: `ActionSendTriggerMessage`
puts the Instigator into the *source* slot and fires class `Message` instead of `MessageTrigger`;
`Global_` names are plain per-script locals with no travel container; message payloads beyond
class/source are unread (`Keycode` / `RA` / `Instigator`); nested `And`/`Or`/`Not` cannot bind
because properties are named `bLhs`/`bRhs` while bindings say `lhs`/`rhs`; boolean compares are
case-sensitive and ignore the guide’s type rules; door and many label lookups are first-match and
case-sensitive; timers never emit `MessageTimerExpired`; ScriptableMovers neither consume trigger
messages nor emit mover classes. Chapter 23’s fourteen examples mostly cannot reproduce described
behaviour until those core contracts land. Known opens from this session (`messageFilter`, spawn
archetypes, Gatherer ecology, ToggleAIReactions incomplete switches, etc.) are not re-listed as
new findings.

---

## BUG table (player-visible impact first)

| id | what the guide says (own words) | guide ref | our code | what we do instead | proposed fix | effort |
| --- | --- | --- | --- | --- | --- | --- |
| SCR-B01 | `ActionSendTriggerMessage` always sends under the *running script’s* Label; `Instigator` is only a message field (often `Player`). Receivers match `TriggeredBy` to the script Label. | ch.21 Calling other scripts / ActionSendTriggerMessage; ch.23 Ex.10–12 | `ShockActionSendTriggerMessage.cpp:23-34` | When `Instigator` is set, that name becomes the dispatch *source*, so movers/scripts listening for the script Label never see the event (every Fort Frolic / Welcome elevator row that sets `Instigator=Player`). | Always dispatch source = parent script Label; store Instigator on the message payload (see SCR-B04). | M |
| SCR-B02 | Same action sends class `MessageTrigger` (base of enter/exit trigger messages). Scripts can listen with `MessageTrigger` or base `Message`. | ch.20 Which message class; ch.21 ActionSendTriggerMessage | `ShockActionSendTriggerMessage.cpp:34` | Dispatches class name `Message`. Exact `scriptMessageClass=MessageTrigger` listeners never start; only the base-class wildcard works. | Dispatch `MessageTrigger`; keep subclass acceptance (SCR-B15). | S |
| SCR-B03 | Names with `Global_` live in a player-travel container shared by every script across maps and saves. | ch.21 Variables / Scopes; ch.23 Ex.3,6,9,14 | `ShockScriptRunner.cpp:140-146`, `682`; `ShockVariableScope.cpp` (no global store); no `Global_` in save/travel code | Every assign/increment writes only that runner’s `UShockVariableScope`. Cross-script reads of the same `Global_*` name miss; level return cannot keep Fort Frolic flags. | GameInstance (or player) `UShockVariableScope` for `Global_` prefix; route assign/resolve through it; persist on travel. | L |
| SCR-B04 | `ActionGetMessageValue` returns any field of the starting message (`Keycode`, `RA`, `Instigator`, …) as text. | ch.21 ActionGetMessageValue; ch.23 Ex.11–12 | `ShockActionGetMessageValue.cpp:15-36` | Only `Source`/`Class` (and aliases) work; everything else returns false / empty. Keypad unlock and lift button tests cannot read `Keycode`/`RA`. | Extend message bus beyond class+source; fill fields at send sites; map `Property` to those fields. | L |
| SCR-B05 | `AndStatement` / `OrStatement` / `NotStatement` take nested statements via Bindings `PropertyName=lhs|rhs`. | ch.21 AndStatement…; ch.23 Ex.12,14 | `ShockAndStatement.h:16-19`; `ShockAction.cpp:15,115` (`FindPropertyByName`); `ShockBooleanStatement` has no `ApplyInWorld` return | Nested bind targets `lhs` but UPROPERTY is `bLhs` → resolve fails; nested bool actions never publish a return value. Compound tests stay false. | Rename to `Lhs`/`Rhs` *or* alias in resolve; evaluate nested `UShockActionBool` inside `EvaluateBool`. | M |
| SCR-B06 | After variable substitution, compare by inferred type: bool/name/string equality is case-insensitive; ordered ops on bool/name are always false; numeric lhs coerces non-numeric rhs to 0. | ch.21 BooleanStatement | `ShockBooleanStatement.cpp:16-42` | Both-numeric path is OK-ish; else lexicographic/`==` case-sensitive. `given` vs `Given` fails; `True > False` can be true. | Port the four-type table; use IgnoreCase for name/string eq. | M |
| SCR-B07 | Door open/close/lock/unlock act on *every* door with the Label. | ch.22 Doors and keypads (`ActionOpenDoor` et al.) | `ShockActionOpenDoor.cpp:32-37`; `ShockDoor.cpp:363-389` (first match only); same pattern on Lock/Unlock/Close | Only the first `AShockDoor` is touched. Shared labels (entry door pairs) leave siblings shut/locked. | `CollectLabeled` loop like AI helpers; apply to all. | S |
| SCR-B08 | Labels are not case-sensitive. | ch.20 Labels; ch.23 Labels | `ShockDoor.cpp:378`; `ShockDamageLibrary.cpp:49,56`; `ShockActionPlayEffect.cpp:54`; `BaseShockAI::CollectLabeled` case-sensitive | Mismatched casing fails lookup even when `TriggeredBy` matched IgnoreCase. | `ESearchCase::IgnoreCase` on all Label equals. | S |
| SCR-B09 | Labelled effect / property / collision / hide actions run in the retail game, not only the editor. | ch.21 General actions; ch.23 Ex.1–2 | `ShockActionPlayEffect.cpp:53-62` (`#if WITH_EDITOR` around label match); same gate on SetProperty, SetLightProperties, HideOrShow, ChangeCollision, DestroyActor, … | Outside editor builds the match body is compiled out → silent no-ops for effects, self-disable via Label, lights, etc. | Resolve labels via `DoorLabel` / `ScriptLabel` / tags without `WITH_EDITOR`. | M |
| SCR-B10 | `ActionStartTimer` starts a timer *on that Script*; on expiry that Script sends `MessageTimerExpired` under its own Label. `ActionStopTimer` cancels by `scriptLabel`. | ch.20 Timers; ch.21 Timers; ch.23 Ex.7 | `ShockActionStartTimer.cpp:31-37` (`Player->SetPendingTimerSeconds`); no `MessageTimerExpired` dispatch in runtime | Value sits on the player; nothing fires the timer message. HammerLock / PlasmidJuggler patterns cannot run. | Per-runner timer; tick → `DispatchMessage(MessageTimerExpired, ScriptLabel)`; StopTimer clears by label. | M |
| SCR-B11 | A callee that is already running refuses a second `Blocking`/`NonBlocking` execute. | ch.21 Calling other scripts | `ShockScriptRunner.cpp:149-185`, `648-655` | `StartExecution` does not check `bIsExecuting`; a second call resets and restarts the child mid-run. | If `Child->bIsExecuting`, refuse (return without restart). | S |
| SCR-B12 | `ActionCinematicFadeView` waits until the fade finishes before the next row. | ch.21 General actions (`ActionCinematicFadeView`) | `ShockActionCinematicFadeView.cpp:28-31`; runner has no fade pending path | `ApplyInWorld` only records; script continues immediately. Arrival cinematic timing collapses. | Latent pending like `ActionWait` / animation wait for Duration+hold. | M |
| SCR-B13 | Missing door Label → no actor work (must-exist actions assert; others do nothing). Success is not implied. | ch.22 Doors; ch.21 How an action runs | `ShockActionOpenDoor.cpp:36-37`; Unlock always `return 1` after optional find (`ShockActionUnlockDoor.cpp:31-35`) | Missing door still reports success so runners advance as if the door changed. | Return 0 / false when no match (unless intentionally record-only under a flag). | S |
| SCR-B14 | Empty `Target` on `ActionDealDamage` damages every actor of `DamageeClass` in the map (dangerous but specified). | ch.22 ActionDealDamage | `ShockActionDealDamage.cpp:22-24`, `41-50`; no `DamageeClass` field | Empty Target refuses; class-wide damage path missing. Safer, but wrong vs guide and vs empty-label map data. | Add `DamageeClass`; empty Target → all of class (with loud log). | M |
| SCR-B15 | `scriptMessageClass` accepts the class *and subclasses* (`MessageTrigger` covers enter/exit; `MessageMover` covers open/close, …). | ch.20 scriptMessageClass; The message classes NOTE | `ShockScriptRunner.cpp:93-101` | Exact name or base `Message` only. Intermediate bases never match children. | Small inheritance table (or imported parent chain) in `MatchesMessageClass`. | S |
| SCR-B16 | Disabling a script drops its queued messages. | ch.21 Enable and disable scripts | `ShockScriptRunner.cpp:217-225`; reflection can set `bEnabled` but never clears `MessageQueue` | Queue retained; re-enable later replays stale messages. | On `bEnabled` false, `MessageQueue.Reset()`. | S |
| SCR-B17 | `ActionDoorKeypadUsed` tells the keypad control whether the typed code succeeded. | ch.22 ActionDoorKeypadUsed; ch.23 Ex.11 | `ShockActionDoorKeypadUsed` — `RequestUsed` only; no `ApplyInWorld` override (`ShockAction.h:99` default false) | Action is a silent no-op; door never gets unlock signal from the keypad path. | Resolve keypad by Label; apply Success to control / linked door. | M |

---

## GAP table

| id | what the guide says (own words) | guide ref | our code | proposed fix | effort |
| --- | --- | --- | --- | --- | --- |
| SCR-G01 | ScriptableMovers listen on `TriggeredBy` for `MessageTrigger` and toggle keyframes; they also emit `MessageMoverOpening/Opened/Closing/Closed`. | ch.20 ScriptableMover; ch.23 Ex.8,10 | `ShockAnimatedProp` has keyframe helpers; **no** message consume/emit (repo search: only comments mention mover message classes) | Wire mover TriggeredBy + emit mover classes at keyframe ends. | L |
| SCR-G02 | `ArithmeticStatement` returns a computed value for nested Bindings (used in Ex.14). | ch.21 Arithmetic; ch.23 Ex.14 | No `ShockArithmeticStatement` type under BioShockRuntime | Add bool/float producer action matching UE2 ops. | M |
| SCR-G03 | `ActionGetLevelLabel` returns the map file label lower-cased. | ch.21 ActionGetLevelLabel; ch.23 Ex.14 note | No implementation | Thin producer from world/map name. | S |
| SCR-G04 | Watchers (`ActionCreateWatcher` / Enable / Disable) poll once per second and send `MessageWatcher`. | ch.21 Watchers | No watcher types | Optional; maps rarely use — defer or stub message path. | L |
| SCR-G05 | `bIsGameCritical` + level-change flush; `ShouldExecuteCriticalActionsImmediately` runs only critical rows without waits. | ch.20 Script properties; ch.21 Game-critical; ch.22 Critical actions | No critical-path execution in `ShockScriptRunner` | Track flag on actions; flush API on travel. | L |
| SCR-G06 | Cross-script local read `ScriptLabel.varname`; cannot create dotted names with Assign. | ch.21 Scopes | Only current `EnsureVariables()` | Resolve dotted names via registry + other runner scope. | M |
| SCR-G07 | `ActionSetLightProperties` applies LightType / period / phase / shadow when ChangeProperty set (flicker→steady idiom). | ch.21 General actions; ch.23 Ex.1 | `ShockActionSetLightProperties.h:16` — brightness/colour only | Map UE2 light enums onto UE5 light components. | M |
| SCR-G08 | Quest actions drive HUD goals / objectives / hints / arrow. | ch.22 Quests | Many quest actions still record-only (`ActionInitiateQuest` header, etc.) | Quest manager + HUD feed. | L |
| SCR-G09 | Fact DB with assert/retract/test/duration; survives level change. | ch.22 Facts | Player `AssertFact` exists; duration/retract/test completeness UNKNOWN | Full fact store + query actions. | M |
| SCR-G10 | TrainingScript ticks concepts, conditions, message triggers every frame. | ch.22 Training | Show/clear training message on player only; no TrainingScript actor tick | Import TrainingScript + concept graph. | L |
| SCR-G11 | `MessageSavegameRestored` for `_Resume` ambient scripts. | ch.20 Level start; ch.23 How scripts start | `DispatchLevelEntryMessages` sends `MessageLevelStarted` only (`ShockScriptSubsystem`) | Dispatch restore class on load path. | S |
| SCR-G12 | Message payload fields for filters and GetMessageValue (Instigator, PawnLabel, PawnClass, ActualClass, Reason, Keycode, …). | ch.20 Message filters; ch.21 GetMessageValue | Bus retains class+source (`message-class-gap.md`); **messageFilter decoding known open — not re-filed** | Shared payload struct on dispatch. | L |
| SCR-G13 | Large ch.22 surface still “records request; no X yet” (hand anim, movies, many AI/gatherer/security spawn helpers, bathysphere UI, …). | ch.22 throughout | ~115 stub default `ApplyInWorld` (`ShockAction.h:99`); headers say Records… | Prioritise by Medical/Welcome action census. | L |
| SCR-G14 | `ActionPlayAnimation` waits when `bWaitForCompletion`; mesh path for non-prop targets. | ch.22 ActionPlayAnimation | Partial: doors/props; generic mesh “records only” (`ShockActionPlayAnimation.h`) | Mesh AnimSequence + wait. | M |
| SCR-G15 | `ActionPostMovementGoal` fields: DesiredFocus, NeverSucceed, rotate flags, … | ch.22 ActionPostMovementGoal; ch.23 Ex.13 | Partial Configure (target/dest/name/priority/run) | Expand fields into AI goal struct. | M |
| SCR-G16 | `ActionWaitForQuestLogToFinish` waits for diary audio. | ch.22 | Runner has quest-log wait hooks; audio finish detection incomplete | Tie to diary playback end. | M |
| SCR-G17 | `ActionPropertyTest` only non-static int/float/byte; `maxPasses` all-or-count. | ch.21 ActionPropertyTest | Partial single-actor resolve path | Match multi-actor + type limits. | M |
| SCR-G18 | Temporary variables from value actions die when the list ends. | ch.21 Scopes | Return values live on action objects; no explicit temp scope teardown | Clear expression temps in `FinishExecution`. | S |
| SCR-G19 | `ActionExitScript` stops *every* Script with the Label. | ch.21 ActionExitScript | Registry `TMap` one runner per Label (`ShockScriptRegistry.cpp:11`) | Multi-map or iterate all matches. | S |
| SCR-G20 | TriggerVolume / TriggerRadius filter lists, MaxEnterCount, RequireClearTrace, etc. | ch.20 TriggerRadius / TriggerVolume | Relay is one-shot + Disabled; many volume fields not imported | Expand `UShockTriggerRelayComponent` + importer. | M |
| SCR-G21 | `ActionChangeLevel` refuses while player dead; persist flag. | ch.21 ActionChangeLevel | Need verify vs `ShockActionChangeLevel` | Align dead-player + persist. | S |
| SCR-G22 | Glossary terms (Label vs Tag, Global_, watcher, …) — documentation only. | ch.37 | N/A (no code) | Keep research notes aligned; no runtime work. | — |

---

## OK (verified match, brief)

- Script is an ordered `Actions` list started by messages (`ShockScriptRunner`).
- `TriggeredBy` comma list, trim, case-insensitive (`MatchesTriggeredBy`).
- Empty `TriggeredBy` → never message-starts; callees via ExecuteScript only.
- `TriggeredBy=all` works via dispatch of sources `All`/`all` (PawnDied, level start).
- `scriptMessageClass` required; base `Message` accepts all; `NAME_None` wildcard documented.
- One message at a time; overflow queued (`MessageQueue` while `bIsExecuting`).
- `enabled` / `bEnabled` gates starts and ExecuteScript via `StartExecution`.
- `ActionSetProperty` `enabled` → runner; `Disabled` → trigger relay (session fix, re-verified).
- Sequential StepOne; `ActionWait` latent with resolve-once.
- `ActionIf` ORs `testsOr`; inserts true/else branch.
- `ActionLoop` / `ActionExitLoop`; 1000-iteration cap (`MaxLoopIterations`).
- `ActionFor` counter assign + increment through EndValue.
- `ActionBlockingExecuteScript` / NonBlocking spawn child / PendingChild.
- `ActionExitScript` respects `TargetScript` (session fix).
- `ActionWaitForGoal` returns 0 immediately when no goal (session fix).
- `ActionVariableAssign` / IfNotExist / Increment / Decrement on a scope.
- Variable type infer True/False / numeric / else string (`InferVariableClass`).
- `resolveInfoList` variable + nested action binding (`ShockAction::ResolveParameters`).
- `ActionVariableAdd/Sub/Mul/Div` return temps; string `+` concatenates.
- `ActionPrintClientMessage` → player client message.
- `ActionGiveItemsToPlayer` refuses empty class / non-positive stack.
- Door actions expose `StayOpen` / `ForceClose` and call `AShockDoor`.
- `ActionMuteAI` sets `bMuted` on labelled AI.
- `ActionChangePressure` writes region pressure on player.
- `ActionSetOrUnsetInputContext` reaches player input context.
- Level entry dispatches `MessageLevelStarted` with map label + all.
- Real senders exist for PawnDied / TookDamage / ReceivedInventory / AIWeaponFired / trigger enter-exit (session work).
- `ActionCalcDistance` returns distance between two Labels.
- Glossary Label / message / Script actor meanings match how the port names things (ch.37).

---

## UNKNOWN

| id | question | how to resolve |
| --- | --- | --- |
| SCR-U01 | Do retail scripts ever set `scriptMessageClass` to intermediate bases (`MessageTrigger`, `MessageMover`) rather than leaf classes? | Census `scriptMessageClass` in exported Medical/Welcome/Recreation sidecars. |
| SCR-U02 | Exact UE2 `ForceClose` / blocked-close permission vs our `CloseDoor(bForceClose)`. | Diff decompiled door UC vs `AShockDoor::CloseDoor`. |
| SCR-U03 | Whether cooked PIE HostProject defines `WITH_EDITOR` such that SCR-B09 is latent only for packaged builds. | Build shipping vs editor and run `verify` effect/label cases. |
| SCR-U04 | Fact duration / times-asserted / retract semantics vs `ShockPlayer::AssertFact`. | Read player fact store + guide Fact section against one Medical assert script. |
| SCR-U05 | `ActionOpenDoor` “record-only success when no door” intentional for headless verifies? | Check verify scripts; then decide SCR-B13 severity. |
| SCR-U06 | ch.37 TriggerRadius “sphere” vs ch.20 cylinder — guide inconsistency only? | Measure imported TriggerSphere vs CollisionHeight usage in maps. |

---

## Chapter 23 examples — would our runtime match?

| # | example | verdict |
| --- | --- | --- |
| 1 | Stair lights | **Partial.** Disabled via SetProperty OK; lights miss LightType flicker; PlayEffect label gate (B09); Wait OK. |
| 2 | Exit/re-enter water arming | **Partial.** Disabled swap OK; effect play/stop same label/`WITH_EDITOR` risk. |
| 3 | Fort Frolic level start | **No.** Globals not shared (B03); collision/hide/light gaps; OpenDoor first-only (B07); pressure OK-ish. |
| 4 | Message filter Instigator=Player | **Blocked** by known-open `messageFilter` (not re-filed). |
| 5 | Cohen safe hack ambush | **Partial.** SpawnAI missing fields (known open); MuteAI OK; AttackTarget stand-in; self-disable OK. |
| 6 | Reminder loop | **Partial.** Loop/Wait/If/ExitLoop OK; training message sets a name only; globals for stop flag broken across scripts (B03). |
| 7 | HammerLock timer | **No.** Timers do not emit `MessageTimerExpired` (B10). |
| 8 | Lighthouse arrival | **No.** Fade does not wait (B12); SendTriggerMessage wrong (B01/B02); no mover consumer (G01); movie/hand/AI helpers stubby. |
| 9 | Friend killed + AnyFriendKilled | **Partial.** Blocking execute OK; facts/items partial; filter/PawnLabel known-open; globals (B03). |
| 10 | Welcome elevator | **No.** SendTriggerMessage Instigator/source (B01); movers do not listen/emit (G01). |
| 11 | Plasmid store keypad | **No.** GetMessageValue Keycode (B04); DoorKeypadUsed no-op (B17). |
| 12 | Lift template | **No.** Nested OrStatement (B05); GetMessageValue RA (B04); SendTriggerMessage (B01/B02); GetProperty/MoveTime wait may work if property resolve hits. |
| 13 | Cohen entrance | **Partial.** ExitScript target OK; WaitForGoal OK; PostMovementGoal/AISpeech/spotlight partial/stub; globals (B03). |
| 14 | Plasmid frequency arithmetic | **No.** AndStatement + ArithmeticStatement (B05/G02); `TriggeredBy=all` + PawnClass filter known-open. |

---

## Chapter 37 (glossary)

No separate runtime bugs. Terms for Label, TriggeredBy, Global_ variable, message filter, ScriptableMover, watcher, and game-critical action match the behaviour claimed in ch.20–22 (and therefore feed the BUG/GAP rows above). Guide-internal note: glossary calls TriggerRadius a sphere; ch.20 Collision table describes a cylinder — tracked as SCR-U06.

---

## Status (25 Sept)

y6 scripting-fidelity batch. Re-verified each audit cite against current tree before changing.
Already-done items (B01/B02 SendTriggerMessage, subclass message class, messageFilter, Global_/y5,
ExitScript target, WaitForGoal) were left alone.

| id | status | notes |
| --- | --- | --- |
| SCR-B04 | FIXED | `LastMessageFields` on runner (cleared on ExecuteScript start; queued messages keep theirs); `ActionGetMessageValue` reads fields case-insensitively with Source/Class aliases; absent → empty. |
| SCR-B05 | FIXED | And/Or/Not UPROPERTY renamed `bLhs`/`bRhs` → `Lhs`/`Rhs` so `FindPropertyByName(lhs)` lands; nested `UShockActionBool` evaluated inside `EvaluateBool`; `ActionBool::ApplyInWorld` publishes VariableBool. |
| SCR-B06 | FIXED | Type table after substitution: bool/name/string eq IgnoreCase; ordered ops on bool/name always false; numeric lhs coerces non-numeric rhs to 0. |
| SCR-B07 | FIXED | Open/Close/Lock/Unlock use `AShockDoor::CollectByLabel` (every match). |
| SCR-B08 | FIXED | Label compares IgnoreCase via `ShockScriptReflection::ActorMatchesLabel` (doors, AI CollectLabeled, pawn CollectLabeled, props, FindActorByLabel). |
| SCR-B09 | FIXED | Shared `ActorMatchesLabel` / `CollectActorsByLabel`; PlayEffect/SetProperty/HideOrShow/ChangeCollision/SetLightProperties/DestroyActor routed through it. Importer writes `BioShockLabel=<label>` (`import_level.py`, `import_scripts.py`) — **re-import needed** for packaged / non-editor resolve of already-imported maps. |
| SCR-B10 | FIXED | Per-runner timer (`StartScriptTimer` / tick → `MessageTimerExpired` under ScriptLabel); `ActionStopTimer` clears by label; second start restarts. |
| SCR-B11 | FIXED | `StartExecution` refuses when `bIsExecuting`. |
| SCR-B12 | FIXED | `ActionCinematicFadeView` latent pending (Duration+Hold) like ActionWait. |
| SCR-B13 | FIXED | Missing door label returns 0. **Verify impact:** `verify_script_doors.py` unchanged (only asserts `Request*` Last* labels, which still set). `verify_script_physics_timer.py` updated (player pending-timer asserts → per-runner timer). |
| SCR-B14 | DEFERRED | Tracked skip (DealDamage empty-target class-wide). |
| SCR-B16 | FIXED | `SetEnabled(false)` / reflection `enabled` → drops `MessageQueue`. |
| SCR-B17 | DEFERRED | No DoorKeypad / keypad-control actor class in BioShockRuntime; `ActionDoorKeypadUsed` still records Success/label only. Stopped here as asked. |
| SCR-G01 | DEFERRED | Tracked skip (movers). |
| SCR-G02 | FIXED | `UShockArithmeticStatement` (ADD/SUB/MUL/DIV) return VariableFloat for nested bindings. |
| SCR-G03 | FIXED | `UShockActionGetLevelLabel` returns lower-cased map short name. |
| SCR-G04–G07, quests/facts/training | DEFERRED | Tracked skips. |
| SCR-G19 | FIXED | Medical has duplicate Script label `StandingOnCremationBody` (×2). Registry is now `TMap<FName, TArray<Runner>>`; `ActionExitScript` stops every match via `FindAllScripts`. |

**Deliverable verify:** `tools/ue5/verify_scripting_fidelity.py` (positive + negative per changed item). Claude builds + runs headless.

---

## Status (27 Sept, y8)

y8 ScriptableMover + remaining scripting gaps. Re-verified each audit claim against the tree
before changing. Skipped as asked: G04 watchers, G05 critical, G08–G10 quests/facts/training, G13
stubs. Did not touch `ShockVariableScope` Global_ handling.

| id | status | notes |
| --- | --- | --- |
| SCR-G01 | FIXED | `AShockAnimatedProp` listens for `MessageTrigger` on `TriggeredBy` (TriggerToggle; ignore mid-move); emits `MessageMoverOpening/Opened/Closing/Closed` under `PropLabel` via subsystem. Registry notifies registered movers on dispatch. Importer writes `TriggeredBy` / StayOpenTime / TriggerOnceOnly / InitialState from `mover` record + `BioShockLabel` tag. |
| SCR-G07 | FIXED | `ActionSetLightProperties` ChangeProperty LightType / Period / Phase → `UShockLightEffectComponent` (Steady / Flicker / Pulse / Blink / Strobe / SubtlePulse / None). Brightness/colour unchanged. Shadow flag recorded when set. |
| SCR-G11 | FIXED | Load-from-slot sets `UShockGameInstance::bPendingSavegameRestore`; `DispatchLevelEntryMessages` sends `MessageSavegameRestored` (map + All/all) when consumed, else `MessageLevelStarted`. |
| SCR-G12 | FIXED | `AddStackToInventory` / `AddMoney` / `AddAdam` send `ActualClass`, `Amount`, `Reason`, `ItemClass`. `DispatchDoorKeypadUsed` carries `Keycode` (no keypad actor yet — SCR-B17). |
| SCR-G18 | FIXED | `FinishExecution` clears action return-value temps via `ResetActionRuntimeState` (script/global vars untouched). |
| SCR-G20 | FIXED (partial) | Relay + importer honour `triggerOnlyByLabels` / `triggeredByFilter` / `triggerOnlyByClasses` from `regionActor`. **MaxEnterCount** and **RequireClearTrace** are not in the C# regionActor export — left unwired (existing `triggerOnlyOnce` remains). |

**Deliverable verify:** `tools/ue5/verify_scripting_movers.py` (positive + negative per item). Claude builds + runs headless.

---

## RESULT (27 Sept, y8)

Implemented SCR-G01, G07, G11, G12 remainder, G18, G20 (filter lists only — MaxEnterCount /
RequireClearTrace absent from regionActor export). Lane: `tools/ue5/**`, `docs/research/**`.
No commit / Unreal build in this sandboxed run.
