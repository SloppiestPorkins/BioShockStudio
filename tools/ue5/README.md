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

The importer normalizes each FBX through Blender before import, persists the companion Skeleton
assets, restores valid manifest sockets through the plugin, and keeps every source socket in
`BioShockSockets` metadata. The first-person pistol (12 animations) and TommyGun (13 animations)
slices are verified in UE5.7, and `verify_bioshock_import.py` passes against both resulting sets.

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

Actors with no geometry to attach become positioned, tagged `TargetPoint`s counted as
`unsupported`. That count is deliberately
visible rather than folded into "created" — the coverage ledger already separates "placed" from
"decoded" and this keeps the same distinction in the engine.

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

Supported today: `SkeletalMesh`, `Skeleton`, `AnimSequence`, `Texture2D`, `PointLight`.
Explicitly **not** supported, and stated in the report so the map cannot imply otherwise: level
geometry (exported as OBJ, not imported as UE5 meshes), UE5 material graphs (bindings are exported,
no graph is generated), and cubemaps (decoded and probe-located, but not imported as reflection
captures).

## Headless gotchas

Both documented the hard way; see `docs/HANDOFF_UE5_IMPORT.md` for the full record.

- **Interchange asserts under `-unattended`** for FBX *and* PNG (`CurrentApplication.IsValid()`, via
  Slate/ContentBrowser). Disable it at runtime rather than editing the project config:
  `unreal.SystemLibrary.execute_console_command(None, "Interchange.FeatureFlags.Import.PNG 0")` and
  the same for `.Texture` and `.FBX`.
- **Neither `print()` nor `unreal.log()` reliably reaches the captured log** under
  `-run=pythonscript ... -log`. A script can report "executed successfully" having produced no
  visible output at all. **Write results to a file** and read that.

