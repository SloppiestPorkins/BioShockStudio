# R2.2-R2.4 remaining action audit

Date: 16 September 2026  
Evidence: current `tools/ue5/BioShockRuntime` C++ plus the named decompiled classes under
`tmp/uc_scripting`, `tmp/uc_shockai`, and `tmp/uc_shockgame`.  
Status labels: **VERIFIED SOURCE** means the UE2 call is explicit in the decompile; **PORT
MAPPING** means the UE5 equivalent is an intentional mapping because UE2 actor flags do not have a
1:1 UE5 API.

## Live-source re-audit

The 9 September stub census was stale. The current tree already contained real actor/player state
changes from the a2-a20/c1-c4 batches. This patch did not replace those working implementations.

| Action | Live audit before this patch | Result |
|---|---|---|
| `ActionChangeStaticMesh` | Tag-only (`ShockMesh_*`) | Fixed: resolve a `UStaticMesh` under the slice then full-level mesh roots and call `UStaticMeshComponent::SetStaticMesh`. |
| `ActionAttackTarget` | Already real | Unchanged: resolves a living target and calls `ScriptedAttackTarget` or `AddTargetToAttackOnSight` on every labeled living AI. |
| `ActionTweakAIVision` | Already real | Unchanged: writes the flags read by `TryAcquireTargetFromPerception` / `CanPerceivePlayer`. |
| `ActionTweakAIHearing` | Already real | Unchanged: writes `bHearingOn`, which gates `NotifyHeardSound`. |
| `ActionToggleAIReactions` | Partial: enum bytes were stored but never consumed | Fixed: full-body now gates hit knockback; quick reactions gate stagger/audio/flash in `ReactToHit`. |
| `ActionWaitForGoal` | Partial: merely treated an active goal name as already satisfied | Fixed: scripted movement has completion/failure state and drives toward its destination; the runner holds the action until completion/failure/timeout and returns UE2's 0/1/2 result. |
| `ActionWaitForQuestLogToFinish` | Record-only (`LastQuestLogWait`) | Fixed: quest-log playback has a live player-side active set; the runner blocks on the named log until playback clears or the authored timeout expires. Producers call `SetQuestLogPlaying` at playback start/finish. |
| `ActionDisableOrEnableConcept` | Already real state mutation | Unchanged: updates the player's per-concept enabled map read through `IsConceptEnabled`. The larger TrainingScript presenter is outside this batch. |
| `ActionSetOrUnsetInputContext` | Partial: one current-name field, not UE2 PUSH/POP | Fixed: maintains a true ordered context stack; POP removes the most recent matching entry and restores the previous context. |
| `ActionPlaceItemInContainerSlot` | Validation only | Fixed: writes/merges/replaces an indexed slot on `AShockSearchableContainer`; searching transfers all scripted slots into the player's real inventory map. |
| `ActionChangePressure` | Already real state mutation | Unchanged: writes the player's region-pressure map through `SetRegionPressure`. |
| `ActionDealDamageInRadius` | Already real | Unchanged: resolves the source actor and calls `UShockDamageLibrary::ApplyRadialDamage`, including inner/outer falloff. |
| `ActionChangeCollision` | Partial: only `CollideActors` | Fixed for every authored field; table below. |

The `runtime-brain.md` section 4 labels for AttackTarget, radius damage, vision/hearing, pressure,
concept state, and input state are therefore superseded by the live code. No files for the task's
"already real" exclusion list were changed.

## Static-mesh resolution

**VERIFIED SOURCE:** `ActionChangeStaticMesh.uc` calls `Target.SetStaticMesh(StaticMesh)`.

The runtime strips an optional Unreal object wrapper/package prefix to the asset leaf, then uses the
same ordered roots as `import_slice_pickups._load_mesh`:

1. `/Game/BioShockSlice/Content/Meshes/<name>`
2. `/Game/BioShockLevel/Content/Meshes/<name>`

Failure to resolve either the target, mesh asset, or a `UStaticMeshComponent` returns failure and
does not leave a success tag behind.

## `ActionChangeCollision` mapping

`ActionChangeCollision.uc` reads each current UE2 actor flag, changes only fields not set to
`DoNotChange`, writes `bCollideWorld`, `bBlockNonZeroExtentTraces`, `bWorldGeometry`, calls
`HavokSetBlocking`, then calls UE2 `SetCollision(newCollideActors, NewBlockActors,
NewBlockPlayers)`. UE5 has component response channels instead of that actor-flag set.

| UE2 field | UE5 mutation | Confidence / reason |
|---|---|---|
| `CollideActors` | `AActor::SetActorEnableCollision` | **PORT MAPPING**; actor-wide master gate. |
| `CollideWorld` | primitive response to `ECC_WorldStatic` | **PORT MAPPING**; collision against level/world geometry. |
| `BlockActors` | primitive response to `ECC_WorldDynamic` | **PORT MAPPING**; non-player dynamic actors. |
| `BlockPlayers` | primitive response to `ECC_Pawn` | **PORT MAPPING**; player and pawn bodies. |
| `BlockNonZeroExtentTraces` | primitive response to `ECC_Visibility` | **PORT MAPPING**; the runtime's general swept/interaction trace channel. |
| `WorldGeometry` | primitive response to `ECC_WorldStatic` | **PORT MAPPING**; closest channel representation of UE2 `bWorldGeometry`. Applied after `CollideWorld`, so it wins if malformed authored data sets contradictory values. |
| `blockHavok` | primitive response to `ECC_PhysicsBody` | **PORT MAPPING**; Havok rigid bodies map to the UE5 physics-body channel. |

For response fields, `SetToTrue` maps to `ECR_Block`, `SetToFalse` to `ECR_Ignore`, and
`DoNotChange` performs no component write. Every primitive component on the target is updated.

## Container-slot semantics

**VERIFIED SOURCE:** the UE2 action validates container/slot/item/stack, rolls untouched loot before
editing, replaces an empty or explicitly-overwritten slot, merges a matching existing stack, and
rejects an incompatible occupied slot. The UE5 searchable container has no random-roll object or
per-item maximum-stack metadata, so this batch preserves the observable slot behavior as follows:

- empty slot: create the authored stack;
- overwrite: replace the slot;
- same item without overwrite: merge counts;
- different item without overwrite: reject;
- searched container: reject further scripted placement;
- search: grant slots in numeric slot order through `AShockPlayer::AddStackToInventory`.

The absent UE2 maximum-stack clamp remains **UNKNOWN** in this runtime because item-class default
maximums and the player's stack-size modifier are not imported.

## Headless verification

`tools/ue5/verify_action_batch_r22.py` creates throwaway actors and checks the actual changed state:

- static-mesh component pointer changes to a real imported asset;
- all seven collision fields, including one case for every non-`CollideActors` field;
- container slot contents and transfer into player inventory;
- input-context PUSH/PUSH/POP restoration;
- disabled versus enabled AI hit reaction behavior;
- active goal blocks and completed goal returns success;
- active quest-log playback blocks the runner and clearing it resumes the following action.

Per the task's sandbox mode, Unreal was not launched and the plugin was not built in this worktree.
The verifier is supplied for the next compiled headless run; this patch therefore makes no claim of
UE runtime execution evidence.
