---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# Make the splicer AI 1:1 with BioShock 1

The spawners are placed (w2) and collision is solid — the player no longer dies on spawn and
AI no longer falls through the world. What's missing is **behaviour and animation fidelity**.
Right now a splicer reads as a generic UE enemy: it acquires the player and walks at them.
BioShock's splicers have a recognisable rhythm — idle ticks/mutters, a patrol path, an
*investigate last-known-position* when they lose you, a *search* sweep, cover use for ranged
types, a melee lunge for Thuggish, low-health flee, and a lot of vocal barks. Some AI also
**T-pose intermittently** (animation graph not driving) — fix that as part of this.

## Source of truth — read first

- `docs/research/enemies.md` (w2) — archetypes, `SpawnedMeleeThug` / `SpawnedRangedAggressorPistol`
  / `SpawnedGrenadier`, spawner field layout.
- The decompiled UC: `*AI*.uc`, `ShockAIController*.uc`, `EcologyFighter*.uc`, `AICombat*.uc`,
  the AI state machine / `LatentAIActions`. Derive the real state list, transition conditions,
  timings, perception ranges, morale/flee thresholds from these — do not invent them.
- `BaseShockAI.{h,cpp}`, `ShockAIController.*`, `ShockActionAISpeech.*`, existing `TickCombat` /
  `TickAnimationDriver` / `TickRagdollBlend`.

## Behaviour — match the shipped AI

1. **Perception** — sight cone + range, hearing (gunfire, footsteps, broken glass), memory of
   last-known player position, with the real falloff / time-to-forget from the UC.
2. **States** — Idle/Ambient → Patrol → Alert (heard something) → Investigate (move to
   last-known) → Search (sweep nearby) → Combat → Flee (below the UC morale threshold) →
   return-to-Idle. Melee (Thuggish) lunges and closes; Ranged (Pistol/Grenadier) keeps
   distance, uses cover if a cover point is near, strafes, reloads behind cover.
3. **Combat cadence** — burst-fire then reposition, not continuous fire; melee wind-up telegraph
   before the hit; the "spider" crawlers (if present in Medical) use ceiling/wall movement.
4. **Vocals** — hook `ShockActionAISpeech` / `UShockAudioLibrary` event cues to state entry
   (aggro bark, searching mutter, lost-player taunt, pain, death). The audio events exist from
   w1 — this is wiring them to the new states.
5. **Group behaviour** — a second splicer in earshot of combat goes to Alert/Investigate.

## T-pose fix

`run_ai_animation.py` currently reports OK headless, so the T-pose is intermittent / runtime.
Track down when `TickAnimationDriver` stops producing a pose — likely `EnsureCombatMeshAndAnims`
not having run before the first `TickCombat`, an anim asset that failed to load (falls back to
ref pose), or the mesh swap in `ApplyCombatSkeletalMesh` racing the anim init. Make the driver
resilient: if no montage/anim is active, force the idle loop; never leave the mesh on ref pose.

## Deliverable

- `docs/research/ai-behaviour.md` — the real state machine (states, transitions, the UC-sourced
  constants), perception model, per-archetype combat profile, what's approximated and why.
- Runtime: the state machine on `ShockAIController` / `BaseShockAI`, cover use for ranged,
  melee lunge, flee, investigate/search, vocal hooks, group alert. T-pose eliminated.
- Headless: extend `run_ai_animation.py` / add `verify_ai_behaviour.py` — assert an AI with no
  target patrols/idles (doesn't beeline a random point), transitions Idle→Combat on a simulated
  sight event, transitions Combat→Investigate when the target is hidden, flees below the morale
  threshold, and always has a non-ref-pose after 1s. JSON out. Log
  `BIOSHOCK_AI state=<x> archetype=<y> hasPose=1`.
- `-game` captures: a splicer patrolling, one investigating a noise, one in cover firing, one
  fleeing — `capture_shot.ps1` with whatever spawn/trigger flags you add.

## Constraints

- `tools/ue5/**` + `src/**` (additive, Fast tests green) + `docs/research/**` + `tmp/**`.
- Editor CLOSED for headless. `-run=pythonscript` → JSON. `MSYS_NO_PATHCONV=1` + forward-slash.
  Kill stray `UnrealEditor*.exe` between runs.
- Do NOT re-enable spawn-on-BeginPlay — the opening splicers stay script/proximity driven.
- Don't touch h11 compiled-world mobility/collision or the everything-complex-as-simple policy.
- Do NOT commit. Diff + RESULT.json for review; human confirms in Play.
