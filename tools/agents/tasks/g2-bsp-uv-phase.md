---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj -c Debug --filter "FullyQualifiedName~BspUv|FullyQualifiedName~BspTextureOrigin|FullyQualifiedName~BspRunawayUvClamp|FullyQualifiedName~BspGeometry"
lane: src/BioShockStudio.Core/Level/**, src/BioShockStudio.Core/Export/**, tests/BioShockStudio.Tests/**, docs/research/bsp.md
---

# Compiled-world UVs: real origin for phase, whole-period rebase for magnitude

## Where g1 left it (read `docs/research/bsp.md` §5.3a and `BspTextureOriginTests` first)

The compiled-world texture origin is `Model.Points[surface.Base]` and it is read **correctly** —
`BspTextureOrigin.Resolve` recovers the identical world-space point from the source brush
(6,242/6,242 comparable surfaces on 1-Medical, ≤1 cm). The pan is genuinely baked into a point
~25,750 cm from the face.

- Measuring the projection from that real origin: **cross-face phase is exact** — at a shared
  vertex of two coplanar same-material faces the ΔUV is **0**.
- Measuring from `polygon[0]` (current production): phase is lost — median ΔUV **1,085 texels** at
  the shared vertex, i.e. a visible seam where a texture should run unbroken across a BSP cut.
- The real origin's cost: absolute texel values reach ~60,000, and a UE `StaticMesh` stores UV0 as
  a 16-bit half-float by default, whose step at that magnitude is ~32 texels — the texture swims
  and the GPU picks the wrong mip.

## The fix

Use the **real origin** for the projection, then **rebase each face by a whole number of texture
periods** so the stored numbers are small while `frac(UV)` — everything the sampler and phase
depend on — is byte-identical.

Two coplanar faces A, B share vertex v. With the real origin both compute the same `UV(v)` (same
formula, same origin) → ΔUV = 0. Subtract from A every UV of `round(centroidUV_A)` **whole tiles**
and from B `round(centroidUV_B)` whole tiles. At v: `UV_A' − UV_B' = round(centroidUV_B) −
round(centroidUV_A)` — an **integer**. `frac(UV_A') == frac(UV_B')`, so a wrapping sampler draws
the texture continuous across the cut regardless. Magnitude is now ≤ ~1 tile + the face's own span.

### Implement

1. **Wire the real origin into the production path.** `LevelScene.AddBuiltWorld`
   (`src/BioShockStudio.Core/Level/LevelScene.cs`) builds the compiled-world `LevelInstance`. It has
   the `BioShockPackage` and can get the `LevelContext` (it already calls `LevelAnalyzer` elsewhere,
   or pass what `AddBuiltWorld` receives). Call `BspTextureOrigin.Resolve(package, world, context)`
   and pass the result as the new `surfaceOrigins` arg to `BspGeometry.ToGeometry(world, null,
   origins)` and `ToLightMapBatches(world, origins)`. Where `origins[surface]` is null (cross-package
   brush, ~6.4% on Medical), `ToGeometry` already falls back to `polygon[0]` — keep that.

2. **Whole-period rebase, in `BspGeometry.NormaliseUvs(MeshGeometry, sizes)`** — it is the one place
   the UVs are already in *tile* units (post-divide), so a whole period is `1.0`. For each section
   with a resolved size, walk its faces (the fan-pivot grouping `ClampRunawayFaceUvs` already uses),
   and for each face:
   - `centre = (min(uv) + max(uv)) / 2` over the face's distinct vertices, per axis;
   - `k = round(centre)` per axis (a `Vector2` of integers);
   - subtract `k` from every one of that face's vertex UVs.
   Do this **before** `ClampRunawayFaceUvs` (most faces will no longer need clamping). A face whose
   own span exceeds the clamp cap still gets clamped afterwards — that path is unchanged.

   Faces on a section that resolved **no** size stay in raw texels (nominal 512 divide already
   happens in g1's `NormaliseUvs`); rebase them too, treating one period as `1.0` after that divide.

3. **`polygon[0]` stays as the fallback** for null-origin surfaces, and the `ClampRunawayFaceUvs`
   backstop stays. Do not remove either.

## Tests (extend `BspTextureOriginTests` / `BspUvTests`, `[Trait(Tiers.Name, Tiers.Sweep)]`)

- **Phase preserved:** after the real-origin + rebase pipeline, the shared-vertex ΔUV between
  coplanar same-material face pairs, taken as `frac`, is ~0 (well under 0.02 tiles median) — i.e.
  the seam g1 measured at 1,085 texels is gone. Assert it.
- **Magnitude sane:** the post-`NormaliseUvs` per-vertex UV magnitude on 1-Medical's compiled world
  has median ≤ ~2 and p99 ≤ the clamp cap. Assert median and p99.
- **Sampling unchanged by the rebase:** for a sample of faces, `frac(uv_before_rebase) ==
  frac(uv_after_rebase)` within 1e-3. Assert.
- `BspUvTests.PreparedBrushUvsAreNormalisedAgainstTheirTextures` and the `BspRunawayUvClamp*` tests
  stay green.

## Then regenerate and record

```
export BIOSHOCK_ORIGINAL_TEXTURE_DIR="G:\SteamLibrary\steamapps\common\Bioshock\Builds\Release\UmodelExport\1-Medical\Texture"
dotnet run --project src/BioShockStudio.Cli -- export-level "G:\SteamLibrary\steamapps\common\BioShock Remastered\ContentBaked\pc\Maps\1-Medical.bsm" <tmpdir>
```

`<tmpdir>/1-Medical/Meshes/Model1_20761.obj` — put the `vt` magnitude percentiles (p50/p90/p99/max)
and the clamp-hit count in the task RESULT vs the current numbers (p50 1.0, p90 3.8, p99 12, max
~12.7, ~1,050 verts clamped). You cannot run the UE editor from the worktree.

## Constraints

- Lanes: `src/BioShockStudio.Core/Level/**`, `src/BioShockStudio.Core/Export/**`, `tests/**`,
  `docs/research/bsp.md`. Not `tools/**`, not `src/BioShockStudio.Cli/**` beyond running it.
- Smallest correct change. Every existing test green.
- `DISCOVER → VERIFY → RECORD`. Label claims. Do not commit or push.
- If the rebase does NOT preserve `frac` for some faces (e.g. a face genuinely spanning > 1 period
  where `round(centre)` is ambiguous) — measure how many, and if it is a real problem, rebase by
  `floor(min(uv))` instead of `round(centre)` (still a whole period, just anchored at the low
  corner). Record which you used and why.
- Update `docs/research/bsp.md` §5.3a with the final pipeline and the before/after seam + magnitude
  numbers.
