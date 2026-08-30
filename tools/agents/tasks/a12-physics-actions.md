---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Build a shared physics-impulse path in BioShockRuntime, then wire the Havok/physics script
actions onto it — same shape as the damage path (`5e822ec`).

## Context
`UShockDamageLibrary` is the model: one library, all callers route through it, the script
actions call `ApplyInWorld()` on it. There is no equivalent for physics forces yet. Record-only
stubs that need this: `ActionApplyImpulse`, `ActionTriggerHavokForceActor`,
`ActionEnableOrDisableHavokForceActor`, `ActionFreezeHavokActor`,
`ActionEnableOrDisableCascadingWaterVolume` (if trivial), `ActionTelekinesisDropObject` (only if
self-contained). UE5 physics is Chaos — `UPrimitiveComponent::AddImpulse` / `AddRadialImpulse` /
`SetSimulatePhysics` / `PutRigidBodyToSleep`. Havok joint limits stay licence-blocked
(`UE5_FULL_PORT_PLAN` §5 Phase 3) — approximate, label PLAUSIBLE.

## Do
1. `UShockPhysicsLibrary` (BlueprintFunctionLibrary):
   - `ApplyImpulse(AActor* Target, FVector Impulse, bool bVelChange)` → finds the target's
     simulating `UPrimitiveComponent`(s), `AddImpulse`. If not simulating and the action implies
     it should wake, `SetSimulatePhysics(true)` first (guard behind a param).
   - `ApplyRadialImpulse(UWorld*, FVector Origin, float Radius, float Strength, bool bVelChange)`
     → `AddRadialImpulse` on sim bodies in range, linear falloff.
   - `SetActorPhysicsFrozen(AActor*, bool bFrozen)` → `SetSimulatePhysics(!bFrozen)` +
     `PutAllRigidBodiesToSleep` / wake; remember prior state so unfreezing restores it.
   - `FindActorByLabel` — reuse the one in `UShockDamageLibrary` or lift it to a shared helper;
     do NOT duplicate a third copy.
2. Wire the actions to `ApplyInWorld()` calling the library, matching the batch 1-3 pattern +
   `UShockScriptRunner` dispatch. Cap: 4-5 actions; drop any that isn't self-contained, record why.
3. `run_script_physics_exec.py` / `verify_script_physics_exec.py` — headless: spawn a simulating
   cube, apply a scripted impulse, assert it moved / gained velocity; radial impulse hits
   several; freeze stops motion, unfreeze restores simulation. `Success - N error(s)`.
4. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line — the physics path + the actions wired.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.** One physics path, not several.
- Don't touch the damage path, the combat loop, or player/weapon behaviour.
- `docs/ENGINEERING_RULES.md`: smallest correct change, PLAUSIBLE labels on the Havok
  approximations, verify each claim. Fast tier stays green.
