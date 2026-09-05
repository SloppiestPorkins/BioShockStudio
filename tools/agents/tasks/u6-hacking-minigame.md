---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U6 — the hacking pipe-puzzle minigame

`docs/UI_ROADMAP.md` §2.8. U1-U5 in. Force-open capture flag + `_hud.png` attached (invoke
`UnrealEditor-Cmd` directly with `-game -bioshockscreenshot -bioshockshothud
-bioshockshot<flag>` — chaining two `-Extra` through `capture_shot.ps1` from bash
comma-joins them; the worker's own powershell `-Extra` array is fine, or call the game
directly).

## The game

A grid of pipe tiles (BioShock 1 uses ~7×6). Some start face-down. The player uncovers and
swaps adjacent tiles to build a connected pipe path from the **source** node to the
**target** node before the green fluid, which starts flowing on a timer, reaches the end
of whatever path exists. Tile types: straight, elbow, T, cross, plus hazard tiles
(**speed-up** = fluid moves faster, **overload** = instant fail + damage, **alarm** =
raises the security alarm). Win = fluid reaches target. Options offered before/during:
pay Money to buy out, use an Auto-Hack Tool for instant success.

## Art (`export-swf-images hackingPC.swf` + `export-swf-sprite` for the vector tiles)

- Device bezel / board frame: ids 479 / 564 (blue-grey metal), 474 / 484 (the hazard
  HUD strip with the wrench + red/yellow/green indicator lights). Banner plates 528 / 533
  / 537 / 607. Ring 556.
- The **pipe tiles themselves are DefineSprite / DefineShape vector** — `swf-inspect
  hackingPC.swf`, `swf-find hackingPC.swf pipe` / `tile` / `flow`, then
  `export-swf-sprite hackingPC.swf <id> <out.png>` per tile type. If the sprite decode is
  messy, draw the pipe segments as simple UMG shapes (a rounded rect per connector) on the
  tile and note the compromise — the LOGIC matters more than the tile art for U6.

## What to build

- `UShockHackingMinigame` (UMG). Board model: `TArray<FShockHackTile>` with type, rotation,
  revealed flag, hazard. A flood-fill from source each tick decides whether a connected
  path exists; a fluid-progress float advances on the timer along the current best path;
  reaching target = win, hitting a hazard-overload or timeout = fail.
- Bind to `UShockSecuritySubsystem` / `AShockPlayer::TryHackDevice` (U3-era hacking
  hooks): success → `SetSecurityHacked(true)` on the device; alarm hazard →
  `SetSecurityAlarmOn(true)`; overload → `ApplyDamage` to the player. Money buy-out spends
  `GetMoney()`; Auto-Hack consumes an inventory item if one exists (else just always
  available + note).
- Difficulty scales board size / face-down count / fluid speed by the device's hack
  difficulty (`HackSkill` stand-in from the C3-hacking work).
- Opens from the existing hack-interact path instead of the deterministic instant hack
  (keep the instant path behind a `bInstantHack` cheat flag for the headless verifies that
  rely on it — grep `TryHackDevice` / `run_hacking.py` and don't break them).

## Verify

`run_hacking_minigame.py` (new; keep the old `run_hacking.py` passing): the widget builds
a board of the right size for a given difficulty, a scripted winning sequence of
tile-swaps produces a source→target path and a win that calls `SetSecurityHacked`, a
scripted losing sequence times out and does not, an alarm-hazard tile raises the alarm,
buy-out spends Money. Headless. Force-open capture attached. Human confirms feel in PIE.

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild.
- Keep `run_hacking.py` / `run_security` green (the instant-hack path the AI/security
  tests use must still work).
- Update `docs/UI_ROADMAP.md` (U6 row) + `tools/ue5/README.md`. No `docs/HANDOFF.md` row.
