# HANDOFF.md session-log archive — 16-29 Aug 2026

**Archived, not current.** This is the dated session-by-session journal that used to run to the
end of `docs/HANDOFF.md`. Moved here 4 Sept 2026 because it duplicated status `docs/ROADMAP.md`
now states more currently, and every load-bearing fact in it (landmines, decisions, byte-level
findings) is cross-checked into `docs/HANDOFF.md`'s Landmines / Investigation record / Decision log
sections, or into the relevant `docs/research/*.md` file. Read this for the narrative of how a
specific fix was found, not for current project status.

---

# NEXT CLAUDE SESSION

**Phase 1 has no correctness blocker.** The first-person hand blocker is fixed, the audit is clean,
both Blender validators pass, and the suite is green with nothing skipped. What is left is quality.

**Phase 1C's diagnostics now say what that quality is, in numbers** ? 1,371 diagnostics over 54,335
assets, and two of the counts agree exactly with results other tests already pin, which is what says
the sweep is measuring the same game. Start from the three leads under item 5 rather than from a
fresh survey: the survey has been run.

1. Read this file, then `docs/research/ANIMATION_COORDINATE_SYSTEM.md`.
2. `dotnet test --filter Tier=Fast` while working; the whole suite before finishing. For the
   expected count see the state table at the top of this file ? it is stated there and nowhere else.
3. **The section table is now consumed** ? that was the previous session's item 3 and it is done.
   `MeshSurfaceResolver` pairs section *N* with `Materials[N]` and is shared by the preview, scene
   JSON, FBX and Blender. Sections and material slots agree on **8,668 of 8,668** shipped static
   meshes. Verified by render as well as by count. Do not reopen it without evidence.
4. **The Blender and FBX multi-material paths are verified.** `validate_scene.py` now checks slot
   count, slot order and the per-face assignment, and skips the rest/pose checks for a scene with no
   skeleton instead of failing on the missing armature. Both paths were run for real in Blender
   5.1.2 ? see the table in ?5. Do not reopen without evidence.
5. **?6.5 is closed** ? every material in the game decodes, 0 partial. **?6.2 is closed** and its
   premise was wrong: there is no unread vertex stride, the 18 are door rigs with no geometry.
   **?6.6 is done** on both sides ? the viewport already posed props, and static props and weapon
   rigs now both reach the export.

   **Phase 1B is functionally complete.** The library works end to end (?5), builds for the hardest
   character in the game (`AggressorBabyJane`, 488 actions, 3m28s, 189 MB), organises itself into
   outliner collections, tags every Action with its weapon, and ships a browser add-on
   (`tools/blender/bioshock_animation_browser.py`).

   **Phase 1C's first three items are done.** The diagnostics service, the panel and the health
   report all exist and are the same code:

   - `src/BioShockStudio.Core/Diagnostics/AssetDiagnostics.cs` ? the checks, with coverage counts so
     an empty report cannot be mistaken for a clean game. `DiagnosticsService` scopes them to one
     asset, one package or the install.
   - The **Problems panel** in the application: check a package or everything, worst first,
     click-to-navigate, Copy diagnostic / Copy all. The selected asset's own problems appear in the
     details panel beside it.
   - The **health report** is `diagnose`, which is the same service summarised, with `--code` to list
     every instance of one finding and `--out` for a CSV.

   Tests: `DiagnosticsTests` (checks fire, and are silent on assets other tests prove correct),
   `DiagnosticsUiTests` (the buttons reach the checks, and the window renders with the panel).

   **The sweep's largest finding has been acted on.** It said 755 meshes resolved a material that
   binds no base colour, mostly material classes the reader did not know. **Reading one file settled
   it** ? `Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Materials_And_Shaders.md`,
   which states that every material class is a plain tagged-property object and that texture
   references are ordinary objrefs. The reader was deciding what counted as a binding from a list of
   thirteen slot names. Now: **an `Object` property whose reference resolves to a `Texture`**, plus
   a `Texture` named in a material slot being a material in its own right. **755 ? 240**, and
   96.4% of the game's meshes carry a base colour. Rendered and checked. `docs/research/materials.md`,
   open question 11b.

   **Texture `Format` ordinal 12 is also done** ? it was second on this list and it is **DXT5N**,
   not the 3DC/BC5 that Nyko's texture note calls it. UModel's BioShock branch remaps it and says so
   in a comment; the pixels agree, decisively (X and Y both centre on 128 and **0 of 4,096 texels**
   violate `x? + y? = 1`, where the BC5 reading puts green at 57 and renders magenta). **274 exports,
   all normal maps, now decode**, and `texture-undecodable` fell 320 ? 46.

   **What is left, in priority order** ? `docs/QUALITY.md` ?"Whole-game diagnostic sweep":

   1. **The `SkeletalMesh` section table** ? item 6 below. 153 meshes, and it needs a forward walk of
      the payload. Biggest piece of work left in Phase 1.
   2. **`MaterialSwitch` (38) and `MaterialSequence` (4) are Modifiers**, and nothing follows them.
      The note says a reader should "follow it to the wrapped child material(s)"; the child property
      names have not been read off a shipped object yet. Small, and the clearest quick win.
   3. **`FluidShader` (83)** ? 63 bind textures but no `WaterDiffuseMap`. One look at what such a
      material declares would say whether that is a gap or the truth.
   4. **46 texture exports carry no `Format` property**, and all 42 distinct names are editor sprites
      or engine placeholders. One hand-decode says whether they hold pixels at all.
   5. **?6.0c: the partition lead was measured and is dead.** `hkaAnimationBinding.m_partitionIndices`
      and `hkaSkeleton.m_partitions` are now read. On `AggressorBabyJane`, **457 bindings carry zero
      partition indices and all six skeletons declare zero partitions**, so the partial-body reading
      is eliminated ? a fourth cause struck off ?6.0c with evidence rather than argument. What
      remains there is unchanged: spline evaluation at *t = 0*, compared against `evaluateSimple1/2/3`.

   **`LightBeamShader` (64) is not on this list on purpose.** It binds `FalloffMap` and `DustMap` and
   takes its colour from `BeamColor`; it has no base colour and reporting one would be an invention.

   **The first viewport overlay is done too.** "Highlight problems" tints the triangles whose
   material resolved to nothing, per-*surface* rather than per-mesh ? on `Bomb`, two of seven runs go
   magenta and the other five keep their texture. It closes the loop the panel opens: the panel says
   which assets are affected, the overlay says which *part* of the one on screen.

   Its most useful behaviour is the negative one. `Bomb`'s nose carries a plain grey disc that looks
   exactly like an untextured surface, and with the overlay on it stays grey ? so that disc is real
   art and the fault is elsewhere. **A diagnostic that can only say "something is wrong" is worth much
   less than one that can also say "not this".** `ProblemOverlayTests` asserts both directions,
   including that a mesh whose materials all resolve renders byte-identical with the overlay on.

   **The relationship tree is navigable ? done, and now verified by the full suite.** The details
   panel already listed what an asset relates to and gave no way to go there. Every related asset is
   now a button that opens it. The rule that turns a name into a browsable row moved out of the view
   model into `AssetCatalogService.Resolve`, because it had already been duplicated once ? the
   Problems panel and the relationship tree now share one implementation, so a click means the same
   thing wherever it comes from.

   **The Asset Inspector is done, and with it Phase 1C.** Every asset kind now states what it is
   (name, kind, Unreal class, export object, group, owning rig) and where it lives (package read
   from, **every other package carrying it**, export index, payload). Both are built from the
   catalogue row in one place in `AssetDetailsService`, so no kind can be missed and an asset that
   fails to decode still says what and where it is instead of showing only an error. `Also in` is the
   field that earns its place: `NEWPlayerHands` reports `5-Ryan` and is in twenty packages, and
   treating a reported package as the only one has already made a click do nothing.
   `AssetInspectorTests`; rendered and looked at.

   ~~**State this was left in:** the full suite has not been run since the navigation change.~~
   **It has now.** The full suite was run on 16 Aug 2026 and is green ? see the state table at the
   top. All of the work above is committed, in fourteen commits, each of which builds on its own.

   The Asset Inspector is still to do, and is easier now, because it wants the evidence the
   diagnostics service already produces.

   Remaining Phase 1B polish, none of it blocking:

   - **The add-on has never been driven by hand in the Blender UI.** Its filtering is exercised
     headlessly (`Pistol` ? 10 actions, `Pistol` + `reload` ? 1) but no one has clicked PLAY.
   - **The scene JSON is still large** ? the hands' library is 31 MB, `AggressorBabyJane` 206 MB.
     See the bulk-extraction note below; the user deferred it deliberately.
   - **A library is one mesh per rig.** `AggressorBabyJane` owns thirteen meshes sharing one
     skeleton and the library takes the largest (`Agg_Doctor_Mesh`). The other twelve variants are
     not in the `.blend`, which is existing catalogue behaviour rather than a new fault, but a
     "library" arguably ought to carry them all as alternatives.

   Then:
   ?6.2 (skeletal geometry variant ? read `UModel-master/Unreal/` first), ?6.4 (verify the Unreal
   import, never once run ? and it now also has `ByPolygon` material mapping to confirm), ?6.6
   (attachment placement under animation).
6. **Skeletal meshes DO have a section table, and this item's `UNKNOWN` is closed.** It was worth
   looking for in `UModel-master/Unreal/` exactly as this item said, and it is there:
   `UnMeshBioshock.cpp`'s `FStaticLODModelBio` opens with `TArray<FSkelMeshSection> Sections`, nine
   `uint16`s each ? `MaterialIndex, MinStreamIndex, MinWedgeIndex, MaxWedgeIndex, NumStreamIndices,
   BoneIndex, fE, FirstFace, NumFaces` ? commented "1 section = 1 material". That is the **153**
   meshes `diagnose` reports as `mesh-materials-without-sections`, `TommyGunMESH` and
   `PlasmidEquipMESH` among them.

   **Not implemented, deliberately.** It needs the payload walked from the front instead of the
   vertex chain being searched for, and UModel targets the *original* game ? the Remastered static
   vertex is already 48 bytes against 24, so every field needs checking against shipped bytes. The
   same source gives the full payload order and shows that the "tag block" this project searches for
   (`04 00 00 00 05 00 00 00`) is a **versioned object header** whose subversion selects the layout,
   which is the precondition for walking it. `docs/research/skeletalmesh.md`, open question 11d,
   `docs/research/reference-comparison.md` ?3??4. **This is the biggest single piece of work left in
   Phase 1.**

## Session of 17 Aug 2026 ? the viewport session

Everything below in "Phase 2" still holds. This is what changed after it, and the through-line is
worth stating once: **six faults shipped in this session and a user found five of them by looking at
the screen.** Every one passed the whole suite. They are listed here because the *pattern* is the
finding, not the individual bugs.

| what shipped broken | what the tests could see |
|---|---|
| Every BSP surface tiled its texture hundreds of times | Counts, coverage and a textured-vs-untextured check all passed ? a wrong UV **scale** is still a texture on every pixel |
| Then tiled **8?** too often, because the fix divided by the loaded 256 mip rather than the authored 2048 size | The test averaged over 2M static-mesh vertices that never take that path, and reported an unchanged median |
| Rooms missing ? only source brushes and props were drawn | A scene with no compiled world is still a complete, self-consistent scene |
| Blood splatters, grime and posters as opaque rectangles | The GL shader ignored alpha; geometry and textures were both correct |
| Light shafts as flat white sheets across the view | They bind no base colour **by design** ? nothing was failing |
| Level textures soft | The 256 cap was correct for the CPU renderer it was chosen for, and never revisited |

**The lesson to carry forward: a numeric check cannot see a wrong quantity that is still present.**
Where a value has a magnitude, measure the magnitude ? `BspUvTests` measures UV size directly, and
that is the test that would have caught two of these.

### What was built

- **The compiled world** (`BspWorldReader`) ? the level's actual architecture. 81,566 polygons /
  227,911 triangles across 21 maps, **12 polygons off-plane (0.015%)**, and the figures match Nyko's
  independent measurement exactly. `docs/research/bsp.md` ?5.
- **A walkable, textured level viewport** with a ghost camera, on the **GPU** (`LevelGlViewport`,
  Avalonia `OpenGlControlBase`, no new dependency) with the software rasteriser as a tested fallback.
- **Lights applied** ? 465 decoded, 298 usable on Lighthouse. Off by default: this is *not* the
  game's lighting model, which is baked into lightmaps this project does not read.
- **Filters**, all off by default: zones & triggers, source brushes, unpainted surfaces.
- **The `SkeletalMesh` section table** ? 331 of 944 meshes, 61 multi-material. `skeletalmesh.md`.
- **Three GUI tabs** ? Animated / Static / Level.

### Two limitations found late and left open

- **`AggressorBabyJane` previews `CorpseMale`.** Not a selection bug: the package that row resolves
  to contains **exactly one** mesh in that group. Every map embeds only what it uses, so a group row
  is only as complete as the map it is read from. The choice among a group's meshes and the choice
  of package are both improved, and neither can help here. `PreviewIdentityTests`.
- **25 rows preview a mesh with a different name** ? `Int_Seagrass` ? `IntSeagrass_Mesh`,
  `FlowerVase` ? `flower_vase_mesh`. All checked; all the game's own naming. No rule distinguishes
  them from a real fault by name alone, so the sweep asserts a ceiling rather than zero.

## Session of 17 Aug 2026 (audit) ? two P0 unknowns closed, and the first timings

Ran as a full repository audit against a master engineering prompt. Three things changed and one
thing was measured for the first time.

### The four "section overruns" were a misread field, not missing data

`skeletalmesh.md` recorded four meshes whose sections reached past the index buffer by 2, 5, 5 and 8
faces, and suspected the buffer ? "this project locates the index buffer by *search*, which makes it
the more likely candidate". **Refuted.** Over all 337 shipped section tables:

| claim | agrees | disagrees |
|---|---|---|
| the sections' `NumFaces` add up to exactly the buffer's faces | **337** | **0** |
| `MinStreamIndex` is the running index total | 336 | 1 |
| `FirstFace` is the running face total | 333 | **4** |

A buffer short by 8 faces could not have its sections sum to its length. **The sections tile the
buffer; `FirstFace` is simply not where a section starts.** `MinStreamIndex` says the same
independently, and its one exception is a `uint16` wrap: `CoreTop_Mesh` stores 10,244 where the
running total is 75,780, and 75,780 - 65,536 = 10,244. **The clamp is gone**; a section is placed at
the running total, which cannot overrun by construction, and the reader asserts the sum identity
instead. What `FirstFace` means on those four is `UNKNOWN` and it is preserved.

### The twelve off-plane world polygons are snapped corners

Every one has a vertex **exactly** on its plane and the rest off it by the plane's off-axis slope
times the distance travelled ? `7-Gauntlet` node 755 is 0.0822 ? 44 = 3.60 cm against a measured
3.603, and the off-plane corners are the round coordinates while the exact ones are fractional. The
editor's grid snap, in shipped data. Not precision, not the basis conversion, not the decode ? the
same arrays produce 81,554 exact polygons. `bsp.md` ?5.6b, and the test asserts the discriminator:
snapping moves corners, a decode fault moves whole polygons.

### The first performance numbers this project has ever had

`PerformanceBaselineTests`, medians after a warm-up:

| operation | median |
|---|---|
| open `1-Medical.bsm` (204 MB) | **46.2 ms** |
| open `0-Lighthouse.bsm` (187 MB) | 21.6 ms |
| read one texture payload | **0.001 ms** |
| read one large mesh payload | 0.048 ms |
| decode that mesh's geometry | 17.3 ms |
| `LevelAnalyzer.Analyze` | 107.6 ms |

**Opening a package parses its whole name, import and export table.** Every service opened one for
itself ? `TexturePreviewService.Describe` then `Decode` is two opens for one selection, so a texture
click paid ~92 ms of table parsing to do 0.002 ms of reading.

### `PackageCache` ? fixed, and the measurement chose the design

Four opened packages, least-recently-used. **45.46 ms uncached against 0.0004 ms from the cache**,
asserted as a ratio so it means the same on a slower machine. Wired into texture preview, asset
details and diagnostics; the other ~40 call sites are one-shot and still open their own.

Two things had to be true first, and both are now tested:

- **A shared package must tolerate concurrent readers.** `ReadExportData` seeked a reader the
  instance owns. It now takes a lock ? **and a positionless `RandomAccess` read was tried first**,
  which needs no lock but bypasses the stream's 64 KB buffer. This is called once per export,
  thousands of times in a row, by anything that walks a package: `LevelAnalyzer.Analyze` went
  **107.6 ms ? 217.7 ms** that way, and **97.8 ms** with the lock. The faster-looking design was the
  slower one, and only measuring it said so.
- **Eviction must not close a package somebody is holding.** The details panel holds a lease across
  a long operation, so evicting four packages under it would turn a slowdown into a crash. Entries
  are reference-counted: eviction removes the entry, the file closes when the last lease returns.
  `AnEvictedPackageStaysReadableWhileItIsStillLeased`.

### The "stuck on the first mesh" bug ? a real race, found by reading the code

A user reported the preview viewport freezing on the first asset selected and never updating again
on later clicks, and separately that some assets (`ArcadiaGateMESH`, a Props-category entry) showed
nothing at all. The second report never reproduced ? `AssetCatalogService` (2,362 static meshes, 117
props), `MeshPreviewService.Load` (80/80 Props entries, geometry, zero exceptions) and
`AssetDetailsService.Describe` (80/80, including 40-way concurrent access through the new
`PackageCache`) all check out clean, including for the exact reported entry. Ruled out along the way:
only one `AssetBrowserView`/`DataGrid` exists at a time ? Avalonia's `TabControl` recreates tab
content rather than keeping both alive, so there is no cross-tab `SelectedAsset` binding conflict.

**The first report was real, and did not need live reproduction to find** ? reading
`RenderAsync` found a genuine dropped-work race:

```csharp
var model = _previewModel;           // captured ONCE, before the loop
do {
    var image = await Task.Run(() => SoftwareRenderer.Render(...));   // a selection can land here
    if (!ReferenceEquals(model, _previewModel)) return;               // <-- bug: bypasses the queue check
    Viewport = ToBitmap(image);
} while (_renderQueued);
```

If a new selection lands while a render is in flight, `LoadPreviewAsync` finds `_rendering` already
`true` and ? by design ? only sets `_renderQueued = true`, trusting this loop to notice. The `return`
on model mismatch discards the stale image correctly, but **also exits before the
`while (_renderQueued)` check**, so the newer request it just set is never looked at. `_rendering`
resets to `false` in `finally`, and nothing else is scheduled to fire again ? the viewport freezes on
whatever rendered first, until some unrelated event (a checkbox, a resize) happens to call
`RequestRender()` again.

**Fixed by re-reading `_previewModel` at the top of each loop iteration and turning the mismatch
branch into a retry** (`_renderQueued = true; continue;`) instead of a `return`. Not verified by a
live reproduction ? the race is timing-dependent and forcing it deterministically in a test would
need test-only hooks in production code, which was judged not worth adding for this. The fix is
confirmed by tracing the control flow, which is what found the bug in the first place.

**`DiagnosticLog`, added alongside this.** The app had no diagnostic trail at all ? `Program.cs`
called `.LogToTrace()`, invisible to anyone who launches the exe by double-click, and there was no
handler for an exception escaping every existing try/catch. `%LocalAppData%\BioShockStudio\log.txt`,
reset each launch, now records every selection, every `ShowDetailsAsync`/`LoadPreviewAsync` outcome,
every caught exception with its full inner-exception chain, and any exception that would otherwise
have vanished (`AppDomain.UnhandledException`, `TaskScheduler.UnobservedTaskException`). If the Props
report recurs, this is what will show why without needing a terminal.

### The DataGrid selection quirk ? found from a real log, worked around, not root-caused

The "nothing shows when I click an asset" report was real and, with the diagnostic log added
alongside it, reproducible in the wild every single time: **every click logged `SelectedAsset ->
theRow` immediately followed, 5-15 ms later, by `SelectedAsset -> null`**, with nothing else in the
view model firing in between ? every filter, category and tab-index change is logged too, and none
of them appeared. `ShowDetailsAsync`/`LoadPreviewAsync` load, then get cancelled by the null before
they can populate anything. Occasionally a third event re-selected the same row and it worked; most
of the time it didn't.

**Not root-caused.** This points at Avalonia's `DataGrid.SelectedItem` binding rather than anything
in this project ? a web search turned up several related open issues
([#16591](https://github.com/AvaloniaUI/Avalonia/issues/16591),
[discussion #9834](https://github.com/AvaloniaUI/Avalonia/discussions/9834)) but none matches this
exact shape closely enough to call it confirmed. `Avalonia.Controls.DataGrid` 11.2.3.

**Worked around in `MainViewModel`, not the XAML.** A null selection is no longer acted on
immediately. It waits one 100 ms tick; if the row that was actually clicked is still sitting in the
current `Assets` list when the tick elapses, the null is treated as the quirk and the selection is
re-asserted rather than cleared. If the row is gone (a real navigation happened) or a different
selection has since superseded it, the null is honoured normally. Capped at three consecutive
reassertions per row so a genuinely, persistently rejected selection cannot be fought forever.

**This is a workaround, stated as one.** The underlying DataGrid behaviour is still not understood ?
"unknown is a valid answer" applies to the framework's internals same as to this project's own
formats. If it recurs in a shape the cap doesn't cover, the diagnostic log will show it.

### 22 Aug 2026 ? SOLVED: the actor roll sign was wrong, settled against the game's own BSP tree

**Superseding the "OPEN" record below, which is kept because its dead ends are worth not repeating.**
A user photographed a `1-Medical` skylight rotated wrongly with correctly-rotated neighbours, after
the actor-transform work had been called done. **`UnrealRotator.ToQuaternion` now negates roll as
well as pitch**, and the evidence is a ground truth no reference implementation is involved in.

**The decisive measurement: the game's own BSP tree.** The compiled world is a spatial partition
shipped in the package; it can classify any point as inside architecture or in open space. A prop
stands in a room ? not inside the masonry ? so the share of a rotated actor's geometry landing in a
*solid* leaf is a cost the correct composition minimises. Across **six maps and 147,466 sampled
points**, on actors carrying a non-zero roll:

| composition | geometry buried in solid |
|---|---|
| `Rx(+roll)` ? as shipped, and as the reference builds it | **25.85%** |
| **`Rx(-roll)`** | **15.38%** |
| pre-fix `+pitch` | 26.49% |
| negated yaw | 27.30% |
| reversed order | 26.58% |
| reversed with negated roll | 25.89% |

**Every alternative clusters at 25.8?27.3%; only the negated roll separates, by 40%.** That spread is
what makes this a measurement rather than a preference.

**The classifier behind it is validated, not assumed.** Which leaf side is open space could have been
stated from memory of Unreal's convention ? exactly the inherited claim this project keeps being
caught by. Instead it was established from the shipped AI navigation graph: **7,207 of 7,378
`PathNode`/`PatrolPoint` positions across 18 maps (97.7%) fall in a front leaf**, so front is open.
`BspSolidityTests` asserts both that split and the scoring.

**Rendering agrees.** The four `window_128_corner` pieces of the reported skylight were placed under
all six candidates and drawn: only the negated roll assembles them into a continuous barrel vault.

**And the user confirmed it in the viewport ? which is the evidence that actually closes this.**
The same person who reported the fault walked back to it in the rebuilt app and reported the
skylight fully fixed. Every measurement above is a proxy for that; this project's own history is a
list of numbers that agreed while the picture was wrong, so a human looking at the thing remains the
last word.

**What it does not disturb, and why the two fixes are independent.** A roll of ?180? negates to
itself, so the Medical Pavilion arch that produced the pitch fix is untouched ?
`TheMedicalPavilionCeilingArchFormsOneContinuousSurface` still measures 2422 units, unchanged to the
digit. That is why fixing pitch left this one standing for a further session.

**This project now deliberately disagrees with the reference editor**, and that is pinned rather than
hidden. `ActorTransformReferenceTests` compares against the reference construction *with roll
negated* ? which still exercises the axis assignment, multiplication order, scale, translation and
row/column convention, worst component difference **0.000011** across all 12,557 rotation/scale
pairs ? and `TheDivergenceFromTheReferencesRollIsDeliberateAndMeasured` separately requires all
**5,703** observable-roll rotations to differ from the raw reference (worst 70). A silent revert to
the reference's roll fails a test instead of quietly making every level worse.

**The lesson, which is the reusable part:** agreement with a reference implementation is not
correctness. The reference comparison was committed the same day and stayed green through a real,
visible bug, because Nyko's editor composes roll the same wrong way. **A check that can only compare
two implementations of a rule cannot find a rule that is wrong in both.** What broke the deadlock was
finding a source of truth inside the shipped data ? the BSP tree and the navigation graph ? that
neither implementation had a hand in.

### 22 Aug 2026 ? OPEN (superseded by the entry above): the roll investigation and its dead ends

**A user photographed a skylight in `1-Medical` rotated wrongly with correctly-rotated neighbours,
after the actor-transform work had been called done.** The investigation is unfinished; this records
what is established so a later session does not restart it.

**First, the correction to how item 1 was closed.** `ActorTransformReferenceTests` proves this
project composes an actor transform *identically to Nyko's level editor* ? 12,557 rotations to 1e-5.
That is agreement with a **reference**, not correctness: if the reference builds the rotation wrongly
this project reproduces the error faithfully and the test stays green forever. The project's own
landmine list already says this ("corroboration is not agreement ? check the layer you actually
depend on") and it was not applied. The older evidence has the same hole from the other side: the
Medical Pavilion arch was settled by "the four instances form one continuous surface", which a
surface that is continuous but rotated *as a whole* also passes. **Both existing checks are blind in
exactly the place the bug lives.**

**The reported case, measured.** Four `window_128_corner` actors at Z 8452 form one skylight vault:

| actor | pitch | yaw | roll |
|---|---|---|---|
| `StaticMeshActor1855`, `?1853` | -90? | 0 | 180? |
| `StaticMeshActor1854`, `?1856` | 0 | -90? | -90? |

Their placed area-weighted normals come out `(0, 0.78, 0.63)` and `(0, -0.63, -0.78)` ? the Y and Z
components swapped and negated, the signature of a 90? error about X. **Rendered, two pieces form a
clean barrel vault and two are rotated out of it**, which is exactly what the user saw.

**Six candidate compositions were built and rendered on that assembly. Only one produces a
continuous vault:** `Rz(yaw) ? Ry(-pitch) ? Rx(-roll)` ? i.e. **the current composition with roll
negated**. The shipped one (919 units combined diagonal) and the pre-fix `+pitch` (670) and the
negated-yaw variant (658) are all visibly broken; small diagonal does not mean correct, which is why
this was decided by looking rather than by the number.

**Corroboration is real but weak, and is recorded as such ? do not treat this as settled:**

- **Assembly compactness across five maps** (same mesh, =3 actors, =2 distinct rotations; 287?482
  clusters per map): `negroll` has the lowest mean spread in **4 of 5** ? 1-Medical 1.0172 vs 1.0297
  shipped, 6-Resi 1.0174 vs 1.0278, 3-Arcadia 1.0255 vs 1.0328, 7-Science 1.0262 vs 1.0307 ? and
  loses narrowly on 4-Recreation. Margins are small because yaw-only clusters, which every candidate
  places alike, dilute the signal.
- **Flushness against the compiled world was tried and is INCONCLUSIVE** ? a negative result worth
  keeping so it is not repeated. Counting rolled actors sitting within 12 units of a parallel BSP
  surface gives 63/250 for `negroll` against 60/250 shipped on 1-Medical, 39 vs 37 on 6-Resi, and
  7 vs 10 the *other* way on 3-Arcadia. Most rolled props are not flush against architecture at all,
  so the metric is mostly noise.
- **`Med_Floor_Signs` cannot decide it.** The two rolled ?90? signs sit flush against walls (3.8 and
  5.8 units), which reads as correct under the shipped composition ? but a negated roll leaves them
  vertical and flush too, facing the other way. This is why an early conclusion that "the roll term
  is fine" was wrong: the test could not see the difference it was being asked about.

**Nothing has been changed.** Negating roll would put this project in deliberate disagreement with
the reference editor and would turn `ActorTransformReferenceTests` red on every rotation with a
non-zero roll ? which may be the correct outcome, but not on this evidence. **What would settle it:**
the skylight vault must fill an opening in the compiled world, so its silhouette should match that
opening's boundary ? a ground truth independent of both this project and Nyko. That test is not
written yet.

**Also from this session:** the level viewport now reports the camera position **in the game's own
coordinates** (`MainViewModel.LevelLocation`), so a user can say exactly where a fault is instead of
describing the room. It is the studio basis negated in Y; a readout in viewport coordinates would
name the mirror image of the right place.

### Session of 22 Aug 2026 (later still) ? Gate 0 item 2: the level was missing 11.5% of itself

**Item 2 asked for "remaining blocky/flat BSP surfaces" to be resolved as material-chain failures.
Censusing before fixing found something else first, and it was worse than blocky.**

**A compiled-world surface with no lightmap had no path to the screen.** A map with a proven atlas
pool is drawn from `LightMapBatches` and `Prepare` then `continue`s, so the material-only model is
never built for it. But `ToLightMapBatches` keeps a node only when its first baked-light layer names
an atlas the world carries ? so a *drawn* surface failing that test was in no batch and was drawn by
nothing at all. **23,714 of 206,742 triangles across the 20 affected maps: 49.5% of `7-BossFight`,
37.7% of `0-Lighthouse`.**

- **`Entry` identified the cause on its own.** It was the only map at 100%, and it is the only map
  with no `LightMaps_BSP` group ? so it took the material-only fallback and lost nothing. A natural
  control, not a constructed one.
- **Missing geometry is invisible to every count taken over what is drawn.** The surface census was
  green throughout: a surface that was never added is not a surface with no material, it is simply
  absent. This is the same shape as the mirrored-asset years ? the numbers cannot see it.
- Fixed by drawing the remainder unlit. **206,742 of 206,742 on all 21 maps**, exact, and no map over
  100% (which would have meant double-drawing). `BspGeometry.HasLightMapAtlas` is now one shared
  predicate used by the batch filter and by its complement, so they cannot drift apart.
- **Rendered and looked at, per the standing rule.** "23,714 triangles were missing" is equally
  consistent with real walls and with degenerate slivers, and adding junk would have made the
  coverage assertion pass while making the viewport worse. `7-BossFight`'s remainder is a complete
  room; `1-Medical`'s is scattered solid slabs. Architecture, not slivers.

**Then the material chain itself, where item 2's framing was correct.** Of **74,091 drawn
compiled-world polygons, 0 name no material** ? so a grey BSP surface was never absent data, always
a reference this project failed to follow. **1,530 name their material by import**, and `Describe`
can only express an export, so all 1,530 resolved to null and drew untextured. `MeshSurfaceResolver`
has had the `IExternalMaterialSource` branch for exactly this since "433 slots across the game are
imports and none resolve inside their own package"; the BSP path never got it. Now: **0 unresolved**,
**73,188 of 74,091 (98.8%) bind a base colour**, 875 unpainted by design, 28 neither.

**Two methodology traps, both worth more than the fix:**

- **The first census run reported no change from a fix that works.**
  `AssetCatalogService.ExternalMaterials` is null until `RegisterInstall`, which the application
  calls at startup and the test did not ? so the import branch was a silent no-op *in the test*. A
  measurement that does not set the app up the way the app sets itself up measures a different
  program.
- **The end-to-end check was first written against `0-Lighthouse` and passed ? and would have passed
  before the fix**, because the Lighthouse's compiled world names almost nothing by import. It is now
  on `1-Medical` (248 imports) and was **verified to fail with the fix disabled**, then the source
  restored byte-identical. Reaching for the fixture's default map is how a test ends up asserting
  something true and irrelevant.

**And the census was rewritten to be affordable.** Its first form went through `LevelViewportService`
and therefore decoded every texture in every map ? 18 GB and over twenty minutes, which is precisely
the kind of test that stops being run (the same reasoning behind the Fast/Sweep split). It now walks
the chain without turning any of it into pixels; the pixel check stays as one map.

**Left `UNKNOWN` rather than tidied away:** 28 polygons resolve a material that binds no base colour
and is not a by-design unpainted class. **Source brushes are out of scope throughout** ? `bsp.md`
already establishes their 17,802 material-less polygons as content ? and were not swept for imports.

### Session of 22 Aug 2026 (later) ? Gate 0 item 1: the reference comparison, committed and swept

**A new standing rule came first:** work a roadmap's items in order and clear one fully before
starting another (`ENGINEERING_RULES.md` ?60 "Roadmap discipline", `ROADMAP.md` 0.7). Gate 0 has been
marked *active* for several sessions while work happened in Gate 1 and Gate 2; this session went
back to Gate 0 item 1.

**What was actually wrong with the existing evidence.** The pitch-sign fix below was correct, and the
way it was established was not durable. Nyko's `BuildActorTransform` was matched numerically in one
session over six sampled rotations ? as a throwaway probe. **Nothing of that comparison was
committed.** What went into the suite was
`TheMedicalPavilionCeilingArchFormsOneContinuousSurface`: four instances of one mesh in one map.
That is a single view, and generalizing a rotation rule from a single view is the exact failure that
produced the bug.

**`ActorTransformReferenceTests` now holds it.** `viewport.cpp`'s construction is transcribed
literally ? same column-major `float[16]`, same `m[col*4+row]` arithmetic, same multiplication
order ? so it can be diffed against the C++ by eye rather than trusted as a paraphrase. All sixteen
matrix components are compared (strictly stronger than probe vectors, and it needs no probe choice
to justify) against `ActorTransform.ToMatrix`, for **every one of the 12,557 distinct rotation/scale
pairs the shipped maps place an actor at**: all 161 shipped `.bsm` packages, 118,919 actors, 69,068 rotated, each composed
with that actor's own location and scale. **Worst component difference 0.000011.**

**Proved able to fail.** The pre-fix `+pitch` composition is rejected by all **6,215** placements
pitched far enough to distinguish the two, worst difference **60**. This project has been burned
specifically here before ? two geometric metrics written to catch the backwards first-person pistol
both *passed* the broken pistol ? so a check that has never been seen to fail is not evidence.

**The finding worth keeping: essentially half the game is blind to this class of bug.**
**6,167 of the 12,557 placements sit at a pitch of exactly 0? or 180?**, where `Ry(-p) = Ry(p)` and
the wrong sign produces not a subtly different matrix but the *identical* one. A further 175 combine
a tiny pitch with a small scale and fall below float noise. The first attempt at the falsification
test asserted that *every* rotated actor rejects the wrong sign, failed 91 of 4,562, and **the right
response was to find out why rather than widen the tolerance** ? the difference is
`2?|sin(pitch)|?scale`, which reproduces the measured values to four significant figures. The
exact-symmetry case is pinned by its own test so a later session cannot read the population filter
as a tolerance tuned until the counts agreed.

**A second `UNKNOWN` surfaced, and it is the brush-placement wall again.** Keying the sweep on scale
as well as rotation ? because `T?R?S` and `T?S?R` agree for every *uniform* scale, so a uniform-only
population verifies the ordering no more than a yaw-only one verifies the pitch sign ? turned up
**exactly two** rotated actors in the whole game carrying a non-uniform scale, both in `1-Welcome`,
both `<0.7, 0.687, 0.7>`: **1.8% off uniform**. That is present but far too weak to settle an order.
Same shape as `BrushPlacement`'s "0 of 13,443 brushes scaled, and every rotated one a gameplay
volume": **no shipped sample can decide it.** The order is therefore checked against the reference
under a deliberately non-uniform *probe* scale (`<0.5, 2, 3.5>`, worst difference 0.000004; the
swapped order diverges by 3, so the check distinguishes them) ? and that is labelled for what it is,
an equivalence between two *implementations*, not a claim about shipped data. The census
`Assert.Equal(2, nonUniformScale)` is the fact that can fail if a better sample ever turns up.

**Confidence records corrected while here.** `ToMatrix` moves `LIKELY` ? `CONFIRMED_EXTERNAL`, and
`LevelSceneBuilder.MeshPlacement`'s cross-reference ? which still said "labelled `LIKELY` there,
awaiting a rendered level" long after that stopped being true ? is corrected with it.

**What this comparison deliberately cannot say.** The reference editor does not apply `PrePivot` to
an actor at all; the field appears in its source only as a name in a skip list. So the pre-pivot
term is held at zero throughout, and it continues to rest on this project's own separate and
stronger evidence (`BrushPlacementTests`, 33,631 of 33,632 world polygons). Stated as a boundary,
not left for someone to discover.

### Session of 18 Aug 2026 ? the rotation sign bug, found by a real screenshot

A user reported a warped ceiling arch at the Medical Pavilion entrance ? two panels meeting at a
diagonal seam instead of a smooth barrel vault. This is the bug the earlier "flushness" measurement
had already hinted at (a measured 40-55% mismatch rate for genuinely three-axis rotations) but had
not pinned down, because that heuristic is too coarse and too noisy for floating fixtures.

**The fix: negate pitch in `UnrealRotator.ToQuaternion`.** Found by matching this project's
quaternion composition against the reference level editor's own matrix construction, numerically ?
not by trying alternatives and eyeballing renders. Nyko's `viewport.cpp` builds
`Ry(yaw) * Rp(pitch) * Rr(roll)` for a **column**-vector; this project uses **row**-vector convention
throughout. Six quaternion candidates were matrix-ized and applied to four probe vectors under both
conventions, compared against Nyko's raw matrix multiplied by hand, across six sampled rotations
including the exact case that broke (`pitch=-90?, roll=180?`). `Rz(yaw)?Ry(-pitch)?Rx(roll)`
reproduced Nyko's construction to **1e-6** precision; the shipped `+pitch` version was off by more
than 6 units on the same probes.

**Why the earlier skyline render never caught it.** `LevelRenderingTests`' Rapture-skyline check
exercises real rotated data, but most of Lighthouse's rotated actors are yaw-dominant ? a yaw-only
rotation is insensitive to the pitch sign, so a wrong sign renders identically. The bug needed a
genuinely three-axis case, which is rare and exactly what the arch is.

`TheMedicalPavilionCeilingArchFormsOneContinuousSurface` is the regression test ? verified to fail
against the old sign (combined bounding diagonal 4295 units, one instance scattering away from the
rest) and pass against the fix (2422 units).

**Also investigated, found healthy:** a second report that the Static tab's browser showed nothing
on click. `AssetCatalogService` builds 2,362 static meshes correctly; `MeshPreviewService.Load`
succeeded with geometry on 50/50 sampled entries, zero exceptions; `AssetDetailsService.Describe`
succeeded on all 50, including under 40-way concurrent access through the new `PackageCache`.
Whatever is wrong is in the GUI layer and needs the live window to isolate ? not reproduced here.

### The compiled world's tail ? three findings and one correction

`BspWorldReader` stopped at the vertex pool, leaving **13.9% of the compiled worlds unread** ?
7.9 MB across the 21 maps. The tail is now walked far enough to know what is in it:

- **The first two int32s after the pool are `NumSharedSides` and `NumZones`** ? confirmed by a field
  this project already decodes independently: `max(node.Zone) + 1` equals the declared zone count on
  **21 of 21** maps, from a 2-zone `Entry` to a 125-zone `4-Recreation`.
- **A zone record is an `FCompactIndex` actor reference plus 36 fixed bytes.** The fixed part starts
  with the zone's own bit mask ? 1, 2, 4 for zones 0, 1, 2 ? and the references resolve to
  `ZoneInfo` and `SkyZoneInfo` exports. A fixed 38-byte stride was tried and **rejected**: it lands
  correctly on 2 of 21 maps, because the reference's width varies with the export index.
- **The zone walk lands on the `Polys` reference on 21 of 21 maps**, which is what makes it a decode
  rather than a plausible stride, and the array after that is **`Bounds`** ? 30,578 records across
  the maps, every one a valid `FBox` at a 25-byte stride.

**And the correction, which is the part worth remembering.** That last array was first written up as
`LightMap`, on the strength of UE2's serialisation order ? inherited ordering promoted to a fact
without reading a record. `Entry`'s first record is `min(-128,-128,-128) max(128,128,128)`. It is a
box. **One dump of the bytes settled what one plausible ordering had asserted**, and the wrong
reading stays in `bsp.md` ?5.5c rather than being quietly replaced.

**Lightmaps are past `LeafHulls`, `Leaves` and `Lights`**, with 879 to 628,534 bytes still unread per
map. Walk them the same way: measure a record, anchor it against something already decoded, and only
then name it.

### Documentation drift, corrected

`README.md` had gone stale enough to misrepresent the project: "3D preview: not started", "~40% of
skeletal meshes decode" (98.1%), "130 animations" (16,031), and UE5 import presented as the goal
when it is an excluded feature. Rewritten against the pinned sweeps. **HANDOFF stays authoritative;
the README is now consistent with it.**

## Session of 17 Aug 2026 (later) ? brush placement, settled against the compiled world

The handover's first Phase 2 polish item was: `LevelSceneBuilder.BrushPlacement` is `LIKELY` and
barely exercised, 0 of Lighthouse's 230 brush actors is rotated, **sweep the other maps for one that
is** ? because that would be the sample that settles the composition order.

**Both halves of that were answered, and the second one only because the ground truth turned out to
be sitting in a field this project read and threw away.**

### The sweep: 17 rotated brushes in the whole game, and every one is a volume

All shipped maps, every brush actor: **13,443 brushes, 0 scaled, 17 rotated, 13,255 with a
PrePivot**. The 17 are on `6-Resi` (2), `6-Slums` (3) and `ChallengeRoomCombat` (12), and all 17 are
`ShockDamageVolume`s ? gameplay regions, never drawn.

So **no visible brush anywhere in BioShock exercises the rotation or scale part of the placement
rule**, and no rendered evidence can ever settle it. `LevelSceneTests` asserts that as a fact that
can fail: 0 scaled, and every rotated brush a `Volume`. If a future session finds it red, it has
found the sample this one could not.

### The ground truth: `FBspSurf.Actor`, which was being read and discarded

CSG built the compiled world **from these same brushes**, and every surface names the brush actor it
came from. So the same polygon exists twice ? once in brush space in a `Polys`, once in world space
in the `Model` ? and the placement rule is whatever maps one onto the other. That field was already
being parsed for its length and dropped; it is now on `BspSurface`.

Matching on the **plane** rather than the vertices, because CSG clips a brush against its neighbours
but a clipped polygon stays in the plane it was cut from. Six maps, **33,632 world polygons**:

| candidate | within 1 cm of a plane of its own brush |
|---|---|
| **`Location - PrePivot`** (the rule in use) | **33,631 / 33,632 = 100.0%** |
| the full actor transform | 33,631 / 33,632 = 100.0% |
| `Location` alone | 982 = 2.9% |
| no placement | 297 = 0.9% |

Worst matched offset **0.82 cm**. `BrushPlacementTests`. **The translation is now `CONFIRMED_BYTES`**
and the pre-pivot is load-bearing ? dropping it costs 97% of the match, which is what makes the pass
a measurement rather than a wide tolerance.

**The rotation and the scale are still `UNKNOWN`**, and the first two rows say why: they are
identical because no brush that reaches the built world carries either. This is the honest limit of
what shipped data can say.

Two things fell out that are worth keeping:

- **`0-Lighthouse Brush12` is the one polygon that misses**, by 2.09 cm ? an order of magnitude past
  the tolerance and unexplained. Recorded, not tuned away. It may be the same effect as the 12
  world polygons that sit >1 cm off their own plane.
- **A subtracted brush's face points the other way.** 25,726 of the matched polygons oppose the
  normal of the source poly they came from and 7,905 agree. Rapture is mostly carved out of solid.
  The first attempt matched only same-facing planes and scored 23.5%, which looked like a broken
  placement rule and was a broken *metric*.

`docs/research/bsp.md` ?5.7 has the full write-up; ?6 loses the brush-transform entry and the stale
"the built world is not implemented" line, which the previous session had already falsified.

### The other polish item, closed by counting: brush polygons with no UV

`bsp.md` ?4 said a zero texture axis is real data and "how many is not yet counted". Counted:
**17,802 of 93,264 brush polygons (19.1%) carry no texture axes**, `TextureU` and `TextureV` always
absent together, and **none of the 17,802 names a material**. Missing axes and missing texture are
the same polygons, so nothing in the brush set would ever be drawn with a collapsed UV ? content,
not a decode gap. Both halves are asserted.

## Phase 2 ? where it actually stands

**Measured 16 Aug 2026, on the first run the level analyzer has ever had.** `Core/Level` was written
in an earlier session and had **no test and no caller** ? nothing in the repository executed it ? so
its state was unknown rather than good. `LevelAnalysisTests` now runs it on a shipped map.

`0-Lighthouse` ? 22,780 exports, 596 imports:

| | |
|---|---|
| Actors | **1,877** |
| Actors whose property walk failed | **0** |
| Unresolved references | **0** |
| External references | 1 |
| Actors with a static mesh | 912 (171 distinct meshes) |
| Actors with a skeletal mesh | 132 (20 distinct) |
| **BSP brushes** | **230** |
| Lights | 318 |
| Volumes | 137 |
| Actors with geometry of any kind | 1,274 |

**The actor layer is in good shape and is not the work.** Placement, class defaults, mesh references,
material overrides, attachment parents and BSP brush references all resolve, and nothing is silently
truncated.

**All four of Phase 2's items are now done.**

1. ~~**BSP geometry.**~~ **Decoded** ? `docs/research/bsp.md`. See below.
2. ~~**A level scene exporter.**~~ **Done.** `LevelScene` / `LevelSceneBuilder` assemble a map;
   `LevelSceneExporter` writes it; the **Level tab** in the application drives it.
3. ~~**Lights.**~~ **Done.** 465 on `0-Lighthouse`, with colour, brightness and radius.
4. ~~**A world-bounds sanity check.**~~ **Done, and the guess was right.**

**Do not start by rewriting `Core/Level`.** It measured clean on its first run.

### The level pipeline ? what exists now

```
LevelAnalyzer  ?  LevelContext   (actors, references ? was already here)
                        ?
LevelSceneBuilder ? LevelScene   (placed geometry + lights, in the studio's basis)
                        ?
LevelSceneExporter ? .level.json + .obj        LevelService ? the Level tab
```

`0-Lighthouse`, measured: **1,877 actors ? 1,141 placed objects** (911 static meshes, 230 BSP
brushes), **465 lights**, **2,181,021 triangles**, **0 skipped**. The OBJ is 112 MB; the scene JSON
keeps instancing at **401 assets for 1,141 instances**.

**Rendered and looked at, and this is the load-bearing verification:** the placed static meshes
assemble into **Rapture's skyline** ? recognisable art-deco towers, upright, correctly spaced.

**That render promoted `ActorTransform.ToMatrix` from `LIKELY` to `CORROBORATED`.** Its own remarks
said it was "not yet checked against a rendered level, which is the evidence that would raise it";
a level is the first thing this project has built that composes actor transforms at all. It is
**not** `CONFIRMED_BYTES`: 1,223 Lighthouse actors carry a rotation, but a mostly-yaw level would
look right under several conventions.

**`LevelSceneBuilder.BrushPlacement` is the weakest claim in the pipeline and is labelled `LIKELY`.**
A brush is placed by `Location - PrePivot` with no rotation or scale. **0 of Lighthouse's 230 brush
actors carry a rotation or a scale**, so "the level assembles" is *not* evidence for the composition
order ? the test records that count precisely so a future session does not read confidence into a
green result.

### The level viewport ? walk through a map

**`docs/GUI.md` ?"Walking through a level" is the detail.** "Walk through it" prepares the map ?
about five seconds ? and gives a ghost camera: WASD, Q/E, drag to look, wheel for speed.

**The performance work here is the design, and it came from measurement.** Drawing all of
`0-Lighthouse` on the CPU rasteriser takes **~1.6 s a frame**. Frustum culling alone only reaches
1.15 s: it keeps 399 of 1,141 instances and 883,415 of 2,181,021 triangles, because Rapture's
backdrop city is entirely in view and is most of the map's geometry. **And the frame is bounded by
pixels, not triangles** ? 100,000 triangles cost **423 ms at 960?600 and 147 ms at 480?300**. So the
viewport spends a triangle budget on whatever occupies the most screen *and* halves resolution while
moving. `LevelViewportPerformanceTests` holds all of it.

**Culling must sit above the renderer.** `SoftwareRenderer` projects and buckets every triangle it
is given before touching a pixel, so an off-screen triangle is not free.

**There is a GPU path, and it is the one thing here no test covers.** `LevelGlViewport` is an
Avalonia `OpenGlControlBase` ? no new dependency; `Avalonia.OpenGL` ships inside the Avalonia
package. Avalonia's headless renderer has no GL context, so **every snapshot and pixel check in the
suite comes from the software path**, which is kept rather than replaced. Both consume the same
culled selection and the same camera. If GL fails at any step the window falls back and *says so*.

**What could be tested about it, was.** `GlMatrixConventionTests` pins the claim the whole GL path
rests on: `Matrix4x4` is row-major and row-vector, GL with `transpose = false` reads those bytes as
columns and therefore sees `M?`, and `M? ? v` equals `v ? M`. The companion test proves that
transposing on upload as well ? the intuitive move ? gives a *different* answer, so the pair is not
vacuous. Getting it wrong turns the level inside out and looks like a camera bug.

**Textures work.** Resolved per asset rather than per instance (402 distinct assets against 1,142
placements) and capped at **256** rather than the preview's 1024, because a level holds hundreds at
once and the sum is what matters. Measured on `0-Lighthouse`: **145 textures over 309 of 535
surfaces**.

**A texture fault shipped twice, and a user found it both times by looking.** BSP parameterises its
surfaces in *texels* and the engine divides by the bound texture's size.

1. `NormaliseUvs` was written to do that and **was never called** ? every BSP surface drew with UVs
   running 0?512 and tiled hundreds of times.
2. Wiring it up, the division used **the loaded mip's size, not the texture's authored size**. A
   level caps textures at 256, so a 2048-pixel wall divided by 256 still tiled **eight times too
   often**. A mip is a scaled copy and does not change the parameterisation; the authored
   `USize`/`VSize` is what UVs are relative to.

**Nothing in the suite could see either**, and the *test* was wrong too: it averaged over two
million static-mesh vertices, which are known-good and never take this path, so it reported an
unchanged median while the fix it was checking made no difference to it. It measures **textured BSP
surfaces only** now ? median **6.2**, against a raw peak of 348,160.

**The lesson worth keeping: a wrong UV *scale* is still a texture on every pixel.** Counts, coverage
and even a textured-vs-untextured comparison all pass. Only the magnitude itself shows it.

**A test assertion here was wrong and is recorded as such.** It asserted "more than 15% of drawn
pixels carry a colour cast" and failed at 11% on a render that is visibly correct ? Rapture's
exterior is grey-green concrete under water, so that threshold measured the art direction rather
than the pipeline. It compares a textured render against an untextured one now (**51% of drawn
pixels differ**), which fails for the right reason.

### The GUI ? three tabs now

**Animated**, **Static** and **Level**. The two asset tabs are **one browser filtered two ways**, not
two browsers ? they split on whether an asset carries a rig, which is the distinction that changes
how it is worked with. The markup lives in `AssetBrowserView` and each tab hosts an instance, but
both bind to the same view model, so selection, details and preview are shared and cannot drift.
Textures and materials sit with the static assets.

Both totals count the workspace rather than the catalogue: "Everything (14,380)" beside a list that
can only reach the rigged half stated something untrue, and reads "All rigged assets (1,889)" now.

**Three faults were found by rendering the tab and looking at it, with every test green:**

- The empty-state prompt bound `IsVisible="{Binding !SelectedLevel}"`. **`!` does not negate a
  non-boolean binding in Avalonia**, so "Choose a map on the left" rendered on top of a fully-loaded
  level. Use `ObjectConverters.IsNull`.
- The **asset** extraction bar sat under the level panel offering "Extract selected" / "Extract all
  shown", which reads as though those buttons extract the level. It is hidden on the Level tab now.
  *A control that is merely irrelevant still makes a claim.*
- The level's own Extract button was below the fold.

All three are pinned by `LevelUiTests`, which also had to be corrected: its first snapshot captured
the **Assets** tab, because selecting a level in the view model does not change which tab is
showing. A snapshot of the wrong tab proves nothing.

The size estimate is stated before the job runs ? measured at ~54 bytes per triangle, so Lighthouse
reads "about 112 MB", which is what it writes. Bulk extraction size has been reported as a fault in
this project once already when it was really an unstated cost.

### BSP ? the source brushes are decoded, the built world is documented

**`docs/research/bsp.md` is the note; read it before touching any of this.** Two different things
are called BSP here and confusing them wastes a session:

| | where | state |
|---|---|---|
| **Source brushes** ? the designer's convex solids | one `Polys` export per brush | **`CONFIRMED_BYTES`** |
| **The built world** ? nodes, surfaces, vertex pool, lightmaps | one large `Model` export | **`CONFIRMED_EXTERNAL`, not implemented** |

`0-Lighthouse` ships 285 `Model` exports; 284 are ~1,700 bytes and **one, `Model1`, is 312,400** ?
that is the built world, and the size distribution is what separates them. On `1-Medical` it is
8.6 MB.

| measured | |
|---|---|
| Map packages containing brushes | **21 of 161** |
| `Polys` exports walked | **16,926** |
| ?landing on the **exact** final byte | **16,926 (100%)** |
| Polygons / vertices | **93,264 / 374,372** |
| Polygons naming a material | **59,495 ? every one resolves to a material class, none to an actor** |

**A brush carries its own surface**, so brush geometry can be textured by the existing material
resolver rather than drawing bare. Rendered and looked at: the Lighthouse rotunda comes out as a
recognisable octagonal room shell.

**BSP winds the OPPOSITE way from the game's meshes**, and this is the one decoded container whose
winding must be reversed after the basis reflection. Meshes must not be ? see ?4. Measured over all
21 maps (0 agree / 93,264 disagree in shipped order; 93,264 / 0 for what the reader emits) and
confirmed a second way by enclosed volume (254 positive, **0 negative**).
`ANIMATION_COORDINATE_SYSTEM.md` ?6.1 and ?9, which now lists **five** conversion boundaries.

**The `Model` container now walks too** ? `ModelReader`. That is the link a level needs and the
export table does not state it: of Lighthouse's 285 `Polys` exports only 60 have a `Model` outer, 54
have a `SkeletalMesh` and 171 have none. All **16,926** `Model` exports in the game land on a
reference that resolves to a `Polys` export.

### The compiled world is decoded ? this is what a level actually is

**`BspWorldReader`, `CONFIRMED_BYTES`.** `FBspNode`, `FBspSurf` and the vertex pool are read and
drawn. Before this a level carried only source brushes and placed meshes, so a map was a skyline and
props **with the rooms missing** ? which is what a user reported as "floor bsps aren't working".

| across all 21 maps | |
|---|---|
| Compiled worlds | **21** |
| Polygons / triangles | **81,566 / 227,911** |
| Polygons >1 cm off their own plane | **12 (0.015%)** |

**Planarity is the check that proves the layout**, because three independent arrays ? nodes, vertex
pool, points ? have to agree, and a wrong offset cannot make polygons coplanar by accident. **The
figures match Nyko's exactly:** `1-Medical` gives 7,125 nodes, 3,386 surfaces and worst distance
**0.25** with zero off-plane, which is his number to the digit.

**The landmine, recorded:** `NumVertices` is a **byte at +78**, not the int32 at +88 an initial
reading suggests (+88 gives 64% planarity failures). Note that **+97 also scores 100%** on the
offset probe ? the score does not choose between them, the field layout does.

Winding is the same as the source brushes' (0 of 758 agree in stored order), and
`PF_Invisible`/`PF_FakeBackdrop`/`PF_Portal` surfaces are excluded ? 15 of 370 on Lighthouse ?
because they are zoning and portal geometry the game never draws.

**Still not read:** lightmaps (?5.5 of the note has the full descriptor chain), CSG, and
`FBspSurf +20`, where Nyko's spec, his parser and his lightmap note give three different answers.

### Lights ? ?C.6 of a file nobody had opened answers it

BioShock writes light parameters with **different types** from stock UE2.5, which is exactly why
they sit unread in `UninterpretedProperties`:

| field | BioShock | stock UE2.5 |
|---|---|---|
| `LightBrightness` | **FloatProperty**, 0.0?3.1, median 1.0 | byte 0?255 |
| `LightColor` | **StructProperty `Color`** ? FColor BGRA | `LightHue` + `LightSaturation` bytes |
| `LightRadius` | **FloatProperty**, 0?120,000 units, median 2048 | byte, radius = 25 ? (b+1) |

`bStatic`/`bNoDelete` are never written to disk. Reading three properties is the whole job.

### The world bounds ? one actor, and it is a sentinel

`Z = 262144` is Unreal's `HALF_WORLD_MAX`, and **exactly one actor of 1,874 is there**: a `Script`
actor at `(496, 1088, 262144)`. Excluding it, the level's maximum Z is **12,288** ? a twenty-fold
difference. **An exporter that sizes a scene from the raw extents sizes it from a sentinel.**
`BspGeometryTests.TheLevelsExtentIsSetByOneActorAtTheEngineWorldBoundary` pins it.

## The four reference projects in the repo root ? how far each has been mined

They are gitignored and must stay so; the Havok one is licensed material. **Reading these first is
now project policy**: the hand blocker cost three sessions of internal measurement and was settled
by one function in the Havok SDK, and the section table above came from Nyko's SDK after this
project failed to find it from bytes alone.

| folder | mined |
|---|---|
| `hk2012_2_0_r1` | **2 files of 114** in `Source/Animation`. `hkaSplineCompressedAnimation.h`/`.inl` only. |
| `Bioshock1REMSDK-WIP--main` | `bioshock1-bsm.md` ?C.1, ?C.2, ?C.4, ?C.5, ?C.6; `BioShock_Materials_And_Shaders.md` in full; `BioShock_Texture_Lightmap_Format.md` ?5??6; **and `tools/level_editor/src/bsp_parser.cpp` + `viewport.cpp`, which render BSP.** Four findings so far. **Read this project's code as well as its prose** ? the editor carries measurements the documents do not, and contradicts them in one place. |
| `UModel-master` | **`UnTexture2.cpp`, `UnMeshBioshock.cpp`, `UnMesh2.h`'s `FSkelMeshSection`, `UnCore.h`'s `TRIBES_HDR`.** Source of two findings this session ? the DXT5N texture format and the skeletal section table. Its BioShock branches are extensive and the rest is still unread. |
| `Unreal-Library-master` | **`Engine/Classes/UPolys.cs`, `Engine/Types/Poly.cs`, `Branch/PackageObjectLegacyVersion.cs`.** Source of the `FPoly` field list ? the first finding ever taken from this project. The rest is unread. |

**The policy paid again, and quickly.** `BioShock_Materials_And_Shaders.md` had never been opened; it
was read this session and its first two sections settled the largest open item in materials in
minutes ? 515 meshes went from flat grey to textured ? after the project had spent two sessions
measuring around it. **Read the reference projects first.**

Highest-value unread material, in order:

- **`Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Reading_Textures.md`** and
  `BioShock_Texture_Lightmap_Format.md` ? 247 lines, never opened, and the obvious place to look for
  `Format` ordinal 12 (open question 11c, 274 normal maps that will not decode).
- **`UModel-master/Unreal/`** ? mesh readers, for ?6.2.
- **`hk2012_2_0_r1/Docs/?User_Guide.pdf`** ? never opened. Likely settles `blendHint` and the
  animation-binding contract outright.
- `hkaSkeleton.h`, `hkaAnimationBinding.h`, `hkaSkeletonMapper.h` ? we carry `Unknown*` fields and
  two carried-but-unused flags on inference.

**Dead end, do not re-check:** `hkaSignedQuaternion` ships declarations only, no `.inl`, so this SDK
cannot confirm the ThreeComp40 bit layout. It stays `CONFIRMED_BYTES` by continuity inference.

**Beware one divergence:** Nyko's and UEViewer's `UStaticMesh` vertex is 24 bytes with packed
normals; Remastered's is 48 with full float basis vectors. Both right for their own target. A
finding ported from either may need the record widening.

## Open, recorded, deliberately unfixed

- ~~**`smg/smg_fire`** ? one animation of 16,031 where `Bip01_R_Forearm` and `Bip01_R_ForeTwist`
  collapse.~~ **The "one animation" framing was wrong and is corrected in ?6.0c**, which supersedes
  this entry: it is a family of four ? `PI_Fire`, `PI_Fire_B`, `PI_fire_C` and `smg_fire`, all on
  `AggressorBabyJane`, all 54 tracks against her 73 bones, all worst on frame 0. The rest of the
  entry still stands: not additive (every animation in the game is `blendHint 0`, by census), and the
  answer is probably in `sampleTranslation`, which is not in this SDK build. Four candidate causes
  have been eliminated with evidence; see ?6.0c before proposing a fifth.
- **Bulk extraction is ~140 GB and hours long, and that is a deliberate open item.** Reported as
  "extraction is not working"; it is not ? `ExtractionUiTests` drives the real command and the
  pipeline writes correct output (a 49-asset sample produced 2,478 files, including 457 per-animation
  FBXs for `AggressorBabyJane`). The problem is that "Extract all shown" from the default view is
  2,000 assets, characters first, and the buttons grey out while it runs. Compacting the scene JSON
  took it from ~350 GB to ~140 GB. **The remaining bulk is animation track data written twice** ?
  once as floats in the scene JSON, once in the per-animation FBX files. Omitting the tracks from the
  JSON when FBX is also selected is the obvious fix and was **explicitly deferred by the user**, not
  overlooked. So were a size warning before a large job, and keeping the UI responsive during one.
- **Skeletal meshes cannot be split by material** ? ~~no section table in that container.~~
  **That reason was wrong: the table exists.** `UnMeshBioshock.cpp`'s `FStaticLODModelBio` opens with
  `TArray<FSkelMeshSection>`, nine `uint16`s each, commented "1 section = 1 material" ? item 6 under
  NEXT CLAUDE SESSION, open question 11d, `reference-comparison.md` ?3a. So this is open because the
  work is not done, **not** because the data is missing, and it needs the payload walked from the
  front rather than the vertex chain searched for. The diagnostic sweep counts **153** meshes in this
  state, so the scale of it is known rather than estimated.
- ~~**Five material classes are read as if they were `Shader`** ? `FluidShader`, `PlantShader`,
  `LightBeamShader`, `MaterialSwitch`, `MaterialSequence`, `LayeredShader`. 522 meshes resolve a
  material binding zero textures because of it.~~ **Superseded ? this was fixed.** A texture binding
  is now an `Object` property resolving to a `Texture` rather than a slot name on a list, and a
  `Texture` named in a slot is itself a material. `mesh-no-diffuse` fell 755 ? 240. What is left is
  not all fault: `LightBeamShader` (64) genuinely has no base colour, and `MaterialSwitch` (38) and
  `MaterialSequence` (4) are Modifiers wrapping sub-materials that nothing follows yet ? that is the
  clearest remaining piece. Open question 11b.
- ~~**Texture `Format` ordinal 12 is undecoded** ? 274 exports, 64 distinct names, every one a normal
  map.~~ **Superseded ? it is decoded.** It is **DXT5N**, not the 3DC/BC5 one reference project calls
  it; all 274 exports now decode and `texture-undecodable` fell 320 ? 46. Open question 11c,
  `reference-comparison.md` ?1. **What remains under that heading is different**: the 46 exports
  carrying no `Format` property at all, whose 42 distinct names are all editor sprites and engine
  placeholders. Whether they hold pixels is `UNKNOWN`.
- ~~**Every weapon in the `NEWPlayerHands` animations is backwards.** `REPORTED, NOT YET REPRODUCED`~~
  **FIXED, 16 Aug 2026.** Cause: the viewport chose the attachment's socket **by bone**, and nine of
  the hands' sockets share the bone `R_grip`, so every weapon got `Wrench` ? which carries a 180?
  turn about Z where `Pistol` and `Chem` carry identity. See ?4 and
  `docs/research/firstperson.md`. The account below is kept because its *reasoning* was wrong in an
  instructive way.

  It matters more than its position in this list suggests: **the first-person pistol is this
  project's target case** (?1) and its hands-and-weapon set is the most-checked asset in the
  repository. If the weapons are oriented wrongly, then a great deal of validation that reads green
  is green on a wrong result ? which is the exact failure mode ?4 exists to record, twice over
  (the mirrored years, and the wrong section/material pairing).

  **Do not fix this by rotating the weapon.** Candidate causes worth measuring before changing
  anything, none of them established:
  - **`FCoords` may be a world-to-local basis, not local-to-world.** Unreal's `FCoords` is
    conventionally the *inverse* transform. `SkeletalMeshReader.ReadSocketCoords` builds the matrix
    from the axes as rows and uses it directly. A transposed rotation looks exactly like "backwards"
    for a 180? yaw. **Note the counter-evidence:** every first-person weapon socket is recorded as
    identity, and a transpose of identity is identity, so this alone cannot explain the first-person
    case ? which is what makes it worth measuring rather than assuming.
  - **The weapon rig's own root.** A weapon skeleton is rooted at `R_grip` and is drawn with the
    host's socket-bone transform. Whether the weapon's root reference orientation is being composed
    in or discarded has never been checked.
  - **The basis conversion is not a candidate** without new evidence: `C = diag(1,-1,1)` reflects
    left/right, and every mesh, skeleton and animation goes through it once at four boundaries. A
    fault there would mirror the whole scene rather than turn one attached rig around. See
    `docs/research/ANIMATION_COORDINATE_SYSTEM.md` before touching any transform.

  **How to check it honestly:** render it and look. `BIOSHOCK_RENDER_SNAPSHOT` writes the viewport
  offscreen. The measurement that would settle it is the weapon's muzzle-to-grip axis against the
  hands' forward axis, on several weapons ? not one screenshot of the pistol, which is the asset
  this project has repeatedly over-generalised from (?4, "the first-person rig is not a
  representative sample").
- ~~**The shotgun cannot be attached at all, and it is one of the seven player weapons.**~~
  **FIXED, 16 Aug 2026 ? and the route first proposed for it was wrong.** The handoff suggested
  offering it on the root-bone test that promotes every other weapon to `Confirmed`. **Measured, and
  that is dead:** `WP_Shotgun`'s rig is rooted at **`SG_Body`**, and its three bones are
  `SG_Body, SG_Pump, SG_Shell` ? there is no `R_grip` in it at all, where every other weapon has one
  as its root. So the shotgun has *neither* a socket naming it *nor* the root-bone match.

  What resolves it is a third relationship the game does state: **the hands carry their own
  `Shotgun` animation set**, and `WP_Shotgun` is the only shotgun viewmodel.
  `AssetContextService.WeaponsNamedByAnAnimationSet` offers it on that, at the bone the rig's other
  weapon sockets use, and reports it **`Likely` ? never `Confirmed`**, with evidence separating the
  stated half (the animation set) from the inferred half (the attach point). Rendered and looked at:
  the shotgun sits in both hands, right hand on the stock and left at the pump.

  The original account follows, because its *evidence* stands and only its proposed fix was wrong.

  Checked against the game's own weapon list (wrench, pistol, machine
  gun, shotgun, grenade launcher, chemical thrower, crossbow):
  - the hands carry its animation set ? `USharedSkeletonAnimationMetadata_EmptyFidgetShotgun`, beside
    `...Pistol`, `...Crossbow`, `...Chem`, `...Launcher`, `...TommyGun`;
  - its viewmodel ships with a rig ? `WP_ShotgunMesh`, `UAPW_WP_Shotgun`,
    `USharedSkeletonDataMetadata_WP_Shotgun`;
  - **but `NEWPlayerHands` declares no `Shotgun` socket.** The nine sockets on `R_grip` are `Pistol`,
    `Wrench`, `Crossbow`, `Chem`, `TommyGun`, `Launcher`, `IrritantBall`, `WrenchRibbonSocket` and
    `PlayerGathererGun`.

  `AssetContextService` drives its weapon sweep from the host's sockets, so with no socket naming it
  the shotgun is never offered ? it cannot be previewed with the hands, and it never reaches the
  export as a two-rig set. **Six of seven weapons work and the seventh is invisible**, which is why
  this went unnoticed: nothing fails, the picker simply has one fewer entry.

  **Do not fix it by inventing a socket.** The evidence-backed route already exists: `Assess`
  promotes a candidate to `Confirmed` when *the weapon's own skeleton is rooted at the bone*, which
  is a stated relationship rather than a name match, and `WP_Shotgun` is rooted at `R_grip` like its
  siblings. Offering weapon groups by that test ? for a first-person host only ? would reach the
  shotgun without weakening the rule that keeps NPCs from being handed viewmodels. Not implemented;
  it changes attachment resolution and wants its own measurement.~~

  **That proposal was wrong and the clause "`WP_Shotgun` is rooted at `R_grip` like its siblings" was
  an assumption written down as a fact.** It is rooted at `SG_Body`, and one probe settled it.
  **The rig roots are worth having:** every weapon viewmodel is rooted at `R_grip` ? `WP_Pistol`,
  `WP_TommyGun`, `WP_Crossbow`, `WP_GrenadeLauncher`, `WP_ChemicalThrower`, `WP_PlasmidEquip`,
  `WP_GathererGun` ? and `WP_Shotgun` alone is not.
- **`PlayerGathererGun` is not a player weapon**, and the socket of that name should not be read as
  one. "Gatherer" is the developers' own name for a **Little Sister** ? the hands also carry
  `GathererAttach` and `GatherSave` sockets and `Gatherer` notifies. It is listed among the hands'
  attachments because it hangs off `R_grip` like the weapons do, and it resolves no animation set of
  its own, so anything that poses it borrows another weapon's clip. Corrected on the user's word,
  16 Aug 2026, after it was described here as one of the guns.
- **The `Melee` socket** ? could be the wrench, pipe, machete, rake or shovel. Left unresolved
  rather than given whichever sorted first.
- **Splicer variant ? animation set** ? nothing in the data links a *particular* variant to a
  *particular* behaviour set (spider, nitro, leadhead). Needs evidence found, not a mapping invented.
- **?6.0b** is closed: the left hand now reaches 4.36 cm from the grip.

6. **Phase 2 (level extraction) is unlocked when 1C finishes** ? the user has confirmed this. 1C's
   remaining item is the Asset Inspector; when that lands, Phase 1 is frozen and Phase 2 may begin.
   Groundwork already exists in `src/BioShockStudio.Core/Level/` ? **read it before writing anything
   new**. The unlock is permission to start the phase, not permission to rewrite what is there.
