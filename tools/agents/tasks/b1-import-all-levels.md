---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase A1 of `docs/FULL_GAME_CONVERSION.md`: scaffold the batch level-conversion tool, then
run it on a few maps as a proof and report which import clean vs which have decode gaps.

## Context
`export-level <map> <out> [--package]` (C# CLI) writes a `<map>.ue5-level.json` manifest + OBJ.
`tools/ue5/import_level.py` reproduces one manifest's actors in the currently-open UE5 level
(idempotent, `BioShockKey` tags, reports created/updated/skipped/unsupported). Proven on
`0-Lighthouse` (1,274 instances / 0 skipped) and `1-Medical`. Only those two are actually
imported into the throwaway project.

## Do
1. `tools/ue5/import_all_levels.py` (+ `run_import_all_levels.py` driver following the repo
   pattern):
   - Takes a map list (default: all 21 shipped maps; `--maps a,b,c` to subset).
   - Per map: run `export-level <map> <tempdir> --package` (subprocess, like
     `verify_ai_archetypes._export_manifest_to_temp`), then in-editor open/create
     `/Game/BioShockLevel/<map>` and call `import_level.main(<manifest>)`.
   - Idempotent: skip a map whose `BioShockKey`-tagged actor count already matches, unless
     `--force`.
   - Write `%TEMP%/bioshock_import_all_levels.json`: per map — `imported` bool, counts
     (created/updated/skipped/unsupported), `unsupported_classes` list, elapsed, error.
   - Add a `--lighting-stopgap` flag that, per map, does the same dynamic directional+sky fill
     `ShockGameMode::EnableDynamicLighting` does (or the simplest thing that makes the map not
     pitch black) so a walk-through is possible. Default on.
2. **Run it on 4 maps as a proof**: `0-Lighthouse`, `1-Medical` (already in, tests idempotency),
   `2-Fisheries` (largest script count), `7-BossFight` (set-piece). Record the report.
3. Do NOT run all 21 here — that's hours. The deliverable is the tool + the 4-map proof +
   a clear statement of what the full run would need.
4. `docs/FULL_GAME_CONVERSION.md`: tick A1's status with the proof result and any gaps found.

## Constraints
- `tools/ue5/**` + the `FULL_GAME_CONVERSION.md` A1 line. No `src/**`, `tests/**`. No commit/push.
- Do NOT commit generated `.umap`/`.uasset` — throwaway project only.
- Scratch/exports to `$env:TEMP`, not the worktree.
- Fast tier must stay green (no C# touched).
- `docs/ENGINEERING_RULES.md`: smallest correct change; a map that fails to import is a recorded
  data point, not a task failure — get through all 4 and report.
