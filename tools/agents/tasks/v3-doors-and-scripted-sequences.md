---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Doors, properly — and the scripted event sequence that opens the first one

**Research-first.** The interactive session has cycled through a yaw-swing cube stand-in, a
skeletal-mesh path (renders as broken translucent shards — see below), and a half-built slide
path, and it's going in circles. Stop guessing. Work out how BioShock actually does doors and the
level-entry event sequence, write it down, then build it once.

The concrete target: spawn into `/Game/BioShockSlice/1-Medical` and the **load-room door slides
open** — lever/wheel turns, then the whole door panel slides to the right — revealing the
Steinman "You will be Beautified!" room. It must NOT block the player once open.

## Current state (all committed, all on `main`)

- **Scripts fire.** `14b2157` fixed three bugs — `UShockScriptSubsystem` (UWorldSubsystem, one
  registry per world), `AShockScript::BeginPlay` always rebinds to it, `import_scripts` outers
  actions to the runner so they survive map save/load. On `-game` spawn:
  `OnWorldBeginPlay` → `DispatchLevelEntryMessages` → `DispatchMessage(MessageTrigger,"1-Medical")`
  → ~24 scripts start → ~200 `BIOSHOCK_ACTION applied=` lines. The `LoadRoomDoor` script
  (`TriggeredBy 1-Medical`, 3 actions: `ActionWait 0.5` → `ActionPlayAnimation
  TargetLabel=MedicalLoadRoomDoor Animation=LoadRoomDoor_OPEN` → `ActionPlayAnimation …_OPENED`)
  runs and calls `AShockDoor::OpenDoor`.
- **`AShockDoor`** (`ShockDoor.cpp`) is back to the yaw-swing cube stand-in after `revert` of
  `631ea82`/`60b5e4f`. `import_slice_doors.py` places 41 doors as cube `AShockDoor` +
  `LoadRoomDoor`, wires 86 `UShockTriggerRelayComponent`s. The slice map currently has the
  original static door-mesh actors visible again (un-hidden by the reset).
- `ShockActionPlayAnimation::PlayInWorld` treats `*OPEN*` on a door as `OpenDoor(true)`. It
  **ignores `bWaitForCompletion`** — the runner advances to the `_OPENED` action immediately, so
  any timed sequence collapses.

## Why the skeletal path failed (investigate, don't just repeat it)

Assets ARE present and look sane on paper:
- `/Game/BioShockCharacters/LoadRoomDoorAnim/LoadRoomDoorAnim` — SkeletalMesh, skeleton
  `LoadRoomDoorAnim_Skeleton`, **7 bones** (`Bone01..06`, `SOCKET_LeverBlocking`,
  `SOCKET_blocking`), bounds half-extent ~(47,101,150).
- `Animations/LoadRoomDoor_OPEN` — 6.0 s, 181 keys, **same skeleton**. Probed motion:
  `Bone06` translates **+199 uu in Y** (the slide), `Bone03` rotates **~180° yaw** (the lever).
  Also `_OPENED` (0.07 s hold), `_CLOSE`, `_CLOSED`, `_SPINNING`.
- `Med_DoorAnim` (`Med_DoorOPEN`/`CLOSE`/`BROKEN`/`STUCK`), `BulkheadDoor` (`TestDoorOpen/Close`),
  `AccGateAnim`, `Gate01Anim`, `SlidingBrokeStoreDoor` — same shape.

In-game the `LoadRoomDoorAnim` mesh drew as **spiky, translucent green shards** — classic broken
skinning or a translucent/unassigned material. Questions to answer:
1. Is the skeletal mesh's skin weighting intact? Check `export-fbx` / the rig import
   (`import_level._import_skeletal_rigs`, `tools/ue5/run_import_weapon_meshes.py` pattern) — the
   door proxies may need the same clean-import treatment the weapon rigs got, or `use_t0_as_ref_pose`.
2. What material does it want? `MI_LoadRoom_door` exists — is it translucent, is it even assigned
   to the skeletal mesh's slots? The static `LoadRoomDoorMESH_20894` renders fine with the same
   textures.
3. `LoadRoomDoorAnim_PhysicsAsset` is missing (harmless load warning) — irrelevant to the visual
   but note it for collision.
4. **Does the game even skin the door?** In BioShock a `Door`/`MedicalDoors` actor is an
   *animation proxy* skeleton with **static-mesh leaves attached to its bones** via `Attachments[]`
   (see `docs/research/interaction.md`, `docs/research/door-and-import-materials.md` —
   `MedicalDoors35 → SkeletalMesh_Med_DoorAnim_12858, section 0`). So the visible geometry may be
   rigid static meshes riding animated bones, not a skinned mesh. If so, the fix is: skeletal
   proxy (invisible or 1-bone-per-leaf) + `UStaticMeshComponent` leaves attached to bone sockets,
   driven by the clip. That is a different architecture from "play a skinned SkeletalMesh".

## Where to look

- **Source game**: `tmp/uc_shockgame/` — `Door.uc`, `MedicalDoors` class, `DoorSwitch.uc`,
  `Holdable`/`Interaction` — `bLocked`, `bInitiallyOpen`, `OpenAnimationName`,
  `OpenAnimationRate`, `Attachments[]`, `DoorPortal`, `UseVerbText`, keypad/chained variants.
  `dotnet run --project src/BioShockStudio.Cli -c Release -- properties 1-Medical <DoorActor>` and
  `... context 1-Medical Med_DoorAnim` for the real attachment/socket data.
- `docs/research/interaction.md` §3 (mover/door records), `door-and-import-materials.md` (the
  `Med_DoorAnim` attachment analysis — already done, read it), `scripted-events.md` (the pipeline
  `14b2157` built), `animationpackage.md`, `skeletalmesh.md`, `root-motion.md`.
- Runtime: `ShockDoor.{h,cpp}`, `ShockActionPlayAnimation.cpp`, `ShockActionOpenDoor.cpp`,
  `ShockScriptRunner.cpp` (`bWaitForCompletion` handling, `PendingWait`, `ActionsCompleted`),
  `ShockScriptSubsystem.cpp`, `import_slice_doors.py`, `import_level._import_door_attachments`,
  `_import_skeletal_rigs`.
- The **scripted sequence**: which scripts run at level entry and in what order —
  `LoadRoomDoor`, `Present_LevelStartedCheck` (`TriggeredBy All`), the `TrainingScript` actors,
  the bathysphere-station scripts. Does the load-room door wait on the bathysphere docking, a
  `Wait`, or fire immediately? `bWaitForCompletion=true` on `LoadRoomDoor`'s first
  `ActionPlayAnimation` says the runner is *supposed* to block until the 6 s open clip finishes
  before the `_OPENED` hold — the runner needs to honour that (an action can report "still
  running" until its effect completes).

## What to build

1. **`docs/research/doors.md`** — door architecture (proxy skeleton + static leaves vs skinned;
   the attachment/socket data; door types; collision; locked/broken/keypad), confidence-labelled.
2. **`docs/research/scripted-sequences.md`** (or extend `scripted-events.md`) — the level-entry
   sequence for 1-Medical: script order, triggers, waits, and how `bWaitForCompletion` /
   action-completion should gate it. Enough that the load-room beat is fully explained.
3. **The door implementation** — whichever the research says is right:
   - proxy-skeleton + attached static-mesh leaves animated by the clip (likely), OR
   - a fixed skinned skeletal mesh if the import is just broken, OR
   - a clean slide (translate the real static door mesh along the clip's Y delta) if the full
     anim proxy is out of scope — but say so explicitly and keep the lever motion if cheap.
   Doors must: open on script/interact, slide/animate correctly, drop collision so the player
   passes, respect locked/broken, and NOT leave a mesh blocking the doorway.
4. **`ActionPlayAnimation` / runner completion** — make `bWaitForCompletion` real for door
   clips so `_OPEN` finishes before `_OPENED`.
5. **Wire it in** `import_slice_doors.py` (+ `import_level` if the full import should own it) and
   confirm on the saved slice map — un-hide/replace the leftover static door actors cleanly (an
   earlier over-broad name match hid 100+ meshes; be precise).

## Deliverable

`-game` captures (`tools/ue5/capture_shot.ps1 -Extra @('-bioshockstartslot=1')`, a few settle
values to catch the slide mid-motion and fully open) showing the load-room door animating open
and the room beyond, no blocking mesh. Headless: `verify_script_doors` + `verify_import_scripts`
green, plus a check that the load-room sequence runs to completion (`_OPEN` then `_OPENED`, door
`IsFullyOpen`, collision off). Report walks through both docs' conclusions and shows the captures.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless `UnrealEditor-Cmd` / `rebuild_runtime_fast.ps1`
  (`tasklist //FI "IMAGENAME eq UnrealEditor.exe"` → 0). Kill stray `UnrealEditor-Cmd` / `dotnet`
  / `BioShockStudio.Cli` between runs.
- `-run=pythonscript` swallows `unreal.log` — write results to JSON.
- MSYS: forward-slash Windows paths + `export MSYS_NO_PATHCONV=1`.
- Do NOT commit. No `docs/HANDOFF.md` claim row. Leave the diff for review. A human does the
  final visual QC in the editor.
- Read the reference projects (`UModel-master/`, `Unreal-Library-master/`, repo root, gitignored)
  before deriving door/anim behaviour from bytes.
