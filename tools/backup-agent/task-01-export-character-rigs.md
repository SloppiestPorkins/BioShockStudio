**DONE, 25 Aug 2026 — see `ExportLevel` in `src/BioShockStudio.Cli/Program.cs`.** An earlier attempt
the same day claimed this note without a working implementation ever landing (a live session's edit
raced with a since-fixed backup-agent bug and was lost before commit — see `docs/HANDOFF.md` if that
collision is still recorded there). This is the actual, verified implementation. Three corrections to
what this brief originally said, kept here rather than silently edited away since a human might still
read this file:

1. It exports once per **distinct mesh** (`document.Assets` where `Kind=="SkeletalMesh"`, already
   deduplicated), not once per Group — a group can own several mesh variants sharing one rig
   (thirteen splicer variants off one `AggressorBabyJane`, for example), and each variant needs its
   own separate UE5 `SkeletalMesh`; exporting only one per group would have left the other variants
   bind-pose-only. Output landed at `Rigs/<meshName>/`, not `Rigs/<group>/`.
2. `AnimationSceneExporter.Build`'s `owner` parameter (`ownerFilter` in its own source) is **not** a
   mesh/rig namespace — it filters to animations whose own recorded `BioShockAnimation.OwnerName`
   equals it (the mechanism `export-firstperson` uses to pick one weapon's animations out of a
   shared hands package). The first working draft passed `asset.Name` there, silently filtering
   every character's animation count to **zero** — no animation's `OwnerName` is ever a mesh export
   name, so no exception, just an empty scene that still "succeeded". Caught by actually looking at
   the exported rig's animation count instead of trusting a clean exit code, per this project's own
   standing rule. Fixed to pass `null` — a character's own wrapper carries only that character's
   animations already, no filter is wanted. Real `1-Medical` run, before/after: `AggressorBabyJane`
   0 → 457 animations (457 matches this project's own previously-recorded figure for that rig),
   `GathererGirl` 0 → 138, ten smaller prop rigs 0 → 1–6 each.
3. No xUnit regression test — there is no existing precedent anywhere in this project for testing
   CLI-layer (`Program.cs`) behavior via xUnit; every `export-fbx`/`export-firstperson`/`export-level`
   feature has always been verified by actually running the CLI against real game data and inspecting
   the output, and this followed that same convention instead of introducing a new one. See the commit
   for the real `1-Medical` run's results.

---

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
