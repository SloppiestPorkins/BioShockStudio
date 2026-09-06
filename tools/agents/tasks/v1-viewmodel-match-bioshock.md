---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py, docs/research/**, tmp/**
---

# The first-person weapon viewmodel is wrong. Investigate why, then rebuild it to match BioShock 1 exactly.

This is a **research-first** task. The interactive session has spent hours nudging offset/rotation
numbers on `AShockPlayer::FrameViewmodel` / `AlignEquippedWeaponRootToGripSocket` and it goes in
circles — every weapon needs a different fudge, the hands never line up with the gun, and none of it
matches the real game. The approach is wrong, not the numbers. Find the real architecture, write it
down, then implement it.

## Deliverables (in this order)

1. **`docs/research/viewmodel.md`** — a full write-up of how BioShock 1 does first-person weapons,
   what our exported data actually contains, why the current UE5 code fails, and the design you
   will implement. Confidence-label every claim (`CONFIRMED_BYTES` / `CONFIRMED_EXTERNAL` /
   `PLAUSIBLE` / `UNKNOWN`) per the project's rules (`docs/ENGINEERING_RULES.md` §27, §Process).
2. **The implementation** in `tools/ue5/BioShockRuntime/` (+ any import-script changes in
   `tools/ue5/*.py` if the data needs re-importing differently).
3. **Captures of all 7 weapon slots** (`-bioshockstartslot=0..6`) via
   `tools/ue5/capture_shot.ps1`, saved into `runs/v1-viewmodel-match-bioshock/`, each looked at
   and described in your final report. Idle pose AND — if you can trigger it — mid-fire and
   mid-reload. The bar is: **the hands grip the weapon, the weapon is the right size and in the
   right screen position, and it reads as BioShock 1.**

## What "correct" looks like (the user's reference)

The user sent a screenshot of the real game's **shotgun**: held low-right at the classic FPS
diagonal — stock running off the bottom-right corner, barrel angled up-left toward the crosshair.
The gun fills roughly the right 40% of the frame. BOTH hands are on it: one hand on the pump /
fore-end, the other at the grip/receiver, fingers wrapped. The gold "TIGER" engraving on the
receiver is prominent; loaded shells are visible in the side loops. Nothing floats; the hands and
gun are one unit. Every weapon should read like this — big, close, gripped, BioShock-diagonal.

## Where to look — the original game

- **`tmp/uc_shockgame/Hands.uc`** — the `Hands` class (native in the original, so the `.uc` is
  only the script interface, but it is revealing). Note:
  - three animation channels: `kDefaultAnimationChannel = 0`, `kUseAbilityAnimationChannel = 1`,
    `kHandBobAnimationChannel = 2` — **hand-bob / sway is a SEPARATE additive channel** from the
    weapon/idle animation, not baked into it.
  - `PlayerViewOffset` / `PlayerViewOffsetWidescreen` (config `Weapons`) — the viewmodel screen
    offset, and it has a widescreen variant.
  - `WeaponBobDamping`, `ProceduralLoweringTime` — procedural motion parameters.
  - **separate animation handles**: `HandsAnimationHandle`, `WeaponAnimationHandle`,
    `HolderAnimationHandle`, plus tool/attachment handles. Strongly implies the game plays a
    **hands** clip and a matching **weapon** clip at the same time, on different meshes, kept in
    sync by shared timing — the weapon is animated, not static.
- **`tmp/uc_shockgame/PlayerWeapon.uc`, `Weapon.uc`, `Holdable.uc`** and each weapon
  (`MachineGun.uc`, `Shotgun.uc`, `Pistol.uc`, `Wrench.uc`, `Crossbow.uc`, `GrenadeLauncher.uc`,
  `ChemicalThrower.uc`) — the per-weapon `AttachBone`, `WeaponModel` / `StaticWeaponModel`,
  `IdlingHandsAnim` / `FiringHandsAnim` / `EquippingHandsAnim` arrays, and any `WeaponAnim` /
  firing-model animation names.
- **`tmp/uc_shockgame/ShockPlayer.uc`, `ShockPawn.uc`, `ShockPlayerController.uc`** — how the pawn
  wires the `Hands` actor to the camera, FOV handling (`ActionSetPlayerFOV.uc` exists — check the
  default), and `bIsInWeaponMode`.
- **The config**: `dotnet run --project src/BioShockStudio.Cli -c Release -- config Weapons.ini`
  and `... config User.ini` — `PlayerViewOffset`, `WeaponBobDamping`, `DefaultFOV` / `DesiredFOV`,
  per-weapon offsets if any. `config <file>` lists sections; `config <file> <section>` dumps one.
- **`UModel-master/`, `Unreal-Library-master/`** (repo root, gitignored) if you need the native
  `Hands` / weapon-attachment behaviour that the `.uc` doesn't show. `docs/research/` +
  `docs/HANDOFF.md` §4 "Landmines" for what's already known.

## Where to look — our exported data

- **The hands rig**: `/Game/BioShockWeapons/NEWPlayerHands/NEWPlayerHands` — 47 bones, 19 sockets
  (`Wrench`, `Pistol`, `TommyGun`, `Launcher`, `Chem`, `Crossbow`, all on bone `R_Grip`; plus
  `FirePlasmid`, `GatherSave`, etc.). ~72 `AnimSequence`s under
  `/Game/BioShockWeapons/NEWPlayerHands/Animations` (`FidgetShotgun`, `Swing_A_Wrench`,
  `EquipShotgun`, `FireShotgun`, `EquipPistol`, `FidgetTommygun`, …). **Critical question to
  answer**: do these hand clips contain tracks for a weapon-anchor bone (i.e. does `R_Grip` or a
  child move meaningfully through `FidgetShotgun`, and is there a bone the weapon is meant to
  rigidly follow)? Dump the bone tracks of `FidgetShotgun` / `FidgetTommygun` and see.
- **The weapon rigs**: `/Game/BioShockWeapons/WP_<Name>/WP_<Name>` — each has its OWN skeleton
  (Pistol 8 bones root `R_grip`; **Shotgun root `SG_Body`, no `R_grip`**; TommyGun 12 bones incl
  `TG_AmmoClip` = the drum; Crossbow 15; GL 8). Each weapon export also brought
  `WP_<Name>_Animations/` clips (`Reload`, `FastReload`, `FireShotgun`, …). **Are these the
  weapon-side animations meant to play on the weapon mesh in sync with the hand clip?** The
  weapon mesh names for a clean re-export via `export-fbx UAPW_WP_<W> --mesh <M>` (from the
  `characters` CLI command): Pistol=`WP_PistolMesh`, TommyGun=`TommyGunMESH`,
  Shotgun=`WP_ShotgunMesh`, Chem=`WP_ChemicalThrowerMesh`, Crossbow=`WP_CrossbowMesh`,
  GL=`WP_GrenadeLauncherMesh`.
- **Decoded socket transforms**: `MeshSocket.Transform` is decoded (33/33 sockets orthonormal,
  `CONFIRMED_BYTES` — `src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`). The Wrench socket
  carries ~180° about Z; Pistol identity; TommyGun ~(5,20,0); Launcher ~(20,23,4). Commit
  `d479fbe` plumbed these through the manifest → `_restore_manifest_sockets` → the
  `BioShockImportTools` plugin's `RestoreSockets` (5-arg). Commit `d534944` then found that
  applying them to grip-weapon sockets DOUBLE-rotates the weapon (the runtime
  `AlignEquippedWeaponRootToGripSocket` already cancels the weapon's `R_grip` root rotation), so
  `_restore_manifest_sockets` currently keeps the transform for **`Wrench` only** and the live
  `NEWPlayerHands` grip sockets were reset to identity. Understand this fully before you change it.

## Why the current code fails (starting hypotheses — verify or refute each)

`AShockPlayer` (`tools/ue5/BioShockRuntime/Source/BioShockRuntime/Private/ShockPlayer.cpp`):

1. **`ViewHands` is a `USkeletalMeshComponent` attached to `FirstPersonCamera` at relLoc (0,0,0).**
   The hand clip plays on it via `PlayViewHandsAnimation` → `PlayAnimation` (single-node).
2. **`FrameViewmodel(GripSocket)` runs EVERY Tick.** It reads the grip socket's current
   (animated) position in `ViewHands` component space and then sets
   `ViewHands->SetRelativeLocation(ViewmodelOffset - socketInCameraSpace)` — i.e. it shoves the
   whole hands mesh the opposite way each frame so the socket stays pinned at `ViewmodelOffset`.
   **This cancels the animation's motion of the gripping hand** — the socket (and the weapon
   rigidly attached to it) holds dead still while the rest of the arm slides around underneath.
   That is the "animations don't line up with the weapon" the user is reporting.
3. **The weapon is a separate `AShockWeapon` actor**, its mesh attached to a `ViewHands` socket
   (`Launcher`, `TommyGun`, …) with `SnapToTarget`. **No animation plays on the weapon mesh** —
   it is a static prop rigidly following one bone. If BioShock animates the weapon in sync (see
   `WeaponAnimationHandle` above), that is the missing half.
4. **`AlignEquippedWeaponRootToGripSocket`** cancels the weapon's root-bone component transform so
   the root lands on the socket. For the Shotgun (`SG_Body` root = the gun body, not a grip) this
   drags the receiver into the camera → the recurring "huge blob" — because `SG_Body` is the
   wrong anchor point.
5. **FOV was UE's 90;** BioShock 1 is ~75 (`AShockPlayer::CameraFieldOfView = 75` landed in
   `baaaaa0` — keep or refine, but confirm the real default from config).
6. A **stashed experiment** — `git stash show -p stash@{0}` — tried "anchor `ViewHands` once to
   the reference-pose socket, don't re-pin, let the animation drive." It broke the wrench (arm
   huge, through the camera) because the ref-pose socket sits far forward for that rig. Read it;
   it may be one step from right, or a dead end.

## The likely correct architecture (design it properly, don't assume)

Most first-person games — and, from `Hands.uc`, BioShock — do this:

- Hands mesh at a **fixed** camera-relative transform (`PlayerViewOffset`). No per-frame
  re-pinning against an animated bone.
- The **hand clip** plays on the hands. The **matching weapon clip** plays on the weapon mesh,
  started at the same time, same play rate — OR the weapon is skinned/attached such that a single
  clip drives both.
- Idle **sway / bob** is a small additive layer on top (separate channel — `kHandBobAnimationChannel`),
  driven by look/move velocity, not baked into the idle clip.
- The weapon attaches to the hand bone/socket its `AttachBone` names, at the socket's decoded
  transform, and simply inherits that bone's animated motion — which works **only if the hand
  clip actually animates that bone**, which is the thing you must verify in the data.

Figure out which of these BioShock actually does, whether our imported clips support it, and if
not, what has to change in the export/import (`tools/ue5/import_bioshock.py`,
`import_fp_hand_anims.py`, `run_import_weapon_meshes.py`) to make it possible. It is fine — expected,
even — for the answer to be "re-import the weapon meshes + hand anims a specific way and play both
clips."

## Constraints

- Editor must be CLOSED for any headless `UnrealEditor-Cmd` / `rebuild_runtime_fast.ps1` binary
  copy (`tasklist //FI "IMAGENAME eq UnrealEditor.exe"` returns 0). Kill stray
  `UnrealEditor-Cmd` / `dotnet` / `BioShockStudio.Cli` between runs — a leftover CLI process
  locks `BioShockStudio.Core.dll` and the next `dotnet run` silently no-ops (MSB3027).
- `capture_shot.ps1` from bash comma-joins `-Extra 'a','b'` into one arg — invoke it through
  PowerShell with a real array, or call `UnrealEditor-Cmd` directly with separate flag tokens.
  Slot-0 captures flake when several run back-to-back (leftover process pollutes weapon state) —
  one at a time, kill the editor between.
- `-run=pythonscript` swallows `unreal.log` output — write probe results to a JSON file and read
  that. UE5.7 python: no `Texture2D.update_resource`, no `SkeletalMeshComponent.get_bone_location`
  (use `get_socket_location(boneName)`), no `SkeletalMesh.get_num_vertices`.
- Do NOT junction the UE project. Do NOT touch `src/**` decode code unless the investigation
  genuinely needs an export-format change (then say so loudly in the doc and keep the old reader
  working). Do NOT commit. Do NOT add a claim-table row to `docs/HANDOFF.md`.
- The `../BioShockUE5-broken-assets-20260906/` folder holds pre-recovery weapon assets — a
  reference if you need to compare, not something to restore blindly.

## What good looks like when you're done

`docs/research/viewmodel.md` explains the real system with evidence. The runtime plays the hand
clip and the weapon clip together (or whatever the investigation shows is right), the hands grip
each weapon, sizes and screen positions match the reference, and the 7 captures prove it. If the
investigation concludes the data must be re-exported/re-imported, the doc says exactly how and the
scripts do it. Leave the diff for review with a report that walks through the doc's conclusions and
shows the captures.
