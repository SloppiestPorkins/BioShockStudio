---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py, docs/research/**
---

# First-person camera has to react to walking, jumping, crouching

User (7 Sept 2026, PIE): "camera needs to react to walking jumping and crouching."

Right now the view is rigid — it just tracks the capsule. BioShock 1's first-person camera has
constant subtle life: a walk/run bob, a step-timed sway, a dip-and-recover on landing, weapon
and view kick, and a smooth (not instant) height change when crouching.

**Depends on v5** (movement + camera-height notes in `ShockPlayer.cpp` ~line 1528, and the v4
`BaseEyeHeight`/`CrouchedEyeHeight` work). Cut this worktree after v5 lands.

## What to build (in `AShockPlayer` / its camera component)

- **Walk/run bob** — vertical + lateral offset driven by a phase that advances with horizontal
  speed, amplitude scaling from 0 at idle to full at run speed, blending out in air. Tune to
  BioShock: present but not nauseating. A slight roll on the lateral peak reads well.
- **Landing dip** — on `Landed`, push the camera down proportional to impact velocity (clamp)
  and spring it back over ~0.2–0.35s. Bigger fall = bigger dip. This is the single most
  important one for "reacts to jumping".
- **Jump/takeoff** — small upward/again-settle kick as the jump impulse applies, optional.
- **Crouch** — the eye height change between `BaseEyeHeight` (60) and `CrouchedEyeHeight` (36)
  must interpolate over the crouch transition, not snap. UE's `Crouch()`/`UnCrouch()` already
  lerp the capsule; make the camera follow that smoothly (and check it doesn't fight the v4
  eye-height constructor set-up or clip through geometry when standing under a low ceiling).
- **Head-leading micro-sway** — a tiny delayed lag of the view behind fast mouse turns adds
  weight; keep it small and make it disable-able.
- All of it: gated by a single `bViewEffectsEnabled` (default on) and scaled by a
  `ViewBobScale` so it can be dialled or turned off; respect `bMovementDisabled` (no bob during
  a cutscene/lock).

Source-check `tmp/uc_shockgame/` — `ShockPlayerCamera` / `PlayerCamera` / `ShockPlayer.uc`:
`WalkBob`, `BobAmplitude`, `BobFrequency`, `LandBob`, `bobtime`, `ShakeOffsetRate`, any
`CameraEffect` / view-shake classes and their real magnitudes. Map those to UE; where a value
isn't in the UC, label it feel-tuning.

## Deliverable

- Camera reactions in `ShockPlayer.{h,cpp}` (or a small `UShockViewEffectsComponent`).
- `docs/research/camera.md` — the BioShock bob/land/crouch constants found, the UE mapping,
  what's feel-tuned, the toggle/scale knobs.
- Headless: `run_game_movement` still green (`MOVE_Walking`); a check that a simulated `Landed`
  from a fall produces a non-zero then decaying camera pitch/Z offset; crouch eye-height
  transitions over >1 frame.
- `-game` capture sequence: walking (bob visible across frames), mid-jump, just-landed (dip),
  crouched (lower eye height) — a few settle values.

## Constraints

- `tools/ue5/BioShockRuntime/**` + `tools/ue5/*.py` + `docs/research/**` only.
- Editor CLOSED for headless ops. Kill stray procs between runs. `-run=pythonscript` → JSON out.
  MSYS: forward-slash paths + `MSYS_NO_PATHCONV=1`.
- Don't touch h11 compiled-world mobility/collision.
- Do NOT commit. Diff for review; human does the final PIE feel-check.
- Read `tmp/uc_shockgame/` before deriving bob/shake magnitudes.
