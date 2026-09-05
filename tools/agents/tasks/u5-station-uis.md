---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Phase U5 — station UIs: vending, Gene Bank, U-Invent, Gatherer's Garden, combo lock

`docs/UI_ROADMAP.md` §2.7. U1-U4 in. Each of these opens when the player interacts with a
station actor. Add a force-open capture flag per screen (like `-bioshockshotpause`) and
attach `_hud.png` captures.

## The five screens (art: `export-swf-images` on the named SWF, plus `sharedlibrary.swf`
which most of them ImportAssets from — `swf-find sharedlibrary.swf vend` / `gene` /
`invent` / `adam` etc.)

1. **Vending machine** (`UShockVendingMenu`) — Circus of Values / El Ammo Bandito. Machine
   face art (pause set ids 62 / 740, 2048×2048). A grid of purchasable items (ammo, first
   aid, EVE hypo, etc.) with a price; buy spends `AShockPlayer` Money; hacked machine =
   cheaper + extra stock. Bind stock to a simple per-machine item list for now (a
   `TArray<FShockVendItem>` on the station actor is fine).
2. **Gene Bank** (`UShockGeneBankMenu`, `GeneBankPC.swf`) — two columns: owned Plasmids
   and owned Gene Tonics, each row equip/unequip to a slot. Bind to
   `AShockPlayer::EquippedPlasmids` + whatever tonic state exists (`grep -ri tonic
   tools/ue5/BioShockRuntime`; if there's no tonic system, do Plasmids only and note it).
3. **U-Invent** (`UShockUInventMenu`, `craftingStationPC.swf`) — component inventory
   (glue / rubber / screws / …) + a recipe list; craft consumes components, adds the
   result. If there's no crafting-component inventory yet, show the recipe list against
   the existing `AShockPlayer` inventory stacks and note the gap.
4. **Gatherer's Garden** (`UShockGathererGardenMenu`, `PlasmidEquipStation.swf`) — spend
   ADAM on: new plasmids/tonics, an extra plasmid/tonic slot, +Health max, +EVE max. Bind
   ADAM spend to the player; apply the upgrade (`MaxHealth += N`, `MaxEve += N`,
   `EquippedPlasmids` grows).
5. **Combo lock** (`UShockComboLockMenu`, `ComboLockPC.swf`) — three number dials; correct
   3-digit code opens the linked door/container. A `Code` int on the lock actor.

## Structure

One base `UShockStationMenu : UUserWidget` (pauses on open via `SetGamePaused`, closes on
Esc/interact, common Deco frame) and the five subclasses. A station actor
(`AShockStationBase` or reuse an existing interactable) opens its menu on
`TryHackDevice`-style interact. For U5, spawning one of each behind a `bEnableSliceStations`
flag in the slice (like `bEnableSliceTurret`) so the capture can reach them is enough —
full level placement of real vending machines is a level-import concern, not this task.

## Verify

`run_stations.py` (mirror `run_status_pause.py`): each widget constructs, textures
resolve, a buy spends Money, a Gene Bank equip moves a plasmid to a slot, a Gatherer's
Garden Health upgrade raises `MaxHealth`, the combo lock opens on the right code and not
the wrong one. Headless. Force-open captures attached. Human confirms in PIE.

## Constraints

- `tools/ue5/**` only. No decoded art committed. One `BioShockRuntime` rebuild
  (`-CleanModule` for new UPROPERTYs / classes).
- Don't regress the HUD / radial / menus — run `run_hud`, `run_radial`,
  `run_status_pause` and confirm still green.
- Update `docs/UI_ROADMAP.md` (U5 row) + `tools/ue5/README.md`. Do not add a claim-table
  row to `docs/HANDOFF.md`.
