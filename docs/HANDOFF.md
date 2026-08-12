# Handoff

State as of commit `57220e9`. 78/78 tests pass against the installed game.

```bash
dotnet build && dotnet test
```

Tests read the real install (auto-detected, or set `BIOSHOCK_REMASTERED_PATH`) and skip if absent.
No game data is in the repo.

## What works

| Layer | State |
|---|---|
| `.bsm` packages | All 21 parse byte-exact. 812,435 exports indexed. |
| `ShockGame.U` | Parses byte-exact too — holds the first-person weapon viewmodels. |
| Havok packfile, fixups, object graph | Complete. |
| `AnimationPackageRoot` | Decoded — the class UEViewer reports as unknown. |
| `hkaSkeleton`, `hkaAnimationBinding` | Complete, original bone indices preserved. |
| `hkaSplineCompressedAnimation` | Complete. 130/130 hands animations decode. |
| `SkeletalMesh` | Header, sockets, bone map, geometry, skin weights. ~40% of meshes decode. |
| Animation events | `SharedSkeletonAnimationMetadata` → (time, notify) pairs. |
| Asset context | `Package` objects are the game's own grouping. |
| Textures | DXT1/3/5, RGBA8 → PNG + DDS. 1054/1062 in 0-Lighthouse. |
| Blender export | Skinned mesh, armature, actions, sockets, events, weapon attachment. |
| GUI | Avalonia: browse by category, search, extract with progress and cancel. |

## Key facts that were expensive to learn

- **Blender rest matrices must be set via `EditBone.matrix`.** Building bones from head/tail lets
  Blender pick its own roll, so the rest basis differs from the game's by up to a full axis flip and
  every animation plays the wrong motion while still looking plausible.
- **Every bone must be keyed in every action**, including ones the animation does not drive, or
  poses leak between actions.
- **The mesh index buffer addresses the rigid vertex block first**, though the skinned block is
  stored ahead of it. Every count-based check passes either way; only triangle size distinguishes
  them (median edge 0.87 vs 44.04).
- **Animation channels fall back to the bound bone's reference pose**, not identity — so binding has
  to be resolved *before* decoding.
- **A first-person animation is a two-rig performance.** The hands' `Pistol` socket names bone
  `R_Grip`; the weapon's own skeleton is rooted at `R_grip`; their animations are frame-identical.
  Do not merge the skeletons.
- Names differ in case between the Havok tables and the Unreal objects (`R_Grip`/`R_grip`).
- Object names are not unique within a package; resolve by class as well.
- **Render everything.** Numeric validation has passed twice while the result was visibly wrong.

## Validation

```bash
blender --background <scene>.blend --python tools/blender/validate_scene.py -- <scene>.json
```

Checks rest matrices and posed bone positions against transforms composed independently from the
game's own track data. Exits non-zero on failure.

## Next, roughly in order

1. **FBX / UE5 export.** The intermediate representation already carries skeleton, bone indices,
   sockets, timing, skin weights and events. Nothing has been imported into UE5 yet, so no claim
   about it holds.
2. **Materials.** `Shader` objects (12,566 of them) are unparsed, so meshes export untextured even
   though the textures extract fine. `HkMeshProxy` (8,961) is also unexamined and may link mesh to
   material.
3. **Mesh coverage.** ~40% of `SkeletalMesh` decode; failures are effect and prop meshes, likely a
   vertex stride or container variant. `TommyGunMESH`, `WP_GrenadeLauncherMesh` and
   `PlasmidEquipMESH` are among them.
4. **GUI preview.** It browses and extracts; there is no 3D or animation view.
5. **The game camera.** `PlayerCameraAnim` (2 bones, 56 recoil animations) is decoded but its space
   is not related to the viewmodel's. The exported camera is a preview, explicitly not a
   reconstruction.
6. Remaining weapons and characters through the same path.

## Open unknowns

Recorded in `docs/research/open-questions.md`. The load-bearing ones: the texture mip array header
field, the 16 unexplained bytes before the Havok magic in an `AnimationPackageWrapper`, the two
`Unknown32` fields in every export record, and whether any object reference — as opposed to a
socket or notify — points from a Big Daddy at a Little Sister asset.
