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

## One row per asset

`CONFIRMED`. Every map embeds its own copy of what it uses, so the raw catalogue is about five times
larger than the set of distinct assets:

| Category | Rows | Distinct |
|---|---|---|
| Everything | 71,106 | **14,378** |
| Textures | 30,997 | 7,342 |
| Animations | 16,025 | 1,695 |
| Materials | 13,532 | 2,670 |
| Static meshes | 8,700 | 2,362 |
| Skeletal meshes | 972 | 161 |
| First person | 20 | 1 |

`NEWPlayerHands` is in all twenty maps. Browsing twenty identical rows is not useful, so entries are
collapsed on identity — category, class, group and name.

The copies are **not always byte-identical**; payload sizes differ slightly between maps
(777,639 against 777,632). The largest is kept as the one to read from, and the others are recorded
rather than discarded, so filtering by package still finds an asset in any map that carries it.

## Textures and materials say what they are

A row reading "4.2 MB" tells nobody whether a texture is the diffuse they want. Texture rows carry
their real format and dimensions, and material rows their shader class and how many maps they bind —
plus `partial` when the shader's property walk stopped early.

Both are cheap: `TextureReader.ReadHeader` reads the first few kilobytes of a payload rather than
the mip chain, and a shader is a few hundred bytes in total.

This runs **after** the collapse. Doing it during cataloguing meant reading 44,000 payloads to
describe 10,000 assets and cost four times as much for the same answer — 12 seconds against 4.

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

## The 3D preview

`Core/Rendering` holds a CPU triangle rasteriser — z-buffered, perspective, with linear-blend
skinning, per-vertex normals, a headlamp light and texture sampling.

**Software rather than GPU deliberately.** Avalonia has no built-in 3D, and the alternatives — an
OpenGL control or a rendering dependency — cannot be drawn in a headless test. This one can, so the
viewport is checked the way everything else here is: by rendering it and asserting on the pixels.
`RenderingTests` covers coverage, determinism, that orbiting changes the view, that a posed frame
differs from frame 0, and that the skeleton and socket overlays actually draw.

It is not fast in absolute terms and does not need to be: the largest asset is ~9,000 triangles.
Renders run on a background thread and frames are dropped rather than queued when one overruns, so
dragging stays responsive instead of building a backlog.

The preview loads through the same readers the exporters use. If the viewport shows a mesh deforming
correctly, that is the geometry, skinning and animation the FBX will contain — it is not a second,
looser interpretation of the data.

**Framing.** The camera frames the union of poses sampled across the animation, not the rest pose.
The hands travel far enough during a reload to leave a rest-framed view entirely; framing per frame
instead would keep the subject centred but make the camera chase it. The cost is that no single
frame fills the view.

**Shading.** The base colour, normal and specular maps the material binds are all applied. The
normal map is tangent-space and the mesh ships a per-vertex tangent and binormal, so it is applied in
the basis it was authored in rather than one derived here — the reader now keeps that basis instead
of discarding it. A degenerate basis falls back to the interpolated normal rather than producing a
NaN, which would leave a black hole in the surface. The `Normal + spec` toggle turns it off, which
is what you want when checking a skinning problem rather than a material.

**Mesh variants.** A group is often several meshes sharing one skeleton — `AggressorBabyJane` carries
the doctor, the corpse and the Lady Smith splicer bodies — so the preview lists them all and lets you
switch. Taking only the largest, as it did at first, hid the rest. Switching rebuilds the geometry
and leaves the skeleton, animations and attachments alone, because they are shared.

A mesh whose geometry variant is unsupported still draws its skeleton, with the reason shown.

## Context: a first-person set is two rigs

`AssetContextService` resolves what hangs off a host's sockets, and the viewport draws it there.

The rule is evidence-driven. A hands mesh declares a socket named after a weapon (`Pistol`) bound to
a bone (`R_Grip`); a group named for that socket (`WP_Pistol`) exists in `ShockGame.U`. That much is
only a naming match, so it is reported `Likely`. It is promoted to `Confirmed` **only when the
candidate's own skeleton is rooted at the bone the socket names** — which for the pistol it is
(`R_grip`, casing differing as it does throughout this format). The UI shows that sentence verbatim
under the picker, so the claim can be checked rather than taken.

The rigs are never merged. The attachment is a separate model drawn with the host's socket-bone
transform, and it plays its own animation in sync — the pistol's `FastReload` against the hands'
`FastReloadPistol`. That pairing is `HEURISTIC` (longest shared name prefix, short matches
rejected); what is actually proven is that their frame counts match exactly.

## Quality of life

- **Settings persist.** Game folder, output folder, export formats and the viewport toggles are
  remembered in `%APPDATA%\BioShockHavok\settings.json`. Re-picking a folder every launch is the
  kind of friction that makes a tool feel unfinished. They are written once as the window closes, not
  on every change, and a corrupt file falls back to defaults rather than stopping the app opening.
- **Keyboard.** `Ctrl+F` focuses search, `Escape` clears it, `Space` plays and pauses, `←` and `→`
  step frames. The shortcuts are on the tunnelling pass so they work wherever focus is, but Space and
  the arrows are ignored while the search box has focus, or typing would not produce text.
- **Zoom.** Wheel over the viewport, or the `−` and `+` buttons. The wheel event is marked handled
  there, because the viewport sits inside the details panel's `ScrollViewer` and the panel was taking
  the wheel instead — so zooming appeared not to work at all.
- **The viewport says "Loading…"** while a heavy mesh is read. A blank panel reads as a failure.

## Not built yet
- **Asset relationship tree.** The details panel lists relationships per section; there is no graph
  view yet.
- **Bone picking.** The renderer takes a `SelectedBone` and highlights it, but nothing in the UI
  selects one yet, and bone names are not drawn.
- **Companion context** — character plus Little Sister. The hands carry `Gatherer` notifies and
  sockets, but whether any object reference points at a Little Sister asset is still `UNKNOWN`, so
  nothing is drawn for it.
- **UE5 export status in the UI.** The FBX option writes files that are validated by round trip
  through Blender. Nothing has been imported into Unreal, so the UI does not offer a "UE5" export —
  offering one would claim a verification that does not exist.


## Viewport performance

The rasteriser is on the CPU, so its cost is per pixel and the viewport is drawn at physical pixels
with supersampling on top — roughly 940,000 of them for a 452-point panel on a 150% display. Three
things keep that interactive.

**Drawing is parallel, split by scanline band.** Each worker owns a contiguous run of rows outright,
so its colour and depth writes cannot race another's. Splitting by triangle instead would have two
workers fighting over the same depth value. Triangles are projected once, then bucketed into the
bands they reach, so a band only visits what it can draw.

Two tests guard it: one renders the same frame five times and asserts the pixels are identical — a
race shows up as a frame that differs run to run — and one looks for an empty row between two
covered rows, which is what a band that clipped a triangle wrongly would leave.

**While something is moving, fewer pixels.** A camera drag or a playing animation marks the viewport
as interacting and the next frames draw at six tenths of full size, a little over a third of the
pixels. A fifth of a second after the last interaction, one more frame is drawn at full size. The
difference is invisible while something is moving and the still frame is sharp.

**Preview textures cap at 1024 square.** The art is mostly 2048 once the bulk store is read, which
is more texels than a viewport this size can show, at four times the memory and a cache miss per
sample. Extraction is unaffected — it writes every mip the texture has.

Measured on the first-person hands, 8,726 triangles with diffuse, normal and specular maps:

| | Before | After |
|---|---|---|
| Full size, 1085px | 25.8 fps | ~47 fps |
| Interactive size, 651px | — | ~130 fps |
