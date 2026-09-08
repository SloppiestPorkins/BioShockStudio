---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Pause-menu and status-menu stubs

`docs/AUDIT_2026-09-06.md` open gaps #6 and #8:

- **Pause menu** (`pause_hud.png`): Resume/Save/Load/Options/Main Menu/Quit render with the gold
  chevron, but **Options and Credits are stubs**, and a debug string
  `"(no Little Sister…)"` is visible to the player.
- **Status / objectives menu** (`status_hud.png`): Map/Goals/Messages/Help tabs render. **Map
  tab is a coords placeholder**; Messages tab says "Audio diary collection is not wired yet"
  (that half depends on w1 audio — do the non-audio part here).

## What to build

1. **Remove the debug string** from the pause menu — grep `ShockPauseMenu` /
   `ShockSaveLoadMenu` for `"Little Sister"` and gate or delete it.
2. **Options menu** — a real screen: at minimum mouse sensitivity, invert-Y, master/SFX/music
   volume (hook the w1 audio buses if landed, else leave the sliders wired to cvars),
   FOV, `ViewBobScale` / `bViewEffectsEnabled` (from v6), resolution/fullscreen. Persist to an
   ini or a `USaveGame`. Match BioShock's option list where it maps.
3. **Credits** — a scrolling credits screen (real BioShock credits text if it's in a shipped
   string table / SWF; otherwise a project credit + "based on BioShock" line).
4. **Status Map tab** — render an actual map: a top-down schematic of the level from the
   compiled-world bounds / nav data, player marker, discovered rooms. If a shipped map image
   exists in the SWFs use that; otherwise a generated floorplan from the BSP is acceptable —
   say which.
5. **Goals/Help tabs** — confirm they show real quest/objective data from the script system
   (`InitiateQuest` / `CompleteQuestObjective` actions exist).

## Deliverable

- The four screens functional, no debug text.
- `docs/research/` UI note updated.
- `-game` captures: options, credits, status Map tab.
- Headless: `verify_frontend` / `run_verify_main_menu` / `u4-status-and-pause-menus` verifies
  still pass + a check the debug string is gone.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless. `-run=pythonscript` → JSON. MSYS
  forward-slash + `MSYS_NO_PATHCONV=1`.
- Do NOT commit. Diff for review.
