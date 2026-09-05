---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U4 — status menu (M) + pause menu (Esc)

`docs/UI_ROADMAP.md` §2.4 / §2.5. U1-U3 are in. Visual check:
`tools/ue5/capture_shot.ps1 -Extra '-bioshockshothud','-bioshockshot<flag>'` — add a
force-open flag for each menu the way U3 added `-bioshockshotradial` (grep
`bForceRadial` in `ShockGameMode.cpp` for the pattern), and attach both `_hud.png`
captures to your summary.

## Status menu (M key) — `UShockStatusMenu`

Full-screen paused overlay, four tabs across the top (`mapsPC.swf` / `ingamemanualPC.swf`
art via `export-swf-images`): tab buttons carry icons — compass "N" = **Map**,
exclamation = **Goals**, face = **Messages**, "?" = **Help**. Deco panel frames (ids
1790/1793/1811/1840/1845), nameplate strips (1773/1801/1860), journal/book shapes.

- **Map** — for U4 a placeholder is fine (a panel that says "Map — <level name>" + player
  coords). Real level-plan rendering is a later stretch; note it.
- **Goals** — list the active quests/objectives. Bind to whatever quest state exists
  (`grep -ri quest tools/ue5/BioShockRuntime` — there's a quest/objective system from the
  earlier script-action work). Show objective text; mark the tracked one.
- **Messages** — list collected audio diaries. Bind to the inventory/diary state if one
  exists; if not, an empty "No recordings" panel + a note that diary collection isn't
  wired yet.
- **Help** — a few static reference cards (health/EVE/plasmids/hacking) using the decoded
  poster illustrations (HUDPC ids 552/560/592/599 = research / electro / medical / EVE).

Pause game on open (`UGameplayStatics::SetGamePaused`), unpause on close. Tab switch on
click or Q/E / bumper.

## Pause menu (Esc) — `UShockPauseMenu`

`pausePC.swf` art: BioShock logo (id 1248, 512×256), Deco chevron selection markers
(ids 223/228 = gold up/down chevrons), key-prompt roundels, first-aid/EVE case art.

- Header: BioShock logo. A stats strip: current **Money** and **ADAM** (bind to
  `AShockPlayer::GetMoney()` / ADAM getter), **Little Sisters remaining** on the level
  (count `AShockLittleSister`-ish actors, or 0 + note if none).
- Menu list: Resume / Save / Load / Options / Main Menu / Quit. Wire Resume (close +
  unpause) and Quit (`UKismetSystemLibrary::QuitGame`). Save/Load/Options/Main Menu can be
  stubs that log — note which. Selection highlight with the gold chevron marker.
- Esc toggles it; pauses the game.

## Import

`import_bioshock_ui.py` — add the pause + status art to `/Game/BioShockUI/Pause/` and
`/Game/BioShockUI/Status/`.

## Verify

- `run_status_pause.py` (mirror `run_radial.py`): both widgets construct, textures
  resolve, `SetGamePaused(true)` on open / `false` on close, the Goals tab lists N
  objectives when N exist, the pause stats strip shows the player's money/ADAM. Headless.
- Force-open captures attached.
- Human confirms in PIE.

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild
  (`-CleanModule` for new UPROPERTYs).
- Esc / M must not conflict with existing bindings — check `setup_playable_slice.py` and
  the existing `AShockPlayer` input; add mappings there.
- Update `docs/UI_ROADMAP.md` (U4 row) + `tools/ue5/README.md`.
