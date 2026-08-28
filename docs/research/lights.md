# Placed light actors

Not the baked lightmaps (`bsp.md` §5.5) — the dynamic `Light`-family actors placed in a level, and
the parameters each one carries. `LevelLightReader` reads them; `LevelLightFieldTests` (Sweep) is
the census this note records.

## The seven parameters

BioShock's Vengeance engine writes light parameters with **different types** from stock UE2.5, which
is why the first three sat unread until Nyko's SDK (`bioshock1-bsm.md` §C.6) named the divergence.

| Property | Type here | Stock UE2.5 | Confidence | Notes |
|---|---|---|---|---|
| `LightColor` | `StructProperty:Color` (FColor BGRA) | `LightHue` + `LightSaturation` bytes | `CONFIRMED_BYTES` | Same 4-byte BGRA `MaterialReader` reads. Alpha meaning `UNKNOWN`. |
| `LightBrightness` | `FloatProperty`, 0.0–3.1, median 1.0 | byte 0–255, default 64 | `CONFIRMED_BYTES` | 1.0 = "normal". No unit conversion applied. |
| `LightRadius` | `FloatProperty`, world units, 0–120 000, median 2048 | byte, `WorldRadius = 25·(b+1)` | `CONFIRMED_BYTES` | World centimetres. |
| `LightCone` | `Byte` | `Byte` (spot aperture) | value `CONFIRMED_BYTES`; semantic `PLAUSIBLE` | Written by **3,343 of 10,917** lights with a non-zero value (+22 that write an explicit `0`). A light that writes it casts a cone, not a sphere — a first-class spotlight signal even without the exact byte→angle formula. Range 1–255. |
| `LightType` | `Byte` | `ELightType` enum | value `CONFIRMED_BYTES`; enum `PLAUSIBLE` | 940 lights write it. Values seen: **0, 2, 3, 4, 5, 7, 9** — 4 (`LT_Flicker` under stock) the most common (331). Every value is inside stock `ELightType`'s 0–9 range and **1 (`LT_Steady`, the default) never appears** — consistent with "only non-steady lights bother writing it". Not confirmed against BioShock's own `Engine.U` — this project's decompiler cannot read that package. |
| `LightEffect` | `Byte` | `ELightEffect` enum (20 values) | value `CONFIRMED_BYTES`; semantic `UNKNOWN` | 2,040 lights write it and **1,927 of them write exactly `2`** (the rest: 1 or 3). A 20-value enum does not look like that. The stock reading (2 = `LE_FireWaver`) is therefore rejected — value 2 is most likely Vengeance's repurposed "normal light" path. Surfaced raw so the near-constant is visible. |
| `LightPeriod` | `Byte` | `Byte` (animation timing) | value `CONFIRMED_BYTES`; semantic `PLAUSIBLE` | 1,085 lights write it, spread across the whole 0–255 range. The rate/period for whichever animated `LightType` is set. |

Census: `LevelLightFieldTests.TheFourAddedLightFieldsDecodeAndTheirWholeGameCensusHolds`, 21 base
maps, 28 Aug 2026.

## The falloff exponent — there is no authored one

`docs/UE5_FULL_PORT_PLAN.md` §5 Phase 1.4 tracked a "falloff exponent still `UNKNOWN`". Resolved 28
Aug 2026: a `Light` actor carries the seven parameters above and **no spatial-falloff field**
(`properties 0-Lighthouse --class Light`; Nyko §C.6 lists the same set). UE2.5 point lights use an
engine-fixed falloff curve, so matching it in UE5 is a render A/B against the running game, not a
decode — and the static look is lightmap-dominated regardless.

## What is still open

- **The `LightType` and `LightEffect` enums** are not pinned to BioShock's own definitions. Stock
  `ELightType` is `PLAUSIBLE` from the value distribution; `LightEffect`'s meaning is genuinely
  `UNKNOWN`. Pinning needs `Engine.U` to decompile (currently a hard failure in `tools/uelib-bridge`)
  or in-editor observation.
- **`LightCone` byte → cone angle.** Stock UE2.5 scales an aperture to 0–255; not verified against
  BioShock's renderer. "Is a spotlight" is solid; the exact angle is not.
- **The manifest does not carry these four fields yet.** `LevelLightDocument` still exports
  colour/brightness/radius only. Adding cone/type/effect/period is a schema bump — coordinate with
  the Cursor lane's `import_level.py` (which would gain `SpotLight` spawning and flicker).
- **`LevelAnalyzer.Interpreted`** does not list any `Light*` property, so the uninterpreted-property
  census still counts all seven as unread. Pre-existing (the original three were never added either);
  fixing it moves a coverage figure and needs the classify-before-touching pass (`ENGINEERING_RULES.md`
  §24).
