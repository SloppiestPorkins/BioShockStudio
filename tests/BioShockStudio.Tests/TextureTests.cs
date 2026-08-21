using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using BioShockStudio.Core.Game;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class TextureTests(GameFixture game)
{
    private static BioShockTexture Load(BioShockPackage package, string name) =>
        TextureReader.Read(package, package.Exports
            .Where(e => e.ObjectName == name && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize)!)!;

    [RequiresGameFact]
    public void HandTexturesDecodeToKnownDimensions()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        foreach (string name in new[] { "Hand_DIFF", "Hand_NORM", "Hand_SPEC" })
        {
            var texture = Load(package, name);
            Assert.Equal(BioShockTextureFormat.Dxt1, texture.Format);
            Assert.Equal(2048, texture.Width);
            Assert.Equal(2048, texture.Height);
            Assert.Equal(10, texture.Mips.Count);
        }
    }

    [RequiresGameFact]
    public void MipChainHalvesAndMatchesTheFormatsDataSize()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var texture = Load(package, "Hand_DIFF");

        for (int i = 0; i < texture.Mips.Count; i++)
        {
            var mip = texture.Mips[i];
            Assert.Equal(TextureReader.DataSize(texture.Format, mip.Width, mip.Height), mip.Data.Length);
            if (i > 0)
            {
                Assert.Equal(Math.Max(1, texture.Mips[i - 1].Width / 2), mip.Width);
                Assert.Equal(Math.Max(1, texture.Mips[i - 1].Height / 2), mip.Height);
            }
        }
    }

    [RequiresGameFact]
    public void SourcePathIsPreserved()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var texture = Load(package, "Hand_DIFF");

        // The authoring path is useful provenance and proves the property list is being read right.
        // The hands' diffuse came from ..\..\..\Art\Source\WeaponsstPersonHands...
        Assert.Contains("Art", texture.SourcePath, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("1stPersonHand", texture.SourcePath, StringComparison.OrdinalIgnoreCase);
    }

    [RequiresGameFact]
    public void DecodingProducesPlausiblePixels()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var texture = Load(package, "Hand_DIFF");
        var top = texture.Mips[0];

        byte[] rgba = BlockCompression.Decode(texture.Format, top.Data, top.Width, top.Height);
        Assert.Equal(top.Width * top.Height * 4, rgba.Length);

        // A real diffuse map is neither uniform nor black.
        var distinct = new HashSet<int>();
        long total = 0;
        for (int i = 0; i < rgba.Length; i += 4 * 997)
        {
            distinct.Add((rgba[i] << 16) | (rgba[i + 1] << 8) | rgba[i + 2]);
            total += rgba[i] + rgba[i + 1] + rgba[i + 2];
        }

        Assert.True(distinct.Count > 100, $"only {distinct.Count} distinct sampled colours");
        Assert.True(total > 0);
    }

    [RequiresGameFact]
    public void EveryFormatInThePackageDecodes()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var seen = new HashSet<BioShockTextureFormat>();
        int decoded = 0, failed = 0;

        foreach (var export in package.Exports.Where(e => package.GetClassName(e) == TextureReader.ClassName))
        {
            var texture = TextureReader.Read(package, export);
            if (texture is null) { failed++; continue; }
            decoded++;
            seen.Add(texture.Format);

            var top = texture.Mips[0];
            Assert.Equal(TextureReader.DataSize(texture.Format, top.Width, top.Height), top.Data.Length);
        }

        // Measured: 1054 of 1062 decode. The remainder use a layout that is not understood yet and
        // return null rather than producing garbage.
        Assert.True(decoded > 1000, $"only {decoded} textures decoded");
        Assert.True(failed < 20, $"{failed} textures failed");
        Assert.Contains(BioShockTextureFormat.Dxt1, seen);
        Assert.Contains(BioShockTextureFormat.Dxt5, seen);
    }

    /// <summary>
    /// UE2 utility textures can be a single stored colour rather than a compressed mip chain. They
    /// are normal textures, not corrupt exports, and must stay available to a UE5 material export.
    /// </summary>
    [RequiresGameFact]
    public void SolidColourTextureVariantDecodesFromMipZero()
    {
        using var package = BioShockPackage.Open(Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "Entry.bsm"));
        var export = package.Exports.Single(e => e.ObjectName == "BlackTexture"
            && package.GetClassName(e) == TextureReader.ClassName);

        var header = TextureReader.ReadHeader(package, export);
        var texture = TextureReader.Read(package, export);

        Assert.Equal((BioShockTextureFormat.Rgba8, 32, 32), header);
        Assert.NotNull(texture);
        var mip = Assert.Single(texture!.Mips);
        Assert.Equal(32 * 32 * 4, mip.Data.Length);
        Assert.All(mip.Data.Chunk(4), pixel => Assert.Equal(new byte[] { 0, 0, 0, 255 }, pixel));
    }

    [RequiresGameFact]
    public void PngRoundTripsThroughAValidHeader()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var texture = Load(package, "Hand_DIFF");
        var mip = texture.Mips[^1];

        byte[] rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height);
        using var stream = new MemoryStream();
        PngWriter.Write(stream, rgba, mip.Width, mip.Height);

        byte[] png = stream.ToArray();
        Assert.Equal(new byte[] { 0x89, (byte)'P', (byte)'N', (byte)'G' }, png[..4]);
        Assert.Equal("IHDR", System.Text.Encoding.ASCII.GetString(png, 12, 4));
        Assert.Equal("IEND", System.Text.Encoding.ASCII.GetString(png, png.Length - 8, 4));
    }
}
