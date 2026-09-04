# Handoff

> **Read this first.** It is the project's institutional memory. If a discovery exists only in a
> chat, it does not exist.

## Active work ? check and update this before touching a shared file

Two AI agents (Claude Code and a separate Cursor session) work in this repository
concurrently, on one branch, with no other coordination mechanism between them. This table is it.
Work is split by file ownership - see `docs/DUAL_AGENT_ROADMAP.md` (Cursor owns `tools/ue5/**`,
Claude Code owns `src/**` / `tests/**`). The claim table still governs any shared file.
**Before starting work, add a row. Before touching a file another row claims, check with the user
first** ? they're the one relaying between both sessions and can say whether it's stale or still
live. Remove your row when the track lands (committed) or you stop working on it. An empty table
means no row is currently claimed, not that no one is working ? always check the date.

> **23 Aug 2026 ? a local four-agent team (research / coding / testing / review) was set up and then
> retired the same day.** Its coordination layer lived in `.agent/` and its launcher in
> `.agent-control/`; both were removed once the experiment ended (`4c6c109`, `a06779e`, `9cb53b2`
> hold them in history if they are ever wanted back). **The durable findings were merged into this
> file and `docs/research/` rather than deleted with it** ? see ?4's coverage-bucket landmine and
> `docs/research/audio.md` on `Material.EMaterialVisualType`. This table remains the claim mechanism
> for any concurrent session.

| Agent | Track | Areas / files | Started |
|---|---|---|---|

_(no rows currently claimed — check the date on any that appear; an empty table means no active claim, not that no one is working. Recently cleared: 1-Medical wall textures landed `4be2d3e`; script-importer mapping defect landed `<a14>`.)_

**Backlog landed at `4d2247e` (28 Aug 2026).** Cursor item 0.

> **Interface note — 28 Aug 2026, additive, non-breaking.** `LevelLightDocument` gained four
> optional fields (`cone`, `type`, `effect`, `period`) from the new light decode
> (`docs/research/lights.md`). **`LevelManifestVersion` is unchanged (still 4)** — the fields are
> purely additive and `import_level.py`'s `version != SUPPORTED_FORMAT_VERSION` check still passes.
> The Cursor lane can pick them up whenever it does `SpotLight` / flicker import; nothing needs to
> change on that side first. A non-zero `cone` means "spawn a SpotLight"; `type`/`effect`/`period`
> are raw bytes with low confidence — do not map them to UE enums without pinning first.
>
> **Also 28–29 Aug — `LevelDocument.archetypes` and `.resistanceSets`**, additive / no version
> bump. Each map's `AIArchetype` records (class, mesh, health, resolved loadout slots, status
> tuning) plus the `[*ResistanceSet]` tables its archetypes name, resolved once from `Weapons.ini`
> inside `ConfigINI.IBF`. `docs/research/spawning.md` + `config.md`. Phase 3's `AShockAI` build:
> `document.archetypes` keyed by name; `archetype.damageResistanceSetName` → `document.resistanceSets`.
> The ~46 archetypes no map ships (incl. `PlayerEscortedGathererDLCCombat`) are in `Spawning.ini` —
> `AiArchetypeConfig.Read` / `bioshock-tool archetypes --all`.
>
> **`IniBundle`** now reads the whole config bundle — `Spawning.ini`, `Weapons.ini`,
> `LootTables.ini`, `Ai.ini`, `Plasmids.ini`, `Difficulty.ini`. The UE5 import scripts can load
> `ConfigINI.IBF` directly for anything the manifest doesn't carry.

**Recently released:** Phase 0 mechanical fire on 1-Medical — GameMode spawns `SliceBabyJane` (Agg_BabyJane mesh) 250 uu along +Y (Y=1272→1522) and hitscan drops health 100→75 (`BIOSHOCK_SLICE_OK fire=1`, `-game -bioshockverifypossess`, 28 Aug 2026). Human PIE feel still open. SpawnPickup / SpawnTurret / HackTurret / HackSecurity / SetDoorBrokenState (`0292b99`). quests/timers/HUD/alarms (`fd107ec`). Possess at MedicalStart.

**Recently released (do not re-claim as live):** Cursor Phase 4 through 27 Aug 2026 — world-AI
runner; movement/goal. Older rows cleared.

> **Collision note (historical, 23 Aug 2026).** A Claude session's Materials / Gate 1 item 4 claim
> was breached by another session that finished the item (`2cc637b`, `b2c6808`). Kept here as a
> reminder to check the table before starting.

**Why this exists, not a branch-per-track workflow:** day-to-day work is on **`main` only** (feature
branches are not the standing process). Concurrent agents still need this claim table because they
share one working tree. A written claim is the lowest-overhead coordination both sessions can check. The
existing git-hygiene rule below (stage by filename, never `git add -A`, commit in small logical
groups) is the safety net under this ? it limits the blast radius of a collision even when this
table is stale or unchecked.

## Current state

**[`docs/ROADMAP.md`](ROADMAP.md) is the canonical status document** ? what's done (Part 1), what's
left in gate order (Part 2), and the whole-game figures behind each claim, kept current rather than
duplicated here. This section used to carry its own status table; it went stale (still said "PHASE
1C ? diagnostics" long after UE5 import, audio, lightmaps and physics work had all moved past that),
which is exactly the failure mode `docs/ROADMAP.md` Part 0.6 exists to stop. For test figures, see
`docs/ROADMAP.md` "Test health"; for headline mesh/material/texture/animation numbers, each pinned by
a test, see `docs/QUALITY.md`.

```bash
dotnet test --filter Tier=Fast                       # ~40s ? run while working
dotnet test --filter "FullyQualifiedName~<Class>"    # the sweep classes your diff touches
dotnet test --filter Tier=Sweep                      # ~19min ? only when the diff reaches shared code
dotnet test                                          # both ? only when reporting a whole-suite total
```

**Re-running the full suite to re-confirm another session's measurement is the waste this project
kept paying.** Read the verification stamp at the top of `docs/ROADMAP.md` "Test health" before any
sweep run; `docs/ENGINEERING_RULES.md` ?60 "Test-run economy" has the rule (standing user
instruction, 23 Aug 2026).

**The suite is now split into two tiers.** The whole thing takes about ten minutes and that was
visibly changing how carefully changes got verified ? it was cheaper to reason about a change than
to run the tests, which is the wrong way round. The fast tier is the classes that read one package
or none; the sweep tier is the whole-game censuses, the bulk store, the whole-catalogue builds and
the UI tests, which build a catalogue in order to have something to show.

**Speed came from reading less real data, never from fabricating any.** There are still no synthetic
fixtures. Nothing was dropped or weakened to hit the time: `TierCoverageTests` asserts that every
test class declares exactly one tier, so a test cannot fall out of both and quietly stop running,
and the two filtered runs add up to the unfiltered one.

The split was made from measurement, not by inspection ? a TRX run gave per-class cost and four
classes that looked cheap turned out to read the whole install. Note that most classes share one
xUnit collection and therefore run serially, so the fast tier's wall clock is close to the sum of
its parts rather than the maximum.

A cold run right after a large scan measured 19 minutes; that is the file cache, not the tests.

Tests read the real install (auto-detected, or set `BIOSHOCK_REMASTERED_PATH`) and skip cleanly if
it is absent. **No game data is in the repository**, and `/artifacts/` is gitignored.

To run the application:

```bash
dotnet publish src/BioShockStudio.App/BioShockStudio.App.csproj -c Release -o artifacts/app
```

Close the app before republishing ? a running instance locks the DLLs and the publish fails.

---

## 1. What this project is

A Windows tool for extracting BioShock 1 Remastered's skeletal meshes, skeletons, Havok animation
and materials into Blender and FBX. It is both an extraction tool and a reverse-engineering
notebook: `docs/research/` records what is known about the formats, with confidence labels, and the
code refuses to guess where the notes say `UNKNOWN`.

The target case, and the thing to check after any change to the pipeline: **the first-person pistol**
? hands, weapon, skeletons, correct animations, sockets, materials, textures, out to FBX.

## 2. What works

This section used to carry its own line-by-line status table. It went stale the same way ?"Current
state" above did ? "Unreal import: Never attempted" long after UE5.7 import was verified on eight-plus
rig families, a materials figure that disagreed with `QUALITY.md` in three places at once ? which is
the exact drift Part 0.6 of `docs/ROADMAP.md` exists to stop. **For what works, see
`docs/ROADMAP.md` Part 1** ("What's done"), kept current; **for the byte-level mechanism behind any
one item** (how sockets, weapon upgrades, cross-package material references, the bulk-mip store, or
the coordinate reflection actually work), see the relevant `docs/research/*.md` file ? that detail was
never duplicated here in the first place, and still lives only in the research notes.

## 3. Architecture

```
BioShockStudio.App          window and view models ? no format knowledge, no parsing
        ?
Core/Services               application services, tested without a window
        ?
Core                        Packages, Havok, Mesh, Materials, Textures, Skeleton, Animation
        ?
Core/Export, Core/Rendering scene JSON, FBX, PNG/DDS; the preview rasteriser
```

The view model holds no parsing and no output-path decisions. That is what lets the services be
tested without a window, and what stops the browser and the CLI disagreeing about what an asset is.
`docs/GUI.md` covers the application in detail.

**Never put format knowledge in a view model.** If the window needs to know something about the
data, the service should tell it.

## 4. Landmines ? things that cost real time to find

Each of these produced a plausible, wrong result before it was understood.

- ~~**`ClassDefaults` can silently recover a property list that starts mid-stream, skipping real
  leading properties, on at least two classes.**~~ **Fixed, 25 Aug 2026.** The bug was not a
  struct-size mis-walk: several offsets can produce a clean walk to EOF, and the reader returned the
  *earliest*. On `BerserkRageAbility` that earliest hit was a 10-property mid-stream list starting at
  a numbered `Text?` name; the true 14-property list (starting at `ProjectileClass`) starts 29 bytes
  later. On `ShockPlayer` the earliest was a bogus `GetNumberOfItems` Float (a function name); the
  longest clean walk (119 properties from `BasePlasmidSlots`) includes `SanctuaryModelClass`. Fix:
  prefer the longest clean walk. Census on all 654 `Class` exports in `ShockGame.U`: 17 differ
  between earliest and longest, and longest is strictly longer on every one. Pinned by
  `WeaponEffectsTests.BerserkRageAbilityResolvesProjectileClassOnceClassDefaultsTakesTheLongestWalk`
  and `ShockPlayerSanctuaryModelClassIsVisibleAfterTheLongestWalkFix`.
- **The `properties` CLI command's own `Bool` display always printed `"true"`, regardless of the
  actual value.** Found 25 Aug 2026 decoding `DoorSwitch`'s `DamagedReactions`/`UsedReactions`: the
  tool's own output showed `OnceOnly` as `true`, a real decoded test assertion was written against
  that, and the test itself immediately failed ? the true value is `false`. `UnrealProperty.BoolValue`
  itself was always read correctly; only this one reconnaissance command's display line
  (`UnrealPropertyType.Bool => "true"`, both the top-level and the struct-array-unpacking copy of it)
  was wrong. Fixed to print the real value. Any conclusion drawn from a `properties` command's Bool
  output examined *before* this fix landed should be re-checked, not trusted.
- **A coverage-bucket total is not a per-class count, and seven tests asserted as if it were.**
  `LevelCoverage.Classify()` deliberately routes several unrelated actor classes to the same
  UE5-representation-pending status ? that part is correct design. Four Sweep-tier tests summed the
  whole bucket as though it uniquely identified their own class, so each went red the moment any
  *other* class joined it:

  | Bucket | Composition | Total |
  |---|---|---|
  | `MarkerPending` | `Marker`(150) + `TrainingMarker`(6) + `MapUILayerScaleMarker`(3) | 159 |
  | `InteractionPending` | `MedHypoPickup`(11) + `PlaceableVendingStation`(3) + `DoorKeypadControl`(1) + `dyn_toolbox_open`(1) | 16 |
  | `ScriptPending` | `Script`(300) + `TrainingScript`(26) | 326 |

  **The trap is that the failure looks like a decode regression and the tempting fix is the wrong
  one.** Every count had gone *up*, which reads as "something now over-captures" ? and editing the
  expected number up to match would have gone green while destroying the assertion's meaning.
  Production code was correct throughout; nothing in `LevelAnalyzer.cs` or `LevelCoverage.cs`
  changed. The correct idiom already existed in `MapUiMarkerSchemaTests.cs` and
  `CoverageBoundaryActorTests.cs`: filter `coverage.Classes` to your own `ClassName` before summing.
  Fixed 23 Aug 2026 in `43dcaaa`; three more tests carrying the same latent bug were hardened in
  `1782d3b` before they broke. An eighth, `InteractionActorSchemaTests`, asserted the whole
  `InteractionPending` total (16) while testing two of its classes and passed only by numeric
  coincidence; it was closed the same day. **`InteractionPending` is now pinned per class and in
  full** ? 11 + 3 + 2 = 16 across `PickupActorSchemaTests`, `VendingActorSchemaTests` and
  `InteractionActorSchemaTests` ? so the bucket keeps its total coverage without any one test
  claiming that total as its own class's count.

  **Known gap left behind:** filtering to your own class means no test now notices a *new* class
  joining a bucket. The buggy form at least went red. Nine assertions still sum a whole bucket and
  are the remaining canaries ? `EffectActorSchemaTests`, `HavokConstraintActorSchemaTests`,
  `HavokForceActorSchemaTests`, `LevelInfoActorSchemaTests`, `LevelSceneTests`,
  `MapUiMarkerSchemaTests` (its `MapMarkerPending` line only), `ProjectorActorSchemaTests`,
  `ShockAiScoutActorSchemaTests` and `SoundActorSchemaTests`. Each of those buckets holds one class
  today, so they are canaries by accident rather than design; **do not "fix" them without replacing
  the signal.**

  **Counting them is itself a trap.** A first pass at this list found four, by grepping for the
  bucket sum and excluding any file containing `ClassName` ? which wrongly drops every test that
  mentions `ClassName` in an unrelated assertion (`document.Actors.Where(a => a.ClassName == ...)`).
  Grep for the sum and exclude the match *line*, not the file.

- **A numbered FName renders `nameN`, with no separator ? and one reader wrote `name_N`.**
  `BioShockPackage.ReadFName` appends `extra - 1` directly (CONFIRMED_EXTERNAL against UEViewer's
  BioShock branch), and every other reader in the project follows it. `SoundEventReader` wrote
  `name_N` instead. Nothing threw and no test went red: the name it produced simply matched no
  export, so **100 sound references game-wide resolved to nothing** and looked like missing data
  rather than a rendering bug. Found only by asking why `ambience_common_bubbles_2` had no
  specification when `ambience_common_bubbles2` was sitting in the same package. If a name-keyed
  lookup misses in this codebase, check the numbering convention before concluding the target is
  absent. Fixed 23 Aug 2026; `SoundActorSpecificationTests.ANumberedSpecificationNameMatchesItsExport`
  pins it.

- **Every asset this project produced was mirrored, for two years of commits, because there was no
  coordinate conversion at all.** BioShock's basis is left-handed (+X forward, +Y right, +Z up);
  every consumer ? the preview rasteriser, FBX as Blender reads it, Blender, glTF ? is right-handed.
  No rotation can bridge those, and both the FBX axis declaration and Blender's importer conversion
  are rotations, so nothing in the round trip could detect it. Every numeric validation passed the
  whole time; they were faithfully carrying mirrored data. Fixed by one reflection,
  `C = diag(1,-1,1)`, applied at four decode boundaries and nowhere else.
  **`docs/research/ANIMATION_COORDINATE_SYSTEM.md` is required reading before touching any transform.**
- **The reflection fixes the triangle winding on its own ? do not also reverse the indices.** The
  game is front-face clockwise (100% of triangles, three meshes). A cross product transforms by `-C`
  and a normal by `+C`, so the reflection negates their agreement and the result is
  counter-clockwise, as FBX and Blender want. Reversing the winding on top of it puts the geometry
  back the wrong way. This was implemented the intuitive way first and the tests caught it.
- **An omitted channel component is Havok's IDENTITY, not the bone's reference pose.** This was the
  Phase 1 blocker and it cost three sessions. Havok's own `recompose` fills a component that is
  neither static nor spline from an "Identity values" vector ? 0 for a translation, 1 for a scale,
  `(0,0,0,1)` for a rotation. Filling it from the reference pose instead gives the *same answer* for
  every bone whose bind translation is zero in the omitted components, which is nearly every bone in
  the game; it differs only where a bind translation is not axis-aligned. On the first-person rig
  that is exactly `Bip01_L/R_UpperArm`, and it put each arm root 93 cm from its clavicle instead of
  19 cm. **The evidence recorded for the wrong reading was circular** ? "filling from the reference
  pose keeps 4,442 of 4,452 tracks at their rigid bone length" is true by construction, because
  filling from the bind pose preserves the bind pose's lengths. A `CONFIRMED_BYTES` label is only as
  good as the test behind it, and that test has to be able to fail.
- **A channel that stores *nothing* is still the reference pose.** Havok reaches `recompose` through
  `readNURBSCurve`, so a channel with no components is never read and the caller's value survives.
  Applying identity there instead collapses 44 of `AggressorBabyJane`'s bones onto their parents in
  `smg/smg_fire`.
- **The animation reference-pose fallback is where a double conversion hides.** Omitted channels
  fall back to the bound bone's reference pose, which comes from the already-converted skeleton
  while the compressed data has not been converted yet. `AnimationPackage.Decode` takes the fallback
  back to the game's basis before decoding so the whole result can be converted once. Get this wrong
  and bones sit on the wrong side *only* when their motion happens to be missing a channel.

- **Blender rest matrices must be set via `EditBone.matrix`.** Building bones from head/tail lets
  Blender pick its own roll, so the rest basis differs from the game's by up to a full axis flip and
  every animation plays the wrong motion while still looking fine.
- **Every bone must be keyed in every Blender action**, including undriven ones, or poses leak
  between actions. FBX does not need this ? an unkeyed node holds its reference pose, which is
  already correct.
- **The mesh index buffer addresses the rigid vertex block first**, though the skinned block is
  stored ahead of it. Every count-based check passes either way; only triangle size distinguishes
  them (median edge 0.87 against 44.04).
- **Animation channels fall back to the bound bone's reference pose**, not identity ? binding must
  be resolved *before* decoding.
- **A first-person animation is a two-rig performance.** The hands' `Pistol` socket names bone
  `R_Grip`; the weapon's skeleton is rooted at `R_grip`; their animations are the same performance ?
  same *duration*, not necessarily the same frame count (see below). Do not merge the skeletons.
- **Playing one weapon's animation set with another weapon attached looks exactly like a broken
  attachment.** The launcher passes through the forearm and neither hand is on the grip ? and
  nothing is wrong with the attachment at all; the hands are posed for a gun that is not there. The
  attachment picker now switches the animation set with it.
- **Pair attachment animations by DURATION, not by frame count.** ~~Two rigs playing one performance
  have exactly the same number of frames.~~ **That claim was wrong** and the shipped data disproves
  it: a weapon rig is often authored sparsely, so the launcher's 0.70s `FireLast` is 2 frames at
  1.43 fps against the hands' 22 frames at 30, and its `Equip` is 2 frames against 8. Requiring
  equal frame counts silently dropped the weapon's motion from the crossbow reload (93 against 91),
  the launcher's `FireLast` and `Equip`, and every zoomed fire ? which looks exactly like a broken
  attachment. The rule is now duration within 15%, in `Core/Animation/AnimationPairing.cs`, used by
  both the preview and the FBX manifest so they cannot disagree. The pairing the old guard existed
  to reject, `FireLauncher` against `FireLast`, is 51% apart; every correct pairing is within 10%.
  The attachment is also sampled by **normalised time**, since the two rigs no longer agree on frame
  count.
- **`LockTranslation` must not be applied when sampling.** It is set on 66.6% of the game's bones,
  and 59,889 tracks drive a translation on a bone carrying it ? including `Bip01_Spine`, the
  first-person root, 89.8 cm from its reference pose. Honouring it as "ignore the animated
  translation" would pin every rig to its bind root. It is a `hkaSkeletonMapper` retargeting hint;
  it is preserved, unused, and documented where it is declared.
- **FBX has no quaternion channel for a node's rotation.** Every rotation converts to Euler, order
  `Rz ? Ry ? Rx` on column vectors. A wrong order animates plausibly and wrongly.
- **One FBX declares one frame rate**, and the shipped animations do not share one ? 30.00, 29.94
  and 27.02 all occur within the pistol set ? so each animation gets its own file.
- **A `StaticMesh` vertex has no UV in it.** 48 bytes of position and tangent basis, and the UVs
  follow in separate full-length streams. Writing the reader by analogy with the skeletal record ?
  where the UV sits at +48 ? puts the next vertex's position where the UVs should be.
- **Any one of a static vertex's three basis vectors may be degenerate.** `Turret_Cover` ships a null
  tangent with a good normal, `LS_Hat` the reverse. Requiring all three to be unit length, as the
  skeletal reader does, silently drops 33 of 610 meshes in one package. Requiring one of three
  decodes all 8,668.
- **A static mesh must not be drawn next to its group's skeleton.** Selecting `ConeDrill` used to
  load `NewProtectorBouncer`'s rig alongside it, because the preview resolves animations by group.
  Nothing was numerically wrong and the viewport implied a binding that does not exist. The prop is
  now shown alone until it can be placed on its socket.
- **A skinned block with a count of zero is an empty block, not an absent one.** A weapon's vertices
  are all rigidly bound, so it writes `0` for the skinned count and the rigid block follows.
  Rejecting that zero is what kept every weapon viewmodel undrawable ? 38.1% of skeletal meshes
  decoded, now 98.1% ? while their sockets, skeletons, animations and materials all resolved, so
  nothing looked broken except the empty viewport.
- **Most textures are not in the packages.** They ship stripped, with the top mips in
  `BulkContent`, so a texture that says `USize 2048` carries a chain topping out at 64 ? 1,639 of
  ~1,937 in one package. Nothing inside a package reveals this except `HasBeenStripped`, so the
  tool drew the bottom of the chain for most of the game and looked merely blurry.
- **`StrippedNumMips` is not reliable.** Deriving the recovered chain from it gets 542 of 1,539
  textures; deriving it from the blob size ? the run of levels that sums to it exactly ? gets 1,530.
- **A texture name is not unique across bulk-content groups, and the duplicates are different art.**
  112 catalogue names appear in more than one group and **all 112 point at different bytes**.
  Resolving without the group put another group's texture on **340 of 30,831 texture exports**. The
  final boss drew as a black figure with white paint strokes over him because `Atlas_Diffuse`
  resolved to the `Gen_Graffiti` "ATLAS IS WATCHING" wall decal instead of his skin ? both 2048?
  DXT1, in the same chunk, 2.8 MB apart, so the alignment, the exact mip-chain decomposition and the
  seam check all passed on the wrong texture. The group comes from the export's **outer**, which
  resolves to a catalogue group for 24,950 of the 30,831 exports. `docs/research/bulkcontent.md`.
- **A `SkeletalMesh`'s property list is empty.** Its material reference is in the binary payload,
  after a tag block whose position varies between meshes (64 in `NEWPlayerHands`, 54 in
  `WP_PistolMesh`), so the block is found by search.
- **A mesh's material reference is a counted array, not one reference.** The count was recorded as a
  fixed `byte 1`; meshes with two materials read `2` and lost their second.
- **A struct property's declared size omits its nested properties' size bytes.** This was the last
  place the tagged-property walk lost alignment, and it cost about half the shaders in the larger
  packages. A nested property with an explicit size costs 1, 2 or 4 bytes the declared size does not
  count, so the outer walk advanced that many bytes too few and stopped inside the next property's
  name. Census: **14,610 `MaskMaterial` structs ? 9,152 exact (none with a nested explicit size),
  5,458 short by exactly their nested size bytes, no other cases.** Do not apply the rule blindly:
  `Color` is a plain four-byte BGRA value, not a property list, and there are 6,329 of them. The
  reader corrects only when the nested walk **lands exactly on a terminator** at the corrected
  length. Result: **13,545 materials, 0 partial.**
- **"Unsupported format" is a diagnosis, and it was the wrong one.** The 18 `SkeletalMesh` exports
  that yield no geometry were described for several sessions as an unread vertex stride to be found.
  They are four door rigs that **carry no vertex data at all** ? payload sizes separate cleanly
  (=2,443 bytes decode, =1,291 do not), their groups hold a rig and open/close animations with no
  drawable mesh, `AtlasLabsDoorAnim` ships `Model`/`Polys` (BSP), and other doors decode fine. The UI
  said "a geometry layout this tool does not read yet" and was blaming the reader for the data.
- **A validator that picks the wrong object reports a fault that is its own.** The material check
  selected `meshes[0]` when it could not find the host by name, and in a library that is whichever
  prop happened to be created first ? so the hands' library "failed" because the Bouncer's cigarette
  had a different material list. The host mesh is `<sourceObject>_Mesh`, and attachments are excluded
  by their own marker. **Check what a failing check is actually looking at before believing it.**
- **The first-person rig is not a representative sample.** Two faults survived because the pistol
  looked right: sockets were assumed to have no offset (**every** first-person weapon socket has a
  zero origin, and 60% of the game's do not), and weapon upgrades were assumed to be in the weapon's
  group (11 of 13 are; the 2 that are not are the 2 with their own rig). The hands are the project's
  target case and its most-checked asset, which makes them the easiest thing to over-generalise
  from. **Check a claim on something that is not a weapon before writing it down.**
- **A `TArray` count in this era is an `FCompactIndex`, not an `int32`.** Reading `AttachCoords`'
  count as an `int32` put every subsequent float three bytes out and produced NaNs and 1e38s ? which
  looked like "this is not a transform array" and cost two wrong readings before UModel settled it.
  When floats decode as garbage, suspect the count before the record.
- **An empty material slot must keep its position.** A `Materials` array's own count is what the
  section table indexes, and 40 of the game's 10,198 slots resolve to nothing ? some a *declared*
  null (an `Object` property with an implicit size and reference 0), some a reference truncated by
  the array's one-byte-short declared size. Dropping them shortened the list and shifted every later
  section onto the wrong material. The list is now built exactly `count` long with unread entries
  left null, and that alone took sections-equal-slots from 8,632 to **8,668 of 8,668**. Read the
  slot-ordered `ReadMeshMaterialSlots`, never the compacted `ReadMeshMaterialReferences`, when
  indexing by section.
- **A wrong section/material pairing is invisible to every numeric check.** Every triangle still has
  a material, every count still agrees, and the mesh is complete ? it is just wearing the wrong
  paint. `bat_vehicle` with its two runs swapped is a glass hull with a metal window, and only a
  render shows it. This is the same lesson as the mirrored-asset years: **numbers cannot see it.**
- **The scene JSON was 60.5% indentation.** It was pretty-printed as a "research artefact", but its
  content is flat arrays of animation floats: the hands' scene was 67.5 MB indented and 26.6 MB
  compact, and one character with 457 animations wrote 517 MB. Nothing is readable at that size, so
  the formatting bought nothing. Now compact, with an opt-in `readable` flag.
- **Bulk extraction is a scale problem, not a broken one.** "Extract all shown" from the default view
  is 2,000 assets ? measured at ~350 GB and many hours before the JSON fix, ~140 GB after. The
  browser lists characters first, and they are the most expensive assets in the game. While it runs
  `IsBusy` is true and both Extract buttons are bound to `IsEnabled="{Binding !IsBusy}"`, so they
  grey out and the whole thing reads as a dead button. `ExtractionUiTests` now drives the real
  command on the real view model, because the service tests could only ever prove the pipeline
  works, never that the button reaches it.
- **The hands use a `FacingShader`, not a `Shader`** ? no `Diffuse` at all; the base colour is in
  `FacingDiffuse` and `EdgeDiffuse`.
- **Every map embeds its own copy of what it uses.** The catalogue is five times larger than the set
  of distinct assets (71,106 rows for 14,378 things) unless collapsed.
- Names differ in case between the Havok tables and the Unreal objects (`R_Grip` / `R_grip`).
- Object names are not unique within a package; resolve by class as well.
- **A long animation is not just a longer short one.** Two spline-sampling faults were invisible on
  the hands, whose animations fit in a single block, and folded Ryan's chest into his legs on a
  2,613-frame speech. Test something with ten blocks in it.
- **Measure animation on the bones the mesh actually uses.** `Ryan` has 131 bones and 98 are skinned;
  `Dummy02` and `putterPLACEHOLDER` carry his golf club, move freely, and dominate every statistic
  taken over all bones. They are never drawn.
- **The window reads the catalogue while the catalogue is still being built.** `BuildAsync` runs on
  a background thread and used to clear and refill the very `List` the UI thread walks in `Search`,
  so typing in the search box during a build crashed the app with *Collection was modified;
  enumeration operation may not execute*. Every single-threaded test passed throughout, because
  nothing exercised the two together. The catalogue is now published as a finished array in one
  assignment and readers take a local snapshot; `_packageFiles` is a `ConcurrentDictionary` for the
  same reason. `CatalogConcurrencyTests` reproduces the original exception when the fix is reverted.
- **The browser's character/prop split was two magic numbers, and it hid whole assets.**
  `AnimationCount >= 20 && LargestMeshSize > 200_000` filed every security turret, the security bot,
  both security cameras and `Ryan` as props, because they have two to six animations each. A group is
  a character if its Havok packfile declares an `hkaRagdollInstance` ? the game's own statement that
  it expects the thing to go limp. That is a signal and is presented as one: breakable scenery
  carries a ragdoll too (a slot machine, a wall safe, a flower vase), so those appear as characters
  as well and the row says which test it fired on. `Ryan` carries no ragdoll and is kept by the old
  size bar, which is retained for exactly that reason.
- **A group holding several meshes is several characters, not one.** `AggressorBabyJane` owns
  thirteen ? the splicer variants, three corpses and Sander Cohen ? sharing one rig and nineteen
  animation sets. The catalogue emitted one row for the group and dumped all thirteen meshes into
  `SkeletalMeshes` **with no owner group**, so they were orphaned from their own animations. Each
  mesh is now its own row carrying the group. Anything that resolves an entry must key off what the
  row *is* (`ClassName`) rather than which bucket it is shown in, or a variant loads the largest
  mesh of the thirteen instead of its own.
- **An NPC's weapon is a different asset from the player's.** `WP_AI_Pistol` is a `StaticMesh`;
  `WP_Pistol` is the first-person viewmodel with its own rig. The viewmodel sweep only considers
  groups that carry a skeleton, so before this every splicer was offered the player's pistol and a
  first-person grenade launcher. See `docs/research/context.md`, attachment kind 4.
- **A check dismissed as a false positive needs the same evidence as a check acted on.**
  `docs/QUALITY.md` recorded `anim-character-stretched` on `PI_Fire`, `PI_Fire_B` and `PI_fire_C` as
  firing on correct data ? "a constant amount on every frame, which is authored translation", and
  "the animation was rendered and the splicer is intact". Both halves were wrong: the offset is not
  constant (25 bones on frame 0, 1?4 afterwards) and the splicer is not intact ? a user later
  photographed it with no arms. A dismissal is a claim, and this one went unchallenged for two
  sessions because it read as diligence. The entry is struck through where it was written.
- **Grey paint and a missing material are the same pixels.** A run whose material resolved to
  nothing draws flat grey, and so does a great deal of BioShock ? bare concrete, painted metal, the
  inside of a crate. No count distinguishes them and no render does either, which is how the grey
  security cameras survived: the tool had the evidence and the viewport could not express it. The
  "Highlight problems" overlay tints the unresolved runs magenta, and the valuable half is the
  *negative*: `Bomb`'s grey nose disc stays grey, which proves it is art rather than a fault.
- **A diagnostic panel that is empty must not look like a clean bill of health.** Both the report
  summary and the panel state coverage ? how many meshes, materials and textures were examined ?
  before saying what was found, because "no problems" and "nothing ran" are opposite conclusions that
  otherwise render identically.
- **An allowlist of names is not a decode, and it fails silently.** `MaterialReader` decided what
  counted as a texture binding from thirteen slot names taken off `Shader` and `FacingShader`. The
  game ships at least nine material classes and each names its slots differently ? `PlantShader` uses
  `AliveDiffuse`, `FluidShader` `WaterDiffuseMap`, `LightBeamShader` `FalloffMap` ? so 755 meshes
  reported a material that bound *nothing* and drew flat grey, with the texture named in the property
  list the whole time. Nothing failed; the material decoded, every count agreed, and the list was
  simply short. **The rule is now the relationship, not the name:** a binding is an `Object` property
  whose reference resolves to a `Texture`. The class check is what keeps that honest ? a `FluidShader`
  also carries seven object properties naming `TextureRotator`/`TexturePanner` UV modifiers, and
  "any object property" would bind all seven as textures.
- **Corroboration is not agreement ? check the layer you actually depend on.** Two reference
  projects both describe texture `Format` ordinal 12, agree on its name (3DC) and agree on its block
  size (16 bytes per 4x4). They disagree about what is *inside* the block, which is the only part
  that matters: Nyko's note says two BC4 blocks (BC5), UModel says an ordinary DXT5 block with the
  normal in alpha and green (DXT5N). Implementing the first produces a magenta image whose green
  channel averages 57 where a normal map's must average 128. **Agreement at one layer is not
  evidence at the layer below it**, and the only thing that settled it was decoding both ways and
  looking.
- **A `Texture` named in a material slot is a material, not a mistake.** It is the `BitmapMaterial`
  branch of the class tree and it draws as itself. 162 meshes do this.
- **A catalogue row's `Package` is not the only package the asset is in.** Every map embeds its own
  copy of what it uses, so a collapsed row carries them all in `Packages` and reports whichever one
  it was read from ? often a different map from the one you are looking at. Matching a diagnostic to
  a browser row on name *and* `Package` therefore failed on real data (`Cheese_Mould_Normal`, raised
  in `0-Lighthouse`, listed under another map) and the click silently did nothing. Use the
  catalogue's own `InPackage` rule. **Found by rendering the panel, not by a test** ? the numbers
  were all green.
- **Several sockets share one bone, so a socket must be chosen by NAME.** Nine of the first-person
  hands' sockets sit on `R_grip` ? `Pistol`, `Wrench`, `Crossbow`, `Chem`, `TommyGun`, `Launcher`,
  `IrritantBall`, `WrenchRibbonSocket`, `PlayerGathererGun`. The viewport picked the attachment's
  socket with `FirstOrDefault(s => s.Bone == socketBone)`, which always returns **`Wrench`**, and the
  wrench's socket carries a **180? turn about Z** where the pistol's and the chemical thrower's are
  identity. **Every first-person weapon in the game was therefore drawn backwards**, barrel pointing
  back over the forearm at the player, for as long as socket transforms have been applied.
  - **It was found by a user, not by the tool** ? the same way the grey security cameras and the
    armless splicer were. Nothing failed: every count agreed, the attachment resolved `Confirmed`,
    and the hands gripped the weapon.
  - **Two geometric metrics written to catch it both passed the broken pistol.** Extent along the
    arm's reach scored it +19 (the reach axis on this rig runs largely *up the spine*, so a barrel
    pointing back-and-up still scores positive); barrel-against-view scored it +0.24 (the direction
    from the eye to the weapon is not the direction the player looks). **A wrong lookup is caught by
    checking the lookup, not by measuring a direction** ? `FirstPersonWeaponOrientationTests`
    asserts the pistol's placement equals its bone frame exactly, and fails with the two matrices
    printed side by side if the rule reverts.
  - **The claim "every first-person weapon socket is identity" (?6.6b) was read too broadly.** It is
    true of the socket *origins*, and of the pistol's rotation. It was never true of the wrench's.
    Origin and rotation are separate fields and a note about one says nothing about the other.
  - The rule now lives in `PreviewModel.PlacementFor`, so the viewport and the tests cannot disagree.
- **Render everything.** Numeric validation has passed while the result was visibly wrong, more than
  once. Three features in the last session were implemented, tested, and invisible ? a column
  squeezed to zero width, an error message never displayed, and a zoom whose wheel event was eaten
  by a `ScrollViewer`. None were findable from the code.
- **A diffuse texture's alpha channel is not necessarily opacity** (23 Aug 2026). Many of this
  game's diffuse maps carry a gloss or specular mask in alpha, and a few diffuse slots resolve to a
  normal map or heightmap outright. The GL level shader does not blend at all ? it writes alpha
  `1.0` and its only transparency is a `discard` below 0.35 ? so reading alpha as opacity
  unconditionally made solid props vanish. Before touching transparency anywhere, read
  `docs/research/materials.md` "A diffuse's alpha channel is not necessarily opacity": the rule
  needs **two** signals (the material's declaration, or measured cutout holes) and the dangerous
  direction is forcing surfaces opaque, which would turn the game's gratings into solid rectangles.
  Note the software preview renderer still decides transparency from observed alpha alone and has
  **not** been changed to match.
- **A `MaterialSwitch` section's key named the switch; the material entry resolving it was keyed
  by its default child instead, and the manifest looked complete either way** (24 Aug 2026, level
  materials). `MaterialReader.Read` deliberately follows a switch to its authored default child and
  returns the *child's* class/name/export index ? correct for rendering, since the switch itself
  never draws. `LevelSceneExporter.WriteMaterials` resolved each section's material this way and
  then recomputed the written entry's key from the *resolved* material's own fields, so a section
  naming switch export 12791 got a `LevelDocument.Materials` entry keyed by its child's identity
  instead. Every other numeric check passed: materials non-empty (455 on `1-Medical`), 1,179
  texture bindings, 958 real PNGs on disk ? this is the same shape of failure as the coverage-bucket
  and grey-security-camera entries above, a manifest that looks complete while one specific lookup
  silently finds nothing. Caught by a test that resolves the connection itself ? every section's own
  `MaterialKey` against `LevelDocument.Materials`' keys ? rather than checking either side alone;
  2,673 of 2,674 sections on `1-Medical` passed even with the bug present, so a spot check would very
  likely have missed it. Fixed by keying each written `LevelMaterialDocument` off the
  `Level.SourceId` a section actually references, while still carrying the resolved child's real
  class/name/textures for rendering ? the two are allowed to describe different exports on purpose.
  `LevelSceneTests.MaterialsResolveAndTheirTexturesAreWrittenForAPlacedLevel` pins it.
- **`import_level.py` placed every instance mirrored in Y with an inverted rotation, and a quick
  look still showed a recognisable, right-sized level** (24 Aug 2026, found by the user exploring
  the imported `1-Medical` in the editor). `LevelSceneExporter` runs every instance transform and
  light location through `GameBasis.Convert` ? the reflection this project's whole pipeline applies
  because Blender/FBX/glTF are right-handed and BioShock's Vengeance engine (like Unreal itself) is
  left-handed. `import_level.py` fed those already-reflected numbers straight into
  `unreal.Vector`/`unreal.Quat` with no reversal, so every placed actor landed with Y negated
  relative to where Unreal's own left-handed +Y-right basis puts it, and every rotation extracted
  from the (still-reflected) matrix meant something different once run through UE5's own
  quaternion-to-rotator conversion. This is the same shape of trap as the two-year mirrored-asset
  landmine above, on a different consumer of the same reflection: scale was right, the level was
  still a recognisable hospital, and "confirmed by direct visual inspection" (this file, three
  entries up) had already been written against exactly this bug. **Caught only because a user
  actually explored the level**, not by any check this project runs. Fixed by reversing the same
  reflection ? it is an involution, so reversing it means negating Y and the quaternion's X/Z
  components again ? before every `set_actor_location`/`set_actor_rotation`/`spawn_actor_from_class`
  call. Verified in a live UE5.7 editor by replaying `LevelSceneTests`'
  `TheMedicalPavilionCeilingArchFormsOneContinuousSurface` check against the actually-placed actors'
  real world bounds rather than the raw decode: the four `window_512_corner_4up` instances' combined
  bounding diagonal came back **2422 units** ? the exact reference value that test already
  established for a correctly-assembled arch (a twisted, wrong-handed one measures ~4295) ? so this
  is a real run confirming the fix, not a repeat of the same static reasoning that produced it.
- **Every level asset imported into UE5 had no UV mapping and no more than one material slot, and
  neither gap was visible in a manifest or a report** (24 Aug 2026). `BuildAssetObj` wrote positions
  and faces only ? no `vt` line at all, and every face in one ungrouped run regardless of how many
  materials the mesh's sections named. A material could still be *assigned* to the mesh (the
  manifest's `materials`/`textures` arrays were genuinely populated, see the `MaterialSwitch` entry
  above), which is what made this easy to miss: assignment succeeding said nothing about whether the
  geometry could actually display it correctly. Fixed by writing one `vt` per vertex (same V-flip as
  the already-proven FBX rig path) and one `usemtl BioShock_{n}` group per section; `_assign_asset_material`
  now builds one material slot per section instead of skipping a mesh whose sections disagree.
  Verified live, not assumed: of 792 `1-Medical` assets needing more than one slot, a 20-asset sample
  all show the imported slot count matching the manifest's own section count exactly, confirming
  UE5's OBJ importer does split by `usemtl` group in file order ? the one empirical assumption this
  fix depended on and the only way to actually know before running it. This also surfaced a third
  headless-only crash, the same shape as the PNG/FBX ones: `Interchange.FeatureFlags.Import.OBJ`
  started asserting under `-unattended` only once the writer began emitting UV/group data ? a
  translator that had imported OBJs cleanly for a long time, so the natural first suspect was the
  new OBJ content itself rather than a known class of headless gap landing on a fourth translator.
  Found by grepping the engine source for `InterchangeOBJTranslator.cpp`'s own registered CVar name.
- **`import_level.py`'s own `unsupported` count was wrong the whole time it had been reported as a
  clean, honest number** (found 24 Aug 2026, pre-existing bug ? not introduced this session).
  `_import_instances` marked an actor "handled" using its geometry instance's own composite key
  (`"instance:<actorKey>:<asset>"`), never the bare actor key `_import_actors` checks against. So
  every actor that already got a real `StaticMeshActor` from `_import_instances` was *also* handed a
  second, overlapping `TargetPoint` placeholder by `_import_actors` afterwards, and counted as
  `unsupported` ? the exact opposite of what "unsupported" was meant to mean for that actor. On
  `1-Medical`: reported 7,337, true figure 2,018 ? 5,321 actors with working geometry were being
  double-counted as if they had none, and this had been true (and repeated as fact in this file and
  `docs/ROADMAP.md`) since `import_level.py` first landed, not something today's changes introduced.
  Every other report in this pipeline ? `created`/`updated`/`skipped`, the materials counters ? was
  unaffected; only this one field, and only because two independent dedup mechanisms used two
  different key shapes for the same actor. Fixed by having `_import_instances` also mark the bare
  actor key handled, but only once a real mesh actor is actually standing (not on a mesh-lookup or
  spawn failure), so that failure case still falls through to `_import_actors`'s placeholder rather
  than losing its representation entirely.
- **The local backup agent (`tools/backup-agent/`, aider driven by local Ollama models) can race a
  live session's own uncommitted edit to the same file and silently discard it** (25 Aug 2026). A
  Claude session hit its usage limit mid-edit to `ExportLevel` in `Program.cs`; the `SessionEnd`
  hook fired, `run.ps1` started autonomously, and by the time the session resumed and rebuilt, the
  file was back to the last *committed* state — the live edit gone, no error, no warning, exit code
  0 throughout. The `.run.lock` file only stops two `run.ps1` invocations from overlapping each
  other; it does nothing to stop the agent from touching a file a live, unrelated session is also
  mid-edit on. **Do not run `tools/backup-agent/run.ps1` (by hand or via the hook) while a session
  you care about has uncommitted changes anywhere in this repo** — commit or stash first. The
  `SessionEnd` hook is disabled as of this finding (removed from the "AI Test" project's
  `.claude/settings.local.json`, not this repo's own settings); re-enabling it should wait for a
  real fix — e.g. the wrapper checking `git status --short` is clean before starting a task, or the
  hook including some explicit "nothing else is using this repo right now" signal — not just the
  existing lock file, which was never designed to answer that question.

## 5. Validation

The `.blend` path:

```bash
blender --background <scene>.blend --python tools/blender/validate_scene.py -- <scene>.json
```

The FBX path ? imports the written files back and compares against transforms composed
independently from the game's own track data:

```bash
blender --background --python tools/blender/validate_fbx.py -- <scene>.json <fbx-dir> [rig]
```

Both exit non-zero on failure. Last run, on the first-person pistol set (hands 47 bones / 10
animations, pistol 8 bones / 2 animations), Blender 5.1.2:

| | worst rest error | worst posed position error |
|---|---|---|
| `.blend` | 0.000007 (`kBone_R_Thumb3`) | 0.000001 m (`EmptyFidgetPistol` frame 55) |
| FBX | ? | 0.001376 (`EquipPistol` frame 0, `Bip01_R_UpperArm`) |

Both `VALIDATION PASSED`; 0 mirrored bones skipped. **Re-run after the per-section material work and
both figures are unchanged to the digit**, which is what says that work did not touch the rig.

`validate_scene.py` also checks materials: slot count, slot order, and the slot every face is in
against the scene's own per-face assignment. A scene with no skeleton ? a `StaticMesh` prop ? skips
the rest and pose checks rather than failing on the armature it does not have.

The **first-person library**, built and validated in Blender 5.1.2 ? this is the Phase 1B target:

```bash
blender --background <library>.blend --python tools/blender/validate_scene.py -- <scene>.json validation.json
```

| | |
|---|---|
| Armatures | 7 ? the hands plus six weapon rigs, each on `R_grip` |
| Actions | **148** (130 hands across 9 animation sets, 18 weapon) |
| Event markers | **144**, across 74 actions, as Blender pose markers |
| Actions missing metadata | **0** ? every one carries its original name, fps, duration, set, skeleton and package |
| Sockets | 19, as `SOCKET_*` empties on their bones |
| Static props | 2 (`CS_butt`, `CS_photo`) |
| Materials / images | 9 / 26 |
| Worst rest error | 0.000007 (`kBone_R_Thumb3`) |
| Worst posed error | **0.000002 m** (`ZoomedInFidget_Crossbow` frame 29) ? over **all 130 animations**, not one set |

`VALIDATION PASSED`, and `validation.json` is written beside the library so a bulk export can be
checked without opening each file. Rendered and looked at: both hands sit on the pistol through
`ReloadPistolOne`, correctly textured.

Multi-material, run in Blender 5.1.2:

| | slots | faces | result |
|---|---|---|---|
| `bat_vehicle` `.blend` | 2 (`Bathysphere_mat`, `BathysphereLight_mat`) | 8,288 | `VALIDATION PASSED`, 2 slots used |
| `CityGate` `.blend` | 3 (`Granite_L`, `Gate_Light`, `C_Gate`) | 2,400 | `VALIDATION PASSED`, 3 slots used |
| `CityGate.fbx` ? Blender's FBX importer | 3, in scene order | 2,400 | **0 faces in the wrong slot** |

**The material check was proved able to fail**, not merely observed to pass: forcing every face into
slot 0 ? exactly what the tool did before this work ? makes it report `1,840 of 2,400 faces are in
the wrong slot`, first offender face 560, which is precisely where `Granite_L`'s 560-face run ends.

Poses are sampled at the keys' own frame positions. Blender lays FBX keys out at its rounded scene
rate, so an animation authored at 27.02 fps has keys on fractional frames; sampling at whole numbers
measures Blender's interpolation, not the file.

Pictures of the window and the viewport, rendered offscreen:

```bash
BIOSHOCK_UI_SNAPSHOT=/tmp/ui.png dotnet test --filter FullyQualifiedName~WindowTests
BIOSHOCK_RENDER_SNAPSHOT=/tmp/r.png dotnet test --filter FullyQualifiedName~RenderingTests
BIOSHOCK_CONTEXT_SNAPSHOT=/tmp/c.png dotnet test --filter FullyQualifiedName~ContextTests
BIOSHOCK_PROBLEMS_SNAPSHOT=/tmp/p.png dotnet test --filter FullyQualifiedName~DiagnosticsUiTests
BIOSHOCK_OVERLAY_SNAPSHOT=/tmp/o.png dotnet test --filter FullyQualifiedName~Overlay_Snapshot
BIOSHOCK_STATIC_SNAPSHOT=/tmp/s.png dotnet test --filter FullyQualifiedName~Static_Snapshot
BIOSHOCK_BOUNCER_SNAPSHOT=/tmp/b.png dotnet test --filter FullyQualifiedName~Bouncer_Snapshot
```

The last writes one image per static mesh (`/tmp/s_ConeDrill.png` and so on). The drill should be a
conical auger and the kerosene pickup a canister with a valve wheel and a cage; anything that is not
a recognisable object means the geometry chain landed somewhere plausible and wrong.

**Do not screen-capture the running application to check it.** The capture follows whatever is in
front on the desktop, not the window you meant ? this went wrong once and caught the user's browser.

## 6. Investigation record ? individually numbered, most already closed

**Despite the heading, this is not where current priorities live ? that's `docs/ROADMAP.md` Part 2.**
Kept as the detailed record of each investigation (most marked CLOSED/done/resolved below), the same
role `docs/research/*.md` and ?8b/?8c play ? not renamed outright because the `?6.0c` cross-references
scattered through this file and `docs/ROADMAP.md` would all break.

### 6.0 The former Phase 1 blocker ? SOLVED

**Full detail: `docs/research/FIRST_PERSON_ANIMATION.md`.**

A channel component a track omits is Havok's **identity**, not the bound bone's reference pose.
Found by reading `hkaSplineCompressedAnimation::recompose` in the Havok 2012.2.0-r1 SDK. The two
readings agree for every bone whose bind translation is axis-aligned along the omitted components ?
nearly every bone in the game ? and differ only on `Bip01_L/R_UpperArm`, the one bone in the
first-person arm chain whose bind translation is not.

| | before | after |
|---|---|---|
| `L_UpperArm` local | `(19.142, -25.116, -87.677)` len 93.19 | `(19.142, 0, 0)` len **19.14** |
| `R_UpperArm` local | `(19.142, 27.574, 85.631)` len 91.98 | `(19.142, 0, 0)` len **19.14** |
| Left hand on the wrong side | **3,384 / 5,984 frames** | **48 / 5,984** |
| Closest the left hand gets to the grip | 11.08 cm | **4.36 cm** |

Both hands now sit on the weapon; rendered and checked. The audit is unchanged on every headline
figure and its single-frame jump counts all went down. ?4 of the research note has the whole-game
blast radius.

### 6.0c The 54-track fire animations ? a FAMILY, not one anomaly. **Reopened with measurements.**

**This supersedes the "one animation of 16,031" framing below.** A user reported `PI_Fire_B` drawing a
splicer with no arms; measuring it, and then sweeping the game with the largest copy of each rig,
turns the single documented `smg_fire` anomaly into a small, coherent family:

| animation | tracks | collapsed bones, per frame |
|---|---|---|
| `PI_Fire` | 54 | **f0=25**, then 5, 3, 2, 3, 4, 12, 12 |
| `PI_Fire_B` | 54 | **f0=25**, then 4, 2, 1, 2, 3, 14, 14 |
| `PI_fire_C` | 54 | **f0=25**, drifting up to 23 by frame 20 |
| `smg_fire` | 54 | **f0=13**, then a steady 4 |
| `PI_AttackMelee_A` ? control | **73** | **0 on every one of 47 frames** |

"Collapsed" means a bone whose reference offset from its parent is =1 cm decodes to under 5% of that
length ? the arm folded into the torso, which is what the user photographed.

What the numbers say, and what they do not:

- **All four are on `AggressorBabyJane` and all four have 54 tracks against her 73 bones.** Every
  healthy animation measured has one track per bone. The 54 is the strongest signal available.
- **Frame 0 is by far the worst** ? 25 of 54 driven bones on all three `PI_` animations, and the
  count recovers immediately afterwards. Whatever is wrong is worst at the start of the clip, which
  argues against a purely per-track cause (a track missing a component would be equally wrong on
  every frame) and points at block or spline evaluation at *t = 0*.
- **The whole-game audit reports all of these as playable**, because it checks for NaN, zero-length
  and unbound tracks and *not* for a bone leaving its parent. That is a real gap in the audit: a
  collapse is exactly the kind of plausible-but-wrong result this project keeps being caught by.
  **Adding a bone-rigidity check to `AnimationAudit` is the first thing to do here.**
- Only **5 of 1,500** distinct animations collapse at all; the fifth is `CrackGlass_PreCrack`
  (12 tracks, 2 frames), which is a different shape and may be a different cause.

**Do not fix this by rescuing the four animations.** The previous wrong reading of the spline
decompressor survived three sessions because it was justified by a measurement that could not fail.

#### Four candidate causes, all now ELIMINATED with evidence

The Havok SDK's `hkaSplineCompressedAnimation.inl` was read for this. It did not settle it, and what
it ruled out is worth more than another guess:

1. **The static/spline/identity mask is misread ? NO.** Havok's `recompose` is
   `stat = mask & 0x0F` (low nibble static), `iden = ~mask & (~mask >> 4) & 0x0F` (identity only when
   *neither* static nor spline). `SplineDecompressor.ReadVectorChannel` implements exactly that,
   including reading a static float where a component is static and leaving spline components to the
   curve. The one nearby trap ? `unpackMaskAndQuantizationType`, which steals bits 1?2 of the packed
   byte for a quantization type ? applies to **float tracks only** and is never called for transform
   tracks, which use the 4-byte `TransformMask`. Our reader is right here.
2. **The binding maps tracks to the wrong bones ? NO.** `PI_Fire_B`'s binding holds 54 entries
   mapping to bones **3..56, all distinct** ? it simply does not drive `Bip01`, `Bip01_Pelvis`,
   `Bip01_Spine` or bones 57+. The healthy 73-track animations map identity. Track 0 correctly
   addresses `Bip01_Spine1`. The mapping is read and it is sane.
3. **The clips are additive over an aim pose ? NO**, despite looking exactly like it. The values have
   the right *shape* for a recoil delta (start ~0, rise, return: `Bip01_L_Forearm` runs
   0 ? 4.72 ? 0.90 on a bone whose bind is 25.05), and the Pistol set even contains `PI_aimposes`.
   But **`blendHint` is 0 on all 15,998 animations** ? re-censused properly, the original claim
   holds ? and applying `bind + delta` **does not restore rigidity**: worst drift stays 100% on
   `Bip01_Neck`. Additive is ruled out by measurement, not just by the flag.

4. **The clips are partition-limited partial-body animations ? NO.** This was the newest candidate
   and the only one the SDK suggested rather than the data: `hkaAnimationBinding` carries
   `m_partitionIndices`, "the partitions used to sample the animation", and `hkaSkeleton` carries
   `m_partitions`, a *named contiguous bone range*. The four clips drive bones 3..56 of 73 ?
   contiguous, ascending, a subset ? which is exactly the shape of a partial-body animation, and both
   fields had been documented in our own header comments and never read.

   **Measured, and it is dead.** On `AggressorBabyJane`: **457 bindings and not one carries a
   partition index**; the six skeletons in the wrapper ? three `Bip01` at 73 bones, three ragdolls at
   17 ? **declare no partitions at all**. There is nothing for a partial animation to be sampled
   against. Only 9 of the 457 bindings drive a subset of the skeleton at all, which does confirm how
   unusual the 54-track clips are, and says nothing about why they collapse.
   `SkeletonPartitionTests` pins both numbers so the elimination stays true.

#### What is actually known

The decoded values are **smooth, well-formed curves of plausible magnitude** ? they are not corrupt
bytes. They are the wrong *quantity* for the bone they land on. Something about what these tracks
mean, not how they are unpacked, is still missing.

#### Where to look next

- **`sampleTranslation` is not in this SDK build** and remains the single most likely place the
  answer lives.
- The block header: `getBlockAndTime` divides by `m_maxFramesPerBlock - 1`. Frame 0 is the worst
  frame in all four clips (25 of 54 bones, against 1?4 on later frames), which still points at
  evaluation at *t = 0* rather than at per-track semantics.
- ~~Check what our reader does at u = 0 against `evaluateSimple1/2/3` ? that is the one part of the
  .inl not yet compared line by line.~~ **Checked, 22 Aug 2026, and this lead is closed ? not a
  cause eliminated, but a place to look that turns out not to exist.**
  `hkaSplineCompressedAnimation.inl` is the *entire* file (256 lines, license footer after); grepping
  it and the whole SDK source tree for `evaluateSimple1` finds exactly two hits, both non-bodies: the
  declaration in the `.h` and the function-pointer table entry in the `.inl` that calls it
  (`{ HK_NULL, evaluateSimple1, evaluateSimple2, evaluateSimple3 }`). The actual degree-1/2/3 basis
  evaluation bodies are not in this SDK build at all ? same situation as `sampleTranslation`, not a
  separate, comparable lead. What *is* fully readable and was compared: `findSpan` (cited in the SDK's
  own comment as "Algorithm A2.1, The NURBS Book p68"), `getBlockAndTime`, `recompose`, and the
  mask/quantization unpacking. This project's own `NurbsBasis.FindSpan`/`BasisFunctions`
  (`NurbsCurve.cs`) already implements the general Cox-de Boor recursion for the same public,
  textbook algorithm (Piegl & Tiller, cited by name), already found and fixed one real off-by-one bug
  in `FindSpan` against real bytes (see that file's own doc comment), and is `t=0`-safe by inspection
  ? the `t <= _knots[Degree]` clamp returns span `Degree` at the lower domain bound, which is the
  textbook-correct span for a clamped knot vector. Havok's specialised fast paths and the general
  recursion are mathematically equivalent for a correctly implemented curve, so there is no further
  ground to gain here without either the missing `.cpp`/`.lib` bodies (disassembly, out of scope for
  this project) or a genuinely new lead. **Do not re-open this specific comparison** ? it has now been
  tried and the source needed for it does not exist in this SDK build, confirmed by grep, not by
  memory.
- `docs/research/QUALITY.md` note: the audit now *detects* this, so any change can be measured
  against `AnimationAudit.WorstCollapse` rather than by eye.
- **Disassembling the compiled Havok `.lib`/`.pdb` to recover `sampleTranslation` or
  `evaluateSimple1/2/3`'s actual bodies ? considered and explicitly declined, 22 Aug 2026.**
  Havok's own license (`hk2012_2_0_r1/Havok Limited Use License Agreement for PC XS 12-19-2011.txt`
  ?4.2) prohibits reverse engineering, disassembling or decompiling the product "even for purposes
  of interoperability or error correction." This is a hard line, not a project-scope choice ? **do
  not attempt this**, regardless of how the item is otherwise framed. The license's own ?4.2 names
  the legitimate alternative: a written request to Havok for interoperability information, which is
  a business decision for whoever holds the license, not something a coding session can do.
- **A fifth thing checked, same session, and still clean**: whether *this project's own* block/byte
  walk ? as opposed to Havok's algorithm ? loses alignment on the four fire clips specifically.
  `AnimationAuditRow.WorstBlockSlack` is `8`, `0`, `0`, `12` across `PI_Fire`/`PI_Fire_B`/`PI_fire_C`/
  `smg_fire` ? all comfortably inside the 0?15 byte range a correctly-aligned walk produces (a block
  pads to 16 bytes). This isn't a Havok-algorithm candidate like the four above; it rules out "our
  own reader loses its place reading these specific animations" as the explanation, which hadn't
  been checked from this specific angle before. The bug is confirmed to be in what the correctly-read
  values *mean*, not in whether they were read from the right bytes.
- **A workaround (clamping/rescuing the specific collapsing bones post-decode) was considered and
  rejected, same session.** This section's own text a few lines up already explains why: "inventing a
  rule to rescue one animation of 16,031 is how the original fault got in." A labelled workaround
  would repeat that shape of mistake with better documentation, not avoid it. Left as a real,
  understood, unfixed defect rather than a hidden one.
- **The same license boundary came up again, same session, in a different form**: the seven
  `hkpRagdollConstraintData::Atoms` classes (Gate 2 item 3's ragdoll joint limits) have no header
  anywhere in this SDK at all ? not even their field *declarations*, unlike every other Havok class
  this project has decoded. Recovering their layout would mean inferring Havok's own undisclosed
  struct design by experimenting on the bytes rather than checking a documented schema against real
  files, which is the same category of thing ?4.2 prohibits. Declined for the same reason as this
  section, considered explicitly (not just assumed) after a direct request to proceed anyway, on the
  reasoning that private/non-commercial use changes the license terms ? it doesn't; ?4.2 restricts
  the act, not what happens to the result afterward. See `docs/research/havok-physics.md`'s
  `hkpConstraintInstance` section for the full record.

---

**The original note, kept because its reasoning still applies to inventing a fix:**
`AggressorBabyJane`'s `smg/smg_fire` ?
54 tracks against her usual 73, 6 frames ? still collapses `Bip01_R_Forearm` and
`Bip01_R_ForeTwist`, whose tracks store Y and Z and omit X on a bone whose bind is `(25.05, 0, 0)`.
Havok would collapse them too. It is not additive: **every animation in the game carries
`blendHint` 0**, established by census. Nothing else in the game looks like it ? 0 of 15,998
animations omit translation on every track. Inventing a rule to rescue one animation of 16,031 is
how the original fault got in.

### 6.0b The left hand and the weapon ? resolved by the same fix

The left hand used to sit 25-70 cm from the weapon in every idle, fidget and fire animation. It now
reaches **4.36 cm** from the grip, and `FirstPersonHandTests.TheLeftHandReachesTheWeapon` holds it
there. The elimination list this section used to carry is superseded; the `IKbindLhandDummy`
reachability correction from the previous session stands and is recorded in `docs/QUALITY.md`.

### 6.1 Where a `StaticMesh` names its material ? CLOSED

**This section is superseded and kept only for the record.** A static mesh names its materials in a
real `Materials` tagged property, decoded in `docs/research/materials.md`; the count below belongs to
the state before that. **10,158 of 10,198 material slots now resolve**, and the sections choose
between them. What follows described the problem, not the current code.

Of 630 meshes that draw in `1-Medical`, only **22 resolve a diffuse texture**. The Bouncer's body is
textured; its drill, cage and backpack draw flat grey, and so does most of the world.

`MaterialReader.ReadMeshMaterialReferences` finds a mesh's material by searching for the tag block
`int32 4, int32 5, byte 1`. **A static mesh does not have that tag block** ? its equivalent is
`int32 4, int32 8, int32 1`, and no material reference follows it. Unlike a skeletal mesh, whose
property list is empty, a static mesh has a real one holding `Materials`, and that walk currently
ends `truncated`, on a numbered `None`.

`docs/research/materials.md` has the byte evidence, including a candidate reading of `ConeDrill`'s
`Materials` value that resolves to `ConeDrillRimShader`, a `FacingShader` ? right class, right name.
It is recorded as suggestive and **nothing has been changed on the strength of it**, because the
surrounding bytes are identical across three different meshes, which means the walk is misaligned
and that offset is probably an artefact.

**How to start:** hand-decode a static mesh's property list from offset 8 and find where alignment is
lost. It may be the same cause as ?6.5.

This also gates transparency: a mesh with no material has no texture, so it has no alpha either.

### 6.2 The skeletal geometry variant ? CLOSED, and it was not a variant

**The premise of this section was wrong and is corrected here.** It claimed ~60% of `SkeletalMesh`
exports yield no geometry and that a different vertex stride was waiting to be found. Both are
false as of the measurements below.

- **954 of 972 exports decode (98.1%).** The 60% figure predates the empty-skinned-block fix and
  should have been struck then; `TommyGunMESH`, `WP_GrenadeLauncherMesh` and `PlasmidEquipMESH` all
  decode and draw.
- **The remaining 18 carry no vertex data at all.** They are four door rigs ?
  `LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`, `GathererDoorAnimMesh`, `Atlas_labs_doorAnim` ?
  with 18 copies between them.

`CORROBORATED`, on three independent lines:

1. **The payloads separate cleanly with no overlap.** Every mesh that decodes is at least
   **2,443 bytes** (`ArcadiaGateMESH`); every one of these is at most **1,291**.
2. **Their groups have no drawable mesh of their own.** Each holds an `AnimationPackageWrapper` with
   open/close/stuck animations, socket names for door leaves (`Door`, `BigDoor`, `doorLargeRight`)
   and nothing else ? and `AtlasLabsDoorAnim` ships `Model` and `Polys`, which is **BSP**. The door
   leaf is level geometry, not a mesh asset.
3. **Other doors decode.** `PeepDoorMESH` and `Gate01Anim` are doors and both yield geometry, so
   this is not a format the door pipeline uses.

So there is no unread stride to hunt for, and the UI no longer says there is: it reports *"No vertex
data was found in this mesh"* rather than diagnosing an unsupported layout, because the evidence is
against that diagnosis. `SkeletalMeshGeometryTests.TheMeshesWithoutGeometryAreTooSmallToHoldAny`
pins the four names, the count and the separation, and fails if the two ever overlap.

**What would settle it outright:** byte-exact accounting of a `SkeletalMesh` payload, which this
project does not have ? the vertex chain is still located by search. That is the real remaining gap
in this container, and it is worth more than chasing a stride that is not there.

Note that the earlier claim that these failed geometry *and* materials "for one shared cause" was
**wrong**. The materials were the counted array; the geometry is unrelated.

### 6.3 Socket matching, kind three ? done

`BestGroupFor` now strips a trailing `Socket` before matching, so `ProtectorRosie`'s
`RivetGunSocket` reaches `WP_AI_RivetGun`; `SecurityBot` and the turrets are the same shape. The
hands' attachments are unaffected ? the pistol is still `Confirmed` by the root-bone test, which
outranks anything matched by name alone.

### 6.4 Verify the Unreal import

**Nothing has ever been imported into Unreal Engine 5.** `tools/ue5/import_bioshock.py` is written
from the documented API and has never been run; it says so at the top. Two things would be settled by
one import:

- whether Unreal takes the `SOCKET_*` null nodes as sockets or as **bones** (if the imported skeleton
  shows 66 bones instead of 47, that is it ? `FbxExportOptions.IncludeSocketNodes` turns them off);
- whether the notify API exists under the name that script uses.

Until then the UI deliberately offers no "UE5" export, because that would claim a verification that
does not exist.

### 6.5 `MaskMaterial` nested struct sizes ? CLOSED

**A struct property's declared size omits the size-encoding bytes of its own nested properties.** A
nested property with an explicit size costs 1, 2 or 4 bytes the declared size does not count, so the
outer walk advanced that many bytes too few and stopped inside the next property's name.

Census of every struct-valued property on every material in the game: of **14,610 `MaskMaterial`
structs, 9,152 declare their size exactly ? all of them having no nested property with an explicit
size ? and the other 5,458 are short by exactly their nested size bytes. No other cases.**

`UnrealPropertyReader` corrects a struct's length only when walking its nested list **lands exactly
on a terminator** at the corrected length, so a struct that is not a property list ? `Color` is a
plain four-byte BGRA value, and the game ships 6,329 ? is returned untouched.

**Every material in the game now decodes to its terminator: 13,545 materials, 0 partial**, where
`1-Medical` alone used to have 432 of 819 partial. 13,304 bind at least one texture.
`StructSizeTests` holds it, including a check that no reported property name or texture slot is
absent from the package's own name table ? a wrong correction resumes the walk mid-property and
produces plausible rubbish.

### 6.6 Attachment placement under animation ? half done, and the other half was stale

**The viewport already does this.** `MainViewModel.Preview.cs` builds a static prop's
`PreviewInstance` from `pose[socketBone]`, falling back to `RestGlobal` only when nothing is
playing, so the drill travels with the Bouncer. The claim that it used `RestGlobal` was out of date;
only the *tests* did, which is why nothing caught the discrepancy.

`AttachmentPlacementTests` now pins it two ways: the socket bone's posed position is more than
0.5 units from its rest position across a real animation ? so the two placements are genuinely
distinguishable ? and rendering the prop on each produces visibly different images. A regression to
`RestGlobal` makes the second test's two renders identical.

**Still to do: the FBX side.** `SceneAttachment` carries a *skeletal* attachment ? a whole scene
parented to a socket ? and a static prop is not exported as an attachment at all. Feeding it out as
a mesh parented to the socket bone, so the drill arrives on the Bouncer's back in Blender and
Unreal rather than at the origin, is the remaining work.

Placement itself is verified: on the hands, `CS_butt` lands at the left fingertips and `CS_photo` at
the right hand, with no offset beyond the socket bone's global transform.

### 6.6b Socket transforms ? CLOSED

**A socket carries its own transform relative to its bone, and ignoring it is why some props lined
up and others did not.**

`CONFIRMED_EXTERNAL` then `CONFIRMED_BYTES`. UModel's `USkeletalMesh` ? which carries its own
`#if BIOSHOCK` branch ? serialises sockets as *three* parallel arrays:

```cpp
Ar << AttachAliases << AttachBoneNames << AttachCoords;
struct FCoords { FVector Origin, XAxis, YAxis, ZAxis; };   // 48 bytes
```

The count is an **`FCompactIndex`**, not an `int32` ? reading it as an `int32` is what made both
earlier attempts land three bytes out and produce NaNs. With the right stride, **33 of 33 sockets
across three rigs decode to an exactly orthonormal frame**, which is the check that makes this a
decode rather than a fit: a wrong offset cannot produce a proper rotation 33 times.

Game-wide: **200 of 332 sockets carry a real offset and 246 carry a rotation.** The worst is 11 m.

Why it survived so long: **every first-person weapon socket has a zero origin.** The pistol, wrench,
Tommy gun and crossbow all placed correctly on the bone alone, and the note in this file generalised
from them to "no offset beyond the socket bone's global transform". That was true of the sockets
checked and false of 60% of the game's.

> **This table is about ORIGINS, and it was later misread as being about the whole transform.**
> A zero origin does not mean an identity socket: on `R_grip`, `Wrench` and `IrritantBall` carry a
> **180? rotation about Z**, `Launcher` 30.5?, `TommyGun` 20.5?, `PlayerGathererGun` 3? and
> `Crossbow` 1?, while `Pistol` and `Chem` are genuinely identity. Reading "the first-person sockets
> are identity" off this table is what let the viewport pick a socket by bone for months and draw
> every weapon in the game backwards ? see ?4. **Origin and rotation are separate fields.**

| socket | offset from its bone |
|---|---|
| `NEWPlayerHands/Pistol`, `Wrench`, `TommyGun`, `Crossbow`, `Launcher`, `Chem` | **0** |
| `NEWPlayerHands/WrenchRibbonSocket` | 36.4 cm |
| `NEWPlayerHands/FireballSocket` | 65.8 cm |
| `NEWPlayerHands/GathererAttach` | 84.8 cm |
| `ProtectorRosie/SteamLeakB` | 70.3 cm |
| `SecurityBot/Weapon` | 37.8 cm |

Converted once at the decode boundary by the same `C?M?C??` conjugation as every other transform.
Applied in the preview, the socket markers and attachment placement. `SocketTransformTests` holds
all of it, including that the weapon sockets stay identity ? so a regression to bone-only placement
fails rather than silently looking fine on the pistol again.

### 6.7 Smaller things

- **Bone picking.** `RenderOptions.SelectedBone` highlights a bone; nothing in the UI selects one,
  and bone names are not drawn.
- **Companion context.** The hands carry `Gatherer` notifies and sockets, but whether any object
  reference points at a Little Sister *asset* is still `UNKNOWN`.
- **The game camera.** `PlayerCameraAnim` (2 bones, 56 recoil animations) decodes, but its space is
  not related to the viewmodel's. The exported camera is a preview, explicitly not a reconstruction.

## 7. Working rules

These are the project's, and they are why its claims have held up.

1. **No hypothesis becomes a hardcoded parser.** A field that is not understood is named `Unknown*`
   and preserved.
2. **Every reverse-engineered structure gets a regression test that reads real game bytes.** There
   are no synthetic fixtures.
3. **A parse that looks right once is not a result.** The package layout is trusted because all 21
   shipped packages consume to the exact byte.
4. **Label confidence** ? `CONFIRMED_BYTES`, `CONFIRMED_EXTERNAL`, `CORROBORATED`, `LIKELY`,
   `HYPOTHESIS`, `UNKNOWN` ? and never present an inference as a fact. Every relationship the UI
   shows carries how it was established.
5. **Fail honestly.** A mesh in an unsupported variant says so in the user's terms; a bulk extraction
   records every failure and keeps going; a partial material is reported as partial.
6. **Correct the record when you are wrong.** Two claims in these notes have been overturned by
   later evidence ? `HkMeshProxy` being a material link, and the geometry/material failures sharing
   a cause. Both corrections are recorded where the wrong claim was.

## 7b. Where the project actually stands

`docs/QUALITY.md` is the sweep of every mesh, material, texture and animation the game ships, with
each headline figure pinned by `DocumentedFiguresTests` so a number that stops being true fails a
test instead of rotting silently in prose ? quote that file, not a copy here, for anything current.
It also records which of the audit's checks fired on correct data, so the next person does not chase
them.

## 8. Open unknowns

`docs/research/open-questions.md`, in priority order. The load-bearing ones: what Unreal does with
this export, the static mesh's trailing collision block, the skeletal geometry variant, the
per-material triangle sections a multi-material static mesh must have, the `MaskMaterial` size, the
texture mip array header field, the 16 unexplained bytes before the Havok magic in an
`AnimationPackageWrapper`, the two `Unknown32` fields in every export record, and whether any object
reference ? as opposed to a socket or notify ? points from a Big Daddy at a Little Sister asset.

## 8b. Decision log

**One authoritative basis conversion.** `C = diag(1,-1,1)` applied at four decode boundaries.
*Evidence:* static meshes, skeletal meshes, skeletons and animations were all mirrored; the game's
basis is left-handed and every consumer is right-handed. *Alternative:* per-asset or per-weapon
mirroring. *Rejected because* it creates inconsistent coordinate spaces and hides the root cause.
*Consequence:* every reader converts once, and nothing downstream may convert again.

**Winding is not reversed.** *Evidence:* the game is front-face clockwise (100% of triangles across
three meshes); a cross product transforms by `-C` while a normal transforms by `+C`, so the
reflection alone restores agreement. *Alternative:* reverse the index buffer too. *Rejected because*
it undoes exactly that and puts the geometry back the wrong way.

**Attachment animations pair on duration, not frame count.** *Evidence:* a weapon rig is authored
sparsely ? 0.70 s is 2 frames at 1.43 fps on one rig and 22 at 30 on the other. *Alternative:* exact
frame-count match. *Rejected because* it silently discarded the weapon's motion from the crossbow
reload, the launcher's `FireLast`/`Equip` and every zoomed fire. *Consequence:* one rule in
`Core/Animation/AnimationPairing.cs`, shared by the preview and the FBX manifest.

**A character is a group whose packfile declares a ragdoll.** *Evidence:* 207 of the game's 870
animation wrappers declare `hkaRagdollInstance`, and it separates actors from scenery better than
anything else the data offers. *Alternative:* the previous `AnimationCount >= 20 &&
LargestMeshSize > 200_000`. *Rejected because* it filed the turrets, the security bot, the security
cameras and `Ryan` as props. *Cost, accepted deliberately:* breakable scenery carries a ragdoll too,
so a slot machine and a flower vase are listed as characters; the row's detail says what it
qualified on rather than asserting the category as fact. *Consequence:* the old size bar is kept as
a second path, because `Ryan` has 131 bones and no ragdoll.

**A weapon the hands have animations for is offered even with no socket, at `Likely`.** *Evidence:*
the shotgun is one of the seven player weapons and was reachable by neither existing route ? the
hands declare no `Shotgun` socket (identical 19-socket table on all twenty shipped copies) and
`WP_Shotgun` is rooted at `SG_Body`, not `R_grip`, so the root-bone match that confirms every other
weapon cannot fire. What the game does state is that the hands carry their own `Shotgun` animation
set. *Alternative:* leave it unreachable, which is what six-of-seven meant in practice, or invent a
socket. *Rejected because* the first hides a shipped weapon the tool can otherwise handle, and the
second would fabricate data. *Cost, accepted deliberately:* the attach point is **inferred** from
where the rig's other weapon sockets sit, so the candidate is `Likely` and its evidence says which
half is stated and which is inferred ? it is never `Confirmed`. *Scope:* first-person hosts only, and
only where the host's own animation sets name the weapon, so it cannot hand an NPC a viewmodel.
*Verified by render:* the shotgun sits in both hands, right on the stock and left at the pump.

**An NPC is not offered the player's viewmodel on a name match.** *Evidence:* `WP_AI_*` static
meshes are the NPC-carried weapons and are a different asset from the `WP_*` viewmodel rigs.
*Alternative:* match any `WP_` group by name, which is what happened before. *Rejected because* it
put the player's pistol and first-person grenade launcher on every splicer. *Consequence:* a
viewmodel reaches a non-first-person host only on the stated relationship ? its skeleton rooted at
the host's socket bone ? never on a resemblance.

**`LockTranslation` is never applied.** *Evidence:* set on 66.6% of bones; 59,889 tracks drive a
translation on a bone carrying it, including the first-person root 89.8 cm from its reference pose.
*Rejected because* honouring it would pin every rig to its bind root. It is a `hkaSkeletonMapper`
retargeting hint, preserved and unused.

**An omitted channel component decodes to identity.** *Evidence:* Havok 2012.2.0-r1's own
`hkaSplineCompressedAnimation::recompose` fills a component that is neither static nor spline from an
"Identity values" vector. *Alternative:* the bound bone's reference pose, which is what this reader
did for three sessions. *Rejected because* it injects the authoring pose into every animated frame
wherever a bind translation is not axis-aligned, and the measurement recorded in its favour was
circular. *Refinement:* a channel that stores nothing at all still takes the reference pose, since
Havok never reads it. *Consequence:* the first-person arm roots come out symmetric at 19.14 cm
instead of 93 cm; 3.7% of the game's tracks move; the audit's headline figures do not.

**One resolver decides which triangles use which material.** `MeshSurfaceResolver` pairs section *N*
with `Materials[N]` and is called by the preview, the scene JSON, the FBX exporter and the Blender
importer. *Evidence:* the pairing rule is Nyko's, verified field by field on `ConeDrill` and
`Turret_Cover`, and corroborated by two independent readers ? the section table read backwards from
the geometry block, the `Materials` property read forwards from offset 8 ? agreeing on count for
**all 8,668 shipped static meshes with no exceptions**. *Alternative:* resolving materials next to
each consumer. *Rejected because* the viewport and the export would then be free to disagree about
what a mesh looks like, and the project has already paid for that once. *Consequence:* a mesh has
*surfaces*, not *a material*; `Primary()` exists for callers that genuinely need one name and is
documented as not being what the mesh is drawn with.

**A struct's length is corrected only when its own terminator proves it.** *Evidence:* the shortfall
equals the nested properties' size-encoding bytes on all 14,610 `MaskMaterial` structs in the game.
*Alternative:* apply that arithmetic to every struct. *Rejected because* not every struct is a
property list ? `Color` is four raw bytes ? and a rule applied where it does not hold would resume
the outer walk mid-property and invent properties, which is exactly the failure this replaced.
*Consequence:* the correction is self-validating; a struct that is not a property list cannot
satisfy it and is left alone.

**A prop is exported as an attachment, never merged into its host.** *Evidence:* the game positions
it on a socket; it is not skinned to the rig. *Alternative:* merge the drill into the Bouncer's mesh
so one object comes out. *Rejected because* it states a binding the data does not have and would let
the armature modifier deform a rigid prop. *Consequence:* a prop is a bone-parented mesh with no
armature modifier, and a weapon keeps its own rig ? a first-person animation is a two-rig
performance.

**An unresolved material slot draws untextured rather than inheriting.** *Evidence:* 40 slots across
the game resolve to nothing, and an import naming a material in another package cannot be followed
within one package. *Alternative:* fall back to the mesh's first resolved material. *Rejected
because* it would present a guess as a decode, and the grey run is the honest signal that the slot
is unread. *Consequence:* the preview says how many slots resolved nothing instead of the old
"only the first material is applied" warning, which is no longer true.

**A diagnostic carries its evidence, and the checks live in Core.** *Evidence:* every fault found in
the two sessions before Phase 1C was found by a human looking at the viewport ? grey security
cameras, an armless splicer, a misaligned prop ? and the tool held the measurement in all three
cases. *Alternative:* let the Problems panel work out what is wrong for itself, next to the window.
*Rejected because* the panel and the `diagnose` command would then be free to disagree about the
state of an asset, and neither could be tested without the other's host. *Consequence:*
`AssetDiagnostics` is one service the CLI, the panel and the per-asset view all call; a
`Diagnostic` carries `Summary` (the user's terms) and `Evidence` (the measurement) as separate
fields, and `ToReport()` is the copyable payload. A row with an empty evidence field fails
`DiagnosticsTests`. *Also rejected:* scoping a per-asset check by scanning its whole package and
filtering the result ? tidier, and it decodes every texture in the package on every click.
`AssetDiagnostics.ScanExport` is the shared per-export path, so the two scopes still cannot disagree.

**A hand's side is measured on the head bone's local +Z.** *Evidence:* on every shipped character
with a `Bip01_Head` and feet it is world left at dot 1.00 and equals that character's own clavicle
axis at dot 1.00, and it is a bone the arms do not drive. *Alternatives:* the body frame
(`up ? forward` with `forward = shoulders ? hands`), which judges the hands with an axis built from
the hands, and the arm-root axis (`L_UpperArm - R_UpperArm`), which took as its reference the very
bones that were misplaced and which on the first-person bind pose is the rig's *forward* direction.
*Rejected because* both read green on data that was not. *Consequence:* one metric in
`FirstPersonHandTests`, with guard tests pinning both discarded ones as invalid.

## 8c. Failed approaches ? do not repeat these

- **Reversing triangle winding after the reflection.** Wrong; the reflection already does it.
- **Hunting for a rig-level cause of the first-person hand swap.** There wasn't one. Three sessions
  eliminated the basis conversion, the binding, retargeting, additive blending, channel alignment,
  the socket, model-space composition, track transposition, per-bone negations, rotations at the
  chain root, the spine, hidden reflections, and a second copy of the bind pose in the
  `SkeletalMesh` ? all of it correct behaviour. The fault was one line in the spline decompressor.
  **When every internal check passes and the result is still wrong, go and read the format's own
  implementation.** The Havok SDK settled it in one function.
- **Any per-bone or per-chain transform to "fix" the arms.** Ten were scored against every
  constraint at once in an isolated worktree; all ten were inadmissible for the same reason ? each
  also moved a proven character, because an unconditional transform applies everywhere. That was the
  signal that the fault had to be a decode change which is a no-op wherever the decode was already
  right, and it was.
- **Converting the decoded animation a second time to fix the hand sides.** Flips the sides back and
  is wrong ? the animation's fallback channels already match the skeleton's bind translations
  exactly, so both are already in the same basis.
- **Treating `IKbindLhandDummy` as the left hand's IK goal.** It rides with the weapon and is
  authored per weapon class, but sits 93?108 cm from a 73.3 cm arm. Out of reach.
- **Using the right hand's position as evidence that the right arm is correct.** The weapon is
  parented under `Bip01_R_Hand`; it follows the right hand wherever it goes and always measures
  ~5.8 cm from it. It proves nothing.
- **Judging hand sides from a render.** The first-person rig's local axes are not world axes, so the
  preview camera's roll makes screen left/right meaningless. Use the body-frame measurement.
- **Fitting an axis-aligned rotation at the arm chain root.** Several improve the numbers; none is
  principled. The best is an arbitrary permutation.
- **Interpreting animation tracks as model-space.** Collapses bone lengths (29.98 cm to 13.32 cm).
- **Applying animations additively on the bind pose.** Fixes the first-person sides but changes
  every character animation too, and `blendHint` is 0 (NORMAL). No evidence for it.
- **Trusting the hand-side sign test alone.** At least three wrong changes satisfy it. Any
  candidate must also preserve bone rigidity, leave Rosie's magnitudes alone, and keep the
  fallback channels equal to the bind translations.
- **Two side metrics that read green on broken data.** The body frame (`up ? forward` with
  `forward = shoulders ? hands`) judges the hands with an axis built from the hands; it calls
  `ProtectorRosie` swapped on 2,415 of her 7,982 frames. The arm-root axis
  (`L_UpperArm - R_UpperArm`) takes as its reference the very bones that are misplaced, and on the
  first-person rig that axis is *forward*, not lateral ? the 51.89 cm "hand separation" it measures
  in the bind pose is front-to-back, and laterally the hands are 0.01 cm apart. **Use the head
  bone's local +Z**: world left at dot 1.00 on every character in the game, and equal to that
  character's own clavicle axis at dot 1.00. Both bad metrics are pinned by tests.
- **Applying the animation additively (`anim_local * bind_local`).** Re-tested properly and it is
  far worse than the old note implied: 44.8 cm of bone-length drift on `AggressorBabyJane` and
  437 of 592 of her frames broken, 71.97 cm drift on the first-person neck ? and it does not fix the
  first person either.

## 9. Reading order for a new session

0. **`CLAUDE.md`, then `docs/ENGINEERING_RULES.md`** ? how to work on this project: scope discipline,
   evidence standards, confidence labels, and the standing instructions the user has given (?60).
   The rules in ?7 below are the project's; those are the engineering ones, and neither supersedes
   the other.
1. This file.
2. `docs/research/ANIMATION_COORDINATE_SYSTEM.md` ? the basis policy. Nothing else makes sense
   without it, and every transform in the codebase depends on it.
3. `docs/research/README.md` ? the index and the confidence labels.
4. `docs/QUALITY.md` ? what is measurably still wrong, and what only looks wrong.
5. `docs/GUI.md` ? if touching the application.
6. The research note for whatever you are about to work on: `skeletalmesh.md`, `staticmesh.md`,
   `materials.md`, `fbx.md`, `context.md`, `binding.md`, `havok-compression.md`.

---

## Session log archive

The dated 16–29 Aug 2026 session-by-session journal that used to run to the end of this file
(starting "# NEXT CLAUDE SESSION") is archived at
[`docs/archive/HANDOFF_SESSION_LOG_16-29AUG2026.md`](archive/HANDOFF_SESSION_LOG_16-29AUG2026.md),
moved there 4 Sept 2026. It added nothing `docs/ROADMAP.md` Part 1 (done) and Part 2 (gates) don't
now state more currently — this file's own §7b already said as much for the status half; the
journal was the same drift one layer further in. Every genuinely load-bearing fact it contained
(landmines, decisions, byte-level findings) was cross-checked and is already recorded in §4
Landmines, §6 Investigation record, §8b Decision log above, or in the relevant `docs/research/*.md`
file. Read the archive only for the narrative of how a specific fix was found, not for current
status.
