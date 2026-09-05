# BioShock UI — research and recreation roadmap

**Written 5 Sept 2026.** The in-game UI has been reworked piecemeal (h21 reskin, h23 layout,
both reverted) against a wrong assumption: that BioShock's real UI art could not be decoded.
It can. This document is the research and the plan to recreate the whole UI from the real
assets, executed by the Cursor worker phase by phase rather than nibbled at.

---

## 1. The key finding — the art was never blocked

Every BioShock UI screen is a Scaleform movie under
`<game>/ContentBaked/pc/FlashMovies/*.swf` (the original BioShock 1 install has the same
files under `Content/FlashMovies/`; they are byte-identical in structure). The `.swf.gsc`
sidecars are the GFx-compiled runtime form — ignore them; the `.swf` is the source.

Our SWF pipeline (`src/BioShockStudio.Core/UI/Swf/**`) decodes vector shapes, fonts, sprite
timelines and text. It skipped **tag 512**, which prior notes called an undecodable
"Scaleform tag-512 bitmap". That was wrong.

**tag 512 is a raw DXT texture block.** Body layout (all little-endian):

```
u16 characterId
u16 width
u16 height
u16 format      # 4 = DXT5, 0 = DXT1  (observed)
u16 flags       # 0 in every HUD/pause/radial/shared sample
<width*height   bytes for DXT5>   OR   <width*height/2 bytes for DXT1>
```

Proven 5 Sept 2026: decoding `HUDPC.swf`'s 14 tag-512 blocks as DXT5/DXT1 with our existing
DXT decoder produces the real HUD chrome — the rusted Art-Deco pill-shaped health/EVE meter
frames, the parchment label plates, the brass plasmid/weapon rings. `sharedlibrary.swf`
yields 73 images, `HUDRadial.swf` 28 (including the real HUD digit glyph set 0-9),
`pausePC.swf` 49 (BioShock logo, first-aid-kit and EVE-hypo art, vending/Gatherer's Garden
machine faces, Deco chevron markers, character status roundels, the quest arrow).

Proof scripts (throwaway, in `%TEMP%`): `dxt512.py`, `dxt_any.py`. They are the reference
for the C# implementation, not production code.

Two more unknown tags checked while implementing U1 (5 Sept 2026):

- **tag 12** (30× in HUDPC) — standard SWF **`DoAction`**. Bodies are ActionScript
  bytecode (ActionDefineFunction2 / ActionConstantPool / ActionPush / …); 29/30 parse as
  clean ACTIONRECORD streams ending in ActionEnd. **Not** DefineScalingGrid / atlas-rect.
  We are not building an AS interpreter; Phase U2 measures 9-slice insets on the meter
  frames by hand.
- **tag 34** (38× in PCWeaponSelection) — standard SWF **`DefineButton2`** (buttonId +
  flags + button records carrying more DoAction). Noted only; not on U1/U2 critical path.

Tag 78 (`DefineScalingGrid`) is the real 9-slice tag in the SWF spec; it was not observed
as the mystery payload here.

---

## 2. BioShock 1 UI — what each screen is

Sources: Feral Remastered manual, BioShock wiki in-game help captions, the SWF file set,
decoded art.

### 2.1 HUD (`HUDPC.swf`) — **positions are not what the reworks assumed**

- **Upper-left corner** (wiki, verbatim: *"the red bar in the upper left hand corner"* /
  *"the blue EVE Bar in the top left corner"*):
  - **Health** — horizontal bar, red liquid fill that shrinks with damage, in a rusted
    Deco pill frame. Medical-cross icon at its left end; the number beside it is the
    First Aid Kit count (max 5).
  - **EVE** — below health, same frame, blue liquid fill. Hypo-needle icon at its left
    end; number is the EVE Hypo count (max 5).
- **Lower-right** — active weapon: weapon icon in a brass ring/holder, current-clip count
  in the game's own HUD digit font (large), reserve + ammo-type secondary.
- **Lower-left** — active plasmid icon in a brass ring.
- **World-space** — quest arrow (the white Deco chevron, id 404 in pause set) floating
  toward the current objective.
- **Screen edges** — red directional damage indicators on hit.
- **Top-center** — subtitles, "Found: X" pickup toasts, "Objective updated" toasts,
  security-alarm warning, interact prompts ("Search", "Hack", "Hold to...").
- **Center** — per-weapon / per-plasmid crosshair.
- Full-screen overlays: bottom vignette gradient (id 177, 4096×256), damage/low-health
  desaturation.

### 2.2 Radial select (`HUDRadial.swf`)
Hold-to-open radial. Two rings — weapons and plasmids — brass Deco wheel, slots arranged
radially with the icon art, highlighted segment on the hovered slot, name + ammo/EVE
readout in the center. Real digit glyphs decoded (id 239-278, two sets).

### 2.3 Full weapon/plasmid screen (`PCWeaponSelection.swf`) — Shift
Paused overlay; larger grid of every owned weapon and plasmid with names, ammo, EVE cost.

### 2.4 Status menu (`mapsPC.swf` + `ingamemanualPC.swf`) — M
Four tabs: **Map** (level plan, player marker, objective markers, zoomable), **Goals**
(active objective list, switchable priority), **Messages** (audio diary + radio replay),
**Help** (mechanics reference).

### 2.5 Pause (`pausePC.swf`) — Esc
BioShock logo, current Money and ADAM, Little Sisters remaining on the level, Resume /
Save / Load / Options / Main Menu / Quit. Deco chevron selection markers.

### 2.6 Main menu
New Game (Easy / Medium / Hard / Survivor), Continue, Load Game, Options, Credits,
Director's Commentary, Museum, Challenge Rooms, Exit. (No standalone `mainmenu.swf` in the
file list — the menu is likely assembled from `sharedlibrary.swf` + container movies;
confirm during Phase U6.)

### 2.7 Station UIs
- **Vending** — Circus of Values / El Ammo Bandito: brass machine face (id 62 / 740 in
  pause set, 2048×2048), item grid, price in Money, hacked = discount + extra stock.
- **Gene Bank** (`GeneBankPC.swf`) — owned plasmids + tonics, equip/unequip to slots,
  cross-location storage.
- **U-Invent** (`craftingStationPC.swf`) — component inventory (glue/rubber/screws/…),
  recipe list, craft.
- **Gatherer's Garden** (`PlasmidEquipStation.swf`) — spend ADAM on new plasmids/tonics,
  slot count, Health/EVE max upgrades.
- **Combo lock** (`ComboLockPC.swf`) — 3-dial safe.

### 2.8 Hacking minigame (`hackingPC.swf`)
Pipe-tile puzzle board: reveal and swap tiles to route the flow from source to target
before the fluid arrives; hazard tiles (speed-up, overload, alarm). Buy-out for Money,
Auto-Hack Tool for instant success.

### 2.9 Other
Bathysphere travel (`BathyspherePC.swf`), Vita-Chamber respawn, research camera overlay +
research-reward screen, Little Sister harvest/rescue choice, plane-crash intro sequence
(`PlaneSequenceContainer.swf`), loading screens, the tutorial "PlasmiNow"/comic
containers, ending movies.

---

## 3. Strategy

**Recreate each screen in UMG (C++ widget trees, matching `UShockHudWidget`'s existing
pattern) using the real decoded art, positioned and coloured to match the real game.**
Not a from-scratch reinterpretation, not a decode-the-timeline-and-replay-it emulator
(Scaleform ActionScript is out of scope). Extract the art, rebuild the layout by hand
against reference screenshots.

Where a bitmap is a 9-slice frame (the meter housings, plates, panels), slice it by hand
(tag 12 is DoAction AS, not a scaling grid — see §1). Where the real font is available
(decoded DefineFont2/3 + the digit-glyph bitmaps), use it. Tint fills from the vector
`DefineShape` colours already decoded.

Data binding stays as-is — the HUD already reads `AShockPlayer` / `AShockWeapon`; new
screens bind to the existing gameplay systems (inventory, plasmids, hacking subsystem,
weapon defs, quests).

---

## 4. Phases (each = one Cursor task)

| # | Phase | Deliverable | Depends on | Status |
|---|---|---|---|---|
| **U1** | SWF bitmap decode | tag-512 (DXT5/DXT1) + CLI `export-swf-images` + `tools/ue5/export_all_ui_images.py`; HUDPC regression (14 bitmaps). Tag 12 turned out to be genuine `DoAction` AS bytecode (not 9-slice) — U2 measures meter insets by hand. Tag 34 is standard `DefineButton2` (noted; not on critical path). | — | **done 5 Sept 2026** |
| **U2** | Art import + HUD | `import_bioshock_ui.py` brings the extracted HUD/shared PNGs into `/Game/BioShockUI/**` as `Texture2D`. Rebuild `UShockHudWidget`: health+EVE **upper-left** in the real frames with kit/hypo counts and icons; weapon cluster lower-right with the real digit font; plasmid lower-left; crosshair; damage-direction; pickup/objective toasts top-center; bottom vignette. **U2b (5 Sept 2026):** cavity-punched meter frame + `T_Hud_FillMask`; fill under frame so liquid stays inside the pill; health fill uses `EnsureHealthInitialized` + `GetMaxHealth` (was empty while EVE drew); cap icon + HUDRadial digit on each meter; weapon ring+name always, ammo digits only when `bEnforceAmmo`; meters ~560×116 at (28,28); `-bioshockshothud` grey clear via `ClearRenderTarget2D`. | U1 | **done 5 Sept 2026** (U2b fill/readout pass same day). Visual likeness still a human PIE / `capture_shot.ps1 -Extra '-bioshockshothud'` check. Gap: per-weapon / per-plasmid icon bitmaps not located — brass ring + name text. |
| **U3** | Radial + full select | `UShockRadialMenu` (hold **V** weapon / **Q** plasmid wheel) + `UShockWeaponSelectScreen` (**Shift**). Brass ring id 14 + HUDRadial digits under `/Game/BioShockUI/Radial/`; segment labels = item names (no fake icons). Wheel body is DefineSprite/Shape — not used; UMG ring + labels instead. Capture: `-bioshockshothud -bioshockshotracial`. | U1, U2 | **done 5 Sept 2026** (headless `run_radial.py`; visual = human PIE / capture) |
| **U4** | Status + pause | `UShockStatusMenu` (**M**, Map/Goals/Messages/Help) + `UShockPauseMenu` (**Esc**). Art: `/Game/BioShockUI/Status/` (mapsPC tabs/panels + HUDPC help posters) and `/Game/BioShockUI/Pause/` (logo 1248, chevrons 223/228). Goals=`GetActiveQuestNames`; Messages empty until diaries wired; Map placeholder + coords. Pause: Money/`GetAdam`/Little-Sister count; Resume+Quit wired; Save/Load/Options/Main Menu log stubs. Capture: `-bioshockshothud -bioshockshotstatus` / `-bioshockshotpause`. | U1 | **done 5 Sept 2026** (headless `run_status_pause.py`; visual = human PIE / capture) |
| **U5** | Station UIs | Vending, Gene Bank, U-Invent, Gatherer's Garden, combo lock — bound to inventory / plasmid / ADAM / money systems. `UShockStationMenu` + five subclasses; `AShockStationBase` interact; slice `bEnableSliceStations`. Capture: `-bioshockshothud` + `-bioshockshotvend` / `genebank` / `invent` / `garden` / `combo`. Gaps: no tonic system (Gene Bank = plasmids only); U-Invent uses inventory stacks (no component bag). | U1, U4 | **done 5 Sept 2026** (headless `run_stations.py`; visual = human PIE / capture) |
| **U6** | Hacking minigame | `hackingPC.swf` pipe puzzle recreated as an interactive UMG widget bound to `UShockSecuritySubsystem` / `TryHackDevice`. `UShockHackingMinigame`: difficulty-scaled board, flood-fill path, fluid timer, hazard tiles (speed-up / overload / alarm), Money buy-out, Auto-Hack Tool. Pipe tiles = UMG shapes (vector sprites deferred). `bInstantHack` keeps the C3 skill-check path for `run_hacking` / `run_security`. Capture: `-bioshockshothud -bioshockshothack`. | U1 | **done 5 Sept 2026** (headless `run_hacking_minigame.py`; visual = human PIE / capture) |
| **U7** | Menus + frontend | Main menu (9 entries + pause logo/chevron), difficulty select (Easy/Medium/Hard/Survivor), save/load slots (`UShockSaveGame` ↔ `UShockCarryState`), loading screen (PreLoadMap), stub Options/Credits/Commentary/Museum/Challenge Rooms. First map = `/Game/BioShockSlice/1-Medical`. Background = dark Deco gradient (no still plate). Plane intro deferred. | U1 | **done 5 Sept 2026** (headless `run_frontend.py`; visual = `capture_shot.ps1 -Map /Game/BioShockUI/MainMenu`) |
| **U8** | Polish | research overlay, Vita-Chamber, Little Sister choice, subtitles styling, localisation text hookup (`Localized*.lbf`). | U2-U7 | |

Do **not** run these in parallel — they all rebuild `BioShockRuntime` and share the
HostProject. One at a time, reviewed and committed before the next.

---

## 5. Constraints (every phase)

- Art extraction lands outside the repo (same rule as every other imported asset). The
  extractor and import scripts are committed; the PNGs/textures are not.
- `src/BioShockStudio.Core/UI/Swf/**` + `src/BioShockStudio.Cli` for the decoder (Claude's
  C# lane historically, but this is one connected effort — whoever takes U1 owns it end to
  end). `tools/ue5/**` for the UMG + import side.
- Headless verify proves the widget constructs and its images resolve to non-null textures;
  **visual correctness is a human PIE / capture-harness check** — `tools/ue5/capture_shot.ps1`
  can now photograph the running HUD (`-bioshockstartslot=N` picks the weapon).
- No commit of decoded game art. Update this file's phase table and `tools/ue5/README.md`
  as phases land.
