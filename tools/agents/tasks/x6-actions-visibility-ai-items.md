---
worker: chatgpt
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# R2.2-2.4 — remaining record-only actions (visibility/collision/AI-script/items/HUD)

> **Run mode:** non-interactive, sandboxed — no UE launch/build. Read
> `docs/research/runtime-brain.md` §4/§7, the decompiled `tmp/uc_scripting/`/`tmp/uc_shockgame/`
> sources for each class named below, and — **first, before writing any code** — the CURRENT
> `.cpp` for every action in the list. Some of this roadmap's "trivial, still stub" claims from
> 9 Sept are **already fixed** by earlier work (a2-a20/c1-c4 phase batches, the R2.1 reflection
> pass). Re-audit against the live source; only touch what is genuinely still record-only
> ("validate params, set a `Last*`/tag field, return true, no world mutation").

## What's confirmed still record-only as of 16 Sept (verify this list, don't trust it blindly)

- `ActionChangeStaticMesh` — `ApplyInWorld` only tags the actor `ShockMesh_<name>`, never calls
  `UStaticMeshComponent::SetStaticMesh`. Fix: resolve the mesh from
  `/Game/BioShockSlice/Content/Meshes/<name>` (same `_load_mesh` search path as
  `import_slice_pickups.py`) — but that's Python-side; the C++ action should accept a
  `UStaticMesh*` pointer resolved by a small runtime helper (`LoadObject<UStaticMesh>` against
  both `/Game/BioShockSlice/Content/Meshes/` and `/Game/BioShockLevel/Content/Meshes/`, mirroring
  `ShockScriptReflection`'s style) and actually swap it on the target's `UStaticMeshComponent`.
- `ActionAttackTarget`, `ActionTweakAIVision`, `ActionTweakAIHearing`, `ActionToggleAIReactions`,
  `ActionWaitForGoal`, `ActionWaitForQuestLogToFinish`, `ActionDisableOrEnableConcept`,
  `ActionSetOrUnsetInputContext`, `ActionPlaceItemInContainerSlot`, `ActionChangePressure`,
  `ActionDealDamageInRadius` — spot-checked 16 Sept, all still record-only.
- **Already real, do NOT touch unless you find a genuine bug:** `ActionHideOrShowActor`
  (`SetActorHiddenInGame`), `ActionSetActorLabel` (`SetActorLabel`), `ActionSpawnAI`,
  `ActionTeleportPawnToLocation`, `ActionMuteAI`, `ActionShowTrainingMessage`,
  `ActionSetTipPriority`, `ActionGiveItemsToPlayer`, `ActionFreezeHavokActor` (calls
  `UShockPhysicsLibrary::SetActorPhysicsFrozen` — real).
- `ActionChangeCollision` is PARTIALLY real: only `CollideActors` → `SetActorEnableCollision` is
  wired; `CollideWorld`/`BlockActors`/`BlockPlayers`/`BlockNonZeroExtentTraces`/`WorldGeometry`/
  `BlockHavok` are declared (`EShockCollisionChange` per-field) but never applied. Finish it:
  each field that isn't `DoNotChange` should set the matching collision response/channel on the
  target's primitive component (`SetCollisionResponseToChannel(ECC_Pawn, ...)` for
  `BlockPlayers`, `ECC_WorldStatic` for `CollideWorld`/`WorldGeometry`, etc. — check
  `tmp/uc_shockgame/ActionChangeCollision.uc` for the exact UE2 channel mapping).

## What to build

For each genuinely-stub action above: implement the real effect (world mutation), following the
existing pattern in that file (most already have `ApplyToActor`/`ApplyInWorld` plumbing and a
`FindByLabel`/`ShockScriptReflection::ResolveTargetActor` resolution — reuse it, don't
reinvent). Where an action needs an AI-side hook that doesn't exist yet on `ABaseShockAI` (vision/
hearing radius setters, a reaction-mute flag, a goal queue), add the minimal real property/method
— small, not a redesign of the w13 behaviour SM.

## Deliverable

- `docs/research/action-batch-r22.md` — which of the "confirmed still record-only" list turned
  out to already be fixed (if any), what each fix does, and the UE2 channel-mapping table for
  `ActionChangeCollision`.
- The real implementations (additive, one file per action, same file layout as today).
- Headless: extend or add `verify_action_batch_r22.py` — spawn a target actor, drive each fixed
  action, assert the real state changed (mesh swapped / AI vision radius changed / collision
  channel changed / etc.), plus a `ChangeCollision` case per non-`CollideActors` field.

## Constraints

- `tools/ue5/**` + `docs/research/**` + `tmp/**`. Additive.
- Don't regress existing suites — in particular `run_action_property_test.py`,
  `verify_reflection_actions.py` (R2.1, 7/7), `verify_import_scripts.py` (R1.1 parameter
  resolution, 5/5), and any per-action verify already covering something on the "already real"
  list.
- Do NOT commit. Diff + RESULT.json.
