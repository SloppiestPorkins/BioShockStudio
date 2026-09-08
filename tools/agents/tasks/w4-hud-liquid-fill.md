---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# HUD health / EVE bars render flat — the liquid-fill material is disabled

`docs/AUDIT_2026-09-06.md` open gap #3: `M_Hud_LiquidFill` renders invisible, so a flat
tinted-mask fallback is forced by `bLiquidMaterialDisabled` in `ShockHudWidget`. The bars work
(health upper-left, EVE, hypo/kit counts) but don't have BioShock's liquid look — the meniscus,
the slight wobble, the specular on the fluid.

## What to do

1. Find why `M_Hud_LiquidFill` draws nothing — grep `ShockHudWidget.cpp` for
   `bLiquidMaterialDisabled` and the material/asset it's meant to use. Likely a NULL texture
   param (same class of bug as the wall-texture masters — `repair_null_master_textures.py`), a
   UMG material-domain mismatch, or an opacity/blend-mode issue.
2. Author or repair the material: a UI-domain material that takes a `Fill` scalar (0..1) and a
   tint, renders the fluid with a soft top edge (meniscus), optional slow UV pan for wobble,
   and a subtle highlight. Reference BioShock's HUD: the health bar is a red fluid column, EVE
   is blue.
3. Re-enable it in `ShockHudWidget` (drop or invert `bLiquidMaterialDisabled`); keep the flat
   fallback only for the genuine no-material case.
4. Check the real BioShock HUD SWF (`tools/` SWF decode, `docs/research/` UI notes) for the
   actual fill artwork if it ships as a bitmap rather than needing a procedural material.

## Deliverable

- The liquid material working, wired back into the HUD.
- `docs/research/` UI note updated.
- `-game` HUD captures (`capture_shot.ps1 -Extra @('-bioshockshothud')`) at full / half / low
  health and EVE showing the fluid look.
- Headless: `verify_hud` / `run_verify_main_menu` still pass; a check that the HUD material
  resolves non-null and the fill param drives it.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless. `-run=pythonscript` → JSON. MSYS
  forward-slash + `MSYS_NO_PATHCONV=1`.
- Do NOT commit. Diff for review; human confirms the HUD visually.
