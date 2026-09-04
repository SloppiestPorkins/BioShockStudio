---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Real headless tests for player movement and weapon-follows-hand-animation

## Why this task exists

User reports, live PIE, 4 Sept 2026: **"can't walk or do anything"**, and separately,
**the pistol doesn't visibly react to the hand's reload animation** (the gun should track
the hand bones as they move). Neither of these has ever been tested by anything in this
codebase. This project's existing verify suite covers possession, firing, and AI, but
never drives movement input and never checks whether a weapon actor's transform actually
changes while an animation plays underneath it — both are real, previously-unverified
gaps, not something to guess a fix for. Build the tests first; only fix code once a real
test demonstrates what's actually broken (if anything — it's equally possible both are
fine mechanically and the report is about feel/positioning, which these tests will also
help distinguish).

## Why this needs new C++, not just a new Python script

Editor PIE (`editor_request_begin_play`) access-violates under `UnrealEditor-Cmd` on this
project — confirmed and documented already in `capture_pie_shot.py` and
`verify_game_possess.py`. The only way to get a **real** `BeginPlay`/`PossessedBy`/
per-frame `Tick()` headlessly here is standalone `-game` mode, driven by a command-line
flag `AShockGameMode` checks for and a timer-delayed verification hook — the exact,
already-proven pattern in `ShockGameMode.cpp`'s `PostLogin`-equivalent function (~line
1145-1239): `bioshockverifypossess` logs and exits immediately;
`bioshockverifyencounter` uses `GetWorldTimerManager().SetTimer(..., 3.5f, false)` to let
a few real seconds of ticking happen before verifying and exiting. Follow this pattern
exactly — do not attempt this through `-run=pythonscript` (that path is what crashes) or
through `EditorActorSubsystem.spawn_actor_from_class` in the editor world (measured this
session: a pawn spawned that way never receives `BeginPlay` at all — `MOVE_NONE`, zero
displacement on `AddMovementInput`, and no `Controller` — which produced a false "movement
is broken" signal that had to be discarded once this was understood; don't repeat that
mistake).

## Test 1 — real movement

Add a new flag, e.g. `-bioshockverifymovement`, alongside the existing ones in the same
function. After normal possession completes (same place `bioshockverifyencounter`'s timer
gets armed), use a timer to:

1. Record the pawn's starting location.
2. Over some real duration (2-3 seconds is enough at `MaxWalkSpeed`), drive movement the
   same way real input would — either repeatedly call `AddMovementInput` on a short
   repeating timer, or hook into `Tick` for that window. Pick whichever is more faithful
   to how `AShockPlayer::MoveForward`/`MoveRight` (or whatever the real input handlers are
   named — check `ShockPlayer.cpp`) actually invoke movement, rather than calling a
   lower-level function real input never touches.
3. After that window, log: starting location, ending location, total displacement,
   `GetCharacterMovement()->MovementMode` at both start and end, and whether
   `bMovementDisabled` was ever true during the window. Something like:
   `BIOSHOCK_MOVEMENT_OK displacement=%.1f mode_start=%s mode_end=%s` (or `_FAIL reason=...`
   if displacement is near zero or movement mode is `MOVE_None`).
4. Exit.

If this reveals movement is genuinely broken, the fix belongs wherever the real cause is
— don't guess; the log data (which mode it's in, whether input reached the movement
component at all) should point at the actual mechanism.

## Test 2 — weapon actually tracks the hand's animation

Equip the Pistol (already fully animated per `h8`), trigger `Reload()`, and over the
reload animation's own duration (`ReloadPistol`/`FastReloadPistol`'s `GetPlayLength()` —
don't hardcode a guessed duration), sample the equipped weapon actor's **world-space
transform** at several points (e.g. every 0.1s) via a repeating timer. Log enough of that
series to answer: does the weapon's world position/rotation actually change over the
course of the animation (proving live socket-follow), or does it stay static after the
initial equip-time snap (proving the attachment isn't tracking bone movement)? A useful
signal: total variance/range of the weapon's tracked position across the samples, plus
first/last sample explicitly.

If this reveals the weapon is static while the hand moves: `AttachToComponent` with a
valid socket name should make UE track bone movement automatically every frame with no
extra code — if it isn't, look for whatever might be working against that (something
re-setting the weapon's world transform elsewhere, or the attachment not actually landing
on a bone-driven socket for some reason) rather than assuming the attachment call itself
is wrong, since that's the standard, normally-reliable mechanism.

## Driver scripts

Mirror `run_game_possess.py` / `verify_game_possess.py`'s exact shape: a Python script
that launches `UnrealEditor-Cmd.exe <project>.uproject <map>?game=... -game
-bioshockverifymovement -unattended -nopause -nosplash -log -abslog=<path>`, parses the
resulting log for the new `BIOSHOCK_MOVEMENT_*` / `BIOSHOCK_WEAPON_TRACK_*` lines via
regex, and writes a JSON report — same structure as `verify_game_possess.py`'s
`_parse_log`. Two flags can run in one `-game` invocation if that's simpler, or two
separate ones — whichever keeps each test's log parsing unambiguous.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- These are new C++ verify hooks gated behind command-line flags, same risk profile as
  the existing `bioshockverifypossess`/`bioshockverifyencounter` ones — should have zero
  effect on normal gameplay or the editor.
- Report what the tests actually show, even if it's "movement works fine, the report was
  about something else" — the point is a trustworthy answer, not confirmation of a
  hypothesis.
- Actually run both tests via `-game` (this task requires an out-of-editor process launch,
  not just `-run=pythonscript` — if the Shell tool is unavailable for that, say so
  explicitly and hand back exact commands to run rather than guessing at results).
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once both tests
  have run for real and their results are known.
