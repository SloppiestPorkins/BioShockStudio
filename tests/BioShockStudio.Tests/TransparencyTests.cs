using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers alpha in the viewport. The renderer used to sample only the colour channels, so every
/// surface drew solid — the lighthouse kelp, which is alpha cards, came out as rectangular slabs.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class TransparencyTests(GameFixture game)
{
    private (MeshPreviewService Preview, CatalogEntry Entry) Load(string name)
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(game.LighthousePackage);
        var entry = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Where(e => e.Name == name)
            .MaxBy(e => e.SerialSize)
            ?? throw new InvalidOperationException($"{name} is not catalogued.");

        return (new MeshPreviewService(catalog), entry);
    }

    private static int Covered(PreviewImage image, byte background = 32)
    {
        int drawn = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            if (image.Rgba[i] != background || image.Rgba[i + 1] != background || image.Rgba[i + 2] != background)
                drawn++;
        }
        return drawn;
    }

    private static PreviewImage Draw(PreviewModel model, bool transparency)
    {
        var camera = PreviewCamera.Frame(model).Orbit(0.5f, 0.15f);
        return SoftwareRenderer.Render(
            [new PreviewInstance(model)], camera,
            new RenderOptions { ShowSkeleton = false, ShowSockets = false, Transparency = transparency },
            320, 320);
    }

    [RequiresGameFact]
    public void KelpDrawsItsHolesRatherThanASolidSlab()
    {
        var (preview, entry) = Load("Kelp_Long_01_mesh");
        var model = preview.Load(entry).Model;

        Assert.NotNull(model.Texture);
        Assert.True(model.Texture.HasTransparency, "the kelp texture should carry alpha");

        int solid = Covered(Draw(model, transparency: false));
        int cut = Covered(Draw(model, transparency: true));

        // Roughly two thirds of the texture is fully transparent, so honouring it must remove a
        // large part of the silhouette — but not all of it, which would mean the mesh vanished.
        Assert.True(cut < solid * 0.85, $"transparency removed only {solid - cut} of {solid} covered pixels");
        Assert.True(cut > solid * 0.15, $"transparency erased the mesh: {cut} pixels left of {solid}");
    }

    [RequiresGameFact]
    public void AnOpaqueMeshDrawsIdenticallyEitherWay()
    {
        var (preview, entry) = Load("NEWPlayerHands");
        var model = preview.Load(entry).Model;

        Assert.NotNull(model.Texture);
        Assert.False(model.Texture.HasTransparency, "the hands texture is opaque");

        var solid = Draw(model, transparency: false);
        var alpha = Draw(model, transparency: true);

        // A texture with no alpha must take exactly the path it always did. This is what bounds the
        // risk of the change: it cannot alter anything that was already correct.
        Assert.Equal(solid.Rgba, alpha.Rgba);
    }

    [RequiresGameFact]
    public void AlphaSurvivesTheTextureDecode()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var kelp = package.Exports
            .Where(e => e.ObjectName.Contains("Kelp", StringComparison.OrdinalIgnoreCase)
                        && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);

        if (kelp is null) return;

        var texture = TextureReader.Read(package, kelp)!;
        var mip = texture.Mips[0];
        byte[] rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height);

        int transparent = 0, opaque = 0, partial = 0;
        for (int i = 3; i < rgba.Length; i += 4)
        {
            if (rgba[i] == 0) transparent++;
            else if (rgba[i] == 255) opaque++;
            else partial++;
        }

        // All three bands present: the decode is carrying a real alpha ramp, not a flat 255 and not
        // a binary mask that lost its intermediate values.
        Assert.True(transparent > 0, "no fully transparent texels");
        Assert.True(opaque > 0, "no fully opaque texels");
        Assert.True(partial > 0, "no partially transparent texels — the alpha ramp was flattened");
    }
}
