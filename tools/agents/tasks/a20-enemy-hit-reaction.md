---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Make enemies react when hit — a brief flinch (interrupt, knockback, flash) — so shooting them
reads as connecting. Asset-free; no animation.

## Context
`UShockDamageLibrary::ApplyDamage(Target, Amount, Instigator, Type)` (`5e822ec`) is where a
pawn's health drops and `NotifyAggroFromPlayer` fires for AI. `ABaseShockAI` has the combat FSM
(`8556d17`) with `MeleeCooldown` / `RangedCooldown` and `TickCombat`. `bIsDead` /
`OnDeathFromDamage` already handle death. Right now a live hit does nothing visible except the
number changing.

## Do — on `ABaseShockAI`, triggered from `ApplyDamage` when the target is a live AI
1. `ReactToHit(float Amount, AActor* Instigator)`: 
   - **Stagger:** set `HitReactRemaining = HitStaggerSeconds` (~0.35 s scaled slightly by
     `Amount / AuthoredMaxHealth`, capped). While `HitReactRemaining > 0`, `TickCombat` skips
     the attack action (melee swing / ranged fire) and movement is slowed to ~40% — the AI can
     still turn to face. It does NOT drop the target or leave Chase.
   - **Knockback:** a small impulse away from the instigator — `LaunchCharacter` or an
     `AddImpulse` on the movement, magnitude ~`HitKnockback` (~250) scaled by damage, clamped so
     a full magazine doesn't rocket them across the room. Skip for `bCannotBecomeUnconscious`.
   - **Flash:** briefly tint the skeletal mesh — set a scalar/vector param on a dynamic material
     instance (create one lazily on `GetMesh()`), e.g. an emissive white pulse for ~0.12 s via a
     timer, then restore. If the material has no suitable param, fall back to
     `SetOverlayMaterial` with a transient tinted `MID` for the same duration, or
     `SetRenderCustomDepth` — whichever is asset-free and visible.
2. Rate-limit: at most one flinch per ~0.15 s so rapid TommyGun fire doesn't lock the AI in
   permanent stagger (accumulate — extend the timer a little, don't re-trigger the full effect).
3. `BIOSHOCK_HIT_REACT ai=%s amount=%.0f stagger=%.2f` log.
4. `run_hit_reaction.py` / `verify_hit_reaction.py` — headless: damage an attacking AI mid-swing,
   assert its attack was interrupted (no `ApplyDamage` to the player during the stagger window),
   it moved away from the instigator, and the stagger clears; rapid fire doesn't permanently
   freeze it. `Success - N error(s)`.
5. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.**
- Do NOT change `ApplyDamage`'s math, the damage numbers, weapon behaviour, death handling, or
  the FSM's Idle/Chase/Attack transitions — only *insert a stagger window* inside Chase/Attack.
- Knockback must be clamped — a hit must never launch the AI out of the play area or into the sky.
- `docs/ENGINEERING_RULES.md`: smallest correct change, timer not poll, verify each claim.
