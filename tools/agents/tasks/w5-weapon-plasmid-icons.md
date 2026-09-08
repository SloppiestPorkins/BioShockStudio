---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: src/**, tests/**, tools/ue5/**, docs/research/**, tmp/**
---

# Weapon and plasmid icons — radial and HUD show name-only

`docs/AUDIT_2026-09-06.md` open gap #4: no weapon/plasmid icon bitmaps in any SWF export, so the
8-segment weapon radial (`radial_hud.png`) shows brass medallions with **no icon**, and the HUD
plasmid/weapon slots are empty circles. Everything else about the radial is done
(`u3-radial-and-weapon-select`, `4795435`).

## What's there

- SWF decode exists (`u1-swf-bitmap-decode`, `tools/` SWF tooling); `docs/research/` UI notes.
- The radial + HUD widgets (`ShockWeaponSelectScreen`, `ShockHudWidget`) already lay out the
  segments and would draw an icon if given one.
- BioShock's weapon/plasmid icons live in the frontend/HUD SWFs (`DefineBitmap` /
  `DefineShape` / `DefineSprite` for the vector ones).

## What to build

1. Locate the weapon + plasmid icon assets in the SWFs — which SWF, which character/export ids,
   bitmap vs vector. Document in `docs/research/`.
2. Extract them: bitmaps → PNG; vector shapes → rasterise at icon resolution (the SWF shape
   renderer, or the same path `u6-hacking-minigame` deferred — if vector rasterisation is out
   of scope, say so and rasterise only the bitmap ones).
3. `tools/ue5/import_weapon_icons.py` — import the PNGs as UI textures under `/Game/BioShockUI/`
   and bind them into the radial + HUD slot widgets keyed by weapon slot / plasmid id.
4. Wire into `setup_playable_slice` / `setup_main_menu`.

## Deliverable

- `docs/research/` note — icon source, extraction method, mapping to slots.
- Extraction (C# or tool) + `import_weapon_icons.py`.
- `-game` captures: the weapon radial with icons, the HUD with a plasmid icon.
- Fast tests green; `run_verify_main_menu` / `verify_frontend` / `u3` verifies still pass.

## Constraints

- If you modify `src/**`, additive only + keep Fast tests green. `tools/ue5/**` for the import.
- Editor CLOSED for headless. MSYS forward-slash + `MSYS_NO_PATHCONV=1`.
- Do NOT commit. Diff for review.
