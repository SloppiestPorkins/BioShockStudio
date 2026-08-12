# BioShock 1 Remastered Model Studio

A Windows reverse-engineering and asset-extraction tool for **BioShock 1 Remastered only**, aimed at
recovering skeletal meshes, skeletons, skinning, Havok animation data and first-person viewmodel
assets in a form Blender and Unreal Engine 5 can use.

The target case is the first-person pistol: find it, resolve its hands, skeleton, animation package,
animations, sockets and materials automatically, decode the Havok data, bind it correctly, and
export something that plays back correctly in UE5.

## Status

The **animation pipeline is complete end to end**: a shipped package goes in, a Blender file with a
correct armature and playable actions comes out. The mesh pipeline has not been started, so what
exports today is a skeleton and its animations, not a skinned character.

| Area | State |
|---|---|
| `.bsm` package format | Complete. All 21 shipped packages parse byte-exact. |
| Asset index | Complete: 812,435 exports indexed. |
| Havok packfile, fixups, object graph | Complete. |
| `AnimationPackageRoot` | Complete — the class UEViewer reports as unknown. |
| `hkaSkeleton` | Complete, original bone indices preserved. |
| `hkaAnimationBinding` | Complete, from Havok's own track-to-bone array. |
| Spline decompression | Complete. 130/130 animations decode, zero failures. |
| Blender export | Complete for skeleton + actions + sockets. |
| `SkeletalMesh` payload | **Not started** — the largest remaining gap. |
| FBX / UE5 export | Not started. |
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
| `inspect <package> [pattern]` | Show a package's header and exports. |
| `havok <package> <object>` | Parse the Havok packfiles inside an export's payload. |
| `skeleton <package> <object>` | Print a skeleton's hierarchy. |
| `animations <package> <object> [owner]` | List decoded animations. |
| `export-blender <package> <object> <out-dir> [owner]` | Write the Blender scene JSON. |

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

The result, verified in Blender 5.1: a 47-bone armature with a single root, ten actions, the
`R_grip` and `IKbindLhandDummy` sockets flagged, game bone indices preserved as custom properties,
and 46 of 47 bones rigid under animation.

## Layout

```
src/BioShockStudio.Core/
├── Io/           stream primitives, FCompactIndex, windowed export views
├── Packages/     .bsm header, name/import/export tables
├── Havok/        Detection/, Packfile/, Objects/, Skeleton/, Animation/SplineCompression/
├── Skeleton/     internal skeleton representation
├── Animation/    internal animation, tracks and binding
├── Export/       Blender scene JSON
├── Assets/       whole-game export index, AnimationPackage
└── Game/         install detection
src/BioShockStudio.Cli/
tests/BioShockStudio.Tests/
tools/blender/    headless Blender importer
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
