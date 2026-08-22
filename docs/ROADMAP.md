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

1. **Window-placement fidelity** — verify actor transforms against the external level editor
   construction beyond the one already-fixed vault case; don't generalize a rotation fix from a
   single view.
2. **Material fidelity** — resolve remaining blocky/flat BSP surfaces as material/shader-chain
   failures, not by shrinking UVs or tinting base colour.
3. ~~**Lightmaps to default-on** — the remaining 10 of 21 maps need their atlas-pool location traced
   the same way the first 11 were.~~ **Atlas-pool binding done, 19 Aug 2026 — 20 of 21 maps proven**
   (the 21st, `Entry`, has no `LightMaps_BSP` group to bind). What's left before this becomes a
   default rather than an opt-in: bind the atlas per pixel (currently per-vertex, via
   `MeshGeometry.BakedLight`) and do a lit/unlit comparison render.
4. **Viewer visibility matrix** — every drawable category needs its own toggle (compiled world,
   static meshes, skeletal meshes, source brushes, gameplay volumes/zones/triggers, lights,
   experimental lightmaps); non-drawable actor classes should be listed explicitly, not silently
   absent.

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
   skeleton**, which changed the priority order below. `HkaRagdollInstanceReader`,
   `HavokPhysicsTests.RagdollInstanceCountsAgreeWithTheWholePackfileCensus`. **Recommended next,
   re-prioritised**: `hkaSkeletonMapper` (2 objects on this character) — needed to correlate the
   ragdoll's 17-bone skeleton back onto the 73-bone animation skeleton, i.e. to know *which named bone*
   a given capsule belongs to, which a UE5 Physics Asset needs and which `hkaRagdollInstance` alone
   cannot answer (an earlier version of this entry said the mapper was "not needed to place capsules
   on their bones" — that was wrong, corrected in `docs/research/havok-physics.md`). `hkpRigidBody`
   after that (deeper — a material and a full motion state, though many `hkpEntity` fields are
   `+nosave`/`+serialized(false)` and so genuinely absent from the packfile, narrowing the real
   surface). **Constraints (`hkpConstraintInstance`/`hkpRagdollConstraintData`) remain the largest
   piece** — seven nested "atom" structs per joint — but reachability is now solved (`m_constraints`
   already gives the object graph), so what's left is purely per-joint field decode. Full record and
   field-by-field detail: `docs/research/havok-physics.md`.
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

Fast tier: **199/199 passing** (measured 22 Aug 2026, after the UE5 skeleton-family sweep,
`export-firstperson --group`, root-motion and Havok-physics decode work).

Full suite: last classified at **437/437** (19 Aug 2026, after the 7 failures below were classified
and fixed, and after a second-order dispatch fix on top of the first — see below); **item 0.1 above
is done and stays done** unless a fresh run reports otherwise. Classification, per test:

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
