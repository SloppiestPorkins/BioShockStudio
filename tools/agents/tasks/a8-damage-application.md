---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Build the shared damage-application path in BioShockRuntime, then wire the damage script
actions onto it. This is the piece the Phase 4 batches kept skipping ("needs infra"), and it's
core to "AI actually works" — enemies and the player taking scripted damage.

## Context
`BaseShockAI` already has health fields (`AuthoredHealth`, `CurrentHealth`, `bIsDead`,
`EnsureHealthInitialized`) and the slice hitscan drops health 100→75 directly in `ShockWeapon`.
`AShockPlayer` has its own health. There is no shared "apply N damage to actor X, honour
invincibility/vulnerability, mark dead, broadcast" routine — each site rolls its own. The
already-wired `SetPawnInvincibility` / `SetPlayerInvincibility` / `SetAIVulnerability` flags
exist but nothing reads them on a damage event.

Currently record-only stubs that need this: `ActionInitiateDamage` (45 refs),
`ActionDealDamage`, `ActionDealDamageInRadius` (+ `ActionDealShockingDamageInRadius`).

## Do
1. A `UShockDamageLibrary` (BlueprintFunctionLibrary) or `UShockCombatComponent` — match how
   this project structures shared runtime logic — with:
   - `ApplyDamage(AActor* Target, float Amount, AActor* Instigator, FName DamageType)` →
     resolves the target to `ABaseShockAI` or `AShockPlayer`, checks the relevant invincibility /
     `bCannotDie` / `bVulnerable` flags, subtracts from current health, clamps at 0, sets
     `bIsDead` and fires the existing death path (whatever `ShockWeapon`'s hitscan already
     triggers — reuse it, don't fork it), returns the damage actually applied.
   - `ApplyRadialDamage(FVector Origin, float Radius, float Amount, ...)` → iterates pawns in
     radius, falls off linearly, calls `ApplyDamage` per target.
2. Refactor the existing `ShockWeapon` hitscan damage to call `ApplyDamage` (so there is ONE
   path). Keep the 100→75 slice behaviour identical — verify the existing
   `BIOSHOCK_SLICE_OK fire=1` evidence still holds.
3. Wire `ActionInitiateDamage`, `ActionDealDamage`, `ActionDealDamageInRadius`,
   `ActionDealShockingDamageInRadius` to `ApplyInWorld()` calling the new library. Match the
   batch 1-3 pattern.
4. `run_script_damage_exec.py` / `verify_script_damage_exec.py`: headless — spawn an AI, apply
   scripted damage, assert health dropped and `bIsDead` at 0; assert an invincible target takes
   none; assert radial damage hits multiple and falls off. `Success - N error(s)`.
5. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line — the shared damage path + the 4 actions.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit, no push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.** Non-compiling = failed task.
- Do NOT change the slice's observable fire behaviour (100→75, hitscan pawn-only). Refactor
  under it, don't alter it.
- `docs/ENGINEERING_RULES.md`: smallest correct change, one path not several, verify each claim,
  confidence labels. Fast tier stays green.
