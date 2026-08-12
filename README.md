# BioShock 1 Remastered Model Studio

A Windows reverse-engineering and asset-extraction tool for **BioShock 1 Remastered only**, aimed at
recovering skeletal meshes, skeletons, skinning, Havok animation data and first-person viewmodel
assets in a form Blender and Unreal Engine 5 can use.

The target case is the first-person pistol: find it, resolve its hands, skeleton, animation package,
animations, sockets and materials automatically, decode the Havok data, bind it correctly, and
export something that plays back correctly in UE5.

## Status

Vertical slice 1 of 7. What works today is the container layer — packages and the Havok packfile
structure. Nothing decodes meshes or animations yet.

| Area | State |
|---|---|
| `.bsm` package format | Complete: header, names, imports, exports. All 21 shipped packages parse byte-exact. |
| Asset index | Complete: 812,435 exports indexed across the game. |
| Havok packfile detection | Complete, including unaligned embedded packfiles. |
| Havok header / sections / class names | Complete. |
| Havok fixups, object graph | Not started. |
| `AnimationPackageRoot` layout | Not started — the next blocking target. |
| `SkeletalMesh` payload | Not started. |
| Spline decompression | Not started. |
| Blender / FBX export, GUI, preview | Not started. |

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

## Layout

```
src/BioShockStudio.Core/
├── Io/           stream primitives, FCompactIndex, windowed export views
├── Packages/     .bsm header, name/import/export tables
├── Havok/        Detection/, Packfile/
├── Assets/       whole-game export index
└── Game/         install detection
src/BioShockStudio.Cli/
tests/BioShockStudio.Tests/
docs/research/
```

## Method

The project is evidence-driven. Unknown fields are surfaced under neutral names rather than guessed
at, every structure is validated against real bytes before it is trusted, and confidence is labelled
explicitly (`CONFIRMED_BYTES` through `HYPOTHESIS`). Two facts carried in as assumptions —
"Havok packfiles always have 3 sections" and "do not assume spline compression" — were both
corrected by the bytes early on.
