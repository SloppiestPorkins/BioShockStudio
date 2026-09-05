---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Re-run import_scripts.py across all 21 maps; record nested_unmapped/unmapped_classes per map

Two things left owed from `docs/UE5_FULL_PORT_PLAN.md`'s Phase 2.3 tail:

1. **Script-graph sidecar coverage on the 20 non-Medical maps.** `export-script-actions`
   (the C# CLI command) has already been run over all 21 maps (28 Aug 2026 — 0 skipped
   on every map, ~4,878 scripts, ~39,690 unique exports). The *import* half
   (`tools/ue5/import_scripts.py` + `run_import_scripts.py`, which consumes that sidecar
   and builds `AShockScript` level-placed actors + the nested If/Loop/For action tree in
   UE5) has only actually been run and verified against `1-Medical`. Run it for the
   other 20 maps too and record, per map, the same `nested_unmapped` / `unmapped_classes`
   counts Medical's run already tracks (see `docs/research/interaction.md` §8 for the
   Medical baseline: 300 scripts, 1,463 actions mapped, `nested_unmapped = 0`).

2. **The script-importer mapping gap fix needs its re-import re-run.** Already fixed
   (30 Aug 2026, `docs/UE5_FULL_PORT_PLAN.md` "Phase 2.3 tail-1"): `import_scripts.py`
   was silently dropping `OrStatement` (×23 across the 21-map census), `HideNeedleElement`
   (×2), `ShowNeedleElement` (×2), `TrainingCondition` (×1) — fixed with three prefix
   overrides plus a new `UShockOrStatement` class. That fix compiled clean but "the
   per-map `nested_unmapped` re-import re-run is still owed (worker connection dropped
   during that step)" — i.e. nobody has actually confirmed those four classes now import
   correctly across the maps that use them. Confirm the fix actually closes the gap it
   was meant to close, with real numbers, not just "it compiles."

## What to do

For each of the 21 shipped maps (see `GameLocator.MapsDirectory` / the existing
`export-script-actions` invocation for the map list), run the sidecar export (if its
JSON isn't already sitting somewhere from the 28 Aug pass — check
`tools/ue5/README.md` / prior run reports before re-exporting something that already
exists) then `tools/ue5/import_scripts.py` against it, and record per map:
- scripts imported, actions mapped
- `nested_unmapped` count (should trend toward 0, matching Medical)
- `unmapped_classes` — any UnrealScript action class name the importer doesn't know how
  to map to a `UShockAction*` yet, listed by name and count, not just a total

Do not silently paper over an unmapped class with a generic stub if one doesn't already
exist for it — report it as a genuine gap (matching this project's own documented
practice: "genuinely just unattempted, not blocked" is fine to write down; inventing
behavior for a class you haven't looked at is not).

## Tests / verify

A headless run per map (or a batched driver over all 21) that writes a report with the
per-map counts above. If any map's import throws or corrupts prior state, stop and report
which map and why rather than pushing through — these are real level assets, not
throwaway test data.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- This does NOT need to touch `1-Medical`'s already-verified import — scope changes to
  the other 20 maps' script data only, unless the OrStatement-class fix genuinely
  requires touching shared import code (it already does, per the 30 Aug note — that's
  fine, just don't re-run/re-verify Medical's whole level import as a side effect).
- No live UE session in this worktree — headless assertions are the evidence.
- Do not commit or push. Update `tools/ue5/README.md` and/or
  `docs/UE5_FULL_PORT_PLAN.md` with a dated entry once verified, following the existing
  "Phase 2.3 tail-N" numbering convention already used in that doc.
