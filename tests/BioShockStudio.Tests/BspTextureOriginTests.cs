using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Compiled-world texture origin from the source brush polygon's <c>Base</c> — measured, then
/// wired into production with a whole-period UV rebase (bsp.md §5.3a).
/// </summary>
/// <remarks>
/// Resolving the source <c>FPoly.Base</c> via <c>Location − PrePivot</c> works for most drawn
/// surfaces, and the result is <b>exactly</b> <c>Model.Points[pBase]</c>. That point is already
/// far from the face in brush space (pan-baked). Production projects from it for phase, then
/// <see cref="BspGeometry.NormaliseUvs"/> rebases each face by <c>round(centroid)</c> whole
/// periods so stored magnitudes stay small while <c>frac(UV)</c> is unchanged.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspTextureOriginTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
        else
            Console.WriteLine(line);
    }

    [RequiresGameFact]
    public void BrushBaseOriginResolvesForMostDrawnSurfacesButDoesNotLandNearTheFace()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var (world, origins) = LoadWorldAndOrigins(package);

        int drawn = 0, resolved = 0, nearFace = 0, equalsPointsBase = 0, comparablePoints = 0;
        var mismatchDists = new List<float>();
        foreach (var node in world.Nodes)
        {
            if (!IsDrawnPolygon(world, node)) continue;
            drawn++;

            var origin = origins[node.Surface];
            if (origin is null) continue;
            resolved++;

            var polygon = world.PolygonOf(node);
            float nearest = polygon.Min(v => (v - origin.Value).Length());
            if (nearest <= 2000f) nearFace++; // 20 m

            var surface = world.Surfaces[node.Surface];
            if (surface.Base >= 0 && surface.Base < world.Points.Count)
            {
                comparablePoints++;
                float d = (origin.Value - world.Points[surface.Base]).Length();
                if (d <= 1f) equalsPointsBase++;
                else mismatchDists.Add(d);
            }
        }

        float fraction = drawn == 0 ? 0 : (float)resolved / drawn;
        mismatchDists.Sort();
        string mismatchNote = mismatchDists.Count == 0
            ? "none"
            : $"n={mismatchDists.Count} median {mismatchDists[mismatchDists.Count / 2]:0.##} cm";
        Log($"1-Medical drawn surfaces: {drawn}; brush-Base origin resolved: {resolved} ({100f * fraction:0.0}%); "
            + $"origin within 20 m of a face vertex: {nearFace}; "
            + $"equals Points[pBase] (≤1 cm): {equalsPointsBase}/{comparablePoints}; mismatches: {mismatchNote}");

        Assert.True(drawn > 1_000, $"only {drawn} drawn surfaces");
        Assert.True(fraction > 0.70f,
            $"brush-Base origin resolved for only {resolved}/{drawn} ({100f * fraction:0.0}%) drawn surfaces");

        // The mechanism resolves, but the origin is the same distant point pBase already named
        // for the overwhelming majority (basis/float noise on a small tail).
        Assert.True(nearFace < 0.20f * resolved,
            $"unexpectedly {nearFace}/{resolved} origins landed within 20 m — re-check the finding");
        Assert.True(equalsPointsBase >= 0.95f * comparablePoints,
            $"brush-Base matched Points[pBase] for only {equalsPointsBase}/{comparablePoints}");
    }

    [RequiresGameFact]
    public void BrushBaseOriginAbsoluteTexelsRemainHuge_SpanStaysSane()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var (world, origins) = LoadWorldAndOrigins(package);

        var absPeaks = new List<float>();
        var spans = new List<float>();
        var brushSpaceBaseToVertex = new List<float>();
        var brushes = LevelAnalyzer.Analyze(package).Brushes.ToDictionary(a => a.Source.ExportIndex);
        var polyCache = new Dictionary<int, IReadOnlyList<BspPolygon>>();

        foreach (var node in world.Nodes)
        {
            if (!IsDrawnPolygon(world, node)) continue;
            if (origins[node.Surface] is not { } origin) continue;

            var surface = world.Surfaces[node.Surface];
            var polygon = world.PolygonOf(node);
            if (polygon.Count < 3) continue;

            float minU = float.MaxValue, maxU = float.MinValue;
            float minV = float.MaxValue, maxV = float.MinValue;
            float peak = 0f;
            foreach (var v in polygon)
            {
                var uv = world.TexelsAtLocal(surface, v, origin);
                minU = MathF.Min(minU, uv.X); maxU = MathF.Max(maxU, uv.X);
                minV = MathF.Min(minV, uv.Y); maxV = MathF.Max(maxV, uv.Y);
                peak = MathF.Max(peak, MathF.Max(MathF.Abs(uv.X), MathF.Abs(uv.Y)));
            }

            absPeaks.Add(peak);
            spans.Add(MathF.Max(maxU - minU, maxV - minV));

            var src = BspTextureOrigin.SourcePolygon(package, surface, brushes, polyCache);
            if (src is { Vertices.Count: > 0 })
                brushSpaceBaseToVertex.Add(src.Vertices.Min(v => (v - src.Base).Length()));
        }

        Assert.True(absPeaks.Count > 1_000, $"only {absPeaks.Count} resolved faces measured");

        absPeaks.Sort();
        spans.Sort();
        brushSpaceBaseToVertex.Sort();
        float medianPeak = absPeaks[absPeaks.Count / 2];
        float medianSpan = spans[spans.Count / 2];
        float medianBrushDist = brushSpaceBaseToVertex[brushSpaceBaseToVertex.Count / 2];
        Log($"resolved-face raw |texel| median peak {medianPeak:0.#}, median span {medianSpan:0.#}; "
            + $"brush-space Base→vertex median {medianBrushDist:0.#} cm (n={absPeaks.Count})");

        // Absolute magnitude stays in the pBase failure regime — the pan is baked into a distant Base.
        Assert.True(medianPeak > 10_000f,
            $"median peak |texel| is {medianPeak:0.#}; expected still huge like Points[pBase]");
        // Span is origin-independent and matches the polygon[0] stopgap bar.
        Assert.True(medianSpan < 2_000f,
            $"median texel span is {medianSpan:0.#}, expected under 2000");
        Assert.True(medianBrushDist > 10_000f,
            $"source poly Base already {medianBrushDist:0.#} cm from its vertices in brush space");
    }

    [RequiresGameFact]
    public void SourcePolyAxesAgreeWithCompiledVectors()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var model = ModelReader.BuiltWorld(package);
        Assert.NotNull(model);
        var world = BspWorldReader.Read(package, package.Exports[model!.Source.ExportIndex]);
        Assert.NotNull(world);

        var context = LevelAnalyzer.Analyze(package);
        var brushes = context.Brushes.ToDictionary(a => a.Source.ExportIndex);
        var polyCache = new Dictionary<int, IReadOnlyList<BspPolygon>>();

        int compared = 0, uAgree = 0, vAgree = 0;
        var outliers = new List<string>();

        foreach (var surface in world!.Surfaces)
        {
            if (!surface.IsDrawn) continue;
            var poly = BspTextureOrigin.SourcePolygon(package, surface, brushes, polyCache);
            if (poly is null) continue;
            if (surface.TextureU < 0 || surface.TextureU >= world.Vectors.Count) continue;
            if (surface.TextureV < 0 || surface.TextureV >= world.Vectors.Count) continue;

            var wu = world.Vectors[surface.TextureU];
            var wv = world.Vectors[surface.TextureV];
            compared++;

            if (AxesAgree(wu, poly.TextureU)) uAgree++;
            if (AxesAgree(wv, poly.TextureV)) vAgree++;

            float worldULen = wu.Length();
            float polyULen = poly.TextureU.Length();
            if (worldULen > 10f && polyULen > 0.01f && polyULen < 2f && worldULen / polyULen > 10f)
            {
                string mat = MaterialName(package, surface.Material);
                if (outliers.Count < 30)
                    outliers.Add($"  mat {mat}: Vectors[U] |{worldULen:0.##}| vs poly.TextureU |{polyULen:0.##}|");
            }
        }

        Log($"axis agree within 1%: U {uAgree}/{compared} ({100.0 * uAgree / Math.Max(1, compared):0.0}%), "
            + $"V {vAgree}/{compared} ({100.0 * vAgree / Math.Max(1, compared):0.0}%)");
        foreach (string line in outliers) Log(line);
        Log($"long-Vectors / sane-poly-axis outliers logged: {outliers.Count}");

        Assert.True(compared > 1_000, $"only {compared} surfaces compared");
        Assert.Equal(compared, uAgree);
        Assert.Equal(compared, vAgree);
        Assert.Empty(outliers);
    }

    [RequiresGameFact]
    public void PhaseSeamMeasurement_BrushBaseMatchesPointsBase()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var (world, origins) = LoadWorldAndOrigins(package);

        var faceList = world.Nodes
            .Where(n => IsDrawnPolygon(world, n))
            .Select(n => (Node: n, Poly: world.PolygonOf(n), Surface: world.Surfaces[n.Surface]))
            .Where(f => f.Poly.Count >= 3)
            .ToList();

        var vertexBuckets = new Dictionary<(int, int, int), List<int>>();
        for (int i = 0; i < faceList.Count; i++)
        {
            foreach (var v in faceList[i].Poly)
            {
                var key = ((int)MathF.Round(v.X), (int)MathF.Round(v.Y), (int)MathF.Round(v.Z));
                if (!vertexBuckets.TryGetValue(key, out var list))
                    vertexBuckets[key] = list = [];
                if (list.Count == 0 || list[^1] != i) list.Add(i);
            }
        }

        var seamPoly0 = new List<float>();
        var seamBrush = new List<float>();
        var seenPairs = new HashSet<(int, int)>();
        foreach (var facesAtVertex in vertexBuckets.Values)
        {
            if (facesAtVertex.Count < 2) continue;
            for (int ai = 0; ai < facesAtVertex.Count; ai++)
            {
                for (int bi = ai + 1; bi < facesAtVertex.Count; bi++)
                {
                    int a = facesAtVertex[ai], b = facesAtVertex[bi];
                    if (a > b) (a, b) = (b, a);
                    if (!seenPairs.Add((a, b))) continue;

                    var fa = faceList[a];
                    var fb = faceList[b];
                    if (fa.Node.Surface == fb.Node.Surface) continue;
                    if (fa.Surface.Material.Value != fb.Surface.Material.Value) continue;
                    if (MathF.Abs(Vector3.Dot(fa.Node.Plane.Normal, fb.Node.Plane.Normal)) < 0.999f)
                        continue;
                    if (!TrySharedVertex(fa.Poly, fb.Poly, out var shared)) continue;

                    seamPoly0.Add(UvDelta(world, fa, fb, shared, fa.Poly[0], fb.Poly[0]));

                    var oa = origins[fa.Node.Surface] ?? fa.Poly[0];
                    var ob = origins[fb.Node.Surface] ?? fb.Poly[0];
                    seamBrush.Add(UvDelta(world, fa, fb, shared, oa, ob));
                }
            }
        }

        Assert.True(seamPoly0.Count > 50, $"only {seamPoly0.Count} adjacent face pairs for seam measure");
        seamPoly0.Sort();
        seamBrush.Sort();
        float med0 = seamPoly0[seamPoly0.Count / 2];
        float medB = seamBrush[seamBrush.Count / 2];
        Log($"seam |ΔUV| at shared vertex (texels): polygon[0] median {med0:0.#}, brush-Base median {medB:0.#} "
            + $"(n={seamPoly0.Count} coplanar same-material pairs). "
            + "Brush-Base phase is the compiled pBase phase; production uses it then rebases.");
        Assert.True(medB < 1f,
            $"brush-Base seam median {medB:0.#} texels — expected ~0 for coplanar same-material pairs");
    }

    /// <summary>
    /// Real origin + whole-period rebase: shared-vertex <c>frac(UV)</c> stays continuous across
    /// coplanar same-material BSP cuts (the seam g1 measured at 1,085 texels under polygon[0]).
    /// </summary>
    [RequiresGameFact]
    public void ProductionPipeline_SharedVertexFracPhaseIsNearZero()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var (world, origins) = LoadWorldAndOrigins(package);
        var geometry = BspGeometry.ToGeometry(world, null, origins);
        var sizes = Enumerable.Repeat<(int Width, int Height)?>(null, geometry.Sections.Count).ToList();
        var normalised = BspGeometry.NormaliseUvs(geometry, sizes);

        // Map each drawn face to its first vertex index in the triangulated geometry (fan pivot).
        // ToGeometry walks surfaces grouped by material; rebuild the same order to pair faces.
        var faceFirstVertex = new List<(BspNode Node, IReadOnlyList<Vector3> Poly, BspSurface Surface, int FirstVertex)>();
        int vertexCursor = 0;
        foreach (var group in world.Nodes
            .Where(n => IsDrawnPolygon(world, n))
            .GroupBy(n => world.Surfaces[n.Surface].Material.Value)
            .OrderBy(g => g.Key))
        {
            foreach (var node in group)
            {
                var poly = world.PolygonOf(node);
                if (poly.Count < 3) continue;
                faceFirstVertex.Add((node, poly, world.Surfaces[node.Surface], vertexCursor));
                vertexCursor += poly.Count;
            }
        }

        var vertexBuckets = new Dictionary<(int, int, int), List<int>>();
        for (int i = 0; i < faceFirstVertex.Count; i++)
        {
            foreach (var v in faceFirstVertex[i].Poly)
            {
                var key = ((int)MathF.Round(v.X), (int)MathF.Round(v.Y), (int)MathF.Round(v.Z));
                if (!vertexBuckets.TryGetValue(key, out var list))
                    vertexBuckets[key] = list = [];
                if (list.Count == 0 || list[^1] != i) list.Add(i);
            }
        }

        var fracDeltas = new List<float>();
        var seenPairs = new HashSet<(int, int)>();
        foreach (var facesAtVertex in vertexBuckets.Values)
        {
            if (facesAtVertex.Count < 2) continue;
            for (int ai = 0; ai < facesAtVertex.Count; ai++)
            {
                for (int bi = ai + 1; bi < facesAtVertex.Count; bi++)
                {
                    int a = facesAtVertex[ai], b = facesAtVertex[bi];
                    if (a > b) (a, b) = (b, a);
                    if (!seenPairs.Add((a, b))) continue;

                    var fa = faceFirstVertex[a];
                    var fb = faceFirstVertex[b];
                    if (fa.Node.Surface == fb.Node.Surface) continue;
                    if (fa.Surface.Material.Value != fb.Surface.Material.Value) continue;
                    if (MathF.Abs(Vector3.Dot(fa.Node.Plane.Normal, fb.Node.Plane.Normal)) < 0.999f)
                        continue;
                    if (!TrySharedVertex(fa.Poly, fb.Poly, out var shared)) continue;

                    if (!TryUvAtWorldPoint(normalised, fa.FirstVertex, fa.Poly, shared, out var uva)) continue;
                    if (!TryUvAtWorldPoint(normalised, fb.FirstVertex, fb.Poly, shared, out var uvb)) continue;

                    fracDeltas.Add((Frac(uva) - Frac(uvb)).Length());
                }
            }
        }

        Assert.True(fracDeltas.Count > 50, $"only {fracDeltas.Count} pairs for post-pipeline seam measure");
        fracDeltas.Sort();
        float median = fracDeltas[fracDeltas.Count / 2];
        Log($"post real-origin+rebase seam |Δfrac(UV)| median {median:0.####} tiles (n={fracDeltas.Count})");
        Assert.True(median < 0.02f,
            $"shared-vertex frac seam median {median:0.####} tiles — expected well under 0.02");
    }

    /// <summary>
    /// After NormaliseUvs, absolute UV magnitudes on 1-Medical's compiled world are small enough
    /// for half-float storage (median ≲ 2, p99 within the runaway clamp cap).
    /// </summary>
    [RequiresGameFact]
    public void ProductionPipeline_UvMagnitudeIsSaneAfterRebase()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var (world, origins) = LoadWorldAndOrigins(package);
        var geometry = BspGeometry.ToGeometry(world, null, origins);
        var sizes = Enumerable.Repeat<(int Width, int Height)?>(null, geometry.Sections.Count).ToList();
        var normalised = BspGeometry.NormaliseUvs(geometry, sizes);

        var magnitudes = new List<float>(normalised.Vertices.Count);
        foreach (var v in normalised.Vertices)
            magnitudes.Add(MathF.Max(MathF.Abs(v.Uv.X), MathF.Abs(v.Uv.Y)));

        Assert.True(magnitudes.Count > 1_000);
        magnitudes.Sort();
        float median = magnitudes[magnitudes.Count / 2];
        float p99 = magnitudes[(int)(magnitudes.Count * 0.99)];
        Log($"post-rebase |UV| median {median:0.##}, p99 {p99:0.##}, max {magnitudes[^1]:0.##} "
            + $"(n={magnitudes.Count})");

        Assert.True(median <= 2.5f,
            $"median |UV| {median:0.##} — expected ≲ 2 after whole-period rebase");
        Assert.True(p99 <= 13f,
            $"p99 |UV| {p99:0.##} — expected within the runaway clamp cap (~12)");
    }

    private static Vector2 Frac(Vector2 uv) =>
        new(uv.X - MathF.Floor(uv.X), uv.Y - MathF.Floor(uv.Y));

    private static bool TryUvAtWorldPoint(
        MeshGeometry geometry, int firstVertex, IReadOnlyList<Vector3> poly,
        Vector3 point, out Vector2 uv)
    {
        const float eps = 1f;
        for (int i = 0; i < poly.Count; i++)
        {
            if ((poly[i] - point).LengthSquared() <= eps * eps)
            {
                int vi = firstVertex + i;
                if (vi < 0 || vi >= geometry.Vertices.Count)
                {
                    uv = default;
                    return false;
                }
                uv = geometry.Vertices[vi].Uv;
                return true;
            }
        }
        uv = default;
        return false;
    }

    private static (BspWorld World, IReadOnlyList<Vector3?> Origins) LoadWorldAndOrigins(BioShockPackage package)
    {
        var model = ModelReader.BuiltWorld(package);
        Assert.NotNull(model);
        var world = BspWorldReader.Read(package, package.Exports[model!.Source.ExportIndex]);
        Assert.NotNull(world);
        var origins = BspTextureOrigin.Resolve(package, world!, LevelAnalyzer.Analyze(package));
        return (world!, origins);
    }

    private static bool IsDrawnPolygon(BspWorld world, BspNode node) =>
        node.IsPolygon
        && node.Surface >= 0 && node.Surface < world.Surfaces.Count
        && world.Surfaces[node.Surface].IsDrawn
        && world.PolygonOf(node).Count >= 3;

    private static bool AxesAgree(Vector3 a, Vector3 b)
    {
        float la = a.Length(), lb = b.Length();
        if (la < 1e-8f || lb < 1e-8f) return la < 1e-8f && lb < 1e-8f;
        float lenRatio = la > lb ? la / lb : lb / la;
        if (lenRatio > 1.01f) return false;
        return MathF.Abs(Vector3.Dot(a / la, b / lb)) > 0.99f;
    }

    private static bool TrySharedVertex(
        IReadOnlyList<Vector3> a, IReadOnlyList<Vector3> b, out Vector3 shared)
    {
        const float eps = 1f;
        foreach (var va in a)
        {
            foreach (var vb in b)
            {
                if ((va - vb).LengthSquared() <= eps * eps)
                {
                    shared = va;
                    return true;
                }
            }
        }

        shared = default;
        return false;
    }

    private static float UvDelta(
        BspWorld world,
        (BspNode Node, IReadOnlyList<Vector3> Poly, BspSurface Surface) a,
        (BspNode Node, IReadOnlyList<Vector3> Poly, BspSurface Surface) b,
        Vector3 point,
        Vector3 originA,
        Vector3 originB)
    {
        var uva = world.TexelsAtLocal(a.Surface, point, originA);
        var uvb = world.TexelsAtLocal(b.Surface, point, originB);
        return (uva - uvb).Length();
    }

    private static string MaterialName(BioShockPackage package, PackageIndex material)
    {
        int idx = material.Value;
        if (idx > 0 && idx <= package.Exports.Count)
            return package.Exports[idx - 1].ObjectName;
        if (idx < 0 && -idx <= package.Imports.Count)
            return package.Imports[-idx - 1].ObjectName;
        return material.ToString();
    }
}
