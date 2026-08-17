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

## Three workspaces

The window is a `TabControl`:

| Tab | What it is |
|---|---|
| **Animated** | Rigged assets: the first-person set, characters, weapons, skeletal meshes, animations. |
| **Static** | Static meshes, props, materials and textures. |
| **Level** | Pick a map, see what it holds, walk through it, write it out. |

**The two asset tabs are one browser filtered two ways, not two browsers.** The distinction they
split on is the one that actually changes how an asset is worked with — whether it carries a rig. A
skinned mesh has a skeleton, animation sets, sockets, attachments and a transport; a static mesh's
whole story is geometry and materials. Before the split those sat interleaved in one nine-category
list.

The markup lives in `AssetBrowserView` and each tab hosts an instance, but both bind to the **same**
`MainViewModel`, so the selection, the details panel and the preview are shared and cannot drift.
Two independent copies would be free to disagree, which this project has already paid for once with
the material resolver.

Textures and materials sit with the static assets rather than getting a workspace of their own. They
are shared by both kinds, so any placement is a choice rather than a fact — this one is at least
consistent, in that nothing under Animated is anything but a rig, its parts, or its motion.

**Both totals count the workspace, not the catalogue.** The category row said "Everything (14,380)"
and the result summary "1,889 of 14,380" beside a list that can only reach the rigged half; both
stated something untrue about what was on offer. `EveryCategoryBelongsToExactlyOneWorkspace` guards
the silent failure — a category in neither list is simply unreachable, with nothing to indicate it.

The asset extraction bar at the foot of the window **is hidden on the Level tab** — it offers
"Extract selected" and "Extract all shown", which beneath the level panel reads as though those
buttons extract the level. They do not; the level has its own.

### The Level tab

Everything it needs is in `LevelService`, so it holds no format knowledge and the tab can be tested
without a window — the same rule the rest of the application follows.

It lists every `.bsm` in the install, largest first, and **filters none of them by name**: which
packages hold a level is decided by what is in them. Selecting one reads it on a background thread
and reports actors, placed objects split into static meshes and BSP brushes, lights, triangles, the
extent, and how many actors were skipped. **Skipped is stated even when it is zero**, because
"nothing was skipped" and "nothing ran" otherwise render identically — the same correction the
Problems panel needed.

"Actors with no geometry" is an expander rather than a warning. A level is mostly triggers, volumes,
sounds, spawn points and script, and presenting that as a deficiency would misread the data.

**The size estimate is shown before the job, not after.** A level OBJ is over 100 MB; the estimate
comes from a measured ~54 bytes per triangle, so `0-Lighthouse` reads "about 112 MB" and writes 112.
Bulk extraction size has already been reported as a fault in this project when it was really an
unstated cost.

**Three faults in this tab were found by rendering it and looking, with every test green** — see
`HANDOFF.md`. The one worth repeating here: **`IsVisible="{Binding !SomeObject}"` does not negate a
non-boolean binding in Avalonia**, and silently renders the control always. Use
`{Binding X, Converter={x:Static ObjectConverters.IsNull}}`.

### Walking through a level

"Walk through it" loads the map's geometry, materials and textures — about five seconds — and gives
a ghost camera: **WASD**, **Q/E** for up and down, drag to look, the wheel for speed. It is separate
from selecting a map because preparing a level decodes everything it uses, and doing that on
selection would make browsing the map list feel broken.

**Two renderers sit behind it.**

| | |
|---|---|
| **GPU** (`LevelGlViewport`) | An `OpenGlControlBase` — no new dependency, `Avalonia.OpenGL` ships in the Avalonia package. Uploads each distinct asset once as a VAO plus its textures, then draws the culled set per frame. |
| **CPU** (`SoftwareRenderer`) | The fallback, **and the tested path** — Avalonia's headless renderer has no GL context, so every snapshot and pixel check in the suite comes from this one. |

**The GL shader discards on alpha**, and its absence was a real fault: a great deal of BioShock's
detail is a masked decal on a quad — blood splatter, grime, posters, gratings — where the alpha
channel is what makes the quad invisible around the mark. Without the discard every one of them drew
as an opaque rectangle. The geometry and the texture were both correct; the shader ignored alpha.

**Level textures are capped at 1024**, matching the asset preview. It was 256 while the viewport
drew on the CPU, where every sample is a cache miss and the working set has to stay small; the GPU
changed that arithmetic, and 256 was discarding most of the detail the game ships (its art is mostly
1024 and 2048). Measured cost on `0-Lighthouse`: **8 MB** of decoded texture for the whole level.

Both consume the same `LevelViewport` selection and the same `GhostCamera`, so they draw the same
scene. If the GL context, the shaders or the upload fail, the window falls back **and says so** in
the status line — a viewport that silently becomes twenty times slower reads as a broken feature.

**The frame budget is measured, not guessed.** Drawing all of `0-Lighthouse` on the CPU takes ~1.6 s;
frustum culling alone reaches 1.15 s, because Rapture's backdrop city is entirely in view and is
most of the map's geometry. And the frame is bounded by **pixels**, not triangles — 100,000
triangles cost 423 ms at 960×600 and 147 ms at 480×300. So the viewport spends a triangle budget on
whatever occupies the most screen, and halves resolution while the camera moves.
`LevelViewportPerformanceTests` holds the figures.

**It says what it left out** — "52 drawn · 149,883 triangles · 576 ms · 25 beyond the budget, not
drawn". A viewport that quietly drops geometry shows a partial level while implying a whole one.

Movement runs off a timer over a held-key set, not key-repeat: key-repeat is a text-entry feature
(one event, a pause, then the platform's rate), so holding W stutters and two keys move in steps
rather than diagonally. The step is scaled by real elapsed time, because the frame it triggers can
take hundreds of milliseconds and the timer will not keep up.

### What the viewport draws, and what it hides

Three switches, and two of them are **off by default** because what they show is not architecture:

| | default | why |
|---|---|---|
| **Zones & triggers** | off | A blocking volume, trigger, water volume or zone marker is a region the engine tests against and never draws. Its brush is a room-sized box, so shown they are enormous grey slabs that swallow the view. |
| **Source brushes** | off | A brush is the *input* to CSG; the compiled world is its *output*. Drawing both stacks the uncarved solids on top of the rooms carved from them — most of what "weird boxes covering everything" turns out to be. |
| **Light beams** | off | Light shafts and glow cards — `LightBeamShader`. They bind **no base colour** and the engine blends them additively through a falloff map, so drawn as ordinary surfaces they are flat opaque white sheets. 19 instances / 1,338 triangles on `0-Lighthouse`. |
| **Level lights** | off | See below. |

The beam filter works per **surface** rather than per instance. On Lighthouse that turns out not to
matter — all 19 beam instances are beams throughout, so the shafts are authored as their own meshes
— but a fixture that mixed a shade with its shaft would otherwise vanish entirely, and per-surface
cannot go wrong. All three filters key off the **game's own statement**: an actor's class for the
volumes, a material's class for the beams. Never a name; `HANDOFF.md` §4 records what a name-based
allowlist cost this project once already.

Volumes are identified by the actor's class ending in `Volume`, `Trigger` or `ZoneInfo` — the game's
own statement of what the thing is. A suffix test rather than a fixed list, because the game ships
many and enumerating them would silently miss the ones nobody wrote down.

### Lighting

The level's own lights can be applied — **465 on `0-Lighthouse`, of which 298 are usable** — but the
switch is off by default, and that is a claim about honesty rather than taste.

**This is not the game's lighting model.** BioShock bakes its static lighting into lightmap atlases
(`docs/research/bsp.md` §5.5), and this project reads no part of them. What a light actor carries is
a colour, a brightness and a radius, applied here as simple point lights with a linear falloff to
the stated radius. The result looks like the level; it does not look like the game.

**A light with no stated radius is dropped rather than given one** — its reach is genuinely unknown,
and choosing a number would put illumination in the level that the game may not have. A missing
*brightness* defaults to 1.0, which is different: that is the median of the values that are stated,
so it is interpolation inside measured data. `LevelLightingTests` pins both, and checks the lighting
varies **between two places in the same map** — a bug that ignored light positions would still pass
a test that only asked whether the image changed.

## The services

| Service | Responsibility |
|---|---|
| `InstallationService` | Detects an install; validates a folder and reports **every** check rather than throwing on the first failure. |
| `AssetCatalogService` | Builds the browsable catalogue and searches it. |
| `AssetDetailsService` | Resolves one selected asset's skeleton, animations, sockets, materials and textures. |
| `TexturePreviewService` | Decodes a texture for display, using the extractor's own decoder. |
| `ExtractionService` | Runs extraction jobs with progress, cancellation and per-asset failures. |
| `DiagnosticsService` | Scopes the diagnostic checks to one asset, one package or the install. The checks themselves are `Core.Diagnostics.AssetDiagnostics`, shared with the `diagnose` command. |
| `LevelService` | Lists the maps, reads one into a `LevelScene` — placed meshes, BSP brushes and lights — and writes it out. Everything the Level tab needs, so the tab holds no format knowledge. |

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

A mesh that yields no geometry reports, in the details panel:

> No vertex data was found in this mesh, so it has no geometry to show or export.

**That wording is deliberate and was a correction.** It used to say "a geometry layout this tool does
not read yet", which blamed the reader for the data: the exports that reach this are four door rigs
that carry no vertex data at all, and the evidence is against the unsupported-layout diagnosis.
`docs/HANDOFF.md` §6.2.

A shader whose property walk stopped early says the material is partial. A bulk extraction records
every failure with its reason and keeps going; one bad asset never ends a job.

## The Problems panel

Every fault found in the two sessions before this panel existed was found by a human looking at the
viewport — grey security cameras, an armless splicer, a misaligned prop — while the tool already held
the measurement and never showed it. The panel is that measurement, surfaced.

- **Check this package** or **Check everything** runs `DiagnosticsService`. A package is seconds —
  `0-Lighthouse` is 1,866 assets in under five — and the whole install is minutes, with progress and
  a Stop button.
- Rows are worst first — broken, then degraded, then note — because sorting by package buries what a
  user came for.
- The **Evidence** column carries the measurement, not the conclusion: not "draws untextured" but
  "20 of 20 triangles; slot 0 imports 'DefaultTexture' (Texture) and it did not resolve".
- Selecting a row selects the asset, so the viewport shows the thing being complained about. It
  matches on the catalogue's own `InPackage` rule, **not** on the row's reported package: a collapsed
  row is often listed under a different map from the one the diagnostic came from, and matching both
  made the click do nothing on assets that were in the list. When the catalogue genuinely has no row
  — a shader, or a texture with no entry of its own — the status bar names the package and export
  index instead of failing silently.
- **Copy diagnostic** puts the whole entry — asset, package, group, export index, summary, evidence
  and the research note it belongs to — on the clipboard, so a report to a future session costs one
  click. **Copy all** does the panel.
- The selected asset's own problems appear in the details panel beside it, which is where a user is
  looking when the viewport shows something odd.

**An empty panel is not a clean bill of health, and must not look like one.** Before anything is
checked the panel says so in as many words, and every summary states how many meshes, materials and
textures were examined before it says what was found.

## Highlight problems — the viewport half of the panel

**Grey paint and a missing material look identical.** A run whose material did not resolve draws in
flat grey, and so does a great deal of BioShock: bare concrete, painted metal, the inside of a crate.
That ambiguity is exactly what cost this project the grey security cameras — found by a user, not by
the tool, while the tool held the evidence.

The **Highlight problems** checkbox tints the triangles whose material resolved to nothing. It is
per-*surface*, not per-mesh: on `Bomb`, two of seven runs have no material, and only those two go
magenta while the other five keep their texture. Magenta is deliberate — the long-standing convention
for a missing texture, and no shipped BioShock surface is that colour, so it can never be mistaken
for art. The tint is blended rather than flat, so the shading still reads and the *shape* of the
affected run stays legible.

The most useful thing it does is the negative case. `Bomb`'s nose carries a plain grey disc that
looks exactly like an untextured surface; with the overlay on it stays grey, which says that disc is
real art and the fault is elsewhere. **A diagnostic that can only say "something is wrong" is worth
much less than one that can also say "not this".**

`ProblemOverlayTests` asserts both directions — that it tints an affected run, that it tints strictly
less than the whole mesh, and that a mesh whose materials all resolve renders **byte-identical** with
the overlay on. Set `BIOSHOCK_OVERLAY_SNAPSHOT` to write the on/off pair from four angles.

## Verifying the window

`WindowTests` renders the real window through Avalonia's headless platform **with Skia enabled**, so
the layout is genuinely built and drawn. Every binding resolves during that render, which is what
catches the class of bug that shipped in the first attempt: a `$parent` binding inside a
`DataGrid` column, which cannot resolve because a column is not in the visual tree, and which
crashed the application on startup.

To produce a picture of the window:

```bash
BIOSHOCK_UI_SNAPSHOT=/tmp/ui.png dotnet test --filter FullyQualifiedName~WindowTests
BIOSHOCK_PROBLEMS_SNAPSHOT=/tmp/p.png dotnet test --filter FullyQualifiedName~DiagnosticsUiTests
BIOSHOCK_OVERLAY_SNAPSHOT=/tmp/o.png dotnet test --filter FullyQualifiedName~Overlay_Snapshot
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
