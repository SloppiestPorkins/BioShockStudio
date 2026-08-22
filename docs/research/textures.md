# Textures — what the container declares, and what it does not

**Status: censused across all 33 packages, 23 Aug 2026.** 30,831 `Texture` exports and 287
`Cubemap` exports. Written for Gate 1 item 3 ("colour-space/normal/mask/cubemap intent as
UE5-facing metadata"). Pinned by `TextureIntentCensusTests` and `TextureIntentTests`.

## The headline: colour space is not declared anywhere

**Not one of the 30,831 shipped textures carries an `sRGB`, `CompressionSettings` or
`MipGenSettings` property.** The last two appear in Nyko's SDK property-name list, which is what
made them look like a decode target; the shipped game never serialises them. This is the same shape
as Gate 1 item 1's socket answer — the item's phrasing invited a search for something the container
does not have.

So **colour space is inferred from usage and labelled as inferred** (`TextureColourSpace`), never
presented as decoded fact. Base colour and emissive are sRGB; normal, mask and height are linear.
An unidentified texture resolves to sRGB deliberately: base colour is by far the commonest binding
and the failure is asymmetric — a colour map sampled linearly is an obvious visible error, the
reverse is a subtle distortion of a map most consumers re-author anyway. The originating slot is
carried alongside so the inference can be audited rather than trusted.

## What the container does declare

| Property | Count | Meaning |
|---|---|---|
| `Format` | 30,824 | 3=DXT1 (24,847), 8=DXT5 (3,458), 7=DXT3 (2,121), 12=3Dc (273), 5=RGBA8 (125) |
| `UClampMode` / `VClampMode` | 3,467 / 3,586 | `CONFIRMED_EXTERNAL` against UModel's `ETexClampMode`. **Always value 1 (clamp)** |
| `bAlphaTexture` | 722 | alpha is for blending |
| `bMasked` | 105 | alpha is a cutout |
| `bTwoSided` | 63 | |
| `LODSet` | 7 | effectively unused |

**Clamp is written only to say "clamp".** Every one of the ~3,500 occurrences carries value 1, so
an absent property means wrap — which is why the reader maps absence to `TextureAddress.Wrap`
rather than to unknown.

**Normal-map intent has two independent sources**: the binding slot's name, and format 12 (3Dc),
which this game uses for nothing else — all 273 exports declaring it are normal maps. Format alone
is therefore sufficient when no slot is known.

## A serialised bool is not necessarily true

`bStreamable` is written on **4,374** textures and is **`False` on every one of them**. So
"the property is present" and "the flag is set" are different claims in this game, and any reader
testing presence is wrong on those textures.

The value lives in **bit 7 of the property's info byte** — the same bit that is the array flag for
every other type, which is exactly why the array index is not read for `Bool`. `UnrealProperty` was
discarding it; it is now exposed as `UnrealProperty.BoolValue`.

`bMasked`, `bAlphaTexture` and `bTwoSided` happen to be true wherever they appear, so a presence
test gives the right answer for those three today and the wrong one for the fourth flag anybody
reuses it on. `TextureIntentCensusTests` asserts both halves so the distinction cannot rot.

## A trap in reading the values

These are **UE2 enums serialised in one byte**. `UnrealProperty.AsInt()` returns 0 for any value
shorter than four bytes rather than failing, so reading them with it reports every `Format` in the
game as 0 — which the reader's own DXT1/DXT5/3Dc handling immediately contradicts. The first cut of
the census did exactly this and produced a clean, plausible, entirely wrong table. Use `AsByte()`.

## Still open

- **Cubemaps are undecoded.** 287 exports of a distinct `Cubemap` class, and materials name
  `ReflectionCubemap` / `UseSpecularCubemaps`. `TextureIntent` has a `Cubemap` usage for the slot
  side, but nothing reads the class's payload — face layout, ordering and whether the faces are
  separate `Texture` objects are all `UNKNOWN`.
- **No representative UE5 import has been validated.** The metadata is exported and unit-tested;
  it has not been round-tripped through UE5 and looked at, which is the other half of the item.
- **A few diffuse slots resolve to something that is not a base colour** — `GraniteColor_NOR` and
  `facade_side_normal` are normal maps, `BulletConcDecal_Heightmap` is a heightmap. Whether that is
  the game's own authoring or this project's slot walk is `UNKNOWN`. See `materials.md`.
