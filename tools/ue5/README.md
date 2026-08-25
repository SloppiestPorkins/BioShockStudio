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
`PointLight` actors** carrying the manifest's colour and brightness, and **geometry instances
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

**`CubemapProbe` actors become `SphereReflectionCapture`, 25 Aug 2026 — code landed, not yet
looked at in the editor.** Same replace-stale-placeholder pattern as lights. Influence radius stays
the engine default (no shipped radius decoded). The named cubemap is a `BioShockCubemap=` tag, not
a bound TextureCube: UE5 captures rebuild from the scene. Do not call this verified until a live
UE5.7 look confirms the probes sit where Medical's 29 captures should.

Run `validate_level_manifest.py <map>.ue5-level.json` first.

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
`PointLight`.
Explicitly **not** supported, and stated in the report so the map cannot imply otherwise: level
material assignment/graphs and cubemaps (decoded and probe-located, but not imported as reflection
captures).

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

