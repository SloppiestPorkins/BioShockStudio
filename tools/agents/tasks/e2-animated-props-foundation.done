---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Foundation for script-driven animated props — fans, movers, turrets

In-editor the world is static: fans don't spin, platforms/gates that should slide don't move,
turrets sit inert. BioShock drives these through the script-action system (which E1 wires into
the slice). This task builds the runtime actors those actions target. **Do E1 first or in
parallel — E2 needs the script pipeline live to test the script-driven paths, but the actors
and the continuous-motion (fan) path stand alone.**

## Level data (Medical slice, `1-Medical.ue5-level.json`)

- **`ScriptableMover` ×12** — sliding/rotating kinematic geometry (gates, platforms, the
  accordion doors, lift sections). Dump one: its keyframes/target transforms, loop flag, speed.
- **`Fan` ×6** — continuously spinning; some are script-toggled (on/off, rate).
- **`Turret` ×8**, **`TurretSpawner` ×11**, **`AggressorSpawner` ×19** — `AShockTurret`
  (`ShockTurret.cpp`, 205 lines) exists; check whether it tracks a target / animates its barrel,
  and whether anything places or activates it.
- `Elevator_Switch*`, `Elevator_Button*` — elevator call buttons (interact → mover).

## What's already there

- **`ShockActionPlayAnimation`** (`ShockActionPlayAnimation.cpp`, 69 lines) — `PlayInWorld` finds
  the target actor by label, then `PlayOnActor` **only records `LastPlayedAnimation` and returns
  true — it plays nothing.** This is the stub to make real.
- **`ShockActionChangeAnimationRate`** — same class of stub; drives fan speed / mover rate.
- **`ShockActionSpawnTurret`**, **`ShockActionHackTurret`** — turret script hooks.
- **`AShockTurret`** — read it; extend, don't replace.
- `run_script_movement.py` / `verify_script_movement.py`, `run_script_world_move.py`,
  `run_script_fx.py` — the headless harness for this area.

## What to build

1. **`AShockAnimatedProp`** (or `AShockScriptableMover` + `AShockRotator` if cleaner) — a
   `Movable` static-mesh actor that supports:
   - **continuous spin**: an axis + rev/sec, running from BeginPlay (fans), toggleable and
     rate-settable at runtime.
   - **keyframe move**: interpolate `RelativeTransform` between a start and one or more target
     transforms over a duration, one-shot or ping-pong/loop (gates, platforms). Kinematic —
     sweep so it pushes/blocks the player, don't teleport through them.
   - a label so `ShockActionPlayAnimation` / `ShockActionChangeAnimationRate` /
     `SendTriggerMessage` targets can find it.
2. **Import wiring** — `import_level.py` (and whatever the slice setup calls): place
   `ScriptableMover` and `Fan` actors as `AShockAnimatedProp` with their mesh, label, and
   motion params read from the export. Fall back to a sensible default spin for fans whose
   params aren't in the export (say so in the doc).
3. **Make the action stubs real** — `ShockActionPlayAnimation::PlayOnActor` and
   `ShockActionChangeAnimationRate` drive the matching `AShockAnimatedProp` (start its move /
   set its spin rate). Keep the `Last*` recording for the headless verifies but add the actual
   effect.
4. **Turrets** — confirm `AShockTurret` visually reads as a turret (mesh, mounted pose) and
   tracks / faces a hostile pawn; wire `TurretSpawner` so turrets are placed (hostile by
   default, hackable). If barrel/pan animation needs a skeletal rig we don't have, a
   transform-driven pan/tilt toward the target is an acceptable approximation — document it.

## Deliverable

`-game` / capture evidence: a fan spinning, a `ScriptableMover` gate sliding when its script
fires (needs E1), a turret facing the player. `docs/research/animated-props.md` — what each
actor type does, what's confirmed from the export vs approximated, how the action stubs now
drive real motion. Headless: `verify_script_movement` + a new check that
`ShockActionPlayAnimation` moves a spawned `AShockAnimatedProp` and `ChangeAnimationRate`
changes its spin.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless ops. Kill stray procs between runs.
- `-run=pythonscript` swallows `unreal.log` — JSON out.
- MSYS: forward-slash Windows paths + `MSYS_NO_PATHCONV=1`.
- Do NOT commit. No `docs/HANDOFF.md` claim row. Diff for review.
- Don't invent skeletal animation data. Transform-driven motion is the fallback and is fine —
  label it as an approximation where it is one.
