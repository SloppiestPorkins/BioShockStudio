# Reading the running game: Phase 0 result (6 Oct 2026)

ROADMAP Phase 0 asks whether UE5 can follow the original BioShock as it runs, with the original engine
playing the game and UE5 only rendering it. **Both steps pass.**

## Step 1: reading the running game (pass)

The test ran against BioShock Remastered (`BioshockHD.exe`, 32-bit, monolithic, no exported
symbols), started with `1-Medical` on the command line and muted through Windows per-app volume.
Access is read-only (`ReadProcessMemory`): no patching and no injection.

The tables were found by searching memory:

| What | Where (offset from the exe image base) | Layout |
|---|---|---|
| `FName::Names` | `+0x13904EC`, `TArray<FNameEntry*>` | entry = `{int Index; u64 Flags; ptr HashNext; wchar_t Name[]}` (UTF-16) |
| `UObject::GObjObjects` | `+0x139042C`, `TArray<UObject*>` | ~96,000 objects with Medical loaded |

UObject header fields:

| Offset | Field |
|---|---|
| `+0x04` | Index |
| `+0x1C` | Outer |
| `+0x28` | Name (FName index) |
| `+0x2C` | Name number; the suffix is `Number-1`, with no separator, when the number is > 0 |
| `+0x30` | Class |

`UProperty::Offset` sits at `+0x74` on every property object. Any property's byte offset can
therefore be read by name instead of guessed. Examples:

| Property | Offset |
|---|---|
| `Engine.Actor.Location` | `0x1D8` |
| `Engine.Actor.Rotation` | `0x1E4` |
| `Engine.Actor.Velocity` | `0x1F0` |
| `Engine.Actor.bHidden` | `0xCC` |
| `Engine.Actor.Mesh` | `0x128` |
| `Engine.Actor.StaticMesh` | `0x94` |
| `Engine.Actor.DrawScale` | `0x2AC` |
| `Engine.Actor.Base` | `0xB0` |
| `Engine.Controller.Pawn` | `0x450` |
| `Engine.Pawn.EyeHeight` | `0x558` |
| `Engine.Pawn.BaseEyeHeight` | `0x550` |
| `Engine.PlayerController.DesiredFOV` | `0x648` |
| `Engine.LevelInfo.TimeSeconds` | `0x5FC` |
| `Engine.LevelInfo.Pauser` | `0x668` |

Checks:

- **7,310 of the 8,089 actors** in Medical's export manifest are live in the game under the same
  name. Of the 779 that aren't, 751 are Brushes (compiled into BSP, so not runtime actors), 26 are
  TrainingScripts, and 2 are other classes.
- Location at `0x1D8` equals the manifest `location` for 396 of the 398 sampled actors, with no axis
  flip. **Game world coordinates are the coordinates of our UE5 map.**
- Holding W for 2 s moved `ShockPlayer0` 703 units along its facing direction, and
  `LevelInfo.TimeSeconds` advanced 204.25 → 206.99.
- The game pauses while its window is unfocused, and memory reads still work while it's paused.

## Step 2: rendering our UE5 map from the game's camera (pass, snapshot form)

`tools/livegame/side_by_side.py` reads the camera from the game. It then captures the game's own
frame and renders the UE5 slice offscreen from the same camera
(`capture_shot.ps1 -bioshockshotabs/-bioshockshotlook/-bioshockshotfov`).

The camera is built from these values:

| Part | Source |
|---|---|
| Position | pawn `Location` + (0, 0, `EyeHeight`) |
| Orientation | controller `Rotation` (Unreal rotator units, 65,536 = 360°) |
| Field of view | `DesiredFOV` (75) |

Two traps, both now handled:

- **Display scaling.** At 150% Windows scaling, a non-DPI-aware grab sees a window two-thirds the
  size and copies only the top-left of the real 2538×1384 frame. `grab_game.ps1` calls
  `SetProcessDPIAware` first.
- **Field of view.** BioShock's FOV is horizontal at 4:3 and widens with the window (Hor+). UE5's
  `FOVAngle` is the horizontal angle of the actual frame:
  `hfov = 2·atan(tan(fov/2) · aspect / (4/3))`, which gives 93.1° for this window.

Result: at Steinman's waiting-room couch, the poster and couch line up in both frames, matching in
size and horizontal position, with a few percent of vertical difference. The remaining differences
are rendering, which is the work this direction exists to do:

- UE5 is much darker;
- the warm wall light is missing;
- the floor debris is lit white where the game's is dark.

## Next

- A live bridge that streams transforms each frame instead of taking one-off snapshots.
- Dynamic state: animation, spawned and destroyed actors, lights.
- First person.

All of this is in ROADMAP Phase 1.

## Phase 1, first piece: the live bridge (6 Oct 2026, evening)

The bridge streams continuously instead of taking snapshots.

`tools/livegame/live_bridge.py` reads these from the running game and sends them over UDP to
`127.0.0.1:7781`:

- the camera;
- `LevelInfo.TimeSeconds`;
- the pose and `bHidden` of every non-static manifest actor.

`Actor.bStatic` is bit `0x20` of the dword at `0xCC`. `BoolProperty` keeps its bit mask at `+0x9C`.
Medical has 1,816 non-static manifest actors.

`UShockLiveBridge`, a world subsystem in BioShockRuntime enabled by `-bioshocklive=<port>`, does
three things:

- points a camera at the game's view;
- moves tagged actors by the game's change from their level-file pose (`B` lines, taken from the
  manifest, which stores rotations in the same rotator units as memory);
- saves `ue_<frame>.png` from the live camera.

`live_view.ps1` runs it offscreen under a plain `GameModeBase`, so this project's own gameplay code
stays out of the way.

To run the whole test: `bash tools/livegame/live_test.sh <out-dir> 90`. It starts the view, waits
for `BIOSHOCK_LIVE start`, lets shaders settle, streams while `drive.ps1` walks the player, then
`pair_sheet.py` pairs each game frame with the nearest UE frame.

First run:

| Measure | Result |
|---|---|
| Frames streamed | 2,205 in 90 s (~24 Hz) |
| Lines received by UE | 160,442 |
| Actors moved in UE | 67 |
| Keys UE did not know | 404 |

All 29 paired frames show the same view as the game through the walk: Steinman's poster, the corridor,
the Vita-Chamber hall, and the stairs under the Medical Pavilion sign. The pair sheet is kept outside
this repo (game imagery) at `BioShockUE5/Captures/live/`.

What the run showed is still wrong:

- **Lighting.** UE5 is far too dark everywhere. This is the biggest gap.
- **Missing foreground objects.** Some foliage is absent (a plant beside the sign), consistent with
  the 404 keys UE did not know.

Gotchas:

- `FParse::Param` does not match `-switch=value`; use `FParse::Value`.
- The game only advances while focused.

## Lighting, round 1: zone ambient (6 Oct 2026, late)

What the walk frames showed:

| Measure | UE5 | Game |
|---|---|---|
| Pixels pure black | over half | darkest areas still visible |
| Mean brightness gap | 4–7 stops darker | — |

**Cause.** BioShock's `ZoneInfo` has a hemispheric ambient term, read live as:

| Property | Medical value |
|---|---|
| `CurrentAmbientColorHigh` + `...HighMultiplier` | most of the 75 zones: (32, 44, 53) ×40; dark rooms 0; one teal ×80; two warm ×5 |
| `CurrentAmbientVectorHigh` / `...Low` | — |
| `...ContrastPower` | 2 |
| `...XGroundRatio` | 0.15 |

UE5 had nothing equivalent. The player's zone is `Actor.Region` (the zone pointer is the first field
of the struct).

**What changed:**

- The bridge sends `Z r g b intensity` from the player's zone.
- `UShockLiveBridge` applies it as a post-process ambient cubemap on the view camera and the
  capture.
- The engine `DefaultCubemap` is strongly warm: a blue-grey tint came out orange. The bridge now
  uses `/Game/BioShockLive/WhiteAmbientCube`, a uniform white HDR made by `make_white_hdr.py` and
  imported by `import_white_cube.py`.
- Headless `AssetImportTask` crashes after saving, on a Slate assert, but the asset it wrote is good.
- `calibrate_ambient.sh` holds the game paused and sweeps the ambient scale in one UE run.

**Calibration at the Medical Pavilion sign:**

| Ambient scale | Gap to game | Black pixels |
|---|---|---|
| ×0 | +4.1 EV (darker) | 90.7% |
| ×8 | +0.4 EV | 18.8% |

Colour came out neutral and cool, matching the game. The plant that looked missing was only unlit.

**The 90 s walk at ×8:**

| Measure | Result |
|---|---|
| Black pixels | 8.5% (was more than half) |
| Mean gap | −1.9 EV (UE5 now too bright) |
| Structural correlation | 0.21 |

A flat ambient lifts everything evenly, but the original's look is its baked falloff and shadow.
Next is to import the original's baked static lighting: BSP lightmaps and per-instance vertex
lighting (`StaticMeshInstance`, 2,017 live in Medical). That replaces the guesswork.

**Other gaps seen:**

- The handbag at the sign uses a different skin (pink floral in UE5, green camo in the game).
- Pairs taken during fast turns are a fraction of a second apart, so they don't line up.
