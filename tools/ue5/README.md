# UE5 import bridge

## Phase U1 — SWF tag-512 bitmap decode — 5 Sept 2026

Scaleform **tag 512** is a raw DXT texture (`DefineBitsDxt`). Decoder:
`SwfBitmapReader` in `src/BioShockStudio.Core/UI/Swf/` (reuses `BlockCompression`).
CLI: `export-swf-images <file.swf> <out-dir> [--id=N]` writes `<id>.png` +
`swf_images_manifest.json`. Bulk driver (no Unreal):

```powershell
$env:BIOSHOCK_REMASTERED_PATH = "G:\SteamLibrary\steamapps\common\BioShock Remastered"
# optional: $env:BIOSHOCK_UI_EXPORT = "$env:TEMP\bioshock-ui"
py -3 tools\ue5\export_all_ui_images.py
```

Output defaults to `%TEMP%/bioshock-ui/<movieStem>/` plus a top-level `catalogue.json`.
PNGs stay outside git. Tag 12 = DoAction (AS bytecode, not 9-slice); tag 34 =
DefineButton2. Fast tests: `SwfBitmapReaderTests` (HUDPC → 14 bitmaps).

---

## HUD reskin with decoded Scaleform art — 5 Sept 2026

`UShockHudWidget` now draws health/EVE with `UImage` textures decoded from BioShock's
FlashMovies (not plain `UProgressBar`s). Ammo stays `UTextBlock`.

**Art found**

| Role | Source | Notes |
|---|---|---|
| Health arc | `HUDPC.swf` `FrozenHealth_DangerBar` (id 98 → shape 96, radial-gradient red) | Confirmed vector render |
| EVE arc | `HUDPC.swf` unnamed DefineShape3 id 158 (solid blue arc) | Real vector art from the same HUD file |
| Meter underlay | `HUDPC.swf` unnamed DefineShape3 id 160 | Grey chrome arc behind health |

**Searched, not wired (blockers / gaps)**

- `swf-find` on `HUDPC.swf` / `PCWeaponSelection.swf` / `GeneBankPC.swf` for Eve, Vita, Meter,
  Ammo, Danger, Frozen, Needle, Hypo, Bar, Fill, Display, HUD — no named EVE meter export in
  HUDPC; EVE/health chrome live mainly in `sharedlibrary.swf` (pulled in via HUDPC
  `ImportAssets`).
- Canonical `sharedlibrary.swf` `HUD_HealthBar_Frame01..21` and `HUD_EveBar_Frame01..21` (plus
  `HUD_Ammo_Base*`) are **Bitmap** fills whose pixels live in Scaleform **tag 512**
  (`DefineBitsDxt`). **U1 landed** — `export-swf-images` / `export_all_ui_images.py` decode
  them; Phase U2 imports the PNGs into `/Game/BioShockUI/**`.

- `FrozenHealth_DangerBar` has 20 frames animated by `PlaceObject2` **ColorTransform** (not
  Ratio/morph; no DefineMorphShape in HUDPC). `export-swf-sprite` is first-frame only; the widget
  maps health%/eve% → `UImage` opacity as a first-pass stand-in.
- `WrenchAmmo` (HUDPC id 1) is an empty sprite; ammo panel remains text.

**Pipeline (PNGs outside git — `%TEMP%/BioShockHudUi/import`)**

```powershell
$env:BIOSHOCK_REMASTERED_PATH = "G:\SteamLibrary\steamapps\common\BioShock Remastered"
py -3 tools\ue5\export_hud_ui.py
# then in UnrealEditor-Cmd:
#   -script=<repo>\tools\ue5\run_import_hud_ui.py
# then rebuild runtime + run_hud.py
```

Content path: `/Game/BioShockUI/HUD/T_Hud_{HealthArc,EveArc,MeterUnderlay}` (HostProject only).

**Verify:** headless `run_hud.py` asserts widget construct, text/ammo behaviour, viewport add, and
**non-null** health/EVE `UImage` textures after import. **Visual likeness to BioShock's HUD is a
human PIE check** — not claimed headlessly. Code ready; this worktree had no live UE session.

---

## Phase 2.3 tail-2 — script import across all 21 maps — 5 Sept 2026

Owed re-import after tail-1 (`OrStatement` / needle / `TrainingCondition` mapper fix).
Headless batch: `prepare_script_import_exports.py` (sidecars + Ue5Manifest-only JSON under
`%TEMP%/bioshock-script-import-all-maps`, no mesh dumps) then
`run_import_scripts_all_maps.py` into scratch `/Game/BioShockScriptImport/_Scratch`
(Medical not re-opened; baseline kept from 27 Aug).

```powershell
$env:BIOSHOCK_REMASTERED_PATH = "G:\SteamLibrary\steamapps\common\BioShock Remastered"
$env:BIOSHOCK_SCHEMA_DIR = "C:\Users\Jack\Documents\BioShockUE5\Exports\slice"
$env:BIOSHOCK_SCRIPT_IMPORT_ROOT = "$env:TEMP\bioshock-script-import-all-maps"
$env:BIOSHOCK_SCRIPT_IMPORT_OUT = "$env:TEMP\bioshock-script-import-all-maps\bioshock_import_scripts_all_maps.json"
py -3 tools\ue5\prepare_script_import_exports.py --skip-medical-manifest
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\run_import_scripts_all_maps.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 5 Sept 2026 — `Success - 0 error(s)`, `ok=true`,
`tail1_target_hits={}`.** All four tail-1 classes import clean on every affected map
(`4-Recreation` OrStatement×15, `1-Welcome` TrainingCondition×1, needle×4 on
`7-BossFight`, Or×2 on Resi/Slums/Gauntlet/ChallengeRoomElectric). Report:
`%TEMP%/bioshock-script-import-all-maps/bioshock_import_scripts_all_maps.json`.

| Map | Scripts | Mapped | `nested_unmapped` | Remaining `nested_unmapped_classes` |
|---|---:|---:|---:|---|
| `0-Lighthouse` | 54 | 339 | 0 | — |
| `1-Medical` | 300 | 1,463 | 0 | *(prior 27 Aug; not re-run)* |
| `1-Welcome` | 320 | 2,195 | 0 | — |
| `2-Fisheries` | 418 | 2,210 | 0 | — |
| `2-SubBay` | 74 | 510 | 0 | — |
| `3-Arcadia` | 369 | 2,150 | 0 | — |
| `3-Market` | 140 | 597 | 0 | — |
| `4-Recreation` | 439 | 3,072 | 88 | `ActionChangeSkinToPhoto` 68; `ActionSetNextAssassinTeleportInRunDestination` 20 |
| `5-Hephaestus` | 190 | 760 | 0 | — |
| `5-Ryan` | 95 | 577 | 0 | — |
| `6-Resi` | 192 | 929 | 0 | — |
| `6-Slums` | 117 | 553 | 0 | — |
| `7-BossFight` | 71 | 379 | 0 | — |
| `7-Gauntlet` | 139 | 854 | 0 | — |
| `7-Science` | 189 | 894 | 0 | — |
| `Autoplay` | 300 | 1,460 | 0 | — |
| `Entry` / `museum` | 0 | 0 | 0 | — |
| `ChallengeRoomCombat` | 304 | 1,831 | 12 | `ActionSetNextAssassinTeleportInRunDestination` 9; `ActionSaveGame` 3 |
| `ChallengeRoomDecoy` | 90 | 378 | 0 | — |
| `ChallengeRoomElectric` | 141 | 601 | 0 | — |

Top-level `unmapped_classes` empty on every map. Remaining nested gaps are genuine
missing `UShockAction*` classes (name maps `Action*`→`ShockAction*` but
`load_class` fails) — not stubbed. Closest existing types are
`ShockActionChangeSkinAtIndex` and `ShockActionSetNextAssassinTeleportPoint`
(different UnrealScript names). `ActionSaveGame` has no runtime class yet.

Also: `import_scripts.py` sibling sidecar lookup no longer prefers a stray
`1-Medical.script-actions.json` ahead of the manifest's own sibling.

---

## Grenade Launcher slot equip + Tommy Gun ammo drum (h16) — 5 Sept 2026

Two in-editor reports right after h12 (grip align) / h14 (GL mesh).

**1. Grenade Launcher not equipable (confirmed code bugs, not Projectile fire mode).**
Headless `GiveWeaponByDef("GrenadeLauncher", 4)` + `EquipWeapon` already resolved a mesh
(`run_weapon_meshes.py`, h14) — that path bypasses both failures:

| Bug | Where | Effect |
|---|---|---|
| Starter loadout hole | `AShockGameMode::EquipStarterWeapon` | Never called `GiveWeaponByDef(GrenadeLauncher, 4)`. `SelectWeaponSlot(4)` early-returns on null. Scroll/`NextWeapon` also skips empty slots. |
| Input skip | `HandleWeaponSlot5Input` → `SelectWeaponSlot(5)` | Keys 1–4 mapped to slots 0–3; Key 5 jumped to Chem (slot 5) and Key 6 to Crossbow (slot 6), permanently skipping slot 4. |

BioShock key layout is 1=Wrench … 4=Shotgun, **5=GrenadeLauncher**, 6=Chem, 7=Crossbow.
Fix: give GL in `EquipStarterWeapon`; remap Slot5→4, Slot6→5; add `WeaponSlot7`→slot 6
(+ `setup_playable_slice.py` Key=Seven). `DriveWeaponSlotInputForVerify` exercises the same
handlers the ActionMappings bind (not a direct `SelectWeaponSlot`). Also tightened the
starter early-return to holster slot 0 occupancy (`GetEquippedWeapon()` was the wrong gate —
`GiveWeaponByDef` does not auto-equip).

**Stale editor registry still worth ruling out first in PIE:** GL `.uasset`s imported via a
separate `UnrealEditor-Cmd` while an interactive editor stayed open may not be in that
session's asset registry — restart the editor and re-check Key 5 before assuming a rebuild
didn't take.

**2. Tommy Gun ammo drum "detached" — not a separate component (h12 Align is not the cause).**
`WP_TommyGun` skeleton (`ue5_manifest` / FBX): `R_grip`, `TG_TommyGunBody`, **`TG_AmmoClip`**,
`TG_PistonSOCKET`, `TG_Trigger`, `TG_Bolt`. `AShockWeapon` owns one `USkeletalMeshComponent`.
`AlignEquippedWeaponRootToGripSocket` only `SetRelativeTransform` on that mesh — bone hierarchy
is preserved, so a same-skeleton drum cannot be left behind by the align. Headless asserts:
component count == 1, `TG_AmmoClip` / `TG_TommyGunBody` exist, body↔clip distance ≤80 uu after
equip. A live-PIE-only detach (e.g. wrong material section / import) is still a human look;
this worktree has no interactive editor session.

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
# ensure WeaponSlot7 in the live project's DefaultInput.ini once:
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\setup_playable_slice.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\run_weapon_slots.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\run_viewmodel_anims.py -unattended -nopause -nosplash
```

Reports: `%TEMP%/weapon_slots_report.json`, `%TEMP%/viewmodel_anims_report.json`.

**Verified live UE5.7, 5 Sept 2026** — `weapon_slots=ok` 0 failures
(`grenadeLauncherSlot5Input.activeSlot=4`, `equippedDef=GrenadeLauncher`);
`viewmodel_anims` 0 failures (`TommyGun.ammoDrum`: 1 skeletal mesh component,
`TG_AmmoClip`/`TG_TommyGunBody` present, body↔clip **3.2 uu** after align).
Human should still restart the interactive editor (stale-registry) and confirm Key 5
+ TommyGun drum look in PIE.

---

1. Deploy `BioShockImportTools/` into the UE project's `Plugins/` folder and enable it in the
   `.uproject`. It is an editor-only plugin used to restore socket markers after FBX normalization.

   **This is a C++ plugin, so copying the source folder is not enough** — it has to be compiled.
   Proven the hard way, 23 Aug 2026: importing into a genuinely fresh project with the folder
   copied in fails at socket restoration with

   ```
   RuntimeError: BioShockImportTools editor plugin is required for socket restoration.
   ```

   because `unreal.BioShockSocketLibrary` only exists once the module is built and loaded.
   Either:

   - make the target a **C++ project** so the editor builds the plugin on load, or
   - copy a **prebuilt** `Plugins/BioShockImportTools/Binaries/Win64/` alongside the source
     from a project that has already built it.

   Everything else in the pipeline works without the plugin — meshes, skeletons, animations and
   textures all import — so if you only need those, the failure above is the only thing standing
   in the way and the socket-restoration step is what to skip.
2. Keep `Interchange.FeatureFlags.Import.FBX=false` in the project's `DefaultEngine.ini` for UE5.7.
3. From UE Python, add this directory to `sys.path` and call
   `import_bioshock.main(<export-directory>, "/Game/BioShock")`.

The importer normalizes each FBX through an empty Blender scene before import, persists the
companion Skeleton assets, restores valid manifest sockets through the plugin, and keeps every
source socket in `BioShockSockets` metadata. Manifest v2 rig imports also create material instances,
bind decoded base-colour/normal textures, and place them in the slot used by the imported LOD
section. The textured first-person pistol is visually verified in UE5.7. The pistol (12 animations)
and TommyGun (13 animations) slices pass `verify_bioshock_import.py`.

**A second import of the same export is a reuse, not a re-normalize.** After a complete import the
skeletal mesh is stamped with `BioShockImportFingerprint` — a hash of the current export's
inventory and source-file size+mtime. A later `import_bioshock.main` skips Blender and FBX when that
stamp matches and every animation and texture is still present. A missing stamp, a mismatch, or a
hole in the inventory is a full re-import; inventory-only matching is deliberately not used, because
that is how a stale mesh with the same names would be kept. `BIOSHOCK_FORCE_IMPORT=1` turns skip
off. `skipped` in the report still means "failed to import"; reuse is counted separately as
`reused`. **Measured live UE5.7, 26 Aug 2026**, TommyGun export, `run_import_skip.py`: first import
37s / 0 reused; second **0.16s / 2 reused**; breaking the stamp re-imported that one rig (1 reused,
26s); deleting `EmptyFidgetTommygun` did the same; `Success - 0 error(s)`.

For a level JSON export, run `validate_level_manifest.py <map>.ue5-level.json` before importing. It
requires manifest version 3, verifies that the actor coverage ledger reconciles to the raw actor
graph, checks every ordinary geometry instance's stable actor key (with the compiled world explicitly
identified as actorless), and reports geometry actors separately from the typed UE2 placeholders that
still need a specialised UE5 component. It also refuses a named mesh section without its stable
material source identity.

## Level import

`import_level.py` reproduces a level manifest's actors in the currently-open UE5 level:

```python
import import_level
import_level.main(r"<map>.ue5-level.json")
```

It is **idempotent**: every actor it owns carries a `BioShockKey=<manifest key>` tag, and a second
run finds and updates those rather than spawning duplicates. Verified on `0-Lighthouse` in UE5.7 —
first run 1,877 created, second run 0 created / 1,877 updated, actor count unchanged.

It reports `created / updated / skipped / unsupported` in one pass. **Lights become real
`PointLight` actors** carrying colour, authored brightness as intensity (no `* 1000`), and
authored radius as attenuation radius, with inverse-square falloff off. A light with no radius
is not spawned. **Geometry instances
become real `StaticMeshActor`s**: each unique asset is imported once from its local-space mesh
(manifest v4's per-asset `file`) and placed by the manifest's per-instance transforms. Measured on
`0-Lighthouse`: 422 meshes, 1,274 instances, 0 skipped.

**Every instance was placed mirrored in Y with an inverted rotation until 24 Aug 2026, found by a
user exploring the imported level** — the counts above were never wrong, but the placement was.
`LevelSceneExporter` runs every instance transform and light location through `GameBasis.Convert`
(this project's right-handed, +Y-left basis for Blender/FBX/glTF); Unreal's own basis is
left-handed, +Y-right, the opposite. `import_level.py` fed the manifest's numbers straight into
`unreal.Vector`/`unreal.Quat` with no reversal. Fixed by reversing the same reflection — it is an
involution, so reversing it is negating Y again, and negating the quaternion's X and Z components —
before every placement call. Verified in a live UE5.7 editor, not just re-derived: re-running
`LevelSceneTests.TheMedicalPavilionCeilingArchFormsOneContinuousSurface`'s own check against the
actually-placed actors on `1-Medical`, the four `window_512_corner_4up` instances' combined
world-space bounding diagonal came back **2422 units** — that test's own reference value for a
correctly-assembled arch (a twisted, wrong-handed one measures ~4295). See `docs/HANDOFF.md` §4.

**Materials, verified in the same live UE5.7 run, 24 Aug 2026.** When the manifest carries a
`materials`/`textures` array (only when the level was exported with an open package — see
`LevelSceneExporter.Write`'s `package` parameter), `import_level.py` reuses
`import_bioshock.py`'s texture-import and `MaterialInstanceConstant` creation unchanged, keyed by
each manifest material's own `key` rather than its name (a `MaterialSwitch` reference and its
resolved default child can share one instance under two different keys).

**Multi-material meshes and UV mapping, 24 Aug 2026, also verified live.** `BuildAssetObj` now
writes a "vt" line per vertex (same V-flip as the proven FBX rig path) and one "usemtl
BioShock_{n}" group per section, instead of positions/faces only with no grouping at all — the
latter meant every imported mesh had no UV mapping, and a multi-material mesh always collapsed to
one slot, regardless of what got assigned to it. `_assign_asset_material` now builds one material
slot per section, in order, rather than skipping a mesh whose sections disagree. Verified in a live
UE5.7 editor: of 792 `1-Medical` assets needing more than one slot, a 20-asset sample all show the
imported slot count matching the manifest's own section count exactly, and 1,357 static meshes
total got at least one real material assigned (up from 619 when only single-material meshes were
handled). A section whose material key doesn't resolve gets an empty slot rather than borrowing a
neighbour's material.

**Correction + fix, 4 Sept 2026 — that 24 Aug "slot count" check was the wrong evidence.** Slot
count is what `_assign_asset_material` *writes*; it does not prove the mesh has one render section
per slot. Live PIE (windows, ad frames): first material on every slot. Headless probe of
`ad_horizontal_3702` (and a Content/Meshes census): multi-slot meshes commonly had N slots but
**1** LOD0 section / **1** polygon group. Cause: meshes imported before `usemtl` existed were
reused forever (`does_asset_exist` → load only), so assignment never saw real sections. Fresh
import of the same OBJ yields the correct section count. Fix: `_import_asset_meshes` reimports when
`get_num_sections(0) < len(sections)`; `_assign_asset_material` refuses to paper over a mismatch.
`verify_static_prop_materials.py` asserts section count + polygon groups + distinct slot materials
on `ad_horizontal` after that import path (**ok**, `sectionReimports=1`, sections 1→2). Project-wide
repair of already-imported props (mesh assets only, no map load, `StaticMesh`/`SkeletalMesh` only,
skips BuiltWorld/Brush): `repair_static_prop_material_slots.py` — dry-run on 1-Medical: 93
candidates, 92 still need reimport after the canary fix. Single-material props are unaffected.

**A third headless-only crash, found and disabled the same way as the PNG/FBX ones above.**
`Interchange.FeatureFlags.Import.OBJ` started asserting under `-unattended` only once the OBJ
writer began emitting UV/group data — the same `CurrentApplication.IsValid()` Slate assertion, on a
translator that had been importing OBJs cleanly for the single-section, UV-less case. Found by
grepping the engine source for `InterchangeOBJTranslator.cpp`'s own registered CVar name rather than
guessing.

Actors with no geometry to attach become positioned, tagged `TargetPoint`s counted as
`unsupported`. That count is deliberately
visible rather than folded into "created" — the coverage ledger already separates "placed" from
"decoded" and this keeps the same distinction in the engine.

**`CubemapProbe` actors become `SphereReflectionCapture`, live UE5.7 25 Aug 2026.**
`export-cubemaps 1-Medical` wrote 29 probes / 29 complete cubemaps (six 64×64 face PNGs each).
`tools/ue5/run_cubemap_look.py` in a headless UE5.7 session imported them:
**29 `SphereReflectionCapture` at the manifest locations, 174 face `Texture2D`s (64×64, sRGB),
0 skipped, 0 `TextureCube`.** `Success - 0 error(s), 0 warning(s)`. Influence radius stays the
engine default (no shipped radius decoded). Face-to-axis mapping is still `UNKNOWN` — do not
pack a cube. This is a probe-only import, not a look at reflections on Medical geometry.

Run `validate_level_manifest.py <map>.ue5-level.json` first.

**Lights, live UE5.7 25 Aug 2026.** `run_light_look.py` against the existing `1-Medical` manifest:
**664 `PointLight`s** (every light that stated a radius), 28 dropped (no/zero radius, UNKNOWN
reach), intensity = authored `LightBrightness` (or 1.0), attenuation radius = authored
`LightRadius`, inverse-square off. `Success - 0 error(s), 0 warning(s)`. This is a property
check, not a look at reflections on Medical geometry. `LightFalloffExponent` stays UE5's
default 8 — the game's own falloff curve is `UNKNOWN`.

## Vertical slice (Phase 0)

`run_vertical_slice.py` drives `verify_vertical_slice.py`, which imports one level manifest and one
weapon rig into a **persistent** level, saves it, switches away, loads it back off disk, and checks
the actors in the *reloaded* level:

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_vertical_slice.py -unattended -nopause -nosplash
```

Paths and the rig filter come from `BIOSHOCK_SLICE_MANIFEST` / `_WEAPON` / `_OUT` / `_RIGS`; the
report is written even when the run raises.

**Measured live in UE5.7, 26 Aug 2026 — `1-Medical`, 22m03s, `Success - 0 error(s)`, exit 0.** A
real `Content/BioShockSlice/1-Medical.umap`, 14 MB, exists on disk afterwards; every previous UE5
verification here was a live, unsaved editor session. The census is **identical before the save and
after the reload**: 5,312 `StaticMeshActor`, 664 `PointLight`, 29 `SphereReflectionCapture`, 12
`SkeletalMeshActor` (10 level characters + the 2 weapon rigs), 2,075 `TargetPoint` — 8,090 of them
carrying a `BioShockKey` tag. The ceiling-arch handedness canary measures **2422.0** units *read
back off disk*, matching `LevelSceneTests`'s own reference for a correctly assembled arch (a
mirrored one is ~4295).

**What it deliberately does not cover.** `BIOSHOCK_SLICE_RIGS` defaults to one enemy archetype
(`Agg_BabyJane`), which is what Phase 0 asks for; the level's other 31 skeletal assets fall back to
bind-pose static meshes, exactly as they do for a rig that fails to import, and the report records
which rigs were asked for so a filtered run cannot be misread as a whole-level one. Set it empty for
every rig — a first import of an unstamped rig still pays the animation cost (one splicer
variant carries 457, 20 minutes of the 22 above); a second import of the same export reuses. This
is an asset round trip, not a playable slice: there is no gameplay layer, and the level's look is
still unbuilt lighting.

The run leaves a small `_Scratch.umap` beside the level. That is the mechanism, not a stray: the
editor has to actually leave the slice level before loading it, or the "reload" would hand back the
same in-memory actors the run just spawned. Leaving is asserted too.

## Fast C++ rebuild (BioShockRuntime)

Day-to-day C++ iteration uses `rebuild_runtime_fast.ps1` (incremental UBT against a warm
`PluginBuild\BioShockRuntime\HostProject`, usually tens of seconds). That HostProject is
created by a one-time `RunUAT BuildPlugin` with `-NoDeleteHostProject`.

If `rebuild_runtime_fast.ps1` throws "HostProject missing", or you wiped
`C:\Users\Jack\Documents\BioShockUE5\PluginBuild\`, reseed:

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/seed_hostproject.ps1
```

Idempotent: exits 0 immediately when HostProject is warm and Source matches the repo plugin.
Use `-Force` to rebuild the seed from scratch. Then:

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
```

Do **not** re-run full BuildPlugin for every `.cpp` tweak — only to (re)seed HostProject.

## AI hostility + BabyJane mesh orientation (TestArena PIE)

Live PIE on `/Game/BioShockSlice/TestArena` previously never engaged: target
acquisition required `AttackOnSightLabels` (or prior damage-aggro), which
GameMode-spawned players cannot satisfy. `bHostileToAnyPlayer` (default false)
is a third gate alongside label/aggro. Mesh assign now goes through
`ABaseShockAI::ApplyCombatSkeletalMesh`, which sets RelRotation to Identity —
BioShock full-body rigs are +X forward / +Z up (`docs/research/ANIMATION_COORDINATE_SYSTEM.md`);
`ACharacter`'s mannequin default `(0, -90, 0)` only corrects facing for +Y meshes.
That yaw fix cannot invert up/down; if `GetMeshUprightDeltaForVerify` is largely
negative the import itself is inverted — no guessed pitch/roll is applied.
Mesh `NoCollision` (capsule keeps collision) is unchanged and unrelated to orientation.

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
```

```bash
# Re-save arena enemies with bHostileToAnyPlayer=true (idempotent):
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\setup_test_arena.py -unattended -nopause -nosplash

# Level-loaded verify (not fresh spawn):
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_test_arena_verify.py -unattended -nopause -nosplash
```

**4 Sept 2026 — code landed; headless verify pending** (Shell hook blocked in the
authoring session). Re-run the two commands above after `rebuild_runtime_fast.ps1`.
Report: `%TEMP%/bioshock_test_arena_verify_report.json`.

## AggressorBabyJane import upright (h4)

Measured live on TestArena (4 Sept 2026, after h2 Identity RelRotation): all three
enemies reported `headZ-feetZ = -124.6` — inverted. Authored bbox is Z[1.1, 197.6];
expect ~+196. `C = diag(1,-1,1)` is already applied once at C# decode; the FBX
declares Z-up / -Y-front (same triple UE `ConvertScene` targets). The Blender
normalize step used Blender's default **Y-up** export, so UE's ConvertScene was a
non-identity remap and landed the bind pose upside down. Fix is import-time only:
`tools/ue5/normalize_fbx_for_ue5.py` re-exports `axis_up='Z'`, `axis_forward='-Y'`;
`import_bioshock.py` points at that normalizer. Mesh + animations must re-import
together (`BIOSHOCK_FORCE_IMPORT=1`). No RelRotation pitch/roll in
`ApplyCombatSkeletalMesh`. Hands share the same basis (`ANIMATION_COORDINATE_SYSTEM.md`
§2) — same normalizer; re-import NEWPlayerHands if viewmodel framing looks off after
this.

```bash
# Re-exports to %TEMP%/bioshock-h4-aggressor-babyjane if FBX is missing, then force-imports.
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_reimport_aggressor_babyjane.py -unattended -nopause -nosplash

UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\setup_test_arena.py -unattended -nopause -nosplash

UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_test_arena_verify.py -unattended -nopause -nosplash
```

**4 Sept 2026 — import-path fix landed in this worktree; headless reimport/verify not
re-run here** (Shell blocked by Cursor `rtk hook claude` / bash conflict). Prior
verify report at `%TEMP%/bioshock_test_arena_verify_report.json` still shows -124.6
until the three commands above run. Success criterion: uprightDelta strongly
positive (~196), not merely >0.

## AggressorBabyJane forced-reimport IntFitsIn crash (h6)

Measured three times 4 Sept 2026 (mesh+anims Z-up, mesh+anims Y-up, mesh-only): after
`Built Skeletal Mesh [0.12s]` the task entered `InternalPromptForCheckoutAndSave` /
`Saving Package` on the existing asset, hung ~9 minutes, then:

`Assertion failed: IntFitsIn<OutType>(In) … In = 2499805188` (~2.33 GiB)

Still inside `AssetTools.ImportAssetTasks` — **not** animation import and **not** axis
normalization. The live `AggressorBabyJane.uasset` had ballooned to ~1.2 GiB / ~130s
load (`verify` probe). FBX sources are normal (~400–500 KB).

Mitigation in `import_bioshock.py` (same pattern as texture import /
`fix_compiled_world_materials._reimport_mesh`):

1. Delete existing mesh/skeleton/physics before reimport (fresh create, no atomic
   reimport over the bloated package).
2. `AssetImportTask.save = False`; persist with `save_loaded_asset` (avoids
   `InternalPromptForCheckoutAndSave` under `-run=pythonscript`).
3. `create_physics_asset = False` and `import_meshes_in_bone_hierarchy = False` on
   skeletal options.

```bash
# Mesh+skeleton only (fastest recovery path):
set BIOSHOCK_MESH_ONLY=1
set BIOSHOCK_REMASTERED_PATH=G:\SteamLibrary\steamapps\common\BioShock Remastered
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_reimport_aggressor_babyjane.py -unattended -nopause -nosplash

# Size + load-time gate:
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\verify_aggressor_babyjane_health.py -unattended -nopause -nosplash
```

Reports: `%TEMP%/bioshock_reimport_aggressor_babyjane.json`,
`%TEMP%/bioshock_aggressor_babyjane_health.json`. Healthy: uasset ≪ 50 MiB and load
≪ 30s. Then drop `BIOSHOCK_MESH_ONLY` and re-run to bring back the 457 animations
(chunk if a full batch crashes — unconfirmed until mesh recovery lands).

**4 Sept 2026 — code mitigation in this worktree; live reimport not executed here**
(Shell blocked by the same `rtk hook claude` failure). Re-run the two commands above
and record sizeMiB / loadSeconds in this section once green.

## AI combat animations (PlayAnimation by brain ability)

`ABaseShockAI` drives its skeletal mesh with the same raw `PlayAnimation` pattern as
`AShockPlayer::EnsureViewHands` — no AnimBlueprint. Ability name from
`UShockAIBrain::GetActiveAbilityName()` selects a cached `UAnimSequence` (BabyJane ME_
idle / walk / run / melee / hit-react); `OnDeathFromDamage` plays a non-looping death clip
and holds the last frame. Mesh is assigned to `AggressorBabyJane` only when unset.

Asset paths confirmed present under
`Content/BioShockCharacters/AggressorBabyJane/` before hardcoding (4 Sept 2026).

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
```

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_ai_animation.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 4 Sept 2026 — `Success - 0 error(s)`** via
`rebuild_runtime_fast.ps1` + `run_ai_animation.py`. Report: mesh
`AggressorBabyJane`; idle/move before engagement; `ME_attackMelee_A` while
`ShockAIMeleeAttackAbility` active; `Death_StumbleFWD` after lethal damage
(`ai_animation=ok`). No PIE screenshot visual check — human confirms look in
editor afterward.

## Weapon recoil ceiling snap (h5)

Live PIE (4 Sept 2026): firing any gun once snapped the camera straight to the
ceiling. Not the sustained-auto accumulation case already fixed in comments —
`KickDegrees` is only 0.6°. Root cause: `ApplyWeaponRecoil` used raw
`FMath::Clamp(Pitch - Kick, -89, 89)` while `GetControlRotation().Pitch` can be a
wrapped equivalent outside that range (e.g. 350 ≈ looking 10° down). Raw Clamp
then snaps to +89 on the first call. Fix mirrors `APlayerCameraManager::LimitViewPitch`:
`FMath::ClampAngle` on kick and recovery. No other fire-path `SetControlRotation`
writers. `bUseControllerRotationPitch = false` is unrelated (camera still reads
control rotation via `bUsePawnControlRotation`).

`verify_weapon_feedback.py` now `ensure_controller_for_verify()`s the shooter,
seeds wrapped pitch 350, fires once, and asserts the normalized pitch delta is
KickDegrees-sized (fails on the old Clamp; passes after ClampAngle). Report also
records raw before/after pitch.

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=tools\ue5\run_weapon_feedback.py -unattended -nopause -nosplash
```

**4 Sept 2026 — code + verify script landed in this worktree; headless rebuild/
verify not re-run here** (agent Shell blocked by Cursor `rtk hook claude` / bash
conflict). Report: `%TEMP%/weapon_feedback_report.json`. Human confirms feel in
PIE afterward.

## Play entirely dark vs bright editor viewport (h19) — 5 Sept 2026

User report: editor viewport looks fine (even blown-out bright); pressing Play /
Standalone goes completely dark.

**Checked first — h11 Static compiled-world shell:** `EnableDynamicLighting` still
keeps/restores the "compiled world" / `Model\d+_\d+` shell as Static for
`CTF_USE_COMPLEX_AS_SIMPLE` (Chaos). That shell has **no** UE baked lightmaps
(`force_no_precomputed_lighting`; BioShock lightmap atlases are not imported;
`bake_mesh_render_data.py` disables lightmap UV gen). Confirmed risk: Static + no
lightmap can render unlit in game while the editor shows an unbuilt preview. **Not
reverted** — flipping the shell back to Movable would re-break h11 collision. If
walls/floors still look wrong after the exposure fix below, the next step is a
**dual mesh** (Static invisible collision proxy + Movable lit render mesh), not a
mobility revert. `run_collision.py` / `verify_collision.py` must stay 0 errors.

**Actual editor-vs-Play gap (confirmed in code):** `AShockPlayer`'s camera pinned
Manual `AutoExposureBias = 0` at `PostProcessBlendWeight = 1`, which **overrides**
`repair_level_lighting.py`'s unbound PostProcessVolume (`BIOSHOCK_LIGHT_EV`,
default **11**). Editor viewport sees the volume → bright; possessed Play sees EV 0
→ near-black. Lights are present (664 PointLights on Medical + fill sun/sky from
`EnableDynamicLighting`); this was not a missing-light import gap.

**Fix:** camera Manual bias set to **11.0f** to match the repair PPV default. Human
confirms in PIE/Standalone after `rebuild_runtime_fast.ps1`. No headless lighting
assert — render look is the check. Collision path untouched.

## Interactive doors (AShockDoor) — 5 Sept 2026

User report (in-editor): doors aren't functional. Audit confirmed there was no
`AShockDoor` — only script-action request records (`OpenDoor` / `CloseDoor` /
`LockDoor` / `UnlockDoor` / `SetDoorBrokenState` / `DoorKeypadUsed`). Level import
placed door leaf meshes as plain `StaticMeshActor`s with default collision and
zero interactivity (`docs/research/interaction.md`, `door-and-import-materials.md`).

**Source (CONFIRMED_BYTES):** ~50 door classes; state fields `bLocked`,
`bInitiallyOpen`, `OpenAnimationRate`, `DoorPortal`, `Attachments[]`. MedicalDoors
drive a skeletal proxy (`Med_DoorAnim` + `OpenAnimationName`) with static leaves on
sockets. Script layer can lock/open/break by label. Keypad / welded / elevator
variants exist separately.

**What this slice builds (plain doors):** `AShockDoor` — proximity open (APPROXIMATED;
`ShockPlayer` has no Interact bind yet, only UseFirstAid/UseEveHypo; pickups also
use overlap), yaw-swing fallback (APPROXIMATED vs skeletal `OpenAnimationName`),
collision off when mostly open, respects locked/broken. Script actions now
`FindByLabel` + drive the actor; `SetDoorBrokenState` still writes `ShockPlayer`
and also sets `AShockDoor::bBroken`. `import_level._import_door_attachments`
spawns `AShockDoor` (first attachment mesh when present) and leaves extra leaves
as non-blocking visual props.

**Follow-ups (not this slice):** keypad / Interact prompt (`DoorSwitch.UseVerbText`),
dual-leaf skeletal open, `DoorPortal` brush reveal, welded/elevator specials.

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=tools\ue5\run_door.py -unattended -nopause -nosplash
```

**5 Sept 2026 — code + verify landed in this worktree; no live UE session here.**
Report: `%TEMP%/door_report.json`. Human confirms swing speed / proximity range
in the editor afterward.

## Tommy Gun fire mode + grip socket align (h12) — 5 Sept 2026

User report (first in-editor weapon test after movement/collision): Tommy Gun is
single-shot, and the viewmodel sits off to the side.

**Fire mode (confirmed):** `SetupPlayerInputComponent` bound `Fire` as
`IE_Pressed` only → `HandleFireInput` → one `TryFireEquippedWeapon`. No hold path.
`EWeaponFireMode` is hitscan/projectile/melee/shotgun/beam (delivery), not
semi vs full-auto. Fix: `UShockWeaponDef::bAutomatic` / `AShockWeapon::bAutomatic`
(data-driven). TommyGun + ChemicalThrower `true`; Pistol/Shotgun/Crossbow/GL/Wrench
stay `false`. Player tracks `bFireInputHeld` on press/release; `TickHeldFire`
re-calls `TryFireEquippedWeapon` while held when automatic (rate-gated by existing
`CanFireNow`). Beam release still `StopBeam`.

**Socket (confirmed, not a fudge offset):** h8 still resolves socket name `TommyGun`
for TommyGun — same socket as the old hardcoded candidate list. RestoreSockets only
stores name+bone (identity relative). `context.md`: weapon root bone (`R_grip`)
*is* the hands' socket. `SnapToTarget` puts the mesh *component origin* on the
socket; when those differ after FBX import the gun floats beside the grip.
`AlignEquippedWeaponRootToGripSocket` cancels the root bone's component-space
transform so root lands on the socket — correction read from the mesh, not a
hand-tuned XYZ. `ViewmodelOffset` framing is unchanged (still look-and-tune).

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=tools\ue5\run_weapon_ammo.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=tools\ue5\run_viewmodel_anims.py -unattended -nopause -nosplash
```

`verify_weapon_ammo.py`: hold Fire via `DriveFireInputForVerify` /
`AdvanceHeldFireForVerify` — TommyGun >1 shot across >1 fire interval; Pistol
exactly 1. `verify_viewmodel_anims.py`: grip-to-root distance ≤5 uu; TommyGun
bounds lateral in camera space ≤80 uu. Weapon-track logs
`BIOSHOCK_WEAPON_TRACK_ALIGN` (parsed into the report).

**5 Sept 2026 — code + verify extensions landed in this worktree; no live UE
session here** (isolated agent worktree). Rebuild + headless verifies above are
the evidence path; socket framing feel still needs a human look in PIE afterward.

## First-person viewmodel anims (h8) — grip socket + per-weapon fidget/fire/reload

Root cause (confirmed): `EquipWeapon` picked grip sockets from a hardcoded
`TommyGun` / `R_Grip` / `R_grip` candidate list, so only Tommy Gun ever matched;
every other weapon got `NAME_None` and no socket correction. Separately,
`EnsureViewHands` always played `FidgetTommygun` once and never switched by
weapon — no fire/reload/equip trigger existed.

Fix: resolve the grip socket from `AShockWeapon::GetWeaponDefName()` against the
hands skeleton (log once and skip correction when missing — no substitute socket).
ViewHands animation mirrors `ABaseShockAI::TickAnimationDriver`: cache per-weapon
sequences, play equip → fidget (loop), fire/reload as one-shots that return to
fidget via `GetPlayLength()`, only call `PlayAnimation` when state changes.

| Def | Equip | Fidget | Fire | Reload |
|---|---|---|---|---|
| TommyGun | `EquipTommygun` | `FidgetTommygun` | `FireTommyGun` | `ReloadTommyGun` |
| Pistol | `EquipPistol` | `FidgetPistol` | `FireSinglePistol` | `FastReloadPistol` |
| Crossbow | `EquipCrossbow` | `FidgetCrossbow` | `FireCrossbow` | `ReloadCrossbow` |
| Shotgun | `EquipShotgun` | `FidgetShotgun` | `FireShotgun` | `ReloadShotgun_Start` |
| ChemicalThrower | `EquipChem` | `FidgetChem` | `FireStartChem` | `ReloadChem` |
| GrenadeLauncher | `EquipLauncher` | `FidgetLauncher` | `FireLauncher` | `ReloadLauncher` |
| Wrench | `EquipWrench` | `FidgetWrench` | `Swing_A_Wrench` | *(none — melee)* |

### 5 Sept 2026 — the other four weapons' clips landed (h8 left them unimported)

The hand-anim clips for Shotgun / ChemicalThrower / Wrench / GrenadeLauncher exist
in-game on `UAPW_NEWPlayerHands` (owners of the same name, 8-12 clips each) — h8
only ever imported Pistol / TommyGun / Crossbow. `tools/ue5/import_fp_hand_anims.py`
(+ `run_*`) imports them from `export-fbx 0-Lighthouse UAPW_NEWPlayerHands <out> <owner>`
per owner (NOT `export-firstperson` — it uses one string for both owner-filter and
socket name, and Chem / Launcher / Shotgun don't match their owner name). 33 → 72
anims on disk. `TryGetViewHandsAnimNames` wired for all four; multi-part fire/reload
(`FireStartChem`, `ReloadShotgun_Start/_LOOP/_End`) collapse to the trigger clip for
the single-clip struct — shell-by-shell reload is a later refinement.

Shotgun has **no named grip socket** on the hands mesh (every per-weapon socket sits
on the `R_grip` bone and the FidgetShotgun clip already poses the hands around the
gun). `ResolveGripSocketForWeapon` now falls back to the `R_grip` bone for any weapon
without a socket — `alignRoot ... socketToRoot=0.00` for Shotgun after the fix.

**Verified live UE5.7, 5 Sept 2026 — `viewmodel_anims=ok`.** All seven weapons
resolve equip/fidget/fire/(reload) clips; `run_verify_wrench` Success.

Zoomed-in variants (`ZoomedInFidget*`, `ZoomingIn*`, …) are **not** wired — this
codebase has no ADS / zoom input signal yet; inventing one is out of scope.
Unequip clips are also skipped (no clean pre-switch wait without delaying equip).

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=tools\ue5\run_viewmodel_anims.py -unattended -nopause -nosplash
```

`run_viewmodel_anims.py` drives `verify_viewmodel_anims.py`: `unreal.load_asset` on
each hardcoded path, then equip TommyGun/Pistol/Crossbow and assert socket name ==
def name, fidget is that weapon's (not always TommyGun), fire clip plays, then
return to fidget. Shotgun/ChemicalThrower equip without crash (no anim assert).

**Verified live UE5.7, 4 Sept 2026 — `viewmodel_anims=ok`, 0 failures.** TommyGun/
Pistol/Crossbow each resolved their own grip socket, own fidget, own fire clip,
and returned to their own fidget after fire and after reload — not a stale
TommyGun match. Shotgun/ChemicalThrower equip cleanly with no animation (as
designed). Report: `%TEMP%/viewmodel_anims_report.json`. Socket framing feel and
fire timing still worth a human look in PIE, but the state machine itself is
confirmed correct per-weapon.

## Weapon-mesh reload anims (h13) — Mesh PlayAnimation, not screen-pin

User report 5 Sept 2026: "the gun doesn't respond to the reload animation" means
the **weapon's own** moving parts (barrel hinge, bolt, …), not input lockout and
not "does the actor follow the hand socket."

h10's `-bioshockverifyweapontrack` already showed Pistol world-transform follows
the grip during `Reload()` (socket-follow live; position mostly screen-pinned by
`FrameViewmodel`). That does **not** prove the weapon skeleton plays a reload
clip — and it did not: `AShockWeapon::Reload` only called
`NotifyViewHandsWeaponReloadStarted()` (ViewHands). Nothing called
`Mesh->PlayAnimation`.

Shipped assets (on disk under `/Game/BioShockWeapons/WP_<Def>/Animations/`):

| Def | Weapon reload leaf | Hands counterpart (h8) |
|---|---|---|
| Pistol | `FastReload` | `FastReloadPistol` |
| TommyGun | `Reload` | `ReloadTommyGun` |
| Crossbow | `Reload` | `ReloadCrossbow` |
| Shotgun | `Reload` | *(no hands clip yet)* |
| ChemicalThrower | `Reload` | *(no hands clip yet)* |

Fix: `Reload()` loads that leaf and `PlayAnimation`s it on `AShockWeapon::Mesh`
(one-shot), then still notifies ViewHands. Verify asserts the weapon mesh's own
active AnimSequence name — not world transform.

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=tools\ue5\run_weapon_mesh_anims.py -unattended -nopause -nosplash
```

**Verified live UE5.7, 5 Sept 2026 — `weapon_mesh_anims=ok`, 0 failures.** All five
skeletal starters load their reload leaf and install it on `Mesh` after `Reload()`
(`Pistol=FastReload`, TommyGun/Crossbow/Shotgun/ChemicalThrower=`Reload`). Before
reload the mesh anim was `None` (no prior PlayAnimation) — confirms this was a
genuine gap (b), not h10 screen-pinning. Report: `%TEMP%/weapon_mesh_anims_report.json`.
Human should still confirm the barrel/magazine read in PIE; fire/equip weapon-mesh
clips are not wired here (reload only).

## Starter weapon viewmodel meshes (h3 / h14)

`UShockWeaponDef::MeshAssetPath` + `AShockWeapon::ApplyDef` assign the first-person
skeletal mesh for every starter gun; `AShockGameMode::EquipStarterWeapon` no longer
hardcodes Tommy Gun only. Paths follow the TommyGun convention under
`/Game/BioShockWeapons/WP_<Name>/WP_<Name>`.

| Def | Mesh asset | Export |
|---|---|---|
| TommyGun | `WP_TommyGun` (already on disk) | `export-firstperson TommyGun … --fbx` |
| Pistol | `WP_Pistol` | `export-firstperson Pistol … --fbx --group=WP_Pistol` |
| Shotgun | `WP_Shotgun` | `export-fbx <ShockGame.U> UAPW_WP_Shotgun … --mesh WP_ShotgunMesh` (no hand socket) |
| GrenadeLauncher | `WP_GrenadeLauncher` | `export-firstperson Launcher … --fbx --group=WP_GrenadeLauncher` (hands socket `Launcher`) |
| ChemicalThrower | `WP_ChemicalThrower` | `export-firstperson Chem … --fbx --group=WP_ChemicalThrower` |
| Crossbow | `WP_Crossbow` | `export-firstperson Crossbow … --fbx --group=WP_Crossbow` |
| Wrench | `WP_Wrench` (**StaticMesh**) | `export-staticmesh ShockGame WP_WrenchMesh …` → `import_wrench_mesh.py` |

Export scratch under `%TEMP%\bioshock-h14-weapons\` (not the worktree), then:

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
$env:BIOSHOCK_WEAPON_EXPORT_ROOT = "$env:TEMP\bioshock-h14-weapons"
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\run_import_weapon_meshes.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\run_weapon_meshes.py -unattended -nopause -nosplash
```

`run_weapon_meshes.py` drives `verify_weapon_meshes.py`: `GiveWeaponByDef` for each
starter, asserts `Mesh->GetSkeletalMeshAsset()` matches the expected path for the six
skeletal guns (incl. GrenadeLauncher slot 4), and asserts Wrench resolves a
**StaticMesh** on `AShockWeapon::StaticMesh` (`wrench=static_mesh_ok`). Grip-socket
alignment is look-and-tune in the editor afterward — not asserted here.
Projectile/explosive feel for the Grenade Launcher is already covered by
`verify_weapon_def.py`; this task only landed the viewmodel mesh.

**5 Sept 2026 (h14) — GrenadeLauncher mesh path wired; Wrench was still StaticMesh-blocked.**
Confirmed against `ShockGame.U` package context (`WP_GrenadeLauncher`: SkeletalMesh
`WP_GrenadeLauncherMesh` + `UAPW_WP_GrenadeLauncher`; `WP_Wrench`: StaticMesh×1 only).
Headless evidence: `weapon_import=ok` (`%TEMP%/h14_weapon_mesh_import_report.json`),
`weapon_meshes=ok` 0 failures (`%TEMP%/h14_weapon_meshes_report.json`) — GrenadeLauncher
mesh path `/Game/BioShockWeapons/WP_GrenadeLauncher/WP_GrenadeLauncher.WP_GrenadeLauncher`
via `GiveWeaponByDef`; Wrench `wrench=static_mesh_blocked` (superseded by h22 below).
Projectile/explosive fire for the GL was already covered by `verify_weapon_def.py`
(not reinvented here).

**5 Sept 2026 (h22) — Wrench StaticMesh viewmodel.**
`WP_WrenchMesh` exports via `export-staticmesh ShockGame WP_WrenchMesh` (3153 verts /
3696 tris, confirmed decode). Import: `import_wrench_mesh.py` (Blender-normalize +
`FBXIT_STATIC_MESH`) → `/Game/BioShockWeapons/WP_Wrench/WP_Wrench`. Runtime:
`AShockWeapon::StaticMesh` subobject; `ApplyDef` loads `UStaticMesh` when
`MeshAssetPath` is not skeletal; `UShockWeaponDef` Wrench sets
`MeshAssetPath` to that content path. Equip attaches the weapon actor to ViewHands
socket `Wrench` (no alias — socket name matches the def). Headless:
`wrench_import=ok` (`%TEMP%/wrench_mesh_import_report.json`), `wrench_verify=ok`
(`%TEMP%/wrench_verify_report.json`) — StaticMesh path, skeletal cleared, attach
parent `ViewHands`, socket `Wrench`. **Grip / in-hand look is a human PIE check** —
not asserted. Rebuild: `rebuild_runtime_fast.ps1 -CleanModule` then incremental.

## ChemicalThrower / Crossbow visual defects (h17) — 5 Sept 2026

User reports (in-editor): ChemicalThrower "looks borked"; Crossbow "textures are wrong".
Diagnosed with `probe_weapon_visuals.py` against live `/Game/BioShockWeapons` assets
(report `%TEMP%/weapon_visuals_probe.json`) before changing anything.

**ChemicalThrower — confirmed defect (grip socket alias), not materials/beam.**

| Check | Result |
|---|---|
| Mesh / MI / BaseColor+Normal | OK — `ChemThrow_Diff` / `ChemThrow_Norm`, no engine defaults |
| Sampler Color-vs-Masks (masters under `/Game/BioShockWeapons`) | no issues (that class of bug was Slice-only) |
| Bounds / scale vs Pistol/TommyGun/Shotgun | comparable (radius ~66 uu) |
| Beam VFX | none implemented — `FireAtBeam` applies status only; not a held-viewmodel defect |
| NEWPlayerHands sockets | `Chem=true`, `ChemicalThrower=false` |

Root cause: same alias class as `GrenadeLauncher`→`Launcher`. Def key is
`ChemicalThrower`; export-firstperson socket is `Chem`. Without the alias,
`AttachToComponent(..., NAME_None)` snaps to the hands **component root**,
`FrameViewmodel` never pins, and the gun floats wrong — reads as "borked".

Fix: `ResolveGripSocketForWeapon` maps `ChemicalThrower`→`Chem` when that socket
exists. `verify_viewmodel_anims.py` now asserts that socket after equip.
`verify_weapon_meshes.py` also asserts every skeletal starter's material slots
resolve non-default BaseColor/Normal (audit_level_materials-style).

**Crossbow — no asset-level texture defect found; needs a human description.**

Ruled out: null/default materials, sampler mismatch, missing DIFF/NORM bindings,
wrong mesh path, missing `Crossbow` grip socket, gross scale outlier. Mesh has
`MI_Crossbow_Shader` → `crossbow_diffuse` + `crossbow_NormalMap` (game export has
no specular PNG — same as Content). If it still "looks wrong" in PIE, describe
the failure mode (UV stretch, wrong atlas, checkerboard, flat lighting, …) —
do not guess a second fix.

```powershell
powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\run_weapon_meshes.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript `
    -script=<repo>\tools\ue5\run_viewmodel_anims.py -unattended -nopause -nosplash
```

**Verified live UE5.7, 5 Sept 2026:** `weapon_meshes=ok` 0 failures (incl. Chem/Crossbow
BaseColor+Normal texture asserts) — `%TEMP%/h17_weapon_meshes_report.json`.
`viewmodel_anims=ok` 0 failures — ChemicalThrower `socket=Chem` after equip
(`BIOSHOCK_VIEWMODEL hands=1 socket=Chem weapon=ChemicalThrower`) —
`%TEMP%/h17_viewmodel_anims_report.json`. Crossbow texture appearance still needs a
human PIE description if the report persists.

## Runtime skeleton (Phase 3)

`BioShockRuntime/` is a **runtime** plugin (not editor-only). Copy it into the UE project's
`Plugins/` folder and enable `BioShockRuntime` in the `.uproject`, same deploy as ImportTools.

It is the class tree, not the behaviour: `AShockPawn` / `AShockPlayer` / `ABaseShockAI` /
`AShockWeapon` / `UShockAction` / `AShockGameMode`. `UShockSchemaLibrary.apply_class_defaults`
reads Phase 2.1 schema JSON and applies floats that class actually ships. Standing
`CollisionHeight` is **68**, declared on `VPawn` in `VengeanceShared.U` (not Engine.U
`Pawn`'s 78). The ShockGame schema does not contain `VPawn`, so the verifier injects
that one default from the C# pin (`ClassDefaultsInheritanceTests`) before apply.

```bash
dotnet run --project tools/uelib-bridge -- --schema <out.json> ShockGame.U
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_runtime_skeleton.py -unattended -nopause -nosplash
```

Do not commit the schema JSON (game-derived).

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** `ShockPlayer` spawned; schema apply reported
CollisionRadius, GroundSpeed, JumpZ, BaseEyeHeight, CrouchHeight, Health, MaxHealth.
Read back off the actor: radius **34**, walk **450**, jump **525**, eye **60**, health **200**,
standing capsule half-height **68** — matching `ShockGame.U` plus `VPawn` in `VengeanceShared.U`.
Walk speed is the canary that apply cannot fake (UE Character default 600); half-height is the
other (UE default 88). Engine.U `Pawn`'s CollisionHeight is 78 and is **not** the player value.

## Possess setup on the Medical slice (Phase 0 playable half)

`run_possess.py` loads the saved `/Game/BioShockSlice/1-Medical` umap (does **not** re-import),
sets WorldSettings `DefaultGameMode` to `ShockGameMode`, places a real `PlayerStart` at the
exported MedicalStart (`PlayerStart0`, label MedicalStart), pilots a schema-applied
`AShockPlayer`, then save → scratch → reload.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_possess.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Reloaded DefaultGameMode is
`ShockGameMode`; tagged PlayerStart still at MedicalStart; piloted pawn radius **34**, half-height
**68**, walk **450**. Editor `PlayerController.Possess` access-violates under `-unattended` — not
claimed. Python does not run inside PIE; editor Play still AVs under `-unattended`.

### Game-mode possess verify (automated)

`run_game_possess.py` runs possess prep + playable input, then launches
`/Game/BioShockSlice/1-Medical?game=ShockGameMode` with `-game -bioshockverifypossess`.
`ShockGameMode` picks the tagged `MedicalStart` PlayerStart, snaps the pawn there in `PostLogin`,
logs `BIOSHOCK_POSSESS_OK`, and quits.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_game_possess.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 27 Aug 2026 — `Success - 0 error(s)`.** ShockPlayer at MedicalStart
(XY < 1 uu), `playable=1`. **28 Aug:** also logs `BIOSHOCK_SLICE_OK` (BabyJane mesh on,
hitscan 100→75). Editor viewport Play is still the human check for WASD/look/Fire feel.

### Game-mode movement + weapon-track verifies (4 Sept 2026)

Real `-game` hooks (not editor PIE / not `-run=pythonscript` BeginPlay — those paths AV or
never tick). Same PostLogin pattern as `bioshockverifyencounter`: flag → timer → drive real
seconds → log → `RequestExit`.

| Flag | Driver | What it checks |
|---|---|---|
| `-bioshockverifymovement` | `run_game_movement.py` / `verify_game_movement.py` | After possess, every-frame `DriveMoveForwardForVerify` → `MoveForward` → `AddMovementInput` for 2.5s; logs start/end, displacement, modes, `bMovementDisabled`, controller/CMC/gravity/vel |
| `-bioshockverifyweapontrack` | `run_weapon_track.py` / `verify_weapon_track.py` | Equip Pistol, `Reload()`, sample weapon world transform every 0.1s for `FastReloadPistol` `GetPlayLength()` |

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_game_movement.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_weapon_track.py -unattended -nopause -nosplash
# Or -game alone once Medical is prepped:
#   ... 1-Medical?game=ShockGameMode -game -bioshockverifymovement -abslog=%TEMP%\...
```

**Measured live UE5.7, 4 Sept 2026:**

- **Weapon track — PASS.** `BIOSHOCK_WEAPON_TRACK_OK samples=20 range=17.909 first_last=18.594 anim=FastReloadPistol` (len=1.767, socket=`Pistol`). World rotation swings hard during reload; position is mostly screen-pinned (matches `FrameViewmodel` re-pinning the grip each tick). Live socket-follow works — the earlier “gun doesn’t react” report is not “attachment is dead”; feel/framing may still look static in position.
- **Movement — PASS (re-verified after volume-scale + snap fix).** `BIOSHOCK_MOVEMENT_OK displacement=49.5 mode_start=MOVE_Walking mode_end=MOVE_Walking` with `vel≈(0,20,0)`. Root cause was not CMC itself (forced `TickComponent` in clear air with capsule collision off integrated gravity + input immediately). Two stacked blockers: (1) `import_level._import_region_volumes` called `set_actor_scale3d(half_extent)` on brush volumes — UE’s default volume brush half-extent is 100uu, so a room that should be scale≈1.12 became scale=112 / extent≈11200, solid-filling Medical with BlockingVolumes that zeroed CMC velocity every blocked step; repaired on disk by `repair_volume_scale.py` (88 volumes) and fixed at source via `_set_volume_half_extent`. (2) Verify drive timer used `SetTimer(..., 0.0f, true)` which UE5’s `FTimerManager` ignores (`InRate > 0` required) — now 0.016s. Snap also raises out of residual capsule penetration before arming Walking. `run_collision.py` still **0 errors** after the volume repair. Logs: `%TEMP%/game_movement_fixed5.log`, `%TEMP%/repair_volume_scale.json`.

## Script runner (Phase 4 execution head)

`UShockScriptRunner` is a first-slice stand-in for Scripting.U `Script` action lists: authored
Actions → run queue; `TickExecution(WorldTime)` advances until blocked on `ActionWait` or finished.
Handles Wait, If (expand branch), VariableAssign/Inc/Dec, ExitScript, ScriptNote.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_script_runner.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 27 Aug 2026 — `Success - 0 error(s)`.** Linear Wait + If true-branch
verified. Blocking/NonBlocking ExecuteScript: `run_script_blocking.py`, same day, also
`Success - 0 error(s)` (`UShockScriptRegistry` label lookup). ActionLoop/ExitLoop:
`run_script_loop.py`, same day, `Success - 0 error(s)`. Message TriggeredBy:
`run_script_message.py`, same day, `Success - 0 error(s)`. MessageQueue while busy:
`run_script_queue.py`, same day, `Success - 0 error(s)`. Level-placed `AShockScript`:
`run_script_actor.py`, same day, `Success - 0 error(s)`. SendTriggerMessage dispatch:
`run_script_trigger.py`, same day, `Success - 0 error(s)`. Script JSON import:
`run_import_scripts.py`, same day, `Success - 0 error(s)` (TriggeredBy + schema defaults +
`export-script-actions` instance scalars for Wait/Assign/Note/Trigger/Log plus
PlayEffect/SetProperty/ExecuteScript/Hide/Destroy/Attack/PlayAnim/SpawnAI). **Nested
If/Loop import** (formatVersion 2 `childArrays`) — same day, `Success - 0 error(s)`.

## Playable Fire input

`run_playable_input.py` ensures the throwaway project's `Config/DefaultInput.ini` has
`ActionName="Fire"` → LeftMouseButton and legacy `Engine.PlayerInput` /
`Engine.InputComponent` (Enhanced Input ignores ActionMappings). Verifies
`EnablePlayableInput` + `TryFireEquippedWeapon`.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_playable_input.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 27 Aug 2026 — `Success - 0 error(s)`.** PIE possess still a human Play
check.

## ActionWait (Phase 4 head)

`ActionWait` lives in **Scripting.U**, not ShockGame/ShockAI. One float `Seconds` (default 1).
Decompiled `latentExecute`: wake at `Level.TimeSeconds + Seconds`. `UShockActionWait` holds that
parameter and the wake check; it is not a script VM.

```bash
dotnet run --project tools/uelib-bridge -- --schema <out>/Scripting.schema.json Scripting.U
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_wait.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Schema apply sets Seconds **1**;
`PrepareWait(10)` → wake **11**; `IsReady` false before / true at-or-after. No latent Sleep on a
script graph yet.

## ActionSetProperty (Phase 4 census #2)

Native Scripting.U action: find actors by label (`Object`), `SetPropertyText(Property, NewValue)`.
`UShockActionSetProperty` holds the three params; `ApplyToActor` only implements **Label**
(editor `SetActorLabel`). Other properties refused rather than guessed. `bHidden` special-case
and full `SetPropertyText` are still open.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_set_property.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Label write round-trips; unknown
property names return false. **bHidden → SetActorHiddenInGame — done 27 Aug 2026**
(`run_action_set_property.py`, `Success - 0 error(s)`).

## ActionIf (Phase 4 census #3)

Native Scripting.U if: OR over `testsOr` (`ActionBool`), then `trueActions` vs `elseActions`.
`UShockActionIf` chooses the branch; `UShockTruthStatement` evaluates `Value` via `FCString::ToBool`.
Nested latent Execute on a script graph is still open for many actions, but
`ActionLoop` / `ActionFor` (counter ≤ End) now expand on the runner.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_if.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** empty→else; True→true;
False→else; False OR True→true.

## ActionPlayEffect (Phase 4 census #4)

`TriggerEffectEvent(EffectEvent,,,,,,,, EffectTag)` on actors labeled `ActorLabel`. Default
EffectEvent is **ScriptTrigger**. `UShockActionPlayEffect` holds params and records the intended
fire; the effect configurator / FX spawn is not ported.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_play_effect.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Schema EffectEvent ScriptTrigger;
FireOnActor records event+tag.

## ActionNonBlockingExecuteScript (Phase 4 census #5)

UnrealScript `ActionExecuteScript` looks up a `Script` by `targetScript` label and starts it;
`ActionNonBlockingExecuteScript` is that with `block=false`. This slice records
`RequestExecute` only — no Script VM, no `findByLabel`.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_nonblocking_script.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Default non-blocking; empty
target refused; configured target recorded.

## ActionSetLightProperties (Phase 4 census #6)

Finds lights by `Object` label and writes nested `*Property` fields when `ChangeProperty` is true.
This slice applies **brightness** (intensity = BioShock `LightBrightness` scale) and **colour** to
the first `ULightComponent` on a target actor. LightType / period / phase / shadow flags are not
ported yet. Decompiled `LightBrightnessProperty` has no value var line — float is inferred from
Engine.Light + level import.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_set_light.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** intensity 2.5; colour channels
match Configure (use `unreal.Color(r=,g=,b=,a=)`).

## ActionVariableAssignIfNotExist (Phase 4 census #7)

`lhs` / `rhs` create-only into `UShockVariableScope` (string map). Typed Variable* classes,
dotted names, and `bestVariableClass` are not ported.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_var_assign_if.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Creates once; second write
refused; value stays `true`.

## ActionVariableAssign (Phase 4 census #8)

Same lhs/rhs scope write as AssignIfNotExist, but overwrites. C++ class is
`ShockActionVariableAssignOverwrite` (`ActionClassName` still `ActionVariableAssign`).

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_var_assign.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Value becomes `2` after overwrite.

## ActionHideOrShowActor (Phase 4 census #9)

`ActorLabel` + `HideActor` (default true). `ApplyToActor` calls `SetActorHiddenInGame` and, in
editor, temporary editor hide. Label `allActorLabel` foreach is not wired.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_hide_show.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Schema HideActor=true; hide then
show toggles actor hidden state.

## ActionSpawnAI (Phase 4 census #10)

ShockAI.U native: `SpawningManager.SpawnScriptedAI(...)`. This slice holds type / location /
spawned label / radii / force flags and records `RequestSpawn`. Schema default
`bCorpseCanBeRemoved=true`. No real AI spawn yet. Schema file:
`BioShockUE5/Exports/slice/ShockAI.schema.json` (not committed).

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_spawn_ai.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Empty type refused; configured
type+location recorded.

## ActionStopEffect (Phase 4 census #11)

Twin of PlayEffect: `UnTriggerEffectEvent(EffectEvent, EffectTag)`. Default EffectEvent
**ScriptTrigger**. `StopOnActor` records the stop; no FX tear-down.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_stop_effect.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Schema EffectEvent ScriptTrigger;
StopOnActor records event+tag.

## ActionPlayAnimation (Phase 4 census #12)

ShockGame.U: play DT_Mesh animation via `PlayAnimationOnChannel`. Schema defaults TargetLabel
UNSPECIFIED, AnimationRate **1**, bOnlyPlayOnAlivePawns **true**. This slice records
`PlayOnActor`; no skeletal/mesh playback yet. Schema:
`BioShockUE5/Exports/slice/ShockGame.schema.json` (not committed).

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_play_anim.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** Rate=1; alive-only; Idle recorded.

## ActionScriptNote (Phase 4 census #13)

Editor note string; runtime execute does nothing. `UShockActionScriptNote` stores `Note`.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_script_note.py -unattended -nopause -nosplash
```

## ActionDestroyActor (Phase 4 census #14)

`DestroyTarget` → `AActor::Destroy()`. Label foreach and pawn NotifyKilled are not wired.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_destroy.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.**

## ActionAttackTarget (Phase 4 census #15)

ShockAI.U: AILabel / TargetLabel / bAttackOnSight. `ApplyInWorld` finds the first alive
`ShockPawn` with TargetLabel, then every alive `BaseShockAI` with AILabel (editor label or
`ScriptLabel`) and calls `ScriptedAttackTarget` or `AddTargetToAttackOnSight`. No sight cone,
pathing, or weapons. `ApplyImmediateDamage` remains a playable-slice helper and is not what
`execute()` does.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_script_spawn_attack.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 28 Aug 2026 — `Success - 0 error(s)`.** `run_script_spawn_attack.py`:
SpawnedThug's `ScriptedAttackTarget` is Victim, on-sight label recorded, victim health unchanged
(this action orders an attack; it does not deal damage).

## ActionGiveItemsToPlayer (Phase 4 census #16)

ShockGame.U via `ActionShockInventory`: ItemClass + StackSize (default **1**). `ApplyInWorld`
calls `ShockPlayer.AddStackToInventory` on the possessed pawn, or the first placed
`ShockPlayer` when headless. `ActionRemoveItemsFromPlayer` subtracts from the same map.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_script_player_ai_control.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 28 Aug 2026 — `Success - 0 error(s)`.** Give 3 / remove 1 → `ammo_stack` 2.
Same launch also covers crouch, disable-move, concept Hack off, AI state 4, can-attack off,
physics disabled (`script_player_ai_control_report.json`).

## ActionChangeCollision (Phase 4 census #17)

`CollisionChangeType`: SetToTrue / SetToFalse / DoNotChange (defaults all DoNotChange). This
slice maps `CollideActors` onto `SetActorEnableCollision`; other UE2 collision flags held.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_change_collision.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.**

## ActionTweakAIVision / ActionTweakAIHearing (Phase 4 census #18–19)

ShockAI.U sense toggles by AILabel. `ApplyInWorld` writes `bVisionOn` / `bHearingOn` /
`bAlwaysSeePlayer` on labeled `BaseShockAI`. Same runner path now also mutes, waits/continues,
sets patrol + movement-goal dest, toggles hit-reaction bytes, and gates `ApplyAuthoredDamage`
when SetPawn/PlayerInvincibility is on. Fade / ChangeSkin / AISpeech still record-only.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_script_ai_tweak.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 28 Aug 2026 — `Success - 0 error(s)`.** Report
`pawn_health` stayed 100 after 40 authored damage on an invincible splicer.

## ActionControlScriptedSequence / ActionWaitForGoal

WaitForGoal completes immediately when the labeled AI already has that `MovementGoalName`
posted (no pathing). Sequence RunNow, input context, region pressure, and facts live on
the local ShockPlayer. ForcePlayerMove snaps to the marker. `stat fps` is Exec'd;
headless commandlet returned false for that command.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_script_movement.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 28 Aug 2026 — `Success - 0 error(s)`.** WaitForGoal satisfied after
PostMovementGoal `MoveToPoint`; player snapped to MoveMarker X=300.

## Quests / timers / HUD / alarms / spawn-zone / spotlight / mesh

`ApplyInWorld` writes quest state, timer seconds, HUD strings, alarm flags, spawn-zone
aggressor, spotlight target/on, and a `ShockMesh_<name>` actor tag (no real mesh swap,
no save file, no pathing, no Flash HUD). WaitForQuestLogToFinish completes immediately
once the class name is stored.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_script_world_state.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 28 Aug 2026 — `Success - 0 error(s)`.** FindKey state 2 /
objectives 1 / OtherQuest fail 3; ammo stack 2; spawn aggressor Enable; timer
stopped `MyTimerScript`; ImpulseBox tagged `ShockMesh_SomeMesh`; alarm off after
start+stop, last target Player; HUD not playing; SwitchMat index 2.

## Phase 4 census batches (through batch3)

Later census head landed in batches to cut editor launches: BlockingExecuteScript through
UnlockDoor, then MuteAI / SetTipPriority / PostMovementGoal (`run_action_batch2.py`), then
CinematicFadeView / DisableOrEnableConcept / ControlScriptedSequence / DealDamage
(`run_action_batch3.py`), then WaitForGoal / ChangeSkinAtIndex / OpenDoor / AISpeech
(`run_action_batch4.py`), then AssertFact / Loop / TeleportPawnToLocation /
SetOrUnsetInputContext (`run_action_batch5.py`), then ManipulateSpawnZoneRepopulation /
InitiateQuest / SetMovableSpotlightTarget / ChangePressure (`run_action_batch6.py`),
then WaitForQuestLogToFinish / SetMovableSpotlightState / CloseDoor /
ToggleAIReactions (`run_action_batch7.py`), then SendTriggerMessage /
DisplayOnScreenDebugMessage / SetPlayerInvincibility / RunConsoleCommand
(`run_action_batch8.py`), then SetAIPatrol / ChangePawnPhysics /
SetPawnInvincibility / SetAINormalLODOverrideTime (`run_action_batch9.py`), then
SpawnReactiveActor / ActivateResurrectionStation / LockDoor / ShowTrainingMessage
(`run_action_batch10.py`), then CompleteQuest / RemoveGoal / ToggleAIAttacking /
SetActorLabel (`run_action_batch11.py`), then FadeVolumeOverride / InitiateDamage /
TriggerHavokForceActor / ChangeQuestArrowActor (`run_action_batch12.py`), then
EnableOrDisableLevelSaving / RetractFact / SetAIVulnerability / VariableDecrement
(`run_action_batch13.py`), then SetMaterialSwitchIndex /
ToggleAIAttachmentVisibility / PlayScriptedHandAnimation /
CompleteQuestObjective (`run_action_batch14.py`), then SetHUDDisplayState /
AssassinTeleport / Start+StopScriptedHandAnimationSequence / actionSetQuestHint
(`run_action_batch15.py`), then SpawnTurret / SpawnSecurityBot /
ToggleAIWeaponVisibility / UnlockBathysphereDestination (`run_action_batch16.py`),
then StartAIHeadTracking / SetCollisionAvoidance / RemoveItemsFromPlayer /
EnableOrDisableLevelSwitching (`run_action_batch17.py`), then
DisablePlayerMovement / StopSecurityAlarm / FailQuest /
ToggleCeilingCrawlerRangedAttack (`run_action_batch18.py`), then
DisableOrEnableResurrectionStation / RemoveAvailableHoldable /
AwardAchievement / TellAIToSendWeaponFireMessage (`run_action_batch19.py`), then
batches 20–24 (`run_action_batch20.py` … `run_action_batch24.py`) and
`run_playable_standin.py` (HP / hitscan / SpawnAtLocation), then
`run_action_batch25.py` / `run_action_batch26.py` (For / BotSpawn / Mesh /
Continue / AIState / DamageRadius / BathUI / Keypad), then
`run_action_batch27.py` / `run_action_batch28.py` (GathererCrawl / StopHead /
ForceMove / SpawnPickup / ChangeLevel / Resistance / Spotlight / DestroyAIs), then
`run_action_batch29.py` / `run_action_batch30.py` (StopTimer / HudMessages /
PlayMovie / TelekinesisDrop / RangedAccuracy / TrainingMessages / HackTurret /
ControlPlant), then
`run_action_batch31.py` / `run_action_batch32.py` (EffectsContext / ResetProtector /
DamageVolume / ClearAIDamageStates / CorpseCanBeRemoved / UnEquipAllPlasmids /
StartTimer / IncrementNumRoses), then
`run_action_batch33.py` / `run_action_batch34.py` (FxWait / Grenadier / CritWait /
StopHUD / PlayHUD / ActivateSecurityBot / EndDLCLevel), then
`run_action_batch35.py` / `run_action_batch36.py` (BathMode / Landed / WaterVol /
GathererLabel / CollListen / HavokEnable / Ragdoll / AssassinTp).
All `Success - 0 error(s)`. These are parameter + request-record slices — no script
VM, FX, combat, door mechanics, or Tyrion goal stack. Playable stand-ins are not
PIE possess / TommyGun.

## Validation map

`build_validation_map.py` builds one map holding an instance of every asset class this pipeline
supports, and writes a machine-readable report beside it:

```python
import build_validation_map
build_validation_map.main("/Game/BioShock", r"<out>/validation.json")
```

The point is to make regression visible in one place: if textures stop arriving linear, or lights
lose their colour, or skeletal meshes stop instancing, opening this map shows it. The report's
`missing` field is the one that matters — a class the pipeline claims to support but could not
instance is a failure, and is reported rather than skipped silently.

Supported today: `SkeletalMesh`, `Skeleton`, `AnimSequence`, `Texture2D`, rig `MaterialInstance`,
`PointLight`, `SphereReflectionCapture` (29 Medical probes placed live, 25 Aug 2026).
Explicitly **not** supported, and stated in the report so the map cannot imply otherwise: a UE5
material *expression graph* for level geometry, and `TextureCube` assembly (face order UNKNOWN).

## Decal mesh NoCollision (5 Sept 2026)

Cosmetic overlay meshes (Wall_Leak, blood smears, damdec, ScorchMark, drips) were getting the
OBJ importer's default auto convex hull and blocking the player like solid geometry. There is no
decal-specific collision handling in `import_level.py` / `import_bioshock.py`.

**Do not use `outputBlending in (1, 2)` alone** — that is the codebase's soft-alpha signal for
"blood splats, drips, decals" (`import_bioshock._material_rendering_kind`), but
`Wall_Leak_diff_shader` and `reinforcedglass_diffuse_shader` both carry `outputBlending: 1`.
Thinness alone also fails: offline AABB measurement on the Medical export OBJs
(`Exports/1-Medical/1-Medical/Meshes/*.obj` + instance census from `1-Medical.ue5-level.json`)
showed:

| group | n | thinness min / p50 / p90 / max | notes |
|---|---|---|---|
| known decals | 14 | 0.0 / 0.0 / 0.171 / 0.171 | Wall_Leak_*, bloodsmear, BloodSplat*, damdec_*, ScorchMark, Drips*; zero-depth quads except volumetric Drips* |
| known glass | 6 | 0.0 / 0.013 / 0.019 / 0.019 | Int_WindowGlass, BrokenGlassA, glass_safety, … — same flatness band as decals |
| puddles | 7 | 0.0 / 0.007 / 0.015 / 0.015 | keep collision; excluded by name |
| baseline props | 25 | 0.084 / 0.313 / 0.697 / 0.929 | furniture / doors / pillars |

Reuse pattern (decal, not architecture): `Wall_Leak_1024` = 78 instances / 27 unique rotations;
`Wall_Leak_512` = 42 / 17; `BloodSplat3` = 40 / 19. Glass panes share fewer placements
(`Int_WindowGlass_128x256` = 21 / 5).

**Shipped rule** (mirrors `fix_walkable_prop_collision.py`: keywords + size/thinness filter +
exclude list):

- keywords (substring, case-insensitive): `wall_leak|bloodsmear|blood.?splat|bloodsplat|damdec|scorch|drip|decal|smear|splat|footprint`
- excludes: `glass|window|puddle|water`
- max thinness (local mesh AABB min/max extent): **0.20** (catches all 14 Medical decals including DripsSparse at 0.171; glass/puddles never reach the keyword pass once excluded)

Dry-run on `/Game/BioShockSlice/1-Medical` matched exactly those 14 meshes (273 actor instances),
excluded 3 drip+puddle names, skipped 0 as too thick. Apply sets BodySetup
`default_instance` + component to `NoCollision` and clears simple agg geom.

```bash
# dry-run first — review %TEMP%/fix_decal_collision.json
BIOSHOCK_DECAL_DRY=1 UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\fix_decal_collision.py -unattended -nopause -nosplash
BIOSHOCK_DECAL_DRY=0 UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\fix_decal_collision.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_collision.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_decal_collision.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 5 Sept 2026 — both `Success - 0 error(s)`.** `run_collision.py` failures=`[]`.
`run_decal_collision.py`: all 14 decal meshes `NO_COLLISION` on component + mesh BodySetup;
`Int_WindowGlass_128x256` / `glass_safety` / compiled-world `Model1_20761` still
`QUERY_AND_PHYSICS`. Close the live editor before apply — Error 32 file locks otherwise leave
meshes unsaved.

## Compiled-world collision — all 15 BioShockLevel maps (5 Sept 2026)

`fix_compiled_world_collision.py` had only ever been run on `BioShockSlice/1-Medical` and
`BioShockLevel/1-Medical`. The other 13 `/Game/BioShockLevel/*` maps still had their
compiled-world shell (`Model<n>_<idx>`) on `CTF_USE_DEFAULT` with **1 auto convex hull** and
non-Static mobility — the original "solid blob, player stuck on the outside / falls through"
bug, unfixed since those maps were first imported. Surfaced as "collision is gone again" when
play-testing past Medical (Lighthouse / Welcome / etc.).

Fix: ran `fix_compiled_world_collision.py` with `BIOSHOCK_COLLISION_MAPS` set to all 15 maps
(`0-Lighthouse,1-Medical,1-Welcome,2-Fisheries,2-SubBay,3-Arcadia,3-Market,4-Recreation,`
`5-Hephaestus,5-Ryan,6-Resi,6-Slums,7-BossFight,7-Gauntlet,7-Science`). All 15 shells now
`CTF_USE_COMPLEX_AS_SIMPLE`, 0 convex/box, mobility restored to Static (every one reported
`restoredStatic=True`). `run_collision.py` re-verify: structural check passes on all 15; the
only residual failure is "no PlayerStart" on the 14 non-Medical maps (they carry raw geometry
only — player spawns are a separate gap, not a collision problem).

MSYS path-mangling note: pass the `.exe` / `.uproject` / `-script=` as Windows-style paths
(backslashes) **and** set `MSYS_NO_PATHCONV=1`, otherwise a lone `/Game/...` env value gets
rewritten to `C:/Program Files/Git/Game/...` and the map "could not load".

## Headless gotchas

Both documented the hard way, immediately below.

- **Interchange asserts under `-unattended`** for FBX, PNG, *and* OBJ once the OBJ writer emits
  UV/group data (`CurrentApplication.IsValid()`, via Slate/ContentBrowser) — a single-section,
  UV-less OBJ imported cleanly for a long time before this started, so it is easy to mistake for a
  new bug in the OBJ content rather than the same known headless gap on a translator that wasn't
  hit before. Disable it at runtime rather than editing the project config:
  `unreal.SystemLibrary.execute_console_command(None, "Interchange.FeatureFlags.Import.PNG 0")` and
  the same for `.Texture`, `.FBX` and `.OBJ`. Each translator registers its own CVar
  (`InterchangeOBJTranslator.cpp` for the last one) — grep the engine source for the exact name
  rather than guessing it for a type not listed here yet.
- **Neither `print()` nor `unreal.log()` reliably reaches the captured log** under
  `-run=pythonscript ... -log`. A script can report "executed successfully" having produced no
  visible output at all. **Write results to a file** and read that.

