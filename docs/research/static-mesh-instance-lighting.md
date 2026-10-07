# StaticMeshInstance per-vertex baked lighting

Medical (`1-Medical.bsm`) decode of the payload hanging off each placed
`StaticMeshActor`'s `StaticMeshInstance` reference. Reader:
`StaticMeshInstanceReader`. Exporter: `VertexLightingExporter` /
`export-vertex-lighting`.

## Layout (CONFIRMED_BYTES on Medical)

After the tagged property list and the Vengeance `(4, 5)` header:

```
CI  StaticMesh
CI  NumLayers
per layer:
  int32 4, int32 2
  CI NumLights (1..3)
  NumLights × CI light actor
  int32 FieldA          // always 1 on Medical — meaning UNKNOWN
  int32 PageIndex       // 256 KiB bank index
  int32 PageOffset      // 4-aligned offset within the bank
int32 VertexCount
int32 4, int32 2
int32 VertexCount       // repeat
int32 1
[padding zeros]
```

Pool address: `PageIndex * 262144 + PageOffset`, relative to a base offset
inside the package's `Level` export. On Medical the merged coverage of
`[addr, addr + VertexCount*4)` equals Σ `VertexCount*4` with **zero overlaps**.
Same-page multi-layer instances advance by exactly `VertexCount*4`; a handful
of page-boundary placements leave padding and resume at the next page start.

Per vertex in the pool: **4 bytes `[pad, L0, L1, L2]`** (CONFIRMED on L=1
layers — energy lives in byte 1 only). Values are 0–255 luminances
(falloff × cone × visibility averages; SDK guide ch.14). Colour and N·L are
**not** stored.

## Evaluation (same model as BSP lightmaps)

`RGB = Σ_slot luminance[slot] × lightColour × brightness × max(0, N·L)`, then a
global p75 scale (same role as `BakedLightMapExporter.GlobalScale`). N·L is
applied because the bake omits it — same statement the BSP exporter makes.

Pool base on Medical: **60224** (scored by L=1 layers having energy in slot 0).

## Vertex order vs LevelSceneExporter OBJ

**Per-vertex applicable.** `LevelSceneExporter` writes static-mesh OBJs from
`LevelInstance.Geometry`, which is `StaticMeshReader.ReadGeometry` order with
no reorder. `StaticMeshInstance.VertexCount` matches that mesh's vertex count
(3979/3986 live Medical instances; 7 meshes `StaticMeshReader` cannot decode
yet are skipped at export). So the JSON `verticesRgb` stream indexes the same
order as `Meshes/<mesh>.obj`.

## Proven by Fast tests vs inferred

| Claim | Confidence |
|---|---|
| Body layout above on Medical | CONFIRMED_BYTES (`StaticMeshInstanceLightingTests`) |
| Pool bank size 256 KiB, 4 bytes/vert, L=1 → byte1 | CONFIRMED_BYTES |
| Pool sits in `Level` export; base found by score | CONFIRMED_BYTES (base value package-local) |
| FieldA == 1 always | CONFIRMED_BYTES value; meaning UNKNOWN |
| Colour × brightness × N·L live compose | PLAUSIBLE (mirrors BSP / SDK ch.14; not A/B'd vs game) |
| Vertex order = OBJ order | CONFIRMED via shared `StaticMeshReader` path |

## Open doubts

- Pool base locator is a score over L=1 probes, not an absolute header pointer.
  Medical lands at 60224; other maps untested.
- Some lamp-adjacent props are backfacing under authored normals after
  `MeshPlacement`, so Max(0, N·L) zeros them even when luminance is non-zero
  (e.g. `StaticMeshActor1060` / `Grate64`). Abs(N·L) would light them; the
  exporter keeps the BSP clamp.
- Seven Medical instances point at meshes `StaticMeshReader` cannot decode;
  export skips RGB for those.
- Multi-layer page wraps (7 on Medical) leave unused padding — not fully
  explained beyond "resume at next page".
