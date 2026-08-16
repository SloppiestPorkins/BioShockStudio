using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The scale of a brush's texture coordinates.
/// </summary>
/// <remarks>
/// <para>
/// <b>A user found this by looking at the viewport, with the whole suite green.</b> An
/// <c>FPoly</c> parameterises its surface in <i>texels</i> — <c>dot(v − Base, TextureU)</c> — and
/// the engine divides by the bound texture's dimensions. That division was written and never
/// called, so a 512-pixel texture on a wall got UVs running 0→512 instead of 0→1 and tiled 512
/// times. Every brush surface in the game rendered as a dense moiré while the static meshes beside
/// them looked perfect, because their UVs come from their own vertex data and never went through
/// this path.
/// </para>
/// <para>
/// <b>Nothing that existed could see it.</b> Counts agreed, surfaces bound textures, and the
/// textured-vs-untextured comparison passed at 51% — a wrong UV <i>scale</i> is still a texture
/// reaching every pixel. So this measures the quantity itself.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspUvTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// Raw brush UVs are in texels, and are therefore far larger than 1.
    /// </summary>
    /// <remarks>
    /// The premise of the fix, asserted so it cannot quietly stop being true. If the geometry layer
    /// ever started emitting normalised UVs itself, dividing again would shrink every texture to a
    /// single texel — and this test is what would say so.
    /// </remarks>
    [RequiresGameFact]
    public void RawBrushUvsAreInTexelsAndNotNormalised()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        float worst = 0f;
        int measured = 0;

        foreach (var export in PolysReader.Enumerate(package))
        {
            var polys = PolysReader.Read(package, export);
            var geometry = BspGeometry.ToGeometry(polys.Polygons);

            foreach (var vertex in geometry.Vertices)
            {
                if (vertex.Uv == Vector2.Zero) continue;
                worst = MathF.Max(worst, MathF.Max(MathF.Abs(vertex.Uv.X), MathF.Abs(vertex.Uv.Y)));
                measured++;
            }
        }

        Log($"raw brush UVs: {measured:N0} non-zero, largest magnitude {worst:0.#}");

        Assert.True(measured > 1_000, $"only {measured} brush vertices carry a texture coordinate at all");
        Assert.True(worst > 50f,
            $"the largest raw brush UV is {worst:0.##}, which is already normalised — dividing by the "
            + "texture size again would shrink every surface to a single texel");
    }

    /// <summary>
    /// After the level is prepared, brush UVs are in the range a renderer wants.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Not asserted as 0–1: a wall legitimately tiles its texture, so UVs beyond 1 are correct and
    /// expected. What is <i>not</i> correct is tiling hundreds of times, which is what the texel
    /// values gave. The bar is set where the two are unambiguously different.
    /// </para>
    /// <para>
    /// The median is the useful statistic rather than the maximum — one enormous surface can tile a
    /// great many times without being wrong, but half of them cannot.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void PreparedBrushUvsAreNormalisedAgainstTheirTextures()
    {
        var prepared = new LevelViewportService(new AssetCatalogService()).Prepare(game.LighthousePackage);

        var magnitudes = new List<float>();

        foreach (var item in prepared.Viewport.Items)
        {
            // Only the brushes: a static mesh's UVs come from its own vertex data and are already
            // normalised, so including them would dilute the measurement with known-good values.
            if (item.Model.Surfaces.Count == 0) continue;

            foreach (var vertex in item.Model.Vertices)
            {
                if (vertex.Uv == Vector2.Zero) continue;
                magnitudes.Add(MathF.Max(MathF.Abs(vertex.Uv.X), MathF.Abs(vertex.Uv.Y)));
            }
        }

        Assert.NotEmpty(magnitudes);
        magnitudes.Sort();

        float median = magnitudes[magnitudes.Count / 2];
        float ninetieth = magnitudes[(int)(magnitudes.Count * 0.9)];

        Log($"prepared UVs: {magnitudes.Count:N0} sampled, median {median:0.##}, 90th {ninetieth:0.##}, "
            + $"max {magnitudes[^1]:0.##}");

        // Texel-space UVs put the median in the hundreds. Normalised ones put it in single figures,
        // even allowing for surfaces that legitimately tile.
        Assert.True(median < 32f,
            $"the median brush UV magnitude is {median:0.#} — the textures are tiling far too often, "
            + "which is what an unnormalised texel coordinate looks like");
    }
}
