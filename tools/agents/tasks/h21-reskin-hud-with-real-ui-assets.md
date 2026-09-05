---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Reskin the in-game HUD with real decoded BioShock UI art

`UShockHudWidget` (`ShockHudWidget.h/.cpp`) currently renders health/EVE/ammo with plain
`UProgressBar`/`UTextBlock` — no original game art, no real font. This session built a
complete pipeline (already committed to `main`, `src/BioShockStudio.Core/UI/Swf/**`) that
decodes BioShock's actual Scaleform UI (compiled `.swf` files under
`ContentBaked/pc/FlashMovies/`) into real PNGs: vector shapes, embedded fonts, full
sprite/timeline composition (matrix transforms, depth ordering), and text rendering are
all working and verified against the real `HUDPC.swf` — confirmed rendering the actual
health-meter arc (`FrozenHealth_DangerBar`, character 98) and real HUD digit glyphs
(the game's own font, not a system font).

## What's available right now

CLI commands (build `src/BioShockStudio.Cli`, run via `dotnet run --project
src/BioShockStudio.Cli -c Release --`):

- `swf-find HUDPC.swf <substring>` — search ExportAssets names for a real UI element
  (case-insensitive). `swf-find HUDPC.swf health` already finds
  `FrozenHealth_DangerBar` (id 98) and its per-frame fill variants
  (`FrozenHealth_DangerBar_Fill`, id 97, ×21 — likely an animated depletion sequence,
  frame-by-frame). No "eve" or "ammo"-named export turned up in a first pass — search
  further (try "Vita", "Plasmid", "Eve", "Danger", "Meter", numeric HUD element names,
  etc.) before concluding the EVE/ammo art isn't in this file; it may be under a
  different name, or in a different FlashMovies file (`PCWeaponSelection.swf`,
  `GeneBankPC.swf` are also in that folder).
- `export-swf-shapes <file> <out-dir> [--id=N] [--size=N]` — rasterize one or every
  DefineShape character.
- `export-swf-font <file> <out-dir> [--fontId=N] [--text=chars] [--size=N]` — rasterize
  font glyphs (character-code lookup).
- `export-swf-sprite <file> <character-id-or-name-you-found> <out.png> [--size=N]` —
  composite a full DefineSprite (or bare shape) through matrix transforms and depth
  ordering into one PNG. This is what you want for a complete HUD element like the
  health arc.
- `swf-inspect <file>` — tag-type census, useful for orienting in an unfamiliar file.

Known current limitations (documented in the code, not blockers for this task unless you
hit them): no real bitmap (`DefineBits*`) decoding (none of the shapes rasterized so far
needed one — renders as a flat grey placeholder if one turns up), only the sprite's first
frame renders (no multi-frame animation), gradients render as their average color rather
than a real gradient.

## What to do

1. Find and export the real art for at least health and EVE (ideally ammo too, but don't
   force it if the art genuinely isn't findable in these files — report what you tried).
   Health is confirmed available (`FrozenHealth_DangerBar`, id 98, plus the 21 fill-level
   frames of `FrozenHealth_DangerBar_Fill`, id 97 — figure out how those 21 frames relate,
   e.g. via `PlaceObject2`'s `Ratio` field or separate `DefineSprite` characters per
   level, and pick a reasonable mapping from 0-100% health to one of them, or render one
   representative frame if the full set is out of scope for a first pass).
2. Export the chosen assets as PNGs (via the CLI commands above) into a location the UE5
   import pipeline can pick up (follow this project's existing convention for
   game-derived assets living outside the git repo — check how other imported textures
   are organized under `Content/` for the pattern to match; do not commit decoded game
   art to this repo, same rule as every other asset this project imports).
3. Import the PNGs as UE5 `Texture2D` assets (a Python import script, matching the
   pattern of every other `import_*.py` in this pipeline).
4. Change `UShockHudWidget` to display them: replace (or supplement) the plain
   `UProgressBar`/`UTextBlock` health/EVE elements with `UImage` widgets using the
   imported textures, sized/positioned reasonably. Keep ammo/text as `UTextBlock` for now
   unless you also found real font/digit art worth wiring in (this session confirmed
   HUDPC.swf's fonts decode correctly, e.g. font 5 "Century Gothic", font 13 used for the
   HUD digit "9" — real numeral glyphs are available if you want to render ammo/health
   numbers with the game's own font instead of a generic UMG text style).

## Tests / verify

Headless: confirm the widget still constructs without error and the new `UImage`
elements have a valid, non-null texture assigned after `PostLogin` adds the HUD to the
viewport (mirror `run_hud.py`'s existing pattern). Visual correctness (does it actually
look like BioShock's HUD) is a human-in-PIE check — say so explicitly rather than
asserting a "looks right" claim headlessly.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only for the UE5-side change.
  Reference the already-committed `src/BioShockStudio.Core/UI/Swf/**` C# pipeline and its
  CLI commands as a fixed, working tool — do not reimplement or modify SWF decoding
  itself as part of this task; file a separate note (don't silently work around it) if
  you find a real bug in it.
- If bitmap decoding, multi-frame animation, or a specific named asset turns out to be a
  hard blocker for something you need, say so precisely (what you tried, what's missing)
  rather than guessing/faking a substitute.
- No live UE session in this worktree — headless assertions are the evidence; a human
  confirms the actual visual result in PIE afterward.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
