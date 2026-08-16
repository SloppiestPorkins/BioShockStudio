using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Draws static meshes through the same preview path the window uses.
/// <para>
/// "Numeric validation has passed while the result was visibly wrong" is the project's most
/// expensive lesson, so a reader is not finished until something has been rendered from it. These
/// assert on pixels; <c>BIOSHOCK_STATIC_SNAPSHOT</c> writes the image out for a human to look at.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class StaticMeshRenderingTests(GameFixture game)
{
    private const int Width = 480;
    private const int Height = 480;

    private string MedicalFile => Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");

    private (MeshPreviewService Service, CatalogEntry Entry) Load(string name, string map = "1-Medical")
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), map + ".bsm"));

        var entry = AssetCatalogService.Catalogue(package, map)
            .Where(e => e.Name == name && e.ClassName == "StaticMesh")
            .MaxBy(e => e.SerialSize)
            ?? throw new InvalidOperationException($"{name} is not catalogued as a StaticMesh in {map}.");

        return (new MeshPreviewService(catalog), entry);
    }

    private static double Coverage(PreviewImage image, byte background = 32)
    {
        int drawn = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            if (image.Rgba[i] != background || image.Rgba[i + 1] != background || image.Rgba[i + 2] != background)
                drawn++;
        }
        return (double)drawn / (image.Width * image.Height);
    }

    private PreviewImage Draw(string name, out PreviewSubject subject, string map = "1-Medical")
    {
        var (service, entry) = Load(name, map);
        subject = service.Load(entry);
        var model = subject.Model;
        return SoftwareRenderer.Render(
            model,
            PreviewCamera.Frame(model.Centre, model.Radius).Orbit(0.6f, 0.3f),
            new RenderOptions { ShowSkeleton = false, ShowSockets = false },
            Width, Height);
    }

    [RequiresGameFact]
    public void Drill_LoadsWithoutAProblemAndDraws()
    {
        var image = Draw("ConeDrill", out var subject);

        Assert.Null(subject.Problem);
        Assert.True(subject.Model.HasGeometry);
        Assert.Empty(subject.Model.Bones);

        // Framed by its own bounds, the drill should fill a real part of the view. A collapsed or
        // exploded decode shows up here as almost nothing or almost everything.
        double coverage = Coverage(image);
        Assert.InRange(coverage, 0.05, 0.9);
    }

    [RequiresGameFact]
    public void BigDaddyAttachments_AllDraw()
    {
        foreach (string name in new[] { "ConeDrill", "ConeDrillCage", "ConeDrillBackpack" })
        {
            var image = Draw(name, out var subject);
            Assert.True(subject.Model.HasGeometry, $"{name} produced no geometry.");
            Assert.True(Coverage(image) > 0.02, $"{name} drew almost nothing.");
        }
    }

    [RequiresGameFact]
    public void BouncerGroup_ListsItsStaticAttachmentsAlongsideTheBody()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(MedicalFile);
        var body = AssetCatalogService.Catalogue(package, "1-Medical")
            .Where(e => e.Group == "NewProtectorBouncer" && e.ClassName == "SkeletalMesh")
            .MaxBy(e => e.SerialSize);

        if (body is null) return; // The Bouncer is not in every package.

        var subject = new MeshPreviewService(catalog).Load(body);

        // The three meshes its sockets name are in its own group, so the mesh picker must offer them.
        Assert.Contains("ConeDrill", subject.Meshes);
        Assert.Contains("ConeDrillCage", subject.Meshes);
        Assert.Contains("ConeDrillBackpack", subject.Meshes);
    }

    /// <summary>Writes renders to disk so a human can look at them. Off unless a path is given.</summary>
    [RequiresGameFact]
    public void Static_Snapshot()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_STATIC_SNAPSHOT");
        if (string.IsNullOrWhiteSpace(target)) return;

        string directory = Path.GetDirectoryName(target)!;
        Directory.CreateDirectory(directory);
        string stem = Path.GetFileNameWithoutExtension(target);

        // The last three name more than one material. They are here because per-section materials
        // cannot be checked numerically: a wrong pairing is still a complete, plausible mesh with
        // every triangle textured, and only looking at it shows the window glazed in hull metal.
        foreach (var (name, map) in new[]
                 {
                     ("ConeDrill", "1-Medical"), ("ConeDrillCage", "1-Medical"),
                     ("ConeDrillBackpack", "1-Medical"), ("Ammo_Pickup_Kerosene", "1-Medical"),
                     ("bat_vehicle", "0-Lighthouse"), ("CityGate", "0-Lighthouse"),
                     ("RotundaColumns", "0-Lighthouse"),
                     // Two that used to draw flat grey and now should not: the first names a
                     // PlantShader, whose slots are Alive*; the second names a Texture directly
                     // rather than a shader. Both are only checkable by looking.
                     ("kelp_01", "0-Lighthouse"), ("newspaper_old_05", "1-Medical"),
                 })
        {
            var image = Draw(name, out _, map);
            Core.Textures.PngWriter.Write(
                Path.Combine(directory, $"{stem}_{name}.png"), image.Rgba, image.Width, image.Height);
        }

        Assert.True(File.Exists(Path.Combine(directory, $"{stem}_ConeDrill.png")));
    }
}
