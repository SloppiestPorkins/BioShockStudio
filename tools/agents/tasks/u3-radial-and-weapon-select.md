---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U3 — radial weapon/plasmid wheel + full select screen

`docs/UI_ROADMAP.md` §2.2 / §2.3. U1 (SWF bitmap decode) and U2/U2b (HUD) are in. This
phase adds the two selection UIs. The HUD-only capture from U2b is your visual check:
`powershell tools/ue5/capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical -Extra
'-bioshockshothud'` (add whatever key-press hook you build so the radial is open when the
shot is taken — or a debug console command that forces it open for the capture).

## What BioShock 1 does

- **Radial** (`HUDRadial.swf`) — hold a key (default Q for plasmids, or the weapon-wheel
  key). A brass Art-Deco wheel appears centre-screen with the owned weapons (or plasmids)
  as segments around it; the hovered segment highlights; the centre shows the selected
  item's name and its ammo / EVE cost in the game's HUD digit font. Release to equip.
- **Full select** (`PCWeaponSelection.swf`) — Shift pauses and shows a larger grid/list of
  every owned weapon and plasmid with names, ammo counts, EVE costs; click/key to equip.

## Art

`export-swf-images HUDRadial.swf <out>` gives: brass ring (id 14), the HUD digit glyphs
0-9 in two brightness sets (ids 239-278 — normal and highlighted), meter frame crops. The
**wheel body / segment art itself is not a tag-512 bitmap** — it's `DefineSprite` /
`DefineShape` vector. Run `swf-inspect HUDRadial.swf`, find the wheel sprite by
`swf-find HUDRadial.swf wheel` / `radial` / `ring` / `selector`, and
`export-swf-sprite HUDRadial.swf <id-or-name> <out.png>` to see it. Use it if it composes
cleanly; if the sprite decode is messy, build the wheel from the brass ring bitmap (id 14)
+ UMG segment dividers and accept a simpler wheel — note the compromise.

Weapon / plasmid ICONS: still not located as standalone art. Check `PCWeaponSelection.swf`
and `sharedlibrary.swf` (`swf-find ... pistol` / `wrench` / `plasmid` / `electro` /
`incinerate`). If they genuinely aren't extractable, use the brass ring + the item name
text per segment for U3 and record the gap precisely — do NOT author fake icons.

## What to build

1. `UShockRadialMenu` (UMG, C++ tree like `UShockHudWidget`). Bound to
   `AShockPlayer::WeaponSlots` / `EquippedPlasmids`. Open/close on a held input
   (`AShockPlayer` already has weapon-slot and plasmid-cycle input — add a "hold to open
   wheel" action, or repurpose an existing key; check `setup_playable_slice.py`'s input
   mapping steps and add one). Hovered segment from mouse angle or arrow keys; release
   equips via the existing `SelectWeaponSlot` / plasmid-equip path.
2. `UShockWeaponSelectScreen` (Shift) — pauses (`UGameplayStatics::SetGamePaused`), lists
   every owned weapon + plasmid with name / ammo / EVE, equip on click or number key,
   unpause on close.
3. `import_bioshock_ui.py` — add the radial art (ring, digit set) to `/Game/BioShockUI/Radial/`.
4. GameMode / player wires the widgets in (create once, add/remove from viewport on the
   input). Keep them out of the way of the HUD.

## Verify

- A `run_radial.py` (mirror `run_hud.py`): the widgets construct, their textures resolve
  non-null, opening the radial with N owned weapons builds N segments, releasing on a
  segment calls `SelectWeaponSlot` with that index, the select screen lists every owned
  item. Headless — no visual claim.
- `-bioshockshothud` capture with the radial forced open — attach it.
- Human confirms the feel in PIE.

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild
  (`-CleanModule` if new UPROPERTYs).
- Don't touch the HUD widget except to make sure the radial/select don't fight it for
  input or z-order.
- Update `docs/UI_ROADMAP.md` (U3 row) + `tools/ue5/README.md`.
