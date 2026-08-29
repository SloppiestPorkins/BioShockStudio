---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Add a working main menu to the BioShock UE5 slice: a start screen the player sees on launch,
with "Play" (loads the `1-Medical` slice and possesses the player), "Quit", and a title.

## Context
The playable slice currently boots straight into `1-Medical` PIE. There is no menu, no front
end. Runtime lives in `tools/ue5/BioShockRuntime/` (C++: `ShockGameMode`, `ShockPlayer`,
`ShockWeapon`, `ShockGameInstance` if present). Import/setup scripting is in `tools/ue5/*.py`.

## Do
1. A `WBP_MainMenu` UMG widget (built from C++ `UUserWidget` subclass or a Python-authored widget
   asset — whichever matches how this project already creates UE assets from scripts; check
   `import_bioshock.py` / existing `run_*.py` for the pattern). Title text "BIOSHOCK" (or the
   project's existing wordmark), Play / Options-placeholder / Quit buttons, keyboard + mouse
   navigable.
2. A front-end map (`Content/BioShockUI/MainMenu.umap` or similar) set as the project's default
   startup map, with a `AShockMenuGameMode` (or reuse GameMode with a menu flag) that shows the
   widget, sets UI-only input mode, and hides the HUD.
3. "Play" → open the `1-Medical` slice level and hand control to the normal gameplay GameMode /
   possess path that already exists (`run_game_possess.py` / `ShockGameMode` PostLogin). Do not
   duplicate the possession logic — call into it.
4. "Quit" → `UKismetSystemLibrary::QuitGame`.
5. A headless setup script `tools/ue5/setup_main_menu.py` (+ `run_setup_main_menu.py` driver
   following the repo's driver pattern) that creates/wires all of the above into the throwaway
   project idempotently, and a `verify_main_menu.py` that asserts the startup map, the widget
   class, and that "Play" resolves the slice map — reporting `Success - N error(s)` per the
   project's evidence rule (`unreal.log` is not reliable under `-run=pythonscript`).
6. If any of this needs a C++ change to `BioShockRuntime`, keep it minimal and rebuild with
   `tools/ue5/rebuild_runtime_fast.ps1` (if it throws about HostProject, note that the reseed
   task `a1-hostproject-reseed` must land first and stop with a clear message).

## Constraints
- `tools/ue5/**` only. No `src/**`, no `tests/**`. Do not commit, do not push.
- Do NOT commit the generated `.umap` / `.uasset` — those live only in the throwaway project
  (add patterns to `.gitignore` if the scripts would otherwise drop assets in the repo). The
  committable output is the `tools/ue5/*.py` scripts + any `BioShockRuntime` C++.
- Follow `docs/ENGINEERING_RULES.md` and `CLAUDE.md`. Smallest correct change. Scratch to `$env:TEMP`.
- Human PIE confirm is expected and fine — make the scripts + verify pass headless, note the
  visual check as the user's.
