---
worker: cursor
base: main
verify: dotnet test --filter Tier=Fast
lane: src/BioShockStudio.Core/UI/Swf/**, src/BioShockStudio.Cli/**, tools/ue5/*.py
---

# Phase U1 — decode the SWF bitmap tags; extract every BioShock UI image

Context: `docs/UI_ROADMAP.md` (read it). The whole "BioShock UI art can't be decoded"
premise was wrong. Every UI screen is a Scaleform `.swf` under
`<game>/ContentBaked/pc/FlashMovies/`, and the bitmap chrome lives in **tag 512**, which
our SWF pipeline currently skips. It is a plain raw DXT texture — we already have a DXT
decoder.

## tag 512 format (reverse-engineered 5 Sept 2026, confirmed on HUDPC.swf)

Tag body, all little-endian:

```
u16 characterId
u16 width
u16 height
u16 format      # 4 => DXT5 (BC3),  0 => DXT1 (BC1)
u16 flags       # 0 in every HUD / pause / radial / sharedlibrary sample seen
raw payload:    width*height bytes           when format == 4  (DXT5, 1 byte/px)
                width*height/2 bytes          when format == 0  (DXT1, 0.5 byte/px)
```

HUDPC.swf has exactly 14 tag-512 blocks. Sizes seen there: 128×128, 256×128, 2048×1024
(five of them — the chrome atlases), 4096×256 (the bottom vignette gradient). `sharedlibrary.swf`
has 73, `HUDRadial.swf` 28 (includes the real HUD digit glyphs 0-9), `pausePC.swf` 49.

Throwaway proof scripts that already do this correctly: `%TEMP%\dxt512.py`, `%TEMP%\dxt_any.py`
(python). Port that logic to C#, do not ship the python.

## Also look at

- **tag 12** — 30× in HUDPC. Standard SWF tag 12 is `DoAction`, but that makes no sense
  in a GFx movie of mostly ExportAssets. It is very likely the atlas sub-rectangle /
  `DefineScalingGrid` (9-slice) tag that maps the vector `DefineShape` fills onto the big
  2048×1024 bitmap atlases. Decode it if you can — Phase U2 needs the 9-slice grid for the
  meter frames to scale without distortion. If it resists a clean decode, record the byte
  layout you found and move on (measuring the slice insets by hand is an acceptable
  fallback for U2).
- **tag 34** — 38× in PCWeaponSelection.swf. Note it; not on U1's critical path.

## What to build

1. **Decoder** in `src/BioShockStudio.Core/UI/Swf/` — a `SwfBitmapReader` (mirror the
   style of `SwfShapeReader` / `SwfFontReader`). Parse the tag-512 header, hand the DXT
   payload to the existing `BioShockStudio.Core.Textures.BlockCompression` (it has
   `DecodeDxt1Block` / `DecodeDxt5Block` — reuse, don't reimplement), return an RGBA8
   image + its characterId. Wire tag 512 into `SwfFile`'s tag stream / the character
   dictionary so `SwfCharacterDictionary` can resolve a bitmap by id and by any
   `ExportAssets` name pointing at it.
2. **CLI** — `export-swf-images <file.swf> <out-dir> [--id=N]` in `Program.cs` (match the
   verb style of the existing `export-swf-*` commands). Writes one PNG per tag-512 bitmap,
   named `<id>.png` (and `<exportName>.png` symlink/copy when a name resolves), plus a
   `swf_images_manifest.json` listing id, name, width, height, format, and any
   `ExportAssets` / `ImportAssets` name bound to that id.
3. **Bulk extract driver** — `tools/ue5/export_all_ui_images.py` (no Unreal; shells the
   CLI) that runs `export-swf-images` over every `*.swf` in the FlashMovies dir into
   `%BIOSHOCK_UI_EXPORT%` (default `%TEMP%/bioshock-ui`), one subdir per movie, and writes
   a top-level catalogue. This is the raw material for Phase U2's `import_bioshock_ui.py`.

## Tests / verify (`dotnet test --filter Tier=Fast`)

- `SwfBitmapReaderTests` — HUDPC.swf yields exactly 14 bitmaps; assert the id/size/format
  of at least the five 2048×1024 DXT5 atlases and the 4096×256 one; assert a couple decode
  to non-empty, non-uniform RGBA (a stddev floor, same discipline as `capture_shot.ps1`).
- A `swf-inspect` regression: tag 512 now shows as `DefineBitsDxt` (or similar) not
  `Unknown(512)`.
- Do NOT add a Sweep-tier test that decodes all 73 sharedlibrary images unless it stays
  under a second or two.

## Constraints

- Reuse `BlockCompression`; do not add a second DXT path.
- Do not commit any extracted PNG. The scripts are committed; the art is not.
- Do not touch the shape/font/sprite readers except to register the new tag.
- If tag 12 turns out to be genuine `DoAction` bytecode (ActionScript), say so and stop —
  we are not building an AS interpreter; U2 measures the 9-slice insets by hand.
- Update `docs/UI_ROADMAP.md` (mark U1 done, note what tag 12 / tag 34 turned out to be)
  and `tools/ue5/README.md` once `dotnet test --filter Tier=Fast` passes.
