# UELib decompiler bridge

Bridges to `Unreal-Library-master` (UELib), a third-party UnrealScript bytecode decompiler with
explicit BioShock/Vengeance support, to decompile the game's own shipped `.U` script packages back
to readable UnrealScript. See `docs/research/bytecode.md` for what this found and its known limits.

UELib itself is not part of this repository (`Unreal-Library-master/` sits gitignored at the repo
root, alongside the other reference projects — see `ENGINEERING_RULES.md`). Its own `.csproj` files
target frameworks (`net10.0` in the multi-target list) this repo's installed SDK doesn't support, so
`uelib-standalone.csproj` here compiles its source directly against `net8.0` instead of using the
project's own build files.

## Build and run

```bash
dotnet build tools/uelib-bridge/uelib-standalone.csproj
dotnet run --project tools/uelib-bridge -- <out-dir> <package-name.U> [scripts-dir]
```

`scripts-dir` defaults to the auto-detected game install's `Build/Final/BakedScripts/pc`. Output is
one `.uc` file per class. **Do not commit decompiled output** — it is derived from the shipped
game's own bytecode, the same reason no extracted textures/meshes/audio are committed either
(`docs/HANDOFF.md`: "No game data is in the repository").

## Known limits, measured 19 Aug 2026

- `Engine.U` fails outright during package initialization (`UClass.Dependency.Deserialize`,
  "Unexpected value for a boolean") — a version-gated field this UELib build reads incorrectly for
  BioShock's version of that one package. Not investigated further; Engine.U is mostly stock engine
  classes, not BioShock's own game logic.
- Every other script package decompiles cleanly: Core (10 classes), ShockGame (654), ShockAI (540),
  Scripting (99), VengeanceShared (80), Tyrion (27), FMODAudio (1), IGEffectsSystem (8),
  IGModEffectsSubsystem (3), IGSoundEffectsSubsystem (14), IGVisualEffectsSubsystem (9) — 1,445
  classes, 0 hard failures.
- Native function calls decompile as `__NFUN_<id>__(...)` placeholders — the native ID-to-name table
  is per-game and not part of this bridge. `Bioshock1REMSDK-WIP--main/docs/reverse-engineering/
  coop-natives-map.md` already resolves a couple dozen common ones (operators, `GotoState`, `FRand`,
  vector math), keyed by call-site context rather than a complete table.
- A handful of `Emitters`/`Skins`/`EventResponse` array properties fail to parse in class defaults
  (a property-tag array-type inference issue in UELib, unrelated to bytecode) and a small number of
  individual statements produce "Statement decompilation error" comments inline — isolated, not
  fatal to the surrounding function.
