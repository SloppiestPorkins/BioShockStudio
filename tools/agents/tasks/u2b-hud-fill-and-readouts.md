---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U2b — fix the HUD meter fills, counts, icons, weapon cluster

U2 (`3856d37`) put the health/EVE meters in the right place (upper-left) with the real
rusted-Deco pill frames, a plasmid ring lower-left, a centre crosshair and the bottom
vignette. It is a good foundation but four things are visibly wrong. A HUD-only capture
is available: `powershell tools/ue5/capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical
-Extra '-bioshockshothud'` writes `Exports/shots/1-Medical_hud.png` — the game's HUD
widget rasterised on a grey ground. Use it every iteration; do not guess.

## What's wrong (from the U2 capture, slice: health 100, EVE 100, wrench equipped)

1. **The liquid fill is a plain rectangle that overflows the pill frame.** The EVE fill
   is a hard-edged blue box wider and taller than the rusted housing, poking out past the
   rounded ends. It must be clipped/masked to the frame's inner recess (the rounded
   channel where liquid sits), and it should read as liquid, not a flat block.
   - Best fix: a **fill-mask texture** — the pill frame's inner channel as a white-on-black
     alpha shape at the same resolution as the cropped frame (`import_bioshock_ui.py`
     already crops the frame from the 2048×1024 atlas id 86; crop/derive the matching
     inner-channel mask the same way, or paint it once from the frame alpha). Render the
     fill through a small UMG material that multiplies `FillColor * MaskAlpha`, width
     driven by percent. A `UMaterialInstanceDynamic` on a `UImage` is the normal way.
   - Acceptable simpler fix if the mask is a rabbit hole: inset the fill rectangle well
     inside the frame and round nothing — but it will look boxy; prefer the mask.
2. **The health fill (red) does not render at all** while the EVE fill (blue) does — with
   both resources full. Find why `SetMeterFill` produces nothing for health: likely
   `AuthoredMaxHealth` is 0/unset so `Health / MaxHealth` divides wrong, or the health
   `Clamped` path collapses the widget. The EVE path works — make health match it.
3. **The kit / hypo counts read `+ 1` and `| 1`** — cramped, mis-aligned against the frame,
   and the "+"/"|" are stray glyphs, not the cross/hypo cap icons. Put a proper cap-icon
   slot at the left end of each frame (the authored `T_Hud_Icon_Cross` / `T_Hud_Icon_Hypo`
   — or extract real ones: check `sharedlibrary.swf` via `export-swf-images` +
   `swf-find sharedlibrary.swf cross` / `hypo` / `medkit` / `needle`), then the count as a
   single digit beside it in the HUDRadial digit font, vertically centred on the frame.
4. **No weapon representation lower-right.** With the wrench equipped (melee, no ammo) the
   `bEnforceAmmo` gate hides the whole cluster. Show at least the brass ring + weapon name
   always; show the ammo digits only when `bEnforceAmmo`. (Weapon icon art: still not
   located — ring + name is fine, note it.)

## Also

- The meters are a touch small and high; nudge the top-left cluster to ~(28, 28) and size
  the frame so the pill reads clearly at 1280×720 (the reference frame crop is ~661×137;
  display around that or a hair smaller).
- `-bioshockshothud`'s grey ground currently comes out black (the `ClearColor` set on the
  render target isn't taking). Minor — if it's a one-liner (`HudRT->UpdateResourceImmediate(true)`
  after setting ClearColor, or clear via the widget renderer), fix it; otherwise leave it.

## Verify

- `run_hud.py` green.
- `-bioshockshothud` capture: **both** meters show a shaped fill matching their resource
  level, the fill stays inside the pill, cap icon + count sit neatly at the left, the
  wrench shows a ring + "Wrench" lower-right. Attach the capture to your summary.
- Human still confirms the final look in PIE — say so.

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild.
- Update `docs/UI_ROADMAP.md` (fold U2b into the U2 row) + `tools/ue5/README.md`.
