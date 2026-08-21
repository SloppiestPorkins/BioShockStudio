using System.Diagnostics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A textured level, drawn from inside it by the ghost camera.
/// </summary>
/// <remarks>
/// <c>BIOSHOCK_LEVELCAM_SNAPSHOT</c> writes the views out. The pixel checks below can only say that
/// something colourful was drawn; whether it looks like Rapture is what the images are for.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelTextureTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    private static void Snapshot(PreviewImage image, string suffix)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_LEVELCAM_SNAPSHOT") is not { Length: > 0 } path) return;
        string directory = Path.GetDirectoryName(path) ?? ".";
        Directory.CreateDirectory(directory);
        PngWriter.Write(
            Path.Combine(directory, $"{Path.GetFileNameWithoutExtension(path)}_{suffix}.png"),
            image.Rgba, image.Width, image.Height);
    }

    /// <summary>How much of the frame is not a shade of grey — i.e. actually textured.</summary>
    /// <remarks>
    /// A level drawn with no textures is entirely grey: the background, and lit grey geometry. So
    /// "some pixels have a colour cast" is exactly the measurement that separates a textured render
    /// from an untextured one, and it is one no triangle count can make.
    /// </remarks>
    private static double Coloured(PreviewImage image)
    {
        int coloured = 0, drawn = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            byte r = image.Rgba[i], g = image.Rgba[i + 1], b = image.Rgba[i + 2];
            if (r == 32 && g == 32 && b == 32) continue;
            drawn++;
            int max = Math.Max(r, Math.Max(g, b)), min = Math.Min(r, Math.Min(g, b));
            if (max - min > 12) coloured++;
        }
        return drawn == 0 ? 0 : (double)coloured / drawn;
    }

    [RequiresGameFact]
    public void AnInteriorWorldUsesItsVerifiedBakedLightAtlas()
    {
        string medical = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        var level = new LevelViewportService(new AssetCatalogService()).Prepare(medical);

        var baked = level.Viewport.Items
            .Where(item => item.Kind == BioShockStudio.Core.Level.LevelGeometryKind.BuiltWorld)
            .SelectMany(item => item.Model.Surfaces)
            .Where(surface => surface.LightMapTexture is not null)
            .ToList();

        Log($"1-Medical baked-light runs: {baked.Count:N0}");
        Assert.NotEmpty(baked);
        Assert.All(baked, surface => Assert.True(surface.LightMapTexture!.Width > 0
            && surface.LightMapTexture.Height > 0));

        // Atlas headers declare 1024², but this is allowed to select a smaller resident mip. What
        // matters to the first renderer integration is that real sampled light reaches vertices,
        // rather than merely that a texture object was found.
        Assert.Contains(level.Viewport.Items
                .Where(item => item.Kind == BioShockStudio.Core.Level.LevelGeometryKind.BuiltWorld)
                .SelectMany(item => item.Model.Vertices),
            vertex => vertex.BakedLight.X < 0.99f || vertex.BakedLight.Y < 0.99f || vertex.BakedLight.Z < 0.99f);

        // A visual artifact is required here: the failure that prompted this test was valid bytes
        // displayed through raw texel-space UVs. The assertions above cannot detect that a floor
        // texture is tiled thousands of times, so retain the corrected interior render on demand.
        var selection = level.Viewport.Select(level.Start, 16f / 10f, triangleBudget: 250_000);
        Snapshot(SoftwareRenderer.Render(selection.Instances, level.Start.ToPreviewCamera(),
            new RenderOptions { ShowSkeleton = false, ShowSockets = false, Textured = true }, 960, 600),
            "medical-lightmapped");

        // The GPU viewport is deliberately allowed a larger budget than the software fallback.
        // Its starting value must fit every visible Medical object: otherwise the first impression
        // of the level is missing exterior/window pieces rather than a complete place.
        var gpuDefault = level.Viewport.Select(level.Start, 16f / 10f, triangleBudget: 600_000 * 8);
        Assert.Equal(0, gpuDefault.Dropped);
    }

    [RequiresGameFact]
    public void ALevelDrawsFromInsideItselfWithItsOwnTextures()
    {
        var service = new LevelViewportService(new AssetCatalogService());

        var prepared = Stopwatch.StartNew();
        var level = service.Prepare(game.LighthousePackage);
        prepared.Stop();

        Log($"prepared {level.Scene.PackageName} in {prepared.ElapsedMilliseconds} ms");
        Log($"  {level.Viewport.Items.Count} items, {level.Viewport.TotalTriangles:N0} triangles");
        Log($"  {level.TextureSummary}");

        // What the texture cap actually costs, measured rather than assumed. Raising it from 256 to
        // 1024 is sixteen times the pixels per texture, and the total is what decides whether that
        // is affordable — for the level's own memory and for what is uploaded to the GPU.
        long bytes = level.Viewport.Items
            .SelectMany(i => i.Model.Surfaces)
            .Select(s => s.Texture)
            .Where(t => t is not null)
            .Distinct()
            .Sum(t => (long)t!.Rgba.Length);
        Log($"  decoded texture memory: {bytes / 1024 / 1024:N0} MB (cap {LevelViewportService.MaximumTexture})");
        Log($"  camera starts at {level.Start.Position:0}");

        Assert.NotEmpty(level.Viewport.Items);

        // The textures actually resolved. If this were zero the level would still draw — in grey —
        // which is exactly the "plausible and wrong" result this project keeps being caught by.
        Assert.True(level.TexturesLoaded > 50,
            $"only {level.TexturesLoaded} textures resolved across the whole level");
        Assert.True(level.TotalSurfaces - level.SurfacesWithoutTexture > level.TotalSurfaces / 2,
            $"only {level.TotalSurfaces - level.SurfacesWithoutTexture} of {level.TotalSurfaces} "
            + "surfaces bound a texture");

        var options = new RenderOptions { ShowSkeleton = false, ShowSockets = false, Textured = true };
        const int width = 960, height = 600;

        var camera = level.Start;
        double bestColour = 0;

        // Four headings from the starting point. One view could be facing a wall; four cannot all be.
        for (int i = 0; i < 4; i++)
        {
            var facing = camera.Look(i * MathF.PI / 2f, 0);
            var selection = level.Viewport.Select(facing, (float)width / height, triangleBudget: 250_000);

            var timer = Stopwatch.StartNew();
            var image = SoftwareRenderer.Render(
                selection.Instances, facing.ToPreviewCamera(), options, width, height);
            timer.Stop();

            double coloured = Coloured(image);
            bestColour = Math.Max(bestColour, coloured);

            Log($"  heading {i}: {selection.Instances.Count} instances, {selection.Triangles:N0} triangles, "
                + $"{selection.Dropped} dropped, {timer.ElapsedMilliseconds} ms, {coloured:P0} coloured");

            Snapshot(image, $"h{i}");
        }

        // Colour alone is NOT the test, and assuming it was is a mistake worth recording: the first
        // version of this asserted "more than 15% of drawn pixels carry a colour cast" and failed at
        // 11% on a render that is visibly correct. Rapture's exterior is grey-green concrete and
        // steel under water — the art is desaturated, so a threshold on saturation measures the
        // level designer's palette, not whether the pipeline works.
        //
        // What can fail honestly is a comparison: draw the same view with texturing off, and the
        // two images must differ. If no texture reaches a pixel they are identical.
        var forward = level.Start;
        var selectionA = level.Viewport.Select(forward, (float)width / height, triangleBudget: 250_000);

        var textured = SoftwareRenderer.Render(
            selectionA.Instances, forward.ToPreviewCamera(), options, width, height);
        var untextured = SoftwareRenderer.Render(
            selectionA.Instances, forward.ToPreviewCamera(), options with { Textured = false }, width, height);

        int differing = 0, drawn = 0;
        for (int i = 0; i < textured.Rgba.Length; i += 4)
        {
            bool isBackground = textured.Rgba[i] == 32 && textured.Rgba[i + 1] == 32 && textured.Rgba[i + 2] == 32;
            if (isBackground) continue;
            drawn++;
            if (textured.Rgba[i] != untextured.Rgba[i]
                || textured.Rgba[i + 1] != untextured.Rgba[i + 1]
                || textured.Rgba[i + 2] != untextured.Rgba[i + 2]) differing++;
        }

        double share = drawn == 0 ? 0 : (double)differing / drawn;
        Log($"  textured vs untextured: {differing:N0} of {drawn:N0} drawn pixels differ ({share:P0})");
        Log($"  most colourful heading: {bestColour:P0} (recorded, not asserted — see the comment)");

        Snapshot(untextured, "untextured");

        Assert.True(drawn > 10_000, "too little was drawn to compare");
        // Measured at 51%. The bar is set well below that rather than just under it: the point of
        // this check is to catch textures not arriving at all, which scores near zero, not to pin
        // the exact share — that moves with the camera and with which surfaces resolve.
        Assert.True(share > 0.3,
            $"only {share:P0} of drawn pixels change when texturing is turned off, so textures are "
            + "barely reaching the level's geometry");
    }
}
