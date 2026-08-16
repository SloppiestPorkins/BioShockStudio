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

        // BSP surfaces that actually bound a texture, and only those.
        //
        // Two filters, and both were learned the hard way. Including static meshes buries the
        // measurement under two million known-good values — the first version of this test reported
        // an unchanged median while the fix it was checking made no difference to it. And including
        // BSP surfaces with NO texture is just as misleading in the other direction: nothing divides
        // their UVs because there is no size to divide by, they are two thirds of the surfaces, and
        // they held the median at 192 while the textured ones were already correct.
        foreach (var item in prepared.Viewport.Items)
        {
            if (item.Kind is not (LevelGeometryKind.Brush or LevelGeometryKind.BuiltWorld)) continue;

            foreach (var surface in item.Model.Surfaces)
            {
                if (surface.Texture is null) continue;

                for (int i = surface.FirstIndex; i < surface.FirstIndex + surface.IndexCount; i++)
                {
                    if (i >= item.Model.Indices.Count) break;
                    var uv = item.Model.Vertices[item.Model.Indices[i]].Uv;
                    if (uv == Vector2.Zero) continue;
                    magnitudes.Add(MathF.Max(MathF.Abs(uv.X), MathF.Abs(uv.Y)));
                }
            }
        }

        // How many BSP surfaces bound a texture at all. If this is near zero the UV measurement
        // below is meaningless — there was nothing to divide by — and that distinction is worth
        // reporting rather than inferring from a failure.
        int bspSurfaces = 0, bspTextured = 0;
        foreach (var item in prepared.Viewport.Items)
        {
            if (item.Kind is not (LevelGeometryKind.Brush or LevelGeometryKind.BuiltWorld)) continue;
            bspSurfaces += item.Model.Surfaces.Count;
            bspTextured += item.Model.Surfaces.Count(s => s.Texture is not null);
        }
        Log($"BSP surfaces: {bspTextured} of {bspSurfaces} bound a texture");

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
