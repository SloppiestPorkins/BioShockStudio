# Splitting into a BioShock asset editor and a UE5 port — plan (not yet executed)

Written 28 Sept 2026. This is a proposal for review, not a change that has been made. Nothing in
this repo has moved because of this document.

## Why this is low-risk

The two halves of this repo already talk to each other through a **process boundary, not a
compile-time one**. `tools/ue5/*.py` never references `src/BioShockStudio.Core` as code — every
call is a subprocess: `dotnet run --project src/BioShockStudio.Cli -- export-level 1-Medical ...`,
reading back the JSON/OBJ/PNG/FBX it wrote to `Exports/`. `src/BioShockStudio.Core` has zero
`ProjectReference`s and never imports anything from `tools/`. That is exactly the seam a repo split
wants: cut where two things already only communicate through files on disk.

## The two projects

### 1. BioShockStudio (asset editor / extraction toolchain)
- `src/BioShockStudio.Core` — package reader (`.upk`/`.u`), BSP/mesh/material/skeleton/audio
  decoders, the `LevelSceneExporter` that writes the JSON/OBJ manifests everything downstream reads.
- `src/BioShockStudio.Cli` — the `export-level` / `export-fbx` / `export-audio` / `properties` /
  `export-swf-*` commands.
- `src/BioShockStudio.App` — the GUI viewer (`docs/GUI.md`).
- `tests/BioShockStudio.Tests`.
- `BioShockStudio.sln`, `Directory.Build.props`.
- Genuinely useful on its own: reads and exports BioShock 1 (Remastered) assets with no UE5
  dependency at all. Someone could use this to get textures/meshes/levels/audio out of the game
  without ever touching Unreal.

### 2. The UE5 port (name TBD — currently this repo, "BioshockHavok")
- `tools/ue5/BioShockRuntime` — the UE5.7 C++ plugin (all gameplay systems).
- `tools/ue5/*.py` — the import/verify/repair pipeline that turns BioShockStudio's exports into a
  working UE5 level, and the ~140 `verify_*.py` / `run_*.py` headless test drivers.
- `tools/agents/` — the Cursor dispatch orchestrator and its task queue (campaign-specific to this
  port).
- `docs/research/**` — reverse-engineering notes, almost all UE5-port-specific (a handful cite
  BioShockStudio's own decoders too; those stay put and just get a cross-repo link instead of a
  relative path).
- `docs/ROADMAP.md` / `docs/STATUS.md` and the process docs (`ENGINEERING_RULES.md`, `QUALITY.md`,
  `EFFICIENCY_RULES.md`) — largely port-specific already; a couple of paragraphs about the exporter
  CLI move with it.

### Shared / needs a decision
- `tools/uelib-bridge` — a standalone UnrealScript decompiler, referenced by neither project's code
  (a manual research tool, run by hand). Could go either way; leans toward BioShockStudio since it
  is a generic package-reading tool, not UE5-specific.
- `tools/blender` — Blender import/normalize scripts that consume BioShockStudio's FBX exports on
  their way into the UE5 pipeline. Consumption-side, so it leans toward the UE5 port, but has no
  hard dependency on either.
- `external/` — third-party reference projects (Havok SDK, Nyko's SDK, UModel, UELib). Cited by
  both `src/` code comments and `docs/research/**`. Simplest: duplicate the folder (it's gitignored
  either way, so this costs disk, not history) rather than trying to share one copy across two
  repos.

## What actually has to change

1. **New repo for BioShockStudio.** `git filter-repo` (or a fresh repo + one squash commit, if
   history isn't worth carrying) to extract `src/`, `tests/`, `BioShockStudio.sln`,
   `Directory.Build.props` with their history intact.
2. **This repo keeps its history**, drops `src/`/`tests/`/the `.sln`, keeps everything else.
3. **One new setting**: `tools/ue5/import_bioshock.py` and friends currently assume
   `BioShockStudio.Cli` lives at a fixed relative path inside this same repo. That becomes a single
   configurable path (an environment variable or a one-line config file) pointing at wherever the
   new BioShockStudio repo is checked out. Everywhere else already goes through that same
   `dotnet run --project <path>` call site, so this is a small, mechanical change, not a rewrite.
4. **`docs/research/**` cross-references**: a few files cite `src/BioShockStudio.Core/...` file:line
   the way `docs/ENGINEERING_RULES.md` cites `external/...` — those become "see BioShockStudio's own
   `Materials/MaterialReader.cs`" (name only, no path) since the file no longer lives in this repo.
5. **CI / build scripts**: check `.github/` for anything that builds the whole solution in one job;
   split into two.

## What does NOT need to change

- The interchange format (JSON/OBJ/FBX/PNG under `Exports/`) — already file-based, already the
  actual seam.
- Any C++ runtime code.
- `tools/agents/` — it already dispatches Cursor into `tools/ue5/**`, unaffected.
- Git history of the parts that stay.

## Suggested order, when you're ready

1. Confirm the shared-tooling calls above (`uelib-bridge`, `tools/blender`) — one line each, your
   call, not a technical constraint either way.
2. Extract BioShockStudio into its own repo first, standalone, and confirm it still builds and its
   CLI still runs on its own.
3. Point this repo's exporter calls at the new location and confirm one full `export-level` +
   `import_level` round-trip still works end to end.
4. Only then remove `src/`/`tests/`/the `.sln` from this repo.

Each step is independently verifiable and reversible until step 4.
