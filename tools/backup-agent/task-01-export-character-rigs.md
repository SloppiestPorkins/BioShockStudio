Goal: when a level is exported, also export the FBX rig (mesh + skeleton + animations) for every
distinct character group its placed SkeletalMesh instances reference, so a later import step can
give those characters real animated meshes in UE5 instead of bind-pose-only static geometry.

Context you need (established this session, don't re-derive it):

- `LevelSceneExporter.ToDocument` (in `src/BioShockStudio.Core/Export/LevelSceneExporter.cs`) now
  resolves a `Group` field on each `SkeletalMesh`-kind `LevelAssetDocument`, via the existing
  `BioShockStudio.Core.Assets.AssetContextResolver.TopLevelGroup(package, export)` -- read that
  method and its call site (`AssetGroup` helper in the same file) to see exactly how it works.
- Each map package embeds its own copy of every character it uses (confirmed project convention,
  see `docs/HANDOFF.md` "Every map embeds its own copy of what it uses"), so the level's own
  already-open package should normally already contain the character's mesh, skeleton and
  animations -- you should not need to search other packages.
- The CLI already has a generic rig exporter: `export-fbx <package> <object> <output-dir> [owner]
  [--mesh <name>]` in `src/BioShockStudio.Cli/Program.cs` (`ExportFbx` function). Read it, and read
  `ExportFirstPerson` alongside it for a second example of how it's driven. `owner` is used when a
  rig hosts several mesh variants sharing one animation package (`--mesh` picks which mesh); a
  single-mesh character may not need it -- read `ResolveMesh`/`LoadAnimationPackage` to find out
  which case applies here, don't assume.

Task:

1. Add a new CLI command (or extend `export-level`, whichever reads more naturally once you've read
   the existing command dispatch in `Program.cs` -- follow its existing pattern) that, after writing
   a level's manifest, also calls the FBX-export logic once per **distinct** `Group` value found
   among the level's `SkeletalMesh`-kind assets (not once per asset -- a group can have several mesh
   variants and you only want to export its rig once). Write each into its own subdirectory, e.g.
   `<level-output-dir>/Rigs/<group>/`, so `import_bioshock.py`'s existing `ue5_manifest.json`
   convention keeps working unmodified.
2. Write a regression test (follow this project's existing test conventions in
   `tests/BioShockStudio.Tests/` -- `[RequiresGameFact]`, real game data, no synthetic fixtures, this
   project never fabricates test data) that exports a real map with characters (e.g. `1-Medical`,
   already used elsewhere in `LevelSceneTests.cs`) and asserts: every distinct `Group` value among
   its `SkeletalMesh` assets got a `Rigs/<group>/ue5_manifest.json` written, and that manifest's own
   rig actually has a mesh and at least one animation (read the manifest back and check it, don't
   just check the file exists).
3. Build (`dotnet build tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj -c Debug`) and run
   ONLY your new test plus `dotnet test ... --filter Tier=Fast` -- this project's own standing rule
   is never to re-run the whole test suite to confirm a change (`docs/HANDOFF.md` "Current state"
   section explains why). Do not commit -- leave the change in the working tree.

If something in the existing code contradicts what this brief says, trust what you read over this
brief, and leave a clear note (as a code comment or in your final message) about what you found
different and why you made the call you did.
