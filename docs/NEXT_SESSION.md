# BioShockStudio — next session

Copy the block below as the opening prompt for a new agent. Everything it needs is in the
repository; this file only tells it where to look and what not to re-derive.

---

## Read first, in this order

1. `CLAUDE.md`, then `docs/ENGINEERING_RULES.md` — how to work here. Non-negotiable. §2 (user
   instructions are the task boundary), §14 (curiosity control), §55 (a worked example of getting
   scope wrong), §60 (standing user instructions).
2. `docs/HANDOFF.md` — institutional memory. §4 landmines and §7 working rules, then the section
   **"Session of 17 Aug 2026 — the viewport session"**, which has the measurements you inherit.
3. `docs/research/ANIMATION_COORDINATE_SYSTEM.md` — the basis policy. Required before touching any
   transform. `C = diag(1,-1,1)`, applied at **five** decode boundaries and nowhere else, and §6.1
   for the one container whose winding is reversed.
4. `docs/research/bsp.md` — the level format, both halves of it.
5. `docs/research/reference-comparison.md` — what each reference project says and where they
   disagree. **Read the reference projects before deriving from bytes.** That policy has now paid
   off eight times; the compiled world came out of one in an afternoon after being recorded as
   `UNKNOWN` for the whole project's life.

## First action — establish the baseline

```bash
dotnet build
dotnet test --filter Tier=Fast     # ~30s; run this constantly
dotnet test                        # ~20 min; the figure to report
```

Expect **390 passed, 0 failed, 0 skipped** (~21m17s; it was 13 min at the start of 17 Aug, before
the whole-game sweeps that settled brush placement and the section tables). Record what you actually get. If anything
fails, classify per §24 before touching code. `DocumentedFiguresTests` asserts the headline numbers
in `docs/QUALITY.md` — if it goes red the *documentation* may be what is wrong. Never relax it.

**Do not build or publish while the suite is running** — testhost locks the DLLs (MSB3027).

## State of the tree

Branch `feature/fbx-materials-gui`, **no remote**. Working tree clean. Do not push, do not rewrite
history. Commit as you go in logical groups — the user has asked for this and it overrides the
default "don't commit" rule. Review every diff first.

Keep `artifacts/app` current:
`dotnet publish src/BioShockStudio.App/BioShockStudio.App.csproj -c Release -o artifacts/app`
(close the app first — a running instance locks the DLLs).

## The one thing to internalise

**Six faults shipped in the last session and a user found five of them by looking at the screen.**
Every one passed the full suite. The table in `HANDOFF.md` lists them. The pattern:

> **A numeric check cannot see a wrong quantity that is still present.** Textures tiled 512 times
> and every count agreed. Rooms were missing and the scene was self-consistent. Decals drew as
> opaque rectangles and the geometry and textures were both correct.

Where a value has a magnitude, **measure the magnitude**. Where output is visual, **render it and
look** — `BIOSHOCK_LEVELCAM_SNAPSHOT`, `BIOSHOCK_WORLD_SNAPSHOT`, `BIOSHOCK_LEVEL_SNAPSHOT`,
`BIOSHOCK_UI_SNAPSHOT` all write PNGs. Do **not** screen-capture the running app; it captures
whatever is in front and has caught the user's browser before.

## What to do, in priority order

0. ~~The package-open cost~~ — **done**. `PackageCache` holds four opened packages; 45.46 ms
   uncached against 0.0004 ms cached. Wired into texture preview, asset details and diagnostics
   only — the other ~40 call sites are one-shot and can move if a measurement asks for it.

1. **Finish Phase 2 polish** — all four items are now closed.
   - ~~12 world polygons off their own plane~~ — **explained**: snapped corners on oblique planes,
     shipped data, `bsp.md` §5.6b. The deviation is the plane's slope times the distance travelled,
     and all twelve keep a vertex exactly on plane.
   - ~~4 skeletal meshes' sections overrun the index buffer~~ — **closed, and nothing was short**.
     The sections' face counts add up to the buffer exactly on 337 of 337 tables; `FirstFace` is
     simply not where a section begins. `skeletalmesh.md`, and the clamp is gone.
   - ~~Brush placement~~ — **settled**. `Location − PrePivot` is `CONFIRMED_BYTES` against the
     compiled world; rotation and scale stay `UNKNOWN` because no brush in the built world carries
     either. `bsp.md` §5.7, and the HANDOFF section for 17 Aug (later).
   - ~~Brush polygons with no texture axes~~ — **counted**: 17,802 of 93,264, none of them textured.

2. **Lightmaps** — the largest remaining piece, and the route to them is now mapped. §5.3 rules the
   surface out as the home of the index. §5.5b identifies the start of the unread tail —
   `NumSharedSides`, then `NumZones`, verified on 21 of 21 maps against the nodes' own zone bytes —
   and `BspWorld.Layout` reports where the decode stops, so nothing needs searching for.
   §5.5c settles the zone record — an FCompactIndex actor reference plus 36 fixed bytes — and the
   walk lands on the `Polys` anchor on 21 of 21 maps. The array after it is **`Bounds`**, 30,578
   valid FBoxes at a 25-byte stride, **not the lightmap table** — that was asserted from UE2's
   serialisation order and refuted by reading one record. `BspWorld.Layout` reports where it is.
   **Start there**: `LeafHulls`, `Leaves` and `Lights` follow, and 879 to 628,534 bytes remain
   unread per map. Walk them the same way — measure a record, anchor it against something already
   decoded, and only then name it.

3. ~~`FBspSurf +20`~~ — **settled: it is `iBrushPoly`**, 6,372 of 6,372 surfaces naming a polygon of
   their own brush whose normal matches. So the lightmap index is NOT on the surface, and the
   reference note putting it on the node is where to look. `bsp.md` §5.3.

4. **A level FBX exporter.** The scene JSON and OBJ exist; FBX is what the rest of the project
   exports and what a user would expect.

## Reopened, 18 Aug 2026

- ~~**Unreal / UE5 import.**~~ **Reopened — this is now stated as the project's actual end goal**:
  not an import test, but UE5 **as a runtime**, porting the extracted assets to run inside it.
  `ENGINEERING_RULES.md` §60 has the full note. Scope of "runtime" (native plugin reading `.bsm`
  live vs. importing this project's existing FBX/scene-JSON export) was not settled as of this
  entry — check the conversation or ask before assuming which.
- ~~**Audio.**~~ **Reopened.** A second agent (ChatGPT, same repository) is already working on it —
  see the git-safety note in `ENGINEERING_RULES.md` §60. Stage files by name; don't `git add -A`.

## Do not start

- **Bulk extraction size (~140 GB).** Explicitly deferred.
- **§6.0c, the collapsing fire animations.** Four causes eliminated with evidence; needs
  `sampleTranslation`, absent from this SDK build.
- **Rewriting `Core/Level` or the BSP readers.** Both measured clean.

## Traps that bit this session

- **PowerShell destroys non-ASCII in source files.** Use .NET directly and check `git diff` for
  encoding churn before committing.
- **`IsVisible="{Binding !SomeObject}"` does not negate a non-boolean in Avalonia** — it renders
  always. Use `{Binding X, Converter={x:Static ObjectConverters.IsNull}}`.
- **A heredoc to `python` hangs** — python is not installed here; it waits on stdin until timeout.
  Use `Edit`, or `sed`.
- **A snapshot of the wrong tab proves nothing.** Selecting a level in the view model does not change
  which tab is showing.

## The standard that applies

Never promote a hypothesis to a fact. Label confidence always. A measurement that *can fail* is
worth more than one that merely passes — and check what your test is actually measuring, because a
test averaging over the wrong population reported "no change" while a real fix landed underneath it.
Unknown is a valid answer.
