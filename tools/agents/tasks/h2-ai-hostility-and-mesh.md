---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Fix: enemies never engage in real play; AggressorBabyJane renders upside down

## Context

`tools/ue5/setup_test_arena.py` (new this session) builds a persistent test map,
`/Game/BioShockSlice/TestArena`, with 3 `ABaseShockAI` enemies. Headless verify
(`verify_ai_brain.py`, `verify_ai_animation.py`, both manually step combat via
`advance_autonomous_combat()`) all pass. Live PIE in the actual saved map does not:
enemies never move or attack the player, and where a mesh appears at all it's upside
down. Both bugs are real, confirmed by code reading below — this is not a request to
re-diagnose from scratch, the causes are identified; implement the fixes.

## Bug 1: target acquisition requires a scripted label, general perception isn't enough

`ABaseShockAI::TryAcquireTargetFromPerception()`
(`tools/ue5/BioShockRuntime/Source/BioShockRuntime/Private/BaseShockAI.cpp`, ~line 960):

```cpp
for (TActorIterator<AShockPlayer> It(World); It; ++It)
{
    AShockPlayer* Player = *It;
    if (!CanPerceivePlayer(Player)) { continue; }

    const FName PlayerLabel = GetPlayerPerceptionLabel(Player);
    const bool bLabelMatch = HasAttackOnSightLabel(PlayerLabel);
    const bool bAggroMatch = bAggroOnDamage && Player == AggroInstigator;
    if (!bLabelMatch && !bAggroMatch) { continue; }   // <-- this is the bug

    SetCombatTarget(Player);
    return true;
}
```

`CanPerceivePlayer` already does real distance + sight-cone + line-of-sight (that part
is fine and correctly general). But acquiring the target additionally requires either:
- `HasAttackOnSightLabel` — the player's **editor actor label** matches a
  scripted `AttackOnSightLabels` entry (set via the existing
  `AddTargetToAttackOnSight(FName)`, which is how `verify_ai_brain.py` and
  `verify_ai_animation.py` get combat going — they know their spawned player's label
  is literally `"BrainPlayer"` because they set it themselves). In real PIE the
  player pawn is spawned by `AShockGameMode` from `DefaultPawnClass` and its actor
  label is engine-assigned (e.g. `ShockPlayer_C_0`) — nothing can predict or
  pre-register that label from a level-setup script.
- `bAggroMatch` — only true *after* this exact AI has already taken damage from
  that exact player (reactive, not initial engagement).

So a level-placed enemy with no scripted trigger and that hasn't been shot yet can
**never** acquire a target, no matter how long the player stands in plain sight. This
is the entire reason the arena's enemies never move or attack.

`bAlwaysSeePlayer` (which `CanPerceivePlayer` also checks) is a red herring here — it
only widens *candidate eligibility* (skips the sight-cone/LOS trace), it does not
bypass this label/aggro gate. It's also `BlueprintReadOnly`, unsettable from Python
anyway.

**Fix**: add a new bool, e.g. `bHostileToAnyPlayer` (`UPROPERTY(EditAnywhere,
BlueprintReadWrite, Category="BioShock|Combat")`, default `false` so scripted-trigger
levels are unaffected), checked as a third `||` alternative alongside `bLabelMatch` /
`bAggroMatch` in the condition above. This is a level-authoring flag for "this enemy
is hostile on sight, no scripted trigger needed" — the natural generalization of the
existing label system for arenas/playtests that don't have per-level attack triggers,
not a hack specific to the test arena. `EditAnywhere` + `BlueprintReadWrite` so it's
settable both from a Blueprint/level and from Python (`set_editor_property`), unlike
`bAlwaysSeePlayer`.

## Bug 2: AggressorBabyJane renders upside down when assigned as the AI's mesh

Confirmed: both `ABaseShockAI::EnsureCombatMeshAndAnims()` (added this session, see
`h1-enemy-animation`) and `UShockAiArchetypeLibrary::ApplyToAI()`
(`ShockAiArchetype.cpp` ~line 126) assign the mesh with a bare `SetSkeletalMesh(...)`
— neither sets any compensating relative rotation on the mesh component. `ACharacter`
expects its mesh component's relative rotation to match a specific convention (the
default UE mannequin rig sits at identity after `SetSkeletalMesh` with the standard
`(0, -90, 0)` yaw baked into the component by `ACharacter`'s constructor); if
AggressorBabyJane's skeleton was imported with a different forward/up-axis convention
than that (plausible — this project's own research docs, `docs/research/skeletalmesh.md`
and `docs/research/animationpackage.md`, document BioShock's Havok-sourced skeletal
data needing careful axis handling), the mesh displays rotated — reported as
"spawning upside down."

Investigate:
1. Compare AggressorBabyJane's import/bind-pose convention against a mesh that's
   known to display correctly in this project (there may not be another full-body
   character to compare against yet — if so, compare against the skeleton's own
   authored root-bone orientation vs. what `ACharacter`/`USkeletalMeshComponent`
   expects, or check the FBX/import settings used when AggressorBabyJane was brought
   in).
2. If it's a fixed, known rotational offset (e.g. exactly 180° in one axis), the
   fix is a compensating `Body->SetRelativeRotation(...)` alongside `SetSkeletalMesh`
   in both `EnsureCombatMeshAndAnims` and `ApplyToAI` (factor into one shared helper
   if that avoids duplicating the correction). If it's not a fixed offset (e.g. the
   import itself is wrong), say so rather than papering over it with a guessed
   rotation — a wrong guess here would look "less wrong" but still be wrong.
3. Also check whether collision on the AI's mesh component matters here:
   `ApplyToAI` sets `Body->SetCollisionEnabled(ECollisionEnabled::NoCollision)` on
   the mesh (capsule presumably still has collision) — confirm this isn't relevant
   to the orientation report, just note if it looks like an unrelated pre-existing
   choice worth flagging.

## Bug 3 (verify, don't assume): does mesh/animation setup actually run for actors loaded from a saved map?

All existing verification (`verify_ai_animation.py` etc.) spawns `ABaseShockAI`
fresh via `subsystem.spawn_actor_from_class` in the same Python session that then
ticks it — never an actor loaded from a `.umap` that was placed and saved in an
earlier session, which is exactly what `/Game/BioShockSlice/TestArena` is (enemies
were spawned by `tools/ue5/setup_test_arena.py`, then the level was saved; PIE loads
them from disk). Confirm `EnsureCombatMeshAndAnims()`/`TickAnimationDriver()` still
run correctly for a serialized/loaded actor — write or extend a verify script that
`level.load_level()`s `/Game/BioShockSlice/TestArena` (rather than spawning fresh)
and asserts the existing enemies there have a mesh assigned and the hostility fix
above lets them acquire and engage the (also real, GameMode-spawned) player. If this
diverges from the fresh-spawn behavior, that's itself worth noting since it points at
a `BeginPlay` vs `Tick`-first-call ordering issue specific to level-placed actors.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- After the fix, set `bHostileToAnyPlayer = true` on the three enemies already saved
  in `/Game/BioShockSlice/TestArena` (headless: load the map, find them by label —
  `Enemy_Melee`, `Enemy_Ranged_A`, `Enemy_Ranged_B` — set the property, re-save) so
  the existing test arena actually demonstrates the fix rather than needing a rebuild.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once
  verified, same style as the existing `h1` entry.
