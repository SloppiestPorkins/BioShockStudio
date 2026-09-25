---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**, docs/research/**
---

# y7 — gameplay fidelity batch (SDK audit `docs/research/sdk-crossref-gameplay.md`)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.
> **Copyright:** the SDK guide is unlicensed and this repo is public — never copy its prose.
> Facts only, own words. Guide (read-only): `C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test\c7be037f-fb45-4801-8732-1d5df17a8bb3\scratchpad\unrealed-guide-mirror`.

Fix the audited gameplay bugs below. **For each: re-verify the audit's claim against the current
code FIRST** (open the cited file:line, and the guide chapter if unsure). If the audit is wrong,
or the guide is silent/ambiguous, do NOT change it — record why in your RESULT note. Do not touch
`ShockScriptRunner.*`, `ShockVariableScope.*`, `ShockAction*` script-flow code, `ShockDoor.*`
(other tasks own them). Already done, don't redo: hack failure non-lethal cap, Health Station
16/10, 60 s alarm expiry + security subsystem tick.

## Items (audit ids; effort in brackets)

1. **B01 [S]:** winning a DEVICE hack (turret/camera/bot) must only flip that device (allegiance,
   station `SetHacked`). `ShockHackingMinigame::ApplyHackSuccessToWorld` calls `SetSecurityHacked`
   which clears the alarm and shuts down EVERY security device for `HackShutdownSeconds`; that
   system-wide shutdown belongs to `ActionHackSecuritySystem`/a shutdown panel only. Keep the
   instant-hack path consistent. Check the existing verifies (`verify_hacking.py`,
   `verify_hacking_minigame.py`, `verify_security.py`) for assertions that encode the old behaviour
   and update them, saying which.
2. **B05 [S]:** concurrent alarm bots cap 4 (currently `MaxActiveBots=2`); a second alarm while
   one runs adds one bot to the running alarm (the hack-alarm-tile path currently doesn't spawn when
   the alarm is already on; the camera path does).
3. **B08 [S]:** remove the invented 30 s bot despawn after the alarm clears
   (`BotLifetimeAfterAlarmClearSeconds`) — bots stay until killed or explicitly shut down. Note the
   guide is silent on despawn; only do this if you agree it's an invention (audit U03 marks it
   uncertain). If unsure, make it a property defaulting to "never" and say so.
4. **B03 [S]:** non-scripted turrets exist from map start; `ShockEnemySpawner.cpp:454-486` defers
   the spawn while the player is near. Spawn at BeginPlay/start; gate FIRING by LOS/allegiance, not
   existence.
5. **B11 [M]:** spawners' `InitialAITypes` spawn at map start (audit: only proximity/script-zone
   later). Medical has 19 aggressor + 4 protector spawner markers; check what
   `import_slice_enemies.py`/`ShockEnemySpawner` actually place today before changing so you don't
   double-spawn the slice's already-placed enemies. Report what you found either way.
6. **B10 [S]:** a hacked U-Invent needs 20% fewer components (`ShockStationMenu.cpp` `CraftRecipe`
   never consults `bHacked`); `ceil(0.8 * count)` per component.
7. **B04 [S, defaults only]:** camera detection defaults per the guide: view cone 60 degrees wide,
   sight distance 1000 (`ShockSecurityDevice.h` currently 3000 / 90-degree half-angle). Only change
   defaults; don't add importers. Check the existing camera tests (`verify_security.py`,
   `verify_hacking.py`) — they configure devices explicitly; tell me if a default change breaks any.
8. **B02 [M]:** alarm bots should appear 3000-6000 uu from the player at a point out of the
   player's sight (1500-4000 if the alarm is against an AI). `ResolveSpawnLocation` falls back
   to `NearLocation + (250,0,0)`. Implement the distance band + a no-line-of-sight test using
   nav points (`ANavigationData`/nav-mesh random reachable points, or exported PathNode actors if
   present in the level) and honour `NextSpawnLocationLabel`. If no valid point exists, fall back to
   the current behaviour and log it. Keep it testable headlessly (tests can place labelled
   marker actors).
9. **G20 [S]:** the hacking minigame/`TryHackDevice` should dispatch `MessagePlayerStartedHacking`
   (when the puzzle opens) and `MessagePlayerFinishedHacking` (when it ends, field
   `SuccessfulHack` = True/False) under the hacked actor's label, with `ActorLabel` also carried
   as a field. Use `UShockScriptSubsystem::DispatchMessageLoggedWithFields` (see
   `ShockDamageLibrary.cpp` `DispatchPawnMessageSources` for the pattern). Medical has 3 scripts
   on FinishedHacking with `SuccessfulHack=True` filters.
10. **G19 [S]:** a dormant security bot explodes after a FAILED hack (not after simply closing
    the puzzle).

**Do NOT change (asked separately / uncertain):** B12 Vita-Chamber default-active (would change
respawn behaviour the user plays with — report only), B06/B07/B09 Hacking.ini/vending-table
importers (large, separate), ecology.

## Deliverable

- The fixes.
- `tools/ue5/verify_gameplay_fidelity.py` (headless, `-run=pythonscript`-compatible, no sibling
  imports; house style `verify_security.py` / `verify_hacking.py`): a case per item you changed,
  positive AND negative assertions where meaningful.
- `docs/research/sdk-crossref-gameplay.md`: append a "Status (25 Sept)" section listing each id as
  FIXED / NOT-A-BUG (reason) / DEFERRED (reason).
- Don't regress: `verify_security.py`, `verify_hacking.py`, `verify_hacking_minigame.py`,
  `verify_stations.py`, `verify_encounter.py`/`run_encounter.py`, `verify_message_senders.py`,
  `verify_script_trigger.py`.
