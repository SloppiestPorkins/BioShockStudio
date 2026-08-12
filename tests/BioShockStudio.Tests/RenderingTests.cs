using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the software renderer that drives the 3D preview.
/// <para>
/// A viewport is exactly the kind of thing that can look plausible and be wrong, so these assert on
/// the pixels: that the model covers the view, that a posed frame differs from the rest pose, and
/// that the overlays actually draw.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class RenderingTests(GameFixture game)
{
    private const int Width = 320;
    private const int Height = 240;

    private (MeshPreviewService Service, CatalogEntry Entry) Hands()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(game.LighthousePackage);
        var entry = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        return (new MeshPreviewService(catalog), entry);
    }

    /// <summary>Fraction of pixels that are not the background.</summary>
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

    private static double Difference(PreviewImage a, PreviewImage b)
    {
        int changed = 0;
        for (int i = 0; i < a.Rgba.Length; i += 4)
            if (a.Rgba[i] != b.Rgba[i] || a.Rgba[i + 1] != b.Rgba[i + 1]) changed++;
        return (double)changed / (a.Width * a.Height);
    }

    [RequiresGameFact]
    public void Model_LoadsGeometrySkeletonSocketsAndATexture()
    {
        var (service, entry) = Hands();
        var subject = service.Load(entry);

        Assert.Null(subject.Problem);
        Assert.True(subject.Model.HasGeometry);
        Assert.Equal(4852, subject.Model.Vertices.Count);
        Assert.Equal(47, subject.Model.Bones.Count);
        Assert.Contains(subject.Model.Sockets, s => s.Name == "Pistol");

        // Resolved through the material, so the FacingShader's facing diffuse is found.
        Assert.NotNull(subject.Model.Texture);
        Assert.Contains("FastReloadPistol", subject.Animations);
    }

    [RequiresGameFact]
    public void Model_ExposesEveryMeshInTheGroupNotOnlyTheLargest()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        var service = new MeshPreviewService(catalog);

        using var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var entry = AssetCatalogService.Catalogue(package, "1-Medical")
            .First(e => e.Group == "AggressorBabyJane" && e.Category is AssetCategory.Characters or AssetCategory.Props);

        var subject = service.Load(entry);

        // The splicer group carries several bodies on one skeleton; taking only the largest hid the
        // rest, which is what a user notices first.
        Assert.True(subject.Meshes.Count > 1, $"expected several meshes, found {subject.Meshes.Count}");
        Assert.NotNull(subject.SelectedMesh);
        Assert.Contains(subject.SelectedMesh, subject.Meshes);

        // Each variant must actually load as different geometry, not silently fall back to the first.
        var counts = new List<int>();
        foreach (string mesh in subject.Meshes.Take(3))
        {
            var variant = service.Load(entry, mesh);
            Assert.Equal(mesh, variant.SelectedMesh);
            if (variant.Model.HasGeometry) counts.Add(variant.Model.Vertices.Count);

            // The skeleton is shared, so switching body must not change the rig.
            Assert.Equal(subject.Model.Bones.Count, variant.Model.Bones.Count);
        }

        Assert.True(counts.Distinct().Count() > 1, "the variants all produced identical geometry");
    }

    [RequiresGameFact]
    public void Render_DrawsTheModelAcrossTheView()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;

        var image = SoftwareRenderer.Render(
            model, PreviewCamera.Frame(model), new RenderOptions(), Width, Height);

        Assert.Equal(Width, image.Width);
        Assert.Equal(Height, image.Height);

        // A framed model must fill a meaningful part of the view. A blank frame — the failure a
        // camera or projection mistake produces — is well under a percent.
        double coverage = Coverage(image);
        Assert.True(coverage > 0.08, $"only {coverage:P1} of the view was drawn");
        Assert.True(coverage < 0.95, $"{coverage:P1} of the view was drawn, which suggests the camera is inside the mesh");
    }

    [RequiresGameFact]
    public void Camera_ZoomMovesTowardAndAwayAndCannotInvert()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var camera = PreviewCamera.Frame(model);

        var closer = camera.Zoom(0.88f);
        var further = camera.Zoom(1f / 0.88f);
        Assert.True(closer.Distance < camera.Distance);
        Assert.True(further.Distance > camera.Distance);

        // Zooming in hard must not pass through the subject and come out inverted.
        var hard = camera;
        for (int i = 0; i < 200; i++) hard = hard.Zoom(0.88f);
        Assert.True(hard.Distance > 0f);

        var near = SoftwareRenderer.Render(model, closer, new RenderOptions(), Width, Height);
        var far = SoftwareRenderer.Render(model, further, new RenderOptions(), Width, Height);
        Assert.True(Coverage(near) > Coverage(far), "zooming in should fill more of the view");
    }

    [RequiresGameFact]
    public void Render_IsStableForTheSameInputs()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var camera = PreviewCamera.Frame(model);

        var first = SoftwareRenderer.Render(model, camera, new RenderOptions(), Width, Height);
        var second = SoftwareRenderer.Render(model, camera, new RenderOptions(), Width, Height);

        Assert.Equal(first.Rgba, second.Rgba);
    }

    [RequiresGameFact]
    public void Render_OrbitingChangesTheView()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var camera = PreviewCamera.Frame(model);

        var front = SoftwareRenderer.Render(model, camera, new RenderOptions(), Width, Height);
        var side = SoftwareRenderer.Render(model, camera.Orbit(1.2f, 0f), new RenderOptions(), Width, Height);

        Assert.True(Difference(front, side) > 0.05);
    }

    [RequiresGameFact]
    public void Render_AnimatedFramesDeformTheMesh()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var animation = service.LoadAnimation(entry, "FastReloadPistol");

        Assert.NotNull(animation);
        Assert.Equal(55, animation.FrameCount);

        // Framed over the animation's whole range: the hands travel far enough during a reload to
        // leave a view framed on the rest pose.
        var (centre, radius) = model.BoundsOver(model.SamplePoses(animation.Decoded));
        var camera = PreviewCamera.Frame(centre, radius);
        var options = new RenderOptions();

        var first = SoftwareRenderer.Render(model, camera, options, Width, Height, model.Pose(animation.Decoded, 0));
        var middle = SoftwareRenderer.Render(model, camera, options, Width, Height, model.Pose(animation.Decoded, 27));

        // The reload moves the hands a long way; frame 27 must not look like frame 0.
        Assert.True(Difference(first, middle) > 0.05, "the posed frame did not differ from the first frame");

        // Both frames must still draw a real model. The threshold is lower than the rest-pose test's
        // because framing over the whole animation has to fit the widest moment, so no single frame
        // fills the view — that is the cost of a camera that does not chase the subject.
        Assert.True(Coverage(first) > 0.02, $"frame 0 covered {Coverage(first):P1}");
        Assert.True(Coverage(middle) > 0.02, $"frame 27 covered {Coverage(middle):P1}");
    }

    [RequiresGameFact]
    public void Model_LoadsTheNormalAndSpecularMapsTheMaterialBinds()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;

        // The hands' FacingShader binds Hand_DIFF, Hand_NORM and Hand_SPEC.
        Assert.NotNull(model.Texture);
        Assert.NotNull(model.NormalMap);
        Assert.NotNull(model.SpecularMap);

        // And the shipped tangent basis survives the mesh read, or a normal map cannot be applied
        // in the space it was authored in.
        Assert.Contains(model.Vertices, v => v.Tangent.LengthSquared() > 0.5f);
        Assert.Contains(model.Vertices, v => v.Binormal.LengthSquared() > 0.5f);
    }

    [RequiresGameFact]
    public void Render_NormalAndSpecularMapsChangeTheSurface()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var camera = PreviewCamera.Frame(model);

        var flat = SoftwareRenderer.Render(
            model, camera, new RenderOptions { Shaded = false }, Width, Height);
        var shaded = SoftwareRenderer.Render(
            model, camera, new RenderOptions { Shaded = true }, Width, Height);

        // Same geometry and same base colour, so any difference is the normal and specular maps.
        Assert.True(Difference(flat, shaded) > 0.02, "the maps made no visible difference");

        // Neither may blank the model or produce out-of-range colour.
        Assert.True(Coverage(shaded) > 0.08);
    }

    [RequiresGameFact]
    public void Render_SkeletonAndSocketOverlaysDraw()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var camera = PreviewCamera.Frame(model);

        var plain = SoftwareRenderer.Render(model, camera, new RenderOptions(), Width, Height);
        var withBones = SoftwareRenderer.Render(
            model, camera, new RenderOptions { ShowSkeleton = true, ShowSockets = true }, Width, Height);

        // Overlays draw over the mesh, so enabling them must change pixels.
        Assert.True(Difference(plain, withBones) > 0.002);
    }

    [RequiresGameFact]
    public void Render_WireframeDiffersFromSolid()
    {
        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var camera = PreviewCamera.Frame(model);

        var solid = SoftwareRenderer.Render(model, camera, new RenderOptions(), Width, Height);
        var wire = SoftwareRenderer.Render(model, camera, new RenderOptions { Wireframe = true }, Width, Height);

        Assert.True(Difference(solid, wire) > 0.05);
        Assert.True(Coverage(wire) < Coverage(solid));
    }

    [RequiresGameFact]
    public void Render_AMeshWithNoReadableGeometryStillShowsItsSkeleton()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(game.WeaponPackage);
        var entry = AssetCatalogService.Catalogue(package, "ShockGame")
            .First(e => e.Category == AssetCategory.SkeletalMeshes && e.Name == "TommyGunMESH");

        var subject = new MeshPreviewService(catalog).Load(entry);

        // This variant is not readable, and the preview says so rather than showing an empty box.
        Assert.False(subject.Model.HasGeometry);
        Assert.NotNull(subject.Problem);

        if (subject.Model.Bones.Count > 0)
        {
            var image = SoftwareRenderer.Render(
                subject.Model, PreviewCamera.Frame(subject.Model), new RenderOptions(), Width, Height);
            Assert.True(Coverage(image) > 0.001, "the skeleton should still be drawn");
        }
    }

    /// <summary>Writes a render to disk so a human can look at it. Off unless a path is given.</summary>
    [RequiresGameFact]
    public void Render_Snapshot()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_RENDER_SNAPSHOT");
        if (string.IsNullOrWhiteSpace(target)) return;

        var (service, entry) = Hands();
        var model = service.Load(entry).Model;
        var animation = service.LoadAnimation(entry, "FastReloadPistol");
        var (centre, radius) = animation is null
            ? (model.Centre, model.Radius)
            : model.BoundsOver(model.SamplePoses(animation.Decoded));
        var camera = PreviewCamera.Frame(centre, radius).Orbit(0.6f, 0f);

        var image = SoftwareRenderer.Render(
            model, camera, new RenderOptions { ShowSkeleton = false, ShowSockets = false }, 640, 720,
            animation is null ? null : model.Pose(animation.Decoded, 27));

        Core.Textures.PngWriter.Write(target, image.Rgba, image.Width, image.Height);
        Assert.True(File.Exists(target));
    }
}
