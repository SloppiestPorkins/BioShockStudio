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
| UE5 import | **Working, verified for real in UE5.7** across every rig category the game ships — first-person weapons (pistol, TommyGun, Crossbow, ChemicalThrower, GrenadeLauncher), humanoid characters (splicer, both Big Daddy variants, Little Sister), mechanical doors/props/turrets and creatures (cat, crab, whale, giant squid, jellyfish, shark) — via a Blender-normalization bridge + editor plugin. See Gate 2 item 4 for the full list. No app-facing UI yet. |
| Bytecode / game-logic decode | **BioShock's own game logic is readable.** A working third-party decompiler (`tools/uelib-bridge/`) produces real UnrealScript source for 1,445 classes across 11 of 12 script packages, 0 failures, cross-validated against this project's own independent findings. See Track B in Part 2. |
| Public site / CI | GitHub Pages project page live, deploy workflow committed. |
| Tests | Full suite **464/464 passing** (measured 22 Aug 2026). See "Test health" below. |

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

**0.5 — Look at the pistol inside the UE5.7 editor with human eyes.** Every "verified in UE5.7"
claim to date is log evidence (`Success - 0 error(s), 7 warning(s)`, a clean `verify_bioshock_import`
run) — real, but this project has already learned that "a numeric check cannot see a wrong quantity
that is still present": six faults shipped in one session, every one passing the full suite, and a
user caught five of them by looking at the screen (`docs/NEXT_SESSION.md`). Nobody has opened the
UE5.7 editor and actually watched the imported pistol pose and animate yet. That's a ten-minute
check that closes a real, specific gap between "the log says it worked" and "it actually looks
right."

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

The single largest investigation of the last work cycle. UE5.7's legacy FBX importer rejected every
file this project's exporter produced with `File is corrupted` / `No mesh is found or animation
track`. An exhaustive byte-level audit — header, `GlobalSettings`, `Definitions` object counts vs.
actual, the `Connections` graph, transform properties, polygon winding and end-markers, skinning
cluster data, zlib stream validity, the trailing magic footer, and a full object-schema diff against
a known-good reference file — found the exported files were **not** malformed (independently
confirmed: Blender's own FBX importer opens them cleanly). The actual fix ended up being pragmatic
rather than a root-cause fix for the SDK's rejection:

- `tools/blender/normalize_fbx_for_ue5.py` re-exports every FBX through headless Blender before
  handing it to UE5 — Blender's re-export is byte-different in ways not yet fully characterized, but
  UE5.7 accepts it.
- A `BioShockImportTools` UE5 editor plugin (`tools/ue5/BioShockImportTools/`) restores the
  `SOCKET_*` markers that round-trip drops.
- `tools/ue5/verify_bioshock_import.py` checks an imported asset set against its manifest.

**Verified for real, not just documented**: a fresh pistol export run through
`import_bioshock.main` → `verify_bioshock_import.main` in a live UE5.7 editor session imported both
rigs and all 12 animations cleanly (`Success - 0 error(s), 7 warning(s)`, warnings cosmetic — missing
smoothing groups, sockets outside the bind pose). The TommyGun slice is verified the same way per
`tools/ue5/README.md`. No app-facing "export to UE5" button exists yet — this is still a
command-line/editor-script bridge, deliberately, per Gate 5 below.

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
   pack of *per-light* contributions in each light's own colour, a surface commonly has several
   (1,122 of `1-Medical`'s descriptors carry 2-10 layers), and this project applies only
   `Lights[0]`. The layers are not channel-packed: 0 of 1,122 put their layers on one tile.
   **Layer accumulation was then implemented, measured, and reverted** — it is not the answer.
   Summing every layer moved the render from mean luminance 10.5 to 14.0, because **most surfaces
   have only one layer** (1,668 of `1-Medical`'s 3,386 descriptors) and a single-layer surface shows
   the fault just as strongly. **What a tile's RGB means is `UNKNOWN`**, and §5.5e now records five
   measured constraints on any future answer — three light slots per layer, slot position refuted as
   a channel selector, only slot 0 ever singly occupied, 58.7% single-channel, and summed layers
   staying broadly in range. Two readings remain open: the tile is per-light radiance in that light's
   own colour, or the atlas channels are decoded in the wrong sense for this texture format. Nothing
   measured yet distinguishes them. Default-on stays blocked; the per-vertex GPU path has the same
   defect and merely blurs it.
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

1. **Static meshes** — collision/kDOP tail, LODs and socket metadata; only decode the currently
   opaque collision blocks once a concrete UE5 target (collision/navigation/ray query) is known.
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
3. **Textures** — export colour-space/normal/mask/cubemap intent as UE5-facing metadata, not just
   pixels; validate representative imports.
4. ~~**Materials** — decode `OutputBlending` (blend mode) semantics~~ — **already settled, not an
   open item.** `docs/research/open-questions.md` §11: `OutputBlending`'s declared values do not
   correlate with the alpha actually present in that material's own diffuse texture, so it is not
   Unreal's `EBlendMode` or any other rendering blend-mode selector — the renderer is already
   correct to ignore it and drive transparency from the texture's observed alpha instead. What's
   still genuinely open: panners/rotators, environment/cubemap inputs; `MaterialSwitch`'s
   static-default branch is decoded (19 Aug 2026 — see "What's done" above), its dynamic candidate
   selection and `MaterialSequence` are not.

### Gate 2 — animation, rigs and physics

1. Decode remaining Havok animation fields affecting playback: blend hints, compression edge cases,
   additive semantics, root motion, events beyond what's already surfaced.
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
   **Compression edge cases: genuinely still open** — nothing this cycle touched the spline
   decompression path itself (0 failures across all 16,031 already, per `open-questions.md` §3, so
   there is no known-broken case to chase, only unvalidated edge behaviour that hasn't been forced by
   a real shipped animation).
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
3. Map Havok collision/ragdoll data to UE5 Physics Assets only once body shapes, constraints and
   units are byte-backed — preserve unsupported blocks losslessly rather than guessing.
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
4. Validate every skeleton family in UE5 beyond the pistol/TommyGun pair already proven.
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

   **Still open:** what the zone record's constant trailing 20 bytes are (possibly a
   `VisibilityBitMask` or an unused environment default — no per-zone variation exists to correlate
   it against, so this may stay `UNKNOWN`); the other 6% where node visibility isn't a subset of
   zone connectivity; actual portal *geometry* (as opposed to zone-to-zone adjacency); and collision
   relationships.
2. Placed-actor transforms, parent/base links, draw scale, tags, material overrides — for every
   actor class, not just the geometry-bearing ones already placed.
3. Gameplay/world actor schemas in descending shipped-count order (per the existing coverage
   ledger on `1-Medical`). `level-audit` still correctly reports 696 `LightPending` — that label is
   accurate, it means "not yet placed as a real UE5 actor," not "undecoded." **The data schema
   itself is already done**: `LevelSceneExporter`'s `LevelLightDocument` exports location, colour,
   brightness and radius per light, tested end-to-end
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

   **Next in line, still genuinely open**: 309 audio actors, 253
   region/volume actors, 134 effect actors, then 338 genuinely unclassified actors. Navigation has a
   graph handoff (953 actors, 4,838 references) with UE5 movement semantics intentionally
   undecoded.
4. A deterministic level importer: create/update actor instances from the manifest, attach assets,
   apply transforms/overrides, and report created/updated/skipped/unsupported in one pass.

### Gate 4 — audio, effects, interactions

1. Cue/ambient/actor sound relationships beyond the notify chain already proven: chance/variation,
   attenuation, pitch/volume, language routing.
2. Export FSB/native audio to UE5 SoundWave/SoundCue manifests, keeping the original MP3/WAV.
3. Particle/emitter templates and material parameters — enough to build real UE5 Niagara
   placeholders, not a static mesh standing in for an effect.
4. Interaction metadata (movers, doors, triggers, plasmid/weapon effects) once the source object
   graph backing them is known.

### Gate 5 — deterministic UE5 importer (the actual end goal)

1. Version every exported manifest; make imports idempotent (a second run updates existing UE5
   assets rather than duplicating them).
2. Keep source exports immutable — Blender-normalized and UE5-generated files already live under
   `_ue5_normalized/`, separate from the source export, which is the right shape to keep.
3. Build one UE5 validation map containing an instance of every supported asset class, then a
   per-level import report.
4. Only add an app-facing "export to UE5" workflow once the command-line import reproduces cleanly
   on a fresh UE5 project — deliberately not sooner.

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
4. Lower priority: investigate the `Engine.U` crash if its classes turn out to matter; expand the
   native-function ID table beyond `coop-natives-map.md`'s partial coverage if needed.

---

## Test health

The project holds itself to two tiers:

```bash
dotnet test --filter Tier=Fast      # single-package/no-package tests, seconds
dotnet test --filter Tier=Sweep     # whole-game censuses, bulk store, UI, ~20 min
dotnet test                         # both — the number to report
```

Full suite: **464/464 passing** (measured 22 Aug 2026, 29m02s, after Gate 0 items 1 and 2 including
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
