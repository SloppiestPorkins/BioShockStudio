Goal: a level-placed character (splicer, Big Daddy, etc.) should appear in UE5 as a real animated
`SkeletalMeshActor`, not a bind-pose `StaticMeshActor` -- the current behavior for every SkeletalMesh
instance today.

Only start this once task-01 (export-character-rigs) has actually landed and produces real
`Rigs/<group>/ue5_manifest.json` files next to a level export -- read that task file if it's still
open, and check whether the working tree already has its change; if not, do task-01 first.

Context you need (established this session, don't re-derive it):

- `tools/ue5/import_level.py` currently imports every asset's OBJ (bind-pose geometry, single-
  material or multi-material split by `usemtl` group -- see this session's commits on
  `import_level.py` and `LevelSceneExporter.cs` for how that works) as a `unreal.StaticMesh`,
  regardless of `Kind`. That is what needs to change specifically for `Kind == "SkeletalMesh"`
  assets, which now also carry a `Group` field (see task-01's context and the `AssetGroup`/`Group`
  additions already in `LevelSceneExporter.cs`).
- `tools/ue5/import_bioshock.py`'s `main(export_directory, content_root)` already imports a rig
  export directory (mesh, skeleton, animations, textures, materials) into UE5 and returns
  `{rig_name: SkeletalMesh}`. Read it -- this is the exact function to call for each
  `Rigs/<group>/` directory task-01 produces, from inside `import_level.py`.
- `import_level.py`'s existing `_import_asset_meshes`/`_import_instances` functions (read them,
  they're the ones to extend or add alongside) spawn `unreal.StaticMeshActor`s and set
  `static_mesh_component`. A `SkeletalMeshActor` uses `skeletal_mesh_component` instead and its
  `set_skeletal_mesh` equivalent -- check the exact UE5.7 Python property name before assuming it
  matches the static-mesh one.

Task:

1. Add a function that, before the existing asset-mesh import loop, finds every distinct `Group`
   value among `manifest["assets"]` where `"kind" == "SkeletalMesh"`, and for each one whose
   `Rigs/<group>/ue5_manifest.json` exists next to the level manifest, calls
   `import_bioshock.main(rig_dir, content_root)` (reuse it, don't reimplement it) and keeps the
   returned `{rig_name: SkeletalMesh}` mapping.
2. For each `SkeletalMesh`-kind asset in `manifest["assets"]`, use its `Group` and the mapping from
   step 1 to find the already-imported `SkeletalMesh` object. If the OBJ-based path already handles
   placing the actor at the right transform for other kinds, decide (by reading
   `_import_instances`) whether to extend it to branch on kind, or add a parallel
   `_import_skeletal_instances` -- whichever reads more like this file's existing style once you've
   read it, not a new pattern invented from scratch. Spawn/update a `SkeletalMeshActor` per instance
   (idempotent, same `BioShockKey=` tag convention this file already uses everywhere else) instead of
   the current bind-pose `StaticMeshActor` for these specifically.
3. A `SkeletalMesh`-kind asset whose `Rigs/<group>/` export is missing or failed to import must fall
   back to today's behavior (bind-pose static mesh) rather than losing its representation entirely --
   same "counted, not silently dropped" principle this file already follows for its other fallback
   paths (read `_import_actors`'s comments for the convention).
4. This cannot be verified without a live UE5.7 editor run (per this project's own rule: numeric
   validation has passed on visibly wrong results before, see `docs/HANDOFF.md` §4's landmine list --
   render it, don't just trust the report). If you have a way to launch
   `UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript -script=<driver>.py -unattended
   -nopause -nosplash -log` against a real `BioShockUE5` test project, do so and report the actual
   result (a live driver script from this session's earlier work exists at
   `C:\Users\Jack\Documents\BioShockUE5\run_import_level_medical_verify.py` as a working reference for
   the invocation pattern, the Interchange headless-crash workarounds it needs, and how to read back
   a written JSON result). If you cannot run the editor, say so plainly in your final message rather
   than reporting this as done -- an unverified live-import change is not the same as a working one,
   and this whole project's discipline is not claiming more than what was actually checked.
5. Do not commit -- leave the change in the working tree for review.

If something in the existing code contradicts what this brief says, trust what you read over this
brief, and leave a clear note (as a code comment or in your final message) about what you found
different and why you made the call you did.
