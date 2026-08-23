# UE5 import bridge

1. Copy `BioShockImportTools/` into the UE project's `Plugins/` folder and enable it in the
   `.uproject`. It is an editor-only plugin used to restore socket markers after FBX normalization.
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
`PointLight` actors** carrying the manifest's colour and brightness; everything else becomes a
positioned, tagged `TargetPoint`, counted as `unsupported` because the geometry those actors
reference is exported as OBJ and is not yet imported as UE5 meshes. That count is deliberately
visible rather than folded into "created" — the coverage ledger already separates "placed" from
"decoded" and this keeps the same distinction in the engine.

Run `validate_level_manifest.py <map>.ue5-level.json` first.
