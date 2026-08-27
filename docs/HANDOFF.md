# Handoff

> **Read this first.** It is the project's institutional memory. If a discovery exists only in a
> chat, it does not exist.

## Active work ? check and update this before touching a shared file

Two AI agents (this session's assistant and a separate ChatGPT session) work in this repository
concurrently, on one branch, with no other coordination mechanism between them. This table is it.
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
| *(none)* | Active claims empty. Add a row before starting work. | — | — |

**Recently released:** Phase 4 through 27 Aug 2026 including runner PlayEffect/StopEffect by label
(`run_script_fx.py`).

**Recently released (do not re-claim as live):** Cursor Phase 4 through 27 Aug 2026 — nested
If/Loop/For import, ActionBool testsOr stubs, ActionPropertyTest, ActionDisplayMapHUDRegion,
ActionFor counter iterations (`run_script_for.py`). Older Aug 23–25 rows cleared on consolidation.

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

# NEXT CLAUDE SESSION

**Phase 1 has no correctness blocker.** The first-person hand blocker is fixed, the audit is clean,
both Blender validators pass, and the suite is green with nothing skipped. What is left is quality.

**Phase 1C's diagnostics now say what that quality is, in numbers** ? 1,371 diagnostics over 54,335
assets, and two of the counts agree exactly with results other tests already pin, which is what says
the sweep is measuring the same game. Start from the three leads under item 5 rather than from a
fresh survey: the survey has been run.

1. Read this file, then `docs/research/ANIMATION_COORDINATE_SYSTEM.md`.
2. `dotnet test --filter Tier=Fast` while working; the whole suite before finishing. For the
   expected count see the state table at the top of this file ? it is stated there and nowhere else.
3. **The section table is now consumed** ? that was the previous session's item 3 and it is done.
   `MeshSurfaceResolver` pairs section *N* with `Materials[N]` and is shared by the preview, scene
   JSON, FBX and Blender. Sections and material slots agree on **8,668 of 8,668** shipped static
   meshes. Verified by render as well as by count. Do not reopen it without evidence.
4. **The Blender and FBX multi-material paths are verified.** `validate_scene.py` now checks slot
   count, slot order and the per-face assignment, and skips the rest/pose checks for a scene with no
   skeleton instead of failing on the missing armature. Both paths were run for real in Blender
   5.1.2 ? see the table in ?5. Do not reopen without evidence.
5. **?6.5 is closed** ? every material in the game decodes, 0 partial. **?6.2 is closed** and its
   premise was wrong: there is no unread vertex stride, the 18 are door rigs with no geometry.
   **?6.6 is done** on both sides ? the viewport already posed props, and static props and weapon
   rigs now both reach the export.

   **Phase 1B is functionally complete.** The library works end to end (?5), builds for the hardest
   character in the game (`AggressorBabyJane`, 488 actions, 3m28s, 189 MB), organises itself into
   outliner collections, tags every Action with its weapon, and ships a browser add-on
   (`tools/blender/bioshock_animation_browser.py`).

   **Phase 1C's first three items are done.** The diagnostics service, the panel and the health
   report all exist and are the same code:

   - `src/BioShockStudio.Core/Diagnostics/AssetDiagnostics.cs` ? the checks, with coverage counts so
     an empty report cannot be mistaken for a clean game. `DiagnosticsService` scopes them to one
     asset, one package or the install.
   - The **Problems panel** in the application: check a package or everything, worst first,
     click-to-navigate, Copy diagnostic / Copy all. The selected asset's own problems appear in the
     details panel beside it.
   - The **health report** is `diagnose`, which is the same service summarised, with `--code` to list
     every instance of one finding and `--out` for a CSV.

   Tests: `DiagnosticsTests` (checks fire, and are silent on assets other tests prove correct),
   `DiagnosticsUiTests` (the buttons reach the checks, and the window renders with the panel).

   **The sweep's largest finding has been acted on.** It said 755 meshes resolved a material that
   binds no base colour, mostly material classes the reader did not know. **Reading one file settled
   it** ? `Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Materials_And_Shaders.md`,
   which states that every material class is a plain tagged-property object and that texture
   references are ordinary objrefs. The reader was deciding what counted as a binding from a list of
   thirteen slot names. Now: **an `Object` property whose reference resolves to a `Texture`**, plus
   a `Texture` named in a material slot being a material in its own right. **755 ? 240**, and
   96.4% of the game's meshes carry a base colour. Rendered and checked. `docs/research/materials.md`,
   open question 11b.

   **Texture `Format` ordinal 12 is also done** ? it was second on this list and it is **DXT5N**,
   not the 3DC/BC5 that Nyko's texture note calls it. UModel's BioShock branch remaps it and says so
   in a comment; the pixels agree, decisively (X and Y both centre on 128 and **0 of 4,096 texels**
   violate `x? + y? = 1`, where the BC5 reading puts green at 57 and renders magenta). **274 exports,
   all normal maps, now decode**, and `texture-undecodable` fell 320 ? 46.

   **What is left, in priority order** ? `docs/QUALITY.md` ?"Whole-game diagnostic sweep":

   1. **The `SkeletalMesh` section table** ? item 6 below. 153 meshes, and it needs a forward walk of
      the payload. Biggest piece of work left in Phase 1.
   2. **`MaterialSwitch` (38) and `MaterialSequence` (4) are Modifiers**, and nothing follows them.
      The note says a reader should "follow it to the wrapped child material(s)"; the child property
      names have not been read off a shipped object yet. Small, and the clearest quick win.
   3. **`FluidShader` (83)** ? 63 bind textures but no `WaterDiffuseMap`. One look at what such a
      material declares would say whether that is a gap or the truth.
   4. **46 texture exports carry no `Format` property**, and all 42 distinct names are editor sprites
      or engine placeholders. One hand-decode says whether they hold pixels at all.
   5. **?6.0c: the partition lead was measured and is dead.** `hkaAnimationBinding.m_partitionIndices`
      and `hkaSkeleton.m_partitions` are now read. On `AggressorBabyJane`, **457 bindings carry zero
      partition indices and all six skeletons declare zero partitions**, so the partial-body reading
      is eliminated ? a fourth cause struck off ?6.0c with evidence rather than argument. What
      remains there is unchanged: spline evaluation at *t = 0*, compared against `evaluateSimple1/2/3`.

   **`LightBeamShader` (64) is not on this list on purpose.** It binds `FalloffMap` and `DustMap` and
   takes its colour from `BeamColor`; it has no base colour and reporting one would be an invention.

   **The first viewport overlay is done too.** "Highlight problems" tints the triangles whose
   material resolved to nothing, per-*surface* rather than per-mesh ? on `Bomb`, two of seven runs go
   magenta and the other five keep their texture. It closes the loop the panel opens: the panel says
   which assets are affected, the overlay says which *part* of the one on screen.

   Its most useful behaviour is the negative one. `Bomb`'s nose carries a plain grey disc that looks
   exactly like an untextured surface, and with the overlay on it stays grey ? so that disc is real
   art and the fault is elsewhere. **A diagnostic that can only say "something is wrong" is worth much
   less than one that can also say "not this".** `ProblemOverlayTests` asserts both directions,
   including that a mesh whose materials all resolve renders byte-identical with the overlay on.

   **The relationship tree is navigable ? done, and now verified by the full suite.** The details
   panel already listed what an asset relates to and gave no way to go there. Every related asset is
   now a button that opens it. The rule that turns a name into a browsable row moved out of the view
   model into `AssetCatalogService.Resolve`, because it had already been duplicated once ? the
   Problems panel and the relationship tree now share one implementation, so a click means the same
   thing wherever it comes from.

   **The Asset Inspector is done, and with it Phase 1C.** Every asset kind now states what it is
   (name, kind, Unreal class, export object, group, owning rig) and where it lives (package read
   from, **every other package carrying it**, export index, payload). Both are built from the
   catalogue row in one place in `AssetDetailsService`, so no kind can be missed and an asset that
   fails to decode still says what and where it is instead of showing only an error. `Also in` is the
   field that earns its place: `NEWPlayerHands` reports `5-Ryan` and is in twenty packages, and
   treating a reported package as the only one has already made a click do nothing.
   `AssetInspectorTests`; rendered and looked at.

   ~~**State this was left in:** the full suite has not been run since the navigation change.~~
   **It has now.** The full suite was run on 16 Aug 2026 and is green ? see the state table at the
   top. All of the work above is committed, in fourteen commits, each of which builds on its own.

   The Asset Inspector is still to do, and is easier now, because it wants the evidence the
   diagnostics service already produces.

   Remaining Phase 1B polish, none of it blocking:

   - **The add-on has never been driven by hand in the Blender UI.** Its filtering is exercised
     headlessly (`Pistol` ? 10 actions, `Pistol` + `reload` ? 1) but no one has clicked PLAY.
   - **The scene JSON is still large** ? the hands' library is 31 MB, `AggressorBabyJane` 206 MB.
     See the bulk-extraction note below; the user deferred it deliberately.
   - **A library is one mesh per rig.** `AggressorBabyJane` owns thirteen meshes sharing one
     skeleton and the library takes the largest (`Agg_Doctor_Mesh`). The other twelve variants are
     not in the `.blend`, which is existing catalogue behaviour rather than a new fault, but a
     "library" arguably ought to carry them all as alternatives.

   Then:
   ?6.2 (skeletal geometry variant ? read `UModel-master/Unreal/` first), ?6.4 (verify the Unreal
   import, never once run ? and it now also has `ByPolygon` material mapping to confirm), ?6.6
   (attachment placement under animation).
6. **Skeletal meshes DO have a section table, and this item's `UNKNOWN` is closed.** It was worth
   looking for in `UModel-master/Unreal/` exactly as this item said, and it is there:
   `UnMeshBioshock.cpp`'s `FStaticLODModelBio` opens with `TArray<FSkelMeshSection> Sections`, nine
   `uint16`s each ? `MaterialIndex, MinStreamIndex, MinWedgeIndex, MaxWedgeIndex, NumStreamIndices,
   BoneIndex, fE, FirstFace, NumFaces` ? commented "1 section = 1 material". That is the **153**
   meshes `diagnose` reports as `mesh-materials-without-sections`, `TommyGunMESH` and
   `PlasmidEquipMESH` among them.

   **Not implemented, deliberately.** It needs the payload walked from the front instead of the
   vertex chain being searched for, and UModel targets the *original* game ? the Remastered static
   vertex is already 48 bytes against 24, so every field needs checking against shipped bytes. The
   same source gives the full payload order and shows that the "tag block" this project searches for
   (`04 00 00 00 05 00 00 00`) is a **versioned object header** whose subversion selects the layout,
   which is the precondition for walking it. `docs/research/skeletalmesh.md`, open question 11d,
   `docs/research/reference-comparison.md` ?3??4. **This is the biggest single piece of work left in
   Phase 1.**

## Session of 17 Aug 2026 ? the viewport session

Everything below in "Phase 2" still holds. This is what changed after it, and the through-line is
worth stating once: **six faults shipped in this session and a user found five of them by looking at
the screen.** Every one passed the whole suite. They are listed here because the *pattern* is the
finding, not the individual bugs.

| what shipped broken | what the tests could see |
|---|---|
| Every BSP surface tiled its texture hundreds of times | Counts, coverage and a textured-vs-untextured check all passed ? a wrong UV **scale** is still a texture on every pixel |
| Then tiled **8?** too often, because the fix divided by the loaded 256 mip rather than the authored 2048 size | The test averaged over 2M static-mesh vertices that never take that path, and reported an unchanged median |
| Rooms missing ? only source brushes and props were drawn | A scene with no compiled world is still a complete, self-consistent scene |
| Blood splatters, grime and posters as opaque rectangles | The GL shader ignored alpha; geometry and textures were both correct |
| Light shafts as flat white sheets across the view | They bind no base colour **by design** ? nothing was failing |
| Level textures soft | The 256 cap was correct for the CPU renderer it was chosen for, and never revisited |

**The lesson to carry forward: a numeric check cannot see a wrong quantity that is still present.**
Where a value has a magnitude, measure the magnitude ? `BspUvTests` measures UV size directly, and
that is the test that would have caught two of these.

### What was built

- **The compiled world** (`BspWorldReader`) ? the level's actual architecture. 81,566 polygons /
  227,911 triangles across 21 maps, **12 polygons off-plane (0.015%)**, and the figures match Nyko's
  independent measurement exactly. `docs/research/bsp.md` ?5.
- **A walkable, textured level viewport** with a ghost camera, on the **GPU** (`LevelGlViewport`,
  Avalonia `OpenGlControlBase`, no new dependency) with the software rasteriser as a tested fallback.
- **Lights applied** ? 465 decoded, 298 usable on Lighthouse. Off by default: this is *not* the
  game's lighting model, which is baked into lightmaps this project does not read.
- **Filters**, all off by default: zones & triggers, source brushes, unpainted surfaces.
- **The `SkeletalMesh` section table** ? 331 of 944 meshes, 61 multi-material. `skeletalmesh.md`.
- **Three GUI tabs** ? Animated / Static / Level.

### Two limitations found late and left open

- **`AggressorBabyJane` previews `CorpseMale`.** Not a selection bug: the package that row resolves
  to contains **exactly one** mesh in that group. Every map embeds only what it uses, so a group row
  is only as complete as the map it is read from. The choice among a group's meshes and the choice
  of package are both improved, and neither can help here. `PreviewIdentityTests`.
- **25 rows preview a mesh with a different name** ? `Int_Seagrass` ? `IntSeagrass_Mesh`,
  `FlowerVase` ? `flower_vase_mesh`. All checked; all the game's own naming. No rule distinguishes
  them from a real fault by name alone, so the sweep asserts a ceiling rather than zero.

## Session of 17 Aug 2026 (audit) ? two P0 unknowns closed, and the first timings

Ran as a full repository audit against a master engineering prompt. Three things changed and one
thing was measured for the first time.

### The four "section overruns" were a misread field, not missing data

`skeletalmesh.md` recorded four meshes whose sections reached past the index buffer by 2, 5, 5 and 8
faces, and suspected the buffer ? "this project locates the index buffer by *search*, which makes it
the more likely candidate". **Refuted.** Over all 337 shipped section tables:

| claim | agrees | disagrees |
|---|---|---|
| the sections' `NumFaces` add up to exactly the buffer's faces | **337** | **0** |
| `MinStreamIndex` is the running index total | 336 | 1 |
| `FirstFace` is the running face total | 333 | **4** |

A buffer short by 8 faces could not have its sections sum to its length. **The sections tile the
buffer; `FirstFace` is simply not where a section starts.** `MinStreamIndex` says the same
independently, and its one exception is a `uint16` wrap: `CoreTop_Mesh` stores 10,244 where the
running total is 75,780, and 75,780 - 65,536 = 10,244. **The clamp is gone**; a section is placed at
the running total, which cannot overrun by construction, and the reader asserts the sum identity
instead. What `FirstFace` means on those four is `UNKNOWN` and it is preserved.

### The twelve off-plane world polygons are snapped corners

Every one has a vertex **exactly** on its plane and the rest off it by the plane's off-axis slope
times the distance travelled ? `7-Gauntlet` node 755 is 0.0822 ? 44 = 3.60 cm against a measured
3.603, and the off-plane corners are the round coordinates while the exact ones are fractional. The
editor's grid snap, in shipped data. Not precision, not the basis conversion, not the decode ? the
same arrays produce 81,554 exact polygons. `bsp.md` ?5.6b, and the test asserts the discriminator:
snapping moves corners, a decode fault moves whole polygons.

### The first performance numbers this project has ever had

`PerformanceBaselineTests`, medians after a warm-up:

| operation | median |
|---|---|
| open `1-Medical.bsm` (204 MB) | **46.2 ms** |
| open `0-Lighthouse.bsm` (187 MB) | 21.6 ms |
| read one texture payload | **0.001 ms** |
| read one large mesh payload | 0.048 ms |
| decode that mesh's geometry | 17.3 ms |
| `LevelAnalyzer.Analyze` | 107.6 ms |

**Opening a package parses its whole name, import and export table.** Every service opened one for
itself ? `TexturePreviewService.Describe` then `Decode` is two opens for one selection, so a texture
click paid ~92 ms of table parsing to do 0.002 ms of reading.

### `PackageCache` ? fixed, and the measurement chose the design

Four opened packages, least-recently-used. **45.46 ms uncached against 0.0004 ms from the cache**,
asserted as a ratio so it means the same on a slower machine. Wired into texture preview, asset
details and diagnostics; the other ~40 call sites are one-shot and still open their own.

Two things had to be true first, and both are now tested:

- **A shared package must tolerate concurrent readers.** `ReadExportData` seeked a reader the
  instance owns. It now takes a lock ? **and a positionless `RandomAccess` read was tried first**,
  which needs no lock but bypasses the stream's 64 KB buffer. This is called once per export,
  thousands of times in a row, by anything that walks a package: `LevelAnalyzer.Analyze` went
  **107.6 ms ? 217.7 ms** that way, and **97.8 ms** with the lock. The faster-looking design was the
  slower one, and only measuring it said so.
- **Eviction must not close a package somebody is holding.** The details panel holds a lease across
  a long operation, so evicting four packages under it would turn a slowdown into a crash. Entries
  are reference-counted: eviction removes the entry, the file closes when the last lease returns.
  `AnEvictedPackageStaysReadableWhileItIsStillLeased`.

### The "stuck on the first mesh" bug ? a real race, found by reading the code

A user reported the preview viewport freezing on the first asset selected and never updating again
on later clicks, and separately that some assets (`ArcadiaGateMESH`, a Props-category entry) showed
nothing at all. The second report never reproduced ? `AssetCatalogService` (2,362 static meshes, 117
props), `MeshPreviewService.Load` (80/80 Props entries, geometry, zero exceptions) and
`AssetDetailsService.Describe` (80/80, including 40-way concurrent access through the new
`PackageCache`) all check out clean, including for the exact reported entry. Ruled out along the way:
only one `AssetBrowserView`/`DataGrid` exists at a time ? Avalonia's `TabControl` recreates tab
content rather than keeping both alive, so there is no cross-tab `SelectedAsset` binding conflict.

**The first report was real, and did not need live reproduction to find** ? reading
`RenderAsync` found a genuine dropped-work race:

```csharp
var model = _previewModel;           // captured ONCE, before the loop
do {
    var image = await Task.Run(() => SoftwareRenderer.Render(...));   // a selection can land here
    if (!ReferenceEquals(model, _previewModel)) return;               // <-- bug: bypasses the queue check
    Viewport = ToBitmap(image);
} while (_renderQueued);
```

If a new selection lands while a render is in flight, `LoadPreviewAsync` finds `_rendering` already
`true` and ? by design ? only sets `_renderQueued = true`, trusting this loop to notice. The `return`
on model mismatch discards the stale image correctly, but **also exits before the
`while (_renderQueued)` check**, so the newer request it just set is never looked at. `_rendering`
resets to `false` in `finally`, and nothing else is scheduled to fire again ? the viewport freezes on
whatever rendered first, until some unrelated event (a checkbox, a resize) happens to call
`RequestRender()` again.

**Fixed by re-reading `_previewModel` at the top of each loop iteration and turning the mismatch
branch into a retry** (`_renderQueued = true; continue;`) instead of a `return`. Not verified by a
live reproduction ? the race is timing-dependent and forcing it deterministically in a test would
need test-only hooks in production code, which was judged not worth adding for this. The fix is
confirmed by tracing the control flow, which is what found the bug in the first place.

**`DiagnosticLog`, added alongside this.** The app had no diagnostic trail at all ? `Program.cs`
called `.LogToTrace()`, invisible to anyone who launches the exe by double-click, and there was no
handler for an exception escaping every existing try/catch. `%LocalAppData%\BioShockStudio\log.txt`,
reset each launch, now records every selection, every `ShowDetailsAsync`/`LoadPreviewAsync` outcome,
every caught exception with its full inner-exception chain, and any exception that would otherwise
have vanished (`AppDomain.UnhandledException`, `TaskScheduler.UnobservedTaskException`). If the Props
report recurs, this is what will show why without needing a terminal.

### The DataGrid selection quirk ? found from a real log, worked around, not root-caused

The "nothing shows when I click an asset" report was real and, with the diagnostic log added
alongside it, reproducible in the wild every single time: **every click logged `SelectedAsset ->
theRow` immediately followed, 5-15 ms later, by `SelectedAsset -> null`**, with nothing else in the
view model firing in between ? every filter, category and tab-index change is logged too, and none
of them appeared. `ShowDetailsAsync`/`LoadPreviewAsync` load, then get cancelled by the null before
they can populate anything. Occasionally a third event re-selected the same row and it worked; most
of the time it didn't.

**Not root-caused.** This points at Avalonia's `DataGrid.SelectedItem` binding rather than anything
in this project ? a web search turned up several related open issues
([#16591](https://github.com/AvaloniaUI/Avalonia/issues/16591),
[discussion #9834](https://github.com/AvaloniaUI/Avalonia/discussions/9834)) but none matches this
exact shape closely enough to call it confirmed. `Avalonia.Controls.DataGrid` 11.2.3.

**Worked around in `MainViewModel`, not the XAML.** A null selection is no longer acted on
immediately. It waits one 100 ms tick; if the row that was actually clicked is still sitting in the
current `Assets` list when the tick elapses, the null is treated as the quirk and the selection is
re-asserted rather than cleared. If the row is gone (a real navigation happened) or a different
selection has since superseded it, the null is honoured normally. Capped at three consecutive
reassertions per row so a genuinely, persistently rejected selection cannot be fought forever.

**This is a workaround, stated as one.** The underlying DataGrid behaviour is still not understood ?
"unknown is a valid answer" applies to the framework's internals same as to this project's own
formats. If it recurs in a shape the cap doesn't cover, the diagnostic log will show it.

### 22 Aug 2026 ? SOLVED: the actor roll sign was wrong, settled against the game's own BSP tree

**Superseding the "OPEN" record below, which is kept because its dead ends are worth not repeating.**
A user photographed a `1-Medical` skylight rotated wrongly with correctly-rotated neighbours, after
the actor-transform work had been called done. **`UnrealRotator.ToQuaternion` now negates roll as
well as pitch**, and the evidence is a ground truth no reference implementation is involved in.

**The decisive measurement: the game's own BSP tree.** The compiled world is a spatial partition
shipped in the package; it can classify any point as inside architecture or in open space. A prop
stands in a room ? not inside the masonry ? so the share of a rotated actor's geometry landing in a
*solid* leaf is a cost the correct composition minimises. Across **six maps and 147,466 sampled
points**, on actors carrying a non-zero roll:

| composition | geometry buried in solid |
|---|---|
| `Rx(+roll)` ? as shipped, and as the reference builds it | **25.85%** |
| **`Rx(-roll)`** | **15.38%** |
| pre-fix `+pitch` | 26.49% |
| negated yaw | 27.30% |
| reversed order | 26.58% |
| reversed with negated roll | 25.89% |

**Every alternative clusters at 25.8?27.3%; only the negated roll separates, by 40%.** That spread is
what makes this a measurement rather than a preference.

**The classifier behind it is validated, not assumed.** Which leaf side is open space could have been
stated from memory of Unreal's convention ? exactly the inherited claim this project keeps being
caught by. Instead it was established from the shipped AI navigation graph: **7,207 of 7,378
`PathNode`/`PatrolPoint` positions across 18 maps (97.7%) fall in a front leaf**, so front is open.
`BspSolidityTests` asserts both that split and the scoring.

**Rendering agrees.** The four `window_128_corner` pieces of the reported skylight were placed under
all six candidates and drawn: only the negated roll assembles them into a continuous barrel vault.

**And the user confirmed it in the viewport ? which is the evidence that actually closes this.**
The same person who reported the fault walked back to it in the rebuilt app and reported the
skylight fully fixed. Every measurement above is a proxy for that; this project's own history is a
list of numbers that agreed while the picture was wrong, so a human looking at the thing remains the
last word.

**What it does not disturb, and why the two fixes are independent.** A roll of ?180? negates to
itself, so the Medical Pavilion arch that produced the pitch fix is untouched ?
`TheMedicalPavilionCeilingArchFormsOneContinuousSurface` still measures 2422 units, unchanged to the
digit. That is why fixing pitch left this one standing for a further session.

**This project now deliberately disagrees with the reference editor**, and that is pinned rather than
hidden. `ActorTransformReferenceTests` compares against the reference construction *with roll
negated* ? which still exercises the axis assignment, multiplication order, scale, translation and
row/column convention, worst component difference **0.000011** across all 12,557 rotation/scale
pairs ? and `TheDivergenceFromTheReferencesRollIsDeliberateAndMeasured` separately requires all
**5,703** observable-roll rotations to differ from the raw reference (worst 70). A silent revert to
the reference's roll fails a test instead of quietly making every level worse.

**The lesson, which is the reusable part:** agreement with a reference implementation is not
correctness. The reference comparison was committed the same day and stayed green through a real,
visible bug, because Nyko's editor composes roll the same wrong way. **A check that can only compare
two implementations of a rule cannot find a rule that is wrong in both.** What broke the deadlock was
finding a source of truth inside the shipped data ? the BSP tree and the navigation graph ? that
neither implementation had a hand in.

### 22 Aug 2026 ? OPEN (superseded by the entry above): the roll investigation and its dead ends

**A user photographed a skylight in `1-Medical` rotated wrongly with correctly-rotated neighbours,
after the actor-transform work had been called done.** The investigation is unfinished; this records
what is established so a later session does not restart it.

**First, the correction to how item 1 was closed.** `ActorTransformReferenceTests` proves this
project composes an actor transform *identically to Nyko's level editor* ? 12,557 rotations to 1e-5.
That is agreement with a **reference**, not correctness: if the reference builds the rotation wrongly
this project reproduces the error faithfully and the test stays green forever. The project's own
landmine list already says this ("corroboration is not agreement ? check the layer you actually
depend on") and it was not applied. The older evidence has the same hole from the other side: the
Medical Pavilion arch was settled by "the four instances form one continuous surface", which a
surface that is continuous but rotated *as a whole* also passes. **Both existing checks are blind in
exactly the place the bug lives.**

**The reported case, measured.** Four `window_128_corner` actors at Z 8452 form one skylight vault:

| actor | pitch | yaw | roll |
|---|---|---|---|
| `StaticMeshActor1855`, `?1853` | -90? | 0 | 180? |
| `StaticMeshActor1854`, `?1856` | 0 | -90? | -90? |

Their placed area-weighted normals come out `(0, 0.78, 0.63)` and `(0, -0.63, -0.78)` ? the Y and Z
components swapped and negated, the signature of a 90? error about X. **Rendered, two pieces form a
clean barrel vault and two are rotated out of it**, which is exactly what the user saw.

**Six candidate compositions were built and rendered on that assembly. Only one produces a
continuous vault:** `Rz(yaw) ? Ry(-pitch) ? Rx(-roll)` ? i.e. **the current composition with roll
negated**. The shipped one (919 units combined diagonal) and the pre-fix `+pitch` (670) and the
negated-yaw variant (658) are all visibly broken; small diagonal does not mean correct, which is why
this was decided by looking rather than by the number.

**Corroboration is real but weak, and is recorded as such ? do not treat this as settled:**

- **Assembly compactness across five maps** (same mesh, =3 actors, =2 distinct rotations; 287?482
  clusters per map): `negroll` has the lowest mean spread in **4 of 5** ? 1-Medical 1.0172 vs 1.0297
  shipped, 6-Resi 1.0174 vs 1.0278, 3-Arcadia 1.0255 vs 1.0328, 7-Science 1.0262 vs 1.0307 ? and
  loses narrowly on 4-Recreation. Margins are small because yaw-only clusters, which every candidate
  places alike, dilute the signal.
- **Flushness against the compiled world was tried and is INCONCLUSIVE** ? a negative result worth
  keeping so it is not repeated. Counting rolled actors sitting within 12 units of a parallel BSP
  surface gives 63/250 for `negroll` against 60/250 shipped on 1-Medical, 39 vs 37 on 6-Resi, and
  7 vs 10 the *other* way on 3-Arcadia. Most rolled props are not flush against architecture at all,
  so the metric is mostly noise.
- **`Med_Floor_Signs` cannot decide it.** The two rolled ?90? signs sit flush against walls (3.8 and
  5.8 units), which reads as correct under the shipped composition ? but a negated roll leaves them
  vertical and flush too, facing the other way. This is why an early conclusion that "the roll term
  is fine" was wrong: the test could not see the difference it was being asked about.

**Nothing has been changed.** Negating roll would put this project in deliberate disagreement with
the reference editor and would turn `ActorTransformReferenceTests` red on every rotation with a
non-zero roll ? which may be the correct outcome, but not on this evidence. **What would settle it:**
the skylight vault must fill an opening in the compiled world, so its silhouette should match that
opening's boundary ? a ground truth independent of both this project and Nyko. That test is not
written yet.

**Also from this session:** the level viewport now reports the camera position **in the game's own
coordinates** (`MainViewModel.LevelLocation`), so a user can say exactly where a fault is instead of
describing the room. It is the studio basis negated in Y; a readout in viewport coordinates would
name the mirror image of the right place.

### Session of 22 Aug 2026 (later still) ? Gate 0 item 2: the level was missing 11.5% of itself

**Item 2 asked for "remaining blocky/flat BSP surfaces" to be resolved as material-chain failures.
Censusing before fixing found something else first, and it was worse than blocky.**

**A compiled-world surface with no lightmap had no path to the screen.** A map with a proven atlas
pool is drawn from `LightMapBatches` and `Prepare` then `continue`s, so the material-only model is
never built for it. But `ToLightMapBatches` keeps a node only when its first baked-light layer names
an atlas the world carries ? so a *drawn* surface failing that test was in no batch and was drawn by
nothing at all. **23,714 of 206,742 triangles across the 20 affected maps: 49.5% of `7-BossFight`,
37.7% of `0-Lighthouse`.**

- **`Entry` identified the cause on its own.** It was the only map at 100%, and it is the only map
  with no `LightMaps_BSP` group ? so it took the material-only fallback and lost nothing. A natural
  control, not a constructed one.
- **Missing geometry is invisible to every count taken over what is drawn.** The surface census was
  green throughout: a surface that was never added is not a surface with no material, it is simply
  absent. This is the same shape as the mirrored-asset years ? the numbers cannot see it.
- Fixed by drawing the remainder unlit. **206,742 of 206,742 on all 21 maps**, exact, and no map over
  100% (which would have meant double-drawing). `BspGeometry.HasLightMapAtlas` is now one shared
  predicate used by the batch filter and by its complement, so they cannot drift apart.
- **Rendered and looked at, per the standing rule.** "23,714 triangles were missing" is equally
  consistent with real walls and with degenerate slivers, and adding junk would have made the
  coverage assertion pass while making the viewport worse. `7-BossFight`'s remainder is a complete
  room; `1-Medical`'s is scattered solid slabs. Architecture, not slivers.

**Then the material chain itself, where item 2's framing was correct.** Of **74,091 drawn
compiled-world polygons, 0 name no material** ? so a grey BSP surface was never absent data, always
a reference this project failed to follow. **1,530 name their material by import**, and `Describe`
can only express an export, so all 1,530 resolved to null and drew untextured. `MeshSurfaceResolver`
has had the `IExternalMaterialSource` branch for exactly this since "433 slots across the game are
imports and none resolve inside their own package"; the BSP path never got it. Now: **0 unresolved**,
**73,188 of 74,091 (98.8%) bind a base colour**, 875 unpainted by design, 28 neither.

**Two methodology traps, both worth more than the fix:**

- **The first census run reported no change from a fix that works.**
  `AssetCatalogService.ExternalMaterials` is null until `RegisterInstall`, which the application
  calls at startup and the test did not ? so the import branch was a silent no-op *in the test*. A
  measurement that does not set the app up the way the app sets itself up measures a different
  program.
- **The end-to-end check was first written against `0-Lighthouse` and passed ? and would have passed
  before the fix**, because the Lighthouse's compiled world names almost nothing by import. It is now
  on `1-Medical` (248 imports) and was **verified to fail with the fix disabled**, then the source
  restored byte-identical. Reaching for the fixture's default map is how a test ends up asserting
  something true and irrelevant.

**And the census was rewritten to be affordable.** Its first form went through `LevelViewportService`
and therefore decoded every texture in every map ? 18 GB and over twenty minutes, which is precisely
the kind of test that stops being run (the same reasoning behind the Fast/Sweep split). It now walks
the chain without turning any of it into pixels; the pixel check stays as one map.

**Left `UNKNOWN` rather than tidied away:** 28 polygons resolve a material that binds no base colour
and is not a by-design unpainted class. **Source brushes are out of scope throughout** ? `bsp.md`
already establishes their 17,802 material-less polygons as content ? and were not swept for imports.

### Session of 22 Aug 2026 (later) ? Gate 0 item 1: the reference comparison, committed and swept

**A new standing rule came first:** work a roadmap's items in order and clear one fully before
starting another (`ENGINEERING_RULES.md` ?60 "Roadmap discipline", `ROADMAP.md` 0.7). Gate 0 has been
marked *active* for several sessions while work happened in Gate 1 and Gate 2; this session went
back to Gate 0 item 1.

**What was actually wrong with the existing evidence.** The pitch-sign fix below was correct, and the
way it was established was not durable. Nyko's `BuildActorTransform` was matched numerically in one
session over six sampled rotations ? as a throwaway probe. **Nothing of that comparison was
committed.** What went into the suite was
`TheMedicalPavilionCeilingArchFormsOneContinuousSurface`: four instances of one mesh in one map.
That is a single view, and generalizing a rotation rule from a single view is the exact failure that
produced the bug.

**`ActorTransformReferenceTests` now holds it.** `viewport.cpp`'s construction is transcribed
literally ? same column-major `float[16]`, same `m[col*4+row]` arithmetic, same multiplication
order ? so it can be diffed against the C++ by eye rather than trusted as a paraphrase. All sixteen
matrix components are compared (strictly stronger than probe vectors, and it needs no probe choice
to justify) against `ActorTransform.ToMatrix`, for **every one of the 12,557 distinct rotation/scale
pairs the shipped maps place an actor at**: all 161 shipped `.bsm` packages, 118,919 actors, 69,068 rotated, each composed
with that actor's own location and scale. **Worst component difference 0.000011.**

**Proved able to fail.** The pre-fix `+pitch` composition is rejected by all **6,215** placements
pitched far enough to distinguish the two, worst difference **60**. This project has been burned
specifically here before ? two geometric metrics written to catch the backwards first-person pistol
both *passed* the broken pistol ? so a check that has never been seen to fail is not evidence.

**The finding worth keeping: essentially half the game is blind to this class of bug.**
**6,167 of the 12,557 placements sit at a pitch of exactly 0? or 180?**, where `Ry(-p) = Ry(p)` and
the wrong sign produces not a subtly different matrix but the *identical* one. A further 175 combine
a tiny pitch with a small scale and fall below float noise. The first attempt at the falsification
test asserted that *every* rotated actor rejects the wrong sign, failed 91 of 4,562, and **the right
response was to find out why rather than widen the tolerance** ? the difference is
`2?|sin(pitch)|?scale`, which reproduces the measured values to four significant figures. The
exact-symmetry case is pinned by its own test so a later session cannot read the population filter
as a tolerance tuned until the counts agreed.

**A second `UNKNOWN` surfaced, and it is the brush-placement wall again.** Keying the sweep on scale
as well as rotation ? because `T?R?S` and `T?S?R` agree for every *uniform* scale, so a uniform-only
population verifies the ordering no more than a yaw-only one verifies the pitch sign ? turned up
**exactly two** rotated actors in the whole game carrying a non-uniform scale, both in `1-Welcome`,
both `<0.7, 0.687, 0.7>`: **1.8% off uniform**. That is present but far too weak to settle an order.
Same shape as `BrushPlacement`'s "0 of 13,443 brushes scaled, and every rotated one a gameplay
volume": **no shipped sample can decide it.** The order is therefore checked against the reference
under a deliberately non-uniform *probe* scale (`<0.5, 2, 3.5>`, worst difference 0.000004; the
swapped order diverges by 3, so the check distinguishes them) ? and that is labelled for what it is,
an equivalence between two *implementations*, not a claim about shipped data. The census
`Assert.Equal(2, nonUniformScale)` is the fact that can fail if a better sample ever turns up.

**Confidence records corrected while here.** `ToMatrix` moves `LIKELY` ? `CONFIRMED_EXTERNAL`, and
`LevelSceneBuilder.MeshPlacement`'s cross-reference ? which still said "labelled `LIKELY` there,
awaiting a rendered level" long after that stopped being true ? is corrected with it.

**What this comparison deliberately cannot say.** The reference editor does not apply `PrePivot` to
an actor at all; the field appears in its source only as a name in a skip list. So the pre-pivot
term is held at zero throughout, and it continues to rest on this project's own separate and
stronger evidence (`BrushPlacementTests`, 33,631 of 33,632 world polygons). Stated as a boundary,
not left for someone to discover.

### Session of 18 Aug 2026 ? the rotation sign bug, found by a real screenshot

A user reported a warped ceiling arch at the Medical Pavilion entrance ? two panels meeting at a
diagonal seam instead of a smooth barrel vault. This is the bug the earlier "flushness" measurement
had already hinted at (a measured 40-55% mismatch rate for genuinely three-axis rotations) but had
not pinned down, because that heuristic is too coarse and too noisy for floating fixtures.

**The fix: negate pitch in `UnrealRotator.ToQuaternion`.** Found by matching this project's
quaternion composition against the reference level editor's own matrix construction, numerically ?
not by trying alternatives and eyeballing renders. Nyko's `viewport.cpp` builds
`Ry(yaw) * Rp(pitch) * Rr(roll)` for a **column**-vector; this project uses **row**-vector convention
throughout. Six quaternion candidates were matrix-ized and applied to four probe vectors under both
conventions, compared against Nyko's raw matrix multiplied by hand, across six sampled rotations
including the exact case that broke (`pitch=-90?, roll=180?`). `Rz(yaw)?Ry(-pitch)?Rx(roll)`
reproduced Nyko's construction to **1e-6** precision; the shipped `+pitch` version was off by more
than 6 units on the same probes.

**Why the earlier skyline render never caught it.** `LevelRenderingTests`' Rapture-skyline check
exercises real rotated data, but most of Lighthouse's rotated actors are yaw-dominant ? a yaw-only
rotation is insensitive to the pitch sign, so a wrong sign renders identically. The bug needed a
genuinely three-axis case, which is rare and exactly what the arch is.

`TheMedicalPavilionCeilingArchFormsOneContinuousSurface` is the regression test ? verified to fail
against the old sign (combined bounding diagonal 4295 units, one instance scattering away from the
rest) and pass against the fix (2422 units).

**Also investigated, found healthy:** a second report that the Static tab's browser showed nothing
on click. `AssetCatalogService` builds 2,362 static meshes correctly; `MeshPreviewService.Load`
succeeded with geometry on 50/50 sampled entries, zero exceptions; `AssetDetailsService.Describe`
succeeded on all 50, including under 40-way concurrent access through the new `PackageCache`.
Whatever is wrong is in the GUI layer and needs the live window to isolate ? not reproduced here.

### The compiled world's tail ? three findings and one correction

`BspWorldReader` stopped at the vertex pool, leaving **13.9% of the compiled worlds unread** ?
7.9 MB across the 21 maps. The tail is now walked far enough to know what is in it:

- **The first two int32s after the pool are `NumSharedSides` and `NumZones`** ? confirmed by a field
  this project already decodes independently: `max(node.Zone) + 1` equals the declared zone count on
  **21 of 21** maps, from a 2-zone `Entry` to a 125-zone `4-Recreation`.
- **A zone record is an `FCompactIndex` actor reference plus 36 fixed bytes.** The fixed part starts
  with the zone's own bit mask ? 1, 2, 4 for zones 0, 1, 2 ? and the references resolve to
  `ZoneInfo` and `SkyZoneInfo` exports. A fixed 38-byte stride was tried and **rejected**: it lands
  correctly on 2 of 21 maps, because the reference's width varies with the export index.
- **The zone walk lands on the `Polys` reference on 21 of 21 maps**, which is what makes it a decode
  rather than a plausible stride, and the array after that is **`Bounds`** ? 30,578 records across
  the maps, every one a valid `FBox` at a 25-byte stride.

**And the correction, which is the part worth remembering.** That last array was first written up as
`LightMap`, on the strength of UE2's serialisation order ? inherited ordering promoted to a fact
without reading a record. `Entry`'s first record is `min(-128,-128,-128) max(128,128,128)`. It is a
box. **One dump of the bytes settled what one plausible ordering had asserted**, and the wrong
reading stays in `bsp.md` ?5.5c rather than being quietly replaced.

**Lightmaps are past `LeafHulls`, `Leaves` and `Lights`**, with 879 to 628,534 bytes still unread per
map. Walk them the same way: measure a record, anchor it against something already decoded, and only
then name it.

### Documentation drift, corrected

`README.md` had gone stale enough to misrepresent the project: "3D preview: not started", "~40% of
skeletal meshes decode" (98.1%), "130 animations" (16,031), and UE5 import presented as the goal
when it is an excluded feature. Rewritten against the pinned sweeps. **HANDOFF stays authoritative;
the README is now consistent with it.**

## Session of 17 Aug 2026 (later) ? brush placement, settled against the compiled world

The handover's first Phase 2 polish item was: `LevelSceneBuilder.BrushPlacement` is `LIKELY` and
barely exercised, 0 of Lighthouse's 230 brush actors is rotated, **sweep the other maps for one that
is** ? because that would be the sample that settles the composition order.

**Both halves of that were answered, and the second one only because the ground truth turned out to
be sitting in a field this project read and threw away.**

### The sweep: 17 rotated brushes in the whole game, and every one is a volume

All shipped maps, every brush actor: **13,443 brushes, 0 scaled, 17 rotated, 13,255 with a
PrePivot**. The 17 are on `6-Resi` (2), `6-Slums` (3) and `ChallengeRoomCombat` (12), and all 17 are
`ShockDamageVolume`s ? gameplay regions, never drawn.

So **no visible brush anywhere in BioShock exercises the rotation or scale part of the placement
rule**, and no rendered evidence can ever settle it. `LevelSceneTests` asserts that as a fact that
can fail: 0 scaled, and every rotated brush a `Volume`. If a future session finds it red, it has
found the sample this one could not.

### The ground truth: `FBspSurf.Actor`, which was being read and discarded

CSG built the compiled world **from these same brushes**, and every surface names the brush actor it
came from. So the same polygon exists twice ? once in brush space in a `Polys`, once in world space
in the `Model` ? and the placement rule is whatever maps one onto the other. That field was already
being parsed for its length and dropped; it is now on `BspSurface`.

Matching on the **plane** rather than the vertices, because CSG clips a brush against its neighbours
but a clipped polygon stays in the plane it was cut from. Six maps, **33,632 world polygons**:

| candidate | within 1 cm of a plane of its own brush |
|---|---|
| **`Location - PrePivot`** (the rule in use) | **33,631 / 33,632 = 100.0%** |
| the full actor transform | 33,631 / 33,632 = 100.0% |
| `Location` alone | 982 = 2.9% |
| no placement | 297 = 0.9% |

Worst matched offset **0.82 cm**. `BrushPlacementTests`. **The translation is now `CONFIRMED_BYTES`**
and the pre-pivot is load-bearing ? dropping it costs 97% of the match, which is what makes the pass
a measurement rather than a wide tolerance.

**The rotation and the scale are still `UNKNOWN`**, and the first two rows say why: they are
identical because no brush that reaches the built world carries either. This is the honest limit of
what shipped data can say.

Two things fell out that are worth keeping:

- **`0-Lighthouse Brush12` is the one polygon that misses**, by 2.09 cm ? an order of magnitude past
  the tolerance and unexplained. Recorded, not tuned away. It may be the same effect as the 12
  world polygons that sit >1 cm off their own plane.
- **A subtracted brush's face points the other way.** 25,726 of the matched polygons oppose the
  normal of the source poly they came from and 7,905 agree. Rapture is mostly carved out of solid.
  The first attempt matched only same-facing planes and scored 23.5%, which looked like a broken
  placement rule and was a broken *metric*.

`docs/research/bsp.md` ?5.7 has the full write-up; ?6 loses the brush-transform entry and the stale
"the built world is not implemented" line, which the previous session had already falsified.

### The other polish item, closed by counting: brush polygons with no UV

`bsp.md` ?4 said a zero texture axis is real data and "how many is not yet counted". Counted:
**17,802 of 93,264 brush polygons (19.1%) carry no texture axes**, `TextureU` and `TextureV` always
absent together, and **none of the 17,802 names a material**. Missing axes and missing texture are
the same polygons, so nothing in the brush set would ever be drawn with a collapsed UV ? content,
not a decode gap. Both halves are asserted.

## Phase 2 ? where it actually stands

**Measured 16 Aug 2026, on the first run the level analyzer has ever had.** `Core/Level` was written
in an earlier session and had **no test and no caller** ? nothing in the repository executed it ? so
its state was unknown rather than good. `LevelAnalysisTests` now runs it on a shipped map.

`0-Lighthouse` ? 22,780 exports, 596 imports:

| | |
|---|---|
| Actors | **1,877** |
| Actors whose property walk failed | **0** |
| Unresolved references | **0** |
| External references | 1 |
| Actors with a static mesh | 912 (171 distinct meshes) |
| Actors with a skeletal mesh | 132 (20 distinct) |
| **BSP brushes** | **230** |
| Lights | 318 |
| Volumes | 137 |
| Actors with geometry of any kind | 1,274 |

**The actor layer is in good shape and is not the work.** Placement, class defaults, mesh references,
material overrides, attachment parents and BSP brush references all resolve, and nothing is silently
truncated.

**All four of Phase 2's items are now done.**

1. ~~**BSP geometry.**~~ **Decoded** ? `docs/research/bsp.md`. See below.
2. ~~**A level scene exporter.**~~ **Done.** `LevelScene` / `LevelSceneBuilder` assemble a map;
   `LevelSceneExporter` writes it; the **Level tab** in the application drives it.
3. ~~**Lights.**~~ **Done.** 465 on `0-Lighthouse`, with colour, brightness and radius.
4. ~~**A world-bounds sanity check.**~~ **Done, and the guess was right.**

**Do not start by rewriting `Core/Level`.** It measured clean on its first run.

### The level pipeline ? what exists now

```
LevelAnalyzer  ?  LevelContext   (actors, references ? was already here)
                        ?
LevelSceneBuilder ? LevelScene   (placed geometry + lights, in the studio's basis)
                        ?
LevelSceneExporter ? .level.json + .obj        LevelService ? the Level tab
```

`0-Lighthouse`, measured: **1,877 actors ? 1,141 placed objects** (911 static meshes, 230 BSP
brushes), **465 lights**, **2,181,021 triangles**, **0 skipped**. The OBJ is 112 MB; the scene JSON
keeps instancing at **401 assets for 1,141 instances**.

**Rendered and looked at, and this is the load-bearing verification:** the placed static meshes
assemble into **Rapture's skyline** ? recognisable art-deco towers, upright, correctly spaced.

**That render promoted `ActorTransform.ToMatrix` from `LIKELY` to `CORROBORATED`.** Its own remarks
said it was "not yet checked against a rendered level, which is the evidence that would raise it";
a level is the first thing this project has built that composes actor transforms at all. It is
**not** `CONFIRMED_BYTES`: 1,223 Lighthouse actors carry a rotation, but a mostly-yaw level would
look right under several conventions.

**`LevelSceneBuilder.BrushPlacement` is the weakest claim in the pipeline and is labelled `LIKELY`.**
A brush is placed by `Location - PrePivot` with no rotation or scale. **0 of Lighthouse's 230 brush
actors carry a rotation or a scale**, so "the level assembles" is *not* evidence for the composition
order ? the test records that count precisely so a future session does not read confidence into a
green result.

### The level viewport ? walk through a map

**`docs/GUI.md` ?"Walking through a level" is the detail.** "Walk through it" prepares the map ?
about five seconds ? and gives a ghost camera: WASD, Q/E, drag to look, wheel for speed.

**The performance work here is the design, and it came from measurement.** Drawing all of
`0-Lighthouse` on the CPU rasteriser takes **~1.6 s a frame**. Frustum culling alone only reaches
1.15 s: it keeps 399 of 1,141 instances and 883,415 of 2,181,021 triangles, because Rapture's
backdrop city is entirely in view and is most of the map's geometry. **And the frame is bounded by
pixels, not triangles** ? 100,000 triangles cost **423 ms at 960?600 and 147 ms at 480?300**. So the
viewport spends a triangle budget on whatever occupies the most screen *and* halves resolution while
moving. `LevelViewportPerformanceTests` holds all of it.

**Culling must sit above the renderer.** `SoftwareRenderer` projects and buckets every triangle it
is given before touching a pixel, so an off-screen triangle is not free.

**There is a GPU path, and it is the one thing here no test covers.** `LevelGlViewport` is an
Avalonia `OpenGlControlBase` ? no new dependency; `Avalonia.OpenGL` ships inside the Avalonia
package. Avalonia's headless renderer has no GL context, so **every snapshot and pixel check in the
suite comes from the software path**, which is kept rather than replaced. Both consume the same
culled selection and the same camera. If GL fails at any step the window falls back and *says so*.

**What could be tested about it, was.** `GlMatrixConventionTests` pins the claim the whole GL path
rests on: `Matrix4x4` is row-major and row-vector, GL with `transpose = false` reads those bytes as
columns and therefore sees `M?`, and `M? ? v` equals `v ? M`. The companion test proves that
transposing on upload as well ? the intuitive move ? gives a *different* answer, so the pair is not
vacuous. Getting it wrong turns the level inside out and looks like a camera bug.

**Textures work.** Resolved per asset rather than per instance (402 distinct assets against 1,142
placements) and capped at **256** rather than the preview's 1024, because a level holds hundreds at
once and the sum is what matters. Measured on `0-Lighthouse`: **145 textures over 309 of 535
surfaces**.

**A texture fault shipped twice, and a user found it both times by looking.** BSP parameterises its
surfaces in *texels* and the engine divides by the bound texture's size.

1. `NormaliseUvs` was written to do that and **was never called** ? every BSP surface drew with UVs
   running 0?512 and tiled hundreds of times.
2. Wiring it up, the division used **the loaded mip's size, not the texture's authored size**. A
   level caps textures at 256, so a 2048-pixel wall divided by 256 still tiled **eight times too
   often**. A mip is a scaled copy and does not change the parameterisation; the authored
   `USize`/`VSize` is what UVs are relative to.

**Nothing in the suite could see either**, and the *test* was wrong too: it averaged over two
million static-mesh vertices, which are known-good and never take this path, so it reported an
unchanged median while the fix it was checking made no difference to it. It measures **textured BSP
surfaces only** now ? median **6.2**, against a raw peak of 348,160.

**The lesson worth keeping: a wrong UV *scale* is still a texture on every pixel.** Counts, coverage
and even a textured-vs-untextured comparison all pass. Only the magnitude itself shows it.

**A test assertion here was wrong and is recorded as such.** It asserted "more than 15% of drawn
pixels carry a colour cast" and failed at 11% on a render that is visibly correct ? Rapture's
exterior is grey-green concrete under water, so that threshold measured the art direction rather
than the pipeline. It compares a textured render against an untextured one now (**51% of drawn
pixels differ**), which fails for the right reason.

### The GUI ? three tabs now

**Animated**, **Static** and **Level**. The two asset tabs are **one browser filtered two ways**, not
two browsers ? they split on whether an asset carries a rig, which is the distinction that changes
how it is worked with. The markup lives in `AssetBrowserView` and each tab hosts an instance, but
both bind to the same view model, so selection, details and preview are shared and cannot drift.
Textures and materials sit with the static assets.

Both totals count the workspace rather than the catalogue: "Everything (14,380)" beside a list that
can only reach the rigged half stated something untrue, and reads "All rigged assets (1,889)" now.

**Three faults were found by rendering the tab and looking at it, with every test green:**

- The empty-state prompt bound `IsVisible="{Binding !SelectedLevel}"`. **`!` does not negate a
  non-boolean binding in Avalonia**, so "Choose a map on the left" rendered on top of a fully-loaded
  level. Use `ObjectConverters.IsNull`.
- The **asset** extraction bar sat under the level panel offering "Extract selected" / "Extract all
  shown", which reads as though those buttons extract the level. It is hidden on the Level tab now.
  *A control that is merely irrelevant still makes a claim.*
- The level's own Extract button was below the fold.

All three are pinned by `LevelUiTests`, which also had to be corrected: its first snapshot captured
the **Assets** tab, because selecting a level in the view model does not change which tab is
showing. A snapshot of the wrong tab proves nothing.

The size estimate is stated before the job runs ? measured at ~54 bytes per triangle, so Lighthouse
reads "about 112 MB", which is what it writes. Bulk extraction size has been reported as a fault in
this project once already when it was really an unstated cost.

### BSP ? the source brushes are decoded, the built world is documented

**`docs/research/bsp.md` is the note; read it before touching any of this.** Two different things
are called BSP here and confusing them wastes a session:

| | where | state |
|---|---|---|
| **Source brushes** ? the designer's convex solids | one `Polys` export per brush | **`CONFIRMED_BYTES`** |
| **The built world** ? nodes, surfaces, vertex pool, lightmaps | one large `Model` export | **`CONFIRMED_EXTERNAL`, not implemented** |

`0-Lighthouse` ships 285 `Model` exports; 284 are ~1,700 bytes and **one, `Model1`, is 312,400** ?
that is the built world, and the size distribution is what separates them. On `1-Medical` it is
8.6 MB.

| measured | |
|---|---|
| Map packages containing brushes | **21 of 161** |
| `Polys` exports walked | **16,926** |
| ?landing on the **exact** final byte | **16,926 (100%)** |
| Polygons / vertices | **93,264 / 374,372** |
| Polygons naming a material | **59,495 ? every one resolves to a material class, none to an actor** |

**A brush carries its own surface**, so brush geometry can be textured by the existing material
resolver rather than drawing bare. Rendered and looked at: the Lighthouse rotunda comes out as a
recognisable octagonal room shell.

**BSP winds the OPPOSITE way from the game's meshes**, and this is the one decoded container whose
winding must be reversed after the basis reflection. Meshes must not be ? see ?4. Measured over all
21 maps (0 agree / 93,264 disagree in shipped order; 93,264 / 0 for what the reader emits) and
confirmed a second way by enclosed volume (254 positive, **0 negative**).
`ANIMATION_COORDINATE_SYSTEM.md` ?6.1 and ?9, which now lists **five** conversion boundaries.

**The `Model` container now walks too** ? `ModelReader`. That is the link a level needs and the
export table does not state it: of Lighthouse's 285 `Polys` exports only 60 have a `Model` outer, 54
have a `SkeletalMesh` and 171 have none. All **16,926** `Model` exports in the game land on a
reference that resolves to a `Polys` export.

### The compiled world is decoded ? this is what a level actually is

**`BspWorldReader`, `CONFIRMED_BYTES`.** `FBspNode`, `FBspSurf` and the vertex pool are read and
drawn. Before this a level carried only source brushes and placed meshes, so a map was a skyline and
props **with the rooms missing** ? which is what a user reported as "floor bsps aren't working".

| across all 21 maps | |
|---|---|
| Compiled worlds | **21** |
| Polygons / triangles | **81,566 / 227,911** |
| Polygons >1 cm off their own plane | **12 (0.015%)** |

**Planarity is the check that proves the layout**, because three independent arrays ? nodes, vertex
pool, points ? have to agree, and a wrong offset cannot make polygons coplanar by accident. **The
figures match Nyko's exactly:** `1-Medical` gives 7,125 nodes, 3,386 surfaces and worst distance
**0.25** with zero off-plane, which is his number to the digit.

**The landmine, recorded:** `NumVertices` is a **byte at +78**, not the int32 at +88 an initial
reading suggests (+88 gives 64% planarity failures). Note that **+97 also scores 100%** on the
offset probe ? the score does not choose between them, the field layout does.

Winding is the same as the source brushes' (0 of 758 agree in stored order), and
`PF_Invisible`/`PF_FakeBackdrop`/`PF_Portal` surfaces are excluded ? 15 of 370 on Lighthouse ?
because they are zoning and portal geometry the game never draws.

**Still not read:** lightmaps (?5.5 of the note has the full descriptor chain), CSG, and
`FBspSurf +20`, where Nyko's spec, his parser and his lightmap note give three different answers.

### Lights ? ?C.6 of a file nobody had opened answers it

BioShock writes light parameters with **different types** from stock UE2.5, which is exactly why
they sit unread in `UninterpretedProperties`:

| field | BioShock | stock UE2.5 |
|---|---|---|
| `LightBrightness` | **FloatProperty**, 0.0?3.1, median 1.0 | byte 0?255 |
| `LightColor` | **StructProperty `Color`** ? FColor BGRA | `LightHue` + `LightSaturation` bytes |
| `LightRadius` | **FloatProperty**, 0?120,000 units, median 2048 | byte, radius = 25 ? (b+1) |

`bStatic`/`bNoDelete` are never written to disk. Reading three properties is the whole job.

### The world bounds ? one actor, and it is a sentinel

`Z = 262144` is Unreal's `HALF_WORLD_MAX`, and **exactly one actor of 1,874 is there**: a `Script`
actor at `(496, 1088, 262144)`. Excluding it, the level's maximum Z is **12,288** ? a twenty-fold
difference. **An exporter that sizes a scene from the raw extents sizes it from a sentinel.**
`BspGeometryTests.TheLevelsExtentIsSetByOneActorAtTheEngineWorldBoundary` pins it.

## The four reference projects in the repo root ? how far each has been mined

They are gitignored and must stay so; the Havok one is licensed material. **Reading these first is
now project policy**: the hand blocker cost three sessions of internal measurement and was settled
by one function in the Havok SDK, and the section table above came from Nyko's SDK after this
project failed to find it from bytes alone.

| folder | mined |
|---|---|
| `hk2012_2_0_r1` | **2 files of 114** in `Source/Animation`. `hkaSplineCompressedAnimation.h`/`.inl` only. |
| `Bioshock1REMSDK-WIP--main` | `bioshock1-bsm.md` ?C.1, ?C.2, ?C.4, ?C.5, ?C.6; `BioShock_Materials_And_Shaders.md` in full; `BioShock_Texture_Lightmap_Format.md` ?5??6; **and `tools/level_editor/src/bsp_parser.cpp` + `viewport.cpp`, which render BSP.** Four findings so far. **Read this project's code as well as its prose** ? the editor carries measurements the documents do not, and contradicts them in one place. |
| `UModel-master` | **`UnTexture2.cpp`, `UnMeshBioshock.cpp`, `UnMesh2.h`'s `FSkelMeshSection`, `UnCore.h`'s `TRIBES_HDR`.** Source of two findings this session ? the DXT5N texture format and the skeletal section table. Its BioShock branches are extensive and the rest is still unread. |
| `Unreal-Library-master` | **`Engine/Classes/UPolys.cs`, `Engine/Types/Poly.cs`, `Branch/PackageObjectLegacyVersion.cs`.** Source of the `FPoly` field list ? the first finding ever taken from this project. The rest is unread. |

**The policy paid again, and quickly.** `BioShock_Materials_And_Shaders.md` had never been opened; it
was read this session and its first two sections settled the largest open item in materials in
minutes ? 515 meshes went from flat grey to textured ? after the project had spent two sessions
measuring around it. **Read the reference projects first.**

Highest-value unread material, in order:

- **`Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Reading_Textures.md`** and
  `BioShock_Texture_Lightmap_Format.md` ? 247 lines, never opened, and the obvious place to look for
  `Format` ordinal 12 (open question 11c, 274 normal maps that will not decode).
- **`UModel-master/Unreal/`** ? mesh readers, for ?6.2.
- **`hk2012_2_0_r1/Docs/?User_Guide.pdf`** ? never opened. Likely settles `blendHint` and the
  animation-binding contract outright.
- `hkaSkeleton.h`, `hkaAnimationBinding.h`, `hkaSkeletonMapper.h` ? we carry `Unknown*` fields and
  two carried-but-unused flags on inference.

**Dead end, do not re-check:** `hkaSignedQuaternion` ships declarations only, no `.inl`, so this SDK
cannot confirm the ThreeComp40 bit layout. It stays `CONFIRMED_BYTES` by continuity inference.

**Beware one divergence:** Nyko's and UEViewer's `UStaticMesh` vertex is 24 bytes with packed
normals; Remastered's is 48 with full float basis vectors. Both right for their own target. A
finding ported from either may need the record widening.

## Open, recorded, deliberately unfixed

- ~~**`smg/smg_fire`** ? one animation of 16,031 where `Bip01_R_Forearm` and `Bip01_R_ForeTwist`
  collapse.~~ **The "one animation" framing was wrong and is corrected in ?6.0c**, which supersedes
  this entry: it is a family of four ? `PI_Fire`, `PI_Fire_B`, `PI_fire_C` and `smg_fire`, all on
  `AggressorBabyJane`, all 54 tracks against her 73 bones, all worst on frame 0. The rest of the
  entry still stands: not additive (every animation in the game is `blendHint 0`, by census), and the
  answer is probably in `sampleTranslation`, which is not in this SDK build. Four candidate causes
  have been eliminated with evidence; see ?6.0c before proposing a fifth.
- **Bulk extraction is ~140 GB and hours long, and that is a deliberate open item.** Reported as
  "extraction is not working"; it is not ? `ExtractionUiTests` drives the real command and the
  pipeline writes correct output (a 49-asset sample produced 2,478 files, including 457 per-animation
  FBXs for `AggressorBabyJane`). The problem is that "Extract all shown" from the default view is
  2,000 assets, characters first, and the buttons grey out while it runs. Compacting the scene JSON
  took it from ~350 GB to ~140 GB. **The remaining bulk is animation track data written twice** ?
  once as floats in the scene JSON, once in the per-animation FBX files. Omitting the tracks from the
  JSON when FBX is also selected is the obvious fix and was **explicitly deferred by the user**, not
  overlooked. So were a size warning before a large job, and keeping the UI responsive during one.
- **Skeletal meshes cannot be split by material** ? ~~no section table in that container.~~
  **That reason was wrong: the table exists.** `UnMeshBioshock.cpp`'s `FStaticLODModelBio` opens with
  `TArray<FSkelMeshSection>`, nine `uint16`s each, commented "1 section = 1 material" ? item 6 under
  NEXT CLAUDE SESSION, open question 11d, `reference-comparison.md` ?3a. So this is open because the
  work is not done, **not** because the data is missing, and it needs the payload walked from the
  front rather than the vertex chain searched for. The diagnostic sweep counts **153** meshes in this
  state, so the scale of it is known rather than estimated.
- ~~**Five material classes are read as if they were `Shader`** ? `FluidShader`, `PlantShader`,
  `LightBeamShader`, `MaterialSwitch`, `MaterialSequence`, `LayeredShader`. 522 meshes resolve a
  material binding zero textures because of it.~~ **Superseded ? this was fixed.** A texture binding
  is now an `Object` property resolving to a `Texture` rather than a slot name on a list, and a
  `Texture` named in a slot is itself a material. `mesh-no-diffuse` fell 755 ? 240. What is left is
  not all fault: `LightBeamShader` (64) genuinely has no base colour, and `MaterialSwitch` (38) and
  `MaterialSequence` (4) are Modifiers wrapping sub-materials that nothing follows yet ? that is the
  clearest remaining piece. Open question 11b.
- ~~**Texture `Format` ordinal 12 is undecoded** ? 274 exports, 64 distinct names, every one a normal
  map.~~ **Superseded ? it is decoded.** It is **DXT5N**, not the 3DC/BC5 one reference project calls
  it; all 274 exports now decode and `texture-undecodable` fell 320 ? 46. Open question 11c,
  `reference-comparison.md` ?1. **What remains under that heading is different**: the 46 exports
  carrying no `Format` property at all, whose 42 distinct names are all editor sprites and engine
  placeholders. Whether they hold pixels is `UNKNOWN`.
- ~~**Every weapon in the `NEWPlayerHands` animations is backwards.** `REPORTED, NOT YET REPRODUCED`~~
  **FIXED, 16 Aug 2026.** Cause: the viewport chose the attachment's socket **by bone**, and nine of
  the hands' sockets share the bone `R_grip`, so every weapon got `Wrench` ? which carries a 180?
  turn about Z where `Pistol` and `Chem` carry identity. See ?4 and
  `docs/research/firstperson.md`. The account below is kept because its *reasoning* was wrong in an
  instructive way.

  It matters more than its position in this list suggests: **the first-person pistol is this
  project's target case** (?1) and its hands-and-weapon set is the most-checked asset in the
  repository. If the weapons are oriented wrongly, then a great deal of validation that reads green
  is green on a wrong result ? which is the exact failure mode ?4 exists to record, twice over
  (the mirrored years, and the wrong section/material pairing).

  **Do not fix this by rotating the weapon.** Candidate causes worth measuring before changing
  anything, none of them established:
  - **`FCoords` may be a world-to-local basis, not local-to-world.** Unreal's `FCoords` is
    conventionally the *inverse* transform. `SkeletalMeshReader.ReadSocketCoords` builds the matrix
    from the axes as rows and uses it directly. A transposed rotation looks exactly like "backwards"
    for a 180? yaw. **Note the counter-evidence:** every first-person weapon socket is recorded as
    identity, and a transpose of identity is identity, so this alone cannot explain the first-person
    case ? which is what makes it worth measuring rather than assuming.
  - **The weapon rig's own root.** A weapon skeleton is rooted at `R_grip` and is drawn with the
    host's socket-bone transform. Whether the weapon's root reference orientation is being composed
    in or discarded has never been checked.
  - **The basis conversion is not a candidate** without new evidence: `C = diag(1,-1,1)` reflects
    left/right, and every mesh, skeleton and animation goes through it once at four boundaries. A
    fault there would mirror the whole scene rather than turn one attached rig around. See
    `docs/research/ANIMATION_COORDINATE_SYSTEM.md` before touching any transform.

  **How to check it honestly:** render it and look. `BIOSHOCK_RENDER_SNAPSHOT` writes the viewport
  offscreen. The measurement that would settle it is the weapon's muzzle-to-grip axis against the
  hands' forward axis, on several weapons ? not one screenshot of the pistol, which is the asset
  this project has repeatedly over-generalised from (?4, "the first-person rig is not a
  representative sample").
- ~~**The shotgun cannot be attached at all, and it is one of the seven player weapons.**~~
  **FIXED, 16 Aug 2026 ? and the route first proposed for it was wrong.** The handoff suggested
  offering it on the root-bone test that promotes every other weapon to `Confirmed`. **Measured, and
  that is dead:** `WP_Shotgun`'s rig is rooted at **`SG_Body`**, and its three bones are
  `SG_Body, SG_Pump, SG_Shell` ? there is no `R_grip` in it at all, where every other weapon has one
  as its root. So the shotgun has *neither* a socket naming it *nor* the root-bone match.

  What resolves it is a third relationship the game does state: **the hands carry their own
  `Shotgun` animation set**, and `WP_Shotgun` is the only shotgun viewmodel.
  `AssetContextService.WeaponsNamedByAnAnimationSet` offers it on that, at the bone the rig's other
  weapon sockets use, and reports it **`Likely` ? never `Confirmed`**, with evidence separating the
  stated half (the animation set) from the inferred half (the attach point). Rendered and looked at:
  the shotgun sits in both hands, right hand on the stock and left at the pump.

  The original account follows, because its *evidence* stands and only its proposed fix was wrong.

  Checked against the game's own weapon list (wrench, pistol, machine
  gun, shotgun, grenade launcher, chemical thrower, crossbow):
  - the hands carry its animation set ? `USharedSkeletonAnimationMetadata_EmptyFidgetShotgun`, beside
    `...Pistol`, `...Crossbow`, `...Chem`, `...Launcher`, `...TommyGun`;
  - its viewmodel ships with a rig ? `WP_ShotgunMesh`, `UAPW_WP_Shotgun`,
    `USharedSkeletonDataMetadata_WP_Shotgun`;
  - **but `NEWPlayerHands` declares no `Shotgun` socket.** The nine sockets on `R_grip` are `Pistol`,
    `Wrench`, `Crossbow`, `Chem`, `TommyGun`, `Launcher`, `IrritantBall`, `WrenchRibbonSocket` and
    `PlayerGathererGun`.

  `AssetContextService` drives its weapon sweep from the host's sockets, so with no socket naming it
  the shotgun is never offered ? it cannot be previewed with the hands, and it never reaches the
  export as a two-rig set. **Six of seven weapons work and the seventh is invisible**, which is why
  this went unnoticed: nothing fails, the picker simply has one fewer entry.

  **Do not fix it by inventing a socket.** The evidence-backed route already exists: `Assess`
  promotes a candidate to `Confirmed` when *the weapon's own skeleton is rooted at the bone*, which
  is a stated relationship rather than a name match, and `WP_Shotgun` is rooted at `R_grip` like its
  siblings. Offering weapon groups by that test ? for a first-person host only ? would reach the
  shotgun without weakening the rule that keeps NPCs from being handed viewmodels. Not implemented;
  it changes attachment resolution and wants its own measurement.~~

  **That proposal was wrong and the clause "`WP_Shotgun` is rooted at `R_grip` like its siblings" was
  an assumption written down as a fact.** It is rooted at `SG_Body`, and one probe settled it.
  **The rig roots are worth having:** every weapon viewmodel is rooted at `R_grip` ? `WP_Pistol`,
  `WP_TommyGun`, `WP_Crossbow`, `WP_GrenadeLauncher`, `WP_ChemicalThrower`, `WP_PlasmidEquip`,
  `WP_GathererGun` ? and `WP_Shotgun` alone is not.
- **`PlayerGathererGun` is not a player weapon**, and the socket of that name should not be read as
  one. "Gatherer" is the developers' own name for a **Little Sister** ? the hands also carry
  `GathererAttach` and `GatherSave` sockets and `Gatherer` notifies. It is listed among the hands'
  attachments because it hangs off `R_grip` like the weapons do, and it resolves no animation set of
  its own, so anything that poses it borrows another weapon's clip. Corrected on the user's word,
  16 Aug 2026, after it was described here as one of the guns.
- **The `Melee` socket** ? could be the wrench, pipe, machete, rake or shovel. Left unresolved
  rather than given whichever sorted first.
- **Splicer variant ? animation set** ? nothing in the data links a *particular* variant to a
  *particular* behaviour set (spider, nitro, leadhead). Needs evidence found, not a mapping invented.
- **?6.0b** is closed: the left hand now reaches 4.36 cm from the grip.

6. **Phase 2 (level extraction) is unlocked when 1C finishes** ? the user has confirmed this. 1C's
   remaining item is the Asset Inspector; when that lands, Phase 1 is frozen and Phase 2 may begin.
   Groundwork already exists in `src/BioShockStudio.Core/Level/` ? **read it before writing anything
   new**. The unlock is permission to start the phase, not permission to rewrite what is there.
