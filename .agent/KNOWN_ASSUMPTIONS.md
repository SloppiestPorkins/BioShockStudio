# Known assumptions

**This file is a guardrail.** Every entry is something the code currently relies on, with the
evidence behind it. An agent that "fixes" one of these without new evidence will break output that
is currently correct — several of these were derived over multiple sessions and at least two were
originally wrong in a way that looked right.

Read the entry for whatever you are about to touch **before** you touch it. If you believe an
assumption is wrong, that is a Research task producing evidence, not a code change.

Confidence: **HIGH** = byte-level or external-reference proof plus a regression test.
**MEDIUM** = consistent across the whole game but no independent confirmation.
**LOW** = works on what has been looked at; could be package-local.

---

## A1 — Coordinate basis: one reflection, `C = diag(1, -1, 1)`

**Assumption.** BioShock/Vengeance is left-handed (+X forward, +Y right, +Z up), units centimetres.
Everything this project emits is right-handed. The conversion is a single reflection
`C = diag(1, -1, 1)`, `det(C) = -1`, applied at **exactly five decode boundaries and nowhere else**.
Nothing downstream — rasteriser, FBX writer, Blender importer, scene JSON — does any further axis
work.

**Evidence.** Measured from shipped skeletons in world space (`ProtectorRosie`,
`AggressorBabyJane`), three independent anatomical readings: feet near Z=0 and neck at Z=159 (up is
+Z); toe 23 units ahead of ankle in X (forward is +X); every `Bip01_L_*` at negative Y and every
`Bip01_R_*` at positive Y (right is +Y). Confirmed externally by FBX round-trip through Blender.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Coordinates/GameBasis.cs`,
`tests/BioShockStudio.Tests/CoordinateSystemTests.cs`,
`docs/research/ANIMATION_COORDINATE_SYSTEM.md`.

**Safe to change?** **NO.** Every asset this project produced for two years of commits came out
mirrored because this conversion did not exist. Adding a second axis operation anywhere downstream
re-creates that class of bug and it will not be obvious.

---

## A2 — Actor roll is negated: `Rx(-roll)`

**Assumption.** Composing a placed actor's rotation uses **negated roll**.

**Evidence.** Settled against the compiled world's own BSP tree, which classifies any point as
inside architecture or open space — so "how much of a rotated actor is buried in solid" is a cost
the correct composition minimises, with no reference implementation involved. Across six maps and
147,466 points on rolled actors: **negated roll 15.38% buried vs 25.85% shipped**; every other
candidate (pre-fix pitch, negated yaw, reversed order, reversed-negated) clusters at 25.9–27.3%.
Only one separates, by 40%. Rendering agrees: only this composition assembles the reported
`1-Medical` skylight into a continuous vault.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Level/ActorTransform.cs`,
`tests/BioShockStudio.Tests/ActorPlacementAgainstTheWorldTests.cs`,
`tests/BioShockStudio.Tests/ActorTransformReferenceTests.cs`, `docs/ROADMAP.md` Gate 0 item 1.

**Safe to change?** **NO.** Note specifically that `ActorTransformReferenceTests` — which compares
against Nyko's editor over all 12,557 shipped rotation/scale pairs — **stayed green while the roll
was wrong**, because the reference composes roll the same wrong way. A check that compares two
implementations of a rule cannot find a rule wrong in both. Agreement with the reference is not
evidence here.

---

## A3 — FName numbering renders with **no separator**

**Assumption.** An FName is a compact index into the name table plus an int32 "extra index". Extra
0 means the bare name; otherwise `extra - 1` is appended **directly, with no separator**:
`ambience_common_bubbles` + 2 → `ambience_common_bubbles2`.

**Evidence.** `CONFIRMED_EXTERNAL` against UEViewer's `GAME_Bioshock` FName path
(`UModel-master/`). Every reader in the repository follows it.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Packages/BioShockPackage.cs` (`ReadFName`, the definition),
`src/BioShockStudio.Core/Packages/UnrealProperty.cs`,
`src/BioShockStudio.Core/Level/PropertyValues.cs`,
`src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs`,
`src/BioShockStudio.Core/Audio/SoundEventReader.cs`,
`tests/BioShockStudio.Tests/SoundActorSpecificationTests.cs`.

**Safe to change?** **NO** — and note the failure mode. `SoundEventReader` wrote `name_N` instead.
Nothing threw, no test went red: the name simply matched no export, and **100 sound references
game-wide resolved to nothing** while looking like missing game data. If a name-keyed lookup misses
in this codebase, check the numbering convention before concluding the target is absent.

---

## A4 — Property lists start at offset 8; nested struct values at 0

**Assumption.** A BioShock export payload carries an 8-byte prefix before its tagged property list
(`UnrealPropertyReader.PayloadPropertyOffset = 8`). A **nested** struct value is itself a property
list and starts at **0**.

**Evidence.** Reading from 8 yields clean property names (`Format`, `USize`, `VSize`, `SourcePath`)
and a clean `None` terminator; reading from 0 produces garbage.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Packages/UnrealProperty.cs`.

**Safe to change?** **NO.** Calling the default overload on a nested struct value is a live trap —
it throws "Name index out of range" or silently under-reads. Pass `start: 0` explicitly.

---

## A5 — A struct's declared size omits its nested properties' size bytes

**Assumption.** A struct property's declared size does **not** count the size-encoding bytes of its
own nested properties (1, 2 or 4 bytes for encodings 5, 6, 7). `CorrectedStructSize` repairs this,
and only where the struct's own terminator proves it.

**Evidence.** A census of every struct-valued property on every material in the game: of 14,610
`MaskMaterial` structs, 9,152 declare their size exactly — every one of them having no nested
property with an explicit size — and the remaining 5,458 are short by exactly the number of
size-encoding bytes their nested properties carry. There are no other cases.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Packages/UnrealProperty.cs` (`CorrectedStructSize`),
`tests/BioShockStudio.Tests/StructSizeTests.cs`, `docs/research/materials.md`.

**Safe to change?** **NO.** This was the entire cause of the "partial material" problem — about half
the shaders in the larger packages stopped at their first `MaskMaterial`.

---

## A6 — A UE2 `Bool` carries its value in the property tag

**Assumption.** Bit 7 of the info byte is the array flag for every type **except** `Bool`, where it
is the boolean's value. `UnrealProperty.BoolValue` exposes it.

**Evidence.** Reading presence alone makes every serialized flag in the game read as true.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Packages/UnrealProperty.cs`,
`tests/BioShockStudio.Tests/SoundEffectSpecificationTests.cs`.

**Safe to change?** **NO.** Presence is not the value.

---

## A7 — `Try…Exact` readers must consume the whole value

**Assumption.** `PropertyValues.TryAsNameArrayExact`, `TryAsNameIndexArrayExact`,
`TryAsStructArrayExact`, `TryAsReferenceArrayExact`, `TryAsProjectorGradientExact` return **false**
unless the walk consumes the property value exactly. A valid-looking prefix is rejected.

**Evidence.** A partial read silently turns an unknown payload into a partial graph — the exported
result then looks complete and is not. Every whole-game array census in the repository (110,120
sound specification entries, 81,775 `SoundSpecs` entries, 123,500 level contexts, 974 navigation
references) reports 0 inexact arrays, which is only meaningful because inexact is a reportable
state.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Level/PropertyValues.cs`.

**Safe to change?** **NO.** Relaxing exactness to "make more things resolve" converts a truthful
partial result into a plausible wrong one, which is the specific failure this project exists to
avoid.

---

## A8 — Two array encodings coexist and must not be normalised

**Assumption.** BioShock ships both a numbered-FName array (name index + number pairs) and a bare
compact name-index array without the numbered suffix. `TrainingScript.Concepts` uses the second;
`AggressorSpawner`'s overridden archetypes use the first. Both are decoded separately.

**Evidence.** Byte-level, on the shipped arrays; the distinction is tested rather than smoothed
over.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Level/PropertyValues.cs`,
`tests/BioShockStudio.Tests/TrainingScriptActorTests.cs`,
`tests/BioShockStudio.Tests/SpawnerActorSchemaTests.cs`.

**Safe to change?** **NO.** Unifying them loses a real byte distinction.

---

## A9 — Package enumeration: 21 non-localised maps vs all 161

**Assumption.** `GameLocator.EnumeratePackages(root)` yields the **21 non-localised** map packages,
filtering the 140 per-language duplicates. Some existing sweeps instead use
`Directory.GetFiles(GameLocator.MapsDirectory(root), "*.bsm")` and therefore span **all 161**.

**Evidence.** `GameLocator.LocalizedSuffix()` regex; the two enumerations give figures differing by
roughly 5×.

**Confidence.** HIGH (mechanically), but this is a **live inconsistency**, not a settled design:
`SoundEventCoverageTests` counts 106,000 responses over all 161, while
`SoundEffectSpecificationCoverageTests` counts 33,227 specifications over the 21. Both are correct
for what they measure and the numbers are not comparable.

**Files.** `src/BioShockStudio.Core/Game/GameLocator.cs`,
`tests/BioShockStudio.Tests/SoundEventCoverageTests.cs`,
`tests/BioShockStudio.Tests/SoundEffectSpecificationCoverageTests.cs`.

**Safe to change?** **ONLY WITH NEW EVIDENCE**, and never silently. Changing which enumeration a
census uses changes its figure without any decode changing. Any test asserting a whole-game count
must state which population it counted. See `OPEN_QUESTIONS.md` Q7.

---

## A10 — The FMOD bridge is an x86 child process, and both pipes must be drained

**Assumption.** The game's FMOD runtime (`Build/Final/fmodex.dll`) is 32-bit and **cannot** be
loaded into this 64-bit process. `StreamAudioService` shells out to an x86 helper and reads its
stdout and stderr **concurrently**.

**Evidence.** A full 65-bank census deadlocked when stderr was drained to EOF first: a large
`--list` response filled the stdout pipe and blocked both child and parent.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Audio/StreamAudioService.cs`, `tools/fmod-x86/` (gitignored),
`tests/BioShockStudio.Tests/StreamAudioTests.cs`.

**Safe to change?** **NO** for the concurrent-drain part. Any refactor that serialises the reads
re-introduces a hang that only appears on large responses.

---

## A11 — Havok packfiles have a variable number of sections

**Assumption.** A Havok packfile here does **not** have a fixed three sections. The first-person
hands package has twelve. Frame rates are not a fixed 30. BioShock **does** use spline compression.
Animation channels fall back to the **skeleton's reference pose**, not to identity.

**Evidence.** Each of these was a carried-in assumption corrected by the shipped data; the
corrections are recorded with their evidence in `docs/research/havok.md` and
`docs/research/havok-compression.md`. Whole-game: 16,031 of 16,031 animations decode, 0 failures.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Havok/`, `docs/research/havok-compression.md`,
`tests/BioShockStudio.Tests/HavokPackfileTests.cs`,
`tests/BioShockStudio.Tests/SplineDecompressionTests.cs`.

**Safe to change?** **NO.**

---

## A12 — Bone indices are preserved, never re-ordered

**Assumption.** `BioShockSkeleton` keeps the original bone indices from the shipped skeleton.
Animation binding is index-based and depends on it.

**Evidence.** `docs/research/binding.md`; the FBX round-trip compares posed bone positions against
transforms composed independently from the game's own track data.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Skeleton/BioShockSkeleton.cs`,
`src/BioShockStudio.Core/Animation/AnimationPairing.cs`,
`tests/BioShockStudio.Tests/SkeletonTests.cs`, `tests/BioShockStudio.Tests/AnimationPairingTests.cs`,
`tests/BioShockStudio.Tests/SkeletonPartitionTests.cs`.

**Safe to change?** **NO.** Sorting or compacting bones silently breaks binding for every animation.

---

## A13 — First-person sockets are chosen by **name**, not by bone

**Assumption.** A first-person weapon attachment resolves its socket by socket name. Nine of the
hands' sockets share the bone `R_grip`.

**Evidence.** Choosing by bone gave every weapon the `Wrench` socket, which carries a 180° turn
about Z where `Pistol` and `Chem` carry identity — so every weapon appeared backwards. Fixed
16 Aug 2026.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Mesh/` socket handling, `docs/research/firstperson.md`,
`tests/BioShockStudio.Tests/SocketOrientationTests.cs`,
`tests/BioShockStudio.Tests/FirstPersonWeaponOrientationTests.cs`.

**Safe to change?** **NO.**

---

## A14 — `MeshGeometryReader` has two overloads and only one yields sections

**Assumption.** The byte-only overload of `MeshGeometryReader.Read` returns geometry with an
**empty** `Sections` list. The package-aware overload is required for per-material sections.

**Evidence.** `AssetDiagnostics.ScanMesh` called the byte-only overload and therefore flagged every
multi-material skeletal mesh as lacking a section table, including ones that resolved fine. Fixing
the call dropped the count from 157 to 94.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Mesh/MeshGeometryReader.cs`,
`src/BioShockStudio.Core/Diagnostics/AssetDiagnostics.cs`, `docs/QUALITY.md` §2.

**Safe to change?** The overloads are fine; **the trap is calling the wrong one**. Any new caller
that needs sections must use the package-aware form.

---

## A15 — No synthetic fixtures, ever

**Assumption.** Every test reads the real installed game. `GameFixture` locates it (or
`BIOSHOCK_REMASTERED_PATH`) and `RequiresGameFact` skips cleanly when absent. The Fast/Sweep split
is by **how much** real data a test reads, never by faking any.

**Evidence.** `TierCoverageTests` asserts every test class declares exactly one tier, so nothing can
fall out of both and stop running. No game data is in the repository.

**Confidence.** HIGH.

**Files.** `tests/BioShockStudio.Tests/GameFixture.cs`, `Tiers.cs`, `TierCoverageTests`.

**Safe to change?** **NO.** Introducing a fixture file to make a test fast or deterministic is
prohibited by `docs/ENGINEERING_RULES.md` §26.

---

## A16 — `SoundToPlay` is null on every shipped sound entry

**Assumption.** The sample **name** is the only link from a `SoundEffectSpecification` to its audio.
The object reference sitting beside it (`SoundSpecEntry.SoundToPlay`) is null on all 81,775 shipped
entries.

**Evidence.** Whole-game census, 23 Aug 2026.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Audio/SoundEffectSpecificationReader.cs`,
`tests/BioShockStudio.Tests/SoundEffectSpecificationCoverageTests.cs`.

**Safe to change?** N/A — but an implementation that follows the object reference will resolve
nothing at all. Use the name.

---

## A17 — Sound-actor matching is exact; nothing is normalised

**Assumption.** `SoundActorSpecificationIndex` matches actor-declared names exactly. `AmbientSound`
reaches its specification via the response named `AmbientSoundSpawned_<Tag>`; `SoundMarker` names its
specification outright via `Schema1`/`Schema2`. The two routes are disjoint in the shipped data.

**Evidence.** All 10,360 `AmbientSoundSpawned_*` responses carry `Event = "Spawned"` and
`SourceClassName = "AmbientSound"`, no exceptions — that is what makes the prefix structural rather
than a resemblance. 3,068 of 3,247 actors resolve.

**Confidence.** HIGH for the route; the 179 unresolved are genuinely unresolved.

**Files.** `src/BioShockStudio.Core/Audio/SoundActorSpecificationIndex.cs`,
`tests/BioShockStudio.Tests/SoundActorSpecificationCoverageTests.cs`, `docs/research/audio.md`.

**Safe to change?** **ONLY WITH NEW EVIDENCE.** Fuzzy or normalised matching is explicitly ruled
out: labels such as `LightSquare` and `Bubbles` are *not* sample names and must not be coerced into
them.

---

## A18 — `Flag` is `Material.EMaterialVisualType`, the physical-surface enum — **PROMOTED, 23 Aug 2026**

**Assumption, now confirmed.** `SoundSpecEntry.Flag` (0–27) is BioShock's own
`Material.EMaterialVisualType` enum value, not a project-invented grouping. Decompiling
`IGSoundEffectsSubsystem.U` (`tools/uelib-bridge`) shows the field declared as
`var config Material.EMaterialVisualType Flag;` in `SoundEffectSpecification.uc`, and the same type
is the parameter of the (native) `PickSoundToPlay(Material.EMaterialVisualType inTextureFlags, ...)`.
`Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Materials_And_Shaders.md` independently
describes the same field: "physical-surface class (Stone, Glass, Flesh, Water, …) — drives
footstep/impact/decal selection, not rendering." Its full 28-value declaration (0–27, matching the
observed range exactly) is in `Bioshock1REMSDK-WIP--main/tools/property_db.json`:

```
0 MVT_Default        7  MVT_ThinMetal     14 MVT_Flesh          21 MVT_ElectricalGlass
1 MVT_Concrete        8  MVT_ThickMetal    15 MVT_Carpet         22 MVT_ElectricalMetal
2 MVT_Stone           9  MVT_Wood          16 MVT_Dirt           23 MVT_ExteriorGlass
3 MVT_ThinGlass       10 MVT_Plastic       17 MVT_WaterPipe      24 MVT_Mud
4 MVT_ThickGlass      11 MVT_Cardboard     18 MVT_Plant          25 MVT_BreakableGlass
5 MVT_ThinCloth       12 MVT_Plaster       19 MVT_FleshAlternate 26 MVT_Paper
6 MVT_ThickCloth      13 MVT_Water         20 MVT_OpaqueGlass    27 MVT_Trash
```

The original sample-name-only hypothesis is now exactly confirmed by the game's own declared enum:
`MVT_ThinMetal`(7)/`MVT_ThickMetal`(8) matches "7/8 are metalThin/metalThick" and `MVT_Cardboard`(11)
matches "11 is cardboard" precisely.

**Evidence.** CONFIRMED_EXTERNAL — two independent sources agree: the decompiled UnrealScript field
declaration itself, and Nyko's SDK's independently-authored materials documentation.

**Confidence.** HIGH (identity of the field). The *behavioural* claim — that the game actually
dispatches `PickSoundToPlay` by the caller's surface-visual-type argument — is not itself decompilable
(the function is native, `__NFUN_`-only in the UnrealScript output) but is exactly what its own
signature and name state, and matches the SDK doc's plain description.

**Files.** `src/BioShockStudio.Core/Audio/SoundEffectSpecificationReader.cs`,
`tests/BioShockStudio.Tests/SoundEffectSpecificationTests.cs`; new evidence at
`Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Materials_And_Shaders.md:68`,
`Bioshock1REMSDK-WIP--main/tools/property_db.json:15772-15800`, and a fresh decompile of
`IGSoundEffectsSubsystem.U` → `SoundEffectSpecification.uc:60,170` (not committed — decompiled output
is never committed, `tools/uelib-bridge/README.md`).

**Safe to change?** Exposing `Flag` as the named `MaterialVisualType` enum (28 values, above) rather
than a raw byte is now well-evidenced and low-risk — logged as **TASK-010**. Actually *acting* on it
(surface-keyed sound selection at export time) is a larger Gate-4-adjacent feature decision, not
implied by this evidence alone, and should go through a Research → Lead-decision step first the way
`AGENT_PROTOCOL.md` requires for any behavioural change.

---

## A19 — Chance / level-context selection is deliberately not implemented

**Assumption.** `Chance` is a parallel int array with exactly one entry per sound alternative
(values 0, 20, 30, 50, 70, 75, 80, 100). It is exposed and **not interpreted**. Reading it as a
percentage is `LIKELY`, not a rule. Which alternative wins at runtime is engine behaviour and is
deliberately undecided.

**Evidence.** 105,580 responses carry chances; the count equals the specification count on every
response that has sounds.

**Confidence.** HIGH for the pairing, LOW for the meaning.

**Files.** `src/BioShockStudio.Core/Audio/SoundEventReader.cs`,
`tests/BioShockStudio.Tests/SoundEventCoverageTests.cs`.

**Safe to change?** **ONLY WITH NEW EVIDENCE.** Do not implement a winner-picking rule from the
numbers alone.

---

## A20 — `Region` is UE2's `FPointRegion` and cross-checks itself

**Assumption.** Every actor's `Region` property is `FPointRegion` (`Zone`, `iLeaf`, `ZoneNumber`) as
a nested tagged list. `iLeaf == 0` is a "no leaf" sentinel.

**Evidence.** `ZoneNumber` and `Leaves[iLeaf].Zone` are the same fact from different bytes and agree
on **96,136 of 96,376 (99.75%)**; 20,159 actors carry the sentinel; the 240 that disagree are
disproportionately brushes (`PLAUSIBLE`: a brush indexes its own model's leaves).

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Level/LevelModel.cs` (`ActorRegion`),
`tests/BioShockStudio.Tests/ActorRegionTests.cs`, `docs/research/bsp.md`.

**Safe to change?** **NO.**

---

## A21 — "Pending" in the coverage ledger means *not placed in UE5*, not *undecoded*

**Assumption.** `LevelCoverage` labels such as `LightPending`, `ScriptPending`, `MarkerPending`,
`InteractionPending`, `RuntimeStatePending` mean "decoded, but no UE5 actor representation has been
selected yet". They do **not** mean bytes remain unread.

**Evidence.** Each category has a schema test asserting the complete manifest record; `1-Medical`
`Unclassified` is zero.

**Confidence.** HIGH.

**Files.** `src/BioShockStudio.Core/Level/LevelCoverage.cs`, the `*ActorSchemaTests.cs` family,
`docs/ROADMAP.md` Gate 3 item 3.

**Safe to change?** N/A — but do not open a decode task because a ledger says "Pending". Check which
kind of pending it is first.
