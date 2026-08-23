# Task queue

Maintained by the lead. Agents take a task, they do not add one. Anything discovered mid-task is
**captured here as a new task and not chased** (`DISCOVER → VERIFY → RECORD → DEFER → CONTINUE`).

Status: `READY` / `BLOCKED` / `INVESTIGATING` / `IMPLEMENTING` / `TESTING` / `REVIEW` / `DONE`.

**Dispatch rule:** no two in-flight tasks may share a file. Check the "Files likely involved" lines
before starting a second task in the same module.

---

## TASK-000 — **highest priority**

**Title:** Classify the four failing `1-Medical` actor-schema count tests

**Goal:** Determine, for each of the four, whether the count rose because classification genuinely
improved or because it now over-captures. Then either the code or the expected figure is wrong —
**decide which, with evidence, before either is touched.**

| Test | Expected | Actual |
|---|---|---|
| `MarkerActorSchemaTests.EveryMedicalMarkerIsOnlyAPlacedCommonActorRecord` | 150 | 159 |
| `PickupActorSchemaTests.EveryMedicalHypoPickupExportsItsResolvedLootSlot` | 11 | 16 |
| `TrainingScriptActorTests.MedicalTrainingConceptArraysDecodeExactlyAndReachTheManifest` | 325 | 326 |
| `VendingActorSchemaTests.EveryMedicalVendingStationExportsItsInteractionDeclaration` | 14 | 16 |

**Why it matters:** The team cannot trust any actor-schema or coverage figure until this is settled,
and `1-Medical`'s "`Unclassified` is zero" claim — the basis for calling Gate 3 item 3 complete —
depends on these categories partitioning correctly. An unclassified red test is also the specific
thing `ENGINEERING_RULES.md` §24 forbids stepping around.

**Agent:** Tester (bisect + classification) → Research **only if** the bisect does not make the
cause obvious → Lead decides → Coder applies.

**Dependencies:** none. **Dispatch this before anything else.**

**Files likely involved:** `tests/BioShockStudio.Tests/{Marker,Pickup,Vending}ActorSchemaTests.cs`,
`tests/BioShockStudio.Tests/TrainingScriptActorTests.cs`,
`src/BioShockStudio.Core/Level/LevelAnalyzer.cs`, `src/BioShockStudio.Core/Level/LevelCoverage.cs`

**Acceptance criteria:** For each of the four: the commit that changed the number, the actor
class(es) newly landing in the category, and a stated verdict — *improvement* (the expected figure
is stale and moves, with the reason recorded) or *regression* (the classification is wrong and the
code moves). A single verdict covering all four is acceptable only if the evidence actually shows
one cause.

**Evidence required:** a bisect over the Gate 3 commits touching `Level/` (`d33cf17`, `8f48173`,
`a8d22ef`, and earlier schema commits) naming the one that moved each count; and, for at least one
category, the specific actors added, by object name, with why they now qualify.

**Already established** (do not redo): the failures are deterministic and reproduce in isolation in
10 s, so this is not test ordering; they are **not** caused by `55488e2`/`9b2036f`, which touch only
`Core/Audio/`; the subject code was last touched by `d33cf17`, `8f48173`, `a8d22ef`.

**Explicitly prohibited:** editing an expected number up to match the actual one to get green. That
is the exact move `ENGINEERING_RULES.md` §24 and §50 exist to stop, and with counts that *rose* it
is the tempting one.

**Risk:** MEDIUM — the answer may invalidate a "complete" claim on ROADMAP Gate 3 item 3.

**Status:** **DONE, 23 Aug 2026.** Verdict: **improvement, not regression, all four** — one shared
root cause, not four separate ones. The earlier attribution to `d33cf17`/`8f48173`/`a8d22ef` was
wrong in its specifics (those three commits add `RuntimeStatePending`/`WorldSettingsPending`/a
`ShockAIScout`+`LevelInfo` schema and a `DoorKeypadControl`/`dyn_toolbox_open` `Interaction` schema —
none of which touch `Marker`/`TrainingMarker`/`MapUILayerScaleMarker`, `MedHypoPickup`, `Vending`, or
`TrainingScript`/`Script` classification) but the underlying instinct — "recent Gate-3 classification
work moved these counts" — was correct for three of the four via `a8d22ef` specifically.

**Root cause:** all four assertions summed a **coverage bucket shared by multiple unrelated actor
classes** (`LevelCoverage.Classify()` deliberately routes several classes to the same
UE5-representation-pending status — that part is correct design) as if the bucket total uniquely
identified their own class. Two other tests in the same suite (`MapUiMarkerSchemaTests.cs`,
`CoverageBoundaryActorTests.cs`) already used the correct idiom — filter `coverage.Classes` to your
own `ClassName` before summing — proving the fix pattern already existed, just not applied
consistently.

**Full per-class arithmetic** (every term below independently confirmed by a different,
currently-passing test in the suite — not derived circularly from these four):

| Shared bucket | Composition | Total |
|---|---|---|
| `MarkerPending` | `Marker`(150) + `TrainingMarker`(6) + `MapUILayerScaleMarker`(3) | 159 |
| `InteractionPending` | `MedHypoPickup`(11) + `PlaceableVendingStation`(3) + `Interaction`(`DoorKeypadControl`+`dyn_toolbox_open` = 2) | 16 |
| `ScriptPending` | `Script`(300) + `TrainingScript`(26) | 326 |

`PickupActorSchemaTests`' constant (11) was already stale *before* today — it never accounted for
`Vending` joining the same bucket in `51947a4`. `VendingActorSchemaTests`' constant (14) was correct
for `MedHypoPickup`+`Vending` but not for `a8d22ef`'s `Interaction` addition. `TrainingScriptActorTests`'
change (325→26) is the largest-looking edit but is the same bug: 325 was a stale shared-bucket total,
26 is the per-class figure the fix now asserts.

**Fix applied:** `tests/BioShockStudio.Tests/{Marker,Pickup,Vending}ActorSchemaTests.cs` and
`TrainingScriptActorTests.cs` now filter `row.ClassName == "<owning class>"` before summing, matching
the established idiom. **No production code changed** — `LevelAnalyzer.cs`/`LevelCoverage.cs` were
correct throughout.

**Evidence chain:** research done directly by the Lead (git log/diff on `d33cf17`, `8f48173`,
`a8d22ef`, `3e99872`, `9ed26b9`, `a9018b0`, `ce90b4b`; read of `LevelCoverage.Classify()`;
cross-referenced against `InteractionActorSchemaTests.cs`, `CoverageBoundaryActorTests.cs`,
`MapUiMarkerSchemaTests.cs`); fix dispatched to and implemented by the local coder agent (two
mechanical errors — missing string-literal quotes, a stray BOM — caught by the Lead reading the diff
directly and hand-corrected, not re-dispatched); independently verified by the local tester agent in
its own isolated worktree (patch-applied, real `dotnet build` + `dotnet test`: 5/5 passed) and again
by the Lead directly in the main worktree (5/5 passed, 0 errors, 0 warnings). Reviewed by the local
reviewer agent: **APPROVE WITH FOLLOW-UP** (see TASK-009).

**Confidence:** CONFIRMED_BYTES for every number; CONFIRMED (build+test, twice independently) for the
fix itself.

---

## TASK-001

**Title:** Point `BulkTextureCatalog` at the 1,970 unlocated sound sample names

**Goal:** Determine whether the unlocated samples live in `BulkContent/`, or rule that store out.

**Why it matters:** The last substantive gap in the audio chain (34.4% of referenced samples) and
the blocker for Gate 4 item 2. `docs/research/audio.md` §4 names this as the cheap, correct, still
untried test — a raw byte search of `Catalog.bdc` proved nothing because it also misses `Hand_DIFF`,
a texture certainly in there.

**Agent:** Research

**Dependencies:** none

**Files likely involved:** `src/BioShockStudio.Core/Textures/BulkTextureCatalog.cs`,
`src/BioShockStudio.Core/Audio/SoundEffectSpecificationReader.cs`, `docs/research/bulkcontent.md`,
`docs/research/audio.md`

**Acceptance criteria:** A written answer of the form "N of 20 sampled unlocated names are present
in the bulk catalogue" — **either answer closes the task.** If present, a follow-up Coder task is
proposed. If absent, `docs/research/audio.md` §4 records the store as ruled out, with the method.

**Evidence required:** the exact names tried, the catalogue lookup used, and the raw result. A
negative must show the lookup succeeding on a known-present name (a texture) in the same run, so an
absent result is not just a broken query.

**Risk:** LOW — read-only.

**Status:** READY

---

## TASK-002

**Title:** Search the decompiled UnrealScript for what `SoundSpecEntry.Flag` selects

**Goal:** Find the game's own name or enum for the 0–27 byte on each `SoundSpecs` entry, or
establish that it is not in the decompiled source.

**Why it matters:** Decides whether `KNOWN_ASSUMPTIONS.md` A18 can be promoted from `PLAUSIBLE`, and
whether audio export can be surface-keyed. The game's own source became readable only recently
(1,445 classes, 11 of 12 script packages) and nobody has searched it for this.

**Agent:** Research

**Dependencies:** none

**Files likely involved:** `tools/uelib-bridge/` (and its output),
`src/BioShockStudio.Core/Audio/SoundEffectSpecificationReader.cs`, `docs/research/bytecode.md`,
`docs/research/audio.md`

**Acceptance criteria:** Either the field's declared name/enum with its source class and line, or a
recorded negative ("searched N classes for `<terms>`, not present").

**Evidence required:** the decompiled declaration itself, quoted with its file, or the exact search
terms and scope for a negative.

**Risk:** LOW — read-only.

**Status:** **DONE, 23 Aug 2026.** Done directly by the Lead — this needed decompiling a package first
(actual execution: `dotnet build tools/uelib-bridge/uelib-standalone.csproj` then
`dotnet run --project tools/uelib-bridge -- <out-dir> IGSoundEffectsSubsystem.U`), which the current
orchestrator's Research role can't do (text-only, no code execution) — noted as a real gap in
`.agent-control/CLAUDE_ORCHESTRATION.md`'s limitations, not silently worked around. Found in
`SoundEffectSpecification.uc:60`: `var config Material.EMaterialVisualType Flag;`. Full 28-value
enum table and cross-reference against `Bioshock1REMSDK-WIP--main` in `KNOWN_ASSUMPTIONS.md` A18,
now `HIGH`/`CONFIRMED_EXTERNAL`. Closed as Q2 in `OPEN_QUESTIONS.md`. Follow-up: **TASK-010**.

---

## TASK-003

**Title:** Audit which package population every whole-game census test counts

**Goal:** Produce a table of every `*CoverageTests` / census test, which enumeration it uses
(`GameLocator.EnumeratePackages` = 21 non-localised, vs `Directory.GetFiles(MapsDirectory)` = all
161), and its asserted figure.

**Why it matters:** Two figures in the same document can differ by ~5× with no decoder having
changed. This is the drift `DocumentedFiguresTests` exists to catch, and it has already cost a
session once. The lead needs the table to pick one convention.

**Agent:** Tester

**Dependencies:** none

**Files likely involved:** `tests/BioShockStudio.Tests/*CoverageTests.cs`,
`tests/BioShockStudio.Tests/*CensusTests.cs`, `src/BioShockStudio.Core/Game/GameLocator.cs`,
`docs/QUALITY.md`

**Acceptance criteria:** The table, as a report. **No test is changed in this task** — the decision
is the lead's.

**Evidence required:** file and line for each enumeration call site.

**Risk:** LOW — read-only.

**Status:** **DONE (partial precision), 23 Aug 2026.** Dispatched to the local research agent first;
its report is **not trustworthy as-is** and is kept here as a documented example of why every worker
result gets verified, not summarized. It grepped for the bare string `MapsDirectory` and classified
every hit as either the 21-package or 161-package enumeration by which nearby literal appeared,
without checking *how* `MapsDirectory(...)` was used at each site — so it misclassified
`StaticMeshGeometryTests.cs` (which only builds a path to `1-Medical.bsm`, a **single package**, via
`Path.Combine(GameLocator.MapsDirectory(...), "1-Medical.bsm")`) as an "all-161 census." Spot-checked
directly by the Lead and confirmed wrong.

**Corrected finding**, from the Lead re-grepping for the actual enumeration call
(`Directory.GetFiles`/`Directory.EnumerateFiles` applied to `MapsDirectory`, not just any use of the
helper): roughly 26 files do a genuine whole-game census this way; roughly 11 use
`GameLocator.EnumeratePackages` (21 non-localised). The single confirmed, concrete, already-costed
instance of this mattering is exactly what `KNOWN_ASSUMPTIONS.md` A9 already documents:
`SoundEventCoverageTests` (161, `Directory.GetFiles(MapsDirectory)`) = 106,000 responses, vs
`SoundEffectSpecificationCoverageTests` (21, `GameLocator.EnumeratePackages`) = 33,227 specifications —
both correct for what they measure, not comparable, no decoder difference.

**Not fully exhaustively verified past that one instance** — the Lead did not hand-check all ~26 files
individually for whether their whole-game iteration actually feeds an asserted whole-game *count* (vs.
e.g. "every skeleton across all packages decodes," where the total file count isn't itself asserted
and the enumeration choice doesn't create a stale-figure risk the way TASK-000/009's pattern did).
**Recorded honestly as a partial result rather than a false claim of completeness** (Q7's own
recommendation — non-localised-21 as the default convention, all-161 counts explicitly labelled — is
unchanged and still the Lead's standing recommendation for any *new* whole-game census test).

**Evidence chain:** local research agent's raw grep hit list (file+line, mechanically correct);
Lead's own targeted re-grep and spot-check (`CoordinateSystemTests.cs:344` confirmed a genuine
`Directory.EnumerateFiles` census; `StaticMeshGeometryTests.cs:23` confirmed a single-package
`Path.Combine`, disproving the worker's classification of it).

---

## TASK-004

**Title:** Byte-diff one non-decoding door mesh against a working skeletal mesh

**Goal:** Identify why `LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`, `Atlas_labs_doorAnim` and
`GathererDoorAnimMesh` yield no geometry.

**Why it matters:** These 18 exports are the *entire* remaining `SkeletalMesh` decode gap
(954/972 decode). Bounded, well-defined, and it is the kind of task that produces reusable evidence
about the container.

**Agent:** Research

**Dependencies:** none

**Files likely involved:** `src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`,
`tests/BioShockStudio.Tests/SkeletalMeshTests.cs`, `docs/research/skeletalmesh.md`,
`docs/QUALITY.md` §1, `UModel-master/` (`UnMeshBioshock.cpp`)

**Acceptance criteria:** A stated cause with the offset at which the two payloads diverge, **or** a
recorded negative naming what was compared and eliminated. All four doors must be checked — one
sample is not evidence (§7).

**Evidence required:** hex with offsets from both payloads; the reference layout it was read
against.

**Risk:** LOW — read-only. Any fix is a separate Coder task.

**Status:** READY

---

## TASK-005

**Title:** Walk `FStaticLODModelBio` from the front on a mesh whose section table is unreachable

**Goal:** Establish whether the per-material section table can be located by walking the payload
from the front, instead of forward from the socket table.

**Why it matters:** The table is only reachable ~35% of the time (331 of 944), purely because the
current locator starts at the socket table and 94 meshes have one that does not validate. Those
meshes export with a single material, which is visibly wrong in UE5. The reference says the table
is at the **front** of `FStaticLODModelBio` (`TArray<FSkelMeshSection>`, nine `uint16`s each).

**Agent:** Research → Coder (Research must complete and be accepted first — §2 risky category)

**Dependencies:** none, but do **not** dispatch alongside TASK-004: both touch
`Mesh/SkeletalMeshReader.cs`.

**Files likely involved:** `src/BioShockStudio.Core/Mesh/SkeletalMeshSections.cs`,
`src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`,
`tests/BioShockStudio.Tests/SkeletalMeshSectionCoverageTests.cs`,
`docs/research/skeletalmesh.md`, `docs/research/reference-comparison.md` §3a

**Acceptance criteria:** Front-walk validated on at least one currently-unresolved mesh
(`WP_CrossbowMesh`, `TommyGunMESH`, `PlasmidEquipMESH`, `PearlsAnim_Mesh` are named candidates)
**and** shown to agree with the existing locator on meshes where both work. A change that improves
the 35% while disagreeing anywhere with the currently-correct 331 is a regression, not a fix.

**Evidence required:** the walk offsets, section counts, and material indices for at least three
meshes across at least two packages, plus the reference layout.

**Risk:** MEDIUM — touches a reader whose output feeds preview, FBX export and UE5 materials.

**Status:** READY

---

## TASK-006

**Title:** Regression-test the two nonsense-UV meshes and locate the mis-read

**Goal:** Explain `BatPath` (428 of 858 vertices, worst component 6.309e+36) and `Shadow_Scissors`.

**Why it matters:** Small, isolated, definitely wrong, and the whole-game check that would catch a
third already exists — so this is cheap and closes a named defect in `docs/QUALITY.md`.

**Agent:** Research → Coder

**Dependencies:** do not dispatch alongside TASK-005 if the fix reaches
`Mesh/MeshGeometryReader.cs`.

**Files likely involved:** `src/BioShockStudio.Core/Mesh/MeshGeometryReader.cs`,
`tests/BioShockStudio.Tests/BspUvTests.cs`, `docs/QUALITY.md` §4

**Acceptance criteria:** The cause identified (vertex stride, UV-set count, or a genuinely corrupt
shipped block — **the third is an acceptable answer**), with a test pinning whichever it is.

**Evidence required:** the UV block bytes at the offending vertices, and the stride arithmetic.

**Risk:** LOW–MEDIUM.

**Status:** READY

---

## TASK-007

**Title:** Reconcile the ROADMAP verification stamp with the measured full-suite result

**Goal:** Move `docs/ROADMAP.md` "Test health" forward to the current HEAD with the figure this
preparation pass actually measured, and record the per-tier split.

**Why it matters:** The stamp names commit `1c2e4b2`; HEAD is 72 commits and 101 files past it.
A stale stamp is precisely what forces the next agent to re-run everything — the cost §60 exists to
stop.

**Agent:** Lead (mechanical; may be delegated to Tester once the full run reports)

**Dependencies:** the full-suite run started during this preparation pass.

**Files likely involved:** `docs/ROADMAP.md` ("Test health"), `.agent/PROJECT_STATE.md`

**Acceptance criteria:** Stamp names the current commit and the measured total.

**Evidence required:** the runner's own summary line.

**Risk:** LOW.

**Status:** **DONE, 23 Aug 2026.** The full suite ran during the preparation pass: **546/550, 4
failing, 41m47s at `9b2036f`**. `docs/ROADMAP.md` "Test health" now stamps that commit and names the
four failures rather than reporting a green total. The failures themselves are TASK-000.

---

## TASK-008

**Title:** Look at the imported pistol in the UE5.7 editor, with human eyes

**Goal:** Confirm the imported first-person pistol poses and animates correctly in UE 5.7, by
watching it.

**Why it matters:** Every "verified in UE5.7" claim so far is log evidence. This project has already
shipped six faults in one session that passed the full suite, five of which a human caught by
looking at the screen. ROADMAP Part 0.5; a ten-minute check that closes a real gap between "the log
says it worked" and "it looks right".

**Agent:** **Lead / user — an agent cannot discharge this.**

**Dependencies:** UE 5.7 at `G:\Games\UE_5.7`; a current export.

**Files likely involved:** `tools/ue5/import_bioshock.py`, `tools/ue5/verify_bioshock_import.py`,
`docs/HANDOFF_UE5_IMPORT.md`

**Acceptance criteria:** A first-hand statement of what was seen, and a screenshot in `artifacts/`.

**Evidence required:** the screenshot.

**Risk:** LOW to perform, HIGH in what it might reveal.

**Status:** READY — needs the user.

---

## TASK-009

**Title:** Audit every `coverage.Classes.Sum(row => row.StatusCounts.GetValueOrDefault(<Status>))`
assertion for the same latent shared-bucket bug TASK-000 just fixed

**Goal:** TASK-000 fixed four *currently-failing* tests that summed a coverage-status bucket shared by
multiple actor classes without filtering to their own `ClassName` first. `InteractionActorSchemaTests.cs:26-27`
does the exact same un-filtered sum over `InteractionPending` (`Assert.Equal(16, coverage.Classes.Sum(row =>
row.StatusCounts.GetValueOrDefault(LevelActorCoverage.InteractionPending)));`) and is **not currently
failing only because 16 happens to already equal the full shared-bucket total** (`MedHypoPickup`(11) +
`PlaceableVendingStation`(3) + `Interaction`(2) = 16, per TASK-000's own arithmetic). It will silently
break the next time any class is added to `InteractionPending` — identical failure mode, just not
triggered yet. Confirm whether any of `AudioPending` (multi-class gate: `AmbientSound` or `SoundMarker`
or a property match) or `SpawnerPending`/other single-gate buckets are also secretly multi-class, and
fix every genuinely-shared one the same way.

**Why it matters:** Raised by the reviewer agent during TASK-000's review (`APPROVE WITH FOLLOW-UP`)
and confirmed by the Lead with a repo-wide grep the same session — this is a real, reproducible
pattern, not speculation, and it will keep re-costing a session each time it trips a new test.

**Agent:** Tester (grep + trace each `Classify()` gate for multi-class exposure) → Coder (apply the
same `row.ClassName == "..."` idiom to any bucket confirmed shared).

**Dependencies:** none. Same area as TASK-000 (`tests/BioShockStudio.Tests/*ActorSchemaTests.cs`,
`src/BioShockStudio.Core/Level/LevelCoverage.cs`) — do not dispatch alongside another task touching
those test files.

**Files likely involved:** every `tests/BioShockStudio.Tests/*ActorSchemaTests.cs` /
`*ActorTests.cs` file matching `coverage.Classes.Sum(row => row.StatusCounts.GetValueOrDefault(`,
`src/BioShockStudio.Core/Level/LevelCoverage.cs` (`Classify()`, read-only — this is a test-only fix
class, same as TASK-000).

**Acceptance criteria:** A table of every such assertion, which bucket it sums, whether that bucket's
`Classify()` gate is provably single-class or multi-class, and for every multi-class one: fixed (with
the same idiom) or explicitly justified as safe (e.g. bucket total already equals `Assert.Single`'s
class count with no other gate reaching it).

**Evidence required:** the specific `Classify()` gate condition(s) quoted for each bucket touched.

**Risk:** LOW — test-only, same low-risk shape as TASK-000.

**Status:** **DONE, 23 Aug 2026**, for the buckets the Lead was able to fully resolve; one left
explicitly open below rather than guessed at.

**Full audit table.** Every `coverage.Classes.Sum(row => row.StatusCounts.GetValueOrDefault(<X>))`
assertion in the suite, traced against its `Classify()` gate and the `LevelAnalyzer.cs` function that
populates the field the gate tests:

| Test | Bucket | Gate | Verdict |
|---|---|---|---|
| `MarkerActorSchemaTests` etc. (4 tests) | `MarkerPending`/`InteractionPending`/`ScriptPending` | multi-class | **FIXED — TASK-000** |
| `InteractionActorSchemaTests` | `InteractionPending` | `LootSlot`/`Vending`/`Interaction`, 4 classes | multi-class, **not yet failing by coincidence** — deliberately left open, see below |
| `AntiPortalActorSchemaTests` | `VisibilityPending` | `AntiPortal = Reference(...)`, **no `ClassName` gate at all** | multi-class exposure — **FIXED** |
| `CubemapProbeActorTests` | `ReflectionProbePending` | `Cubemap = Reference(...)`, **no `ClassName` gate at all** | multi-class exposure — **FIXED** |
| `SpawnerActorSchemaTests` | `SpawnerPending` | `className.EndsWith("Spawner")` — already 2 classes (`AggressorSpawner`+`ProtectorSpawner`), documented in the file's own pre-existing comment | multi-class, currently coincidentally correct — **FIXED** |
| `ProjectorActorSchemaTests` | `ProjectorPending` | `ClassName is "GoreLight_Decal" or "Caustic_Projector" or "Projector"` (3 classes) | **SAFE, no change** — the test's own `actors.Count` filters on `actor.Projector is not null`, the *same* predicate the bucket gate uses, so the bucket sum is definitionally equal to it. Deliberately a multi-class group test, not a single-class test mistaking a shared total. |
| `HavokConstraintActorSchemaTests` | `PhysicsConstraintPending` | `ClassName is "HavokHingeConstraint" or "HavokBSConstraint"` (2 classes) | **SAFE, no change** — same self-consistency: filters on `actor.HavokConstraint is not null`, identical to the gate. |
| `EffectActorSchemaTests` | `EffectPending` | `HasAny(actor, "Emitters")`, no class restriction | **SAFE, no change** — same self-consistency (`actor.Emitters is not null`). Separately: `effects.Count` (142, decoded) doesn't equal the bucket sum (134) — 8 actors have decoded `Emitters` but classify into an earlier-matching bucket (`Classify()` checks `Light`/`Region` name patterns before `EffectPending`). Not a bug, not touched — recorded as a new minor open question below, not urgent. |
| `SoundActorSchemaTests.MedicalSoundMarkersAreClassifiedByTheirDecodedSchemaNames` | `AudioPending` | `ClassName is "AmbientSound" or "SoundMarker"` OR a 4-property `HasAny` fallback | **left OPEN, not fixed** — ambiguous intent. The test filters its own `actors`/`withSchema` variables to `SoundMarker` only, but the bucket-sum assertion (345) is the *whole 1-Medical `AudioPending` total* including `AmbientSound` (2,893 game-wide) and possibly `MusicBox`, not `SoundMarker`'s own count (36). The file's own extensive docstring suggests this may be a deliberate "is the whole audio bucket accounted for" check rather than a mistaken single-class stand-in — the author was clearly careful here (see the docstring's own correction of a wrong roadmap assumption). Changing it without confirming intent risks silently narrowing a check that was meant to be broad. **Needs Research, not a blind mechanical fix — left for a future task rather than guessed at.** |
| `LevelInfoActorSchemaTests`, `ShockAiScoutActorSchemaTests`, `MapUiMarkerSchemaTests` (`MapMarkerPending` row only) | `WorldSettingsPending`/`RuntimeStatePending`/`MapMarkerPending` | each gated by exactly one `ClassName` (`"LevelInfo"`, `"ShockAIScout"`, `"MapUILayerMarker"`) | **SAFE, confirmed single-class, no change.** |

**Fix applied** (3 files, mirrors TASK-000's idiom): `AntiPortalActorSchemaTests.cs`,
`CubemapProbeActorTests.cs` filter to their one class; `SpawnerActorSchemaTests.cs` filters to the two
classes its own comment already documents. **No expected numeric value changed** — this is a
robustness fix against a *future* class joining an already-shared or fully-unguarded bucket, not a
correctness fix for a value that's wrong today.

**Evidence chain:** gate tracing done directly by the Lead (read of every `LevelAnalyzer.cs` populator
function for the 9 candidate buckets); fix implemented cleanly by the local coder agent on the first
attempt (no errors this time — the earlier lesson about giving exact literal before/after text and
exact evidence paid off); independently verified by the local tester agent (patch-applied, real build
+ test: 4/4 passed) and again directly in the main worktree (4/4 passed). Reviewed by the local
reviewer agent: **APPROVE**.

**Follow-up recorded, not actioned:** (1) `InteractionActorSchemaTests`'s shared-bucket risk is now
explicitly logged rather than silently present — a future class joining `InteractionPending` will
still break it, and that's an accepted, understood risk rather than an unknown one. (2)
`SoundActorSchemaTests`'s ambiguous 345-vs-36 scope needs a Research pass on author intent before
anyone touches it. (3) `EffectActorSchemaTests`'s 142-vs-134 classification-precedence gap is noted in
`OPEN_QUESTIONS.md`.

---

## TASK-010

**Title:** Expose `SoundSpecEntry.Flag` as the named `MaterialVisualType` enum instead of a raw byte

**Goal:** `KNOWN_ASSUMPTIONS.md` A18 (now `HIGH`/`CONFIRMED_EXTERNAL` — TASK-002) established `Flag` is
BioShock's `Material.EMaterialVisualType`, a 28-value physical-surface enum, not a project-invented
number. Add a `MaterialVisualType` C# enum with the 28 named values (`MVT_Default` = 0 … `MVT_Trash` =
27, full table in A18) to `src/BioShockStudio.Core/Audio/` and expose `SoundSpecEntry.Flag` as that
type (or add a parallel named property) instead of a bare `byte`.

**Why it matters:** Turns an opaque number into a name a human or a UE5 export step can act on
directly, at essentially zero risk — this is a pure decode-fidelity improvement (exposing what the
byte already means), not new behaviour. Does **not** imply implementing surface-keyed sound *selection*
at runtime/export time — that's a separate, larger Gate-4-adjacent decision A18 explicitly defers.

**Agent:** Coder (the enum table and evidence are already fully in `KNOWN_ASSUMPTIONS.md` A18 — no
Research step needed first).

**Dependencies:** none.

**Files likely involved:** `src/BioShockStudio.Core/Audio/SoundEffectSpecificationReader.cs`,
`tests/BioShockStudio.Tests/SoundEffectSpecificationTests.cs`.

**Acceptance criteria:** `SoundSpecEntry.Flag`'s type change compiles and every existing test that
reads it still passes (update assertions to the named form, don't just retype and leave numeric
comparisons — check `SoundEffectSpecificationTests.cs`, `SoundEffectSpecificationCoverageTests.cs`
first for any that would need updating). A regression test asserting a couple of known values by name
(e.g. `bullet_hit`'s flag-11 alternative is `MVT_Cardboard`) is a natural addition, not required.

**Evidence required:** none new — cite `KNOWN_ASSUMPTIONS.md` A18 for the enum table.

**Risk:** LOW — additive, decode-fidelity-only, no behavioural change.

**Status:** READY

---

## Recommended first six, in order

| Order | Task | Agent | Why first |
|---|---|---|---|
| 1 | **TASK-000** | Tester → Lead | **DONE, 23 Aug 2026** — see above. Was: the suite is red, four Sweep-tier tests fail, nothing else should be dispatched while an unclassified red test sits in the tree. |
| 2 | **TASK-003** | Tester | Cheapest, read-only, and it makes every later census figure trustworthy. Nothing else should assert a whole-game number until this is answered. Natural follow-on from TASK-000, same agent, same area of concern. |
| 3 | **TASK-001** | Research | Highest information per unit of effort; either answer closes a standing blocker. |
| 4 | **TASK-002** | Research | Read-only, independent of everything else, and it either promotes or kills A18. |
| 5 | **TASK-004** | Research | Bounded population, produces reusable container evidence, no code change. |
| 6 | **TASK-005** | Research → Coder | The largest real correctness gap; needs TASK-004's container evidence to land first since both touch the same reader. |
| 7 | **TASK-006** | Research → Coder | Small, closes a named defect, safe once TASK-005 is out of the mesh readers. |

TASK-007 unblocks itself when the full-suite run reports. **TASK-008 needs the user and is worth
doing before any further UE5 work** — it is ten minutes and it validates a claim the whole UE5 track
rests on.

Note that 1–5 are all read-only. **That is deliberate**: the first pass of a new agent team should
produce evidence and a trustworthy baseline before it produces diffs — and with TASK-000 open, the
baseline is not yet trustworthy.
