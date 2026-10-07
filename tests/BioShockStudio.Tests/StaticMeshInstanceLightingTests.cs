using BioShockStudio.Core.Export;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Per-vertex baked lighting on <c>StaticMeshInstance</c> (Medical Fast slice).
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class StaticMeshInstanceLightingTests(GameFixture game)
{
    /// <summary>
    /// Lamp-adjacent prop that references <c>Light184</c> and keeps non-zero evaluated RGB after
    /// Max(0, N·L). Picked from Medical after a short scan — not every Light184 neighbour faces
    /// the light (e.g. <c>StaticMeshActor1060</c> is backfacing).
    /// </summary>
    private const string LampAdjacentActor = "StaticMeshActor2234";

    [RequiresGameFact]
    public void MedicalLiveInstancesDecodeAndMatchMeshVertexCounts()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var live = StaticMeshInstanceReader.EnumerateLive(package, context);

        Assert.NotEmpty(live);
        Assert.All(live, pair => Assert.NotNull(pair.Instance));

        int checkedMeshes = 0;
        foreach (var (_, instance) in live)
        {
            int meshVerts = StaticMeshInstanceReader.MeshVertexCount(package, instance!.Mesh);
            if (meshVerts < 0) continue; // a few meshes StaticMeshReader cannot decode yet
            Assert.Equal(meshVerts, instance.VertexCount);
            checkedMeshes++;
        }

        Assert.True(checkedMeshes > live.Count / 2, $"only {checkedMeshes}/{live.Count} meshes decoded");
    }

    [RequiresGameFact]
    public void MedicalExportHasWidespreadNonZeroLightAndLampBrighterThanDark()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        string path = Path.Combine(Path.GetTempPath(), "bioshock-vertex-lit-" + Guid.NewGuid().ToString("N") + ".json");
        try
        {
            var result = VertexLightingExporter.Export(package, path);
            Assert.True(File.Exists(path));
            Assert.True(result.Summary.InstanceCount > 1000, $"instances={result.Summary.InstanceCount}");
            Assert.True(
                result.Summary.LitInstanceCount * 2 >= result.Summary.InstanceCount,
                $"lit={result.Summary.LitInstanceCount}/{result.Summary.InstanceCount}");
            Assert.True(result.Summary.Scale > 0f);
            Assert.True(result.Summary.AppliesNDotL);

            var lamp = result.Summary.Instances.Single(i => i.Actor == LampAdjacentActor);
            var dark = result.Summary.Instances.First(i => i.Lights.Count == 0);
            float lampB = MathF.Max(lamp.AverageR, MathF.Max(lamp.AverageG, lamp.AverageB));
            float darkB = MathF.Max(dark.AverageR, MathF.Max(dark.AverageG, dark.AverageB));
            Assert.True(lampB > darkB + 1e-4f, $"lamp={lampB:0.####} dark={darkB:0.####}");
            Assert.Contains("Light184", lamp.Lights, StringComparer.Ordinal);
        }
        finally
        {
            try { File.Delete(path); }
            catch (IOException) { /* temp cleanup best-effort */ }
        }
    }
}
