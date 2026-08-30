---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Fix the 4 script node classes the 21-map census (`579186f`, `docs/research/interaction.md` §8,
`docs/HANDOFF.md` row dated 30 Aug) found unmapped in `tools/ue5/import_scripts.py`.

## The finding (CONFIRMED_BYTES)
`import_scripts.py`'s class-name mapper (`Action*` → `ShockAction*` + 6 explicit overrides)
silently drops, game-wide:
- `OrStatement` × 23 (15 in `4-Recreation`, 2 each in `6-Resi`, `6-Slums`, `7-Gauntlet`,
  `ChallengeRoomElectric`) — a `testsOr` boolean child alongside the already-mapped
  `AndStatement`, `NotStatement`, `TruthStatement`, `BooleanStatement`. It has **no** runtime
  class and **no** override.
- `HideNeedleElement` × 2, `ShowNeedleElement` × 2 (`7-BossFight`), `TrainingCondition` × 1
  (`1-Welcome`) — these three **already have runtime classes** (`UShockActionHideNeedleElement`,
  `UShockActionShowNeedleElement`, `UShockActionTrainingCondition`); the importer just lacks the
  non-`Action` prefix override.

## Do
1. `import_scripts.py`: add the three prefix overrides so `HideNeedleElement` /
   `ShowNeedleElement` / `TrainingCondition` map to their existing `UShockАction*` classes. Match
   how the existing 6 overrides are declared.
2. `OrStatement`: add a `UShockOrStatement` runtime class mirroring `UShockAndStatement` (same
   base, same `testsOr` child-collection semantics — read `AndStatement`'s .h/.cpp and copy the
   shape; an OR evaluates true if any child is true). Add its mapping to `import_scripts.py`
   alongside the other boolean-test overrides. Wire it into `UShockScriptRunner` / the `ActionIf`
   test evaluation the same way `AndStatement` is.
3. Re-run `import_scripts.py` on `4-Recreation` (the worst case — 15 `OrStatement`) and confirm
   its report shows `nested_unmapped = 0` for those classes now. Also run `1-Welcome`,
   `6-Resi`, `7-BossFight`, `7-Gauntlet`, `ChallengeRoomElectric` — the other affected maps —
   and record `nested_unmapped` before/after.
4. Update `docs/research/interaction.md` §8: mark the finding resolved with the fix + the
   re-run numbers; remove/complete the `docs/HANDOFF.md` row.
5. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line.

## Constraints
- `tools/ue5/**` + `docs/research/interaction.md` §8 + the `docs/HANDOFF.md` row + one §9 line.
  No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile the new `UShockOrStatement` before you finish.**
- `OrStatement` must be a faithful mirror of `AndStatement` — don't invent evaluation semantics;
  if `AndStatement`'s exact truth rule isn't obvious from the code, label the OR rule PLAUSIBLE.
- `docs/ENGINEERING_RULES.md`: smallest correct change, verify the re-run numbers, confidence labels.
