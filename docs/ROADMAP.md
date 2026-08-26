# Roadmap

> Replaces the previous `ROADMAP.md`. That document's execution-step list and gate structure are
> folded in below rather than discarded — this version adds the retrospective ("what's actually
> done") that a pure forward-looking task list doesn't give a new reader. If a number here disagrees
> with `docs/QUALITY.md`, `docs/HANDOFF.md` or a `docs/research/*.md` file, those are the primary
> sources — they're pinned by tests (`DocumentedFiguresTests`) and this document is not. This one is
> for orientation: what exists, what doesn't yet, and in what order the rest is planned.

## What this is

A Windows tool that decodes BioShock 1 Remastered's shipped packages — meshes, skeletons, Havok
animation, materials, textures, audio and whole levels — from raw bytes, with no format assumed
without evidence from the bytes or an external reference. It is simultaneously an extraction tool
(Blender/FBX/PNG/DDS/WAV out) and a reverse-engineering notebook (`docs/research/` records what's
known, with confidence labels, and the code refuses to guess where the notes say `UNKNOWN`).

The project's stated end goal, as of 18 Aug 2026, is **UE5 as a runtime** — porting the decoded
assets into Unreal Engine 5, faithfully first, then improving systems once the port stands. That
reopened two tracks that had previously been deliberately deferred: UE5 import and audio. Both have
since had major progress (see below).

The standing discipline governing all of this is in `docs/ENGINEERING_RULES.md`: minimum correct
change, confidence labels (`CONFIRMED_BYTES` / `PLAUSIBLE` / `UNKNOWN`), read the reference projects
before deriving anything from bytes, and never fill an unknown field with a guess.

## Where things stand today

| Area | State |
|---|---|
| `.bsm` package format | Complete — all 21 map packages plus script packages parse byte-exact. 812,435 exports indexed, 14,378 distinct assets browsable. |
| Havok packfile / object graph | Complete. |
| Skeletons & animation binding | Complete, original bone indices preserved. |
| Animation (spline-compressed) | Complete — **16,031 / 16,031 decode, 0 failures**, 47,560 events. |
| `SkeletalMesh` | **954 / 972 exports decode (98.1%)** — the 18 that don't are all doors. |
| `StaticMesh` | Complete — **all 8,668 shipped exports**, including per-material section tables. |
| Materials | **14,328 walked, 0 partial. 96.8% of meshes carry a base colour.** |
| Textures | DXT1/3/5 + DXT5N (ordinal 12) decode; 8 GB bulk-mip store indexed and resolved per group. |
| Levels — BSP/actors | Compiled world + source brushes + placed actors assemble into a scene. `0-Lighthouse`: 1,141 objects, 2,181,021 triangles, 465 lights. |
| Levels — lightmaps | Descriptor table **complete on all 21 maps** (39,288 descriptors, 45,851 baked-light layers); atlas *binding* proven on **all 20 maps that carry a `LightMaps_BSP` group** (`Entry` has none — see Gate 0 below). |
| Audio — native `Sound` | Complete — **25,848 exports across 21 packages, 100% decode as MP3**, 0 unknown, 0 package failures. |
| Audio — streamed FSB5 | Working — x86 FMOD bridge decodes any subsound to WAV; app has a Streamed Audio tab (65 banks, 10,882 subsounds). |
| Application (GUI) | Asset browser (14,378 assets), 3D preview + animation playback, walkable level viewport (GPU + tested software fallback), Problems panel, audio tabs, profile editor. |
| Export — Blender / FBX | Complete — skinned mesh, armature, actions, sockets, materials; FBX validated by round-trip through Blender. |
| UE5 import | **Full status moved to `docs/UE5_FULL_PORT_PLAN.md`, 25 Aug 2026** (§3, §3a, §9) — that document is now the canonical UE5 record. In brief: rigs verified for real in UE5.7 across every rig category the game ships; levels import with correct placement, materials, UV mapping and multi-material slots, verified live on `1-Medical`; level-placed characters now import as real animated `SkeletalMeshActor`s (25 Aug 2026). No app-facing UI yet. |
| Bytecode / game-logic decode | **BioShock's own game logic is readable.** A working third-party decompiler (`tools/uelib-bridge/`) produces real UnrealScript source for 1,445 classes across 11 of 12 script packages, 0 failures, cross-validated against this project's own independent findings. See Track B in Part 2. |
| Public site / CI | GitHub Pages project page live, deploy workflow committed. |
| Tests | Full suite **550/550 passing** (measured 23 Aug 2026 at `9cb53b2`). See "Test health" below for the stamp and what has been run since. |

---

## Part 0 — Process, before any more feature work

This section didn't exist in the previous version of this file. It's here because the project's
biggest risk right now isn't a missing decode — it's process debt accumulated while four tracks
(UE5, audio, lightmaps, and soon bytecode) ran at once with two AI agents in one working tree. None
of this is theoretical: every item below already caused a real incident this cycle.

**0.1 — First thing to do: classify the 7 failing tests.** `DocumentedFiguresTests` and
`DiagnosticsTests.AReportSaysHowMuchItExamined` are failing because the whole-game `diagnose`
sweep's live counts have drifted from what `QUALITY.md` has written down — in code the lightmap and
audio work this cycle both touch. This is exactly the failure mode `DocumentedFiguresTests` exists
to catch, and the project has a documented history of this exact drift going unnoticed for a whole
session when nobody looked (the "73.9%" figure, wrong in three places at once). Per
`ENGINEERING_RULES.md` §24: find out whether the counts moved because something regressed or
because something correctly improved, *before* touching either the code or the figure. Do this
before starting anything in Part 2 — an unclassified red test is exactly the kind of thing that's
easy to keep stepping around until it's unclear which of six weeks of changes caused it.

**0.2 — Commit in small, reviewed chunks instead of one running diff.** A single ~57-file, ~2,800
insertion diff sat uncommitted in the working tree for over a week, spanning audio, lightmaps, UE5
and GUI work simultaneously. `HANDOFF.md` already says "commit as you go in logical groups"; the
practice hasn't matched it. No rollback point exists inside that week if something goes wrong —
a bad `git clean`, an accidental hard reset, a crash mid-edit. Break the current backlog into
logical commits (by track: audio, lightmaps, UE5 tooling, GUI) and keep future work landing that
way rather than accumulating.

~~**0.3 — Give the two concurrent agents (this session and ChatGPT) lanes.**~~ **Done, 19 Aug
2026.** Went with the lighter option rather than a branch-per-track workflow: a branch scheme only
works if both sessions actually use it, and this session can't enforce that on a separately-run
ChatGPT session. Added an "Active work" claim table at the top of `docs/HANDOFF.md` — add a row
before starting a track, check it before touching a file another row claims, remove it when the
track lands. `ENGINEERING_RULES.md` §60 points at it. The existing git-hygiene rule (stage by
filename, never `git add -A`, small logical commits — 0.2 above) remains the safety net under this
for whenever the table is stale or unchecked.

**0.4 — Finish one track before starting the next.** UE5 import, audio, and lightmaps are all
mid-flight, and Track B (bytecode decoding) is about to become a fourth. UE5 import is the
project's own stated end goal and the closest of the four to actually done (Gates 0–5 above) — it
would compound less to drive that to Gate 5 before opening bytecode research cold, rather than
have five open fronts at once.

~~**0.5 — Look at the pistol inside the UE5.7 editor with human eyes.**~~ **Done, 24 Aug 2026.**
Every "verified in UE5.7" claim before this was log evidence (`Success - 0 error(s), 7 warning(s)`,
a clean `verify_bioshock_import` run) — real, but this project has already learned that "a numeric
check cannot see a wrong quantity that is still present": six faults shipped in one session, every
one passing the full suite, and a user caught five of them by looking at the screen
(`docs/NEXT_SESSION.md`). **The user opened `WP_Pistol` in the UE5.7 Skeletal Mesh editor and
confirmed it directly**: correct geometry, `MI_PistolShi...` material instance bound (not the
missing-material state an earlier screenshot in the same session briefly showed mid-load), wood
grip and worn blued-steel texture rendering correctly. First human confirmation this project has
had of any UE5-imported asset. Static pose only — animation playback in-editor still unconfirmed.

**0.6 — Consolidate the status documents.** There are now six overlapping places project state gets
written down (`ROADMAP.md`, `HANDOFF.md`, `HANDOFF_UE5_IMPORT.md`, `NEXT_SESSION.md`, `QUALITY.md`,
`README.md`'s own status table), and they have already disagreed with each other at least once
(`README.md` said lightmaps were "not started" after `docs/research/bsp.md` had already recorded
the decode work). Pick one canonical status document — this file is a reasonable candidate, since
it already exists to be the orientation layer — and have the others link into it rather than
maintain their own parallel summary. `QUALITY.md` and the `research/*.md` files should stay as the
detailed evidence record; the duplication to remove is the *status* tables scattered across
`README.md`, `HANDOFF.md` and `NEXT_SESSION.md`.

**0.7 — Work Part 2's gate items in order, not by jumping around.** Added 22 Aug 2026, user
instruction — `ENGINEERING_RULES.md` §60 "Roadmap discipline" is the canonical text. Take the next
undone item within whichever gate is active, drive it fully to done — not merely started, not
"mostly working" — before starting another item. This is one level more granular than 0.4 above,
which governs the four concurrent tracks; this governs the numbered items inside whichever
track/gate is currently active.

---

## Part 1 — What's done

### 1. Core format decoding

- `.bsm` package headers, imports, exports, name table — byte-exact on all 21 map packages and the
  script packages (`ShockGame.U` and others).
- Havok packfile parsing, fixups and the full object graph.
- `AnimationPackageRoot`, `hkaSkeleton`, `hkaAnimationBinding` — complete, decoded from a class
  UEViewer itself reports as unknown, with original bone indices preserved rather than remapped.
- `hkaSplineCompressedAnimation` — the game's only compression form (confirmed: every shipped
  animation uses it) — fully decoded, 16,031/16,031 animations, 0 failures.
- One coordinate reflection, `C = diag(1,-1,1)`, applied at exactly five decode boundaries — the
  fix for a mirroring bug that shipped undetected for two years because no numeric check could see
  it (`docs/research/ANIMATION_COORDINATE_SYSTEM.md`).

### 2. Meshes, materials, textures

- `SkeletalMesh`: header, sockets, bone map, geometry, skin weights, tangent basis, per-section
  materials. 954/972 (98.1%) — the 18 failures are all door variants sharing one unread payload
  shape.
- `StaticMesh`: complete, all 8,668 shipped exports, including the section table that assigns
  `Materials[N]` to section *N* (previously multi-material static meshes drew from one material
  only — fixed).
- Materials: the full tagged-property walk, 14,328 materials, 0 partial (`MaterialSwitch`'s own
  candidate array excepted — not yet decoded, tracked as a real gap, see Gate 1 item 4).
  Base-colour resolution went from 7.0% → 73.9% → 91.1% → 96.4% → **96.8%** across four fixes
  (texture-binding rule generalized from a fixed slot-name list to "any Object property that
  resolves to a Texture"; cross-package shader imports followed; a Texture named directly in a slot
  treated as itself a material; and, 19 Aug 2026, a diagnostic-dispatch ordering bug that was
  silently hiding every texture export from the sweep, plus decoding UE2's constant-colour `MipZero`
  texture variant).
- Textures: DXT1/3/5 plus format ordinal 12, identified from bytes and cross-checked against two
  disagreeing reference projects as DXT5N (not BC5/3DC as one reference claimed) — settled with a
  test that fails on the wrong reading rather than merely describing the right one. The 8 GB
  bulk-content mip store is indexed and resolved **per group**, after a duplicate-name bug put one
  group's texture on 340 of 30,831 exports (the final boss briefly drew wearing the wrong texture).
- Whole-game diagnostic sweep (`AssetDiagnostics`/`diagnose` command): 54,335 assets examined, every
  finding pinned by `DocumentedFiguresTests` so a number that stops being true goes red instead of
  rotting silently in prose.

### 3. Animation & rigs

- The "left hand" bug — the project's Phase 1 blocker, three sessions to find — is resolved: an
  omitted Havok channel component is the format's own identity value, not the bound bone's
  reference pose. Left-hand-to-grip distance went from 11.08 cm to 4.36 cm; wrong-side frames from
  3,384/5,984 to 48/5,984.
- Whole-game animation audit (`audit-animations`): 33 packages, 883 wrappers, 399 skeletons, 16,031
  animations, 100% playable, 0 unbound tracks, 0 block-walk misalignments across the entire game.
- Bone-rigidity checking added on top of "plays back" — 252 rows fold a bone into its parent (27 of
  them ≥20 bones), which the earlier audit couldn't see because it only checked for NaN/zero
  frames/unbound tracks. This is an open, tracked gap (§6.0c), not a false "100% correct" claim.
- Weapon-rig attachment: sockets carry a full `FCoords` (previously ignored — 200/332 sockets carry
  an offset, 246 a rotation); animation pairing between the hands rig and a weapon rig is by
  **duration within 15%**, not frame count (frame-count pairing silently dropped weapon motion on
  several sparse-authored clips, discovered because it looked exactly like a broken attachment).

### 4. Levels

- All 21 maps' compiled BSP worlds and source brushes decode: 16,926 `Polys` exports walk to the
  exact byte across 93,264 polygons; brush placement (`Location − PrePivot`) is `CONFIRMED_BYTES`
  against the compiled world.
- A level assembles into a scene and exports as scene JSON + OBJ. `0-Lighthouse`: 1,141 placed
  objects, 2,181,021 triangles, 465 lights, 0 skipped.
- Placed-actor coverage: a byte-backed, class-by-class ledger accounts for every actor in a map
  (8,089 in `1-Medical`) — geometry, skeletal placements, lights, gameplay regions and unclassified
  objects — rather than silently dropping anything the exporter doesn't yet handle.
- **Lightmaps** (18–19 Aug 2026): the descriptor chain that eluded the project for most of its life
  is now fully walked — `iLightMap` at `+96` settled with 42,887/42,887 in-range matches; the full
  tail (bounds → `LeafHulls` → `FLeaf` records → compact-reference arrays → `RootOutside`/`Linked`)
  lands on the lightmap descriptor table on all 21 maps; 39,288 descriptors map one-to-one onto
  their worlds' surfaces with 45,851 baked-light layers. The `WorldToLightMap` matrix and UV
  packing are `CONFIRMED_BYTES` (234,404/234,404 vertices land inside their declared atlas tile).
  **Atlas-pool binding, 19 Aug 2026: proven on all 20 of 21 maps that carry a `LightMaps_BSP`
  group, up from 11.** The gap was the pool-search's count floor (`>= 8`, a range read off the
  first 11 maps rather than a real constraint) — `0-Lighthouse` turned up a genuine 5-entry pool,
  so the floor is 1 now, with zero regressions on the original 11's counts or offsets. `Entry` is
  the sole exception, correctly: it carries no `LightMaps_BSP` group at all (a 40-export, ~20 KB
  trivial package, not a real level).

### 5. Audio

Reopened 18 Aug 2026 after being recorded "closed" for most of the project's life; now substantially
complete:

- **Native `Sound` exports**: 25,848 across 21 packages, every one decodes as a valid MPEG Layer III
  frame, 0 unknown, 0 package failures. The full chain from an animation notify event through to a
  playable MP3 is proven end-to-end (`FastReloadPistol`'s reload notify → response → sound name →
  native export → MP3 bytes).
- **Streamed FSB5 audio**: the game's own 32-bit FMOD Ex runtime is driven by a dedicated x86 bridge
  helper (`tools/fmod-x86/FmodFsbDecoder.cpp`) that the 64-bit app/CLI invoke out-of-process — it
  asks FMOD to decode a subsound and locks the FMOD-owned PCM buffer rather than inferring a WAV
  header from FSB bytes. 65 banks, 10,882 subsounds enumerated with their real FMOD-reported names.
  The app has a separate Streamed Audio tab (English + localized `.deu_fsb`/`.fra_fsb` banks kept
  distinct) with decode-and-play and export-WAV.
- **Still open**: per-language routing, `Chance`/`FilteredState` response selection semantics, and
  locating the one sample name (`weapons_pistol_reload_one` was found; not every effect name has
  been chased down this far).

### 6. Application (desktop GUI)

Three workspaces (Animated / Static / Level) sharing one asset browser and detail panel; texture
preview; 3D preview with animation playback and weapon attachment; walkable level viewport (GPU
renderer with a tested software fallback for machines without one); Problems panel driven by the
same `AssetDiagnostics` service the CLI uses (so the window and the command line cannot disagree);
extraction queue; audio tabs for native and streamed sound; a settings/profile editor; system tray
and hotkey support; an in-app update check.

### 7. Export pipeline

- **Blender**: one `.blend` per rig — armature, mesh, textures, materials, sockets, every animation
  as an Action with event markers, weapon rigs and props parented to their sockets, plus a
  `validation.json` that cross-checks bone rest matrices, skin weights and posed positions against
  transforms composed independently from the game's own track data (agrees to within a few
  microns).
- **FBX**: binary 7.4, validated by round-tripping through Blender. One real exporter bug found and
  fixed this cycle — Cluster (skinning) sub-deformer objects were tagged with the FBX name-string
  class suffix `\x01Deformer` instead of the spec-correct `\x01SubDeformer`
  (`FbxSceneBuilder.cs`).

### 8. UE5 import pipeline

**Full detail moved to `docs/UE5_FULL_PORT_PLAN.md` §3a, 25 Aug 2026** — that document is now the
canonical UE5 status record (see Gate 5's note below). In brief: UE5.7's legacy FBX importer
initially rejected every exported file (`File is corrupted`); an exhaustive byte-level audit found
the files were not malformed, and the working fix is pragmatic — a Blender re-export normalization
pass plus a C++ editor plugin restoring socket markers the round-trip drops. Verified live: a pistol
rig imports both meshes and all 12 animations cleanly in UE5.7. No app-facing "export to UE5" button
exists — a command-line/editor-script bridge, deliberately (Gate 5 below).

### 9. Public site / CI

A GitHub Pages project page (`docs/site/`) and its deploy workflow are committed and live.

---

## Part 2 — What's left

Kept in the gate structure the previous roadmap established — it's a genuinely useful shape (package
bytes → core representation → real-data tests → rendered/UE5 validation → exporter/importer → GUI)
and rewriting it from scratch would lose that. Updated to reflect what Part 1 above just closed out.

### Gate 0 — a trustworthy level viewer (active)

UE5 level work can't be judged while the source viewer itself can show the wrong transform or
material.

1. ~~**Window-placement fidelity** — verify actor transforms against the external level editor
   construction beyond the one already-fixed vault case; don't generalize a rotation fix from a
   single view.~~ **Done, 22 Aug 2026 — reopened the same day by a user screenshot, then closed
   properly against the game's own data.** Two rounds:
   - **Round one, and why it wasn't enough.** The reference comparison was committed and run over
     all 12,557 rotation/scale pairs the game ships (worst difference 0.000011). Then a user
     photographed a `1-Medical` skylight rotated wrongly with correctly-rotated neighbours — and the
     new test was green throughout, because **it proves agreement with Nyko's editor, not
     correctness, and the reference composes roll the same wrong way.** A check that compares two
     implementations of a rule cannot find a rule wrong in both.
   - **Round two: `Rx(roll)` → `Rx(−roll)`, settled against the compiled world's BSP tree.** The
     tree classifies any point as inside architecture or open space, so "how much of a rotated
     actor's geometry is buried in solid" is a cost the correct composition minimises — and it
     involves no reference implementation. Across six maps and 147,466 points on rolled actors:
     **negated roll 15.38% buried against 25.85% shipped**, with every other candidate (pre-fix
     pitch, negated yaw, reversed order, reversed-negated) clustered at 25.9–27.3%. Only one
     separates, by 40%. Rendering the reported skylight under all six agrees: only this one
     assembles it into a continuous vault.
   - **The classifier is itself validated, not assumed** — which leaf side is open space comes from
     the shipped AI navigation graph, 7,207 of 7,378 `PathNode`/`PatrolPoint` positions across 18
     maps in a front leaf (97.7%). `BspSolidityTests`.
   - **Independent of the pitch fix**: ±180° roll negates to itself, so the Medical Pavilion arch is
     untouched (2422 units, unchanged to the digit) — which is exactly why the earlier pitch fix
     left this one standing.
   - **Confirmed by the reporting user in the rebuilt viewport** — the skylight draws correctly.
     Every measurement above is a proxy for that check, and this project has a documented history of
     numbers agreeing while the picture was wrong.
   - **The disagreement with the reference is now pinned, not hidden**:
     `TheDivergenceFromTheReferencesRollIsDeliberateAndMeasured` requires all 5,703 observable-roll
     rotations to differ from the raw reference, so a silent revert fails a test rather than quietly
     degrading every level. The pitch-sign fix had been settled by a throwaway probe
   against Nyko's `BuildActorTransform` over six sampled rotations, and the only thing committed
   from it was a single-case geometric assertion on four instances of one mesh in one map — which
   is the same shape of evidence that let the bug ship in the first place. The reference comparison
   is now a committed test (`ActorTransformReferenceTests`): `viewport.cpp`'s `BuildActorTransform`
   transcribed literally (same column-major `float[16]`, same index arithmetic, same multiplication
   order, so it can be diffed against the C++ by eye), compared component-by-component against
   `ActorTransform.ToMatrix` on **every one of the 12,557 distinct rotation/scale pairs the shipped
   maps place an actor at** — all 161 shipped `.bsm` packages, 118,919 actors, 69,068 rotated —
   each composed with that actor's own location and scale. **Worst component difference 0.000011.**
   `ToMatrix`'s label moves from `LIKELY` to `CONFIRMED_EXTERNAL`; the stale `LIKELY`
   cross-reference in `LevelSceneBuilder.MeshPlacement` is corrected with it.
   - **Proved able to fail, which is the half that matters.** Re-run with the pre-fix `+pitch`
     composition, all **6,215** placements pitched far enough to distinguish the two reject it,
     worst difference **60**.
   - **A real finding about why the old evidence was so weak.** Of the game's 12,557 placements,
     **6,167 sit at a pitch of exactly 0° or 180°**, where `Ry(−p) ≡ Ry(p)` and the wrong sign is
     not merely hard to see but produces the *identical* matrix — pinned as its own test rather
     than left as an unexplained gap in the falsification sweep. A further 175 combine a tiny pitch
     with a small scale and fall below float noise. So **essentially half of Rapture cannot express
     this class of bug at all**, which is what "don't generalize from a single view" was warning
     about, quantified.
   - **The scale/rotation composition order is `UNKNOWN` from shipped data, and now says so.** A
     uniform scale commutes with the rotation, so only a non-uniform one can tell `T·R·S` from
     `T·S·R` — and the whole game ships **exactly two** rotated actors with a non-uniform scale,
     both in `1-Welcome`, both only **1.8%** off uniform. This is the same wall the brush placement
     rule hit (0 of 13,443 brushes scaled). The order is instead verified against the reference
     under a deliberately non-uniform **probe** scale, which establishes that the two
     *implementations* agree and is labelled as exactly that — it is not a claim about shipped
     data, and the census is asserted so a future session finding it red has found a better sample.
   - **What the comparison deliberately cannot speak to:** the reference editor does not apply
     `PrePivot` to an actor (it appears in its source only as a name in a skip list), so the
     pre-pivot term is held at zero here. It rests on separate and stronger evidence —
     `BrushPlacementTests`, 33,631 of 33,632 world polygons.
2. ~~**Material fidelity** — resolve remaining blocky/flat BSP surfaces as material/shader-chain
   failures, not by shrinking UVs or tinting base colour.~~ **Done, 22 Aug 2026 — and the census
   came first, which is what stopped this being solved as the wrong problem.** The only coverage
   that existed was one map asserting that more than *half* its surfaces bound a texture. Measured
   properly, the compiled world's material chain was already close to healthy — so the real defects
   were elsewhere, and one of them was much worse than "blocky".
   - **The big one: 11.5% of the compiled world was never drawn at all.** A map with a proven atlas
     pool is drawn from its lightmap batches and the material-only model is skipped entirely — but a
     drawn surface whose first baked-light layer names no atlas the world carries is in *no batch*,
     so it reached the screen through nothing. **23,714 of 206,742 triangles across the 20 affected
     maps**, up to **49.5% of `7-BossFight`** (a whole room) and 37.7% of `0-Lighthouse`. `Entry` was
     the only map at 100% — and it is the one map with no `LightMaps_BSP` group, so it fell back to
     the material path, which is the natural control that identified the cause. Fixed by drawing the
     remainder unlit; **now 206,742 of 206,742 on all 21 maps**, exact, with no map over 100% (which
     would mean double-drawing). `BspGeometry.HasLightMapAtlas` is now the single shared predicate so
     the batch filter and its complement cannot drift. **Rendered and looked at**: the remainder is
     architecture — floors, ceilings, wall panels — not slivers, which a count alone could not have
     told apart.
   - **Then the actual material-chain gap, and item 2's framing was right about it.** Of the game's
     **74,091 drawn compiled-world polygons, 0 name no material** — so a grey BSP surface was always
     this project failing to follow a reference that is present. **1,530 of them name their material
     by *import*** (another package), and `Describe` can only express an export, so every one
     resolved to null and drew untextured. The mesh path has resolved these via
     `IExternalMaterialSource` since it was introduced ("433 slots… draw flat grey"); the BSP path
     never got the branch. Now it has. **0 unresolved**, and 73,188 of 74,091 polygons (98.8%) bind a
     base colour, 875 unpainted by design, 28 neither.
   - **A methodology trap worth keeping.** The first run of the new census reported *no change* from
     a fix that works: `AssetCatalogService.ExternalMaterials` is null until `RegisterInstall`, which
     the app calls at startup and the test did not — so the import branch was a silent no-op **in the
     test only**. Then the end-to-end check was written against `0-Lighthouse`, the fixture's default
     map, where it passed *and would have passed before the fix*, because the Lighthouse names almost
     nothing by import. It is now on `1-Medical` (248 imports) and **verified to fail when the fix is
     disabled**. Picking the convenient map is how a test ends up asserting something true and
     irrelevant.
   - **The census was also rewritten to be affordable.** Its first form went through
     `LevelViewportService` and decoded every texture in every map: 18 GB and 20+ minutes, which is
     the kind of test that stops being run. It now walks the chain without turning any of it into
     pixels; the end-to-end pixel check stays as one map.
   - **Still `UNKNOWN`, recorded not fixed:** the 28 polygons that resolve a material binding no base
     colour and are not a by-design unpainted class. And the **source brushes** are excluded
     throughout — `docs/research/bsp.md` already establishes that 17,802 of 93,264 brush polygons
     carry neither texture axes nor a material, which is content; the import branch was scoped to the
     compiled world and brushes were not swept for imports.
3. ~~**Lightmaps to default-on** — the remaining 10 of 21 maps need their atlas-pool location traced
   the same way the first 11 were.~~ **Atlas-pool binding done, 19 Aug 2026 — 20 of 21 maps proven**
   (the 21st, `Entry`, has no `LightMaps_BSP` group to bind). What's left before this becomes a
   default rather than an opt-in: bind the atlas per pixel (currently per-vertex, via
   `MeshGeometry.BakedLight`) and do a lit/unlit comparison render.
   **Both done, 22 Aug 2026 — and they exposed the real blocker.** The software rasteriser now
   samples the atlas per pixel (`RenderOptions.BakedLightmaps`, off by default) and
   `BakedLightmapRenderTests` renders lit against unlit from inside the level, so baked light can be
   *looked at* in a test for the first time; it previously reached only the GPU viewport, which
   cannot render headless. **The picture is wrong, and now visibly so:** every surface draws a flat
   saturated primary. Cause measured and written up in `docs/research/bsp.md` §5.5e — the atlas is a
   pack of separate coloured layer tiles, a surface commonly has several
   (1,122 of `1-Medical`'s descriptors carry 2-10 layers), and this project applies only
   `Lights[0]`. The layers are not channel-packed: 0 of 1,122 put their layers on one tile.
   **Layer accumulation was then implemented, measured, and reverted** — it is not the answer.
   Summing every layer moved the render from mean luminance 10.5 to 14.0, because **most surfaces
   have only one layer** (1,668 of `1-Medical`'s 3,386 descriptors) and a single-layer surface shows
   the fault just as strongly. **What a tile's RGB means is `UNKNOWN`**, and §5.5e now records five
   measured constraints on any future answer — three light slots per layer, slot position refuted as
   a channel selector, only slot 0 ever singly occupied, and summed layers staying broadly in range.
   **The format branch was narrowed, 23 Aug:** all 14
   `1-Medical` atlas-pool textures declare ordinary DXT1 and decode through the shared BC1 path;
   there is no special format ordinal or header flag (`LightmapAtlasFormatTests`). **A retained
   full-atlas actor-colour probe then corrected the earlier ad-hoc census on 23 Aug:** 868 of 1,039
   single-actor layers carry a directly serialised non-zero colour. Across all four atlas axis
   orientations and all six RGB
   permutations, matched tile/actor cosine improves by at most +0.009 over shuffled actor pairing.
   The simple "tile RGB is this light's radiance" reading is therefore refuted. **Done — resolved
   and default-on, 23 Aug:** the recovered shipped `LayerLighting.hlsl` unswizzles each sample with
   `.yzx`, treats the result as three scalar luminances paired with the layer's three actor slots,
   multiplies each by that light's colour and diffuse-facing term, and adds the passes. The raw-green
   slot-0 bias is independent byte corroboration. The shared renderer now carries every layer and
   actor pairing, the software path composes it per fragment, and the GPU path composes the same
   rule at vertices. The Medical comparison is no longer saturated primaries: mean luminance 19.6,
   deviation 16.6, with coherent local green/warm pools visible in the retained render.
4. ~~**Viewer visibility matrix** — every drawable category needs its own toggle (compiled world,
   static meshes, skeletal meshes, source brushes, gameplay volumes/zones/triggers, lights,
   experimental lightmaps); non-drawable actor classes should be listed explicitly, not silently
   absent.~~ **Done, 22 Aug 2026.** The toggles were already all there — nine of them, covering
   every category the item lists plus unpainted surfaces and effects. **The second clause was the
   outstanding half**, and the data for it had existed for a while in `LevelCoverageReport` while
   reaching only the CLI's `level-audit`; the person who needs it most is the one looking at the
   level. The viewport now carries a "What this level contains" panel built from that ledger. On
   `0-Lighthouse`: 1,877 actors across 64 classes, 1,137 drawn (1,005 meshes/brushes, 132 skeletal
   in bind pose) and **740 in eight categories it never draws** — 321 lights, 157 zones/triggers,
   104 emitters, 54 script graphs, 50 unclassified, 28 navigation, 25 sound actors, 1 with geometry
   in another package — each naming its actual classes so a line can be acted on. `Expander`,
   collapsed by default: it is a reference, not a running commentary.
   `LevelWalkthroughUiTests.TheViewportListsWhatItCannotDraw` asserts the **not-drawn** half
   specifically, since a ledger listing only the geometry would satisfy a count-based check while
   omitting the entire point.

### Gate 1 — complete asset containers

1. ~~**Static meshes**~~ — collision/kDOP tail, LODs and socket metadata; only decode the currently
   opaque collision blocks once a concrete UE5 target (collision/navigation/ray query) is known.
   - ~~**LODs**~~ **answered, 22 Aug 2026: there are none.** 8,668 shipped static meshes yield
     **8,668 geometry chains — exactly one each**. `StaticMeshReader.LevelsOfDetail` exposes them and
     `StaticMeshLevelOfDetailTests` pins the census. This also corrects the reader, whose
     "keep looking and take the densest" rule sat under a comment claiming payloads hold several
     levels; it never has to choose on any mesh in the game. Caveat recorded: a cruder LOD in a
     *different vertex format* would not satisfy the search constraints and is not excluded.
   - ~~**Socket metadata**~~ **answered, 22 Aug 2026: static meshes have none.** Censused across all
     8,668 exports — no `AttachAliases`, `AttachBoneNames`, `AttachCoords` or `Sockets` on any of
     them. The relationship runs the other way: a static mesh *hangs off* a skeletal mesh's socket,
     which is already decoded. The item's phrase invited a search for something the container does
     not have. `StaticMeshPropertyTests`.
   - **The kDOP tail stays deferred by the item's own condition** — no concrete UE5 collision or
     navigation target has been chosen. **But the same census makes that deferral cheaper than it
     looked:** the game declares collision *intent* in plain properties — `NeverCollide` (954
     meshes), `UseSimpleBoxCollision`, `UseSimpleVisionCollision`, `UseSimpleFootIKCollision`,
     `HavokCollisionTypeStatic`/`Dynamic` — so a UE5 bridge wanting collision can carry that across
     without decoding a kDOP tree at all. The census also turned up `LightMapCoordinateIndex` and
     `LightMapScale`, which are the static-mesh side of Gate 0 item 3.
   - **So item 1 is complete apart from the kDOP tail, which is deferred by design rather than
     unfinished.**
2. ~~**Skeletal meshes** — close the 4 remaining unreadable door variants; the 153
   `mesh-materials-without-sections` skeletal meshes have a known fix (the section table exists per
   `UnMeshBioshock.cpp`'s `FStaticLODModelBio`, it just isn't consumed yet — this is scoped work,
   not a research gap).~~ **This was already stale when written — the section table was already
   implemented and consumed** (`docs/research/skeletalmesh.md` §"Section table — `CONFIRMED_BYTES`",
   `Core/Mesh/SkeletalMeshSections.cs`), and the sweep's own dispatch bug (fixed 19 Aug 2026, see
   "Test health" below) was hiding how much of it already worked. **The real remaining gap**: the
   table sits right after the socket table and is located by walking from there, so it's only
   reachable when the socket table itself validates — measured at 331 of 944 skeletal meshes with
   geometry (35%). Close the 4 remaining unreadable door variants (unrelated), and find a more
   robust locator for the section table that doesn't depend on the socket table resolving first, to
   close the other 65%.

   **The locator is done, 22 Aug 2026: 331 of 944 exports (35%) → 966 of 967 (99.9%).** The layout
   allows the search to run backwards, and backwards needs nothing but the geometry — the section
   array ends exactly where the bone map's count begins, so a candidate count is testable by whether
   its own `FCompactIndex` ends exactly where the array would start, corroborated by the
   `TRIBES_HDR` before it and settled by the same face-sum check the forward walk uses.
   - **The evidence is the agreement, not the coverage.** A locator finding *more* tables would be
     worthless if it found *different* ones. The forward and backward walks produce **byte-identical
     tables on every mesh where both succeed, 0 disagreements**; forward-only is 0, so the backward
     route is a strict superset. Both are kept, because their continued agreement is an ongoing
     check. `SkeletalMeshSectionCoverageTests`.
   - **`mesh-materials-without-sections` is now 0**, from 94 — the whole diagnostic total moved
     427 → 333, exactly the 94, with no other code changing. Classified per `ENGINEERING_RULES.md`
     §24 as a correct improvement before either the code or the figure was touched;
     `docs/QUALITY.md` and `DocumentedFiguresTests` updated to the measured values.
   - **The 4 unreadable door variants were already closed, and this line asking to "close" them was
     stale.** `docs/HANDOFF.md` §6.2 settles them `CORROBORATED` on three independent lines: the
     payloads separate with no overlap (everything that decodes is ≥2,443 bytes, every one of these
     ≤1,291), their groups hold open/close animations and door-leaf socket names but no drawable
     mesh — `AtlasLabsDoorAnim` ships `Model`/`Polys`, which is BSP — and other doors decode fine.
     They carry no vertex data at all, so there is no unread stride to hunt for, and
     `SkeletalMeshGeometryTests.TheMeshesWithoutGeometryAreTooSmallToHoldAny` pins the names, the
     count and the separation. **The genuine remaining gap in this container is byte-exact accounting
     of a `SkeletalMesh` payload** — the vertex chain is still located by search — which is worth
     more than the doors ever were.

   **So Gate 1 item 2 is complete.**
3. ~~**Textures**~~ — export colour-space/normal/mask/cubemap intent as UE5-facing metadata, not just
   pixels; validate representative imports.
   - **Started 23 Aug 2026, from the transparency side, driven by a user bug report** rather than by
     working the item top-down: parts of solid props were drawing invisible in the level viewport.
     The cause was the item's own subject — **the renderer had no notion of texture intent at all**
     and read every diffuse's alpha as opacity. `BioShockMaterial.DeclaresTransparency` now carries
     the game's own declaration (`Opacity`/`bAlphaTexture`/`Masked`/`OutputBlending`, names
     `CONFIRMED_EXTERNAL` from UModel's `UTexture` table and Nyko's SDK) and
     `PreviewImage.HasCutoutHoles` the measured alternative. See
     `docs/research/materials.md` "A diffuse's alpha channel is not necessarily opacity" for the
     census and `TransparencyIntentTests` for the pins.
   - **Intent is now exported, 23 Aug 2026.** `TextureIntent` carries usage, colour space,
     addressing and the alpha flags, and rides in the scene JSON as `SceneMaterial.TextureIntents`,
     keyed by slot — the role belongs to the binding, not to the image, since the same file is a
     base colour in one material and a mask in another. Enums serialise by name so the file's
     meaning does not depend on an enum order the importer cannot see. Full census in
     `docs/research/textures.md`; `TextureIntentTests` and `TextureIntentCensusTests` pin it.
     - **Colour space is not declared by the game at all** — no `sRGB`, `CompressionSettings` or
       `MipGenSettings` on any of the 30,831 shipped textures, so it is **inferred from usage and
       labelled inferred**. Same shape as item 1's socket answer: the item's phrasing invited a
       search for something the container does not have.
     - **Addressing and alpha intent are declared** and were simply unread: `UClampMode`/
       `VClampMode` (~3,500 textures, always "clamp"), `bMasked` (105), `bAlphaTexture` (722).
     - **A decode bug found and fixed on the way:** `UnrealProperty` discarded the value of every
       `Bool` property, which lives in bit 7 of the info byte. That matters because this game
       serialises false bools — `bStreamable` is written 4,374 times and is false on every one — so
       a presence test is not a value test. Now exposed as `UnrealProperty.BoolValue`.
   - **Cubemaps decoded, 23 Aug 2026.** No new payload format at all: a `Cubemap`'s six `Faces`
     entries are object references to plain `Texture` exports named `<cubemap>_Face_N`. **All 287
     in the game resolve all six faces** (`CubemapReader`, `CubemapTests`, plus the whole-game
     check in `TextureIntentCensusTests`). Face *ordering* stays `UNKNOWN` — the game names them
     only `_Face_0..5` — so declaration order is preserved rather than a convention guessed at.
   - ~~**Item 3's remaining half: no representative UE5 import has been validated.**~~
     **Done, 23 Aug 2026 — imported into UE5.7 and verified in the engine.** Normal maps land with
     `sRGB=false` and `TC_NORMALMAP`, colour maps with `sRGB=true` and `TC_DEFAULT`, addressing as
     declared, and provenance in asset metadata. **Gate 1 item 3 is now closed.**
     - **The import found a gap unit tests could not.** Intent was exported into the scene JSON and
       tested there, but `ue5_manifest.json` is a separate document and is the one the importer
       reads — and `import_bioshock.py` had texture/material import switched off outright. Both
       documents were individually correct; the gap lived between them. This is the
       "render it" rule earning its place: numeric validation passed throughout.
     - `FbxRig.Textures` now carries the intent; the importer applies it and tags provenance.
       `ManifestTextureIntentTests` pins the manifest half. Headless traps (Interchange PNG
       crashing under `-unattended`, `unreal.log` not reaching the captured log) are recorded in
       `docs/HANDOFF_UE5_IMPORT.md`.
   - **A gap found in passing, not chased:** a few materials' diffuse slot resolves to a normal map
     or heightmap (`GraniteColor_NOR`, `facade_side_normal`, `BulletConcDecal_Heightmap`). Whether
     that is the game's authoring or this project's slot walk is `UNKNOWN`.
4. ~~**Materials** — decode `OutputBlending` (blend mode) semantics~~ — **already settled, not an
   open item.** `docs/research/open-questions.md` §11: `OutputBlending`'s declared values do not
   correlate with the alpha actually present in that material's own diffuse texture, so it is not
   Unreal's `EBlendMode` or any other rendering blend-mode selector — the renderer is already
   correct to ignore it. **Amended 23 Aug 2026:** the second half of that sentence used to read
   "and drive transparency from the texture's observed alpha instead", which is no longer what the
   renderer does and was not safe advice — observed alpha alone made solid props invisible in the
   level viewport, because a diffuse's alpha here is frequently a gloss mask. Transparency now
   takes the material's declaration or measured cutout holes; see
   `docs/research/materials.md`.

   ~~What's still genuinely open: `MaterialSwitch`'s dynamic candidate selection and
   `MaterialSequence`.~~ **Both closed, 23 Aug 2026 — and `MaterialSequence` was never undecoded.**
   - **`MaterialSwitch` candidates decode: all 45 switches in the game.** The `Materials` array is
     an `FCompactIndex` count followed by that many object references, consuming its declared size
     exactly. **This settles the candidates, not the selection** — which one a running game picks
     is `UNKNOWN` game logic, not package data — so a switch still resolves to its authored default
     and the candidate list rides alongside. That is enough to carry every state across:
     `Resurrection_Shader` beside `Resurrection_Shader_NoLights`, a sign's `_scroll` beside `_off`.
     **44 of 45 looked like success** until the whole-game count: `LangScreenSwitch`'s default is
     not a class the reader parses as a shader, so it took the fallback path and lost its
     candidates while its array decoded fine.
   - **`MaterialSequence` was decoded all along.** `MaterialSequenceReader` has read these for a
     long time with its own test; nothing called it from the material walk, so a sequence binding
     landed in `UnhandledProperties`. Now `BioShockMaterial.Sequences`, keyed by slot.
   - **A pattern worth naming:** this is the fourth item this cycle where "not decoded" meant "not
     wired" — the skeletal-mesh section table, `m_extractedMotion`, the cubemaps, and now this.
     Check whether a reader already exists before opening any item that claims otherwise.
   - ~~**panners/rotators**~~ **decoded, 23 Aug 2026 — and the reference projects were no help,
     which is the finding.** UModel documents UE2's `TexPanner`/`TexRotator`; **this game ships
     neither name nor either layout.** It ships `TexturePanner` (2,823 — `UPan`/`VPan`/`PanTime`),
     `TextureScalar` (691), `ColorCycle` (630) and `TextureRotator` (418 — `Rotation`/`Duration`/
     `UCenter`/`VCenter`), found by censusing what materials actually point at rather than by
     searching for the reference's names. Decoding by the reference layout would have produced
     confident nonsense.
     - These were the **largest group of bindings falling into `UnhandledProperties`** — the
       texture-binding rule requires an `Object` property to resolve to class `Texture`, which is
       correct (an animator is not a texture) but left 4,562 animator bindings looking like
       unknown properties. Now `BioShockMaterial.Animators`, and exported.
     - **Carried, not interpreted.** `UNKNOWN`: the units of `PanTime`/`Duration`, whether those
       are the same quantity, and the `Waveform` byte. `Rotation`'s three `int32` are raw — Unreal
       rotator units is `PLAUSIBLE` only, so no degree conversion is applied.
   - ~~**environment/cubemap inputs**~~ **answered, 23 Aug 2026: a material never says which
     cubemap.** Across all 33 packages, 6,179 cubemap-named properties on 5,726 materials, and
     **not one is an object reference to a cubemap** — they are two bools
     (`UseSpecularCubemaps` 542, `UseSpecularCubeMap` 156) and a float
     (`SpecularCubeMapBrightness` 5,481). `ReflectionCubemap` is in the SDK's name list and the
     shipped game never writes it. Both scalars are now decoded and exported. **Which cubemap a
     surface reflects is `UNKNOWN` and is not material data** — it must come from the level or a
     global, which makes it level work, not material work. `CubemapBindingTests`.
     **Answered later the same day from the level side: `CubemapProbe` actors, 281 of them, every
     one naming a real `Cubemap` and carrying a world position** — UE5's reflection-capture
     model. See Gate 3 item 2. Still `UNKNOWN`: which probe covers which surface (the actor's
     `Region` struct is undecoded).
   - **A decode correction found alongside it:** `MaterialReader` tested bool *presence*, and
     materials serialise false bools (`RealTimeReflection` 203 times, always false). It now reads
     `UnrealProperty.BoolValue`. Behaviour-preserving on the two flags it acts on — `Masked` and
     `TwoSided` have no false occurrence anywhere in the game, which is asserted rather than
     assumed.

### Gate 2 — animation, rigs and physics

1. ~~Decode remaining Havok animation fields affecting playback: blend hints, compression edge cases,
   additive semantics, root motion, events beyond what's already surfaced.~~
   **Blend hints/additive semantics: already settled** — `CONFIRMED_EXTERNAL` then census, every one
   of the game's animations is `blendHint` 0 (`NORMAL`); `open-questions.md` §3.
   **Events: already complete** — 47,560 events across all 16,031 animations, 0 blocks left
   unconsumed (`docs/HANDOFF.md`'s current-state table).
   **Root motion: decoded, 22 Aug 2026.** `m_extractedMotion` was named in this project's own byte
   layout doc comment but never read — the same shape of gap as the skeletal mesh section table.
   Now read (`HkaDefaultAnimatedReferenceFrameReader`) and censused: **6,356 of 16,031 animations
   (39.6%) carry it**, resolving to a real `hkaDefaultAnimatedReferenceFrame` object whose
   `up`/`forward`/`duration`/sample-count all cross-validate against the owning animation.
   **A sample's field meaning is `CONFIRMED_EXTERNAL`** (X/Y/Z translation, W yaw around up — the
   SDK's own comment on `m_referenceFrameSamples`) **and both Z and W are `CONFIRMED_BYTES` live, not
   structurally dead** — a breadth check across three more skeleton families (`GathererGirl`, both Big
   Daddy variants, 196 more root-motion animations) found smoothly growing Z on the Little Sister's
   vent-climb animations and smoothly growing W (unwrapped past ±π — an "absolute offset from the
   start" angle, not a bug) on all three. **A genuinely new finding along the way**: root motion's
   units are the same centimetre-ish scale as this project's mesh/bone data, not the metre scale
   `hkpCapsuleShape` (Gate 2 item 3, below) turned out to use — two different Havok subsystems, two
   different authored scales, both now confirmed rather than assumed. **Still `PLAUSIBLE`**: which
   world/local axis X and Y actually are (forward/right or something else). **Still `UNKNOWN`**:
   whether the remaining ~6,150 root-motion animations outside these four families (creatures'
   swim/flight paths look most likely to differ) look the same shape. Wiring any of this into the
   exporter is separately out of scope, crossing into Gate 5's export-pipeline territory and needing
   the coordinate-basis policy applied first. See `docs/research/root-motion.md` for the full record.
   ~~**Compression edge cases: genuinely still open.**~~ **Answered, 23 Aug 2026: there are none.**
   The right question was not "what is broken" — nothing is — but "what has never been exercised".
   **Every track mask in the game is the same byte**: 884,855 masks across 15,998 spline animations
   in 20 packages, `QuantizationTypes` = `0x45` on every one, decomposing (per the SDK's own
   `unpackQuantizationTypes`) to `Bits16` translation, `ThreeComp40` rotation, `Bits16` scale. Every
   other selector is unreachable by shipped data. `QuantizationCensusTests`;
   `docs/research/havok-compression.md`.
   - **The unused branches already refuse rather than guess** — `DecodeRotation` throws for anything
     but `ThreeComp40`. Keep it that way: a second format must surface as a refusal, never as a
     plausible wrong pose.
   - **`unpack16` is now `CONFIRMED_EXTERNAL`** against the SDK's own
     `( val / 65535 ) * ( max - min ) + min`.
   - **The 12-bit midpoint is now a *closed* lead, not an untried one.** The unpack path reaches
     `hkaSignedQuaternion::unpackSignedQuaternion40`, whose **body does not ship** — declared in the
     header, referenced from the `.inl`, no `.cpp` anywhere (grepped). Same missing-source situation
     as `sampleTranslation` and `evaluateSimple1/2/3`. Error stays under 0.0005. **Do not re-open
     this against the SDK.**
2. §6.0c — the 252 bone-rigidity collapses (27 folding ≥20 bones), including `AggressorBabyJane`'s
   fire clips — needs `sampleTranslation`, which the current SDK build doesn't expose. Genuinely
   blocked, not merely unstarted. **Re-checked, 22 Aug 2026**: the recorded next lead
   ("compare against `evaluateSimple1/2/3` at u=0") is now also confirmed closed, not just untried —
   those functions are declared and referenced but their bodies are nowhere in the SDK source tree
   (grepped, not assumed), the same missing-`.cpp` situation as `sampleTranslation`. What *is*
   readable in that area (`findSpan`, `getBlockAndTime`, `recompose`) was compared against this
   project's own `NurbsBasis` and agrees. See `docs/HANDOFF.md` §6.0c "Where to look next" for the
   full record. No further ground here without either the missing compiled bodies or a genuinely new
   lead — do not re-open this specific comparison.
3. ~~Map Havok collision/ragdoll data to UE5 Physics Assets only once body shapes, constraints and
   units are byte-backed — preserve unsupported blocks losslessly rather than guessing.~~
   **Scoping started, 22 Aug 2026** (was genuinely unstarted before — only ragdoll *presence* had
   ever been checked, `CharacterCatalog.DeclaresRagdoll`, never a payload read). One character
   (`AggressorBabyJane`) censused: 17 `hkpRigidBody`, 17 `hkpCapsuleShape`, 16
   `hkpConstraintInstance`/`hkpRagdollConstraintData` pairs, 1 `hkaRagdollInstance`, 2
   `hkaSkeletonMapper`. **`hkpCapsuleShape` fully decoded, `CONFIRMED_BYTES`** on all 17 of this
   character's capsules, 0 disagreements — radius and both end-vertices' redundant radius component
   agree exactly, and every decoded radius/length is a plausible human-body proportion **in metres**
   (three orders of magnitude smaller than this rig's own centimetre-scaled mesh/animation data — the
   expected Havok convention, not a bug, but a scale factor nothing here has derived yet).
   `HkpCapsuleShapeReader`, `HavokPhysicsTests`. **`hkaRagdollInstance` also fully decoded,
   `CONFIRMED_BYTES`, same session**: every field cross-validates against the whole-packfile census —
   `m_rigidBodies` resolves to exactly 17 elements, `m_constraints` to exactly 16, the array data
   sits exactly where Havok's own packing predicts (immediately after the object), and its first four
   entries land exactly on the first four independently-found `hkpRigidBody` offsets.
   `m_boneToRigidBodyMap` is `[0..16]` (identity) and `m_skeleton` resolves to a real `hkaSkeleton` —
   **but it is this ragdoll's own 17-bone skeleton, confirmed distinct from the 73-bone animation
   skeleton**. `HkaRagdollInstanceReader`,
   `HavokPhysicsTests.RagdollInstanceCountsAgreeWithTheWholePackfileCensus`. **`hkaSkeletonMapper`
   fully decoded too, `CONFIRMED_BYTES`, same session** — closing the gap the ragdoll instance left:
   both of this character's mappers resolve to real, class-named, bone-counted `hkaSkeleton` objects
   (73-bone `Bip01` and 17-bone `Ragdoll_Bip01 Pelvis01`), and their `SimpleMappings` are near-exact
   inverses of each other — 20 of 21 entries in one direction have an exact reverse counterpart in
   the other's 29, the one exception understood (a bone plausibly covered by the reverse mapper's
   separately-counted "unmapped bones" instead). `HkaSkeletonMapperReader`,
   `HavokPhysicsTests.SkeletonMappersAreNearExactInversesOfEachOther`. **A capsule can now be traced
   end to end to a named animation bone**: rigid body index → `BoneToRigidBodyMap` → ragdoll bone
   index → `SimpleMappings` → animation bone index. **`hkpRigidBody` partially decoded, same
   session**: its shape pointer, `CONFIRMED_BYTES` on all 17 rigid bodies (`HkpRigidBodyReader`,
   `HavokPhysicsTests.EveryRigidBodyPointsAtARealCapsuleShape`) — reachable despite `hkpEntity`'s
   materially deeper inheritance chain because the intervening classes' own fields
   (`hkMultiThreadCheck`, `hkpLinkedCollidable`'s `m_collisionEntries`) are entirely
   `+nosave`/`+serialized(false)`. **The rest of `hkpRigidBody` (mass, inertia, velocities,
   friction/restitution, the body's own world transform) is deliberately still open** — a first byte
   dump found plausible candidates (a friction/restitution-looking float pair, a near-unit-length
   quadruple that could be a rotation component) but a principled cross-reference against this rig's
   own bind-pose bone chain came up inconclusive (the tested bone's local translation was exactly
   zero, and a rigid body's transform is world-space, needing the full parent chain composed, not one
   bone read in isolation) — not published as fact. **`hkpConstraintInstance` fully decoded,
   `CONFIRMED_BYTES`, same session**: the full constraint topology — `Data`, `EntityA`, `EntityB` all
   resolve on all 16 of this character's constraints, 0 disagreements, to a real
   `hkpRagdollConstraintData` and two real `hkpRigidBody` objects each, and the resulting graph is
   coherent (several constraints touch rigid body 0, the pelvis — a root-radiating hierarchy, not a
   coincidence). `HkpConstraintInstanceReader`,
   `HavokPhysicsTests.EveryConstraintConnectsTwoRealRigidBodiesToRealConstraintData`. Along the way,
   corrected an assumption this investigation had over-applied: `+nosave` doesn't always mean a field
   is omitted from the layout — `hkpConstraintInstance::m_owner` is `+nosave` but still occupies its
   4-byte slot (permanently null). **`hkpRagdollConstraintData::Atoms` — the seven nested "atom"
   structs holding the actual joint limit angles and motor parameters — checked and found genuinely
   out of reach, not merely unattempted.** None of the seven atom classes have a header anywhere in
   this SDK, not even their field declarations — unlike every other class decoded this session, where
   a header gave the real field list to verify against bytes. Recovering their layout would mean
   inferring Havok's own undisclosed struct design purely by experimenting on the bytes, the same
   category of reverse engineering Havok's license (§4.2) prohibits as the
   `sampleTranslation`/`evaluateSimple1-3` disassembly question in §6.0c — considered explicitly,
   including after a direct request to proceed on the reasoning that private/non-commercial use
   changes the license terms (it doesn't; §4.2 restricts the act itself). **Declined, for the same
   reason as §6.0c.** Gate 2 item 3 therefore closes here: the full topology — every shape's owning
   body, every body's owning bone, and the complete constraint graph — is `CONFIRMED_BYTES`; the
   joint limits and `hkpRigidBody`'s remaining fields (mass/inertia/world transform — a real header
   exists for these, genuinely just unattempted, not blocked) are what a future session would pick up.
   Full record: `docs/research/havok-physics.md`.

   **`hkpRigidBody`'s world transform and mass properties decoded, 23 Aug 2026 - `CONFIRMED_BYTES`
   across 207 ragdolls and 1,426 rigid bodies.** `m_transform` at `+240`, `m_inertiaAndMassInv` at
   `+416`. **Found by search and confirmed by structure, not by offset arithmetic** through
   `hkpEntity`'s inheritance chain - which is what the previous inconclusive pass had attempted.
   Four independent properties agree: exactly one offset gives an orthonormal basis; its determinant
   is +1 on **1,426 of 1,426** bodies; the translations show bilateral limb symmetry **and the
   inertia values mirror in the same pairs**; and `1/w` is a clean authored mass on every simulated
   body in the game (5 kg x351, 10 x202, 1 x132, 30 x105, 20 x80). Positions are metres, matching
   the capsules. **40 bodies are fixed (infinite mass)** - doors, wall cameras, a blast door post, a
   slot machine, a scripted plane crash - which a UE5 bridge needs, since a fixed body is a
   kinematic constraint rather than a simulated one. `RigidBodyMotionTests`,
   `RigidBodyMotionCoverageTests`.
   - **A disproved assumption, recorded:** "a character has an `hkaRagdollInstance`, a prop does
     not" is **false** - props carry them too. So there is no structural prop/character
     discriminator here, and the categorisation above is by name, logged rather than asserted.
   - ~~**Still open, unattempted rather than blocked:** velocities, damping, friction,
     restitution.~~ **Done, same session — and these were *derived*, not searched.** Once `+240`
     and `+416` were confirmed the header accounts for every byte between them: `m_objectRadius`
     `+400`, damping `+404`/`+406`, `m_timeFactor` `+408`, velocities `+432`/`+448`, and
     `hkpMaterial`'s friction/restitution at `+140`/`+144`. **`m_timeFactor` reads exactly 1.0 on
     1,426 of 1,426 bodies**, which confirms both the offset and the encoding (`hkHalf` stores a
     float's high 16 bits, not an IEEE half). Friction takes three distinct values game-wide and
     restitution six — authored constants, not a continuum.
   - **One rig ships with a live velocity state:** 104 bodies have non-zero velocity and **every one
     belongs to `NewProtectorBouncer`**. `PLAUSIBLE` that it was saved mid-simulation; what is
     confirmed is that the exceptions are confined to a single rig, which a wrong offset would not
     manage.
   - The joint-limit `Atoms` stay **declined on licence grounds** - do not re-open.
4. ~~Validate every skeleton family in UE5 beyond the pistol/TommyGun pair already proven.~~
   **Splicer done, 19 Aug 2026**: `AggressorBabyJane` (73 bones, 6,176 vertices, 17 sockets — a
   structurally different, larger rig than any weapon viewmodel) imports cleanly
   (`Success - 0 error(s), 5 warning(s)`, the same cosmetic warning shape as the weapon rigs) and
   the resulting asset verified directly: a real `SkeletalMesh` with a non-null `Skeleton` and a
   populated bone tree. Found and fixed a real CLI gap along the way: `export-fbx` guessed a rig's
   mesh name by stripping `UAPW_` off the wrapper name, which only holds for a rig with one mesh —
   `AggressorBabyJane`'s rig is shared by three (`Agg_Doctor_Mesh` plus two corpse variants), so it
   silently exported 0 vertices. `export-fbx` now takes an explicit `--mesh <name>` override.
   Animations weren't re-verified per-character here (the rig has 457 of them — whole-game format
   validation already covers all 16,031 animations in the game; this item is about mesh/skeleton
   topology, which the weapon rigs' narrower bone counts didn't exercise).
   **Both Big Daddy variants done, same session**: `ProtectorRosie` (60 bones, 12,670 vertices, 7
   sockets, single-mesh rig) and `NewProtectorBouncer` (42 bones, 8,586 vertices, 7 sockets —
   another rig whose mesh name, `ProtectorBouncerMESH`, didn't match its wrapper, exercising the new
   `--mesh` flag again) both import cleanly (`Success - 0 error(s), 10 warning(s)` for the pair,
   same cosmetic shape) and verify as real `SkeletalMesh`es with populated skeletons.
   **Little Sister done, same session**: `GathererGirl` (60 bones, 5,495 vertices, 6 sockets —
   named for the game's own "Gatherer" terminology) imports cleanly
   (`Success - 0 error(s), 5 warning(s)`) and verifies the same way.
   **22 Aug 2026 — weapons, doors, props and creatures extended to closure.** Beyond
   pistol/TommyGun/Splicer/Big Daddy/Little Sister above, 22 more rigs across every remaining
   structural category import and verify clean the same way (`verify_bioshock_import.py` raising no
   `RuntimeError`, a real `SkeletalMesh` with a non-null populated `Skeleton`); `export-fbx` gained
   `--mesh <name>` (18 Aug) and `export-firstperson` gained `--group=<name>` (`Cli/Program.cs`, 22
   Aug) as the same fix applied twice — a rig's mesh export or ShockGame.U group name doesn't always
   match a `UAPW_`-stripped wrapper name or a `"WP_" + socket` guess.

   **Weapons — all 7 hand sockets resolved, none open.** `Pistol`, `TommyGun` (prior session),
   `Crossbow` (`WP_Crossbow`, 15 bones, 10,151 vertices, 3 animations), `Chem` → `WP_ChemicalThrower`
   (`WP_ChemicalThrowerMesh`, 8 bones, 7,936 vertices, 6 animations — needed `--group`, the socket
   name doesn't match the group name), `Launcher` → `WP_GrenadeLauncher` (`WP_GrenadeLauncherMesh`,
   8 bones, 5,386 vertices, 4 animations — same `--group` case) all import attached to the hands.
   `PlayerGathererGun`'s rig (`UAPW_WP_gathererGun` / `PlayerGathererGunMESH`, 2 bones, 923 vertices)
   turned out to live in the `7-BossFight`/`7-Gauntlet` map packages, not `ShockGame.U` — a
   boss-fight-scripted weapon outside the shared first-person set — so it was exported directly via
   `export-fbx` against the map package instead, and verifies the same way. `Wrench` is
   **confirmed, not merely unresolved**: `WP_WrenchMesh` in `ShockGame.U` is a plain `StaticMesh`
   with no `AnimationPackageWrapper`/`SkeletalMesh` at all — a real, decoded answer ("melee weapon,
   no separate skeleton"), not an open question. A genuine curiosity found and closed along the way:
   `ShockGame.U` also holds a fully animated, fully authored `WP_ShotgunMesh` / `UAPW_WP_Shotgun` (3
   bones, 3,417 vertices, 4 animations with notifies) with **no corresponding socket on the current
   `NEWPlayerHands` rig** — exported and verified standalone (no hand attachment to test) to confirm
   it decodes and imports cleanly; it is real, finished content with no way to attach it in the
   shipped game, plausibly cut or multiplayer-only. Not chased further — recorded as `PLAUSIBLE`,
   not promoted to a claim about *why* it's orphaned.

   **Doors — 7 working variants verified, 3 real decode failures found and named for Gate 1.**
   `UAPW_BulkheadDoor` (mechanical, no skin deformation, 11 bones), `UAPW_LockerDoorAnim` (3 bones),
   `UAPW_Med_DoorAnim` (3 bones), `UAPW_Hyd_CrawlSpaceDoor` (3 bones), `UAPW_PeepDoorAnim` (4 bones),
   `UAPW_SlidingStoreDoor` and `UAPW_SlidingBrokeStoreDoor` (3 bones each) all import and verify
   clean. Three more — `UAPW_GathererDoorAnim` (`GathererDoorAnimMesh`), `UAPW_Sliding512SingleDoor`
   (`Sliding512SingleDoorMesh`) and `UAPW_Res_LowRentDoorAnim` (`LowRentDoor_Mesh`) — report **"no
   geometry"** from `meshes`, i.e. they don't decode at all. **Confirmed against `docs/QUALITY.md`
   §"Four door meshes do not decode"**: these are exactly 3 of its 4 already-tracked names
   (`LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`, `GathererDoorAnimMesh`; the 4th,
   `Atlas_labs_doorAnim`, wasn't hit this session) — the same gap, not a new one, nothing further to
   chase here.

   **Props — 8 variants verified**, spanning rigid mechanisms (`UAPW_TurretMachineGun`,
   `UAPW_TurretFlamethrower`, `UAPW_ElevatorFall`, `UAPW_CeilingFan`, `UAPW_GreatChain_MESH`), small
   fixed props (`UAPW_SlotMachine_MESH`, `UAPW_KeyCard_MESH`, `UAPW_WallSafe_MESH`,
   `UAPW_TeleportBeacon_Anim` → mesh `TBeaconAnim_Mesh`) and one enemy robot
   (`UAPW_SecurityBot`, 8 bones, 7 sockets) plus a fixed console (`UAPW_SecurityStation`).

   **Creatures — 7 variants verified**, the widest bone-count and topology spread tried yet:
   `UAPW_CatSkeletalMesh` (9 bones, no animations exported — a static pose/corpse use), `UAPW_CrabAnim`
   (32 bones), `UAPW_Whale_SkeletonMESH` (43 bones, 5,455 vertices — the largest creature rig tried),
   `UAPW_GiantSquidAnim` (33 bones), `UAPW_Jellyfish` (7 bones), `UAPW_shark` (4 bones). None needed
   root-motion or IK verification beyond topology — out of scope for this item, tracked under Gate 2
   item 1 (Havok field decode) and Gate 2 item 3 (physics) instead.

   **Where this item stands**: every structurally distinct rig *category* shipped in the game —
   first-person weapon, mechanical door, static/rigid prop, humanoid enemy, quadruped, aquatic
   creature, enemy robot — now has at least one member verified importing clean into a live UE5.7
   editor, with no outstanding "does this category work" question. What's **not** done, by design:
   literally every one of the ~118 named `AnimationPackageWrapper` rigs in the game (would be pure
   repetition of already-verified categories) and the 3 named decode failures above (Gate 1's, not
   this item's, to fix). Both are enumerable, bounded gaps, not open questions.

### Gate 3 — levels and UE2 actor systems

1. ~~Zones, leaves, portals, visibility/collision relationships for the compiled world.~~ **Zone
   connectivity and per-node visibility both done, 19 Aug 2026:**
   - Every zone's 128-bit connectivity mask decodes (`BspZone.ConnectedZones`,
     `docs/research/bsp.md` §5.5c), `CONFIRMED_BYTES` over all 1,042 zones in the game (bit *N* set
     for zone *N* itself, 100%; 94% connect to at least one other zone, in a distribution — 1–15
     bits, average 3.2 — shaped like real portal adjacency).
   - `FBspNode+16`'s 128-bit per-node visibility mask also decodes (`BspNode.VisibleZones`,
     §5.2), sourced from `Bioshock1REMSDK-WIP--main`'s working level editor and confirmed
     independently: 81,559 of 81,566 polygon-carrying nodes (99.99%) see their own zone, the 7
     exceptions all sharing `Zone == 0`. The two masks correlate (94% subset) but aren't identical —
     real, related structures, not duplicates.
   - Leaves already carry their own zone/permeating/volumetric fields (`BspLeaf`).

   - **Portal geometry done, 23 Aug 2026 — and the reference had two bytes backwards.** Nyko's SDK
     notes label `+76` as `NodeFlags` and `+79` as "iZone[1] / Pad"; the shipped bytes say the
     opposite, and stock UE2's own field order (`iZone[0]`, `iZone[1]`, `NumVertices`, `NodeFlags`)
     is what actually holds. `+76` takes **121 distinct values** (an index); `+79` takes **four**
     (a flag byte), and **`+79 == 5` marks every one of the game's 2,386 portals, no exceptions**.
     Each portal polygon therefore names the two zones it joins.
     - **The cross-check is the evidence:** all 2,259 portal pairs that name two different zones are
       already claimed by both zones' 128-bit connectivity masks — **0 disagreements** — and those
       masks were decoded from the zone records, a different part of the file. Independent, not
       circular. `PortalGeometryTests`; `docs/research/bsp.md`.
     - `UNKNOWN`: the individual bit names in `+79`. Consistent with UE2's `NF_NotCsg`|
       `NF_NotVisBlocking` but no available reference declares those constants, so the raw byte is
       stored and the reading stays `PLAUSIBLE`.

   **Still open:** what the zone record's constant trailing 20 bytes are (possibly a
   `VisibilityBitMask` or an unused environment default — no per-zone variation exists to correlate
   it against, so this may stay `UNKNOWN`); the other 6% where node visibility isn't a subset of
   zone connectivity; and collision relationships.
2. ~~Placed-actor transforms, parent/base links, draw scale, tags, material overrides — for every
   actor class, not just the geometry-bearing ones already placed.~~ **Already done, verified
   23 Aug 2026.** `LevelAnalyzer.BuildActor` applies no class filter, and the census bears that out:
   **118,919 actors across 764 classes, of which 118,854 carry a non-identity transform spanning 762
   of the 764 classes.** Tags on 118,245, draw scale on 31,672, base/owner links on 13,599 (33
   classes), material overrides on 6,648 (69 classes). The item's qualifier — "not just the
   geometry-bearing ones" — is satisfied. `ActorFieldCoverageTests` pins it so a future class filter
   cannot quietly narrow the coverage.
   - **A cross-gate find while censusing:** the class list turned up **`CubemapProbe`, 281 actors**,
     and **every one names a real `Cubemap` export and carries a world position**. That closes Gate 1
     item 4's cubemap question from the other end — the material says it wants a cubemap, the level
     says which one and where. It is UE5's reflection-capture model, so it bridges directly.
     `CubemapProbeActorTests`. Still `UNKNOWN`: which probe covers which surface — the probe's
     `Region` struct is undecoded and is the obvious next place to look.
3. ~~Gameplay/world actor schemas in descending shipped-count order (per the existing coverage
   ledger on `1-Medical`).~~ **Done, 23 Aug 2026 — Medical `Unclassified` reached zero; see the
   item's own closing paragraph below for the final tally.** `level-audit` still correctly reports
   696 `LightPending` — that label is accurate, it means "not yet placed as a real UE5 actor," not
   "undecoded." **The data schema itself is already done**: `LevelSceneExporter`'s
   `LevelLightDocument` exports location, colour, brightness and radius per light, tested end-to-end
   (`LevelSceneTests.TheLightsDecodeWithTheTypesTheSdkDocuments` asserts
   `scene.Lights.Count == document.Lights.Count` plus per-field validation). What remains for
   lights is turning that data into placed UE5 actors (Gate 3 item 4 / Gate 5) and rendering them
   faithfully in the viewport (Gate 0) — not decoding anything further.

   **The 299 `ScriptPending` actors are the same shape of "already has a schema, just not a UE5
   translation."** `LevelAnalyzer.ScriptActions` already resolves each actor's `Actions` array to
   real, typed references (class + object name), exported as `LevelScriptActionsDocument` and
   tested (`LevelAnalysisTests`: a specific actor, `Script79`, asserts exactly 17 complete,
   correctly-typed action references). What's actually still open is the same as Emitters below —
   translating identified references into UE5 behaviour (Blueprint/Kismet-equivalent), not
   identifying them.

   **`Actor.Region` decoded, 23 Aug 2026 — every actor now knows its zone.** Censusing this item's
   open categories turned up `Region` as **the single most common uninterpreted property in the
   game**, on every actor of every class. It is UE2's `FPointRegion` (`Zone`, `iLeaf`,
   `ZoneNumber`) as a nested tagged list, and it **cross-checks itself**: `ZoneNumber` and
   `Leaves[iLeaf].Zone` are the same fact from different bytes and agree on **96,136 of 96,376
   (99.75%)**. `iLeaf == 0` is a "no leaf" sentinel (20,159 actors); 240 (0.25%) genuinely
   disagree, disproportionately brushes — `PLAUSIBLE` that a brush indexes its own model's
   leaves. `ActorRegionTests`; `docs/research/bsp.md`. **This also completed the cubemap chain**:
   surface — zone (BSP node) — `CubemapProbe` (this `Region`) — `Cubemap`.

   **Region/volume schema started, 23 Aug 2026.** All 253 Medical region-category actors now export
   `Region` plus a typed collision/trigger record rather than leaving those values as property hex.
   The retained census covers 86 `TriggerVolume`, 59 `ZoneInfo`, 56 `BlockingVolume` and the seven
   smaller classes; all records are complete. Trigger label/class filters, one-shot/disabled/enabled
   state, radius/height/distance and collision flags are decoded with absent-vs-false preserved.
   `RegionActorSchemaTests`; `docs/research/bsp.md`. **`ZoneInfo` completed in the next slice:** all
   59 Medical zones now export their ambient-pressure states, fog variants, reverb, map/pressure
   regions and typed name/reference arrays. **Region actors completed in the final slice:** all 174
   brush-backed actors export exact nested main/post scale structs; cascading-water mesh/axis,
   fluid penalty/enabled state and default-volume priority/lifetime flags are typed too. No
   class-specific gameplay field in the retained 253-actor census remains only as hex.

   **Effect schema completed, 23 Aug 2026.** Medical contains **142 emitter-bearing actors**, and
   every one reaches the level manifest with a non-empty, complete typed template graph. The
   coverage ledger reports 134 `EffectPending` because eight emitter-bearing actors are classified
   earlier by geometry/light translation precedence; that difference is not missing emitter data.
   `EffectActorSchemaTests` pins both counts and the end-to-end export. What remains is selecting a
   Niagara representation, not decoding the shipped declaration.

   **Plain markers completed, 23 Aug 2026.** The largest formerly unclassified class is **150
   `Marker` actors**. Their retained property ledger contains no class-specific field at all: only
   the common actor record already exported (identity, transform, region, tag/ownership) plus the
   engine bookkeeping references `Level`, `PhysicsVolume` and `CheckpointTypePadding`. They now
   report as `MarkerPending`, meaning a UE5 placeholder representation has not been selected rather
   than that bytes remain undecoded. `MarkerActorSchemaTests`.

   **Medical `SoundMarker` classification corrected, 23 Aug 2026.** All 36 are now `AudioPending`
   rather than `Unclassified`. Twenty-six carry at least one exact, readable `Schema1`/`Schema2`
   FName; ten omit both and therefore use only the class/common actor identity. This agrees with the
   retained whole-game sound-actor census instead of inventing a missing payload for the ten.
   `SoundActorSchemaTests.MedicalSoundMarkersAreClassifiedByTheirDecodedSchemaNames`.

   **Training scripts decoded, 23 Aug 2026.** All 26 Medical `TrainingScript` actors now export
   their non-empty `Concepts` arrays and report as `ScriptPending`. The shipped encoding is an exact
   compact-count sequence of compact name-table indices, without the numbered-name suffix used by
   the other FName-array form; a separate exact decoder preserves that byte distinction. The script
   total is now 325 and every decoded concept reaches the manifest. `TrainingScriptActorTests`.

   **AI population spawners decoded, 23 Aug 2026.** The next 19 `AggressorSpawner` actors and the
   four later `ProtectorSpawner` actors share one exact schema and now report as `SpawnerPending`.
   Patrol and initial-label fields are FNames; global/initial/repopulation AI types are compact
   name-index arrays; overridden archetypes and spawn zones retain the numbered-FName array form.
   All 23 open-category declarations decode completely and reach the manifest. The distinction
   between the two array encodings is tested rather than normalised away. `SpawnerActorSchemaTests`.
   **Medical reflection probes wired end-to-end, 23 Aug 2026.** The 29 `CubemapProbe` actors were
   already known to name real cubemaps, but that reference existed only in retained property bytes.
   It is now a typed resolved actor reference, reaches the manifest, and reports as
   `ReflectionProbePending` for UE5 reflection-capture placement. All 29 Medical references resolve;
   the earlier whole-game proof remains 281 of 281. `CubemapProbeActorTests`.
   **Projectors/decals decoded, 23 Aug 2026.** The next 12 `GoreLight_Decal` actors share their UE2
   projector schema with eight `Caustic_Projector` actors and one `Projector`, clearing 21 actors in
   one byte-backed slice. Material, tile, trace distance, Z bias, scale timing and projection flags
   reach the manifest. The caustics' 27-byte `ProjectorGradient` is an exact two-field tagged layout
   (`FadeInEnd`, `FadeOutStart`), not a generic nested property stream; its decoder validates both
   names, types, terminator and full byte consumption. All 21 report as `ProjectorPending`.
   `ProjectorActorSchemaTests`.

   **Havok force actors decoded, 23 Aug 2026.** All 12 `HavokForceActor`s export typed object
   references for force type and force shape; eight also carry a force filter and four explicitly
   omit it. No target has failed resolution, and all declarations reach the manifest as
   `PhysicsForcePending`. This records the shipped composition graph without guessing how UE5's
   physics fields should reproduce it. `HavokForceActorSchemaTests`. **Next:** the remaining 41
   genuinely unclassified actors.

   **Medical hypo pickups decoded, 23 Aug 2026.** Each of the 11 `MedHypoPickup` actors carries one
   class-specific gameplay field: a `LootSlot` object reference. All 11 references resolve to
   shipped exports and now reach the manifest as `InteractionPending`; the rest of each record is
   already-covered transform, region, ownership and engine bookkeeping. `PickupActorSchemaTests`.
   **Training markers completed, 23 Aug 2026.** The six `TrainingMarker` actors declare no
   training-specific field at all; their retained ledger is only the already-covered common actor
   record plus collision/bookkeeping state. They now join plain `Marker` as `MarkerPending`, rather
   than implying a missing schema. `MarkerActorSchemaTests.TrainingMarkersAlsoContainOnlyTheCommonActorRecord`.
   **Havok actor constraints decoded, 23 Aug 2026.** Five `HavokHingeConstraint`s and one
   `HavokBSConstraint` now export their attached-actor graph as `PhysicsConstraintPending`. Actor A
   is present on all six; actor B and friction/tau settings on three hinges; two other hinges carry
   the limited-hinge flag. Nullable booleans retain absence versus false, and no actor link fails
   resolution. `HavokConstraintActorSchemaTests`. **Next:** the remaining 18 genuinely unclassified
   actors.

   **Anti-portals decoded, 23 Aug 2026.** Each of the three `AntiPortalActor`s carries one resolved
   `AntiPortal` object reference. Those references now reach the manifest as `VisibilityPending`,
   leaving representation/occlusion behaviour to the UE5 bridge rather than treating the actors as
   unknown. `AntiPortalActorSchemaTests`. **Next:** the remaining 15 genuinely unclassified actors.

   **Map UI markers decoded, 23 Aug 2026.** Three `MapUILayerMarker`s export their layer name,
   scale-marker name and exact numbered-FName region lists (1, 15 and 24 entries) as
   `MapMarkerPending`. The three `MapUILayerScaleMarker`s carry no class-specific field and now join
   the plain marker category. `MapUiMarkerSchemaTests`. **Next:** the remaining nine genuinely
   unclassified actors.

   **Vending stations decoded, 23 Aug 2026.** All three `PlaceableVendingStation`s export their
   table name/reference, hack-info name, static-mesh-instance reference, nullable hackable flag and
   raw `SendDestructionNotification` integer as `InteractionPending`. The integer is retained under
   its shipped declaration without guessing whether its numeric values are an actor index, event ID
   or another gameplay handle. `VendingActorSchemaTests`. **Next:** the remaining six genuinely
   unclassified actors.

   **Empty path/script boundary instances classified, 23 Aug 2026.** One `PathNode` serialises no
   path list and one `Script` serialises no action array; those absent optional arrays had left one
   actor of each class unclassified. Exact class identity now keeps all 495 Medical path nodes in
   `NavigationPending` and all 300 scripts in `ScriptPending`, without fabricating empty payload
   entries. `CoverageBoundaryActorTests`. **Next:** the remaining four genuinely unclassified
   actors.

   **Keypad/toolbox interactions decoded, 23 Aug 2026.** The singleton `DoorKeypadControl` exports
   its door label, hack-info name and nullable hackable flag; `dyn_toolbox_open` exports its nullable
   HUD-elements flag. Both now report as `InteractionPending`, with absence kept distinct from false.
   `InteractionActorSchemaTests`.

   **`LevelInfo` world settings decoded, 23 Aug 2026.** The map-root actor now exports title/map
   labels, time/path state, four editor cameras, ambient scalars, summary/spawning/glow/tone-map/
   animation-info references, **974 navigation references**, four pressure-region structs, 44 map-UI
   region structs, 11 HUD-description structs and two required-animation-group structs. A new exact
   tagged-struct-array reader validates every element terminator and full array consumption; all five
   arrays reach the manifest at their shipped counts and no navigation reference fails resolution.
   `LevelInfoActorSchemaTests`.

   **Final actor completed, 23 Aug 2026 — Medical `Unclassified` is zero.** The saved singleton
   `ShockAIScout` is runtime state, not authored content to recreate blindly. Its one-element null
   point collection, pathfinding origin/location/timers/result, controller/head-volume links,
   movement-capability flags, last anchor time, floor/collision state and raw destruction-notification
   integer now export as `RuntimeStatePending`. `ShockAiScoutActorSchemaTests` pins both the complete
   manifest record and a zero `Unclassified` total. **Gate 3 item 3 is complete for its stated
   `1-Medical` shipped-count ledger.**
   The now 345 Medical audio actors' declaration was
   settled under Gate 4 item 1; their
   unresolved sound-event targets remain audio-system work, not another actor-payload decode.
   Navigation has a
   graph handoff (953 actors, 4,838 references) with UE5 movement semantics intentionally
   undecoded.
4. ~~A deterministic level importer: create/update actor instances from the manifest, attach assets,
   apply transforms/overrides, and report created/updated/skipped/unsupported in one pass.~~
   **Done, 23 Aug 2026 — `tools/ue5/import_level.py`, verified in UE5.7 on `0-Lighthouse`.**
   First run 1,877 created; second run **0 created / 1,877 updated**, actor count unchanged.
   - **Idempotent by construction**, not by convention: each actor carries a
     `BioShockKey=<manifest key>` tag and a re-run finds actors by that tag rather than by label,
     which is neither unique nor stable under a rename.
   - **Running it twice found two bugs a single run cannot expose.** The pre-run snapshot was taken
     once, so lights created during the same run were invisible to the actor loop and every light
     got a duplicate placeholder — 2,342 actors where the manifest declares 1,877, exactly 465
     duplicates. On the re-run the key then resolved to the placeholder and the light path crashed
     setting `light_component` on a `TargetPoint`. Both fixed.
   - **Lights become real `PointLight` actors** with the manifest's colour and brightness
     (brightness carried proportionally, not converted — no photometric mapping is established,
     so `UNKNOWN` rather than guessed). Everything else is a positioned `TargetPoint` counted as
     **`unsupported`**, because the geometry it references is exported as OBJ and not yet imported
     as UE5 meshes. That count stays visible rather than folded into "created".

### Gate 4 — audio, effects, interactions

1. Cue/ambient/actor sound relationships beyond the notify chain already proven: chance/variation,
   attenuation, pitch/volume, language routing.
   **Premise corrected, 23 Aug 2026: those settings are not on the placed actors.** Across all 21
   maps, 3,247 sound-bearing actors (`AmbientSound` 2,893, `SoundMarker` 352, `MusicBox` 2) and
   **not one carries `SoundVolume`, `SoundPitch`, `SoundRadius` or an `AmbientSound` object
   property**. No amount of actor decoding will produce them.
   - **The link is by name.** `AmbientSound` names its sound through `Tag`/`Label`
     (`2_sixtywattlight`, `1_water_lapping`, `sparksloop`); `SoundMarker` carries
     `Schema1`/`Schema2` naming ambience schemas (`ambience_5_oneOff_machine`,
     `ambience_9_mainroom`). **Only 7 of 3,247 tags resolve to a `Sound` object in the same
     package**, so resolution goes through the sound-event system — the blocker
     `docs/research/audio.md` SS4 already records.
   - **`Schema1`/`Schema2` is the concrete new lead**: structured values, 317 and 131 actors, and
     they look like direct keys into an ambience system. `SoundActorSchemaTests`.
   - **Exact FSB resolution implemented, 23 Aug 2026.** The game FMOD runtime reports 2,047 unique
     names in 20 English banks and the same names across 45 localised banks, for 10,882 shipped
     sample locations. Exact matching resolves **177 of 3,247 actors, all `SoundMarker`s**. It
     resolves zero of 2,893 `AmbientSound`s and zero of two `MusicBox` actors; those tag/label names
     therefore still need the sound-event/schema route rather than fuzzy matching. Each resolved
     marker now identifies exact bank/index/language variants through `StreamSampleCatalog` and
     `AudioActorResolver`. `AudioActorResolutionTests`.
   - **A native-helper deadlock was found by the full census and fixed.** `StreamAudioService` read
     redirected stderr to EOF before stdout; a large `--list` filled the stdout pipe and blocked the
     child and parent. Both streams are now drained concurrently. The complete 65-bank sweep passes.
   - **Response variation and conditions decoded, 23 Aug 2026.** The former reader handled one
     sound from a supposed 19-byte blob and silently left longer names/multiple alternatives
     unresolved. The real `Specification` is an exact array of nested property lists containing
     `SpecificationType` (the sound name) and a `SpecificationClass` object reference; six- or
     seven-byte numbered FNames make the full entries 25 or 26
     bytes. Across all maps, **106,000 response objects contain 110,120 sound entries**; 1,760
     responses contain several alternatives, and all arrays now decode completely. Parallel
     `Chance` arrays have exactly one integer per sound entry (values 0/20/30/50/70/75/80/100), and
     51,620 responses carry 123,500 exact level-context FNames. `FilteredState` and
     `bLevelContextsMoved` are retained too. This establishes variation and condition data without
     asserting that the chance integer is a percentage or choosing a winner. `SoundEventCoverageTests`.
     Every entry's `SpecificationClass` resolves exactly to `SoundEffectSpecification`. Its shipped
     script-class defaults establish `OuterRadius=3000`, `Volume=100` and `Pitch=1`; these are class
     defaults, not evidence that every sound lacks an override.
   - **Concrete metadata path proven, 23 Aug 2026.** Map packages pair native `Sound` exports with
     same-name `SoundEffectSpecification` exports. The pistol reload explicitly overrides
     `InnerRadius=1000`, `Volume=80` and `VolumeCategory=3`, while absent `OuterRadius`/`Pitch`
     inherit the script-class defaults. `SoundEffectSpecificationReader` preserves that distinction.
   - **The settings do exist — on `SoundEffectSpecification`, not on the actors. Whole-game census
     done, 23 Aug 2026, closing that open sub-part.** 33,227 specifications across 20 of 21 map
     packages decode completely, 0 failures, and they serialize 31 distinct properties covering
     exactly what this item asks for: attenuation (`OuterRadius` 12,225, `InnerRadius` 19,438),
     level and pitch (`Volume` 31,669, `VolumeRange` 32,693, `PitchRange` 3,048), timing
     (`DelayRange` 1,327, `Monoloop` 30,414, `Polyloop` 32,995) and variation — a `SoundSpecs`
     array naming **81,775 sample entries, 5,726 distinct names in 91 units**, with **8,561
     specifications offering more than one alternative**. Every array consumes its value exactly;
     none is absent. `Range` turned out to be a nested tagged `Min`/`Max` list rather than a pair
     of floats, which reads as a plausible tiny number if taken literally. `SoundToPlay` is null on
     every one of the 81,775 entries, so the name is the only link to the sample.
     `SoundEffectSpecificationCoverageTests`, `SoundEffectSpecificationTests`;
     `docs/research/audio.md`.
   - **The placed-actor blocker is closed, 23 Aug 2026.** `AmbientSound` reaches its specification
     through the event response named `AmbientSoundSpawned_<Tag>`; `SoundMarker` names its
     specification outright through `Schema1`/`Schema2`. The prefix is structural, not a
     resemblance: all **10,360** shipped `AmbientSoundSpawned_*` responses carry `Event="Spawned"`
     and `SourceClassName="AmbientSound"`, no exceptions. **3,068 of 3,247 sound actors now resolve
     to a shipped `SoundEffectSpecification`** — `AmbientSound` 2,751/2,893, `SoundMarker` 317/352,
     `MusicBox` 0/2 — against **177** by exact FSB name matching, and 0 `AmbientSound`s before.
     Matching stays exact; the 179 that do not resolve mostly carry only an editor default label.
     A one-line rendering bug in `SoundEventReader` (numbered FNames written `name_N` where every
     other reader in the project writes `nameN`) was silently costing 100 references and is fixed.
     `SoundActorSpecificationIndex`; `SoundActorSpecificationCoverageTests`,
     `SoundActorSpecificationTests`.
   - **Sample location closed, 23 Aug 2026 — 5,722 of 5,726 (99.93%).** An earlier reading of this
     item reported "1,970 (34.4%) in neither store"; that was an **enumeration artefact**, not a
     gap. It counted only the 21 non-localised map packages, and the game ships its voice-over in
     the 140 **localised** ones. Full accounting: 2,080 in the core maps, **1,995 in the localised
     maps**, 1,676 in the FSB5 banks, 10 in `FMODAudio.U`. **`BulkContent/` is ruled out** — 0 of
     5,726, with controls in both directions, closing the leading candidate
     `docs/research/audio.md` §4 had proposed and never tested. The remaining **4** names carry the
     `99` level prefix or have no shipped variant at all, and read as references to cut content
     (`LIKELY`). Chance/level-context selection — which alternative wins at runtime — is engine
     behaviour and remains deliberately undecided.
     **Consequence for item 2 below: audio export now has essentially total source coverage.**
   - **Note:** the earlier "those settings do not exist" reading was recorded by the Claude session
     while auditing the roadmap, and was correct about the actors and wrong about the game. The
     audio track was worked concurrently by another session until 23 Aug 2026, when this session
     took it over.
2. ~~Export FSB/native audio to UE5 SoundWave/SoundCue manifests, keeping the original MP3/WAV.~~
   **Manifest and payload export done, 23 Aug 2026 — not yet listened to in UE5.**
   `Core/Export/AudioExporter.cs` writes a versioned `ue5_audio_manifest.json` plus the shipped
   payloads byte-for-byte (no transcoding), and `export-audio <package> <out-dir> [--locate]` drives
   it. On `0-Lighthouse`: **1,447 cues, 2,106 waves, 31 placed actors, 0 unresolved samples.**
   `AudioExportTests` (6/6).
   - **The mapping is near one-to-one because the game's structure already is one.** A
     `SoundEffectSpecification` carries alternatives, attenuation radii, volume and pitch ranges and
     looping state — which is what a `USoundCue` is made of. No graph is invented.
   - **Inheritance is preserved, and that is the assertion that matters.** A property the object does
     not serialize is *omitted* from the JSON, so the script-class default stands. Writing `0` for an
     absent `OuterRadius` would silently un-attenuate the sound while the manifest looked complete.
     Pinned twice — on the document and on the emitted JSON.
   - **`AudioSampleLocator` (new) indexes all four stores.** Added because the first cut reported
     **908 unresolved samples** for `0-Lighthouse`, every one of which ships perfectly well
     elsewhere; a figure that reads as missing audio and is not is exactly the failure this project
     exists to avoid. "Not in this package" and "in no shipped store" are now distinct, and the
     CLI says which it means.
   - **Surface classes are exported, not acted on.** Each alternative carries its `MVT_*` name
     (3,245 of 3,245 on `0-Lighthouse`). That the runtime *dispatches* on it remains `LIKELY` —
     `PickSoundToPlay` is native and unreadable.
   - **Not done, deliberately:** streamed payloads are located (bank + subsound index) but not
     decoded on export, because sweeping all 10,882 subsounds is the kind of large implicit job §60
     forbids starting unasked. **And nobody has imported this into UE5 and listened to it** — a
     manifest can be numerically perfect and play the wrong sample. That is the next step, and it is
     the same "render it" rule that has caught real faults here before.
3. Particle/emitter templates and material parameters — enough to build real UE5 Niagara
   placeholders, not a static mesh standing in for an effect.
   **Census done, 23 Aug 2026 — the decode half is scoped from measurement rather than from
   Medical.** `docs/research/effects.md`, pinned by `EmitterTemplateCensusTests` (all 161 shipped
   packages, proved able to fail). What ships: **1,859 actors carry an `Emitters` array across 20
   packages, referencing 3,211 templates with a vocabulary of 120 distinct properties.**
   - **Two facts that bound the mapping.** **0 of 3,211 references are imports** — an effect never
     crosses a package boundary the way a material can, so whatever a level needs, that level
     ships. And **0 of 3,211 property walks truncate**, so those 120 names are the whole
     vocabulary rather than a readable prefix of it.
   - **`SpriteEmitter` is 96.0%** (3,084), then `MeshEmitter` 57, `BeamEmitter` 50,
     `MultipleRibbonEmitter` 13, `RibbonEmitter` 7. All 57 `MeshEmitter` templates carry
     `StaticMesh` and no other class does — which is why sprite-only is *wrong* rather than
     approximate for that one class: it is this item's own "static mesh standing in for an effect"
     failure, inverted.
   - **The typed subset is 4 of those 120** (`Material`, `MaxParticles`, `ParticlesPerSecond`,
     `InitialParticlesPerSecond`) — correctly scoped when the placement array's job was to
     *identify* templates, and not enough to build a placeholder. The fields a placeholder needs
     and does not have are listed with their shipped counts in §5 of the research note; all are
     present on thousands of templates, so none of it is edge-case work.
   - **Blocked, specifically, on eleven byte enums** (`Blending`, `CoordinateSystem`,
     `StartLocationShape`, …): the values read, the *meanings* do not, and the declarations are
     not in `Bioshock1REMSDK-WIP--main` (grepped, not assumed). The one real lead is Track B's
     decompiler — UE2 declares them on `Engine.ParticleEmitter`, and `Engine.U` is exactly the
     package that crashes it. Same blocker already recorded, not a new one. **A placeholder must
     not blend or colour from a guess** until that resolves.
   - **`EmitterTemplateData` widened, 24 Aug 2026, user-authorised** (the `Core/Level/` claim
     collision above was raised and the user said to proceed). **31 of the 120 fields are now
     typed, up from 4** — every field §5 listed as needed for a placeholder, including the three
     curve arrays. `Range`/`RangeVector` turned out to be nested tagged-property structs (25/116
     bytes), not fixed-size packed floats like `Vector` — read with the same nested-list idiom
     `ReadRegion` already used.
   - **The curve arrays turned out to be the same nested-struct shape as an array element, not a
     separate reverse-engineering task as first assessed.** `SizeScale`/`SegmentSizeScale` are
     `[{RelativeTime, RelativeSize}]` (25B/key); `ColorScale`/`SegmentColorScale` are
     `[{RelativeTime, Color}]` (30B/key); `VelocityScale` is `[{RelativeTime, RelativeVelocity}]`
     (39B/key). `ReadStructArrayElements` reads each key by its own terminator rather than a
     computed stride, and requires the compact count and every key to consume the array's complete
     value or the curve reads null rather than partial. `SubdivisionScale`/`RevolutionScale` (6/1
     hits) are almost certainly the same shape but weren't worth a probe pass at that frequency —
     the one thing still deliberately left out of the 120.
   - Pinned against real bytes by `EmitterTemplateFieldTests` — a `SpriteEmitter` (21 of 24 scalar
     fields present, plus all three curves — its `ColorScale` carries alpha 0 and 30, not 255,
     which is exactly the kind of value a placeholder assuming opaque would get wrong), a
     `MeshEmitter`'s `StaticMesh`, a `RibbonEmitter`'s segment curves, and the export-manifest
     path — proved able to fail. **Still no Niagara mapping** — this is the decode half only, and
     the byte enums' meanings are unchanged from `UNKNOWN` — now confirmed as blocked specifically
     on the `Engine.U` decompiler crash (Track B item 4 below), not merely undecoded.
4. Interaction metadata (movers, doors, triggers, plasmid/weapon effects) once the source object
   graph backing them is known.
   - **First slice landed, 24 Aug 2026 — movers' trigger wiring and start pose.**
     `docs/research/interaction.md`, `MoverActorSchemaTests`. `Mover`/`ScriptableMover` (94 + 15
     actors across 15 packages, 0 incomplete) now export `TriggeredBy` — the comma-separated names
     that trigger the mover, e.g. `MeatLockerDoorScript, MeatLockerOn` — which is literally the
     "source object graph" this item names, plus `InitialState`, `BasePos`/`BaseRot`, `MoveTime`,
     `StayOpenTime` and the two byte enums (`MoverEncroachType`/`MoverGlideType`, raw values,
     meanings `UNKNOWN`). Gated on the exact class name: `Int_FireMover` shares the word "Mover"
     but not the shape (confirmed by reading it, not assumed) and correctly gets no record.
   - **The graph resolved and wired in, 24 Aug 2026 — `TriggeredBy` matches another actor's
     `Label`, not `Tag`.** 103 names across every package with movers, `Tag` and `Label` both
     already decoded generically for every actor: **88 (85.4%) match a `Label` in the same
     package, 0 match a `Tag`** — ruling out the obvious UE1/2 `Trigger`→`Tag` convention rather
     than leaving it assumed. **Every one of those 88 resolves to a `Script` actor, no
     exceptions** — a mover is triggered exclusively through the level's script layer, never
     directly by a door or switch. **All 88 are unambiguous**, checked against a game where `Label`
     is otherwise far from unique (one auto-numbered name repeats 962 times in a single package).
     The 15 unresolved (`MoveMe`, `TurretControlSwitchScript`, ...) read as UnrealScript state
     names a script calls directly, not object references — `LIKELY`, consistent with
     `InitialState` already being a state name in the same records. **Now typed**:
     `MoverActorData.ResolvedTriggers`, populated by a new `LevelAnalyzer.ResolveMoverTriggers`
     second pass that runs once per package after every actor is built (the one piece of
     interaction metadata so far that needs the whole package, not just its own actor's bytes) —
     pinned by `MoverActorSchemaTests`, including a game-wide regression against ambiguity.
   - **Deliberately not decoded: the keyframe motion path (`KeyPos`/`KeyRot`).** They're UE1/2
     fixed-array properties (repeated same-name entries distinguished by `ArrayIndex`), a pattern
     with no precedent elsewhere in this codebase, and the "index 0 is implicit, equals
     `BasePos`/`BaseRot`" reading is an unverified `HYPOTHESIS`. A wrong key count or order here is
     exactly the "numeric validation passes on visibly wrong output" failure mode this project has
     already hit — this needs a render check, not just a parse, before it's typed.
   - **Triggers' own `TriggeredBy` closed, 24 Aug 2026 — checked at whole-game scale and it isn't
     a name at all.** All 25 shipped occurrences (`TriggerVolume`/`TriggerRadius`/`ZoneInfo`) are
     the literal string `"Player"` — a class filter, not an object reference, so the mover
     resolution mechanism doesn't apply. `TriggerOnlyByLabels` (a separate already-decoded array,
     mostly `"Player"` but also carrying names like `Steinman`/`Cohen`/`FinalAmbushDude`) was
     checked against every already-decoded name field — `Tag`, `Label`, `Spawner.InitialLabel` —
     and none resolves more than 1 of 62. `LIKELY` an AI-archetype/character-identity filter
     resolved through a system this project hasn't decoded. Left open rather than chased further —
     a genuinely separate investigation from movers' `TriggeredBy`, not a variant of it.
   - **Doors decoded, 24 Aug 2026 — `DoorActorData`.** The game ships ~50 door-named classes with
     no naming convention consistent enough to enumerate, so this is gated on field presence
     instead: any actor carrying `DoorPortal`, `bLocked`, `bInitiallyOpen`, `OpenAnimationRate`,
     `CloseAnimationRate`, `DelayBeforeOpening` or `StayOpenDuration` gets a record. Verified
     whole-game that the gate can't misfire — every class carrying any of those fields has `"Door"`
     in its name, and none outside that family does. **353 door actors across 18 packages, 0
     incomplete.** `DoorKeypadControl` (a singleton interaction record that happens to share the
     word "Door") correctly gets no record, confirmed by reading it rather than assumed. A
     bookkeeping fix landed alongside it: `PathList`/`PathCollisionRadius` were already decoded
     generically for any actor (doors included) but missing from the `Interpreted` property-name
     set, so doors were showing them as uninterpreted when they were already typed. Pinned by
     `DoorActorSchemaTests`.
   - **`DoorSwitch` decoded separately, same day — and a real gating mistake caught before it
     landed.** `DamageResistanceSetName`/`UseVerbText`/`OverlayMaterial` were first implemented
     with `DoorActorData`'s field-presence gate, on the assumption a door-scoped census meant they
     were door-specific. A whole-game check said otherwise: all three are generic
     interaction/combat properties shared by 16+ unrelated classes (`BandagesPickup`,
     `ArmorPiercingBulletPickup`, `Cabinet`, a generic `Switch`, ...) — that gate would have
     attached a record to 98 actors in `1-Medical` alone, 94 of them not door switches. Fixed
     before landing: gated on the exact class name instead. **37 `DoorSwitch` actors across 8
     packages, 0 incomplete.** `UseVerbText` is the on-screen interaction prompt (`"Look"`,
     `"TURN LATCH"`) — genuinely useful, and empty string is a real shipped value, not absence.
     **`DamagedReactions`/`UsedReactions` decoded too, 25 Aug 2026** — turned out to be the same
     `ReadStructArrayElements` shape `OnFiredEffects`/`TracerEffects` below already use, not the
     `KeyPos`/`KeyRot`-style risk this line originally worried about. A generic engine
     reaction-framework record (`Reaction` names the handler class that fires; several other slots'
     meaning is UNKNOWN, carried raw). `DoorSwitchReactionData`; `docs/research/interaction.md` §5.
     **A real, separate display bug caught in the process**: the `properties` CLI command's `Bool`
     case always printed the literal `"true"`, regardless of the actual value — fixed.
     `Attachments` on doors decoded 25 Aug 2026 (see the item closeout below). `ScriptedSequence`
     decoded the same day — nested `ScriptedAnimations` is `Chance`+`Animation` (FName).
   - **Weapon effects landed, 25 Aug 2026 — `OnFiredEffects`/`TracerEffects` decoded from class
     defaults, not placed-actor payloads.** A weapon (`MachineGun`, `Pistol`, `Shotgun`, ...) is
     never placed in a level, so this is the one interaction-metadata source that reads a `Class`
     export's own defaults rather than `ActorPayload`. Each array element names an `EmitterClass`,
     decoded with the exact same `LevelAnalyzer.ReadEmitterTemplate` reader a placed actor's
     `Emitters` array already uses, and `OnFiredEffects` elements carry an optional `LightClass`
     (a different shape, read directly: brightness/colour/radius/lifespan). `WeaponEffects.For` in
     `src/BioShockStudio.Core/Assets/WeaponEffects.cs`; CLI `weapon-effects <package> <class>`;
     `WeaponEffectsTests`. Verified against real bytes: `MachineGun` 4 `OnFiredEffects` / 3
     `TracerEffects`, `Pistol` 1, `Shotgun` 12 — every count matches an independent UELib
     decompile of the same classes exactly. **A real bug caught first**: the initial draft only
     accepted `Class`-typed reference fields; every one of these actually wire-encodes as `Object`
     (`Class'...'` is only how the decompiler renders it), so every emitter/light silently resolved
     to null with a clean build until this was caught by running the CLI against real data and
     reading the output, not by trusting the exit code. `docs/research/interaction.md` §6.
     **The flat-property shape decoded too, same day.** `EmitterAmmo`-derived ammo classes
     (`ChemicalThrower_LiquidNitrogen`/`_IonicGel`/`_Kerosene`) name their effect directly on a flat
     `EmitterClass`/`HighPressureEmitterClass` pair rather than through the array — resolved via the
     same `ResolveEmitter` helper, exposed as `WeaponEffectsData.EmitterClass`/
     `.HighPressureEmitterClass`. `CONFIRMED_BYTES` against all three ammo types, matching the
     UELib decompile exactly; a weapon that uses the array shape instead correctly reports neither
     flat property.
     **Plasmid ability flat properties landed, 25 Aug 2026** —
     `WeaponEffects.ResolveEffectProperty` for arbitrary property names:
     `SecurityBeaconAbility.ProjectileClass`, `SpringBoardTrapAbility.TargetIndicatorClass`,
     `TrapBoltProjectile.BeamEffectClass`, and (after the ClassDefaults longest-walk fix)
     `BerserkRageAbility.ProjectileClass` → `EnrageProjectile`.
     **String-path shape also landed:** `DecoyHumanAbility.TargetIndicatorClassString` →
     `"FXClass.DecoyHumanTarget"` via `WeaponEffects.ResolveEffectClassString` (`CONFIRMED_BYTES`);
     the named class is not a local `ShockGame.U` export (`Resolved` null — where those class
     bytes live is `UNKNOWN`). **Door `Attachments` landed, 25 Aug 2026** — 17 doors across
     `2-Fisheries` and two Challenge Room maps; mesh-on-socket structs. **`ScriptedSequence`
     landed, 25 Aug 2026** — 109 actors, 0 doors; nested `ScriptedAnimations` is `Chance` +
     animation FName. **Still open within this item:** `KeyPos`/`KeyRot` deliberately deferred
     pending a render check. `docs/research/interaction.md` §5–§7.

### Gate 5 — deterministic UE5 importer (the actual end goal)

**Moved to `docs/UE5_FULL_PORT_PLAN.md`, 25 Aug 2026** — that document is the actual UE5 strategy
(phases, risks, decisions) and had grown a parallel, overlapping status record of its own (§9); this
gate's item-by-item detail duplicated it rather than adding anything. It's kept there now, as dated
entries in §9, not here.

Current shape, in brief — see the linked doc for the full evidence behind each:

1. Manifest versioning + idempotent imports — **done**, 23 Aug 2026.
2. Keep source exports immutable under `_ue5_normalized/` — already the shape in place.
3. A UE5 validation map + per-level import report — **done**, 23 Aug 2026; `1-Medical` proof of
   concept — **done**, 24 Aug 2026; level-placed characters as real `SkeletalMeshActor`s — **done**,
   25 Aug 2026; `CubemapProbe` → `SphereReflectionCapture` in `import_level.py` — **code 25 Aug
   2026, not visually confirmed**. **The Phase 0 vertical slice's asset half — done, 26 Aug 2026**:
   `1-Medical` + one enemy archetype + one weapon imported in one pass into a saved 14 MB `.umap`
   and checked from the level *reloaded off disk*, identical census across the round trip, arch
   canary 2422.0. Not playable — that needs Phase 3. **Rig skip-on-exists — done the same day**:
   fingerprint of the export, proven to refuse a stale stamp and a missing animation.
   **Phase 3 runtime skeleton, first slice — done, 26 Aug 2026**: plugin classes compile and load;
   ShockPlayer capsule/walk/jump/health match ShockGame.U schema. Standing CollisionHeight is
   **68** (`VPawn` in `VengeanceShared.U`; Engine.U `Pawn`'s 78 is not the player value).
   **Possess setup on Medical umap — done same day**: ShockGameMode + MedicalStart PlayerStart
   survive reload; editor pilot of schema-applied ShockPlayer. PIE possess not claimed (headless
   PC.Possess AVs). **ActionWait first slice — done same day**: Seconds from Scripting.U schema +
   wake check; not on a script graph yet. **ActionSetProperty first slice — done**: Label write
   only; full SetPropertyText open. **ActionIf first slice — done**: OR + true/else branch choice.
   Next census: ActionPlayEffect. **ActionPlayEffect first slice — done**: ScriptTrigger record
   fire; no FX yet. **ActionNonBlockingExecuteScript first slice — done**: records targetScript,
   block=false; no Script VM. Next: ActionSetLightProperties.
4. An app-facing "export to UE5" workflow — **deliberately not started**; a product decision, not a
   decode, pending a call on whether the app should carry this at all.

### Track B — UnrealScript bytecode / game-logic decoding

Opened alongside the UE5 track on 18 Aug 2026 ("do both" — pursue UE5 import and game-logic
decoding in parallel). **Went well past a reference survey, 19 Aug 2026: BioShock's own game logic
is now readable.** `docs/research/bytecode.md` has the full record;
`tools/uelib-bridge/` is the reusable tool.

`Unreal-Library-master` (UELib) turned out to have first-class, explicit BioShock/Vengeance support
— not just generic UE2 coverage. Its own build files target a `net10.0` this repo's SDK doesn't
support, so `tools/uelib-bridge/` compiles its source directly against `net8.0` instead. Once
building, it decompiles BioShock's actual shipped script packages to readable UnrealScript:
**1,445 classes across 11 of 12 packages, 0 failures** (`Engine.U` crashes during package
initialization on one version-gated field — a real, lower-priority gap, not chased further since
it's mostly stock engine base classes rather than BioShock's own logic). Independently
cross-validated: the decompiled `Pistol.uc`'s animation and mesh names match this project's own,
completely independently byte-derived animation-package findings exactly.

This means the practical question Track B exists to answer — "what does BioShock's game logic
actually do" — can already be answered for almost everything by regenerating and reading the
decompiled output, without first building an independent decoder. What remains:

1. ~~Survey UModel/UELib/Unreal-Library/Bioshock1REMSDK-WIP and UE2's own UDN documentation for the
   opcode table and bytecode framing.~~ **Far exceeded** — a working decompiler run against the
   real game, not just a reference survey.
2. **Use the decompiled output as documentation** going forward, the same way other reference
   projects' docs already get read, whenever a specific class or function's behavior is in
   question elsewhere in this project. Regenerate via `tools/uelib-bridge/`; never commit the
   output (game-derived, same reason no extracted textures/meshes/audio are committed).
3. **Only if an independent, from-scratch decoder is still wanted** separately from reading UELib's
   output: verify the bytecode length-framing hypothesis (`bytecode.md` §4) against this project's
   own byte reader, then hand-walk one simple function's bytecode against the opcode table before
   generalizing.
4. **Its classes now do turn out to matter, confirmed 24 Aug 2026** — Gate 4 item 3's eleven
   emitter byte enums (`Blending`, `CoordinateSystem`, ...) are declared somewhere in `Engine.U`
   specifically, not BioShock-side: the five emitter classes and any `ParticleEmitter` base were
   searched for and not found in any of the other 11 packages the decompiler already handles
   (`docs/research/effects.md` §6). The crash is in `UClass.Dependency.Deserialize` reading a
   version-gated `bool` — `Unreal-Library-master` already special-cases one other build's
   `Dependency.IsDeep` field the same shape of way, so there's a concrete fix shape, just not
   verified for BioShock's version. **Not attempted** — patching UELib and re-verifying the other
   11 packages still decompile clean is its own scoped task, deferred rather than opened inside
   Gate 4 item 3. Expand the native-function ID table beyond `coop-natives-map.md`'s partial
   coverage if needed, separately.

---

## Test health

The project holds itself to two tiers:

```bash
dotnet test --filter Tier=Fast      # single-package/no-package tests, seconds
dotnet test --filter Tier=Sweep     # whole-game censuses, bulk store, UI, ~20 min
dotnet test                         # both — the number to report
```

### Verification stamp — read this before running anything

**Last full-suite run: 550/550 GREEN — 23 Aug 2026, 43m36s, at commit `9cb53b2`.**
Supersedes the 546/550 red stamp taken earlier the same day at `9b2036f`, and the 464/464 at
`1c2e4b2` before it.

**The four failures that earlier stamp recorded are fixed and the fix is now confirmed at
whole-suite level** (`43dcaaa`, `1782d3b`). What they were:

| Test | Its own class's count | Bucket total it summed |
|---|---|---|
| `MarkerActorSchemaTests.EveryMedicalMarkerIsOnlyAPlacedCommonActorRecord` | `Marker` 150 | `MarkerPending` 159 |
| `PickupActorSchemaTests.EveryMedicalHypoPickupExportsItsResolvedLootSlot` | `MedHypoPickup` 11 | `InteractionPending` 16 |
| `TrainingScriptActorTests.MedicalTrainingConceptArraysDecodeExactlyAndReachTheManifest` | `TrainingScript` 26 | `ScriptPending` 326 |
| `VendingActorSchemaTests.EveryMedicalVendingStationExportsItsInteractionDeclaration` | `PlaceableVendingStation` 3 | `InteractionPending` 16 |

**The direction of the change turned out to be neither regression nor over-capture: nothing about
these classes moved at all.** Each test summed a `LevelActorCoverage` status bucket across *every*
class, as if the total uniquely identified its own, so each later commit that correctly routed one
more class into a shared bucket broke every test carrying a stale total for it — while that test's
own class stayed exactly where it was. No production decoder changed; the fix filters to the test's
own `ClassName` before summing, the idiom `MapUiMarkerSchemaTests` and `CoverageBoundaryActorTests`
already used.

**The arithmetic, re-confirmed independently against the shipped bytes** (`level-audit 1-Medical`,
23 Aug 2026 — the counts the four tests assert, read straight out of the game rather than out of the
test): `MarkerPending` 159 = `Marker` 150 + `TrainingMarker` 6 + `MapUILayerScaleMarker` 3;
`InteractionPending` 16 = `MedHypoPickup` 11 + `PlaceableVendingStation` 3 + `DoorKeypadControl` 1 +
`dyn_toolbox_open` 1. Every per-class figure matches what its test asserts, which is the evidence
that the buckets were the only thing that moved. (This arithmetic previously lived only in the
retired `.agent/TASK_QUEUE.md`; it is recorded here because that file is gone.)

**Gate 3 item 3's "complete for its stated `1-Medical` ledger" claim is therefore no longer in
question** — the categories do partition, and the per-class census above is what shows it.

**The same landmine, swept.** `1782d3b` hardened `AntiPortalActorSchemaTests`,
`CubemapProbeActorTests` and `SpawnerActorSchemaTests` before they could break.
`InteractionActorSchemaTests` was the one left that was demonstrably wrong rather than merely
unguarded — it asserted `InteractionPending` summed over *every* class (16) while testing two of
them, and passed by numeric coincidence — and it is fixed here to assert its own 2. **That closes
the bucket rather than shrinking its coverage:** `InteractionPending` is now pinned per class and in
full, 11 + 3 + 2 = 16, across `PickupActorSchemaTests`, `VendingActorSchemaTests` and this one.

**What is deliberately left unfiltered, and why.** `EffectActorSchemaTests` (134),
`HavokConstraintActorSchemaTests` (6), `HavokForceActorSchemaTests` (12),
`LevelInfoActorSchemaTests` (1), `MapUiMarkerSchemaTests` (3, its `MapMarkerPending` line only),
`ProjectorActorSchemaTests` (21), `ShockAiScoutActorSchemaTests` (1) and `LevelSceneTests` still sum
a whole bucket. Each of those buckets holds one class today, so
they are the suite's only remaining canaries for a *new* class joining a bucket — the known gap
`docs/HANDOFF.md` §4 records as the cost of the filtering idiom. They are not oversights and should
not be "fixed" without replacing that signal. **`SoundActorSchemaTests` (345) is unfixed for a
different reason**: its scope reads as genuinely ambiguous rather than accidental, so narrowing it
would be a guess about intent.

**Measured after the 550/550 stamp, by name** — the tree has moved on since, and
`docs/ENGINEERING_RULES.md` §60 says run what the diff could have touched, not everything:

| Run | Result |
|---|---|
| `AudioExportTests` | **6/6** (2s) |
| `SoundActorSpecificationCoverageTests` | **4/4** (4m06s) |
| the seven bucket-fixed schema classes | **9/9** (1m03s) |
| `--filter Tier=Fast` | **249/249** (53s) |
| `EmitterTemplateCensusTests` | **1/1** (11s, all 161 packages) |
| `EmitterTemplateFieldTests`, `EmitterTemplateCensusTests`, `EffectActorSchemaTests`, `LevelSceneTests` | **18/18** (1m23s) |
| `--filter Tier=Fast` | **249/249** (1m01s) |
| `~Level` + `~Export` | **96/96** (4m59s), then **99/99** (4m39s) after `MoverActorSchemaTests` |
| `--filter Tier=Fast` | **249/249** (53s), re-confirmed after the mover decode |

Those cover everything added since `9cb53b2`: the audio exporter (`Core/Export/AudioExporter.cs`),
the sample locator (`Core/Audio/AudioSampleLocator.cs`), the rewritten sample-location census, the
last bucket-filter fix (`9cebd5a`, test-only), and the new emitter census (`EmitterTemplateCensusTests`,
test-only — no production code changed for it). No production code outside `Core/Audio` and
`Core/Export` has moved since the stamp. **The whole suite has not been re-run since that commit** and is reported
as such rather than as passing.

The recipe, which is a standing user instruction rather than a shortcut — see
`docs/ENGINEERING_RULES.md` §60 "Test-run economy":

```bash
git diff --stat 9cb53b2..HEAD                          # what could have moved since the stamp
dotnet test --filter "FullyQualifiedName~<Class>"      # run only what that covers
```

Run the whole sweep when the diff reaches shared machinery (package reading, the property walker,
the catalogue, the coordinate basis), when this stamp is many commits stale, or when a handover
reports the whole-suite total — **and move this stamp forward in the same commit when you do.**

**Superseded stamp, kept for its per-test classification.** Full suite: **464/464 passing** (measured
22 Aug 2026, 29m02s, after Gate 0 items 1 and 2 including
the roll correction — `ActorTransformReferenceTests`, `BspSurfaceCensusTests`,
`BspWorldCoverageTests`, `BspSolidityTests`, `ActorPlacementAgainstTheWorldTests`,
`BakedLightmapRenderTests`). Intermediate clean runs this session measured 452 and 458. The previous entry
here recorded 202 fast / 446 full; the fast figure was already stale when written, which is the
ordinary drift this section exists to catch. Classification below is
from the 19 Aug 2026 pass that first closed item 0.1; **item 0.1 stays done** unless a fresh run
reports a new failure, and this full run reported none. Classification, per test:

- `DocumentedFiguresTests` (4 checks) and `DiagnosticsTests.AReportSaysHowMuchItExamined` —
  **a real regression, fixed, in two parts.** First: `AssetDiagnostics.ScanExport` checked
  `MaterialReader.IsMaterialClass` before the texture-class check; since a `Texture` export is
  itself a valid material (`MaterialReader.SelfSlot`), every texture in the game was being
  swallowed into the Materials bucket and the sweep silently examined **0 textures**. Fixed by
  reordering the two checks. Second, found while working Gate 1 item 2 below:
  `AssetDiagnostics.ScanMesh` called `MeshGeometryReader.Read`'s byte-only 2-arg overload, so a
  `SkeletalMesh`'s `geometry.Sections` was always empty during the sweep, and `mesh-no-sections`
  fired for every multi-material skeletal mesh regardless of whether its section table had actually
  resolved. Fixed by calling the package-aware overload. `docs/QUALITY.md` and `README.md`'s
  figures updated to match what the sweep now correctly measures: 14,328 materials (was 13,545),
  202 `mesh-no-diffuse` (was 240), 110 `mesh-material-slot-unresolved` (was 123), 1
  `texture-undecodable` (was 46), 94 `mesh-materials-without-sections` (was 157, then 153 before
  that). Base-colour coverage moved from 96.4% to **96.8%**.
- `StructSizeTests.NoMaterialReportsAnInventedPropertyName` (`ZoningOnlyBrushMaterial` / `'Self'`)
  — **not a bug.** `ZoningOnlyBrushMaterial`'s class is `Texture`, and `MaterialReader.SelfSlot` is
  an already-documented, deliberate synthetic slot name for exactly that case (a `Texture` used
  directly as a material has no texture properties to name a slot from — it *is* the texture). The
  test didn't know about that one intentional exception; fixed the test, not the reader.
- `StructSizeTests.EveryMaterialInTheGameDecodesCompletely` (`3-Arcadia/LangScreenSwitch` truncated)
  — **a real, already-tracked gap surfacing for the first time**, not a fresh regression.
  `LangScreenSwitch` is a `MaterialSwitch`; its own `Materials` candidate array has no decoder yet
  (Gate 1 item 4 above), so the tagged-property walker runs past what it understands and reports one
  bogus trailing property. `IsMaterialClass` only started scanning `MaterialSwitch`'s own record
  directly (rather than just its default child) this cycle, which is what exposed it. The test now
  excludes `MaterialSwitch` specifically from the "must fully decode" assertion, with a comment
  explaining why, rather than guessing at the candidate-array format to force it green.

While fixing the first item, also hardened `MaterialReader`'s `MaterialSwitch` child-following: it
now checks the referenced default child is actually a class the reader understands
(`IsMaterialClass`) before recursing into it, rather than assuming every switch's declared child is
shader-shaped.

`DocumentedFiguresTests` pins every headline number in `docs/QUALITY.md` against a live run of the
whole-game `diagnose` sweep — a documented figure that stops being true fails a test instead of
rotting silently in prose. Never relax that assertion to make it pass; classify the failure
(`docs/ENGINEERING_RULES.md` §24) before touching either the code or the figure.

## Where the source of truth actually lives

This file is orientation, not the record. For anything load-bearing:

- `docs/ENGINEERING_RULES.md` — house rules, non-negotiable.
- `docs/HANDOFF.md` — current state table, architecture, and the landmines list (things that cost
  real time to find — read before touching coordinate systems, Havok decoding, or the material
  walk).
- `docs/QUALITY.md` — every headline mesh/material/texture/animation figure, each pinned by a test.
- `docs/research/*.md` — one file per format area, with confidence labels
  (`CONFIRMED_BYTES`/`PLAUSIBLE`/`UNKNOWN`) and the byte evidence behind each claim.
- `docs/HANDOFF_UE5_IMPORT.md` — the full UE5/FBX investigation record (superseded by `tools/ue5/`
  for current usage, kept as investigation history).
- `tools/ue5/README.md` — how to actually run the UE5 import bridge today.

## Explicitly not a shortcut

No destructive cleanup, synthetic test fixtures, guessed format fields, or a UE5 UI button before an
editor import has been observed to work. Every closed item above kept the real-data-test and
rendered/verified-output standard; nothing on this list gets to skip it going forward.
