---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U2 — import the real HUD art and rebuild UShockHudWidget to BioShock 1's layout

Read `docs/UI_ROADMAP.md` §2.1 and §3 first. U1 landed the SWF bitmap decoder
(`export-swf-images`, `tools/ue5/export_all_ui_images.py`). This phase brings the HUD art
into UE and rebuilds the widget properly. Two prior attempts (h21, h23) were reverted —
this one uses the real decoded assets and the correct layout.

## The correct layout (this is the part the reworks got wrong)

BioShock 1's health and EVE bars are in the **UPPER-LEFT corner**, stacked (health on top,
EVE below), NOT bottom-left. Wiki in-game help captions, verbatim: *"the red bar in the
upper left hand corner of the screen"*, *"the blue EVE Bar in the top left corner"*.

- **Upper-left**: Health meter (red fill) over EVE meter (blue fill), both in the rusted
  Art-Deco pill frame. A medical-cross icon at the health frame's left cap with the First
  Aid Kit count beside it; a hypo-needle icon at the EVE frame's left cap with the EVE Hypo
  count. Fills shrink toward the left as the resource drains.
- **Lower-right**: active weapon — icon in the brass ring, current magazine in the game's
  large HUD digit font, reserve + ammo-type smaller.
- **Lower-left**: active plasmid icon in the brass ring.
- **Top-center**: pickup toasts ("Found: X"), objective-updated toasts, interact prompts.
- **Center**: crosshair (a simple dot/cross is fine for U2; per-weapon reticles are U8).
- **Screen edges**: red directional damage flash on health drop (the widget already has a
  damage-flash timer — repurpose it).
- **Bottom**: full-width vignette gradient (HUDPC id 177, 4096×256).

## The art (from `export-swf-images HUDPC.swf` / `HUDRadial.swf` / `sharedlibrary.swf`)

Run the extractor and read the manifests to get exact ids/names. What's confirmed present:

- **HUDPC id 86 / 100 / 105 / 111 / 118** — 2048×1024 atlases, each holding 6 pill meter
  frames (two widths × three tint states), 3 parchment plates, 3 brass circles. Pick one
  atlas (they differ by tint/state — 86 looks like the neutral one) and crop the pill
  frame sub-rectangle in the import script; the frame is a 9-slice (measure the corner
  insets by hand — tag 12 is ActionScript, not a scaling grid, confirmed in U1).
- **HUDPC id 8** — brass ring, 128×128 — the weapon/plasmid icon holder.
- **HUDPC id 177** — bottom vignette gradient, 4096×256.
- **HUDPC id 370 / 381** — gold-framed dark readout plates, 256×128.
- **HUDRadial id 239-278** — the real HUD digit glyphs 0-9 (two sets: normal + highlight),
  64×128 each. Import these and render numbers by compositing glyphs, OR check whether the
  already-decoded `DefineFont2` in HUDPC (the "HUD digit" font from the h21 work) covers it
  — either is fine, but the numerals must be the game's, not a UMG system font.
- Weapon / plasmid ICONS: search the manifests (`swf-find HUDPC.swf pistol` etc.) and
  `sharedlibrary.swf`. If the per-weapon icons genuinely aren't in these files, use the
  brass ring alone with the weapon name as text for U2 and note the gap — do not fake icons.
- The cross / hypo cap icons: check `sharedlibrary` (the medical caduceus and EVE apple
  appear on the poster art ids 592/599 but standalone icons may exist) — again, if not
  found, a simple authored glyph is acceptable, noted.

## What to build

1. `tools/ue5/import_bioshock_ui.py` (+ `run_*`): shell `export_all_ui_images.py`, then
   import the HUD-relevant PNGs to `/Game/BioShockUI/HUD/` as `Texture2D` (UI group,
   sRGB, no mips, `TC_EditorIcon` or `TC_UserInterface2D`). Idempotent. Delete the stale
   `T_Hud_HealthArc` / `T_Hud_EveArc` / `T_Hud_MeterUnderlay` from the h21 attempt and
   their references.
2. Rebuild `UShockHudWidget::EnsureWidgetTree()` to the layout above. Anchor the
   health/EVE cluster top-left (anchor (0,0), alignment (0,0), position ~(24,24)). Meters:
   the pill frame as a `UImage` (or `UBorder` with a boxed brush for the 9-slice), the
   fill as a child `UImage`/`UProgressBar` clipped to the frame's inner rect, tinted red /
   blue. Weapon cluster bottom-right, plasmid bottom-left, both anchored to their corners.
   Keep the `bEnforceAmmo` gate on the weapon cluster and the damage-flash behaviour.
3. Keep every `Get*ForVerify` / `RunHeadlessHudVerify` hook working — rename for the new
   widget members, don't delete the assertions. `HasHealthArcTexture` etc. become
   `HasHealthMeterFrame` / verify the real textures resolve non-null.

## Verify

- `run_hud.py` green — widget constructs, meter-frame + fill + digit textures resolve
  non-null, damage still reduces displayed health, ammo panel gates on `bEnforceAmmo`.
- **Visual is a capture-harness check**: `tools/ue5/capture_shot.ps1 -Map
  /Game/BioShockSlice/1-Medical` photographs the running HUD. Include a note in the PR /
  summary that a human still confirms it reads like BioShock's HUD.

## Constraints

- `tools/ue5/**` only. Don't touch the SWF pipeline (U1 owns it).
- No decoded art committed. Scripts committed, textures not.
- One rebuild of `BioShockRuntime`; do not run alongside another C++ task.
- If `-CleanModule` is needed for new UPROPERTY widget members, that's the verify command
  with `-CleanModule` appended.
- Update `docs/UI_ROADMAP.md` (mark U2) and `tools/ue5/README.md` when `run_hud.py` is green.
