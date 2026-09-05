---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Doors don't work in-editor

User report (in-editor, 5 Sept 2026): doors aren't functional. Confirmed by code audit:
there is no `AShockDoor`-style actor anywhere in `BioShockRuntime` — the only door-related
code that exists is the script-action layer (`ShockActionOpenDoor.cpp`,
`ShockActionCloseDoor.cpp`, `ShockActionLockDoor.cpp`, `ShockActionUnlockDoor.cpp`,
`ShockActionDoorKeypadUsed.cpp`, `ShockActionSetDoorBrokenState.cpp`), which are handlers
for the game's *scripted event* system (triggered by level scripts), not a standalone
interactive door actor a player can walk up to and open. This is likely a genuine missing
system, not a bug in an existing one — scope it properly before assuming a small fix will
cover it.

## Investigate first

1. How are doors represented in the imported level data right now? Check
   `docs/research/*.md` for door-related decode notes (mesh naming conventions like
   `*_door_*`/`Door*`, any `Door` UClass in the source game's package data, animation/
   collision conventions). Check the current level import pipeline
   (`import_level.py`/`import_bioshock.py`) — are door meshes imported as plain static
   props right now (matching the "everything gets default collision, no special
   handling" gap this session already found for decals), with zero interactivity wired?
2. What does the *source game* actually do for a door — is it a simple open/close swing
   or slide animation triggered by proximity/interact, a keypad-locked door tied to the
   scripted event system above, or both depending on door type? Don't assume one uniform
   behavior; BioShock has multiple door classes (plain doors, keypad doors, chained/
   welded doors that never open, elevator doors). Check what the existing
   `ShockActionDoorKeypadUsed`/`ShockActionSetDoorBrokenState` handlers imply about door
   state (broken/locked/keypad) that any new interactive door actor needs to respect.
3. Confirm what player-interaction system already exists to hang a door off — is there a
   generic "interact" input/trait already in `AShockPlayer` (used for anything else,
   e.g. pickups) this can reuse, or does door interaction need its own?

## What to build

A minimal `AShockDoor` (or similarly named) actor: detects player proximity/interact
input, plays an open/close state change (animation if the mesh has one, otherwise a
simple transform/rotation swing as a fallback — don't invent skeletal animation data that
doesn't exist), updates its own collision so the player can actually walk through when
open, and respects locked/keypad/broken state if the script-action layer already models
that (wire into it rather than duplicating door-state tracking). Scope the first landable
version to plain doors (the common case) — keypad/locked/broken doors can be a documented
follow-up if the state-machine hookup turns out to be a bigger, separate piece of work.

## Tests / verify

Headless: spawn a door actor, verify default state, drive open/close directly (not
through a live player interaction if there's no clean way to fake proximity/input
headlessly) and assert collision updates accordingly (mirroring how `verify_collision.py`
already checks blocking behavior elsewhere in this project).

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- Do not invent assumed game behavior where the source data doesn't confirm it — if a
  door's exact original interaction model is unclear from available research/docs, build
  the simplest reasonable version (proximity-open, swing/slide by transform) and say
  explicitly what's approximated vs. confirmed from source data.
- No live UE session in this worktree — headless assertions are the evidence; a human
  confirms feel (swing speed, interact range) in the editor afterward.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
