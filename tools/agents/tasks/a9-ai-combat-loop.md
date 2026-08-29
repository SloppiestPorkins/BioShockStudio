---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Give `ABaseShockAI` a minimal autonomous combat loop so the slice enemy actually engages the
player, using the shared damage path from `5e822ec`.

## Context
`ABaseShockAI` already carries the state flags (`bVisionOn`, `bCanAttack`, `bToldToWait`,
`bAlwaysSeePlayer`, `AttackOnSightLabels`, `CurrentScriptedAttackTarget`, `bVulnerable`,
`ScriptedAIState`) and `ScriptedAttackTarget(Target)` / `AddTargetToAttackOnSight()`. What's
missing: anything that *acts* on them per frame. The slice enemy currently just stands there.
`UShockDamageLibrary::ApplyDamage` is the damage entry point.

## Do — a minimal, hardcoded 3-state tick FSM. NOT a StateTree / behavior tree.
The real UnrealScript-states → StateTree decision is deferred (`UE5_FULL_PORT_PLAN.md` §5
Phase 3) — do NOT make that architectural choice here. Just a `TickComponent`/`Tick` switch:

1. **Idle** — no target. Acquire one: if `CurrentScriptedAttackTarget` is set and alive → Chase.
   Else if `bCanAttack` && !`bToldToWait` && vision on && a `AShockPlayer` is within
   `SightRadius` (and, unless `bAlwaysSeePlayer`, within a ~90° forward cone and not fully
   occluded by a line trace) && (`HasAttackOnSightLabel` for the player's label OR a
   `bAggroOnDamage` flag you add that gets set when the AI takes damage) → set target, → Chase.
2. **Chase** — target set, out of melee range. Face the target (yaw only), drive
   `AddMovementInput` toward it (respect `bMovementShouldRun` for speed). Lose the target if it
   dies, goes `bIsDead`, or leaves `SightRadius * 1.5` for > `LoseTargetSeconds` → Idle.
   In melee range → Attack.
3. **Attack** — in range. On a `MeleeCooldown` timer, face target and
   `UShockDamageLibrary::ApplyDamage(Target, MeleeDamage, this, "Melee")`. Out of range → Chase.
   Target dead → Idle.

- Tunables as `UPROPERTY(EditAnywhere)` on the AI with sane defaults (SightRadius ~2500,
  MeleeRange ~180, MeleeDamage ~15, MeleeCooldown ~1.2s, LoseTargetSeconds ~5).
- Throttle the perception scan (e.g. every 0.25s), not every frame.
- Gate the whole loop: if `bIsDead` || `bToldToWait` || !`bCanAttack` → do nothing (stay/return
  to Idle). A scripted `TellAIToWait` must still freeze it.
- Wire "took damage → aggro": in `UShockDamageLibrary::ApplyDamage`, when the target is an
  `ABaseShockAI` and `Instigator` is an `AShockPlayer`, set the AI's aggro flag + target. Keep
  that addition tiny.

## Verify
`run_ai_combat.py` / `verify_ai_combat.py` — headless: spawn the slice AI + a stand-in player
pawn in range, tick the world a few seconds, assert (a) the AI faced and closed distance,
(b) the player pawn's health dropped on the melee cadence, (c) a `bToldToWait` AI does nothing,
(d) an AI out of sight range does nothing. `Success - N error(s)`.

## Constraints
- `tools/ue5/**` + one `UE5_FULL_PORT_PLAN.md` §9 line. No `src/**`, `tests/**`. No commit/push.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.** Scratch → `$env:TEMP`.
- Smallest thing that makes the enemy fight. No nav-mesh dependency if avoidable (direct
  `AddMovementInput` is fine for the slice); if you do need nav, note it and keep a
  straight-line fallback.
- `docs/ENGINEERING_RULES.md`: confidence labels, verify each claim, don't gold-plate.
