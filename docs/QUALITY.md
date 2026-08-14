# Quality pass

A sweep of every mesh and every animation the game ships, looking for anything that does not come
out right.

The animation half is now a committed, repeatable command rather than a one-off probe:

```bash
dotnet run -c Release --project src/BioShockStudio.Cli -- audit-animations out.csv
```

`src/BioShockStudio.Core/Diagnostics/AnimationAudit.cs`, tested by
`tests/BioShockStudio.Tests/AnimationAuditTests.cs`. The mesh half is still the older probe.

**Scope:** 21 map packages plus `ShockGame.U` — 9,672 mesh exports and 16,025 animations across 880
animation packages.

Every check is objective. Nothing here judges whether something "looks" right; each one reports a
fact that can only be true of a broken result — a decode that failed, a non-finite vertex, an index
out of range, a skeleton whose bones changed length. Where a check turned out to flag correct data,
that is recorded rather than the check being quietly dropped.

## Headline

| | Total | Good | |
|---|---|---|---|
| Meshes decoded | 9,672 | **9,654** | 99.8% |
| Animations decoded | 16,025 | **16,025** | 100% |
| Meshes with a resolved diffuse texture | 9,672 | **7,146** | 73.9% |

Geometry and animation are essentially complete, and materials have gone from 7.0% to 73.9% —
a `StaticMesh` names its material in its own `Materials` property, which is now read. See
[research/materials.md](research/materials.md).

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

## What is actually wrong

### 1. Four door meshes do not decode — 18 exports

`LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`, `Atlas_labs_doorAnim`, `GathererDoorAnimMesh`. The
last unreadable skeletal variant; everything else now decodes. The preview shows their skeletons and
says why there is no geometry.

### 2. Multi-material meshes are textured from the first material only — 28 distinct

`WP_CrossbowMesh` names `Crossbow_Shader` and `group_02_mat`; `TommyGunMESH` and `PlasmidEquipMESH`
name two each; `PearlsAnim_Mesh` names three. Which triangles use which is not decoded, so part of
each mesh is textured wrongly. The preview and the details panel now say so. See open question 4c.

### 3. Three skeletal meshes resolve a material that will not read — 3 distinct

`BeaconBall_Mesh`, `SecCameraSmall`, `SecCameraSmallWall`. The reference resolves, `MaterialReader`
returns nothing. Probably the `MaskMaterial` size problem (open question 10).

### 4. Two meshes decode nonsense UVs — 2 distinct

`BatPath` and `Shadow_Scissors` produce UV values around 6e36. Everything else about them decodes.
Small, isolated, and definitely wrong.

## Checks that fired on correct data

Recorded so the next person does not chase them.

- **`mesh-shattered` (28 distinct).** Flags a median triangle edge over a quarter of the model's
  extent, which catches a wrong index-buffer ordering. It also catches anything legitimately made of
  a few big flat panels. `Gen_Counter_Straight` was rendered and is a correct rounded counter;
  `Seabox` is a box. Raising the threshold to 64 triangles cut this from 207 to 28, and the
  remainder are simple geometry rather than broken geometry.
- **`anim-character-stretched` (3 distinct).** `AggressorBabyJane`'s `PI_Fire`, `PI_Fire_B` and
  `PI_fire_C` show a third of the skeleton off its rest bone lengths — but by a constant amount on
  every frame, including frame 0, which is authored translation rather than a decode drifting. The
  animation was rendered and the splicer is intact and posed correctly.
- **`anim-prop-translates` (132 distinct).** Fish schools, bats, a sinking engine. A prop rig
  animates bone translation on purpose, so bone length is meaningless there. Separated from the
  character check rather than merged with it, because on a character it is a real signal — it is
  what caught Ryan's speech.
- **`mesh-no-diffuse` (1).** `FireSpread_Mesh` uses `invisible_shader`. Working as intended.

## How to re-run it

The audit lives in the scratch probe rather than the repository, because it is a diagnostic rather
than a feature. What it does is described above in enough detail to rebuild: walk every export,
decode with `MeshGeometryReader` and `AnimationPackage.Decode`, and apply the checks. The
regression tests hold the parts worth keeping permanently — `StaticMeshGeometryTests`,
`SkeletalMeshGeometryTests`, `AnimationContinuityTests`, `TransparencyTests`.
