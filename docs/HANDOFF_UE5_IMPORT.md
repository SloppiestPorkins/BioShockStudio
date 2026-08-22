# Handover — UE5 import pipeline, 18 Aug 2026

> Written for a fresh agent (ChatGPT session working in parallel on the same repo) to pick up the
> UE5-as-runtime import track without re-deriving what's already been established. Read
> `docs/ENGINEERING_RULES.md` and `docs/HANDOFF.md` first for house rules and general project state
> — this file is scoped to one investigation.

> **Superseded, 19 Aug 2026 — the blocker described below is resolved.** The ChatGPT session that
> received this handover took the workaround in §5 (Blender normalization) the rest of the way: it
> shipped `tools/blender/normalize_fbx_for_ue5.py` (does exactly what §5 describes), a
> `BioShockImportTools` UE5 editor plugin (`tools/ue5/BioShockImportTools/`) that restores the
> `SOCKET_*` markers the Blender round-trip drops, and `tools/ue5/verify_bioshock_import.py`. I
> independently re-ran the whole chain against a fresh pistol export in a real UE5.7 editor
> (`export-firstperson Pistol` → `import_bioshock.main` → `verify_bioshock_import.main`) on 19 Aug
> 2026 and it passed clean: both rigs, all 12 animations, `Success - 0 error(s), 7 warning(s)` (the
> warnings are cosmetic — missing smoothing groups, sockets not in the bind pose — matching what §5
> already flagged as non-fatal). **The current source of truth for this track is
> `docs/ROADMAP.md` Gate 2 item 4 and `tools/ue5/README.md`**, not this file. The sections below are
> kept as the investigation record (§4 in particular is still useful evidence if the same class of
> bug resurfaces on a new asset type), but treat anything here about the import *not* working as
> historical, not current.
>
> The `SubDeformer` fix in §6 is a genuine, separate exporter bug — that part still stands as-is; it
> was already merged before ChatGPT's workaround shipped and did not conflict with it.

## 1. Why this track exists

The project's actual end goal, per direct user instruction (18 Aug 2026), is **UE5 as a runtime** —
not just an import test, but porting the extracted BioShock assets to run inside Unreal Engine 5.
The user was explicit this is not a scope pivot: port everything over **faithfully first**, then
modify/improve systems only **after** the port is in place. `ENGINEERING_RULES.md` §60 and
`NEXT_SESSION.md` "Reopened, 18 Aug 2026" both have the standing note.

Scope chosen by the user: an **import pipeline** (offline FBX/scene-JSON/PNG export from this
tool, imported into UE5 via editor Python script), not a live native C++ plugin reading `.bsm`
files at runtime.

A second track — decoding UnrealScript bytecode for game logic — was also opened in the same
conversation ("do both"). That track has not been started yet (see §7).

## 2. Environment specifics

- **UE5.7** is installed at `G:\Games\UE_5.7\` (confirmed working, not a guess).
- A throwaway UE5 test project lives at `C:\Users\Jack\Documents\BioShockUE5\`
  (`BioShockUE5.uproject`, `EngineAssociation: 5.7`). It exists purely to test the import pipeline
  — not part of the git repo, not tracked.
- `C:\Users\Jack\Documents\BioShockUE5\Config\DefaultEngine.ini` sets
  `Interchange.FeatureFlags.Import.FBX=false` under `[ConsoleVariables]`. This works around a
  **documented UE5.7 Interchange regression** (`FInterchangeFbxParser::LoadFbxFile: Cannot load
  the FBX file`) that affects FBX import generally after upgrading to 5.7. With it set, import
  falls back to the legacy (pre-Interchange) FBX importer. **Keep this set** — without it you get a
  different, even less specific error.
- **Blender 5.1** is installed at
  `C:\Program Files\Blender Foundation\Blender 5.1\blender.exe`. It became essential as an
  independent FBX parser for diagnosis (see §4) and is also the basis of the current workaround
  (§5).
- The repo's existing import script is `tools/ue5/import_bioshock.py` — entry point
  `main(export_directory, content_root="/Game/BioShock")`. It was written blind (no UE5 editor
  available at the time) and is now being verified for real for the first time.
- The pistol vertical-slice export (the standard test case) is produced by:
  ```bash
  dotnet run --project src/BioShockStudio.Cli -c Release -- export-firstperson Pistol <out-dir> --fbx
  ```
  This produces `NEWPlayerHands.fbx`, `WP_Pistol.fbx`, `Textures/`, per-animation FBX files, and
  `ue5_manifest.json` (schema documented in `FbxExporter.cs`'s `ManifestFileName` constant and
  consumed by `import_bioshock.py`).
- To run the import headlessly and capture the log:
  ```bash
  "/g/Games/UE_5.7/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" \
    "C:/Users/Jack/Documents/BioShockUE5/BioShockUE5.uproject" \
    -run=pythonscript -script="<path-to-a-.py-that-calls-import_bioshock.main(...)>" \
    -unattended -nopause -nosplash -log
  ```
  Note: `print()` inside the script does **not** reliably show up in this log capture mode — use
  `unreal.log(...)` instead.

## 3. Current blocker

Every FBX file this project's exporter produces fails to import into UE5.7, even with Interchange
disabled:

```
FBXImport: Warning: FBX Scene Loading Failed : 'File is corrupted <name>.fbx'
FBXImport: Warning: Can't detect import type. No mesh is found or animation track.
```

This happens at the raw scene-loading stage — before any `FbxImportUI`/import-type options are
even consulted — and is identical whether triggered via the bare minimal `AssetImportTask`, the
real `import_bioshock.py` script, or a hand-built `FbxFactory`+`AssetImportTask` path meant to
mimic the editor's own drag-and-drop import. GUI vs. Python scripting is not the variable.

## 4. What has been ruled out (verified, not assumed)

Extensive byte-level forensics on the exported FBX (binary Kaydara format) confirmed all of the
following are **correct and spec-compliant**, matching real reference FBX files
(`G:/Games/UE_5.7/Engine/Content/FbxEditorAutomation/{BlenderCube,AnimatedCharacter}.fbx`)
byte-for-byte in structure:

- File header (27-byte magic + version), `FBXHeaderExtension`, `FileId`/`CreationTime`/`Creator`.
- `GlobalSettings/Properties70` (axis convention values differ from the reference, as expected —
  different coordinate handedness — but nothing malformed).
- `Definitions/ObjectType/Count` entries match the **actual** object counts in `Objects` exactly
  (Deformer 7, Geometry 1, Material 1, Model 15, NodeAttribute 14, Pose 1, Texture 3, Video 3).
- `Connections` graph: no dangling or invalid object references.
- `Model` nodes' `Lcl Translation`/`Lcl Rotation`/`Lcl Scaling` properties are present and correct
  (an earlier apparent bug here was a **false alarm** — caused by `grep -A 5 | head` truncating a
  diagnostic dump, not a real defect in `FbxSceneBuilder.cs`'s `WriteNodeTransform`).
- `Geometry/Vertices`, `PolygonVertexIndex` (correct negative end-of-polygon markers, all triangles,
  4865 polygons, no trailing unterminated indices), `LayerElementNormal`, `LayerElementUV`,
  `LayerElementMaterial` — all internally consistent.
- `Deformer`/Skin and Cluster nodes (`Indexes`/`Weights`/`Transform`/`TransformLink`/
  `TransformAssociateModel`) — internally consistent, correct array-length pairing.
- `Pose`/`BindPose` — 9 pose nodes (8 bones + mesh transform), standard.
- Trailing 16-byte "footer extension" magic (`f85a8c6adef5d97eece90ce3758f290b`) — byte-identical
  across our file and two different reference files, confirmed to be a fixed constant our exporter
  already reproduces.
- All zlib-compressed array properties decompress correctly to their declared lengths (verified
  separately, no corruption in the compressed streams). Both `0x789C` (default) and `0x7801`
  (best-speed) zlib headers appear across the two files and both are accepted elsewhere, so
  compression-level choice is not the issue.
- No `NaN`/`Inf` anywhere in any float/double array (scanned exhaustively).
- A **programmatic schema diff** — comparing the ordered child-field-name list for every object
  kind (`Name/ClassTag` combination, e.g. `Deformer/Cluster`, `Model/LimbNode`) between our export
  and a working reference — found **zero differences**. Every object kind's schema matches.

## 5. What is proven, and the known-working workaround

**Our exported FBX files are not corrupted.** Decisive evidence: Blender 5.1's own independent FBX
importer opens `WP_Pistol.fbx` cleanly — 11 objects, including the armature, mesh, and all sockets:

```bash
"/c/Program Files/Blender Foundation/Blender 5.1/blender.exe" --background --python script.py -- <file.fbx>
# bpy.ops.import_scene.fbx(filepath=path) → succeeds, no errors
```

Further: **re-exporting that same imported scene from Blender produces a file UE5.7 *does* import
successfully** (mesh, skeleton, material created; only cosmetic warnings about missing smoothing
groups and bones missing from the bind pose — both non-fatal). So UE5.7's legacy FBX SDK can
correctly parse this exact content when Blender writes it, but rejects the byte-identical-in-schema
content when this project's exporter writes it.

**Workaround that works today**: chain export → headless Blender re-export → UE5.7 import. This
unblocks the pistol vertical slice (and presumably everything else) without knowing the exact SDK
quirk. Not yet wired into the pipeline — just proven manually.

## 6. One confirmed, fixed bug (real, but not the fatal one)

While diffing our Cluster deformer objects against Blender's, found that
[`FbxSceneBuilder.cs:293`](../src/BioShockStudio.Core/Export/Fbx/FbxSceneBuilder.cs) tags skinning
Cluster sub-objects with the embedded name-string class tag `\x01Deformer` — it should be
`\x01SubDeformer` per FBX convention (the top-level Skin object correctly uses `\x01Deformer`;
Cluster objects, which are its sub-deformers, should not). Confirmed by comparing against every
Cluster object Blender writes, 100% consistent pattern on both sides.

```csharp
// before (both calls used "Deformer"):
long clusterId = NewObject("Deformer", "Deformer", scene.Bones[bone].Name, "Cluster", out var cluster);
// after:
long clusterId = NewObject("Deformer", "SubDeformer", scene.Bones[bone].Name, "Cluster", out var cluster);
```

**This fix alone did not resolve the import failure** — reproduced the exact same "File is
corrupted" error after applying it and re-exporting. It is still worth keeping (it's a genuine spec
deviation from our writer), just not sufficient.

**Important — where this fix currently lives:** it is applied **only** in an isolated git worktree
at `C:\Users\Jack\Documents\BioshockHavok-fbxtest` (detached HEAD at `960db55`), **not** in the main
working tree. This is deliberate: at the time of testing, the main tree's build was broken by
in-progress, uncommitted changes to `src/BioShockStudio.Core/Services/AssetDetailsService.cs`
(`error CS0103: The name 'DescribeSound' does not exist in the current context`) — this looks like
it belongs to the concurrent audio work, not something to fix blind. The worktree let the FBX fix
be tested without touching or reverting anyone else's in-progress edit. **Before porting the
`SubDeformer` fix into the main tree, check whether `AssetDetailsService.cs`'s build break has
since been resolved by whoever is working on it, and stage the fix by filename, not `git add -A`**
(see §8).

## 7. What has not been tried yet (next candidates, in rough priority order)

1. **Diff the actual compressed byte contents**, not just structure — the `Indexes` array on
   `pistol_body`'s Cluster happens to have identical `len=1908 enc=1 compLen=2700` in both files
   (worth checking if the compressed bytes are literally identical, which would rule out an
   encoding-level difference there specifically). No array's raw bytes have been diffed yet, only
   lengths/types/decompressed validity.
2. **Binary-search via splicing**: since Blender's working re-export and our failing file are both
   fully available, consider surgically replacing one section at a time in a copy of our file with
   Blender's equivalent bytes (requires recalculating all ancestor/sibling `EndOffset` values, which
   are absolute file offsets — nontrivial but scriptable) to bisect which single object or section
   flips the import from failing to working.
3. **`Connections` ordering/content diff** — never directly diffed connection-by-connection against
   Blender's; only checked ours in isolation for dangling references.
4. **Check whether the *order* Definitions/Objects appear in relative to their Connections matters**
   to the SDK (unlikely per spec, but not actually tested).
5. **Look for a documented, specific UE5.7 legacy-FBX-SDK bug** (as opposed to the already-found
   Interchange one) — this was not searched for directly; only the Interchange regression was found
   via web search. Worth searching Epic's issue tracker / UE forums for "File is corrupted" +
   version 5.7 + legacy FBX SDK specifically, since that phrase is unusually specific and may be a
   known, fingerprint-able bug with a documented cause.
6. If none of the above lands quickly, **wire in the Blender-normalization workaround** for real
   (headless Blender step between our exporter and the UE5 import script) rather than continuing to
   chase the SDK-level root cause — diminishing returns after this many structural checks came back
   clean.

The user was asked to choose between (a) applying the Blender-workaround now, (b) continuing to
root-cause the SDK rejection, or (c) parking this and switching to the bytecode research track —
**no answer was given yet**; the question is still open as of this handover.

## 8. Git hygiene — read before touching anything

A second AI agent (this ChatGPT session, or whichever picks this up) is working in the **same
repository** concurrently, currently on audio (`SoundReader.cs`, `SoundExporter.cs`,
`AssetDetailsService.cs`, `docs/research/audio.md`, and others — see `git status --short` for the
live list). This has already caused one incident this session: a `git add -A` swept up unrelated,
uncommitted audio-track files into an unrelated commit, which had to be undone with
`git reset --soft HEAD~1` + selective `git add <file>` by name.

**Rules going forward** (also recorded in `ENGINEERING_RULES.md` §60):
- **Never `git add -A` or `git add .`** — stage files by explicit name only.
- Commit small and often, in logical groups, reviewing `git diff --stat` before each commit.
- Before editing any file, `git status`/`git diff` it first — it may have changed underneath you
  since another agent is live in this tree.
- Don't "fix" a build break in a file you don't recognize as your own work without checking first
  whether it's mid-edit by the other agent — prefer isolating your own testing (e.g. a worktree, as
  done for the FBX fix) over touching shared broken state.

## 9. Track B — not started

The user also asked to pursue (in parallel, "do both") decoding UnrealScript bytecode for game
logic — `Class`/`UFunction`/`UState` exports in the `.u` packages. **Zero prior work exists on
this** in the project; the only trace is a comment in `src/BioShockStudio.Core/Level/ClassDefaults.cs`
noting bytecode of unknown length must be skipped to reach property defaults. Per this project's
standing policy (`ENGINEERING_RULES.md` — read reference material before deriving from bytes,
never guess), the first step is surveying UModel/UELib/Unreal-Library/Bioshock1REMSDK-WIP and UE2's
UDN documentation for the UE2.5 script VM opcode format, which is externally documented. This has
not been started.
