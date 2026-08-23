using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// <c>Cubemap</c> exports: six ordinary textures named as one object.
/// </summary>
/// <remarks>
/// Gate 1 item 3's cubemap half. The finding worth keeping is that there was nothing hard here —
/// a cubemap introduces no new payload format, its <c>Faces</c> entries are object references to
/// plain <c>Texture</c> exports the reader already handled. The gap was that nothing looked.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class CubemapTests(GameFixture game)
{
    private static IEnumerable<ObjectExport> Cubemaps(BioShockPackage package) =>
        package.Exports.Where(e => package.GetClassName(e) == CubemapReader.ClassName);

    [RequiresGameFact]
    public void ACubemapResolvesSixFaces()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var export = Cubemaps(package).FirstOrDefault();
        Assert.True(export is not null, "0-Lighthouse holds no Cubemap exports");

        var cubemap = CubemapReader.Read(package, export!);
        Assert.NotNull(cubemap);
        Assert.Equal(6, cubemap!.Faces.Count);
        Assert.Empty(cubemap.UnreadableFaces);
        Assert.True(cubemap.IsComplete);

        // Each face is a real decoded texture, not an empty shell.
        foreach (var face in cubemap.Faces)
        {
            Assert.NotEmpty(face.Mips);
            Assert.True(face.Width > 0 && face.Height > 0);
        }

        // The faces belong to this cubemap: the game names them <cubemap>_Face_N.
        foreach (var (face, index) in cubemap.Faces.Select((f, i) => (f, i)))
            Assert.Equal($"{cubemap.Name}_Face_{index}", face.Name);
    }

    /// <summary>
    /// Every cubemap in the package resolves, so the first one was not a lucky sample.
    /// </summary>
    [RequiresGameFact]
    public void EveryCubemapInThePackageResolves()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        int total = 0, complete = 0;
        foreach (var export in Cubemaps(package))
        {
            total++;
            var cubemap = CubemapReader.Read(package, export);
            if (cubemap?.IsComplete == true) complete++;
        }

        Assert.True(total > 0, "no cubemaps found");
        Assert.Equal(total, complete);
    }

    /// <summary>
    /// A cubemap is not a texture, and asking the wrong reader for one gets nothing rather than
    /// something plausible.
    /// </summary>
    [RequiresGameFact]
    public void TheReaderRefusesExportsThatAreNotCubemaps()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var texture = package.Exports.First(e => package.GetClassName(e) == TextureReader.ClassName);
        Assert.Null(CubemapReader.Read(package, texture));
    }

    /// <summary>
    /// A cubemap binding is recognised as cubemap usage, and cubemaps are colour.
    /// </summary>
    [RequiresGameFact]
    public void ACubemapBindingCarriesCubemapIntent()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var cubemap = CubemapReader.Read(package, Cubemaps(package).First());
        Assert.NotNull(cubemap);

        var intent = TextureIntent.For(cubemap!.Faces[0], "ReflectionCubemap");
        Assert.Equal(TextureUsage.Cubemap, intent.Usage);
        Assert.Equal(TextureColourSpace.Srgb, intent.ColourSpace);
    }
}
