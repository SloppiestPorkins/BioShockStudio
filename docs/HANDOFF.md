# Handoff

**140/140 tests pass against the installed game.** Branch `feature/fbx-materials-gui`, 16 commits
ahead of `master`, tree clean.

```bash
dotnet build && dotnet test
```

Tests read the real install (auto-detected, or set `BIOSHOCK_REMASTERED_PATH`) and skip cleanly if
it is absent. **No game data is in the repository**, and `/artifacts/` is gitignored.

To run the application:

```bash
dotnet publish src/BioShockStudio.App/BioShockStudio.App.csproj -c Release -o artifacts/app
```

Close the app before republishing — a running instance locks the DLLs and the publish fails.

---

## 1. What this project is

A Windows tool for extracting BioShock 1 Remastered's skeletal meshes, skeletons, Havok animation
and materials into Blender and FBX. It is both an extraction tool and a reverse-engineering
notebook: `docs/research/` records what is known about the formats, with confidence labels, and the
code refuses to guess where the notes say `UNKNOWN`.

The target case, and the thing to check after any change to the pipeline: **the first-person pistol**
— hands, weapon, skeletons, correct animations, sockets, materials, textures, out to FBX.

## 2. What works

| Layer | State |
|---|---|
| `.bsm` packages | All 21 parse byte-exact. 812,435 exports indexed. |
| `ShockGame.U` | Parses byte-exact too — holds the first-person weapon viewmodels. |
| Havok packfile, fixups, object graph | Complete. |
| `AnimationPackageRoot` | Decoded — the class UEViewer reports as unknown. |
| `hkaSkeleton`, `hkaAnimationBinding` | Complete, original bone indices preserved. |
| `hkaSplineCompressedAnimation` | Complete. 130/130 hands animations decode. |
| `SkeletalMesh` | Header, sockets, bone map, geometry, skin weights, tangent basis. **~40% of meshes decode to geometry.** |
| `StaticMesh` | **Not read at all.** See §6.1. |
| Animation events | `SharedSkeletonAnimationMetadata` → (time, notify) pairs. |
| Materials | `Shader` and `FacingShader`; a mesh's material list is a counted array. |
| Textures | DXT1/3/5, RGBA8 → PNG + DDS. 1054/1062 in 0-Lighthouse. |
| Blender export | Skinned mesh, armature, actions, sockets, events, materials, weapon attachment. |
| FBX export | Binary 7.4, validated by round trip through Blender. |
| Unreal import | **Never attempted.** See §6.4. |
| Application | Discovery, browse 14,378 distinct assets, search, details, texture preview, 3D preview with animation playback and weapon attachment, extraction queue. |

## 3. Architecture

```
BioShockStudio.App          window and view models — no format knowledge, no parsing
        ↓
Core/Services               application services, tested without a window
        ↓
Core                        Packages, Havok, Mesh, Materials, Textures, Skeleton, Animation
        ↓
Core/Export, Core/Rendering scene JSON, FBX, PNG/DDS; the preview rasteriser
```

The view model holds no parsing and no output-path decisions. That is what lets the services be
tested without a window, and what stops the browser and the CLI disagreeing about what an asset is.
`docs/GUI.md` covers the application in detail.

**Never put format knowledge in a view model.** If the window needs to know something about the
data, the service should tell it.

## 4. Landmines — things that cost real time to find

Each of these produced a plausible, wrong result before it was understood.

- **Blender rest matrices must be set via `EditBone.matrix`.** Building bones from head/tail lets
  Blender pick its own roll, so the rest basis differs from the game's by up to a full axis flip and
  every animation plays the wrong motion while still looking fine.
- **Every bone must be keyed in every Blender action**, including undriven ones, or poses leak
  between actions. FBX does not need this — an unkeyed node holds its reference pose, which is
  already correct.
- **The mesh index buffer addresses the rigid vertex block first**, though the skinned block is
  stored ahead of it. Every count-based check passes either way; only triangle size distinguishes
  them (median edge 0.87 against 44.04).
- **Animation channels fall back to the bound bone's reference pose**, not identity — binding must
  be resolved *before* decoding.
- **A first-person animation is a two-rig performance.** The hands' `Pistol` socket names bone
  `R_Grip`; the weapon's skeleton is rooted at `R_grip`; their animations are frame-identical. Do
  not merge the skeletons.
- **FBX has no quaternion channel for a node's rotation.** Every rotation converts to Euler, order
  `Rz · Ry · Rx` on column vectors. A wrong order animates plausibly and wrongly.
- **One FBX declares one frame rate**, and the shipped animations do not share one — 30.00, 29.94
  and 27.02 all occur within the pistol set — so each animation gets its own file.
- **A `SkeletalMesh`'s property list is empty.** Its material reference is in the binary payload,
  after a tag block whose position varies between meshes (64 in `NEWPlayerHands`, 54 in
  `WP_PistolMesh`), so the block is found by search.
- **A mesh's material reference is a counted array, not one reference.** The count was recorded as a
  fixed `byte 1`; meshes with two materials read `2` and lost their second.
- **The hands use a `FacingShader`, not a `Shader`** — no `Diffuse` at all; the base colour is in
  `FacingDiffuse` and `EdgeDiffuse`.
- **Every map embeds its own copy of what it uses.** The catalogue is five times larger than the set
  of distinct assets (71,106 rows for 14,378 things) unless collapsed.
- Names differ in case between the Havok tables and the Unreal objects (`R_Grip` / `R_grip`).
- Object names are not unique within a package; resolve by class as well.
- **Render everything.** Numeric validation has passed while the result was visibly wrong, more than
  once. Three features in the last session were implemented, tested, and invisible — a column
  squeezed to zero width, an error message never displayed, and a zoom whose wheel event was eaten
  by a `ScrollViewer`. None were findable from the code.

## 5. Validation

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
rate, so an animation authored at 27.02 fps has keys on fractional frames; sampling at whole numbers
measures Blender's interpolation, not the file.

Pictures of the window and the viewport, rendered offscreen:

```bash
BIOSHOCK_UI_SNAPSHOT=/tmp/ui.png dotnet test --filter FullyQualifiedName~WindowTests
BIOSHOCK_RENDER_SNAPSHOT=/tmp/r.png dotnet test --filter FullyQualifiedName~RenderingTests
BIOSHOCK_CONTEXT_SNAPSHOT=/tmp/c.png dotnet test --filter FullyQualifiedName~ContextTests
```

**Do not screen-capture the running application to check it.** The capture follows whatever is in
front on the desktop, not the window you meant — this went wrong once and caught the user's browser.

## 6. What to do next, in priority order

### 6.1 A `StaticMesh` geometry reader — highest value

This one reader unblocks the most assets. `docs/research/context.md` records that sockets point at
three different kinds of thing, and this is the second:

```
NewProtectorBouncer sockets   Drill -> SocketDrillROTATION
                              DrillCage -> SocketDrillBase
                              backpack -> SocketBackpack
NewProtectorBouncer group     ConeDrill, ConeDrillCage, ConeDrillBackpack   (all StaticMesh)
```

Three sockets, three static meshes in the host's own group, names mapping one to one. The same shape
gives Baby Jane her wig and the hands their photo and wallet. `WP_WrenchMesh` is a `StaticMesh` too —
the wrench has no moving parts, so it ships as a static prop rather than a rig.

**The relationship is already established in the data. What is missing is vertices.**
`SkeletalMeshReader.ReadGeometry` returns nothing for `ConeDrill`, as it does for `WP_WrenchMesh`.

**How to start:** dump `ConeDrill`'s payload beside `WP_PistolMesh`'s. The skeletal container is a
chain of `FCompactIndex`-counted arrays (bone map, indices, then vertex blocks); a static mesh has no
bone map or skin weights, so expect a shorter chain and a smaller vertex stride.

### 6.2 The skeletal geometry variant

~60% of `SkeletalMesh` exports yield no geometry. `TommyGunMESH`, `WP_GrenadeLauncherMesh` and
`PlasmidEquipMESH` are the visible ones — they attach, animate and resolve materials, and draw
nothing.

`ReadGeometry` locates the vertex chain **by search**, requiring tangent, binormal and normal to all
be unit length at +12/+24/+36 with a 64- or 57-byte stride. A mesh that yields nothing means no
candidate satisfied every constraint at once, which points at **a different vertex stride** rather
than a different offset — an extra UV set or a compressed format.

Note that the earlier claim that these failed geometry *and* materials "for one shared cause" was
**wrong**. The materials were the counted array; the geometry is unrelated.

### 6.3 Socket matching, kind three — a small win

`ProtectorRosie` declares `RivetGunSocket -> Dummy_GunParent` and her weapon is the separate group
`WP_AI_RivetGun`. `SecurityBot` and the turrets are the same shape. `AssetContextService.BestGroupFor`
does not strip the `Socket` suffix before matching, so it misses them. Stripping it should light up
the rivet gun and the bot weapons immediately.

### 6.4 Verify the Unreal import

**Nothing has ever been imported into Unreal Engine 5.** `tools/ue5/import_bioshock.py` is written
from the documented API and has never been run; it says so at the top. Two things would be settled by
one import:

- whether Unreal takes the `SOCKET_*` null nodes as sockets or as **bones** (if the imported skeleton
  shows 66 bones instead of 47, that is it — `FbxExportOptions.IncludeSocketNodes` turns them off);
- whether the notify API exists under the name that script uses.

Until then the UI deliberately offers no "UE5" export, because that would claim a verification that
does not exist.

### 6.5 `MaskMaterial` nested struct sizes

Roughly half the shaders in the larger packages stop early. The walk always loses alignment
immediately after a `MaskMaterial` struct **whose nested list contains a sized reference**: the
declared size is one byte short of its content. Byte evidence for both the working and the failing
case is in `docs/research/materials.md`. The reader stops cleanly and flags the material `Truncated`
rather than inventing properties.

### 6.6 Smaller things

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
4. **Label confidence** — `CONFIRMED_BYTES`, `CONFIRMED_EXTERNAL`, `CORROBORATED`, `LIKELY`,
   `HYPOTHESIS`, `UNKNOWN` — and never present an inference as a fact. Every relationship the UI
   shows carries how it was established.
5. **Fail honestly.** A mesh in an unsupported variant says so in the user's terms; a bulk extraction
   records every failure and keeps going; a partial material is reported as partial.
6. **Correct the record when you are wrong.** Two claims in these notes have been overturned by
   later evidence — `HkMeshProxy` being a material link, and the geometry/material failures sharing
   a cause. Both corrections are recorded where the wrong claim was.

## 8. Open unknowns

`docs/research/open-questions.md`, in priority order. The load-bearing ones: what Unreal does with
this export, the `StaticMesh` container, the skeletal geometry variant, the `MaskMaterial` size, the
texture mip array header field, the 16 unexplained bytes before the Havok magic in an
`AnimationPackageWrapper`, the two `Unknown32` fields in every export record, and whether any object
reference — as opposed to a socket or notify — points from a Big Daddy at a Little Sister asset.

## 9. Reading order for a new session

1. This file.
2. `docs/research/README.md` — the index and the confidence labels.
3. `docs/GUI.md` — if touching the application.
4. The research note for whatever you are about to work on: `skeletalmesh.md`, `materials.md`,
   `fbx.md`, `context.md`, `binding.md`, `havok-compression.md`.
