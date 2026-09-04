---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj -c Debug --filter "FullyQualifiedName~BspTextureOrigin|FullyQualifiedName~BspRunawayUvClampTests"
lane: src/BioShockStudio.Core/Level/**, tests/BioShockStudio.Tests/**, docs/research/bsp.md
---

# Recover the compiled-world texture origin from the source brush

## The problem, exactly

BioShock's compiled world (`Model1`, one large `Model` export per map) parameterises each drawn
surface's texture as, in UE2 terms:

```
u_texels = dot(vertexWorldPos - textureOrigin, TextureU)
v_texels = dot(vertexWorldPos - textureOrigin, TextureV)
```

then the engine divides by the bound texture's width/height. `TextureU` / `TextureV` are
`world.Vectors[surface.TextureU | surface.TextureV]` and **those are read correctly** — verified by
`BspTextureVectorDiagnosticTests.ReportSurfaceVectorSanityPerMaterial`: `Vectors[surface.Normal]`
is unit length and plane-aligned for 13,041/13,041 drawn 1-Medical surfaces.

**`textureOrigin` is the unsolved part.** `FBspSurf +4` is `pBase`, spec'd (Nyko `bioshock1-bsm.md`
§C.1.3) as an index into `Model.Points`. `world.Points[surface.Base]` is NOT a usable origin:
measured on 1-Medical it lands within 20 m of the face's own vertices for only **800 of 6,667**
drawn surfaces; for the rest it is tens to hundreds of metres away, and
`dot(vertex - Points[pBase], TextureU)` comes out at a median of **62,353 texels** — the GPU then
samples a near-random mip and walls/floors render wrong. `Model.Points` itself is read correctly
(the planarity check puts 81,554/81,566 compiled polygons exactly on their node plane). Reading
`pBase` as a `Verts` index is no better (535/6,667). See `docs/research/bsp.md` §5.3a and
`reference-comparison.md` §8.2 for the full write-up and the UELib `Poly.cs` cross-reference (the
pan offset `PanU/PanV` is folded into the origin and stops being serialised at package version 78;
BioShock is 142, so the origin is pre-baked — into a vector for a source `FPoly`, into the `pBase`
index for a compiled `FBspSurf`, and that index does not resolve).

The current stopgap (`BspGeometry.ToGeometry(BspWorld)` / `BspWorld.TexelsAtLocal`) measures the
projection from `polygon[0]` — the face's own first vertex. That recovers the texture **scale**
exactly (the span across a face is base-independent) but loses cross-face **phase**: a texture that
should flow unbroken across a BSP cut can seam, and a face whose axis vectors are genuinely long
(`medical_pillar_texture`, ~66 texels/unit) still over-tiles. A `BspGeometry.NormaliseUvs` per-face
clamp (`BIOSHOCK_BSP_UV_MAX_TILES`, default 12) currently hides the worst of it. **A user looking
at the render still calls the walls "borked".**

## The approach — build only on what is already CONFIRMED_BYTES

Two things about each compiled surface are verified:

1. **`FBspSurf.Actor` (the `CI` after +20) names the source brush actor it was CSG'd from.** §5.7:
   the brush places by `Location - PrePivot`, no rotation or scale, on **33,631 of 33,632** world
   polygons across six maps.
2. **`FBspSurf.iBrushPoly` (`+20`, `surface.BrushPoly`) names which polygon of that brush's
   `Polys` this surface was cut from.** `SurfaceBrushPolyTests`: 6,372/6,372 across three maps land
   in range AND name a polygon whose normal matches the surface's.

The source polygon is a `BspPolygon` (`src/BioShockStudio.Core/Level/BspPolys.cs`) with a real
`Vector3 Base` — the **pan-baked texture origin, in brush space**, plus its own `TextureU` /
`TextureV`. Placing `Base` into world space by the brush transform (`Location - PrePivot`) gives the
origin the compiled surface lost.

`SurfaceBrushPolyTests.TheFieldAtTwentyIndexesTheSourceBrushsOwnPolygons` already shows the exact
resolution chain — copy it:

```
surface.Actor.IsExport  →  LevelAnalyzer.Analyze(package).Brushes keyed by Source.ExportIndex
  →  actor.Brush.Source  →  ModelReader.Read(package, ...)  →  ModelReader.ResolvePolys(package, ...)
  →  PolysReader.Read(package, export).Polygons  →  polygons[surface.BrushPoly]
```

The brush actor carries its placement in `actor.Transform` (`ActorTransform`, has `Location` and
`PrePivot`). §5.7 / `BrushPlacementTests` establish the rule is `Location - PrePivot`, no rotation
or scale — `ActorTransform` already builds a matrix (`Matrix4x4.CreateTranslation(-PrePivot) *
...`); for a brush with no rotation/scale the world origin is simply `polyBase + (Location -
PrePivot)`. Confirm against `BrushPlacementTests` before relying on it.

## What to build

Everything lives in `src/BioShockStudio.Core/Level/` and `tests/`.

1. **A resolver** that, given a `BioShockPackage`, a `BspWorld` and its owning level context
   (`LevelAnalyzer.Analyze` result), produces a `textureOrigin` (world-space `Vector3`) per
   surface — from the source brush poly's `Base` transformed by `Location - PrePivot`. Cache the
   per-brush `Polys` read (the test does; brushes have many surfaces).

2. **Wire it into the geometry path.** `BspGeometry.ToGeometry(BspWorld)` currently takes only a
   `BspWorld`. It needs the resolved origins. Options, your call:
   - add an overload `ToGeometry(BspWorld, IReadOnlyList<Vector3?> surfaceOrigins)` and have
     `LevelScene.AddBuiltWorld` build the origins and pass them, or
   - pass a `Func<BspSurface, Vector3?>` .
   Where an origin resolves, use it in the projection (`TexelsAtLocal(surface, position,
   resolvedOrigin)`); where it does NOT (cross-package brush, missing actor, `BrushPoly < 0`,
   `Polys` fails to read), fall back to the current `polygon[0]` behaviour. Do not remove the
   `polygon[0]` fallback and do not remove the `NormaliseUvs` clamp.

3. **Also cross-check the axis vectors.** For each resolved surface, compare
   `world.Vectors[surface.TextureU]` against the source poly's `TextureU` (both are already in the
   studio basis). Report (in the test's log) how often they agree within, say, 1%. If the source
   poly's axes agree with `Vectors` for the clean materials but the source poly has a *sane* axis
   where `Vectors` is the ~66-texels/unit outlier for `medical_pillar_texture`, note that — it may
   mean `surface.TextureU` is a mis-index and the source poly's axis is the right one to use. Do
   NOT change the axis source in this task unless the evidence is unambiguous; just measure and
   record.

## Tests to add (`tests/BioShockStudio.Tests/BspTextureOriginTests.cs`, `[Trait(Tiers.Name, Tiers.Sweep)]`, `[RequiresGameFact]`)

- **Coverage**: on 1-Medical, the fraction of drawn surfaces for which a brush-Base origin
  resolves. Assert it is a large majority (> 70%); log the exact number.
- **Correctness**: for the resolved surfaces, `dot(anyFaceVertex - resolvedOrigin, TextureU)` is a
  small texel count — assert the median raw texel span per resolved face is under ~2,000 (a few
  tiles of a 512 texture), the same bar `bsp.md` §5.3a quotes for the `polygon[0]` result. This is
  the assertion that says the origin is real.
- **Phase**: two surfaces sharing a brush poly (or adjacent surfaces of one wall) get origins that
  differ by a whole number of texture periods along the shared axis — i.e. the seam the
  `polygon[0]` method introduces is gone. If you can express this cleanly, assert it; if not, log
  a before/after seam measurement.
- Keep `BspRunawayUvClampTests` (fast) green.

## Then, and only if the tests above pass and the numbers are good

Regenerate 1-Medical and eyeball it:

```
export BIOSHOCK_ORIGINAL_TEXTURE_DIR="G:\SteamLibrary\steamapps\common\Bioshock\Builds\Release\UmodelExport\1-Medical\Texture"
dotnet run --project src/BioShockStudio.Cli -- export-level "G:\SteamLibrary\steamapps\common\BioShock Remastered\ContentBaked\pc\Maps\1-Medical.bsm" <tmpdir>
```

then inspect `<tmpdir>/1-Medical/Meshes/Model1_20761.obj` — `vt` magnitudes should be mostly ≤ ~4
with far fewer clamp hits than now. You cannot run the UE editor from the worktree; do not try.
Record the OBJ `vt` percentile before/after in the task result.

## Constraints

- `src/BioShockStudio.Core/Level/**`, `tests/**`, `docs/research/bsp.md` only. Do NOT touch
  `tools/**`, `src/BioShockStudio.Cli/**` beyond running it, or anything under `src/` outside
  `Level/`.
- Smallest correct change. Keep every existing test green (`--filter Tier=Fast` at minimum; run
  the BSP sweep if you changed the reader).
- `DISCOVER → VERIFY → RECORD → DEFER`. Label claims `CONFIRMED_BYTES` / `PLAUSIBLE` / `UNKNOWN`.
- Do not commit, do not push. If the brush-Base origin turns out NOT to resolve or NOT to land
  near the face for most surfaces, that is a valid result — write exactly what you measured into
  `docs/research/bsp.md` §5.3a and stop; do not invent a third mechanism.
- Update `docs/research/bsp.md` §5.3a with the outcome either way.
