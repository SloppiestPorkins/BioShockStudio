using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Texture <c>Format</c> ordinal 12 — the format BioShock calls 3DC and which is really DXT5N.
/// </summary>
/// <remarks>
/// <para>
/// 274 texture exports in the game declare it, 64 distinct names, and every one is a normal map.
/// They decoded to nothing at all until this, so every mesh using one had no normal map.
/// </para>
/// <para>
/// <b>Two reference projects disagreed about what it is.</b> Nyko's texture note calls ordinal 12
/// "3DC — BC5/ATI2, two BC4 alpha blocks giving R and G". UModel's BioShock branch remaps it to
/// <c>TEXF_DXT5N</c> with the comment "Bioshock used 3DC name, but real format is DXT5N", and nvtt
/// then rebuilds the normal from <c>(alpha, green)</c> rather than <c>(red, green)</c>. The bytes
/// agree with UModel, and these tests are the check that says so — they are written as invariants a
/// normal map must satisfy, so they fail under the other reading rather than merely differing.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class NormalMapFormatTests(GameFixture game)
{
    private BioShockTexture Read(string map, string name)
    {
        using var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), map + ".bsm"));

        var export = package.Exports
            .Where(e => package.GetClassName(e) == TextureReader.ClassName
                        && string.Equals(e.ObjectName, name, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        Assert.True(export is not null, $"{name} is not in {map}");

        var texture = TextureReader.Read(package, export!);
        Assert.True(texture is not null, $"{name} did not decode");
        return texture!;
    }

    [RequiresGameFact]
    public void TheFormatIsRecognisedAndItsMipChainDecomposes()
    {
        var texture = Read("0-Lighthouse", "Cheese_Mould_Normal");

        Assert.Equal(BioShockTextureFormat.ThreeDc, texture.Format);
        Assert.NotEmpty(texture.Mips);

        // 16 bytes per 4x4 block, the same as DXT3/DXT5. Every mip has to land on it exactly, which
        // is what says the block size is right independently of what is inside a block.
        foreach (var mip in texture.Mips)
        {
            Assert.Equal(
                TextureReader.DataSize(BioShockTextureFormat.ThreeDc, mip.Width, mip.Height),
                mip.Data.Length);
        }
    }

    /// <summary>
    /// The decoded pixels are a unit normal field — which is the check that distinguishes DXT5N from
    /// BC5, rather than merely preferring one.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A tangent-space normal map is overwhelmingly "pointing out of the surface": X and Y centre on
    /// 128 and Z sits near 255. And every texel must satisfy <c>x² + y² ≤ 1</c>, because x and y are
    /// two components of a unit vector.
    /// </para>
    /// <para>
    /// Read as BC5 — taking the second half of the block as a BC4 pair when it is really the DXT5
    /// colour block — the green channel of this texture averages <b>57</b> instead of 128 and the
    /// image comes out magenta. So this test fails on the wrong reading; it does not just describe
    /// the right one.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheDecodedPixelsAreAUnitNormalField()
    {
        var texture = Read("0-Lighthouse", "Cheese_Mould_Normal");
        var mip = texture.Mips[0];

        byte[] rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height);
        int texels = mip.Width * mip.Height;
        Assert.Equal(texels * 4, rgba.Length);

        double x = 0, y = 0, z = 0;
        int offUnitSphere = 0;

        for (int i = 0; i < texels; i++)
        {
            x += rgba[i * 4];
            y += rgba[i * 4 + 1];
            z += rgba[i * 4 + 2];

            float nx = rgba[i * 4] / 255f * 2f - 1f;
            float ny = rgba[i * 4 + 1] / 255f * 2f - 1f;

            // The tolerance is for 8-bit quantisation, not for a wrong channel: a misread green
            // puts thousands of texels far outside this.
            if (nx * nx + ny * ny > 1.02f) offUnitSphere++;
        }

        x /= texels; y /= texels; z /= texels;

        Assert.True(Math.Abs(x - 128) < 24, $"X averages {x:0.0}, which is not a normal map's X");
        Assert.True(Math.Abs(y - 128) < 24, $"Y averages {y:0.0}, which is not a normal map's Y");
        Assert.True(z > 200, $"Z averages {z:0.0}; a normal map mostly points out of its surface");

        Assert.True(offUnitSphere == 0,
            $"{offUnitSphere} of {texels} texels have x² + y² > 1, so they are not unit normals");
    }

    /// <summary>
    /// Every texture in the game that declares this format now decodes.
    /// </summary>
    /// <remarks>
    /// The count is what makes this worth having: it was 274 exports producing nothing, and a
    /// regression would put them straight back to being reported as broken by <c>diagnose</c>.
    /// </remarks>
    [RequiresGameFact]
    public void EveryTextureDeclaringTheFormatDecodes()
    {
        int found = 0, decoded = 0;

        foreach (string file in Core.Game.GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports)
            {
                if (export.SerialSize <= 0) continue;
                if (package.GetClassName(export) != TextureReader.ClassName) continue;

                var header = TextureReader.ReadHeader(package, export);
                if (header?.Format != BioShockTextureFormat.ThreeDc) continue;

                found++;
                if (TextureReader.Read(package, export) is not null) decoded++;
            }
        }

        Assert.True(found > 200, $"only {found} exports declare the format; the sweep counted 274");
        Assert.Equal(found, decoded);
    }
}
