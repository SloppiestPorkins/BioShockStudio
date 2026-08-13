using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the bulk store: the eight gigabytes of texture mips the packages ship without.
/// </summary>
/// <remarks>
/// Most of the game's art is stripped. A <c>Texture</c> export declares <c>USize</c> 2048 and
/// carries a chain topping out at 64, with <c>HasBeenStripped</c> set — the missing head is in
/// <c>BulkContent</c>, indexed by <c>Catalog.bdc</c>.
/// </remarks>
[Collection(GameCollection.Name)]
public sealed class BulkTextureTests(GameFixture game)
{
    private BulkTextureCatalog Catalog() =>
        BulkTextureCatalog.Load(game.RequireRoot) ?? throw new InvalidOperationException("no bulk catalogue");

    private string MedicalPackage =>
        Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");

    [RequiresGameFact]
    public void TheCatalogueParsesEveryEntryConsistently()
    {
        var catalog = Catalog();

        Assert.Equal(5777, catalog.Entries.Count);
        Assert.Equal(201, catalog.Entries.Select(e => e.Chunk).Distinct().Count());

        // Two invariants that hold for every single entry. A misparse does not produce these.
        Assert.All(catalog.Entries, e => Assert.Equal(0, e.Offset % BulkTextureCatalog.OffsetAlignment));
        Assert.All(catalog.Entries, e => Assert.True(e.Size > 0));
        Assert.All(catalog.Entries, e => Assert.EndsWith(".blk", e.Chunk, StringComparison.OrdinalIgnoreCase));
        Assert.All(catalog.Entries, e => Assert.False(string.IsNullOrWhiteSpace(e.Texture)));
    }

    [RequiresGameFact]
    public void EverySizeIsAnExactMipChainSum()
    {
        var catalog = Catalog();

        // The strongest evidence the record layout is right: each size is the sum of a run of mip
        // levels for a square power of two, to the byte. 2,793,472 is DXT1 at 2048+1024+512+256+128.
        int explained = catalog.Entries.Count(e => IsMipChainSum(e.Size, 8) || IsMipChainSum(e.Size, 16));

        Assert.Equal(catalog.Entries.Count, explained);
    }

    private static bool IsMipChainSum(int size, int blockBytes)
    {
        for (int top = 8192; top >= 4; top /= 2)
        {
            long total = 0;
            for (int edge = top; edge >= 1; edge /= 2)
            {
                long blocks = Math.Max(1, edge / 4);
                total += blocks * blocks * blockBytes;
                if (total == size) return true;
                if (total > size) break;
            }
        }

        return false;
    }

    [RequiresGameFact]
    public void AStrippedTextureComesBackAtItsDeclaredSize()
    {
        using var package = BioShockPackage.Open(MedicalPackage);
        var export = package.Exports
            .Where(e => e.ObjectName == "ChemThrow_Pickup_Kero_Diffuse"
                        && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize)!;

        var withoutBulk = TextureReader.Read(package, export)!;
        var withBulk = TextureReader.Read(package, export, Catalog())!;

        // What the package carries on its own: the tail.
        Assert.Equal(2048, withoutBulk.DeclaredWidth);
        Assert.Equal(5, withoutBulk.StrippedMipCount);
        Assert.Equal(64, withoutBulk.Width);
        Assert.False(withoutBulk.IsComplete);

        // And with the bulk store, the whole chain.
        Assert.Equal(2048, withBulk.Width);
        Assert.Equal(2048, withBulk.Height);
        Assert.True(withBulk.IsComplete);
        Assert.Equal(withoutBulk.Mips.Count + 5, withBulk.Mips.Count);

        // Each level is half the one above it, with no gap where the two chains were joined.
        for (int i = 1; i < withBulk.Mips.Count; i++)
        {
            Assert.Equal(Math.Max(1, withBulk.Mips[i - 1].Width / 2), withBulk.Mips[i].Width);
            Assert.Equal(
                TextureReader.DataSize(withBulk.Format, withBulk.Mips[i].Width, withBulk.Mips[i].Height),
                withBulk.Mips[i].Data.Length);
        }
    }

    [RequiresGameFact]
    public void TheRecoveredMipsAreTheSameImageThePackageShipped()
    {
        using var package = BioShockPackage.Open(MedicalPackage);
        var catalog = Catalog();

        int compared = 0, agreed = 0;
        double worst = 0;

        foreach (var export in package.Exports
                     .Where(e => package.GetClassName(e) == TextureReader.ClassName && e.SerialSize > 0)
                     .Take(120))
        {
            var plain = TextureReader.Read(package, export);
            var full = TextureReader.Read(package, export, catalog);
            if (plain is null || full is null) continue;
            if (full.Mips.Count == plain.Mips.Count) continue;

            // The last level recovered sits directly above the first the package had. Halve it and
            // it should be that one — which is the check the sizes alone cannot give: a wrong offset
            // into eight gigabytes can still be the right number of bytes.
            var above = full.Mips[full.Mips.Count - plain.Mips.Count - 1];
            var below = plain.Mips[0];
            if (above.Width != below.Width * 2) continue;

            double error = SeamError(full.Format, above, below);
            compared++;
            worst = Math.Max(worst, error);
            if (error < 0.10) agreed++;
        }

        Assert.True(compared > 40, $"only {compared} textures were recovered to compare");
        Assert.True(agreed >= compared - 2, $"only {agreed} of {compared} matched at the seam (worst {worst:P1})");
    }

    /// <summary>Mean absolute channel difference between a mip halved and the mip below it.</summary>
    private static double SeamError(BioShockTextureFormat format, TextureMip above, TextureMip below)
    {
        byte[] a = BlockCompression.Decode(format, above.Data, above.Width, above.Height);
        byte[] b = BlockCompression.Decode(format, below.Data, below.Width, below.Height);

        double total = 0;
        int count = 0;

        for (int y = 0; y < below.Height; y++)
        {
            for (int x = 0; x < below.Width; x++)
            {
                for (int c = 0; c < 3; c++)
                {
                    int sum = 0;
                    for (int dy = 0; dy < 2; dy++)
                        for (int dx = 0; dx < 2; dx++)
                            sum += a[(((y * 2 + dy) * above.Width) + (x * 2 + dx)) * 4 + c];

                    total += Math.Abs(sum / 4 - b[((y * below.Width) + x) * 4 + c]) / 255.0;
                    count++;
                }
            }
        }

        return count == 0 ? 1 : total / count;
    }

    [RequiresGameFact]
    public void MostOfAPackagesTexturesAreRecovered()
    {
        using var package = BioShockPackage.Open(MedicalPackage);
        var catalog = Catalog();

        int stripped = 0, recovered = 0;

        foreach (var export in package.Exports
                     .Where(e => package.GetClassName(e) == TextureReader.ClassName && e.SerialSize > 0))
        {
            var full = TextureReader.Read(package, export, catalog);
            if (full is null || full.StrippedMipCount == 0) continue;

            stripped++;
            if (full.IsComplete) recovered++;
        }

        // 1-Medical ships 1,539 stripped textures and all but a handful come back.
        Assert.True(stripped > 1400, $"expected most of the package to be stripped, found {stripped}");
        Assert.True(recovered > stripped * 0.98, $"only {recovered} of {stripped} came back");
    }

    [RequiresGameFact]
    public void WithoutTheCatalogueNothingChanges()
    {
        using var package = BioShockPackage.Open(MedicalPackage);
        var export = package.Exports
            .First(e => package.GetClassName(e) == TextureReader.ClassName && e.SerialSize > 0);

        var a = TextureReader.Read(package, export)!;
        var b = TextureReader.Read(package, export, bulk: null)!;

        // The bulk store is an addition, not a dependency: an install without it reads as before.
        Assert.Equal(a.Mips.Count, b.Mips.Count);
        Assert.Equal(a.Width, b.Width);
    }
}
