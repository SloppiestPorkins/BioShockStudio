# Handoff

**184/184 tests pass against the installed game.** Branch `feature/fbx-materials-gui`, 23 commits
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
| `SkeletalMesh` | Header, sockets, bone map, geometry, skin weights, tangent basis. **954/972 exports decode (98.1%)** — the 18 that do not are all doors. |
| `StaticMesh` | Geometry, UV streams, indices. **All 8,668 shipped exports decode.** |
| Animation events | `SharedSkeletonAnimationMetadata` → (time, notify) pairs. |
| Materials | `Shader` and `FacingShader`; a mesh's material list is a counted array. |
| Textures | DXT1/3/5, RGBA8 → PNG + DDS, alpha preserved. 1054/1062 in 0-Lighthouse. |
| Transparency | The viewport cuts out holes and blends translucent surfaces, from the texture's own alpha. |
| Blender export | Skinned mesh, armature, actions, sockets, events, materials, weapon attachment. |
| FBX export | Binary 7.4, validated by round trip through Blender. |
| Unreal import | **Never attempted.** See §6.4. |
| Attachments | All three socket kinds resolve: weapon rigs, static props in the host's own group, and `*Socket`-suffixed names. |
| Weapon viewmodels | All ten in `ShockGame.U` decode and draw, textured. |
| Animation sets | A character's animations carry the game's own set — Melee, Pistol, Ceiling — and the UI filters by it. |
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
- **A `StaticMesh` vertex has no UV in it.** 48 bytes of position and tangent basis, and the UVs
  follow in separate full-length streams. Writing the reader by analogy with the skeletal record —
  where the UV sits at +48 — puts the next vertex's position where the UVs should be.
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
  Rejecting that zero is what kept every weapon viewmodel undrawable — 38.1% of skeletal meshes
  decoded, now 98.1% — while their sockets, skeletons, animations and materials all resolved, so
  nothing looked broken except the empty viewport.
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
- **A long animation is not just a longer short one.** Two spline-sampling faults were invisible on
  the hands, whose animations fit in a single block, and folded Ryan's chest into his legs on a
  2,613-frame speech. Test something with ten blocks in it.
- **Measure animation on the bones the mesh actually uses.** `Ryan` has 131 bones and 98 are skinned;
  `Dummy02` and `putterPLACEHOLDER` carry his golf club, move freely, and dominate every statistic
  taken over all bones. They are never drawn.
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
BIOSHOCK_STATIC_SNAPSHOT=/tmp/s.png dotnet test --filter FullyQualifiedName~Static_Snapshot
BIOSHOCK_BOUNCER_SNAPSHOT=/tmp/b.png dotnet test --filter FullyQualifiedName~Bouncer_Snapshot
```

The last writes one image per static mesh (`/tmp/s_ConeDrill.png` and so on). The drill should be a
conical auger and the kerosene pickup a canister with a valve wheel and a cage; anything that is not
a recognisable object means the geometry chain landed somewhere plausible and wrong.

**Do not screen-capture the running application to check it.** The capture follows whatever is in
front on the desktop, not the window you meant — this went wrong once and caught the user's browser.

## 6. What to do next, in priority order

### 6.1 Where a `StaticMesh` names its material — highest value

Of 630 meshes that draw in `1-Medical`, only **22 resolve a diffuse texture**. The Bouncer's body is
textured; its drill, cage and backpack draw flat grey, and so does most of the world.

`MaterialReader.ReadMeshMaterialReferences` finds a mesh's material by searching for the tag block
`int32 4, int32 5, byte 1`. **A static mesh does not have that tag block** — its equivalent is
`int32 4, int32 8, int32 1`, and no material reference follows it. Unlike a skeletal mesh, whose
property list is empty, a static mesh has a real one holding `Materials`, and that walk currently
ends `truncated`, on a numbered `None`.

`docs/research/materials.md` has the byte evidence, including a candidate reading of `ConeDrill`'s
`Materials` value that resolves to `ConeDrillRimShader`, a `FacingShader` — right class, right name.
It is recorded as suggestive and **nothing has been changed on the strength of it**, because the
surrounding bytes are identical across three different meshes, which means the walk is misaligned
and that offset is probably an artefact.

**How to start:** hand-decode a static mesh's property list from offset 8 and find where alignment is
lost. It may be the same cause as §6.5.

This also gates transparency: a mesh with no material has no texture, so it has no alpha either.

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

### 6.3 Socket matching, kind three — done

`BestGroupFor` now strips a trailing `Socket` before matching, so `ProtectorRosie`'s
`RivetGunSocket` reaches `WP_AI_RivetGun`; `SecurityBot` and the turrets are the same shape. The
hands' attachments are unaffected — the pistol is still `Confirmed` by the root-bone test, which
outranks anything matched by name alone.

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

### 6.6 Attachment placement under animation

Static props resolve and draw, but on the socket bone's *rest* transform, so a prop stays where the
bind pose put it while the host moves. The first-person set already solves this for a skeletal
attachment — see `ContextTests.Render_ContextSnapshot`, which poses host and weapon together at
frame 27 — so the work is feeding the host's posed bone matrix to a static prop's `PreviewInstance`
instead of `RestGlobal`, and carrying the same into the FBX as a parent constraint.

Placement itself is verified: on the hands, `CS_butt` lands at the left fingertips and `CS_photo` at
the right hand, with no offset beyond the socket bone's global transform.

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
this export, the static mesh's trailing collision block, the skeletal geometry variant, the
per-material triangle sections a multi-material static mesh must have, the `MaskMaterial` size, the
texture mip array header field, the 16 unexplained bytes before the Havok magic in an
`AnimationPackageWrapper`, the two `Unknown32` fields in every export record, and whether any object
reference — as opposed to a socket or notify — points from a Big Daddy at a Little Sister asset.

## 9. Reading order for a new session

1. This file.
2. `docs/research/README.md` — the index and the confidence labels.
3. `docs/GUI.md` — if touching the application.
4. The research note for whatever you are about to work on: `skeletalmesh.md`, `staticmesh.md`,
   `materials.md`, `fbx.md`, `context.md`, `binding.md`, `havok-compression.md`.
