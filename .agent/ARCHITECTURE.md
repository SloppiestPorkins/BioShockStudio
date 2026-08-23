# Architecture

Written 23 Aug 2026 by the lead engineer, from the tree at `9b2036f`. Exact paths and symbol names
throughout — an agent should be able to open the file named here without searching first.

This file describes **structure**. For what works and what does not, see `PROJECT_STATE.md`; for
what must not be changed casually, see `KNOWN_ASSUMPTIONS.md`.

---

## 1. Solution layout

`BioShockStudio.sln`, .NET 8, `Nullable=enable`, `LangVersion=latest` (`Directory.Build.props`).

| Project | Path | Kind | Depends on |
|---|---|---|---|
| `BioShockStudio.Core` | `src/BioShockStudio.Core/` | class library, **no external packages** | — |
| `BioShockStudio.Cli` | `src/BioShockStudio.Cli/` | console exe, one file `Program.cs` (~64 KB) | Core |
| `BioShockStudio.App` | `src/BioShockStudio.App/` | Avalonia 11.2.3 WinExe | Core |
| `BioShockStudio.Tests` | `tests/BioShockStudio.Tests/` | xUnit 2.5.3, 140 files | Core, App |

Non-.NET code:

| Path | What |
|---|---|
| `tools/blender/` | 5 headless Blender scripts — scene import, FBX round-trip validation, UE5 normalisation |
| `tools/ue5/` | UE5 editor Python (`import_bioshock.py`, `import_level.py`, `verify_bioshock_import.py`, `build_validation_map.py`) plus the `BioShockImportTools` UE plugin (C++) |
| `tools/uelib-bridge/` | standalone .NET project wrapping UELib to decompile the game's UnrealScript |
| `.github/workflows/deploy-pages.yml` | publishes `docs/site/` |

**Core has zero NuGet dependencies.** Every binary format in this project is read by hand. Adding a
package to Core is an architecture decision and needs lead approval.

---

## 2. Core module map

`src/BioShockStudio.Core/`, in roughly the order data flows.

### Io — stream primitives
- `Io/StreamReaderLE.cs` — little-endian reader, `ReadCompactIndex()` (Unreal `FCompactIndex`).
- `Io/WindowStream.cs` — a bounded view over an export's payload, so a reader cannot walk past it.

### Packages — the `.bsm` container
- `Packages/BioShockPackage.cs` — `Open()`, summary, name/import/export tables, `ReadExportData()`,
  `GetClassName()`. `ReadFName` lives here and defines **the** FName rendering (see
  `KNOWN_ASSUMPTIONS.md` A3).
- `Packages/PackageStructures.cs` — `NameEntry`, `ObjectImport`, `ObjectExport`, `PackageIndex`.
- `Packages/UnrealProperty.cs` — `UnrealPropertyReader.Read()`, the tagged-property walker every
  higher reader is built on. Payload property lists start at offset **8**
  (`PayloadPropertyOffset`); nested struct values start at **0**.
- `Packages/PackageCache.cs` — keeps packages open across a catalogue build.

### Havok — the animation container
- `Havok/Detection/HavokDetector.cs` — finds packfiles inside an export payload.
- `Havok/Packfile/` — `PackfileHeader`, `PackfileSectionHeader`, `HavokPackfile`, `PackfileFixups`.
- `Havok/Objects/HavokSection.cs`
- `Havok/Skeleton/HkaSkeletonReader.cs`
- `Havok/Animation/AnimationPackageRootReader.cs`, `HkaAnimationReaders.cs`
- `Havok/Animation/SplineCompression/` — `SplineFormat`, `NurbsCurve`, `SplineDecompressor`.
  **This is the hardest code in the repository.**
- `Havok/Physics/` — `HkpRigidBodyReader`, `HkpCapsuleShapeReader`, `HkpConstraintInstanceReader`,
  `HkaRagdollInstanceReader`, `HkaSkeletonMapperReader`.

### Skeleton / Animation — internal representation
- `Skeleton/BioShockSkeleton.cs` — original bone indices preserved, never re-ordered.
- `Animation/BioShockAnimation.cs`, `DecodedAnimation.cs`, `AnimationPairing.cs`.

### Coordinates
- `Coordinates/GameBasis.cs` — **`C = diag(1, -1, 1)`, the only handedness-changing operation in the
  codebase.** Applied at exactly five decode boundaries. See `KNOWN_ASSUMPTIONS.md` A1.

### Mesh
- `Mesh/SkeletalMeshReader.cs`, `Mesh/StaticMeshReader.cs`
- `Mesh/MeshGeometry.cs`, `MeshGeometryReader.cs` — note the **package-aware overload**; the
  byte-only one silently yields empty `Sections` (this caused a real mis-measurement, see
  `docs/QUALITY.md` §2).
- `Mesh/SkeletalMeshSections.cs` — per-material section table.

### Materials / Textures
- `Materials/MaterialReader.cs` — the shader walk.
- `Materials/MeshSurfaceResolver.cs` — per-section material resolution.
- `Materials/MaterialSwitchReader.cs`, `MaterialSequenceReader.cs`, `MaterialAnimator.cs`,
  `ExternalMaterialSource.cs` (resolves materials living in other packages, e.g. `ShockAI.U`).
- `Textures/TextureReader.cs`, `BlockCompression.cs` (DXT1/3/5 + DXT5N), `BulkTextureCatalog.cs`
  (the 8 GB `BulkContent/` mip store), `CubemapReader.cs`, `TextureIntent.cs`, `ImageWriters.cs`.

### Level
- `Level/LevelAnalyzer.cs` — **the largest single reader (~1,000 lines)**; `Analyze()` produces a
  `LevelContext` of placed actors. Actor schema decoding lives here.
- `Level/LevelModel.cs` — `LevelActor`, `ActorRegion`, `RegionActorData`, and the per-class typed
  records.
- `Level/PropertyValues.cs` — decodes property *values*: `AsName`, `AsString`, `AsReference`,
  `TryAsNameArrayExact`, `TryAsStructArrayExact`, `TryAsReferenceArrayExact`. The `*Exact` methods
  refuse a partial read; that is deliberate.
- `Level/BspWorld.cs`, `BspGeometry.cs`, `BspPolys.cs`, `ModelReader.cs` — compiled world + source
  brushes.
- `Level/LevelScene.cs`, `LevelLight.cs`, `LevelCoverage.cs` (the UE5 classification ledger),
  `ClassDefaults.cs`, `ActorPayload.cs`, `ActorTransform.cs`.

### Audio
- `Audio/SoundReader.cs` — native `Sound` exports (MP3 payloads).
- `Audio/SoundEventReader.cs` — `EventResponse_SoundEffectsSubsystem`: animation event → sound name.
- `Audio/SoundEffectSpecificationReader.cs` — the 31-property specification: attenuation, volume,
  pitch, looping, and the `SoundSpecs` sample list.
- `Audio/SoundActorSpecificationIndex.cs` — placed actor → specification, by the two shipped routes.
- `Audio/StreamAudioService.cs` — drives an **x86 helper process** over the game's 32-bit FMOD DLL
  (a 64-bit process cannot load it). Both stdout and stderr must be drained concurrently.
- `Audio/StreamSampleCatalog.cs` — exact-name index over all 65 FSB5 banks; `AudioActorResolver`.

### Export
- `Export/Fbx/FbxWriter.cs`, `FbxSceneBuilder.cs`, `FbxNode.cs`, `FbxMath.cs` — binary FBX, written
  by hand.
- `Export/FbxExporter.cs`, `AnimationSceneExporter.cs` (Blender scene JSON),
  `LevelSceneExporter.cs` (versioned level JSON + OBJ for UE5), `MaterialExporter.cs`,
  `SoundExporter.cs`.

### Assets / Diagnostics / Rendering / Services / Game
- `Assets/AssetIndex.cs` — whole-game export index (812,435 exports, 14,378 browsable assets).
- `Assets/AnimationPackage.cs`, `AssetContext.cs`, `CharacterCatalog.cs`, `AnimationMetadata.cs`,
  `WeaponUpgrades.cs`.
- `Diagnostics/AssetDiagnostics.cs` — one list of everything the tool knows is wrong;
  `AnimationAudit.cs`, `Ue5Coverage.cs`.
- `Rendering/SoftwareRenderer.cs`, `LevelViewport.cs`, `PreviewModel.cs` — a software rasteriser,
  used as the tested fallback for the GPU viewport.
- `Services/*.cs` — 12 window-free services (`AssetCatalogService`, `LevelService`,
  `ExtractionService`, `MeshPreviewService`, `TexturePreviewService`, `DiagnosticsService`,
  `SettingsService`, …). **The GUI holds no logic; it binds to these.**
- `Game/GameLocator.cs` — install detection, `BIOSHOCK_REMASTERED_PATH` override, and
  `EnumeratePackages()` (21 non-localised maps) vs `Directory.GetFiles(MapsDirectory, "*.bsm")`
  (all 161, including 140 localised duplicates). **Choosing the wrong one changes every census
  figure** — see `KNOWN_ASSUMPTIONS.md` A9.

---

## 3. Pipelines

### Parsing
```
.bsm file
  → BioShockPackage.Open            summary, name/import/export tables
  → package.ReadExportData(export)  WindowStream over the payload
  → UnrealPropertyReader.Read(..., start: 8)
  → a typed reader (Mesh / Material / Texture / Level / Audio / Havok)
```

### Mesh
```
SkeletalMeshReader / StaticMeshReader
  → MeshGeometryReader.Read(package-aware overload)   ← sections come from here
  → SkeletalMeshSections                              per-material section table
  → MeshSurfaceResolver                               section → material → textures
  → GameBasis                                         C = diag(1,-1,1), once
```

### Animation
```
AnimationPackageWrapper export
  → HavokDetector → HavokPackfile → HavokSection
  → AnimationPackageRootReader → hkaSkeleton, hkaAnimationBinding, hkaSplineCompressedAnimation
  → SplineDecompressor (NurbsCurve)
  → BioShockAnimation / DecodedAnimation
  → AnimationPairing                                  animation ↔ owner (weapon/character)
  → GameBasis
```

### Export
```
DecodedAnimation + BioShockSkeleton + MeshGeometry + materials
  → FbxSceneBuilder → FbxWriter        binary FBX, one file per animation, plus a manifest
  → AnimationSceneExporter             scene JSON for tools/blender/import_bioshock_scene.py
  → tools/blender/validate_fbx.py      round-trip check against the game's own transforms
  → tools/blender/normalize_fbx_for_ue5.py → tools/ue5/import_bioshock.py
```

### Level
```
map .bsm
  → LevelAnalyzer.Analyze → LevelContext (actors, transforms, regions, per-class schemas)
  → ModelReader / BspWorld / BspGeometry (compiled world + source brushes)
  → LevelCoverage                       classification ledger: every actor accounted for
  → LevelSceneExporter                  versioned level JSON + OBJ
  → tools/ue5/import_level.py
```

### Audio
```
map .bsm
  → SoundReader                     native Sound exports (MP3)
  → SoundEventReader                EventResponse_SoundEffectsSubsystem
  → SoundEffectSpecificationReader  radii, volume, pitch, looping, SoundSpecs
  → SoundActorSpecificationIndex    placed actor → specification (two routes)
  → StreamSampleCatalog             sample name → FSB bank/index (via the x86 FMOD helper)
```

---

## 4. GUI structure

Avalonia 11.2.3, MVVM via `CommunityToolkit.Mvvm`.

- `App.axaml` / `App.axaml.cs`, `Program.cs`, `ViewLocator.cs`, `DiagnosticLog.cs`
- `ViewModels/MainViewModel.cs` split by concern into partials: `.Audio`, `.Diagnostics`, `.Level`,
  `.LevelView`, `.Preview`; plus `AssetWorkspace.cs`, `ViewModelBase.cs`
- `Views/MainWindow.axaml` (+ `.axaml.cs`, `.LevelCamera.cs`), `AssetBrowserView`,
  `StreamAudioView`, `LevelGlViewport.cs` (GPU viewport; `Core/Rendering/SoftwareRenderer` is the
  tested fallback)
- `Services/NativeSoundPlaybackService.cs`

`docs/GUI.md` is the reference for intended behaviour.

---

## 5. Test structure

140 files in one project. Two tiers, declared per class:

```csharp
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]     // or Tiers.Sweep
```

- `Tiers.cs` — the trait constants.
- `GameFixture.cs` — locates the install, exposes `RequireRoot`, `LighthousePackage`,
  `MedicalPackage`. `RequiresGameFact` skips cleanly when the game is absent.
- `TierCoverageTests` — **fails if any test class does not declare exactly one tier**, so nothing
  can fall out of both and silently stop running.
- `DocumentedFiguresTests` — asserts the headline numbers written in `docs/QUALITY.md`. When it goes
  red, the code may have improved, regressed, *or the documentation may be wrong*. Classify before
  editing either (`docs/ENGINEERING_RULES.md` §24).

Tier rule: **Fast** = reads one package or none; **Sweep** = whole-game censuses, the bulk store,
catalogue builds, UI tests. The split is by how much real data is read, never by faking any.
**There are no synthetic fixtures anywhere in this repository.**

---

## 6. External dependencies and reference material

Runtime/build packages: Avalonia 11.2.3 (App + headless test harness), `CommunityToolkit.Mvvm`
8.4.2, xUnit 2.5.3, `Microsoft.NET.Test.Sdk` 17.8.0, `coverlet.collector` 6.0.0. **Core: none.**

Four reference projects live gitignored at the repo root and are **read in place, never vendored**:

| Path | Size | What | Note |
|---|---|---|---|
| `hk2012_2_0_r1/` | 2.3 GB | Havok 2012.2.0-r1 SDK | **Confidential — must never be committed.** |
| `Bioshock1REMSDK-WIP--main/` | 98 MB | Nyko's BioShock Remastered SDK | someone else's licence |
| `UModel-master/` | 8.4 MB | UEViewer | someone else's licence |
| `Unreal-Library-master/` | 2.4 MB | UELib | someone else's licence |

Project policy (`docs/ENGINEERING_RULES.md` §60): **read the reference projects before deriving
anything from bytes.** It keeps paying — see `docs/research/reference-comparison.md`.

Also outside git: `artifacts/` (4.5 GB of generated output), `tools/fmod-x86/` (downloaded FMOD
helper binaries).

---

## 7. Agent Impact Map

Which agent should touch what, and in what order. "Research first" means **no code change lands
until a `.agent/REPORT.md` with byte-level evidence exists**.

| Subsystem | Paths | Order |
|---|---|---|
| Package container / property walker | `Core/Packages/`, `Core/Io/` | **Research → Tester → Coder → Reviewer.** Everything is built on this; a change here moves every census figure in the repo. |
| Havok packfile & spline decompression | `Core/Havok/` | **Research first, mandatory evidence.** Hardest code here; consult `hk2012_2_0_r1/` before deriving from bytes. |
| Coordinate conversion | `Core/Coordinates/GameBasis.cs` | **Research + Tester + Coder + Reviewer, all four.** Highest blast radius in the repository. See A1. |
| Skeleton / animation binding | `Core/Skeleton/`, `Core/Animation/` | Research → Coder → Tester. |
| FBX writer & transform layout | `Core/Export/Fbx/`, `tools/blender/validate_fbx.py` | Research + Tester + Coder + Reviewer. Numeric checks have passed on visibly wrong output here before — a render or a round-trip is required. |
| Mesh readers | `Core/Mesh/` | Research → Coder → Tester. |
| Materials / textures | `Core/Materials/`, `Core/Textures/` | Coder + Tester; Research only for a new shader class or texture format. |
| Level / BSP / actor schemas | `Core/Level/` | Research → Coder → Tester. Actor schemas are well-trodden; follow the existing per-class pattern. |
| Audio | `Core/Audio/` | Research → Coder → Tester. The x86 FMOD helper is a process-I/O hazard (see A10). |
| Diagnostics / censuses | `Core/Diagnostics/` | Tester-led. Changing a figure needs the classification step first (§24). |
| Services | `Core/Services/` | Coder + Reviewer. |
| GUI | `src/BioShockStudio.App/` | Coder + Reviewer. Behaviour belongs in `Core/Services`, not here. |
| CLI | `src/BioShockStudio.Cli/Program.cs` | Coder + Reviewer. One 64 KB file — keep additions local. |
| Blender / UE5 tooling | `tools/blender/`, `tools/ue5/` | Coder + Tester. Verification means opening UE5 and looking, not reading a log. |
| Documentation / research notes | `docs/` | Research + Lead. **Never delete a negative result.** |
