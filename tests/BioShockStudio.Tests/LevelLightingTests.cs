using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Lighting a level with its own lights.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is not the game's lighting model and the tests do not pretend otherwise.</b> BioShock
/// bakes its static lighting into lightmap atlases — <c>docs/research/bsp.md</c> §5.5 has the whole
/// descriptor chain — and this project reads none of it. What a light actor carries is a colour, a
/// brightness and a radius, applied here as simple point lights.
/// </para>
/// <para>
/// So what is asserted is not "the level looks like BioShock". It is that the lights <i>reach the
/// pixels</i>, and that they vary the image the way position-dependent lighting must.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelLightingTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// A light with no stated radius is dropped, and one with no brightness gets the measured median.
    /// </summary>
    /// <remarks>
    /// The asymmetry is the point. A missing <i>brightness</i> is interpolation inside data that has
    /// been measured — §C.6 gives 0.0–3.1 with a median of 1.0 — while a missing <i>radius</i> is an
    /// unknown reach, and choosing one would put light in the level the game may not have. Dropping
    /// is the honest option and this pins that it happens.
    /// </remarks>
    [RequiresGameFact]
    public void LightsWithNoStatedRadiusAreDroppedRatherThanGivenOne()
    {
        var prepared = new LevelViewportService(new AssetCatalogService()).Prepare(game.LighthousePackage);

        int declared = prepared.Scene.Lights.Count;
        int withRadius = prepared.Scene.Lights.Count(l => l.Radius is > 0);

        Log($"lights: {declared} decoded, {withRadius} with a radius, {prepared.Lights.Count} usable");

        Assert.Equal(withRadius, prepared.Lights.Count);
        Assert.True(prepared.Lights.Count > 100, $"only {prepared.Lights.Count} lights are usable");
        Assert.True(declared > prepared.Lights.Count,
            "every light stated a radius, so the dropping rule is not being exercised");

        // Nothing usable may carry a zero reach or a black colour — either would be a light that
        // cannot light anything, kept for no reason.
        Assert.All(prepared.Lights, l => Assert.True(l.Radius > 0));
        Assert.All(prepared.Lights, l => Assert.True(l.Brightness > 0));
    }

    /// <summary>
    /// The lights actually change the picture, and differently in different places.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Two checks, because either alone is weak. That the lit and unlit images <i>differ</i> proves
    /// the lights reach the shader at all. That the difference <i>varies between two positions in
    /// the map</i> proves they are being applied per-point rather than as a uniform brightening —
    /// which is what a bug that ignored light positions would look like, and which would still pass
    /// the first check.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheLightsChangeTheImageAndDoItDifferentlyInDifferentPlaces()
    {
        string medical = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        var prepared = new LevelViewportService(new AssetCatalogService()).Prepare(medical);

        Log($"1-Medical: {prepared.Lights.Count} usable lights of {prepared.Scene.Lights.Count} decoded");
        Assert.NotEmpty(prepared.Lights);

        // Two places, chosen from the lights themselves so both are somewhere the level is lit.
        var places = prepared.Lights
            .OrderByDescending(l => l.Radius)
            .Take(2)
            .Select(l => l.Position)
            .ToList();

        var differences = new List<double>();

        for (int i = 0; i < places.Count; i++)
        {
            var camera = new GhostCamera { Position = places[i], Yaw = 0.4f };
            var selection = prepared.Viewport.Select(camera, 1.5f, 250_000);

            var unlit = SoftwareRenderer.Render(
                selection.Instances, camera.ToPreviewCamera(),
                new RenderOptions { ShowSkeleton = false, ShowSockets = false }, 480, 320);

            var lit = SoftwareRenderer.Render(
                selection.Instances, camera.ToPreviewCamera(),
                new RenderOptions { ShowSkeleton = false, ShowSockets = false, Lights = prepared.Lights },
                480, 320);

            long total = 0;
            int drawn = 0;
            for (int p = 0; p < lit.Rgba.Length; p += 4)
            {
                if (lit.Rgba[p] == 32 && lit.Rgba[p + 1] == 32 && lit.Rgba[p + 2] == 32) continue;
                drawn++;
                total += Math.Abs(lit.Rgba[p] - unlit.Rgba[p])
                         + Math.Abs(lit.Rgba[p + 1] - unlit.Rgba[p + 1])
                         + Math.Abs(lit.Rgba[p + 2] - unlit.Rgba[p + 2]);
            }

            double average = drawn == 0 ? 0 : (double)total / drawn;
            differences.Add(average);
            Log($"  place {i}: {drawn:N0} drawn pixels, mean channel change {average:0.##}");

            if (Environment.GetEnvironmentVariable("BIOSHOCK_LIGHT_SNAPSHOT") is { Length: > 0 } path)
            {
                string directory = Path.GetDirectoryName(path) ?? ".";
                Directory.CreateDirectory(directory);
                string stem = Path.GetFileNameWithoutExtension(path);
                PngWriter.Write(Path.Combine(directory, $"{stem}_{i}_lit.png"), lit.Rgba, lit.Width, lit.Height);
                PngWriter.Write(Path.Combine(directory, $"{stem}_{i}_unlit.png"), unlit.Rgba, unlit.Width, unlit.Height);
            }
        }

        // They reach the pixels.
        Assert.All(differences, d => Assert.True(d > 1.0, $"the lights changed the image by only {d:0.##} per channel"));

        // And they are position-dependent: two places in the same map are not lit identically.
        Assert.True(Math.Abs(differences[0] - differences[1]) > 0.5,
            $"both places changed by the same amount ({differences[0]:0.##} and {differences[1]:0.##}), "
            + "so the lighting is not depending on where anything is");
    }
}
