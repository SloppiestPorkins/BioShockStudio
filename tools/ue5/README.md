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
