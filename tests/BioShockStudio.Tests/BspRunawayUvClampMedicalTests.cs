using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The runaway-UV clamp, run against 1-Medical's real compiled world.
/// </summary>
/// <remarks>
/// The synthetic <see cref="BspRunawayUvClampTests"/> pin the rescale arithmetic; this pins that
/// the clamp actually reaches every section of the shipped geometry — including the water and
/// zoning sections that resolve no texture size and were being skipped.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspRunawayUvClampMedicalTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void NoCompiledWorldFaceTilesPastTheCapAfterNormalisation()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var model = ModelReader.BuiltWorld(package);
        Assert.NotNull(model);

        var world = BspWorldReader.Read(package, package.Exports[model!.Source.ExportIndex]);
        Assert.NotNull(world);

        var geometry = BspGeometry.ToGeometry(world!);

        // Every section null: the hardest case for the clamp — nothing is divided, so it must work
        // on raw texels against the nominal size. If it holds here it holds when a real size makes
        // the numbers smaller.
        var sizes = new List<(int Width, int Height)?>();
        for (int i = 0; i < geometry.Sections.Count; i++) sizes.Add(null);

        var clamped = BspGeometry.NormaliseUvs(geometry, sizes);

        float worst = 0f;
        int worstSection = -1;
        for (int s = 0; s < clamped.Sections.Count; s++)
        {
            var range = clamped.Sections[s];
            for (int i = range.FirstIndex; i < range.FirstIndex + range.TriangleCount * 3 && i < clamped.Indices.Count; i++)
            {
                var uv = clamped.Vertices[clamped.Indices[i]].Uv;
                float m = MathF.Max(MathF.Abs(uv.X), MathF.Abs(uv.Y));
                if (m > worst) { worst = m; worstSection = s; }
            }
        }

        Log($"clamped compiled-world UVs: worst {worst:0} texels in section {worstSection}");

        // Every section divided (real or nominal size) and clamped to MaxFaceTiles.
        Assert.True(worst <= 6f,
            $"section {worstSection} still tiles {worst:0.#}x after the clamp — a runaway face got past it");
    }
}
