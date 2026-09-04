---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Fix player movement: MOVE_Falling, zero velocity, gravity never integrates

## The bug, confirmed by real test, independently reproduced twice

`h10`'s new `-bioshockverifymovement` hook (real `-game` mode, real possession, real
per-frame `Tick`) drives `MoveForward(1.0)` every frame for 2.5 real seconds after
possessing the player on `/Game/BioShockSlice/1-Medical`, then logs state. Both cursor's
run and an independent re-run of the exact same binary produced the same result:

```
BIOSHOCK_SNAP_FLOOR valid=1 blocking=1 mode=3 gravityZ=-980.0 findFloor hit=0 walkable=0 dist=-30.6 locZ=7856.31
BIOSHOCK_MOVEMENT_START x=-17320.00 y=1272.00 z=7856.31 mode=MOVE_Falling disabled=0 updated=1 tick=1 role=3 maxspeed=450
BIOSHOCK_MOVEMENT_END start=(-17320.00,1272.00,7856.31) end=(-17320.00,1272.00,7856.31) displacement=0.0 mode_start=MOVE_Falling mode_end=MOVE_Falling disabled_seen=0 controller=1 cmc=1 gravity=1.00 vel=(0.0,0.0,-0.0)
```

Zero displacement over 2.5 seconds. Zero velocity, even on Z, despite `gravityZ=-980`
and `MOVE_Falling` (a falling character with real gravity should be picking up downward
speed immediately — velocity staying at exactly `(0,0,-0.0)` for 2.5 straight seconds is
itself strange and worth explaining, not just "well it's stuck"). `controller=1`,
`cmc=1` (`IsActive()` true), `updated=1` (has an `UpdatedComponent`), `tick=1`
(component tick enabled) — every precondition for movement to work looks satisfied, and
it still doesn't move at all.

**`BIOSHOCK_SNAP_FLOOR`** (added this session, logged the instant `SnapPawnToStart`
places the pawn) is the sharpest clue: the plain `LineTraceSingleByChannel` used to place
the pawn on `ECC_WorldStatic` gets a valid blocking hit (`valid=1 blocking=1`) — the pawn
IS placed on real geometry. But `UCharacterMovementComponent::FindFloor`, called
immediately after at that exact same location, reports `hit=0 walkable=0` — the
movement component's own floor query finds nothing at all, right where the level trace
just confirmed solid ground.

## A concrete hypothesis to check first — not confirmed, don't assume it's right

Earlier this session, the compiled-world mesh's collision was fixed from an auto-
generated convex hull back to `CTF_USE_COMPLEX_AS_SIMPLE` (see
`fix_compiled_world_collision.py` / `reimport_compiled_world_only.py`), which also
**clears every simple collision primitive** (`convex_elems`, `box_elems`, `sphere_elems`
all set to empty). `CTF_USE_COMPLEX_AS_SIMPLE` is the standard, correct UE mechanism for
exactly this situation (architecture with only complex collision, walked on by
characters) and *should* make ordinary simple-collision sweeps resolve against the
complex geometry automatically — so this may not be the cause. But the timing lines up
(movement was never reported broken before that collision fix landed), and `FindFloor`'s
own sweep/line-trace setup (`ComputeFloorDist` in `CharacterMovementComponent.cpp`) is
exactly the kind of query that could behave differently against a mesh with zero simple
primitives, depending on trace-complexity flags and query defaults. **Verify this
directly** — e.g., temporarily test `FindFloor` against a mesh that still has real simple
collision, or read `ComputeFloorDist`'s actual trace setup (`bTraceComplex`, collision
channel, response mode) closely enough to state definitively whether `CTF_USE_COMPLEX_AS_SIMPLE`
alone explains a `hit=0` result — rather than assuming a match on timing is causation.

Other things worth checking, in no particular priority, before landing on one:
- Does anything call `StopMovementImmediately()` / zero `Velocity` on a repeating timer
  or every tick (would explain velocity staying pinned at exactly zero rather than
  merely small)?
- Is `AShockPlayer`'s or `ABaseShockAI`'s shared movement setup (`EnableFloorlessMovement`,
  `SetMovementDisabled`, or similar) leaving some state configured for a different context
  (e.g. AI nav-fallback floorless flight) that a player pawn shouldn't inherit?
- Does `UpdatedComponent` actually match the capsule component being queried, or could a
  root-component mismatch mean the movement component is querying floor position against
  the wrong transform?

## What "fixed" looks like

Re-run `run_game_movement.py` (`-bioshockverifymovement`) after the fix and get
`BIOSHOCK_MOVEMENT_OK` with real displacement (the test already asserts `displacement >
10.0` and rejects `MOVE_None`/`MOVE_Falling` at start or end) — not a relaxed threshold,
not a different success condition. If the fix requires touching the collision setup from
earlier, verify collision is still correct afterward too
(`tools/ue5/run_collision.py` — must stay 0 errors; do not trade the movement fix for a
collision regression).

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- This is the fourth investigation into this general area today (recoil, collision,
  static prop materials, now movement) — read what's already been found rather than
  re-deriving it, but verify rather than trust any single hypothesis in this brief,
  including the collision one above.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once
  `BIOSHOCK_MOVEMENT_OK` is achieved for real.
