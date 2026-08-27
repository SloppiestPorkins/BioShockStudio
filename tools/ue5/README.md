# UE5 import bridge

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
(XY < 1 uu), `playable=1`. Editor viewport Play is still the human check for WASD/look/Fire feel.

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

ShockAI.U: AILabel / TargetLabel / bAttackOnSight. `RequestAttack` records the order; no
`ScriptedAttackTarget` / combat yet.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_attack.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.**

## ActionGiveItemsToPlayer (Phase 4 census #16)

ShockGame.U via `ActionShockInventory`: ItemClass + StackSize (default **1**). `RequestGive`
records the grant; no `AddStackToInventory` yet.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_give_items.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.** StackSize=1 from schema; grant
PistolAmmo×12 recorded.

## ActionChangeCollision (Phase 4 census #17)

`CollisionChangeType`: SetToTrue / SetToFalse / DoNotChange (defaults all DoNotChange). This
slice maps `CollideActors` onto `SetActorEnableCollision`; other UE2 collision flags held.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_change_collision.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.**

## ActionTweakAIVision / ActionTweakAIHearing (Phase 4 census #18–19)

ShockAI.U sense toggles by AILabel. `RequestTweak` records on/off; no SetVisionState /
SetHearingState yet.

```bash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_tweak_vision.py -unattended -nopause -nosplash
UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \
    -script=tools\ue5\run_action_tweak_hearing.py -unattended -nopause -nosplash
```

**Measured live UE5.7, 26 Aug 2026 — `Success - 0 error(s)`.**

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

## Headless gotchas

Both documented the hard way; see `docs/HANDOFF_UE5_IMPORT.md` for the full record.

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

