# Handoff

134/134 tests pass against the installed game.

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
| Materials | `Shader` and `FacingShader` decode; the mesh names its own shader. |
| Blender export | Skinned mesh, armature, actions, sockets, events, materials, weapon attachment. |
| FBX export | Binary 7.4, validated by round trip through Blender. |
| Application services | Installation, catalogue, details, texture preview, extraction. Tested without a window. |
| GUI | Avalonia: game discovery and validation, browse 14,378 distinct assets by category, search, asset details, texture preview, 3D preview with animation playback, extraction queue with progress and cancellation. |
| 3D preview | Software rasteriser in `Core/Rendering`: skinned mesh, base colour, normal and specular maps, skeleton and socket overlays, orbit camera, animation transport. Verified by rendering and asserting on pixels. |
| Asset context | The weapon a hands socket names is resolved, placed on its socket bone and played in sync. `Confirmed` only when the attachment's skeleton root matches the socket bone. |

## Key facts that were expensive to learn

- **Blender rest matrices must be set via `EditBone.matrix`.** Building bones from head/tail lets
  Blender pick its own roll, so the rest basis differs from the game's by up to a full axis flip and
  every animation plays the wrong motion while still looking plausible.
- **Every bone must be keyed in every action** in Blender, including ones the animation does not
  drive, or poses leak between actions. This is a Blender problem specifically: in FBX an unkeyed
  node holds its reference pose, which is already correct, so the exporter does not emit those keys.
- **The mesh index buffer addresses the rigid vertex block first**, though the skinned block is
  stored ahead of it. Every count-based check passes either way; only triangle size distinguishes
  them (median edge 0.87 vs 44.04).
- **Animation channels fall back to the bound bone's reference pose**, not identity — so binding has
  to be resolved *before* decoding.
- **A first-person animation is a two-rig performance.** The hands' `Pistol` socket names bone
  `R_Grip`; the weapon's own skeleton is rooted at `R_grip`; their animations are frame-identical.
  Do not merge the skeletons.
- **FBX has no quaternion channel for a node's rotation.** Every rotation converts to Euler, and the
  order is `Rz · Ry · Rx` on column vectors. A wrong order animates plausibly and wrongly — the same
  failure mode as the Blender rest-matrix bug.
- **One FBX declares one frame rate**, and the shipped animations do not share one (30.00, 29.94 and
  27.02 all occur within the pistol set), so each animation gets its own file.
- **A `SkeletalMesh`'s property list is empty.** Its material reference is in the binary payload,
  after a tag block whose position varies between meshes.
- **The hands use a `FacingShader`, not a `Shader`** — different slot names entirely, so a reader
  that knows only `Diffuse` reports them as having no base colour map.
- Names differ in case between the Havok tables and the Unreal objects (`R_Grip`/`R_grip`).
- Object names are not unique within a package; resolve by class as well.
- **Render everything.** Numeric validation has passed twice while the result was visibly wrong.

## The application

Architecture, categories and what the window does and does not do: `docs/GUI.md`.

The rule that matters: the view model holds no parsing. Everything it shows comes from
`Core/Services`, which is why those are tested without a window and why the browser and the CLI
cannot drift apart. The catalogue decodes no payloads — 14,378 distinct assets across 22 packages in seconds
— and skeletons, textures and materials are resolved only when something is selected.

`WindowTests` renders the real window headlessly with Skia, so every binding resolves during the
test. Do not screen-capture the running app to check it: the capture follows whatever is in front on
the desktop.

## Validation

The `.blend` path:

```bash
blender --background <scene>.blend --python tools/blender/validate_scene.py -- <scene>.json
```

The FBX path — imports the written files back and compares against transforms composed
independently from the game's own track data:

```bash
blender --background --python tools/blender/validate_fbx.py -- <scene>.json <fbx-dir> [rig]
```

Both exit non-zero on failure. Current FBX results: worst rest-matrix error 0.00006 cm, worst posed
bone position error 0.0052 cm, across the hands (47 bones, 10 animations), the pistol (8 bones) and
the Little Sister (60 bones, 138 animations).

Poses are sampled at the keys' own frame positions. Blender lays FBX keys out at its rounded scene
rate, so an animation authored at 27.02 fps has keys on fractional frames and sampling at whole
numbers measures Blender's interpolation, not the file.

## Next, roughly in order

1. **Import into Unreal.** Nothing has been. `tools/ue5/import_bioshock.py` is written from the
   documented API and has never been run. Two things would be settled immediately: whether Unreal
   takes the `SOCKET_*` null nodes as sockets or as bones (`IncludeSocketNodes` turns them off if
   they become bones), and whether the notify API exists under the name that script uses.
2. **Mesh coverage.** ~40% of `SkeletalMesh` decode. `TommyGunMESH`, `WP_GrenadeLauncherMesh`,
   `PlasmidEquipMESH` and `WP_CrossbowMesh` are among the failures — and the same four are the only
   weapon meshes that fail to resolve a material, so it is likely one cause rather than two.
3. **`MaskMaterial` nested struct sizes.** The declared size is one byte short of its content when
   the content holds a sized reference, which stops the shader walk there. Roughly half the shaders
   in the larger packages are reported partial for this reason. Byte evidence for both the working
   and the failing case is in `docs/research/materials.md`.
4. **Companion context.** The hands carry `Gatherer` notifies and sockets, but whether any object
   reference points at a Little Sister *asset* is still unknown. The attachment machinery is in
   place and would show it if such a reference were found.
5. **The game camera.** `PlayerCameraAnim` (2 bones, 56 recoil animations) is decoded but its space
   is not related to the viewmodel's. The exported camera is a preview, explicitly not a
   reconstruction.
6. Remaining weapons and characters through the same path.

## Open unknowns

Recorded in `docs/research/open-questions.md`. The load-bearing ones: what Unreal does with this
export, the `MaskMaterial` size question above, the texture mip array header field, the 16
unexplained bytes before the Havok magic in an `AnimationPackageWrapper`, the two `Unknown32` fields
in every export record, and whether any object reference — as opposed to a socket or notify — points
from a Big Daddy at a Little Sister asset.
