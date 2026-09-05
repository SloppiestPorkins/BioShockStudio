---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U8a — HUD + radial polish (toward 1:1 with BioShock 1)

`docs/UI_ROADMAP.md`. U1-U7 landed the structure with real art; the layouts are rough.
This phase brings the **HUD and radial** to a faithful finish. Visual check every
iteration: `capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical -Extra '-bioshockshothud'`
(single flag is fine) → `Exports/shots/1-Medical_hud.png`. Attach before/after.

## HUD (`UShockHudWidget`)

Current state (screenshot in the U2b commit `98ceb70`): meters upper-left in the real
frames, fills masked, cap icons + counts, plasmid/weapon rings. Fix:

1. **Numerals** — the kit/hypo counts and the weapon ammo currently render in a UMG
   system font. Use the game's own HUD digit glyphs (`T_Hud_Digit_0..9`, already imported
   from `HUDRadial.swf` ids 260-278) — a small helper that lays out a number as a row of
   digit `UImage`s. Same for the ammo magazine/reserve.
2. **The stray "+" glyph** next to the health cross — remove it (it's a leftover text
   node, not the cross icon).
3. **Liquid look** — the fill is a flat colour block. Give it BioShock's liquid feel: a
   subtle vertical gradient (darker at the bottom) + a faint top highlight line, via a
   small UMG material on the fill instead of a flat tint. Keep it masked to the pill.
4. **Fill overshoot** — at 100% the fill slightly exceeds the frame's rounded ends; tighten
   the mask/inset so it sits flush.
5. **Damage direction** — the widget has `HudDamageEdge()` but no directional indicator.
   Add four edge wedges (top/bottom/left/right) that flash red toward the damage source
   when health drops (the damage instigator's direction relative to the camera). If the
   damage event doesn't carry a source direction, flash all four briefly and note it.
6. **Weapon/plasmid labels** — "ElectroBolt" / class-y names → friendly ("Electro Bolt",
   "Research Camera"). A name-tidy map or a display-name field on the def.
7. Size/position pass against a real BioShock screenshot: meters a touch smaller, tucked
   into the very corner (~16px margin); ammo cluster bottom-right at a matching size.

## Radial (`UShockRadialMenu`)

Current state (U3 commit `beadf63`): wheel is off-centre (overlaps the HUD), segment
labels collide, raw class names.

1. **Centre it** — the wheel goes dead-centre of the screen, not offset.
2. **Segment layout** — evenly space N segments on a circle of fixed radius; the label
   sits just outside its segment, anchored so it never overlaps the neighbour or the
   centre readout. For >6 items, shrink the radius text or use two rings (weapons outer,
   nothing inner) — match BioShock's single-ring layout.
3. **Friendly names** (same map as the HUD).
4. **Centre readout** — selected item name + its ammo (weapons) or EVE cost (plasmids) in
   the digit font, inside the ring, not colliding with segments.
5. **Hover highlight** — the hovered segment's ring brightens / scales up slightly.
6. Dim the game behind the wheel (a translucent black full-screen layer under it) like
   BioShock does.

## Verify

`run_hud.py` / `run_radial.py` stay green. Attach `-bioshockshothud` captures of the HUD
and (with `-bioshockshotradial`) the wheel. Human confirms 1:1 feel in PIE.

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild.
- Don't touch the menus/stations (U8b). Don't regress any other `run_*` UI verify.
- Update `docs/UI_ROADMAP.md` + `tools/ue5/README.md`. No `docs/HANDOFF.md` row.
