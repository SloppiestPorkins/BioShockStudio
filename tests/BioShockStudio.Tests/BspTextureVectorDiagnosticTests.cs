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
}
