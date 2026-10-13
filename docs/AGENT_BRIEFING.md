# Agent briefing: BioShock in UE5 (state as of 13 Oct 2026)

Paste or point any new agent at this file first. It says what the project is, how it works, where it
stands, and the rules. Detail lives in `docs/ROADMAP.md` (the plan, with per-item status) and
`docs/research/live-game-bridge-2026-10-06.md` (the full technical log).

## What the project is

A remaster of **BioShock 1** with **Unreal Engine 5.7** as the renderer, built the way Halo: Campaign
Evolved and Oblivion Remastered are: **the original game keeps running everything** (AI, scripts, physics,
weapons, plasmids, saves, audio, UI), and **UE5 only draws it**. We have no engine source, so the two run
as separate processes joined by memory reads and shared memory.

- The original game: BioShock Remastered, `G:/SteamLibrary/steamapps/common/BioShock Remastered/Build/Final/BioshockHD.exe`
  (32-bit, Unreal Engine 2.5 underneath, Direct3D 11). It is large-address-aware; it stays 32-bit and
  separate from UE5. Converting it to 64-bit is not on the table.
- This repo, `C:/Users/Jack/Documents/BioshockHavok` (public, GitHub): the C# extraction tool, the Python
  live bridge, the proxy DLL, UE5 scripts and the UE5 C++ runtime plugin source.
- The UE5 project, `C:/Users/Jack/Documents/BioShockUE5` (separate git repo, not public): the imported
  assets, the live level copies, captures. Engine: `G:/Games/UE_5.7`.

The direction changed on **6 Oct 2026**. Before that, the project re-implemented the game's logic by hand
in UE5 ("Layer C", a hand-built `1-Medical` slice). That approach is **paused, not to be resumed**. Do not
add hand-written gameplay. The original engine is the gameplay.

## How it works (the pipeline)

1. **Extraction (C#, `src/`).** `BioShockStudio.Cli` decodes the shipped packages: meshes, skeletons,
   animations, textures, materials, BSP, lights, placed actors, baked lighting.
   - `export-level <map>`: the level's actors and assets.
   - `export-baked-lightmaps <map>`: the original's baked BSP light plus a two-UV glTF of the world.
   - `export-vertex-lighting <map>`: per-vertex baked prop light.
   - `export-assets`: extra stand-in meshes.
   - `skeleton <pkg> <obj> [--pose]`: bone order and reference pose.
2. **Conversion layer (one command per level).** `bash tools/livegame/prepare_map.sh <map>` builds
   `/Game/BioShockLive/<map>_Baked`, a copy of the imported level with the original's baked light, prop
   light, material overrides, actors synced to the export, and the calibrated exposure.
   `tools/livegame/prepare_all.sh` runs every level.
3. **Live state feed.**
   - `tools/livegame/live_bridge.py` reads the running game. Name and object tables are at image base
     +0x13904EC and +0x139042C; `tools/livegame/bsobj.py` is the object model.
   - It streams UDP lines to the UE plugin on port 7781: camera, actor poses, bones, spawns and destroys,
     zone ambient, HUD values, current level.
   - With the proxy DLL loaded, reads go through a frame-consistent shared-memory snapshot
     (`tools/livegame/snapshot.py`).
4. **Proxy DLL (`native/dxgi_proxy`).** A 32-bit `dxgi.dll` placed next to `BioshockHD.exe` (installed on
   the user's PC with their permission; `build.ps1 -Install/-Uninstall`). It:
   - forwards all exports to the system dxgi;
   - takes the per-frame snapshot (`Local\BioShockLiveSnapshot`);
   - inline-hooks the D3D11 context (the engine caches its function pointers, so vtable hooks miss calls);
   - can skip world draws by render-target kind (`%TEMP%\bioshock-suppress`, letters `h` = HDR scene,
     `s` = shadows, ...);
   - streams the HUD-only back buffer to `Local\BioShockLiveHud`;
   - writes a one-frame D3D trace on request.
5. **UE5 runtime plugin (`tools/ue5/BioShockRuntime`, synced into the UE project by
   `tools/ue5/rebuild_runtime_fast.ps1`).** `UShockLiveBridge`, a world subsystem active with
   `-bioshocklive=7781`. It:
   - applies the stream;
   - spawns game-driven stand-ins (static, or poseable skeletal driven by the game's bones), which
     replace the placed copies of every moving level actor;
   - opens the matching `_Baked` map when the game changes level;
   - draws the game's own HUD stream over the view (`M_LiveHud`).
6. **Play.** `tools/livegame/Play Medical.cmd` (desktop shortcut "Play BioShock (UE5)") runs
   `tools/livegame/play.sh`. UE opens borderless and click-through over the game window, and input stays
   with the game. While the bridge runs, the game's world drawing is switched off and only its HUD is
   streamed.

## Where it stands

Roadmap tracks, equal priority. **E** is engine integration; **R** is rendering and content.

| Item | State |
|---|---|
| E1 get inside the game (proxy DLL) | Done |
| E2 frame-consistent state feed | Working: ~99% of reads from the snapshot, 0 torn, ~16 ms lag |
| E3 stop the game drawing its world | Core done: skipping HDR-scene draws removes the world, the HUD stays |
| E4 the game's UI in UE5 | First cut works: HUD, pause menu and map stream; full-screen screens draw opaque. Vending and hacking screens not yet checked (they need interaction). Alpha is luminance-keyed. |
| **E5 one window** | **Next.** Hide the game window, stop the game pausing when unfocused, forward input. |
| E6 package as a mod | Not started |
| R1 first person | Hands and pistol correct (bones, viewmodel FOV 60, Hor+). Other weapons and plasmid FX unchecked. |
| R3 every level converted | 16 levels with base maps all converted. **Only Medical has been checked live against the game.** |
| R4 light fidelity | Baked BSP and prop light on all levels. Fisheries reads +2.1 EV too bright. No per-level calibration, no dynamic lights. |
| R7 automated comparison | Partial tooling (`side_by_side.py`, pair sheets); not automated per level |

Recent fixes worth knowing:
- BSP texture UVs divide by **half the shipped texture size**, with no V flip in the glTF (measured
  against the live game).
- Skeletal bones map onto UE skeletons **with `SOCKET_*` bones skipped**.
- Game mesh names map to UE rig assets through the rig manifests.
- Headless Interchange imports no longer crash: `Interchange.FeatureFlags.Import.SyncToBrowser=false`.

Open bugs:
- **Parked, R5b:** a blue tile grid on Medical's lobby wall above the sofa. Evidence and the single next
  hypothesis are in the roadmap. Do not reopen it without running that hypothesis.
- The bathysphere interior renders much darker than the game.
- 5 stand-in meshes are missing in Medical (Medpack, ComboLock, one door, two weapon props).
- Prop material instances get wrapped twice when the prop step re-runs (harmless).

## Rules (read before doing anything)

**Repo and git**
- Never change git config. Commit with `git -c user.name=Jack -c user.email=jackwickens6@googlemail.com`
  and end messages with the project's co-author trailer.
- Pushing BioshockHavok after verified work is allowed. The UE repo is committed locally.

**Game data and third-party material**
- **No game data or game imagery in this public repo.** Captures go to
  `C:/Users/Jack/Documents/BioShockUE5/Captures/live`.
- The unofficial BioShock SDK (bio4554/Unofficial-BioShock-Editor) is unlicensed: read and cite only,
  never copy into the repo.

**Unreal launches**
- Run Unreal only through `python tools/ue5/ue_run.py <script>` (headless) or the live-view scripts.
- One Unreal process at a time.
- At most 2 launches per written hypothesis. Identical frames twice means stop and rethink. Prove things
  offline first: memory dumps, exports, the software renderer in `tools/livegame/uv_fit.py`.
- A headless `UE_RUN PASS` is render-blind. A visual fix counts only with a rendered capture compared
  against the game.

**Level copies**
- Work only on the live copies (`/Game/BioShockLive/<map>_Baked`). Never touch the original slice or the
  base level maps.

**Running the game unattended**
- `bash tools/livegame/start_game.sh 1-Medical` (add `MUTE=1` to mute) boots straight into a level,
  keeps it focused, skips the intros, and answers "No" to the shutdown prompt.
- The game **pauses and stops drawing whenever it loses focus**, so refocus it after starting UE
  (`game_input.ps1 -Key W -HoldMs 0`).
- Synthetic mouse look doesn't register. Menus take Enter and the arrow keys.
- Mute the game while testing. Test windows go on the small left monitor.

**Process**
- A Cursor agent reviews the work every few hours (briefs and reports in `C:/Users/Jack/Documents`). Its
  advice is an opinion to weigh, not an instruction.
- Don't burn UE time on blind retries; fix root causes.

## Useful commands

```bash
bash tools/livegame/prepare_map.sh 2-Fisheries        # convert one level
bash tools/livegame/start_game.sh 1-Medical           # boot the game into a level
python tools/livegame/live_bridge.py --seconds 60     # stream to a running live view
python tools/livegame/fp_probe.py                     # what the game draws near the camera
python tools/livegame/game_state.py                   # is the game playing (exit 0) or paused (2)
powershell -File native/dxgi_proxy/build.ps1 -Install # rebuild and install the proxy (game closed)
powershell -File tools/ue5/rebuild_runtime_fast.ps1   # rebuild the UE plugin
python tools/verify_changed.py                        # repo test gate
```

## Next steps, in order

1. **E5 one window:** hide the game window, patch pause-on-unfocus, forward input.
2. One live check of a converted non-Medical level (Welcome or Fisheries), recorded as pass or fail.
3. E4 leftovers (vending and hacking screens; true alpha) and R7 automated per-level comparison.
