using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;
using Xunit.Abstractions;

namespace BioShockStudio.Tests;

/// <summary>
/// Per-vertex baked lighting on <c>StaticMeshInstance</c>.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class StaticMeshInstanceLightingTests(GameFixture game, ITestOutputHelper output)
{
    /// <summary>
    /// Lamp-adjacent prop that references <c>Light184</c> and keeps non-zero evaluated RGB after
    /// Max(0, N·L). Picked from Medical after a short scan — not every Light184 neighbour faces
    /// the light (e.g. <c>StaticMeshActor1060</c> is backfacing).
    /// </summary>
    private const string LampAdjacentActor = "StaticMeshActor2234";

    /// <summary>All 21 non-localised map packages (see docs/research/remastered.md).</summary>
    private static readonly string[] StoryMaps =
    [
        "0-Lighthouse", "1-Medical", "1-Welcome", "2-Fisheries", "2-SubBay",
        "3-Arcadia", "3-Market", "4-Recreation", "5-Hephaestus", "5-Ryan",
        "6-Resi", "6-Slums", "7-BossFight", "7-Gauntlet", "7-Science",
        "Autoplay", "Entry", "museum",
        "ChallengeRoomCombat", "ChallengeRoomDecoy", "ChallengeRoomElectric",
    ];

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
            // Pinned Medical numbers from the first decode (591e7c1): do not drift.
            Assert.Equal(3979, result.Summary.InstanceCount);
            Assert.Equal(3280, result.Summary.LitInstanceCount);
            Assert.Equal(60224, result.Summary.PoolBase);
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

    [RequiresGameFact]
    public void AllStoryMapsLocatePoolAndDecodeOrSkipWithReason()
    {
        string mapsDir = GameLocator.MapsDirectory(game.RequireRoot);
        output.WriteLine("map\tdecoded\tskipped\tpoolBase\tlitInstances\tlitFrac");

        foreach (string map in StoryMaps)
        {
            string file = Path.Combine(mapsDir, map + ".bsm");
            Assert.True(File.Exists(file), $"missing {file}");
            using var package = BioShockPackage.Open(file);
            var context = LevelAnalyzer.Analyze(package);
            var live = StaticMeshInstanceReader.EnumerateLive(package, context);

            var decoded = new List<StaticMeshInstance>();
            int skipped = 0;
            foreach (var (actor, instance) in live)
            {
                if (instance is null)
                {
                    skipped++;
                    output.WriteLine($"  skip {actor.Source.ObjectName}: StaticMeshInstance body did not parse");
                    continue;
                }

                decoded.Add(instance);
            }

            if (decoded.Count == 0)
            {
                output.WriteLine($"{map}\t0\t{skipped}\t-\t0\t-");
                Assert.True(skipped == live.Count);
                continue;
            }

            var located = StaticMeshInstanceReader.LocateLuminancePool(package, decoded);
            Assert.True(located is not null, $"{map}: luminance pool not located");
            var (poolBase, levelData) = located.Value;

            int lit = 0;
            int evaluated = 0;
            foreach (var (actor, instance) in live)
            {
                if (instance is null) continue;
                int meshVerts = StaticMeshInstanceReader.MeshVertexCount(package, instance.Mesh);
                if (meshVerts < 0)
                {
                    skipped++;
                    output.WriteLine($"  skip {actor.Source.ObjectName}: StaticMesh geometry did not decode");
                    continue;
                }

                if (meshVerts != instance.VertexCount)
                {
                    skipped++;
                    output.WriteLine(
                        $"  skip {actor.Source.ObjectName}: mesh verts {meshVerts} != instance {instance.VertexCount}");
                    continue;
                }

                evaluated++;
                bool any = false;
                foreach (var layer in instance.Layers)
                {
                    if (!StaticMeshInstanceReader.TryReadLuminances(
                            levelData, poolBase, layer, instance.VertexCount,
                            out var s0, out var s1, out var s2))
                    {
                        Assert.Fail($"{map}/{actor.Source.ObjectName}: luminance slice out of range");
                    }

                    for (int v = 0; v < instance.VertexCount && !any; v++)
                        if (s0[v] > 0f || s1[v] > 0f || s2[v] > 0f) any = true;
                }

                if (any) lit++;
            }

            float litFrac = evaluated == 0 ? 0f : (float)lit / evaluated;
            output.WriteLine($"{map}\t{evaluated}\t{skipped}\t{poolBase}\t{lit}\t{litFrac:0.000}");

            Assert.True(evaluated > 0, $"{map}: no evaluable instances");
            // Raw luminance (no N·L): a clear majority of props store some bake energy.
            Assert.True(
                litFrac >= 0.55f,
                $"{map}: lit fraction {litFrac:0.000} ({lit}/{evaluated})");

            if (map == "1-Medical")
            {
                Assert.Equal(60224, poolBase);
                // Full export (N·L) pins 3979/3280; raw luminance counts every stored non-zero.
                Assert.Equal(3979, evaluated);
            }
        }
    }
}
