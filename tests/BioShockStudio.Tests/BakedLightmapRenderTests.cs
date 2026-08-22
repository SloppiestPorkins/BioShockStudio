using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The lit/unlit comparison Gate 0 item 3 asks for, before baked lightmaps become a default.
/// </summary>
/// <remarks>
/// <para>
/// <b>Until now the baked lightmaps could not be looked at in a test at all.</b> They reached only
/// the GPU viewport, which needs a real GL context and cannot render headless; the software
/// rasteriser — the path this project renders and checks everything else with — had no lightmap
/// support whatsoever and drew every level unlit. So "lightmaps work" rested on log evidence and on
/// the atlas binding being byte-proven, neither of which can see a lightmap applied to the wrong
/// surface, at the wrong scale, or upside down.
/// </para>
/// <para>
/// <b>And the sampling was per vertex, which for BSP is close to throwing the lightmap away.</b> A
/// compiled-world surface is a large flat polygon; sampling its atlas at three corners and
/// interpolating reconstructs a flat gradient from data that exists precisely to vary across the
/// face. <c>RenderOptions.BakedLightmaps</c> samples per pixel.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BakedLightmapRenderTests(GameFixture game)
{
    private const int Width = 900;
    private const int Height = 600;

    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>Mean luminance, and how much the image varies — a flat wash and a bake differ in both.</summary>
    private static (double Mean, double Deviation) Luminance(PreviewImage image)
    {
        double sum = 0, sumSquares = 0;
        int pixels = image.Rgba.Length / 4;

        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            double l = 0.2126 * image.Rgba[i] + 0.7152 * image.Rgba[i + 1] + 0.0722 * image.Rgba[i + 2];
            sum += l;
            sumSquares += l * l;
        }

        double mean = sum / pixels;
        return (mean, Math.Sqrt(Math.Max(0, sumSquares / pixels - mean * mean)));
    }

    private static long DifferingPixels(PreviewImage a, PreviewImage b)
    {
        long differing = 0;
        for (int i = 0; i < a.Rgba.Length && i < b.Rgba.Length; i += 4)
            if (Math.Abs(a.Rgba[i] - b.Rgba[i]) > 8
                || Math.Abs(a.Rgba[i + 1] - b.Rgba[i + 1]) > 8
                || Math.Abs(a.Rgba[i + 2] - b.Rgba[i + 2]) > 8)
                differing++;
        return differing;
    }

    [RequiresGameFact]
    public void TheBakedLightmapChangesWhatIsDrawnAndCanBeLookedAt()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        string map = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        var level = new LevelViewportService(catalog).Prepare(map);

        // The compiled world only: the lightmap belongs to it, and including the props would dilute
        // the comparison with geometry that cannot change between the two renders.
        var items = level.Viewport.Items
            .Where(i => i.Kind == LevelGeometryKind.BuiltWorld)
            .ToList();

        Assert.NotEmpty(items);

        int withAtlas = items.Sum(i => i.Model.Surfaces.Count(s => s.LightMapTexture is not null));
        int surfaces = items.Sum(i => i.Model.Surfaces.Count);
        Log($"{Path.GetFileNameWithoutExtension(map)}: {items.Count} built-world items, "
            + $"{withAtlas} of {surfaces} surfaces carry a lightmap atlas");

        // Not vacuous: if nothing carries an atlas the two renders are trivially identical and the
        // comparison would "pass" while proving nothing.
        Assert.True(withAtlas > 0, "no compiled-world surface carries a lightmap atlas to compare");

        var instances = items
            .Select(i => new PreviewInstance(i.Model, null, i.Transform))
            .ToList();

        // FROM INSIDE THE LEVEL, not framing the whole map.
        //
        // The first version of this test orbited the entire compiled world, where every surface is a
        // few pixels across — and the lit render came out as unreadable speckle that looked like a
        // broken sampler. It was a useless viewpoint, not a broken sampler: baked light is a
        // property of a wall you are standing near, and a lightmap judged from orbit is judged at a
        // scale that cannot show it. The camera sits at a position a user reported from the
        // viewport's own readout, in the game's coordinates, converted to the basis the renderer
        // uses.
        var eye = GameBasis.Convert(new Vector3(-24495, 2282, 8350));
        var camera = new GhostCamera { Position = eye, Yaw = -0.12f, Pitch = 0.09f }.ToPreviewCamera();

        var unlit = SoftwareRenderer.Render(instances, camera,
            new RenderOptions { ShowSkeleton = false, ShowSockets = false, BakedLightmaps = false },
            Width, Height);
        var lit = SoftwareRenderer.Render(instances, camera,
            new RenderOptions { ShowSkeleton = false, ShowSockets = false, BakedLightmaps = true },
            Width, Height);

        var (unlitMean, unlitDeviation) = Luminance(unlit);
        var (litMean, litDeviation) = Luminance(lit);
        long differing = DifferingPixels(unlit, lit);

        Log($"  unlit: mean luminance {unlitMean:0.0}, deviation {unlitDeviation:0.0}");
        Log($"  lit:   mean luminance {litMean:0.0}, deviation {litDeviation:0.0}");
        Log($"  {differing:N0} pixels differ by more than 8/255");

        if (Environment.GetEnvironmentVariable("BIOSHOCK_LIGHTMAP_SNAPSHOT") is { Length: > 0 } path)
        {
            string directory = Path.GetDirectoryName(path) ?? ".";
            Directory.CreateDirectory(directory);
            PngWriter.Write(Path.Combine(directory, "lightmap_unlit.png"), unlit.Rgba, unlit.Width, unlit.Height);
            PngWriter.Write(Path.Combine(directory, "lightmap_lit.png"), lit.Rgba, lit.Width, lit.Height);
            Log($"  wrote lightmap_unlit.png and lightmap_lit.png to {directory}");
        }

        // The bake must actually change the image. Equal renders would mean the atlas is bound but
        // never sampled — which is exactly what the per-vertex path did to a large flat surface.
        Assert.True(differing > 10_000,
            $"only {differing} pixels differ between the lit and unlit renders, so the lightmap is "
            + "bound but is not reaching the fragments");
    }
}
