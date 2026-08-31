---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C2 of `docs/FULL_GAME_CONVERSION.md` (see the corrected C2 section — the AI is
goals+abilities, NOT states). Build the AI brain framework and migrate the slice combat onto it,
so adding an enemy behaviour = adding an ability, not editing the combat tick.

## Spec (from `tmp/uc_shockai/`, decompiled — bodies are degraded, hierarchy + defaults are clean)
- `Aggressor extends EcologyFighter`. `Aggressor` `addAbility_Class`: AggressorCommanderAction,
  MimicAction, HealAtHealthStationAction, ReactToAlertGathererAction, HeadTrackingAction,
  CharacterMoveToAction, FleeAction, MoveToAction. `EcologyFighter`: MoveToSpawnPointAction,
  PatrolAction, SearchAction, InvestigateAction, FrozenAction, ShockedAction,
  FullBodyReactionAction, BurningAction, ReactToSwarmAction.
- `RangedAggressor extends Aggressor`: `bHasRangedAttack=true`, `bPrefersRangedAttack=true`,
  `RangedWeaponClass` / `MeleeWeaponClass`, collision 50/82, `MinDistanceFromLastKnownLocation
  ToLoseTarget=300`.
- The a9 combat FSM (`EShockAICombatState` Idle/Chase/Attack on `ABaseShockAI`, `TickCombat`) +
  a11 ranged branch + a18 nav + a20 hit-react are what exists today.

## Do
1. **`UShockAIGoal`** (UObject): `GoalType` enum (Idle, Patrol, KillTarget, MoveTo, Flee,
   Investigate, React), a target `AActor*` / `FVector` / `FName` param bag, `Priority` float.
2. **`UShockAIAbility`** (UObject base): `TArray<EGoalType> AchievableGoals`,
   `virtual bool CanAchieve(const UShockAIGoal&, const FShockAIContext&)`,
   `virtual void Enter/Tick(float)/Exit()`, `virtual EAbilityStatus GetStatus()` (Running /
   Succeeded / Failed). Latent-safe (no blocking).
   First set (each its own .h/.cpp): **IdleAbility, PatrolAbility, MoveToAbility,
   MeleeAttackAbility, RangedAttackAbility, FleeAbility, HitReactAbility.** Their logic is the
   corresponding slice behaviour that already exists — MoveToAbility = a18's nav MoveToActor
   with the straight-line fallback; MeleeAttackAbility = a9's melee (MeleeRange, MeleeCooldown,
   `UShockDamageLibrary::ApplyDamage(..., "Melee")`); RangedAttackAbility = a11's `FireAt`
   branch; HitReactAbility = a20's stagger. Move the code, don't rewrite it.
3. **`UShockAIBrain`** (`UActorComponent` on `ABaseShockAI`, created in its ctor): owns the
   ability list (seed from `ABaseShockAI::AITypeName` / archetype — a default list for now:
   Idle, Patrol, MoveTo, MeleeAttack, RangedAttack (if `bIsRanged`/has weapon), Flee (below
   `FleeHealthFraction`), HitReact). `ThinkInterval` ~0.2s: build the candidate goal list from
   perception + state (see player in `SightRadius`/cone/LoS → KillTarget prio 100; took damage
   from player → KillTarget; low health → Flee prio 120; no target → Patrol prio 10 / Idle 0),
   pick highest-priority goal with a `CanAchieve` ability, run that ability's `Tick`. Switch
   ability on goal change (Exit old, Enter new).
4. **Migrate `ABaseShockAI::TickCombat`**: it now just drives `UShockAIBrain::Think` + the
   active ability's `Tick`. Keep `bToldToWait` / `bCanAttack` / `bIsDead` gating. Keep
   `EnableFloorlessMovement()` for headless. Delete the Idle/Chase/Attack `switch` once the
   abilities cover it — or keep it behind a `bUseBrain` UPROPERTY (default true) with the FSM as
   fallback if that's safer to land.
5. **Aggro/damage hook**: a20's `NotifyAggroFromPlayer` / `ReactToHit` feed the brain (set a
   pending KillTarget goal + trigger HitReactAbility) instead of poking `CombatState` directly.
6. `run_ai_brain.py` / `verify_ai_brain.py` — headless: spawn the slice melee AI + a target,
   assert the brain picks KillTarget → MoveToAbility closes distance → MeleeAttackAbility drops
   the target's health on cadence; a ranged AI uses RangedAttackAbility from range; a
   `bToldToWait` AI runs IdleAbility and does nothing; damage triggers HitReactAbility (attack
   interrupted). `Success - N error(s)`.
7. `docs/FULL_GAME_CONVERSION.md` C2: tick status + the ability set landed.

## Constraints
- `tools/ue5/**` + one C2 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **The slice must fight identically** — same SightRadius / MeleeRange / MeleeDamage /
  MeleeCooldown / RangedRange values, damage still 100→75 on hitscan, same 3-enemy encounter.
  `run_game_possess.py` (`-bioshockverifypossess`) must still log `BIOSHOCK_SLICE_OK` +
  `BIOSHOCK_POSSESS_OK`. `run_ai_combat` / `run_ai_nav` / `run_hit_reaction` must still pass.
- Do NOT touch the damage path, weapons, HUD, player, or the FSM's *tuning numbers* — this is
  restructuring how the AI decides, not what it does.
- **Partial is fine**: Brain + Goal + Ability base + MoveTo + MeleeAttack + Idle, with the FSM
  kept as `bUseBrain=false` fallback and Patrol/Flee/Ranged/HitReact noted as TODO — as long as
  it compiles and every existing verify stays green.
- `docs/ENGINEERING_RULES.md`: smallest correct change, move-don't-rewrite the existing
  behaviour, verify each claim, PLAUSIBLE labels where the ability logic isn't from the source.
