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
