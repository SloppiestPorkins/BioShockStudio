---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Animated props aren't live in the playable slice

E2 (`e4c91f5`) built the runtime for script-driven animated props — `AShockAnimatedProp`
(continuous spin + keyframe move), turrets, the `ShockActionPlayAnimation` /
`ShockActionChangeAnimationRate` effect paths. `docs/research/animated-props.md` documents it.
**But the playable slice predates it and has no repair step**, so in-editor the world is still
static: fans don't spin, `ScriptableMover` gates/platforms don't move, turrets sit inert.

The slice manifest places (per `docs/research/animated-props.md` / E2 task):
- `ScriptableMover` ×12, `Fan` ×6, `Turret` ×8, `TurretSpawner` ×11, elevator switches/buttons.
- Plus the skeletal animated-prop rigs already imported (`AccGateAnim`, `Gate01Anim`,
  `IceBulge*`, `WallTechAnim_*`, `LiveWireAnim`, fish schools, whale) — some may just need their
  looping anim set to play.

## What to build

1. **`tools/ue5/import_slice_animated_props.py`** (mirror `import_slice_doors.py`): place `Fan`
   and `ScriptableMover` actors as `AShockAnimatedProp` with mesh + motion params from the
   export; give fans a default spin where params are absent (document it). Set the skeletal
   animated-prop rigs to play their idle/loop clip.
2. Confirm `ShockActionPlayAnimation` / `ChangeAnimationRate` (E2 made these real) actually
   drive the placed props when their script fires — the script system is live in the slice now
   (`14b2157` / `35c7a3b`).
3. Turrets: place `Turret` actors (hostile, hackable), barrel/pan tracking toward a hostile
   pawn — coordinate with w2 (`TurretSpawner`) so you don't double-place.
4. Add to `setup_playable_slice.py` STEPS.

## Deliverable

- `import_slice_animated_props.py` + STEPS wiring; `animated-props.md` updated with the slice
  placement step.
- Headless: `verify_animated_props.py` (or extend `verify_script_movement`) — N fans placed and
  spinning (rotation delta over 2 ticks), a `ScriptableMover` moves when its script fires, a
  turret faces the player.
- `-game` captures: a fan mid-spin (a few settle values), a gate sliding.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless. `-run=pythonscript` → JSON. MSYS
  forward-slash + `MSYS_NO_PATHCONV=1`.
- Don't invent skeletal animation — transform-driven spin/move is the documented fallback.
- Do NOT commit. Diff for review.
