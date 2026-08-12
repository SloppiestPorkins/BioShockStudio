# BioShock 1 Remastered Model Studio

A Windows reverse-engineering and asset-extraction tool for **BioShock 1 Remastered only**, aimed at
recovering skeletal meshes, skeletons, skinning, Havok animation data and first-person viewmodel
assets in a form Blender and Unreal Engine 5 can use.

The target case is the first-person pistol: find it, resolve its hands, skeleton, animation package,
animations, sockets and materials automatically, decode the Havok data, bind it correctly, and
export something that plays back correctly in UE5.

## Status

**A shipped package goes in and a skinned, textured, animated Blender file or FBX set comes out.**
The first-person hands mesh, its skeleton, its weapon sockets, its material and all 130 animations
extract and play correctly. The FBX is validated by importing it back and comparing against the
game's own transforms; it has not yet been imported into Unreal.

| Area | State |
|---|---|
| `.bsm` package format | Complete. All 21 shipped packages parse byte-exact. |
| Asset index | Complete: 812,435 exports indexed. |
| Havok packfile, fixups, object graph | Complete. |
| `AnimationPackageRoot` | Complete — the class UEViewer reports as unknown. |
| `hkaSkeleton` | Complete, original bone indices preserved. |
| `hkaAnimationBinding` | Complete, from Havok's own track-to-bone array. |
| Spline decompression | Complete. 130/130 animations decode, zero failures. |
| `SkeletalMesh` | Header, sockets, bone map, geometry, skin weights. ~40% of meshes decode. |
| Materials | `Shader` and `FacingShader` decode; a mesh names its own shader in its payload. |
| Blender export | Complete: skinned mesh, armature, actions, sockets, materials. |
| FBX export | Complete: binary 7.4, validated by round trip through Blender. |
| UE5 import | Files written and a helper script exists; **nothing has been imported into UE5 yet**. |
| GUI, viewport preview | Not started. |

See [docs/research/](docs/research/) for the evidence behind every claim and
[docs/research/open-questions.md](docs/research/open-questions.md) for what is still unknown.

## Building

```bash
dotnet build
```

```bash
dotnet test
```

The tests read the installed game directly — there are no synthetic fixtures. They auto-detect a
Steam install and skip cleanly if the game is absent. Override detection with
`BIOSHOCK_REMASTERED_PATH`.

## CLI

```bash
dotnet run --project src/BioShockStudio.Cli -- scan
```

| Command | Purpose |
|---|---|
| `scan` | Parse every shipped package and report table integrity and the class census. |
| `assets [--class C] [pattern]` | List indexed assets. |
| `materials <package> [pattern]` | Resolve each mesh's material and the textures it binds. |
| `properties <package> <object\|--class C> [n]` | Dump an export's property list and what follows it. |
| `inspect <package> [pattern]` | Show a package's header and exports. |
| `havok <package> <object>` | Parse the Havok packfiles inside an export's payload. |
| `skeleton <package> <object>` | Print a skeleton's hierarchy. |
| `animations <package> <object> [owner]` | List decoded animations. |
| `export-blender <package> <object> <out-dir> [owner]` | Write the Blender scene JSON. |
| `export-fbx <package> <object> <out-dir> [owner]` | Write FBX plus the Unreal manifest. |
| `export-firstperson <weapon> <out-dir> [--fbx]` | Assemble the hands, the weapon and both animation sets. |

Example — the first-person hands animation package:

```bash
dotnet run --project src/BioShockStudio.Cli -- havok 0-Lighthouse UAPW_NEWPlayerHands
```

```
AnimationPackageWrapper UAPW_NEWPlayerHands: 920658 bytes
1 Havok packfile(s) embedded.

  @34  hk_2012.2.0-r1  fileVersion=9  sections=12  dataStart=640  size=920624
    root class: AnimationPackageRoot
    section pistol   data=46112  local=4160  global=128  virtual=240
    ...
    classes: AnimationPackageRoot, hkaSkeleton, hkaAnimationBinding, hkaSplineCompressedAnimation
```

## The pistol case

```bash
dotnet run --project src/BioShockStudio.Cli -- animations 0-Lighthouse UAPW_NEWPlayerHands Pistol
```

```
owner              name                             secs  frames     fps  tracks  section
Pistol             EquipPistol                      0.23       8   30.00      47  pistol
Pistol             FastReloadPistol                 1.80      55   30.00      47  pistol
Pistol             FireSinglePistol                 0.23       8   30.00      47  pistol
Pistol             UnequipPistol                    0.50      16   30.00      47  pistol
...
10 shown, 130 decoded, 0 unsupported.
```

Then export and build a `.blend`:

```bash
dotnet run --project src/BioShockStudio.Cli -- export-blender 0-Lighthouse UAPW_NEWPlayerHands artifacts Pistol
```

```bash
blender --background --python tools/blender/import_bioshock_scene.py -- artifacts/UAPW_NEWPlayerHands_Pistol.json artifacts/UAPW_NEWPlayerHands_Pistol.blend
```

Or export FBX instead, one file per animation plus a manifest for Unreal:

```bash
dotnet run --project src/BioShockStudio.Cli -- export-firstperson Pistol artifacts --fbx
```

```bash
blender --background --python tools/blender/validate_fbx.py -- artifacts/Pistol_FirstPerson.json artifacts
```

That check imports the written files back and compares bone rest matrices, skin weights and posed
bone positions against transforms composed independently from the game's own track data. See
[docs/research/fbx.md](docs/research/fbx.md) for the numbers and for what the FBX cannot carry.

The result, verified in Blender 5.1: a 4,852-vertex skinned mesh with 8,726 triangles and 38 vertex
groups, a 47-bone armature with a single root, ten actions, and 19 socket empties parented to their
bones. Every vertex is weighted, weights sum to 1, and the mesh deforms correctly under the
animations. The `Pistol` socket sits exactly on `R_grip` and travels 31 cm through the reload.

## Layout

```
src/BioShockStudio.Core/
├── Io/           stream primitives, FCompactIndex, windowed export views
├── Packages/     .bsm header, name/import/export tables
├── Havok/        Detection/, Packfile/, Objects/, Skeleton/, Animation/SplineCompression/
├── Skeleton/     internal skeleton representation
├── Animation/    internal animation, tracks and binding
├── Export/       Blender scene JSON, and Fbx/ the binary FBX writer
├── Mesh/         SkeletalMesh header and sockets
├── Assets/       whole-game export index, AnimationPackage
└── Game/         install detection
src/BioShockStudio.Cli/
tests/BioShockStudio.Tests/
tools/blender/    headless Blender importer and the FBX round-trip validator
tools/ue5/        Unreal editor import script (unverified)
docs/research/
```

## Method

The project is evidence-driven. Unknown fields are surfaced under neutral names rather than guessed
at, every structure is validated against real bytes before it is trusted, and confidence is labelled
explicitly (`CONFIRMED_BYTES` through `HYPOTHESIS`).

Several carried-in assumptions were corrected by the data: Havok packfiles do not always have three
sections (the hands package has twelve), BioShock does use spline compression, frame rates are not a
fixed 30, and animation channels fall back to the skeleton's reference pose rather than to identity.
Each correction is recorded with the evidence that forced it.
