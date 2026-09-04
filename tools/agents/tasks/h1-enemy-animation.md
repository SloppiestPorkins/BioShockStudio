---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Play real animations on `ABaseShockAI` enemies — idle, move, melee attack, hit react, death

## Goal

`ABaseShockAI` enemies currently have no animation driver at all — spawned with a skeletal mesh
(where one is assigned) but nothing ever calls `PlayAnimation` on it, so they either T-pose or hold
whatever pose the mesh imported in. This task wires state-driven `PlayAnimation` calls, the same
mechanism already proven for the player's first-person hands — **no AnimBlueprint, no state
machine asset**, just `USkeletalMeshComponent::PlayAnimation(UAnimSequence*, bool bLoop)` switched
by the AI's current brain ability, matching the project's own existing pattern exactly.

## The exact precedent to copy

`tools/ue5/BioShockRuntime/Source/BioShockRuntime/Private/ShockPlayer.cpp`,
`AShockPlayer::EnsureViewHands()` (~line 176-214):

```cpp
USkeletalMesh* Hands = LoadObject<USkeletalMesh>(
    nullptr, TEXT("/Game/BioShockWeapons/NEWPlayerHands/NEWPlayerHands.NEWPlayerHands"));
ViewHands->SetSkeletalMesh(Hands);
if (UAnimSequence* Idle = LoadObject<UAnimSequence>(
        nullptr, TEXT("/Game/BioShockWeapons/NEWPlayerHands/Animations/FidgetTommygun.FidgetTommygun")))
{
    ViewHands->PlayAnimation(Idle, true);
    ViewHands->TickAnimation(0.0f, false);   // pose immediately, don't wait for next tick
    ViewHands->RefreshBoneTransforms();
}
```

Same `LoadObject<T>(nullptr, TEXT("/Game/Path/Asset.Asset"))` pattern, same
`PlayAnimation(seq, bLoop)` call, same immediate-pose-refresh trick when something reads the pose
right after setting it (sockets, bounds).

## What's already in the project — verified present, don't re-check

`AggressorBabyJane`'s mesh, skeleton and **486 animations** are already imported at
`/Game/BioShockCharacters/AggressorBabyJane/`:

- Mesh: `/Game/BioShockCharacters/AggressorBabyJane/AggressorBabyJane.AggressorBabyJane`
- Skeleton: `/Game/BioShockCharacters/AggressorBabyJane/AggressorBabyJane_Skeleton.AggressorBabyJane_Skeleton`
- Animations: `/Game/BioShockCharacters/AggressorBabyJane/Animations/<Name>.<Name>`

For the melee-splicer archetype (`ME_` prefix — matches `Agg_BabyJane`, the archetype
`verify_ai_brain.py` already spawns as `"BrainAI"`), confirmed present by filename:

| Purpose | Candidate assets (pick one per state; `_A`/`_idle` variants exist for most) |
|---|---|
| Idle | `ME_Fidget_A_idle`, `ME_fidget_SingleFrame_idle` |
| Walk | `ME_WalkFWD_A_agg`, `ME_WalkFWD_A_idle` |
| Run | `ME_runFWD_A_agg`, `ME_RunFWD_B_agg` |
| Melee attack | `ME_attackMelee_A` through `_M` (9 variants — A is fine to start) |
| Hit react (forward) | `ME_hitFWD_A` through `_D` |
| Hit react (backward) | `ME_hitBWD_A` through `_D` |
| Death | `Death_StumbleFWD`, `Death_StumbleBWD`, `Death_SpinLeft`, `Death_GrabHead`, `DeathPoses` |

Confirm each exact asset path resolves (`unreal.load_asset` or in-editor) before hardcoding it —
the list above is from filenames on disk, not opened and checked one by one.

## Where to hook it in — `BaseShockAI.h` / `.cpp`

`ABaseShockAI::Tick()` calls `TickCombat()`, which — when `bUseBrain` is true (the default) — calls
`Brain->Think(DeltaSeconds)` and returns; the legacy `CombatState`/`TickCombatFsm` path is **not**
used by default, so don't drive animation off `CombatState`. Drive it off the brain's active
ability instead: `UShockAIBrain::GetActiveAbilityName()` (already exposed, used by
`verify_ai_brain.py` as `brain.get_active_ability_name()` — returns names like `IdleAbility`,
`MoveToAbility`, `MeleeAttackAbility`, `RangedAttackAbility`, `FleeAbility`, `HitReactAbility`).

1. Add a small state enum or just compare the ability `FName` each tick; only call
   `PlayAnimation` when the resolved state actually **changes** from the previous tick (calling it
   every frame restarts the animation from frame 0 every frame — check
   `USkeletalMeshComponent::IsPlayingRootMotion()`/whatever guard is idiomatic, or just track the
   last-played `UAnimSequence*` and skip if unchanged).
2. Map ability name → animation:
   - `IdleAbility` / no ability → idle loop.
   - `MoveToAbility` → walk or run loop (`GetVelocity().Size()` or `GetCharacterMovement()->MaxWalkSpeed`
     vs. current speed can pick walk vs. run if there's an easy signal; otherwise run is fine as the
     single "moving" anim to start).
   - `MeleeAttackAbility` → melee attack, **non-looping** (`bLoop=false`), then fall back to
     idle/move once it finishes (`GetMesh()->GetSingleNodeInstance()` or a timer sized to the
     sequence's own `GetPlayLength()` — do not hardcode a duration).
   - `HitReactAbility` → a hit-react clip, non-looping, alternating or random between the `_A`.._D`
     variants is a nice touch but not required — one fixed clip is a fine first cut.
3. Death: `ABaseShockAI::OnDeathFromDamage()` (already exists, ~line 654) is the hook — play a
   death clip there, non-looping, and let it hold on the last frame (do not blend back to idle).
4. Lazily load and cache the `UAnimSequence*` pointers (load once, e.g. in `BeginPlay` or on first
   use, not via `LoadObject` every tick) — same as `EnsureViewHands` loads the mesh once and checks
   `GetSkeletalMeshAsset()` before reloading.
5. **Mesh assignment**: if `ABaseShockAI`'s mesh component has no `SkeletalMeshAsset` set when this
   runs (bare C++ spawn, no Blueprint default), set it to `AggressorBabyJane` the same way
   `EnsureViewHands` sets `ViewHands`'s. Only set it if unset — don't override an explicitly
   different mesh a Blueprint subclass or archetype-driven spawn already assigned.

## Tests / verify

- `dotnet`/C# is untouched by this task; the `verify` command above (`rebuild_runtime_fast.ps1`) is
  the build check — it must succeed.
- Extend `tools/ue5/verify_ai_brain.py` (or add a new `run_ai_animation.py` /
  `verify_ai_animation.py` alongside the existing `run_ai_*`/`verify_ai_*` pairs) to spawn one
  `ABaseShockAI`, tick it through a melee engagement the way `verify_ai_brain.py`'s melee case
  already does, and assert: the mesh's `SkeletalMeshAsset` is `AggressorBabyJane` (or whatever you
  assign), an idle/move animation is playing before combat starts, the played animation changes to
  the melee-attack clip while `MeleeAttackAbility` is the active ability, and — kill the target
  (`unreal.ShockDamageLibrary` or however the existing tests deal lethal damage) — a death clip is
  playing afterward. Model the spawn/tick/assert shape on `verify_ai_brain.py`'s melee case
  directly; don't reinvent the harness.
- This cannot be verified by a screenshot from this worktree (no live UE session here) — say so in
  the result rather than claiming a visual check you didn't do. The headless assertions above (mesh
  assigned, correct anim sequence object playing at each state) are the evidence; a human confirms
  it looks right in PIE afterward.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only. Do not touch `src/**` or `docs/research/**`.
- Smallest correct change: no AnimBlueprint, no new Blueprint assets, no montage system — raw
  `PlayAnimation` switched by ability name, exactly like the existing viewmodel-hands code. If the
  brain's active-ability signal turns out not to be readable/stable enough for clean state
  switching (e.g. it flickers between abilities faster than an animation should cut), say so and
  pick the least surprising fallback (e.g. gate switches with a minimum-hold time) rather than
  inventing a bigger animation system.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry in the existing style
  (what was measured/verified, headless command) once this lands.
