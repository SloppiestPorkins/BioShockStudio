# FBX export

**Implementation:** `src/BioShockStudio.Core/Export/Fbx/`, `src/BioShockStudio.Core/Export/FbxExporter.cs`
**Tests:** `tests/BioShockStudio.Tests/FbxExportTests.cs`, `tools/blender/validate_fbx.py`
**Status:** written and validated by round trip. **Not yet imported into Unreal.**

This document is about a format we write rather than one we read, so its confidence labels mean
something slightly different: `CONFIRMED_BYTES` here means the file was written, read back by an
independent implementation, and the numbers matched.

## Why binary 7.4 and not ASCII

`CONFIRMED_EXTERNAL`. Blender's importer refuses ASCII FBX outright. Blender is the only independent
reader available to this project, so ASCII would have meant shipping an exporter that nothing here
could check. Unreal's importer prefers binary as well.

The container framing — record end offsets, the 13-byte null terminator and the rules for when a
record carries one — is taken from Blender's `io_scene_fbx/encode_bin.py`, which is the reference
implementation this exporter is checked against.

Two details are easy to get wrong and produce a file no reader will open:

- Every record header stores its own **absolute end offset**, so array payloads have to be
  compressed before any of it is written. The writer therefore encodes each property when it is
  added, not when it is written.
- A record with no children still needs the null terminator when it has no properties and is not the
  last in its list, and `AnimationStack` and `AnimationLayer` always need one.

`FbxWriter` asserts that each record's write ends exactly on the offset the size pass predicted.

## What one export produces

```
<out>/
  UAPW_NEWPlayerHands.fbx                          mesh, skeleton, sockets, bind pose
  UAPW_NEWPlayerHands_Animations/*.fbx             one file per animation
  UAPW_WP_Pistol.fbx                               the weapon, its own rig
  UAPW_WP_Pistol_Animations/*.fbx
  ue5_manifest.json
```

**One animation per file is not a convenience.** An FBX declares a single frame rate, and the
shipped animations do not share one — within the ten pistol animations alone, `FastReloadPistol` is
30.00 fps, `ZoomedInFidgetPistol` is 29.94 and `ZoomingOutPistol` is 27.02. Baking them into one
file would force a resample and quietly change the timing of two of them. Each file declares
`TimeMode` 14 (`eCustom`) with its animation's own `CustomFrameRate`.

## Conventions

`CONFIRMED_BYTES`.

| | Value | Why |
|---|---|---|
| Units | centimetres, unscaled | The game authors in centimetres and so does Unreal. `UnitScaleFactor` is 1. |
| Axes | Z up, -Y front, X right | The game's own basis. `UpAxis` 2, `FrontAxis` 1 with sign -1, `CoordAxis` 0. |
| Node transform | `Lcl Translation`, `Lcl Rotation`, `Lcl Scaling` | All pivots and pre/post rotations left at zero, so the node transform is exactly T·R·S. |
| Inherit type | 0 (`eInheritRrSs`) | A child's world transform is the plain product of the chain, matching how the scene JSON composes. |
| Rotation order | 0 (`eEulerXYZ`) | The only order written. |

### The Euler conversion is the load-bearing part

`CONFIRMED_BYTES`. FBX has **no quaternion channel** for a node's local rotation, so every rotation
in the game data — reference poses and every animation key — has to be converted to Euler angles.
With rotation order `eEulerXYZ` the composed rotation is

```
R = Rz(z) · Ry(y) · Rx(x)          on column vectors — X is applied first
```

Getting that order wrong yields a rig that still animates, still deforms the mesh and still has the
right timing, and is simply the wrong motion — the same failure mode as the Blender rest-matrix bug.
`FbxExportTests.EulerConversion_RecomposesEveryBoneRotationExactly` recomposes the angles back into
a matrix and compares against the quaternion's, over every real bone rotation.

Consecutive keys are also forced onto the same Euler branch. Every rotation has two Euler solutions
plus whole turns of each angle, and two adjacent frames that pick different ones describe the same
poses but interpolate through a spin between them.

### Skin binding

`CONFIRMED_BYTES`. The mesh sits at the origin of skeleton space, so for each cluster:

```
TransformLink = the bone's reference-pose matrix in skeleton space
Transform     = its inverse
```

That is the convention Blender's importer reads back (`mesh_matrix = tx_bone @ tx_mesh`), and the
test asserts the two matrices cancel to the identity.

### Sockets

`LIKELY`. Each socket is a null node parented to its bone, named `SOCKET_<name>`. Blender imports
these as empties, which is what a socket is.

`UNKNOWN`: what Unreal's **skeletal mesh** importer does with them. The `SOCKET_` convention is
documented for static meshes; a skeletal mesh takes its sockets from the Skeleton asset. If Unreal
treats the nulls as bones it will add nineteen junk bones to the hands skeleton, so the exporter has
`IncludeSocketNodes` to turn them off, and the manifest lists the sockets either way.

### Mirrored reference transforms survive here

`CONFIRMED_BYTES`, and an improvement on the `.blend` path. A Blender bone matrix must be a proper
rotation, so a bone whose reference transform carries a -1 scale axis — `Bip01_L_Toe0Nub` on the
Little Sister — has its mirror stripped when the `.blend` is built. FBX stores scale as its own
channel, so the exported node carries the game's transform unchanged.

## What FBX cannot carry, and where it goes instead

The manifest (`ue5_manifest.json`) holds what has no place in an FBX:

- **Animation notifies.** The reload beats, equip points and Little Sister interaction events, with
  their times and the game's own notify class names. 122 of the Little Sister's 138 animations carry
  them.
- **The attachment relationship.** Which socket a weapon rig hangs off, and on which bone. The rigs
  stay separate files, because a first-person animation is a two-rig performance and merging the
  skeletons would destroy it.
- **Animation pairing.** Which weapon animation plays with which hand animation. `HEURISTIC`:
  matched on longest shared name prefix, with short matches rejected. What is actually proven is
  that the frame counts match exactly; nothing in the data names the partner.

## Validation

```bash
blender --background --python tools/blender/validate_fbx.py -- <scene>.json <fbx-dir> [rig]
```

Blender is used only as an independent reader. The script imports the written files with the FBX's
own declared axes and compares against transforms composed from the scene JSON:

| Check | What a failure would mean |
|---|---|
| Armature object transform is a pure uniform scale | The declared up/front axes disagree with the data. |
| Bone rest matrices | Wrong Euler order, or a wrong reference-pose composition. |
| Vertex positions, counts, skin weights | Wrong geometry container or bone map. |
| Posed bone positions at the start, middle and end of every animation | Wrong track binding or key times. |

Results, against the installed game:

| Rig | Bones | Vertices | Animations | Worst rest error | Worst posed error |
|---|---|---|---|---|---|
| `NEWPlayerHands` (pistol set) | 47 | 4,852 | 10 | 0.00006 cm | 0.0017 cm |
| `WP_PistolMesh` | 8 | 3,736 | 2 | 0.00003 cm | 0.000008 cm |
| `GathererGirl` (Little Sister) | 60 | 5,495 | 138 | 0.00003 cm | 0.0052 cm |

Poses are sampled at the keys' own frame positions rather than at whole frames. Blender lays FBX
keys out on its own frame axis at the scene's rounded rate, so an animation authored at 27.02 fps
has its keys on fractional frames; sampling those at whole numbers measures Blender's interpolation
rather than the file, and showed 0.055 cm of error that was not there.

The rendered result was also looked at, per the project's rule that numeric validation has passed
twice while the result was visibly wrong: both forearms, both hands and the revolver in the right
hand, positioned and oriented at the grip.

## Unreal

`UNKNOWN`. **Nothing has been imported into Unreal Engine 5.** `tools/ue5/import_bioshock.py` is
written from the documented API and has never been run; no editor was available. It is marked as
such at the top of the file. Any claim about Unreal in this repository is a claim about what the
files declare, not about what Unreal does with them.


## Naming

Files and folders are named after the **asset**, not after the export the scene was built from.

A rig's scene comes from the animation package wrapper, whose object name carries the game's
internal `UAPW_` prefix — so the whole output tree used to be named `UAPW_NEWPlayerHands.fbx`,
`UAPW_NEWPlayerHands_Animations/` and so on. The prefix is bookkeeping, not part of what the asset
is called, and it has no business in an export someone else opens. The wrapper's real name is kept
in the manifest as each rig's `sourceObject`, so nothing is lost.

```
NEWPlayerHands.fbx
NEWPlayerHands_Animations/   one file per animation, each with its own frame rate
Textures/                    PNGs the material binds
ue5_manifest.json            notifies, sockets, attachment pairing — what FBX cannot carry
```

A static mesh exports the same way, minus the animation folder and the skeleton.
