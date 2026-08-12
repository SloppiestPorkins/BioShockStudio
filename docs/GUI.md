# The application

**Projects:** `src/BioShockStudio.App` (Avalonia 11), `src/BioShockStudio.Core/Services`
**Tests:** `tests/BioShockStudio.Tests/ServiceTests.cs`, `WindowTests.cs`

## Layers

```
BioShockStudio.App          the window and its view model — no format knowledge
        ↓
Core/Services               application services, testable without a window
        ↓
Core                        packages, Havok, meshes, materials, textures
        ↓
Core/Export                 scene JSON, FBX, PNG/DDS
```

The view model holds no parsing, no offsets and no output-path decisions. That is not tidiness for
its own sake: the services are what the tests exercise, and it is what stops the browser and the
command line from disagreeing about what an asset is.

## The services

| Service | Responsibility |
|---|---|
| `InstallationService` | Detects an install; validates a folder and reports **every** check rather than throwing on the first failure. |
| `AssetCatalogService` | Builds the browsable catalogue and searches it. |
| `AssetDetailsService` | Resolves one selected asset's skeleton, animations, sockets, materials and textures. |
| `TexturePreviewService` | Decodes a texture for display, using the extractor's own decoder. |
| `ExtractionService` | Runs extraction jobs with progress, cancellation and per-asset failures. |

## Why the catalogue is fast

`AssetCatalogService` **decodes no payloads**. It reads package tables and the group chain only —
the same reads `AssetIndex` does — so the whole game catalogues to 71,106 browsable assets across 22
packages in a few seconds, and searching is a pass over an in-memory list.

Everything expensive is deferred to selection: a skeleton is only loaded, and a texture only
decoded, when the user clicks the thing. The previous browser decoded every texture in a package
just to list its dimensions, which is why opening a package was slow.

The grid holds 2,000 rows at a time. When the cap is hit the count says so — "first 2,000 of 71,106
— narrow the search to see the rest" — because "2,000 of 71,106" reads as a filter that matched
2,000.

## Categories are structural

`CONFIRMED`. Nothing is classified by matching names.

- A **character** is an asset group that owns both a `SkeletalMesh` and an `AnimationPackageWrapper`.
- **First person** and **Weapons** split off that set by group name (`*PlayerHands`, `WP_*`), which is
  the game's own naming of its own groups, not an inference about an asset's contents.
- Doors, gates and levers carry animation packages too, so **Props** takes the animated groups that
  are too small to be characters. `HEURISTIC`: 20 animations and a 200 KB mesh. Everything animated
  still appears; only the bucket differs.
- Exports whose user-facing role cannot be established — notifies, package objects, script classes —
  are **not shown at all** rather than filed under a confident-looking heading.

## Relationships carry their confidence

Every related asset in the details panel is labelled with how the link was established. `Confirmed`
means the game data states it: an outer chain, a socket, a material reference. `Heuristic` means
this tool inferred it. The field is never blank — an inferred relationship displayed as a fact is
exactly how a plausible wrong answer gets believed, which has already happened twice on this project.

## Honest failure

A mesh in an unsupported geometry variant reports, in the details panel:

> This mesh uses a geometry layout this tool does not read yet, so it has no vertices to show or
> export.

A shader whose property walk stopped early says the material is partial. A bulk extraction records
every failure with its reason and keeps going; one bad asset never ends a job.

## Verifying the window

`WindowTests` renders the real window through Avalonia's headless platform **with Skia enabled**, so
the layout is genuinely built and drawn. Every binding resolves during that render, which is what
catches the class of bug that shipped in the first attempt: a `$parent` binding inside a
`DataGrid` column, which cannot resolve because a column is not in the visual tree, and which
crashed the application on startup.

To produce a picture of the window:

```bash
BIOSHOCK_UI_SNAPSHOT=/tmp/ui.png dotnet test --filter FullyQualifiedName~WindowTests
```

It renders offscreen. Do not screen-capture the running application to check it — the capture
follows whatever is in front on the desktop, not the window you meant.

## Not built yet

- **3D preview.** No mesh, skeleton or animation viewport. Avalonia has no built-in 3D, so this
  needs either a software rasteriser or an OpenGL control, and it is the next substantial piece of
  work. The data behind it is ready: `SkeletalMeshGeometry` and the decoded animation tracks are
  what the FBX exporter already consumes.
- **Asset relationship tree.** The details panel lists relationships per section; there is no graph
  view yet.
- **Context-aware preview** — hands plus weapon, character plus companion. `AssetContextResolver`
  establishes group ownership; what a first-person set needs is proven for the pistol and is not yet
  generalised.
- **UE5 export status in the UI.** The FBX option writes files that are validated by round trip
  through Blender. Nothing has been imported into Unreal, so the UI does not offer a "UE5" export —
  offering one would claim a verification that does not exist.
