# StaticMeshInstance per-vertex baked lighting

Decode of the payload hanging off each placed `StaticMeshActor`'s `StaticMeshInstance`
reference. Reader: `StaticMeshInstanceReader`. Exporter: `VertexLightingExporter` /
`export-vertex-lighting`.

## Layout (CONFIRMED_BYTES)

After the tagged property list and the Vengeance `(4, 5)` header:

```
CI  StaticMesh
CI  NumLayers
per layer:
  int32 4, int32 2
  CI NumLights (1..3)
  NumLights × CI light actor
  int32 FieldA          // always 1 on every map sampled — meaning UNKNOWN
  int32 PageIndex       // 256 KiB bank index (0..255; Welcome reaches 119)
  int32 PageOffset      // 4-aligned offset within the bank
int32 VertexCount
int32 4, int32 2
int32 VertexCount       // repeat
int32 1
[padding zeros]
```

Pool address: `PageIndex * 262144 + PageOffset`, relative to the start of **page 0** inside
the package's `Level` export. Banks are contiguous. On Medical the merged coverage of
`[addr, addr + VertexCount*4)` equals Σ `VertexCount*4` with **zero overlaps**.
Same-page multi-layer instances advance by exactly `VertexCount*4`; a handful of
page-boundary placements leave padding and resume at the next page start.

Per vertex in the pool: **4 bytes `[pad, L0, L1, L2]`** (CONFIRMED on L=1 layers — energy
lives in byte 1 only). Values are 0–255 luminances (falloff × cone × visibility averages;
SDK guide ch.14). Colour and N·L are **not** stored.

## Where page 0 lives (the pool base)

**Rule:** page 0 is the first 256 KiB bank of a contiguous luminance arena embedded in the
`Level` (`MyLevel`) export. Instances address that arena with `PageIndex*262144+PageOffset`.

**What does not state the base:** exhaustive `int32` search on Medical / Fisheries /
Lighthouse found **no** stored field equal to the working base in `Level`, `Model`, or
`LevelInfo`. `Level[+32]/[+36]` is a Num==Max bulk size that *overlaps* the start of the
arena but is **not** the arena length (the pool extends past that blob). There is no
absolute page-pointer table `base, base+262144, …`.

**How the reader recovers it:** `LocateLuminancePool` places the arena so that single-light
layers show luminance energy in byte 1 (slot 0), then refines to 4-byte alignment. That is
the same consensus that lands Medical at **60224**. The absolute offset is package-local;
the *addressing rule* (contiguous 256 KiB banks from page 0) is not.

The Medical-only page-index cap of 63 was wrong: Welcome reaches page 119, Fisheries 95.

## Evaluation (same model as BSP lightmaps)

`RGB = Σ_slot luminance[slot] × lightColour × brightness × max(0, N·L)`, then a
global p75 scale (same role as `BakedLightMapExporter.GlobalScale`). N·L is
applied because the bake omits it — same statement the BSP exporter makes.

## Vertex order vs LevelSceneExporter OBJ

**Per-vertex applicable.** `LevelSceneExporter` writes static-mesh OBJs from
`LevelInstance.Geometry`, which is `StaticMeshReader.ReadGeometry` order with
no reorder. `StaticMeshInstance.VertexCount` matches that mesh's vertex count
when the mesh decodes; otherwise the exporter skips RGB and records a reason.
So the JSON `verticesRgb` stream indexes the same order as `Meshes/<mesh>.obj`.

## Per-map table

Pool base and raw-luminance coverage (fraction of layers with any non-zero L0/L1/L2 in
the first 16 verts). Full export with N·L is lower (backfaces zero out); Medical's
export pin is **3979 instances / 3280 lit / poolBase 60224**.

| Map | Decoded instances | Max page | Pool base | Layer energy frac |
|---|---:|---:|---:|---:|
| 0-Lighthouse | 914 | 38 | 28288 | 0.690 |
| 1-Medical | 3986 | 63 | **60224** | 0.757 |
| 1-Welcome | 3370 | 119 | 1082304 | 0.671 |
| 2-Fisheries | 4692 | 95 | 682624 | 0.682 |
| 2-SubBay | 1659 | 31 | 255948 | 0.724 |
| 3-Arcadia | 5553 | 71 | 872128 | 0.701 |
| 3-Market | 3218 | 37 | 1442112 | 0.833 |
| 4-Recreation | 5142 | 70 | 2524672 | 0.791 |
| 5-Hephaestus | 3691 | 79 | 5533120 | 0.767 |
| 5-Ryan | 1114 | 28 | 164480 | 0.741 |
| 6-Resi | 4475 | 72 | 478272 | 0.741 |
| 6-Slums | 3691 | 52 | 686208 | 0.702 |
| 7-BossFight | 526 | 20 | 1083584 | 0.772 |
| 7-Gauntlet | 2592 | 37 | 155908 | 0.727 |
| 7-Science | 4994 | 68 | 471364 | 0.737 |
| Autoplay | 3976 | 60 | 304828 | 0.779 |
| Entry | 0 | — | — | — |
| museum | 349 | 31 | 28600 | 0.778 |
| ChallengeRoomCombat | 4319 | 58 | 1928328 | 0.818 |
| ChallengeRoomDecoy | 1137 | 23 | 1585112 | 0.878 |
| ChallengeRoomElectric | 1670 | 23 | 808196 | 0.746 |

`Entry` has no `StaticMeshInstance` actors. A few instances per map fail body parse or point
at meshes `StaticMeshReader` cannot decode; the exporter lists each skip with a reason.
Fisheries full export (N·L): 4678 instances / 3515 lit / poolBase 682624.

## Proven by Fast tests vs inferred

| Claim | Confidence |
|---|---|
| Body layout above | CONFIRMED_BYTES (`StaticMeshInstanceLightingTests`) |
| Pool bank size 256 KiB, 4 bytes/vert, L=1 → byte1 | CONFIRMED_BYTES |
| Contiguous banks in `Level`; page 0 = arena start | CONFIRMED_BYTES (coverage packing + multi-map export) |
| Absolute page-0 offset not stored as int32 | CONFIRMED_BYTES (search) |
| Page-0 offset recovered by L=1 slot-0 consensus | CONFIRMED_BYTES (Medical 60224; all 21 maps locate) |
| FieldA == 1 always | CONFIRMED_BYTES value; meaning UNKNOWN |
| Colour × brightness × N·L live compose | PLAUSIBLE (mirrors BSP / SDK ch.14; not A/B'd vs game) |
| Vertex order = OBJ order | CONFIRMED via shared `StaticMeshReader` path |

## Open doubts

- A full `ULevel` body walk that *lands* on the arena by structure (like `BspWorld`'s
  lightmap walk) is still missing; the locator remains a validated placement, not a
  named header field.
- Some lamp-adjacent props are backfacing under authored normals after
  `MeshPlacement`, so Max(0, N·L) zeros them even when luminance is non-zero
  (e.g. `StaticMeshActor1060` / `Grate64`). Abs(N·L) would light them; the
  exporter keeps the BSP clamp.
- Multi-layer page wraps leave unused padding — not fully explained beyond
  "resume at next page".
- `Level[+16]` is 65536 on most maps and 262144 on a few (Lighthouse, BossFight, Ryan);
  it equals the luminance page size only sometimes, so it is not the page-size field.
