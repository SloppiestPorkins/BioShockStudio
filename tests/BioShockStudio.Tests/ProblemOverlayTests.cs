using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The viewport half of the Problems panel: tinting the triangles whose material did not resolve.
/// </summary>
/// <remarks>
/// <para>
/// A run with no material draws flat grey, and so does a great deal of BioShock — bare concrete,
/// painted metal, the inside of a crate. The two are indistinguishable by eye, which is the class of
/// fault this project keeps paying for: the grey security cameras were found by a user, not by the
/// tool, and the tool held the evidence the whole time.
/// </para>
/// <para>
/// These tests assert on pixels in both directions, because an overlay that never fires and an
/// overlay that fires on everything are equally useless and look equally plausible in a screenshot.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class ProblemOverlayTests(GameFixture game)
{
    private const int Width = 320;
    private const int Height = 320;

    private (PreviewModel Model, PreviewCamera Camera) Load(string name, string map)
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), map + ".bsm"));

        var entry = AssetCatalogService.Catalogue(package, map)
            .Where(e => e.Name == name && e.ClassName == "StaticMesh")
            .MaxBy(e => e.SerialSize)
            ?? throw new InvalidOperationException($"{name} is not a StaticMesh in {map}.");

        var model = new MeshPreviewService(catalog).Load(entry).Model;
        return (model, PreviewCamera.Frame(model.Centre, model.Radius).Orbit(0.6f, 0.3f));
    }

    private static PreviewImage Draw(PreviewModel model, PreviewCamera camera, bool highlight) =>
        SoftwareRenderer.Render(
            model, camera,
            new RenderOptions { HighlightUnresolvedSurfaces = highlight },
            Width, Height);

    /// <summary>
    /// Pixels tinted toward magenta. The tint lifts red and blue and cuts green, so no shipped
    /// surface and no shading of one can reach this separation by accident.
    /// </summary>
    private static int Tinted(PreviewImage image)
    {
        int count = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            int r = image.Rgba[i], g = image.Rgba[i + 1], b = image.Rgba[i + 2];
            if (r - g > 80 && b - g > 80) count++;
        }
        return count;
    }

    /// <summary>Pixels the mesh drew at all, against the background.</summary>
    private static int Drawn(PreviewImage image, byte background = 32)
    {
        int count = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            if (image.Rgba[i] != background || image.Rgba[i + 1] != background
                || image.Rgba[i + 2] != background)
            {
                count++;
            }
        }
        return count;
    }

    /// <summary>
    /// A mesh with two unresolved runs of seven gets those runs tinted, and only those.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <c>Bomb</c> is the case worth testing rather than a wholly untextured mesh: the sweep reports
    /// <b>2 of its 7 surfaces</b> with no material, covering 792 of its 6,368 triangles. A per-mesh
    /// overlay would tint the whole thing and still look like it worked in a screenshot.
    /// </para>
    /// <para>
    /// The first mesh tried here was <c>frame_and_light</c>, whose unresolved run is 2 triangles of
    /// 522 — the overlay was correct and drew nothing visible from the test's camera. A test that
    /// cannot see the thing it asserts on is not evidence, so it was replaced rather than tuned.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void OnlyTheUnresolvedRunsAreTinted()
    {
        var (model, camera) = Load("Bomb", "5-Hephaestus");

        // The premise, checked rather than assumed: if this mesh ever resolves every slot, the test
        // measures nothing and should be pointed at another one rather than quietly passing.
        int unresolved = model.Surfaces.Count(s => s.MaterialName is null);
        Assert.True(unresolved > 0 && unresolved < model.Surfaces.Count,
            $"Bomb has {unresolved} unresolved of {model.Surfaces.Count} surfaces; this test needs "
            + "a partially-resolved mesh");

        var off = Draw(model, camera, highlight: false);
        var on = Draw(model, camera, highlight: true);

        Assert.Equal(0, Tinted(off));

        int tinted = Tinted(on);
        Assert.True(tinted > 0, "the overlay tinted nothing on a mesh with unresolved surfaces");

        // Tinted only where the fault is: strictly less than the mesh's own footprint. Equality
        // would mean the overlay is per-mesh, which is what this test exists to catch.
        int drawn = Drawn(on);
        Assert.True(tinted < drawn,
            $"{tinted} of {drawn} drawn pixels are tinted — the overlay is covering the whole mesh, "
            + "not the runs with no material");
    }

    /// <summary>Writes the overlay on and off, for a human to look at.</summary>
    /// <remarks>
    /// Off by default; set <c>BIOSHOCK_OVERLAY_SNAPSHOT</c> to a path. The tinted share is asserted
    /// above, but whether the tint is legible against the shading is a judgement only a picture
    /// supports.
    /// </remarks>
    [RequiresGameFact]
    public void Overlay_Snapshot()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_OVERLAY_SNAPSHOT");
        if (string.IsNullOrWhiteSpace(target)) return;

        string directory = Path.GetDirectoryName(target)!;
        Directory.CreateDirectory(directory);
        string stem = Path.GetFileNameWithoutExtension(target);

        var (model, _) = Load("Bomb", "5-Hephaestus");

        // Several angles: the unresolved runs are on one part of the mesh and are occluded from
        // most viewpoints, which is a property of the mesh rather than of the overlay.
        foreach (float yaw in new[] { 0.6f, 2.2f, 3.8f, 5.4f })
        {
            var camera = PreviewCamera.Frame(model.Centre, model.Radius).Orbit(yaw, 0.3f);

            foreach (bool highlight in new[] { false, true })
            {
                var image = SoftwareRenderer.Render(
                    model, camera,
                    new RenderOptions { HighlightUnresolvedSurfaces = highlight },
                    640, 640);

                Core.Textures.PngWriter.Write(
                    Path.Combine(directory, $"{stem}_{yaw:0.0}_{(highlight ? "on" : "off")}.png"),
                    image.Rgba, image.Width, image.Height);
            }
        }

        Assert.True(File.Exists(Path.Combine(directory, $"{stem}_0.6_on.png")));
    }

    /// <summary>
    /// A mesh whose materials all resolve is drawn identically with the overlay on.
    /// </summary>
    /// <remarks>
    /// <c>ConeDrill</c>'s runs are pinned material by material in <c>MeshSurfaceTests</c>. If the
    /// overlay changes a single pixel of it, the overlay is reporting a fault that is not there —
    /// which would be worse than not having it, because the panel and the viewport would disagree.
    /// </remarks>
    [RequiresGameFact]
    public void AMeshWhoseMaterialsAllResolveIsUnchanged()
    {
        var (model, camera) = Load("ConeDrill", "1-Medical");

        Assert.All(model.Surfaces, s => Assert.NotNull(s.MaterialName));

        var off = Draw(model, camera, highlight: false);
        var on = Draw(model, camera, highlight: true);

        Assert.Equal(off.Rgba, on.Rgba);
    }
}
