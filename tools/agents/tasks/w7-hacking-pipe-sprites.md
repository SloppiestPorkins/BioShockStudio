---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: src/**, tests/**, tools/ue5/**, docs/research/**, tmp/**
---

# Hacking minigame — pipe tiles are placeholder UMG shapes

`docs/AUDIT_2026-09-06.md` open gap #7: the hacking minigame works (`verify_hacking_minigame`
passes) but the pipe tiles are drawn as UMG shapes because the `DefineSprite` export was
deferred (`u6-hacking-minigame`). Also: **Auto-Hack succeeds with no AutoHackTool in inventory**
— a separate small bug.

## What to build

1. **`DefineSprite` extraction** — the hacking SWF's pipe-tile sprites (straight, elbow,
   T-junction, cross, start/end caps, flowing-water frames). Extend the SWF tooling to
   rasterise `DefineSprite` (a sprite is a timeline of `DefineShape`/`DefineBitmap` placements —
   render frame 0, or the animated water frames as a flipbook). Document the tag layout in
   `docs/research/`.
2. `tools/ue5/import_hacking_sprites.py` — import the tile PNGs and bind them into the hacking
   widget replacing the UMG shapes; wire the water-flow animation.
3. **Auto-Hack inventory gate** — grep `ShockHackingMinigame` for the auto-hack path; require an
   `AutoHackTool` in inventory (consume one) before it succeeds.

## Deliverable

- `docs/research/` SWF-sprite note.
- Extraction + `import_hacking_sprites.py`; auto-hack gated on inventory.
- `-game` capture of the hacking board with real pipe art.
- `verify_hacking_minigame` still passes + a new check that auto-hack fails without the tool.
- Fast tests green.

## Constraints

- `src/**` additive only, Fast tests green. `tools/ue5/**` for import + the auto-hack fix.
- Editor CLOSED for headless. MSYS forward-slash + `MSYS_NO_PATHCONV=1`.
- Do NOT commit. Diff for review.
