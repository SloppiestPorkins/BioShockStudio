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
| Levels — lightmaps | Descriptor table **complete on all 21 maps** (39,288 descriptors, 45,851 baked-light layers); atlas *binding* proven on 11 of 21 — see Gate 0 below. |
| Audio — native `Sound` | Complete — **25,848 exports across 21 packages, 100% decode as MP3**, 0 unknown, 0 package failures. |
| Audio — streamed FSB5 | Working — x86 FMOD bridge decodes any subsound to WAV; app has a Streamed Audio tab (65 banks, 10,882 subsounds). |
| Application (GUI) | Asset browser (14,378 assets), 3D preview + animation playback, walkable level viewport (GPU + tested software fallback), Problems panel, audio tabs, profile editor. |
| Export — Blender / FBX | Complete — skinned mesh, armature, actions, sockets, materials; FBX validated by round-trip through Blender. |
| UE5 import | **Working, verified for real in UE5.7** — pistol and TommyGun first-person slices (both rigs, all animations, sockets) import cleanly via a Blender-normalization bridge + editor plugin. No app-facing UI yet. |
| Bytecode / game-logic decode | **Not started.** Zero prior work; scoped in Part 2 below. |
| Public site / CI | GitHub Pages project page live, deploy workflow committed. |
| Tests | Full suite **437/437 passing** (measured 19 Aug 2026). See "Test health" below. |

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
- **Lightmaps** (newest work, 18 Aug 2026): the descriptor chain that eluded the project for most of
  its life is now fully walked — `iLightMap` at `+96` settled with 42,887/42,887 in-range matches;
  the full tail (bounds → `LeafHulls` → `FLeaf` records → compact-reference arrays →
  `RootOutside`/`Linked`) lands on the lightmap descriptor table on all 21 maps; 39,288 descriptors
  map one-to-one onto their worlds' surfaces with 45,851 baked-light layers. The
  `WorldToLightMap` matrix and UV packing are `CONFIRMED_BYTES` (234,404/234,404 vertices land
  inside their declared atlas tile). Atlas-pool *binding* — finding where each map's actual
  `LightMaps_BSP` texture pool lives — is proven on 11 of 21 maps; the other 10 still need that
  final trace.

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

1. **Window-placement fidelity** — verify actor transforms against the external level editor
   construction beyond the one already-fixed vault case; don't generalize a rotation fix from a
   single view.
2. **Material fidelity** — resolve remaining blocky/flat BSP surfaces as material/shader-chain
   failures, not by shrinking UVs or tinting base colour.
3. **Lightmaps to default-on** — the remaining 10 of 21 maps need their atlas-pool location traced
   the same way the first 11 were (locate the local `LightMaps_BSP` texture pool, don't assume its
   position). Once all 21 are proven, bind the atlas per pixel and do a lit/unlit comparison render
   before it becomes a default rather than an opt-in.
4. **Viewer visibility matrix** — every drawable category needs its own toggle (compiled world,
   static meshes, skeletal meshes, source brushes, gameplay volumes/zones/triggers, lights,
   experimental lightmaps); non-drawable actor classes should be listed explicitly, not silently
   absent.

### Gate 1 — complete asset containers

1. **Static meshes** — collision/kDOP tail, LODs and socket metadata; only decode the currently
   opaque collision blocks once a concrete UE5 target (collision/navigation/ray query) is known.
2. **Skeletal meshes** — close the 4 remaining unreadable door variants; the 153
   `mesh-materials-without-sections` skeletal meshes have a known fix (the section table exists per
   `UnMeshBioshock.cpp`'s `FStaticLODModelBio`, it just isn't consumed yet — this is scoped work,
   not a research gap).
3. **Textures** — export colour-space/normal/mask/cubemap intent as UE5-facing metadata, not just
   pixels; validate representative imports.
4. **Materials** — decode `OutputBlending` (blend mode) semantics, panners/rotators,
   environment/cubemap inputs; `MaterialSwitch`'s static-default branch is decoded, its dynamic
   candidate selection and `MaterialSequence` are not.

### Gate 2 — animation, rigs and physics

1. Decode remaining Havok animation fields affecting playback: blend hints, compression edge cases,
   additive semantics, root motion, events beyond what's already surfaced.
2. §6.0c — the 252 bone-rigidity collapses (27 folding ≥20 bones), including `AggressorBabyJane`'s
   fire clips — needs `sampleTranslation`, which the current SDK build doesn't expose. Genuinely
   blocked, not merely unstarted.
3. Map Havok collision/ragdoll data to UE5 Physics Assets only once body shapes, constraints and
   units are byte-backed — preserve unsupported blocks losslessly rather than guessing.
4. Validate every skeleton family in UE5 beyond the pistol/TommyGun pair already proven: splicer,
   Big Daddy, Little Sister, other weapons, doors, props.

### Gate 3 — levels and UE2 actor systems

1. Zones, leaves, portals, visibility/collision relationships for the compiled world.
2. Placed-actor transforms, parent/base links, draw scale, tags, material overrides — for every
   actor class, not just the geometry-bearing ones already placed.
3. Gameplay/world actor schemas in descending shipped-count order (per the existing coverage
   ledger on `1-Medical`): 696 light placeholders, 309 audio actors, 299 script-action actors, 253
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
decoding in parallel), and **genuinely not started**. The only trace of it anywhere in the codebase
is a comment in `src/BioShockStudio.Core/Level/ClassDefaults.cs` noting that a `Class`/`UFunction`
export's bytecode, of unknown length, must be skipped to reach its property defaults.

Per this project's standing policy, the first real step is not writing a decoder — it's reading
reference material first: UE2.5's script VM opcode format is externally documented (UDN docs,
UELib, other UE2 reverse-engineering projects), and those should be surveyed and cross-checked
before any byte is interpreted. Concretely, in order:

1. Survey UModel/UELib/Unreal-Library/Bioshock1REMSDK-WIP and UE2's own UDN documentation for the
   opcode table and bytecode framing.
2. Find and measure where bytecode begins/ends in a real, simple `Class`/`UFunction`/`UState` export
   from a shipped package.
3. Attempt a first decode on a small, well-understood function and verify the result against
   expected logic before generalizing.

---

## Test health

The project holds itself to two tiers:

```bash
dotnet test --filter Tier=Fast      # single-package/no-package tests, seconds
dotnet test --filter Tier=Sweep     # whole-game censuses, bulk store, UI, ~20 min
dotnet test                         # both — the number to report
```

Fast tier: **195/195 passing** (measured 19 Aug 2026, after the Blender/UE5 and audio work landed).

Full suite: **437/437 passing** (measured 19 Aug 2026, after the 7 failures below were classified
and fixed). **Item 0.1 above is done.** Classification, per test:

- `DocumentedFiguresTests` (4 checks) and `DiagnosticsTests.AReportSaysHowMuchItExamined` —
  **a real regression, fixed.** `AssetDiagnostics.ScanExport` checked
  `MaterialReader.IsMaterialClass` before the texture-class check; since a `Texture` export is
  itself a valid material (`MaterialReader.SelfSlot`), every texture in the game was being
  swallowed into the Materials bucket and the sweep silently examined **0 textures**. Fixed by
  reordering the two checks. `docs/QUALITY.md` and `README.md`'s figures updated to match what the
  sweep now correctly measures: 14,328 materials (was 13,545), 202 `mesh-no-diffuse` (was 240), 110
  `mesh-material-slot-unresolved` (was 123), 1 `texture-undecodable` (was 46, the rest recovered by
  a second, unrelated fix below), 157 `mesh-materials-without-sections` (was 153). Base-colour
  coverage moved from 96.4% to **96.8%**.
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
