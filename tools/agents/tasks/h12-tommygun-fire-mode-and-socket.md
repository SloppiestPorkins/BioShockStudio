---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Tommy Gun: fix single-shot fire mode and off-to-the-side viewmodel socket

User report (in-editor, 5 Sept 2026, first time weapons could actually be tested since
movement/collision were fixed the same night): "the tommy gun is single shot, and its
not socketed correctly as its off to the side."

## Issue 1 — single shot instead of automatic

The Tommy Gun (`WP_TommyGun`) is BioShock's automatic weapon — holding the fire input
should keep firing until ammo runs out or the input releases, not stop after one round.
Find where fire input is handled (`AShockPlayer`/`AShockWeapon` — check for an input
action binding tied to `PlayFireFeedback`/`Fire()` and whether it's bound as a
press-once action vs a held/repeating one, and whether `AShockWeapon` itself has any
per-weapon "is this automatic" concept — e.g. a fire-rate timer that should keep
re-triggering while the trigger is held). Confirm what SHOULD happen per-weapon: Pistol
and Shotgun are semi-auto (one shot per press, correct as-is presumably — don't break
those), Tommy Gun and Crossbow may differ (check `UShockWeaponDef`/`ShockWeaponDef.cpp`
for any existing fire-mode field before assuming none exists). Fix should be data-driven
per weapon def, not a hardcoded Tommy-Gun-only special case, so future automatic
weapons don't need the same fix repeated.

## Issue 2 — grip socket positions the gun off to the side

`h8-viewmodel-animations-all-weapons` (already applied, see `ShockPlayer.cpp`
`EquipWeapon`/`ResolveGripSocketForWeapon`) generalized socket resolution from a
hardcoded Tommy-Gun-only candidate list to resolving the socket name from the equipped
weapon's own identity. That headless task could only assert the resolved socket NAME
was non-empty and weapon-specific — it explicitly could not judge visual correctness
("a human confirms... especially for socket positioning"). The human check now says
Tommy Gun renders off to the side, not gripped correctly.

Investigate: does the hands skeleton's `TommyGun` socket (the one that was previously
hardcoded and presumably worked, per h8's docstring finding "only TommyGun ever
matched") have a transform (location/rotation offset) that doesn't actually line up
with `WP_TommyGun`'s own mesh origin/pivot? Or did generalizing the resolution logic in
h8 change WHICH socket or offset gets applied for TommyGun specifically (compare
before/after behavior — h8's diff is in
`tools/agents/runs/h8-viewmodel-animations-all-weapons/changes.patch` if still present,
else `git log`/`git show` on `ShockPlayer.cpp` around `EquipWeapon`/grip resolution).
Check whether `FrameViewmodel` (screen-pinning logic) applies a per-weapon or shared
offset, and whether that offset was tuned for a different weapon's mesh origin.

Do not guess a fudge-factor offset without confirming the actual pivot/socket
transform mismatch first — this project has already had to revert a "looked
plausible, was wrong" fix twice tonight for a different system (materials); the pattern
to avoid is exactly that.

## Tests / verify

Extend the existing weapon-tracking / viewmodel verify scripts
(`verify_viewmodel_anims.py` / `h10`'s weapon-tracking test) to also sample the Tommy
Gun's actual world-space socket transform vs. its mesh's own bounding-box center, so a
gross misalignment is headlessly detectable in the future (not just "did a socket name
resolve"). For fire mode, drive `DriveMoveForwardForVerify`-style test input holding
fire for >1 fire-rate interval and assert more than one shot/ammo-decrement occurred for
Tommy Gun specifically, while Pistol still fires exactly once per single trigger call.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- No live UE session in this worktree — headless assertions are the evidence for fire
  mode; socket position is a look-and-tune value a human confirms afterward, same
  caveat as h8.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
