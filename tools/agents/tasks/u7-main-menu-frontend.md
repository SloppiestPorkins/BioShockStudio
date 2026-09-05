---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U7 — main menu + frontend (difficulty, save/load, loading screens)

`docs/UI_ROADMAP.md` §2.6. U1-U6 in. There is already a `UShockMainMenuWidget` +
`AShockMenuGameMode` (from the 30 Aug main-menu work — `grep -rl MainMenu
tools/ue5/BioShockRuntime`). This phase reskins it with the real art and fills in the
frontend flow. `GameDefaultMap` is `/Game/BioShockUI/MainMenu`.

## Real art

No standalone `mainmenu.swf` — the menu art is in `sharedlibrary.swf` + `pausePC.swf`:
- BioShock logo (pause id 1248, 512×256) — already imported to `/Game/BioShockUI/Pause/`.
- Deco chevron selection markers (pause 223/228), banner plates (565/567/576),
  key-prompt roundels.
- `swf-find sharedlibrary.swf menu` / `title` / `newgame` / `difficulty` for anything
  menu-specific; `export-swf-images` whatever turns up.
- Background: BioShock's menu is the bathysphere-interior / Rapture-skyline plate. Check
  `sharedlibrary.swf` and `BinkMovies/` for a menu background loop; if there's no still
  plate, a dark Deco gradient with the logo is an acceptable U7 background — note it.

## What to build / wire

1. **Main menu** (`UShockMainMenuWidget` reskin): logo, then the list — **New Game**,
   **Continue**, **Load Game**, **Options**, **Credits**, **Director's Commentary**,
   **Museum**, **Challenge Rooms**, **Exit**. Gold-chevron highlight. Real font.
2. **New Game → difficulty select** (`UShockDifficultySelect`): Easy / Medium / Hard /
   Survivor, each with its one-line description (from the manual — Easy "for players new
   to shooters", etc.). Selecting one starts the game: travel to the first level. Use the
   existing travel path (`AShockGameMode::TravelToLevel` / `UShockGameInstance` carry
   state) — the first map is `/Game/BioShockLevel/1-Welcome` if it's spawn-ready, else
   `/Game/BioShockSlice/1-Medical` (check which has a working PlayerStart + ShockGameMode;
   note the choice). Store the difficulty on `UShockGameInstance`.
3. **Save / Load screens** (`UShockSaveLoadMenu`): list save slots with timestamp + level
   name + a thumbnail box. Wire to `UGameplayStatics::SaveGameToSlot` /
   `LoadGameFromSlot` with a `UShockSaveGame` capturing `UShockCarryState` + the current
   level. Reachable from both the main menu and the pause menu (replace the U4 pause-menu
   Save/Load log-stubs with this).
4. **Loading screen** (`UShockLoadingScreen`): shown during level travel — a Deco panel
   with the level name and a "Now entering <area>" line + a rotating tip. Hook
   `FCoreUObjectDelegates::PreLoadMap` / `PostLoadMapWithWorld` or the
   `UGameInstance` loading-screen hooks.
5. Options / Credits / Director's Commentary / Museum / Challenge Rooms: log-stub screens
   with a "Not implemented" panel and a Back button are fine — note which. Credits can
   scroll the real credits text if `CreditsContainer.swf` yields it easily.

## Verify

`run_frontend.py`: the main menu constructs with all 9 entries, difficulty select has 4
options and picking one sets the GI difficulty + initiates travel (mock the travel in the
verify), save-to-slot then load-from-slot round-trips a `UShockCarryState`, the loading
screen constructs. Headless. Capture the main menu + difficulty select (the menu map
isn't paused, so `capture_shot.ps1 -Map /Game/BioShockUI/MainMenu` should work directly).

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild.
- Don't break `setup_main_menu.py` / `verify_main_menu.py` if they exist — extend them.
- Don't regress the in-game UI — `run_hud` / `run_radial` / `run_status_pause` /
  `run_stations` / `run_hacking_minigame` stay green.
- Update `docs/UI_ROADMAP.md` (U7 row) + `tools/ue5/README.md`. No `docs/HANDOFF.md` row.
