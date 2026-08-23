# Project state

**As of commit `9b2036f`, 23 Aug 2026.** Written by the lead engineer from the actual tree, not from
older notes — where a note and the code disagreed, the code and its tests won.

This is the **first thing an agent reads**. It is written to be sufficient for scoping a task, so
that `docs/` (≈11,900 lines) is opened only for the specific note a task names.

Canonical long-form sources, if you need them: `docs/ROADMAP.md` (status and gate order),
`docs/QUALITY.md` (headline figures, each pinned by a test), `docs/HANDOFF.md` (institutional
memory, §4 landmines), `docs/research/*.md` (byte-level evidence).

---

## 1. Project goal

Recover BioShock 1 Remastered's shipped assets — skeletal and static meshes, skeletons, skinning,
Havok animation, materials, textures, whole levels, audio and first-person viewmodels — from raw
bytes, with **no format assumed without evidence**, and get them into a form other tools can use.

The stated end goal since 18 Aug 2026 is **UE5 as a runtime**: port the decoded assets into Unreal
Engine 5, faithfully first, then improve systems once the port stands.

The project is simultaneously an extraction tool and a reverse-engineering notebook. Both halves are
load-bearing: `docs/research/` records what is known *with confidence labels*, and the code refuses
to guess where the notes say `UNKNOWN`.

---

## 2. Current capabilities — VERIFIED

Each of these is pinned by a test that reads the real installed game.

| Area | State |
|---|---|
| `.bsm` package format | Complete. All 21 map packages plus script packages parse byte-exact. 812,435 exports indexed, 14,378 distinct assets browsable. |
| Havok packfile / object graph | Complete. |
| Skeletons & animation binding | Complete; original bone indices preserved. |
| Spline-compressed animation | **16,031 / 16,031 decode, 0 failures**, 47,560 events. |
| `StaticMesh` | Complete — all **8,668** shipped exports, including per-material section tables. |
| `SkeletalMesh` | **954 / 972 decode (98.1%)**. The 18 that do not are four door variants. |
| Materials | 14,328 walked, **0 partial**. 96.8% of meshes carry a base colour. |
| Textures | DXT1/3/5 + DXT5N (ordinal 12) decode; the 8 GB bulk-mip store is indexed and resolved per group. |
| Levels — BSP / actors | Compiled world + source brushes + placed actors assemble into a scene. `0-Lighthouse`: 1,141 objects, 2,181,021 triangles, 465 lights. |
| Levels — lightmaps | Descriptor table complete on all 21 maps (39,288 descriptors, 45,851 baked-light layers); atlas binding proven on all 20 maps carrying a `LightMaps_BSP` group. |
| Levels — actor schemas | `1-Medical` `Unclassified` is **zero**. Every placed actor class has a decoded schema. |
| Audio — native `Sound` | **25,848 exports across 21 packages, 100% decode as MP3**, 0 unknown. |
| Audio — specifications | **33,227 `SoundEffectSpecification` objects, 0 decode failures**; 31 properties; **81,775 sample entries**, 5,726 distinct names, 8,561 objects with more than one alternative. |
| Audio — actor resolution | **3,068 / 3,247 placed sound actors resolve** to a shipped specification (was 177). |
| Audio — streamed FSB5 | x86 FMOD bridge decodes any subsound to WAV; 65 banks, 10,882 subsounds indexed. |
| Coordinate conversion | One reflection `C = diag(1,-1,1)` at five decode boundaries; validated by FBX round-trip through Blender. |
| Export — Blender / FBX | Skinned mesh, armature, actions, sockets, materials. Validated by importing the FBX back and comparing against transforms composed independently from the game's own track data. |
| Bytecode | 1,445 UnrealScript classes decompiled across 11 of 12 script packages, 0 failures, cross-validated against this project's independent findings. |
| GUI | Asset browser (14,378 assets), 3D preview + animation playback, walkable level viewport (GPU + tested software fallback), Problems panel, audio tabs, profile editor. |

**The headline case works end to end:** a shipped package goes in and a skinned, textured, animated
Blender file or FBX set comes out. The first-person hands mesh, its skeleton, its weapon sockets,
its material and all 130 animations extract and play correctly — 4,852 vertices, 8,726 triangles,
38 vertex groups, a 47-bone armature, 19 socket empties, every vertex weighted and weights summing
to 1.

---

## 3. Partial capabilities — LIKELY / EXPERIMENTAL

| Area | State | Label |
|---|---|---|
| Skeletal-mesh per-material sections | Implemented and consumed, but reachable only **331 of 944 (35%)** — the locator walks forward from the socket table, and 94 meshes have one that does not validate, so they export with a single material. | LIKELY (the mechanism is right; the locator is not general) |
| UE5 import | Works and has been run in a real UE 5.7 editor across every rig category the game ships — first-person weapons, humanoid characters, mechanical doors/props/turrets, creatures — via a Blender-normalisation bridge and an editor plugin. **But every claim rests on log evidence; nobody has watched it in the viewport.** No app-facing UI. | EXPERIMENTAL |
| Level → UE5 | Versioned level JSON + OBJ export and a deterministic importer exist. Actors reach the manifest as `*Pending` categories — decoded, but no UE5 representation chosen (see `KNOWN_ASSUMPTIONS.md` A21). | EXPERIMENTAL |
| Havok physics / ragdolls | Bodies, shapes and constraints read for censused characters; not mapped to UE5 Physics Assets. | EXPERIMENTAL |
| Audio → UE5 | Nothing exports to SoundWave/SoundCue yet. Gate 4 item 2. | Documented, not implemented |
| Particles / emitters | 142 emitter-bearing actors in `1-Medical` reach the manifest with a complete typed template graph. **Choosing a Niagara representation has not started.** | Documented, not implemented |
| Bulk extraction | Works, but "extract all shown" is ~2,000 assets and ~140 GB. **Deliberately deferred by the user** — do not "fix". | Deferred by instruction |

---

## 4. Known failures — VERIFIED as broken

1. **Four door meshes do not decode** — `LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`,
   `Atlas_labs_doorAnim`, `GathererDoorAnimMesh`; 18 exports. The whole remaining `SkeletalMesh`
   gap. → `OPEN_QUESTIONS.md` Q5, TASK-004.
2. **94 skeletal meshes texture from one material only** — the section table is not reachable for
   them. → Q4, TASK-005.
3. **Two meshes decode nonsense UVs** — `BatPath` (428 of 858 vertices, worst 6.309e+36) and
   `Shadow_Scissors`. → Q6, TASK-006.
4. **252 animations collapse bone rigidity** (27 folding ≥20 bones), including
   `AggressorBabyJane`'s fire clips. **Genuinely blocked**, not unstarted: it needs
   `sampleTranslation`, whose body is not in this SDK build, and the follow-up lead was re-checked
   and is also closed. → Q3. **Do not re-open the eliminated comparisons.**
5. **1,970 of 5,726 referenced sound samples (34.4%) are in neither shipped store.** → Q1,
   TASK-001.

Nothing in this list is a regression. Each is a bounded, measured gap with a test that would catch
it getting worse.

---

## 5. Highest-risk areas

Ordered by blast radius. See `KNOWN_ASSUMPTIONS.md` for the specific guardrails.

1. **`Coordinates/GameBasis.cs`** — one reflection, five call sites. Every asset this project
   produced for two years came out mirrored because it did not exist. A second axis operation
   anywhere downstream re-creates that, invisibly. (A1)
2. **`Packages/UnrealProperty.cs`** — the tagged-property walker under every reader in the repo.
   The offset-8 rule (A4) and the corrected struct size (A5) each caused a whole class of silent
   partial reads before they were understood.
3. **`Level/ActorTransform.cs` — the negated roll.** Note that the reference-comparison test stayed
   green while this was wrong, because the reference composes roll the same wrong way. (A2)
4. **`Havok/Animation/SplineCompression/`** — the hardest code here. Consult the Havok SDK before
   deriving anything from bytes.
5. **`Export/Fbx/`** — a hand-written binary format consumed by Blender and UE5. Numeric validation
   has passed on visibly wrong output here before; a render or round-trip is part of the evidence.
6. **FName rendering (A3)** — a mis-render loses references silently, with nothing throwing and no
   test going red.
7. **Census enumeration (A9)** — 21 packages vs 161 changes any whole-game figure by ~5× with no
   decoder having changed.

---

## 6. Build and test baseline

Measured during this preparation pass, on `9b2036f`, on the user's machine
(Windows 11, .NET 8, game at `G:\SteamLibrary\steamapps\common\BioShock Remastered`).

### Canonical commands

```bash
dotnet build
```

```bash
dotnet test --filter Tier=Fast
```

```bash
dotnet test --filter "FullyQualifiedName~<Class>"
```

```bash
dotnet test
```

### Results

| Command | Result |
|---|---|
| `dotnet build` | **Succeeded. 0 warnings, 0 errors**, 2.7 s. |
| `dotnet test --filter Tier=Fast` | **243 / 243 passed**, 52 s. |
| `dotnet test --filter "FullyQualifiedName~Sound\|~Audio\|~TierCoverage"` | **37 / 37 passed**, 4 m 31 s. |
| `dotnet test` (whole suite) | **546 / 550 passed, 4 FAILED**, 41 m 47 s. |

### Baseline update, 23 Aug 2026 (later same day): the 4 failures are FIXED — TASK-000 closed

**Superseding the section below**, kept for its evidence trail. All four were **test-design defects,
not decoder regressions**: each summed a coverage-status bucket shared by multiple actor classes
(`LevelCoverage.Classify()` deliberately routes several classes to the same bucket — that part was
always correct) as if the bucket total uniquely identified its own class. Full root cause, exact
per-class arithmetic (independently cross-confirmed by other still-passing tests), and the fix are in
`TASK_QUEUE.md` TASK-000. Re-verified directly in this worktree, 23 Aug 2026:

| Command | Result |
|---|---|
| `dotnet build` | Succeeded, 0 warnings, 0 errors, 2.5 s. |
| `dotnet test --filter "FullyQualifiedName~MarkerActorSchemaTests\|~PickupActorSchemaTests\|~TrainingScriptActorTests\|~VendingActorSchemaTests"` | **5 / 5 passed**, 26 s. |

**No production code changed** — only the four test files' assertions. A related latent issue found
during review (`InteractionActorSchemaTests.cs` sums the same shared bucket without a class filter and
is not yet failing only by coincidence) is recorded as **TASK-009**, not fixed here — out of scope for
this change.

This fix was produced through the new local-agent orchestration layer (`.agent-control/agent.ps1`,
built the same session) as its first real dispatch: Lead did the root-cause research directly, a local
coder agent implemented it (two mechanical errors — missing string-literal quotes causing a compile
failure, and a stray UTF-8 BOM from a controller bug — caught by the Lead reading the actual diff and
hand-corrected rather than blindly accepted), a local tester agent independently verified in an
isolated worktree via a real applied-patch build+test, and a local reviewer agent reviewed the diff
before the Lead integrated it into this worktree. Building that orchestration layer itself surfaced
and fixed several real bugs along the way (documented in `.agent-control/CLAUDE_ORCHESTRATION.md` and
the controller's own inline comments): `Start-Process -PassThru` never populating `.ExitCode` in
Windows PowerShell, `2>&1` on a native command becoming a terminating error under `$ErrorActionPreference
= "Stop"`, `Set-Content -Encoding utf8` always adding a BOM, and a CRLF/LF mismatch breaking
`git apply` on one file in an otherwise-clean patch.

### Baseline as measured during repository preparation, 23 Aug 2026 (historical, now fixed above)

All four were Sweep-tier, all were `1-Medical` actor-schema counts, and **every one counted too
high**:

| Test | Expected | Actual |
|---|---|---|
| `MarkerActorSchemaTests.EveryMedicalMarkerIsOnlyAPlacedCommonActorRecord` | 150 | **159** |
| `PickupActorSchemaTests.EveryMedicalHypoPickupExportsItsResolvedLootSlot` | 11 | **16** |
| `TrainingScriptActorTests.MedicalTrainingConceptArraysDecodeExactlyAndReachTheManifest` | 325 | **326** |
| `VendingActorSchemaTests.EveryMedicalVendingStationExportsItsInteractionDeclaration` | 14 | **16** |

**Classified as far as preparation allows (`ENGINEERING_RULES.md` §24), not fixed** at the time this
paragraph was written — the user's instruction for that pass was explicitly not to fix unrelated
baseline failures. Fixed later the same day; see above.

What was established at the time (still correct as history, superseded as a current-state claim):

- **Reproducible and deterministic.** Re-running only those four classes reproduces all four with
  identical numbers in 10 s, so this is not test-ordering or fixture cross-talk despite the shared
  xUnit collection.
- **Not caused by the audio work committed today.** `55488e2` and `9b2036f` touch only
  `src/BioShockStudio.Core/Audio/` and audio tests (`git diff --name-only 55488e2^..HEAD`); these
  four tests depend on `src/BioShockStudio.Core/Level/`.
- **The subject code was last touched by the concurrent session's Gate 3 actor-schema work** —
  `d33cf17`, `8f48173`, `a8d22ef` on `Level/LevelAnalyzer.cs` / `Level/LevelCoverage.cs`, all
  landing *after* the four tests were written (`53f23b5`, `9ed26b9`, `4411b3e`, `51947a4`).
- **The direction is informative.** Counts rose, they did not fall. That is the signature of later
  classification work moving *more* actors into these categories — which may be a correct
  improvement, or may be over-capture. **Which one it is has not been determined and must not be
  guessed.** Do not "fix" these by editing the expected numbers up to match.

This is precisely the failure mode `docs/ROADMAP.md` Part 0.1 describes and Part 0.3 tried to
prevent: two sessions on one branch, later work shifting figures that earlier tests pin, and nobody
re-running the affected classes. → **TASK-000, the first task in the queue.**

**Environment notes.**

- Tests read the **real installed game**; there are no synthetic fixtures. Override detection with
  `BIOSHOCK_REMASTERED_PATH`. Tests skip cleanly if the game is absent — an agent on a machine
  without it will see skips, not failures, and **must not report skips as passes**.
- **Close the app before `dotnet publish`** — a running instance locks the DLLs.
- The streamed-audio tests shell out to an **x86 helper** over the game's 32-bit FMOD; they are slow
  (~4 min) and are the reason the audio sweep costs what it does.
- A cold run right after a large scan has measured 19 minutes; that is the file cache, not the
  tests.

**Baseline verdict, superseded 23 Aug 2026 (later same day): CLEAN.** The 4 Sweep-tier failures
described below were fixed (TASK-000, see above) — build 0/0, Fast tier 243/243, audio sweep 37/37,
and the four previously-failing classes now 5/5. The whole suite has not been re-run in full since
the fix (only test-only files changed; re-running the whole 41-minute suite to re-confirm a figure
this same session already measured piece-by-piece is exactly what `ENGINEERING_RULES.md` §60 says not
to do) — the next agent to run the full suite should move this figure and the `ROADMAP.md` stamp
forward together.

Note that `ROADMAP.md` Part 0.1's specific claim (7 failures in `DocumentedFiguresTests` and
`DiagnosticsTests`) is **stale in its details** — those two classes now pass — but its *warning*
was correct and has simply moved to four different classes.

**One real staleness problem:** `docs/ROADMAP.md` "Test health" still stamps commit `1c2e4b2`, which
is **72 commits and 101 files behind HEAD**. That is exactly what forces a new agent to re-run
everything. → TASK-007.

---

## 7. Repository map

```
BioshockHavok/
├── .agent/            ← this coordination layer (tracked)
├── .github/workflows/ deploy-pages.yml
├── docs/              35 tracked files, ~11,900 lines; research/ holds the byte-level evidence
├── src/
│   ├── BioShockStudio.Core/   98 .cs files, no NuGet dependencies — every format read by hand
│   ├── BioShockStudio.Cli/    Program.cs, ~64 KB, one file
│   └── BioShockStudio.App/    Avalonia 11.2.3 GUI, MVVM, logic lives in Core/Services
├── tests/BioShockStudio.Tests/  140 files, xUnit, two tiers, real game data only
├── tools/
│   ├── blender/       5 headless scripts (import, FBX round-trip validation, UE5 normalisation)
│   ├── ue5/           editor Python + the BioShockImportTools UE plugin (C++)
│   └── uelib-bridge/  standalone UnrealScript decompiler
└── BioShockStudio.sln
```

**Large, gitignored, and present on disk — do not repeatedly scan these:**

| Path | Size | What |
|---|---|---|
| `artifacts/` | **4.5 GB** | generated export output |
| `hk2012_2_0_r1/` | **2.3 GB** | Havok SDK — **confidential, must never be committed** |
| `Bioshock1REMSDK-WIP--main/` | 98 MB | Nyko's SDK reference |
| `UModel-master/` | 8.4 MB | UEViewer reference |
| `Unreal-Library-master/` | 2.4 MB | UELib reference |
| `tools/fmod-x86/` | small | downloaded FMOD helper binaries |
| `src/`, `tests/` `bin/`+`obj/` | ~236 MB each | build output |

The four reference projects are **read in place**. Project policy is to read them *before* deriving
anything from bytes — it has repeatedly saved sessions of work.

**Stray:** an empty directory named `--schema/` sits at the repo root, almost certainly created by a
mistyped CLI flag. Untracked and harmless; left in place rather than deleted without asking.

### Git state

- Current branch **`feature/fbx-materials-gui`**, **37 commits ahead of `origin`**. Working tree
  clean at the time of writing.
- Local `master` is far behind (`987772c`) and is not the working branch. Remote also has `main`.
- **A second worktree exists** at `C:\Users\Jack\Documents\BioshockHavok-fbxtest` (detached HEAD
  `960db55`). Agents work in the main worktree unless the lead says otherwise.

---

## 8. Current priority

**Inferred from the repository, and it is unambiguous:** `docs/ROADMAP.md` Part 2 gates, worked in
order, with UE5-as-a-runtime as the end goal (`ENGINEERING_RULES.md` §60, a standing user
instruction).

Gates 0, 1 and 3 are closed. Gate 2 item 2 is genuinely blocked. **Gate 4 item 1 was closed during
this session**; the next undone items in order are **Gate 4 items 2–4** (audio → UE5 SoundWave/
SoundCue manifests; particle/emitter templates for Niagara; interaction metadata) and then Gate 5.

**Two things should happen before that feature work, and both are in `TASK_QUEUE.md`:**

- ~~**TASK-000** — classify the four failing actor-schema tests.~~ **DONE, 23 Aug 2026.** All four
  were a shared coverage-bucket test-design defect, not a decoder regression; fixed, independently
  verified twice, integrated. See `TASK_QUEUE.md`.
- **TASK-008** — actually look at the UE5 import in the editor. The entire UE5 track rests on log
  evidence, and this project has been burned by exactly that before. Ten minutes.
- **TASK-003** — settle which package population a census counts, so that later figures mean
  something.
- **TASK-009** (new, raised during TASK-000's review) — audit the rest of the suite for the same
  shared-bucket pattern; one confirmed live instance already found (`InteractionActorSchemaTests.cs`),
  not yet failing only by numeric coincidence.

Priority is **resolved**, not invented: the roadmap states it, the gate order states it, and §60
records the user's own instruction to work it in sequence.
