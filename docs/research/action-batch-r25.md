# R2.5 — world sim actions, re-audit + first landing

Per `docs/FULL_RUNTIME_PORT.md` R2.5. As with x6, re-audited the live tree first rather than
trusting the roadmap doc's stub list — `ActionChangePressure`, `ActionDealDamageInRadius`,
`ActionTriggerHavokForceActor`, and `ActionEnableOrDisableHavokForceActor` are all **already
real** (the last two call into `UShockPhysicsLibrary`'s radial-impulse/force-actor-enable state
directly). Only two of the R2.5 list were genuinely still dispatch-dead (no `ApplyInWorld`
override at all, base class no-op):

## `ActionEnableOrDisableCascadingWaterVolume` — now real

`AShockWaterVolume` already carried a `bCascading` field (the waterfall/ripple material look)
with no writer. The action resolves the labeled actor via `ShockScriptReflection::ResolveTargetActor`,
casts to `AShockWaterVolume`, sets `bCascading`, and calls `RefreshSurface()` to reapply the
surface material immediately. `verify_action_cascading_water.py`: 2/2 (enable sets+refreshes,
disable clears+refreshes).

## `ActionEnableOrDisableDamageVolume` — still stub, deliberately not attempted this pass

No damage-volume actor exists anywhere in the runtime — this needs a new `AShockDamageVolume`
(or equivalent trigger-volume component) that deals periodic damage to overlapping pawns while
enabled, plus the action wiring on top of it. That's new actor infrastructure, not a wire-up of
something half-built, so it's left as its own follow-up rather than rushed alongside the
already-real re-audit.

## Verify

`verify_action_cascading_water.py` 2/2. No regressions: `verify_action_batch_r22.py` (8/8),
`verify_reflection_actions.py` (7/7), `verify_effects_system.py` (5/5), `run_plasmid.py`.
