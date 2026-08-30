---
worker: chatgpt
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: docs/research/**
---
Produce a per-map coverage table for the `export-script-actions` sidecar across all 21 maps.
Pure measurement — REPORT ONLY. This is the Phase 2.3 tail-1 groundwork
(`docs/UE5_FULL_PORT_PLAN.md` §9 "Phase 2.3 audit").

## Do
1. `dotnet run --project src/BioShockStudio.Cli -- --help` shows `export-script-actions` and the
   map list. Run it for every shipped map, writing every sidecar to `%TEMP%` / `$env:TEMP` —
   NOT into the repo or the worktree.
2. For each map, read its sidecar JSON and record: map, script count, total action references,
   distinct action classes, nested body counts (true/else/loop/for/tests), `nested_unmapped`,
   and any `unmapped_classes` with counts. Maps with no scripts (`Entry`, `museum`) are a valid
   "0" row, not an error.
3. Game-wide aggregate: which action classes (if any) appear in the sidecars but fall through to
   a generic bucket / have no mapping, ranked by frequency. Cross-reference the
   `ActionUsageCensusTests` head (ActionWait 2209, ActionSetProperty 1902, ActionIf 1891,
   ActionPlayEffect 1806, ActionNonBlockingExecuteScript 1106) so the report states how much
   scripted behaviour the current sidecar mapping does and does not cover.
4. Write the census as a dated Markdown table into an existing note under `docs/research/`
   (the script or interaction one — do NOT create a new top-level doc). Label measured counts
   `CONFIRMED_BYTES`. If the census now covers all 21 maps, update the §9 "Gap: the sidecar's
   graph coverage is proven on Medical only" line's status (that one line only).

## Hard constraints — read these
- **Do NOT modify any file under `src/`. Not one line.** Measurement task.
- **Do NOT modify or add test files.** `tests/**` is off limits.
- If you find a real exporter defect (a class that should map and doesn't, a nested body the BFS
  misses): STOP, write the precise finding into the research note (which class, which map, which
  sourceKey, expected vs actual), add a `docs/HANDOFF.md` Active-work row for the Claude Code
  lane, and stop. Do not fix it.
- Only `docs/research/**` (+ the one `docs/HANDOFF.md` row / `UE5_FULL_PORT_PLAN.md` §9 line if
  warranted) may change. No commit, no push.
- `dotnet test --filter Tier=Fast` must stay green (you are not touching code).
- `docs/ENGINEERING_RULES.md`: real game bytes only, never promote a hypothesis to a fact,
  "unknown" is a valid cell.
