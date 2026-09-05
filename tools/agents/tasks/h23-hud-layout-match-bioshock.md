---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Rebuild the in-game HUD to BioShock 1's actual layout

User (5 Sept 2026): "the ui is completely incorrect." Correct. `UShockHudWidget`
(`ShockHudWidget.h/.cpp`) currently renders a vertical stack of widgets inside a black
`UBorder` box, bottom-left, with system fonts. That is a placeholder layout, not
BioShock's HUD. h21 wired real decoded arc textures (`/Game/BioShockUI/HUD/T_Hud_*`) but
kept the placeholder arrangement.

## What BioShock 1's HUD actually looks like (PC)

- **Bottom-left corner:** two stacked, slightly-arced horizontal meters.
  - **Health** on top &mdash; crimson/red fill, a small medical-cross cap at the left end.
  - **EVE** below &mdash; blue fill, a hypo/syringe cap at the left end.
  - No large numeral on the bars themselves in the default HUD.
- **Just inboard of the bars (bottom-left, above them):** the **active Plasmid** icon in a
  circular Art-Deco ring.
- **Bottom-left, to the right of the plasmid:** the **equipped weapon** &mdash; weapon icon,
  the current magazine count in large Deco numerals, and small pips/number for the reserve
  and the selected ammo type. This is the "6+" (rounds, + = reserve available) the user
  described; the "3" in a sunburst is the plasmid/EVE indicator.
- **Top-left:** current objective text. **Center:** a per-weapon / per-plasmid crosshair.

## What art we have vs. don't (do not re-derive the blocker)

Have, imported at `/Game/BioShockUI/HUD/`:
- `T_Hud_HealthArc` (SWF `FrozenHealth_DangerBar`, id 98, frame-0 only)
- `T_Hud_EveArc` (unnamed blue arc shape 158)
- `T_Hud_MeterUnderlay` (grey chrome arc shape 160)
- Real decoded fonts from `HUDPC.swf` (font 5 "Century Gothic", font 13 HUD numerals).

Hard blocker (documented, `tools/ue5/export_hud_ui.py` + `docs/research` /
`bioshock-fidelity` notes): the canonical HUD frame bitmaps
(`sharedlibrary.swf` `HUD_HealthBar_Frame01..21`, `HUD_EveBar_Frame01..21`) are Scaleform
**tag-512** bitmaps &mdash; the SWF pipeline cannot decode tag 512. Do NOT try to fix the
SWF decoder in this task; do NOT fake a bitmap. Where frame art is genuinely missing,
approximate with UMG primitives (a Deco-styled `UBorder` + a colour fill `UImage`/
`UProgressBar`) and note it.

## What to do

1. **Look for the missing icons first.** Run `swf-find` (CLI, `dotnet run --project
   src/BioShockStudio.Cli -c Release --`) over `HUDPC.swf`, `PCWeaponSelection.swf`,
   `GeneBankPC.swf` for: weapon-name / plasmid / ammo / cross / hypo / frame / sunburst /
   compass. Export any real shape or sprite you find via `export-swf-shapes` /
   `export-swf-sprite` into the h21 asset location and import as `Texture2D` (mirror
   `import_hud_ui.py`). Report exactly what you searched and what turned up.
2. **Rebuild `UShockHudWidget::EnsureWidgetTree()`** to the layout above:
   - Health + EVE as two horizontal meters in the bottom-left, red and blue, using the
     arc art as the fill or frame (or a UMG bar behind a Deco border if the art doesn't
     fit a horizontal meter). Left-end cap icon slots even if the icon is a placeholder.
   - A weapon cluster (icon slot + magazine numeral in the decoded HUD font + reserve +
     ammo-type) bottom-left, right of the meters. Keep it driven by the existing
     `ResolveEquippedWeapon` / `GetRoundsInMagazine` / `GetReserveAmmo` data.
   - A plasmid icon slot + EVE-cost numeral, near the meters.
   - Drop the big black backing box; BioShock's HUD floats on the frame.
   - Keep the damage-flash and the `bEnforceAmmo`-gates-ammo-panel behaviour.
3. Keep all the existing `Get*ForVerify` / `RunHeadlessHudVerify` hooks working &mdash;
   update them for the new widget names, don't delete the assertions.

## Tests / verify

Headless (`run_hud.py` pattern): widget constructs, the health/EVE meter images have a
non-null texture, ammo numerals resolve, damage still reduces the displayed health,
ammo panel hides for a non-`bEnforceAmmo` weapon. Visual correctness (does it read as
BioShock's HUD) is explicitly a human PIE check &mdash; say so, don't assert it.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only. Reference the committed
  `src/BioShockStudio.Core/UI/Swf/**` pipeline as a fixed tool; file a note if you find a
  real bug in it, don't work around it.
- Do NOT commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
- If a `-CleanModule` rebuild is needed for new UPROPERTY widget bindings, that's the
  verify command with `-CleanModule` appended.
- Do not commit decoded game art to the repo (same rule as every other asset import).
