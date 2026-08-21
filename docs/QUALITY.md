# Quality pass

A sweep of every mesh and every animation the game ships, looking for anything that does not come
out right.

The animation half is now a committed, repeatable command rather than a one-off probe:

```bash
dotnet run -c Release --project src/BioShockStudio.Cli -- audit-animations out.csv
```

`src/BioShockStudio.Core/Diagnostics/AnimationAudit.cs`, tested by
`tests/BioShockStudio.Tests/AnimationAuditTests.cs`.

**The mesh, material and texture half is now a committed command too**, and no longer a scratch
probe:

```bash
dotnet run -c Release --project src/BioShockStudio.Cli -- diagnose [package] [--animations] [--code C] [--out report.csv]
```

`src/BioShockStudio.Core/Diagnostics/AssetDiagnostics.cs`, tested by
`tests/BioShockStudio.Tests/DiagnosticsTests.cs`, and shown in the application's Problems panel.
Every entry carries the asset, the package, the subsystem and the **evidence** — the measurement, not
the conclusion — so a finding can be acted on by a session that did not produce it. See
[the whole-game diagnostic sweep](#whole-game-diagnostic-sweep) below.

**Scope:** 21 map packages plus the script packages — the `diagnose` sweep covers **33 packages,
9,684 mesh exports, 14,328 materials and 31,106 textures**; the animation audit covers 16,031
animations across 883 animation packages. The older figures below (9,672 meshes, 16,025 animations)
are from the previous probe over the narrower set and are kept as written.

**Materials went from 13,545 to 14,328 examined, 19 Aug 2026, from a real bug fix, not scope
creep.** `AssetDiagnostics.ScanExport` checked `MaterialReader.IsMaterialClass` before the
texture-class check; since a `Texture` export is itself a valid material (a `BitmapMaterial`, per
`MaterialReader.SelfSlot`), every texture in the game was being swallowed into the Materials bucket
and the sweep silently examined **0 textures** — a regression `DocumentedFiguresTests` caught the
moment it was measured again. Reordering the two checks fixed the dispatch; it also surfaced a
second real gap while widening `IsMaterialClass` to scan `MaterialSwitch` directly: its
`MaterialReader.Read` follows the switch's default child, but did not check the child was actually a
class the reader understands before recursing into it, misreading an unrelated class's own Object
properties as texture slots. Both are fixed; see `StructSizeTests` and `DocumentedFiguresTests`.

Every check is objective. Nothing here judges whether something "looks" right; each one reports a
fact that can only be true of a broken result — a decode that failed, a non-finite vertex, an index
out of range, a skeleton whose bones changed length. Where a check turned out to flag correct data,
that is recorded rather than the check being quietly dropped.

## Headline

| | Total | Good | |
|---|---|---|---|
| Meshes decoded | 9,672 | **9,654** | 99.8% |
| Animations decoded | 16,025 | **16,025** | 100% |
| Meshes with a resolved diffuse texture | 9,684 | **9,372** | **96.8%** (was 96.4% before the diagnostic-dispatch and MipZero fixes, 73.9% two sessions before that, 91.1% before the material-class work) |

Geometry and animation are essentially complete, and materials have gone from 7.0% to **96.8%** in
four steps: a `StaticMesh` names its material in its own `Materials` property; an import naming a
shader in another package is followed; a texture binding is any object property that resolves to a
`Texture`, not a name on a list; and fixing the diagnostic sweep's material/texture dispatch order
(above) plus decoding UE2's constant-colour `MipZero` texture variant recovered another 45
previously-"undecodable" textures. See [research/materials.md](research/materials.md).

## Animation audit — whole game

`CONFIRMED_BYTES`, from the command above, after the basis conversion landed.

| | |
|---|---|
| Packages swept | 33 (21 maps, plus `Entry`, `ShockGame.U` and the other script packages) |
| Packages holding animation | 23 |
| `AnimationPackageWrapper` exports | 883 |
| Distinct skeletons | 399 (58 distinct names) |
| **Animations** | **16,031** |
| **Playable** | **16,031 (100%)** |
| Partial / Unsupported / Failed | 0 / 0 / 0 |
| Wrappers that would not load | 0 |
| Tracks binding to no bone | 0 |
| Animations carrying events | 11,503, with 47,560 events total |

### Two checks that separate "decoded" from "decoded correctly"

| | Result |
|---|---|
| Block walks that left their block unconsumed | **0 of 16,031** |
| Animations with a bone jumping ≥ 10 cm in one frame | 9,564 |
| … ≥ 25 cm | 3,664 |
| … ≥ 50 cm | 1,212 |
| … ≥ 100 cm | 273 |

**Block slack is clean everywhere.** A block is padded to 16 bytes, so a correct walk ends within 15
bytes of its length; more than that means the walk lost alignment inside a channel and every track
after it is read from the wrong offset. Not one animation in the game does this, which rules out
channel-mask misreads as a cause of any remaining animation fault.

**The frame-step numbers are reported, not judged.** The largest absolute jumps are on things that
genuinely move a long way — `BathyPath_Full` (a bathysphere path, 1782 cm), whale swim paths, the
plane crash — so the absolute figure alone says little. The `worstStepRatio` column, the jump as a
multiple of that animation's own mean step, is the discriminating one.

One real finding sat in here: on the first-person hands rig, 60% of animations had their worst jump
on a left-side bone against 13% on a right-side one. That was the blocker, and it is fixed — see
§"The left hand" below. The audit's jump counts all fell when it landed: 9,564 → 9,504 at ≥10 cm,
3,664 → 3,644 at ≥25 cm, 1,212 → 1,211 at ≥50 cm, 273 → 272 at ≥100 cm.

### `LockTranslation` is a retargeting hint, not a sampling instruction

`CONFIRMED_BYTES` that it must not be applied. The flag is set on 6,230 of 9,356 bones (66.6%), and
59,889 tracks drive a translation on a bone carrying it — including `Bip01_Spine`, the first-person
root, 89.8 cm from its reference pose. Honouring it would pin every rig to its bind root. It is
preserved and unused, and now says so where it is declared.

"Playable" is not a judgement about how the motion looks. It means: the wrapper loaded, the binding
resolved every track onto a bone that exists on the skeleton, the compressed data decoded, every
track is sampled over every frame, every translation and scale key is finite, and every rotation key
is unit length to within 0.01.

Two things worth stating plainly, because both look like gaps and neither is:

- **`Unsupported` is 0 because every animation the game ships is spline-compressed.** There is no
  second compression form waiting to be implemented. Range across the sweep: 2 to 6,001 frames, 1 to
  131 transform tracks.
- **A sweep that reports 100% proves nothing unless its checks can fail.** `AnimationAuditTests`
  feeds each check its own breakage — zero frames, zero tracks, an unbound track, a truncated track,
  a NaN translation, an infinite scale, a non-unit quaternion — and asserts each one is caught.

## The left hand — RESOLVED

**The left hand now reaches the weapon.** This section used to record that on the first-person rig
the left hand sat 25–70 cm from the weapon in every idle, fidget and fire animation, on every
weapon. The cause was in the spline decompressor: a channel component a track omits is Havok's
identity, not the bound bone's reference pose, and the reference pose was injecting the authoring
pose's Y and Z into `Bip01_L/R_UpperArm` on every frame.

| | before | after |
|---|---|---|
| Closest the left hand gets to the weapon grip | 11.08 cm | **4.36 cm** |
| Left hand on the wrong side, all 130 animations | 3,384 / 5,984 frames | **48 / 5,984** |

`FirstPersonHandTests` holds both. Full account in `docs/research/FIRST_PERSON_ANIMATION.md`; the
format detail is in `docs/research/havok-compression.md`.

The long elimination list this section carried — the basis conversion, the binding, retargeting,
additive blending, the attachment transform, scale, block boundaries, hemisphere alignment, bone
stretching, the bind pose, and a clean rotation at the chain root — was all correct behaviour being
correctly eliminated. The fault was never in any of it.

**One correction from that list stands and is worth keeping.** `IKbindLhandDummy` was ruled out as
unreachable by measuring 93–108 cm from `Bip01_L_Clavicle` against a 73.3 cm reach that begins at
`Bip01_L_UpperArm`, 93.11 cm further down the chain. Measured from the origin the reach actually
starts at, it is 13–30 cm away across the pistol set. Whether it is an IK goal remains `UNKNOWN`;
nothing in the code consumes it.

## Whole-game diagnostic sweep

`CONFIRMED_BYTES`, from `diagnose` over the whole install. **Examined 55,118 assets in 33 packages:
9,684 meshes, 14,328 materials, 31,106 textures.** The counts below are current as of 19 Aug 2026;
where a figure moved from a real fix rather than scope creep, both are given. Animation is a
separate sweep — `--animations` merges `audit-animations` in — because it costs minutes on its own.

| count | severity | code | what it means |
|---|---|---|---|
| 1 | Broken | `texture-undecodable` | The texture will not decode, so nothing can be written for it. Was 320 before ordinal 12 was decoded, 46 before the `MipZero` constant-colour variant was decoded (19 Aug 2026). |
| 18 | Broken | `mesh-no-geometry` | No vertex data in the payload. |
| 202 | Degraded | `mesh-no-diffuse` | The material resolves but binds no base colour, so the mesh draws flat. Was 240 before the diagnostic-dispatch fix below let more slots naming a Texture directly resolve. |
| 110 | Degraded | `mesh-material-slot-unresolved` | A surface has no material and draws untextured. Was 123, same fix. |
| 2 | Degraded | `mesh-uv-out-of-range` | The UVs are not usable. |
| 157 | Note | `mesh-materials-without-sections` | A skeletal mesh names several materials and has no table saying which triangles use which. Was 153; more multi-material meshes are now correctly resolved as such. |

Two of these agree exactly with results already pinned by other tests, which is what says the sweep
is measuring the same game: the **18** `mesh-no-geometry` are precisely the 18 door exports
`SkeletalMeshGeometryTests` names, and the **2** `mesh-uv-out-of-range` are `BatPath` and
`Shadow_Scissors`, §4 below.

**This section is where the base-colour figure is measured; the headline table quotes it.** The
headline used to read "73.9% of meshes have a diffuse texture" and was stale — that figure was
stated in three documents at once and was wrong in all three within a session, which is why the
numbers here are now pinned by a test rather than maintained by hand (see
[Keeping these figures honest](#keeping-these-figures-honest)).

**19 Aug 2026 — two real fixes, not a regression, moved every figure in the table above.**
`DocumentedFiguresTests` caught `AssetDiagnostics.ScanExport` checking
`MaterialReader.IsMaterialClass` before the texture-class check: since a `Texture` export is itself
a valid material (`MaterialReader.SelfSlot`), every texture in the game was being swallowed into the
Materials bucket and the sweep silently examined **0 textures** — this was the actual failure, not
documentation drift. Reordering the two checks fixed it, and separately, `TextureReader` now decodes
UE2's constant-colour `MipZero` texture variant (`WhiteTexture`, `BlackTexture` and others were never
actually broken, just not yet modeled). Together: `mesh-no-diffuse` **240 → 202**,
`mesh-material-slot-unresolved` **123 → 110**, `texture-undecodable` **46 → 1**.

By this sweep, **202 + 110 = 312 of 9,684 meshes (3.2%) carry a base-colour fault** — the two codes
remain disjoint on the shipped game, no mesh raises both. So **96.8% carry a base colour**, against
96.4% before the 19 Aug fixes, 91.1% before the material-class work below, and 73.9% when this line
was first written.

> **The older "347" figure quoted here before 19 Aug 2026 was already flagged as unreproducible from
> the `diagnose` output** — its derivation (240 plus only the slot-unresolved meshes whose *every*
> surface resolves nothing) was never written down anywhere the sweep could check it, which is
> exactly the drift `DocumentedFiguresTests` exists to catch. It is not being recomputed against the
> new 202/110 counts for the same reason: **312 is what the sweep can actually reproduce.**

### `mesh-no-diffuse` was mostly material classes the reader did not know — 755 → 240

**This was the largest lead in the sweep and it is now mostly closed.** The reader decided what
counted as a texture binding from a list of thirteen slot names taken off `Shader` and
`FacingShader`; the game ships at least nine material classes and each names its slots differently.
The rule is now *"an `Object` property whose reference resolves to a `Texture`"*, and a `Texture`
named directly in a material slot is itself a material. `docs/research/materials.md` has the byte
evidence and open question 11b the reasoning.

| material class | before | after |
|---|---|---|
| **total** | **755** | **240** |
| `FluidShader` | 249 | 83 |
| `PlantShader` | 183 | **0** |
| `Texture` (the slot names a texture object, not a shader) | 165 | **0** |
| `LightBeamShader` | 64 | 64 |
| `Shader` | 51 | 51 |
| `MaterialSwitch` | 38 | 38 |
| `MaterialSequence` | 4 | 4 |
| `LayeredShader` | 1 | **0** |

**Rendered and looked at, because no count can see this:** `kelp_01` draws as green-gold seaweed
fronds and `newspaper_old_05` as three crumpled newspapers with legible print. Both were flat grey
before. `StaticMeshRenderingTests.Static_Snapshot` writes them.

What is left is not all fault. `LightBeamShader` genuinely has no base colour — it binds `FalloffMap`
and `DustMap` and takes its look from `BeamColor`. **`MaterialSwitch` is no longer wholly
unfollowed as of 19 Aug 2026**: each shipped switch has an explicit `Material` property naming its
authored default child, and `MaterialReader.Read` now follows that one reference (guarded so it only
recurses into a class the reader actually knows how to parse — see `docs/ROADMAP.md`). The switch's
own `Materials` candidate array — the *runtime* selection among several sub-materials — remains
unfollowed; `MaterialSequence` deliberately still isn't, for the same reason. Open question 11b.

**The total in the table above is now further reduced, 240 → 202, by an unrelated dispatch fix**
(see the note above the table) rather than by the `MaterialSwitch` child-following change, which
does not change *this* count — a switch's default child was already being scanned as its own export
when that export's class independently matched `IsMaterialClass`.

### `mesh-material-slot-unresolved` is mostly declared-null slots — 117 of 123 (now 110)

117 slots name nothing at all; 6 name an import that does not resolve, and four of those six are
`DefaultTexture`. The null slots are the ones already recorded in the handoff's decision log: an
empty slot keeps its position so the section table still indexes correctly, and the surface draws
untextured rather than borrowing a neighbour's material. The total dropped to 110 on 19 Aug 2026
from the diagnostic-dispatch fix above; the breakdown of which of the remaining 110 are null versus
a still-unresolved import has not been re-derived and is not asserted here.

### `texture-undecodable` was two separate things — 320 → 46 (now 1)

The diagnostic reports which of the reader's own preconditions failed
(`TextureReader.DescribeFailure`), and that split the original 320 cleanly with nothing left over:

| exports | distinct | cause | state |
|---|---|---|---|
| **274** | **64** | `Format` ordinal **12** | **decoded** — it is DXT5N |
| **46** | **42** | no `Format` property at all | still broken |

**All 64 of the ordinal-12 names were normal maps** — `*_Normal`, `*_Normalmap`, `*_Norm`, `*_NOR`,
without exception — at 128² through 2048². That observation is what made the format identifiable, and
it is also what the fix had to satisfy.

**Two reference projects disagreed and the bytes settled it.** Nyko's texture note calls ordinal 12
"3DC — BC5/ATI2, two BC4 alpha blocks giving R and G". UModel's BioShock branch remaps it to
`TEXF_DXT5N` with the comment *"Bioshock used 3DC name, but real format is DXT5N"* — an ordinary DXT5
block with the normal in **alpha and green**. Decoded both ways on `Cheese_Mould_Normal`:

| | as BC5 | as DXT5N |
|---|---|---|
| X mean | 127 | 127 |
| **Y mean** | **57** | **128** |
| Z mean | 209 | 252 |
| texels with `x² + y² > 1` | many | **0 of 4,096** |
| looks like | magenta noise | a normal map |

`NormalMapFormatTests` asserts the invariants a normal map must satisfy, so it **fails on the wrong
reading** rather than merely describing the right one. See
[research/reference-comparison.md](research/reference-comparison.md) §1.

**Of the 46 that remained, all but one turned out to be decodable after all — 19 Aug 2026.**
`TextureReader` now recognizes UE2's constant-colour `MipZero` variant: a texture with no `Format`
property but a `MipZero` property of struct type `Color` is not missing its format, it's a solid
fill, and the colour itself is the payload. That recovered `DefaultTexture`, `WhiteTexture`,
`BlackTexture`, `MaterialBackdrop`, `Proj_Icon`, `SoundMarker` and the 32 editor sprites (`S_Actor`,
`S_Camera`, `S_HkVehicle`, `S_Trigger` …). Only **`Texture0`** remains — 32,903 bytes, no `Format`
and no `MipZero` either — still reported as broken, because the reader genuinely cannot produce
anything for it and saying otherwise would be a guess about a payload nobody has read.

## What is actually wrong

### 1. Four door meshes do not decode — 18 exports

`LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`, `Atlas_labs_doorAnim`, `GathererDoorAnimMesh`. The
last unreadable skeletal variant; everything else now decodes. The preview shows their skeletons and
says why there is no geometry.

### 2. Multi-material **skeletal** meshes are textured from one material only — 153 exports

**Half of this is fixed and the entry is narrowed accordingly.** A `StaticMesh` carries a section
table, it is now consumed, and section *N* draws with `Materials[N]` on all 8,668 shipped static
meshes. A `SkeletalMesh` naming several materials still draws entirely in one of them.

~~A `SkeletalMesh` carries no such table — whether the container has an equivalent is `UNKNOWN`.~~
**That was wrong and is corrected here: the table exists.** `UnMeshBioshock.cpp`'s
`FStaticLODModelBio` opens with `TArray<FSkelMeshSection>`, nine `uint16`s each, commented
"1 section = 1 material" — see open question 11d and
[reference-comparison.md](research/reference-comparison.md) §3a. So these meshes are open
because **the work is not done, not because the data is missing**: it needs the payload walked from
the front instead of the vertex chain being searched for, and UModel targets the original game, so
every field needs checking against Remastered bytes first.

The diagnostic sweep counts **157** exports in this state (`mesh-materials-without-sections`) — was
153 before the 19 Aug 2026 diagnostic-dispatch fix let more of these meshes' materials resolve
correctly enough to be recognized as genuinely multi-material rather than falling out some other
way. `WP_CrossbowMesh` names `Crossbow_Shader` and
`group_02_mat`; `TommyGunMESH` and `PlasmidEquipMESH` name two each; `PearlsAnim_Mesh` names three.
The preview, the details panel and the Problems panel all say so. See open question 4c, and item 6
under NEXT CLAUDE SESSION in `HANDOFF.md`.

### 3. Three skeletal meshes resolve a material that will not read — 3 distinct

`BeaconBall_Mesh`, `SecCameraSmall`, `SecCameraSmallWall`. The reference resolves, `MaterialReader`
returns nothing. Probably the `MaskMaterial` size problem (open question 10).

**Since fixed, in part:** open question 10 is closed — 13,532 materials, 0 partial — and the security
cameras now resolve, because their `cam_smallcam_shader` lives in `ShockAI.U` and the external
material source reaches it. The sweep reports no `material-unreadable` anywhere in the game, so
whatever remains of this entry no longer reproduces.

### 4. Two meshes decode nonsense UVs — 2 distinct

`BatPath` and `Shadow_Scissors` produce UV values around 6e36. Everything else about them decodes.
Small, isolated, and definitely wrong.

**Still true, and now measured rather than remembered.** `mesh-uv-out-of-range` finds exactly these
two in the whole game — `BatPath` at 428 of 858 vertices, worst component 6.309e+36 — so the check
that would catch a third is in the suite rather than in a scratch probe.

## Checks that fired on correct data

Recorded so the next person does not chase them.

- **`mesh-shattered` (28 distinct).** Flags a median triangle edge over a quarter of the model's
  extent, which catches a wrong index-buffer ordering. It also catches anything legitimately made of
  a few big flat panels. `Gen_Counter_Straight` was rendered and is a correct rounded counter;
  `Seabox` is a box. Raising the threshold to 64 triangles cut this from 207 to 28, and the
  remainder are simple geometry rather than broken geometry.
- ~~**`anim-character-stretched` (3 distinct).** `AggressorBabyJane`'s `PI_Fire`, `PI_Fire_B` and
  `PI_fire_C` show a third of the skeleton off its rest bone lengths — but by a constant amount on
  every frame, including frame 0, which is authored translation rather than a decode drifting. The
  animation was rendered and the splicer is intact and posed correctly.~~
  **This entry was wrong and is corrected here.** A user then photographed `PI_Fire_B` drawing a
  splicer with no arms, and measuring it showed 25 of 54 driven bones folded onto their parents on
  frame 0 — not a constant offset, and not intact. The render that "checked" it did not catch it.
  These three, plus `smg_fire`, are the open fault in `docs/HANDOFF.md` §6.0c, and the audit now
  measures them (`AnimationAudit.WorstCollapse`, `BoneRigidityTests`) instead of dismissing them.
  **A check dismissed as a false positive needs the same evidence as a check acted on.**
- **`anim-prop-translates` (132 distinct).** Fish schools, bats, a sinking engine. A prop rig
  animates bone translation on purpose, so bone length is meaningless there. Separated from the
  character check rather than merged with it, because on a character it is a real signal — it is
  what caught Ryan's speech.
- **`mesh-no-diffuse` (1).** `FireSpread_Mesh` uses `invisible_shader`. Working as intended.
  **Superseded in scale:** the committed check finds 755, and only the 51 with a plain `Shader` are
  candidates for "intended" — the other 704 are material classes the reader does not know, or slots
  naming a texture rather than a shader. See the diagnostic sweep above. The lesson stands: this code
  fires on correct data too, so it is `Degraded` and not `Broken`.

## Keeping these figures honest

**Every headline figure in this document is asserted by a test**, so a number that stops being true
goes red instead of quietly rotting: `tests/BioShockStudio.Tests/DocumentedFiguresTests.cs`, in the
sweep tier. It runs the same whole-game `diagnose` sweep the command below runs and asserts the
coverage counts, the totals by severity, the per-code table and the base-colour share.

This exists because measured numbers get copied into prose by hand and rot immediately: "73.9% of
meshes have a diffuse texture" was stated in three documents and was wrong in all three within one
session, and nothing anywhere could say so.

**A failure there is not automatically a regression.** It means the game as measured no longer
matches what this file claims, and there are two honest responses — the code improved and the figure
should be updated, or the code regressed and the figure is telling you so. Classify it
(`docs/ENGINEERING_RULES.md` §24) before changing either, and **never relax the assertion to make it
pass**: that turns the one mechanism that notices drift into a rubber stamp. When a figure here
changes, change it in the test in the same commit.

## How to re-run it

Both halves are commands in the repository now — the scratch probe is gone:

```bash
dotnet run -c Release --project src/BioShockStudio.Cli -- diagnose --animations --out report.csv
dotnet run -c Release --project src/BioShockStudio.Cli -- audit-animations out.csv
```

`diagnose <package>` scopes it to one package in seconds; `--code <code>` lists every instance of one
finding with its evidence. The same service backs the application's Problems panel, so the window and
the command line cannot disagree about the state of an asset.

The regression tests hold the parts worth keeping permanently — `StaticMeshGeometryTests`,
`SkeletalMeshGeometryTests`, `AnimationContinuityTests`, `TransparencyTests`, `BoneRigidityTests`,
`DiagnosticsTests`, `DiagnosticsUiTests`.
