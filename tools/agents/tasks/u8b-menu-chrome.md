---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U8b — menu chrome: shared Deco style across pause / status / stations / menu / save-load

`docs/UI_ROADMAP.md`. U1-U7 + U8a landed. Every menu currently draws its buttons and
panels as **plain grey UMG boxes** — this phase replaces that with the real BioShock
Deco frame art, consistently, everywhere. Capture each screen with its force-open flag
(`-bioshockshotpause` / `status` / `garden` / `vend` / `combo` / `genebank` / `invent`
via a direct `UnrealEditor-Cmd -game -bioshockscreenshot -bioshockshothud
-bioshockshot<flag>` invocation, and `-bioshockmenushot=<path>` for the main menu).
Attach before/after for at least pause, status, one station, and the main menu.

## Build a shared style helper

`UShockDecoStyle` (a static helper, not a widget) with functions that return configured
`FSlateBrush` / apply styles, all from textures the import scripts already pull (or add to
`import_bioshock_ui.py`). The real art (extract with `export-swf-images`):

| Element | Source (SWF id) | Notes |
|---|---|---|
| List button, normal | `pausePC` 1383 (one cell) or `mapsPC` 1845 | 9-slice; measure corner insets by hand |
| List button, hovered/selected | `mapsPC` 1840 or `pausePC` 567 (the glowing variant) | swap brush on hover |
| Panel / content area | `mapsPC` 1811 (window frame) + `GeneBankPC` 42 (dark inner) | 9-slice frame + tinted fill |
| Header nameplate | `mapsPC` 1773 / 1860 | for tab titles + section headers |
| Banner (screen title) | `pausePC` 565 | main-menu / pause header |
| Slot grid | `GeneBankPC` 148 | Gene Bank / inventory slots |
| Row item plate | `GeneBankPC` 159 / 30 | vend items, gene rows |
| Selection chevron | `pausePC` 223 (already imported) | keep |
| Scrollbar track | `mapsPC` 1793 | list scrollbars |

## Apply it

1. **Pause menu** — buttons use the Deco list-button brush + hover swap; header on the
   `565` banner; the stats strip on a small nameplate. Tighten layout so it doesn't
   overlap the HUD.
2. **Status menu** — tab buttons on nameplate frames with the real tab icons already in
   place; the content area in the `1811` window frame; push the whole thing below/clear
   of the HUD meters (it currently overlaps the EVE bar).
3. **Stations (U5)** — THE BIG FIX: the machine-face art is currently rendered at
   ~full-screen and pushes everything off. Render the machine face at a sane size
   (a panel ~900×640 centred), put the item list / slot grid / dial controls INSIDE it
   using the `148` slot grid + `159` row plates, and make the buy / equip / upgrade
   buttons Deco buttons. Each of the five station screens.
4. **Main menu** — buttons → Deco list buttons; background → a dark Deco vignette (tile
   `GeneBankPC` 42 or a gradient) rather than flat teal; entry list left-aligned under the
   logo like BioShock. Difficulty select + save/load use the same button/panel style.
5. **Save/Load** — slot rows on `159` plates with the timestamp + level; empty slots
   greyed.

## Verify

Every `run_*` UI verify (`run_hud`, `run_radial`, `run_status_pause`, `run_stations`,
`run_hacking_minigame`, `run_frontend`) stays green. Attach the before/after captures.
Human confirms 1:1 in PIE — say so.

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild.
- Don't change any widget's data bindings or the U8a HUD/radial work — this is chrome only.
- Update `docs/UI_ROADMAP.md` (U8 row → done) + `tools/ue5/README.md`. No `docs/HANDOFF.md` row.
