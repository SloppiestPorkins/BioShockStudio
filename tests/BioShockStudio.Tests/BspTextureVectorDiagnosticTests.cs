using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Diagnostic: per compiled-world material, the raw texel span of its faces measured from the
/// face's own first vertex, the world size of those faces, and the implied texels-per-cm. If a
/// section's texels-per-cm is wildly off the median, its texture-axis vectors — not just pBase —
/// are being misread, and no origin fix will save it.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspTextureVectorDiagnosticTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void ReportTexelsPerCentimetrePerCompiledWorldMaterial()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var model = ModelReader.BuiltWorld(package);
        Assert.NotNull(model);
        var world = BspWorldReader.Read(package, package.Exports[model!.Source.ExportIndex]);
        Assert.NotNull(world);

        var byMat = new Dictionary<int, List<(float TexelSpan, float WorldSpan)>>();
        foreach (var node in world!.Nodes)
        {
            if (!node.IsPolygon) continue;
            if (node.Surface < 0 || node.Surface >= world.Surfaces.Count) continue;
            var surface = world.Surfaces[node.Surface];
            if (!surface.IsDrawn) continue;
            var poly = world.PolygonOf(node);
            if (poly.Count < 3) continue;

            var basev = poly[0];
            float tu0 = 0, tv0 = 0, tu1 = 0, tv1 = 0, w1 = 0;
            for (int i = 1; i < poly.Count; i++)
            {
                var uv = world.TexelsAtLocal(surface, poly[i], basev);
                tu0 = MathF.Min(tu0, uv.X); tu1 = MathF.Max(tu1, uv.X);
                tv0 = MathF.Min(tv0, uv.Y); tv1 = MathF.Max(tv1, uv.Y);
                float d = (poly[i] - basev).Length();
                w1 = MathF.Max(w1, d);
            }
            float texelSpan = MathF.Max(tu1 - tu0, tv1 - tv0);
            if (w1 < 1f) continue;
            if (!byMat.TryGetValue(surface.Material.Value, out var list))
                byMat[surface.Material.Value] = list = [];
            list.Add((texelSpan, w1));
        }

        Log("=== compiled-world texels-per-cm by material (Medical) ===");
        foreach (var (matIdx, faces) in byMat.OrderBy(k => k.Key))
        {
            var ratios = faces.Select(f => f.TexelSpan / f.WorldSpan).OrderBy(x => x).ToList();
            if (ratios.Count == 0) continue;
            float med = ratios[ratios.Count / 2];
            float p90 = ratios[(int)(ratios.Count * 0.9)];
            string name = "?";
            if (matIdx > 0 && matIdx <= package.Exports.Count)
                name = package.Exports[matIdx - 1].ObjectName;
            else if (matIdx < 0 && -matIdx <= package.Imports.Count)
                name = package.Imports[-matIdx - 1].ObjectName;
            Log($"  mat {matIdx,6} {name,-38} faces {faces.Count,5}  texels/cm med {med,8:0.00} p90 {p90,8:0.00}");
        }

        Assert.NotEmpty(byMat);
    }

    /// <summary>
    /// Cross-check the FBspSurf field reading against Nyko's spec: vNormal should index a
    /// unit-length entry of Vectors that agrees with the node's own plane, and the texture axes'
    /// magnitudes (texels per unit) should cluster. A material whose vNormal is not unit, or not
    /// aligned with the plane, has a shifted or mis-indexed surface record.
    /// </summary>
    [RequiresGameFact]
    public void ReportSurfaceVectorSanityPerMaterial()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var model = ModelReader.BuiltWorld(package);
        var world = BspWorldReader.Read(package, package.Exports[model!.Source.ExportIndex])!;

        var rows = new Dictionary<int, (int N, int NormalBad, int PlaneBad, List<float> UMag, List<float> VMag, List<int> UIdx)>();
        foreach (var node in world.Nodes)
        {
            if (!node.IsPolygon || node.Surface < 0 || node.Surface >= world.Surfaces.Count) continue;
            var s = world.Surfaces[node.Surface];
            if (!s.IsDrawn) continue;
            if (!rows.TryGetValue(s.Material.Value, out var r))
                r = (0, 0, 0, [], [], []);

            r.N++;
            if (s.Normal >= 0 && s.Normal < world.Vectors.Count)
            {
                var vn = world.Vectors[s.Normal];
                if (MathF.Abs(vn.Length() - 1f) > 0.05f) r.NormalBad++;
                else if (MathF.Abs(Vector3.Dot(Vector3.Normalize(vn), node.Plane.Normal)) < 0.9f) r.PlaneBad++;
            }
            else r.NormalBad++;

            if (s.TextureU >= 0 && s.TextureU < world.Vectors.Count)
            {
                r.UMag.Add(world.Vectors[s.TextureU].Length());
                r.UIdx.Add(s.TextureU);
            }
            if (s.TextureV >= 0 && s.TextureV < world.Vectors.Count)
                r.VMag.Add(world.Vectors[s.TextureV].Length());
            rows[s.Material.Value] = r;
        }

        Log("=== FBspSurf vector sanity by material (Medical) — |Vn|~1, Vn·plane~1, |Vu|/|Vv| = texels/unit ===");
        Log($"  Vectors array: {world.Vectors.Count} entries");
        foreach (var (matIdx, r) in rows.OrderBy(k => k.Key))
        {
            string name = matIdx > 0 && matIdx <= package.Exports.Count ? package.Exports[matIdx - 1].ObjectName
                : matIdx < 0 && -matIdx <= package.Imports.Count ? package.Imports[-matIdx - 1].ObjectName : "?";
            r.UMag.Sort();
            r.VMag.Sort();
            float um = r.UMag.Count > 0 ? r.UMag[r.UMag.Count / 2] : 0;
            float vm = r.VMag.Count > 0 ? r.VMag[r.VMag.Count / 2] : 0;
            int uiMin = r.UIdx.Count > 0 ? r.UIdx.Min() : -1;
            int uiMax = r.UIdx.Count > 0 ? r.UIdx.Max() : -1;
            Log($"  mat {matIdx,6} {name,-36} n {r.N,4}  normalBad {r.NormalBad,3} planeBad {r.PlaneBad,3}  |Vu|med {um,7:0.000} |Vv|med {vm,7:0.000}  Uidx {uiMin}-{uiMax}");
        }

        Assert.NotEmpty(rows);
    }
}
