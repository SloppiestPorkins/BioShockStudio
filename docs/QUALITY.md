# Quality pass

A sweep of every mesh and every animation the game ships, looking for anything that does not come
out right. Run with the `Audit` probe against the installed game.

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
| Meshes with a resolved diffuse texture | 9,672 | 680 | **7.0%** |

Geometry and animation are essentially complete. **Materials are the one large gap left**, and it is
one cause: a `StaticMesh` names its material somewhere the current search cannot see.

## What is actually wrong

### 1. Static meshes have no material — 2,354 distinct meshes

The dominant defect by two orders of magnitude. Most of the world draws flat grey.

`MaterialReader` finds a mesh's material by searching for the skeletal tag block
`int32 4, int32 5, byte 1`; a static mesh's is `int32 4, int32 8, int32 1` and carries no material
reference after it. Its `Materials` array property is the right place to look and the property walk
ends truncated there.

Scanning every offset inside that property value for an `FCompactIndex` that resolves to a
`Shader` or `FacingShader` finds one at value offset 16 on **71.3%** of meshes — and 71.3% is not a
field, it is a coincidence rate. Nothing has been changed on the strength of it. See
[research/materials.md](research/materials.md) and open question 10b.

### 2. Four door meshes do not decode — 18 exports

`LowRentDoor_Mesh`, `Sliding512SingleDoorMesh`, `Atlas_labs_doorAnim`, `GathererDoorAnimMesh`. The
last unreadable skeletal variant; everything else now decodes. The preview shows their skeletons and
says why there is no geometry.

### 3. Multi-material meshes are textured from the first material only — 28 distinct

`WP_CrossbowMesh` names `Crossbow_Shader` and `group_02_mat`; `TommyGunMESH` and `PlasmidEquipMESH`
name two each; `PearlsAnim_Mesh` names three. Which triangles use which is not decoded, so part of
each mesh is textured wrongly. The preview and the details panel now say so. See open question 4c.

### 4. Three skeletal meshes resolve a material that will not read — 3 distinct

`BeaconBall_Mesh`, `SecCameraSmall`, `SecCameraSmallWall`. The reference resolves, `MaterialReader`
returns nothing. Probably the `MaskMaterial` size problem (open question 10).

### 5. Two meshes decode nonsense UVs — 2 distinct

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
