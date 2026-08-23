# Open questions

Unresolved technical questions, deduplicated against `docs/research/open-questions.md` (which
carries the long-form investigation record and has many entries already CLOSED — do not re-open
those). This file is the short list an agent should actually work from.

**Rule:** answering one of these produces a `.agent/REPORT.md` with evidence, not a code change.
Code follows once the lead has accepted the evidence.

---

## Q1 — Where do the 1,970 unlocated sound samples ship?

**Question.** `SoundEffectSpecification` objects name 5,726 distinct samples. 2,080 are native
`Sound` exports and 1,676 are in the FSB5 banks — disjoint sets. **1,970 (34.4%) are in neither.**
Where are they?

**Why it matters.** It is the last substantive gap in the audio chain, and it blocks Gate 4 item 2
(exporting audio to UE5 SoundWave/SoundCue) for a third of the game's referenced sounds.

**Evidence already gathered.** `docs/research/audio.md` §4 rules out a raw byte search of
`Catalog.bdc` as inconclusive (it misses `Hand_DIFF` too, a texture that is certainly in the bulk
store, so the catalogue encodes its names). `BulkTextureCatalog` has **not** been pointed at a sound
name — that is the cheap, obvious, still-untried test. The unlocated names skew heavily
`ambience_*`.

**Relevant files.** `src/BioShockStudio.Core/Textures/BulkTextureCatalog.cs`,
`src/BioShockStudio.Core/Audio/SoundEffectSpecificationReader.cs`,
`tests/BioShockStudio.Tests/SoundActorSpecificationCoverageTests.cs`,
`docs/research/bulkcontent.md`.

**Best next investigation.** Run `BulkTextureCatalog` against ~20 of the unlocated names. It either
finds them or rules the bulk store out; either answer is worth having and it is a few lines.

**Agent.** Research.

---

## Q2 — What does `SoundSpecEntry.Flag` (0–27) select?

**Question.** Sample names group cleanly by this byte (`bullet_hit`: 0/1 default, 7/8 metal,
11 cardboard), which reads like impact surface. Nothing outside the names supports that.

**Why it matters.** It is the difference between exporting 78 undifferentiated alternatives and
exporting a surface-keyed sound set. It also decides whether A18 can be promoted from `PLAUSIBLE`.

**Evidence already gathered.** The name grouping, whole-game flag range 0–27. See
`KNOWN_ASSUMPTIONS.md` A18.

**Relevant files.** `src/BioShockStudio.Core/Audio/SoundEffectSpecificationReader.cs`,
`tools/uelib-bridge/` output (1,445 decompiled UnrealScript classes, 11 of 12 script packages).

**Best next investigation.** Grep the decompiled UnrealScript for the enum or the field name. The
game's own source is in the repository now and nobody has looked for this in it.

**Agent.** Research.

---

## Q3 — Why do 252 animations collapse bone rigidity, and is it fixable here?

**Question.** 252 bone-rigidity collapses (27 folding ≥20 bones), including `AggressorBabyJane`'s
fire clips (`PI_Fire`, `PI_Fire_B`, `PI_fire_C`, `smg_fire`).

**Why it matters.** It is ROADMAP Gate 2 item 2 and the only remaining known animation-quality
defect.

**Evidence already gathered.** **This is recorded as genuinely blocked, not unstarted.** It needs
`sampleTranslation`, whose body is not in this SDK build. The follow-up lead (`evaluateSimple1/2/3`
at u=0) was re-checked 22 Aug 2026 and is *also* closed: those functions are declared and
referenced but their bodies are nowhere in the SDK source tree (grepped, not assumed). What is
readable (`findSpan`, `getBlockAndTime`, `recompose`) agrees with this project's `NurbsBasis`. Four
candidate causes have been eliminated with evidence.

**Relevant files.** `src/BioShockStudio.Core/Havok/Animation/SplineCompression/`,
`tests/BioShockStudio.Tests/BoneRigidityTests.cs`, `docs/HANDOFF.md` §6.0c.

**Best next investigation.** **None of the ones already tried.** `docs/HANDOFF.md` §6.0c says
explicitly: do not re-open this specific comparison. A genuinely new lead would be a compiled Havok
binary containing the missing bodies, or the same animation observed in another engine.

**Agent.** Research — **and only if a new lead exists.** Otherwise leave closed. Re-deriving this is
a known way to burn a session.

---

## Q4 — Why is the skeletal-mesh section table only reachable ~35% of the time?

**Question.** A `SkeletalMesh` does carry a per-material section table, it is implemented and
consumed, but it is located by walking forward from the socket table — so a mesh whose socket table
does not itself validate cannot be reached and draws in one material. Measured: 944 skeletal meshes
with geometry, **331 (35%)** yielding a resolved table, 392 sections, 61 with more than one
material. **94 meshes genuinely still lack it.**

**Why it matters.** It is the largest known correctness gap in mesh export and it directly affects
UE5 material assignment.

**Evidence already gathered.** `UnMeshBioshock.cpp`'s `FStaticLODModelBio` opens with
`TArray<FSkelMeshSection>`, nine `uint16`s each, commented "1 section = 1 material" — so the data is
present, and the payload should be walked **from the front** rather than searched for from the
vertex chain. A prior measurement of 157 was itself an artefact of calling the wrong
`MeshGeometryReader` overload (A14); the true figure is 94.

**Relevant files.** `src/BioShockStudio.Core/Mesh/SkeletalMeshSections.cs`,
`src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`,
`tests/BioShockStudio.Tests/SkeletalMeshSectionCoverageTests.cs`,
`docs/research/skeletalmesh.md`, `docs/research/reference-comparison.md` §3a,
`Bioshock1REMSDK-WIP--main/` and `UModel-master/UnMeshBioshock.cpp`.

**Best next investigation.** Walk `FStaticLODModelBio` from the front against the reference layout,
on a mesh currently in the unresolved 94 (`WP_CrossbowMesh`, `TommyGunMESH`, `PlasmidEquipMESH`,
`PearlsAnim_Mesh` are named candidates).

**Agent.** Research → Coder.

---

## Q5 — Why do four door meshes not decode at all?

**Question.** `LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`, `Atlas_labs_doorAnim`,
`GathererDoorAnimMesh` — 18 exports — produce no geometry. Everything else decodes (954/972, 98.1%).

**Why it matters.** It is the entire remaining `SkeletalMesh` decode gap, and it is a small, bounded
population, which makes it a good evidence-producing task.

**Evidence already gathered.** The preview shows their skeletons and reports why there is no
geometry; they are all doors, which suggests a shared variant rather than four unrelated faults.

**Relevant files.** `src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`,
`tests/BioShockStudio.Tests/SkeletalMeshTests.cs`, `docs/QUALITY.md` §1.

**Best next investigation.** Diff the payload prefix of one failing door against a nearby working
skeletal mesh, byte by byte.

**Agent.** Research → Coder.

---

## Q6 — Two meshes decode nonsense UVs

**Question.** `BatPath` (428 of 858 vertices, worst component 6.309e+36) and `Shadow_Scissors`
produce UVs around 6e36. Everything else about them decodes.

**Why it matters.** Small and isolated, but definitely wrong, and `mesh-uv-out-of-range` finds
exactly these two in the whole game — so the check that would catch a third already exists.

**Evidence already gathered.** The census above.

**Relevant files.** `src/BioShockStudio.Core/Mesh/MeshGeometryReader.cs`,
`tests/BioShockStudio.Tests/BspUvTests.cs`, `docs/QUALITY.md` §4.

**Best next investigation.** Read the UV block of `BatPath` directly; check whether the vertex
stride or a per-mesh UV-set count is being mis-read.

**Agent.** Research → Coder.

---

## Q7 — Which package population should a whole-game census count?

**Question.** Some sweeps enumerate the 21 non-localised maps (`GameLocator.EnumeratePackages`);
others enumerate all 161 `.bsm` files including the 140 localised duplicates. Both appear in the
test suite today.

**Why it matters.** Two figures in the same document can differ by ~5× with nothing having changed
in any decoder, which is precisely the kind of drift `DocumentedFiguresTests` exists to catch and
which has already cost this project a session.

**Evidence already gathered.** `SoundEventCoverageTests` = 106,000 responses over 161;
`SoundEffectSpecificationCoverageTests` = 33,227 specifications over 21. Both correct, not
comparable.

**Relevant files.** `src/BioShockStudio.Core/Game/GameLocator.cs`, the `*CoverageTests.cs` family,
`docs/QUALITY.md`.

**Best next investigation.** Decide one convention (recommendation: non-localised as the default,
with any all-161 count labelled as such at the assertion), then audit existing sweep tests for which
they use. This is a lead decision informed by a cheap audit, not a research problem.

**Agent.** Tester (audit) → Lead (decision).

---

## Q8 — Has anyone actually looked at the UE5 import with human eyes?

**Question.** Every "verified in UE5.7" claim to date is log evidence — `Success - 0 error(s)`, a
clean `verify_bioshock_import` run. Nobody has opened the editor and watched the imported pistol
pose and animate.

**Why it matters.** This project has already shipped six faults in one session that passed the full
suite, five of which a human caught by looking at the screen. "A numeric check cannot see a wrong
quantity that is still present" is a rule here for a reason. It is ROADMAP Part 0.5 and a ten-minute
check.

**Evidence already gathered.** Import logs only. UE 5.7 is installed at `G:\Games\UE_5.7`.

**Relevant files.** `tools/ue5/import_bioshock.py`, `tools/ue5/verify_bioshock_import.py`,
`docs/HANDOFF_UE5_IMPORT.md`, `docs/NEXT_SESSION.md`.

**Best next investigation.** Import and look. This one needs the human, not an agent.

**Agent.** **Lead / user** — an agent cannot discharge it.

---

## Q9 — The 34-byte Unreal prefix on `AnimationPackageWrapper`

**Question.** What are the 34 bytes before the Havok packfile?

**Why it matters.** Low. Everything downstream decodes without it. Recorded so it is not
re-discovered as if new.

**Evidence already gathered.** `docs/research/open-questions.md` §7.

**Relevant files.** `src/BioShockStudio.Core/Havok/Detection/HavokDetector.cs`,
`docs/research/animationpackage.md`.

**Best next investigation.** Only worth doing alongside other work in that reader.

**Agent.** Research, low priority.

---

## Q10 — Export record `Unknown32` / `TrailingUnknown32`, and section tag numeric suffixes

**Question.** Two long-standing unnamed fields in the export record, and the numeric suffixes on
Havok section tags.

**Why it matters.** Low. Surfaced under neutral names rather than guessed at, which is the correct
state. Listed so an agent does not treat "Unknown" as a defect to be fixed.

**Evidence already gathered.** `docs/research/open-questions.md` §8, §9.

**Relevant files.** `src/BioShockStudio.Core/Packages/PackageStructures.cs`,
`src/BioShockStudio.Core/Havok/Objects/HavokSection.cs`.

**Best next investigation.** None scheduled. **Unknown is a valid answer.**

**Agent.** —

---

## Q11 — Why do 8 actors with decoded `Emitters` not land in `EffectPending`?

**Question.** `EffectActorSchemaTests` finds 142 actors with `actor.Emitters is not null` (fully
decoded) but the `EffectPending` coverage bucket sums to only 134 — an 8-actor gap, in a currently
*passing* test, so both numbers are the real, current, correct output.

**Why it matters.** Low urgency (nothing is failing), but worth naming precisely rather than leaving
implicit. `LevelCoverage.Classify()`'s `if`-chain checks `LightPending` (class ends `"Light"` or has a
light property) and `RegionPending` (class ends `"Volume"`/contains `"Trigger"`/`"Zone"`) *before* it
checks `EffectPending`. The likely explanation: 8 of the 142 `Emitters`-bearing actors also match one
of those earlier gates and get classified there instead — a light or volume actor that also happens to
carry a particle effect. Found during TASK-009's shared-bucket audit; not the same bug (this isn't a
test summing a bucket it shouldn't — the assertion is honest about being class-agnostic), just an
unstated precedence interaction worth having a name.

**Evidence already gathered.** `EffectActorSchemaTests.cs` (142 vs 134); `LevelCoverage.Classify()`
gate order in `src/BioShockStudio.Core/Level/LevelCoverage.cs`.

**Relevant files.** `src/BioShockStudio.Core/Level/LevelCoverage.cs` (`Classify()`),
`tests/BioShockStudio.Tests/EffectActorSchemaTests.cs`.

**Best next investigation.** Diff `effects` (the 142) against the `EffectPending`-bucket actor set
directly, name the 8 by object name and class, and confirm they land in `LightPending`/`RegionPending`
as predicted.

**Agent.** Research, low priority.
