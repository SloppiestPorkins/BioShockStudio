using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Pins the texture-format side of Gate 0's remaining baked-light ambiguity.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LightmapAtlasFormatTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalsLightmapAtlasesAreOrdinaryDxt1()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var model = ModelReader.BuiltWorld(package);
        Assert.NotNull(model);
        var world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]);
        Assert.NotNull(world);

        var formats = new Dictionary<BioShockTextureFormat, int>();
        int decoded = 0;
        foreach (var entry in world.LightMapTextures)
        {
            Assert.True(entry.Texture.IsExport);
            var texture = TextureReader.Read(package, package.Exports[entry.Texture.ExportIndex]);
            Assert.NotNull(texture);
            formats[texture.Format] = formats.GetValueOrDefault(texture.Format) + 1;

            var mip = Assert.Single(texture.Mips.Take(1));
            var rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height);
            Assert.Equal(mip.Width * mip.Height * 4, rgba.Length);
            decoded++;
        }

        Assert.Equal(14, decoded);
        Assert.Equal(new Dictionary<BioShockTextureFormat, int>
        {
            [BioShockTextureFormat.Dxt1] = 14,
        }, formats);
    }
}
