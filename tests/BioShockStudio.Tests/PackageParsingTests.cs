using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
public sealed class PackageParsingTests(GameFixture game)
{
    [RequiresGameFact]
    public void EntryPackage_HeaderMatchesConfirmedBytes()
    {
        using var package = BioShockPackage.Open(game.EntryPackage);
        var summary = package.Summary;

        Assert.Equal(142, summary.FileVersion);
        Assert.Equal(56, summary.LicenseeVersion);
        Assert.Equal(0x00340001u, summary.PackageFlags);
        Assert.Equal(153, summary.NameCount);
        Assert.Equal(0x31FD, summary.NameOffset);
        Assert.Equal(21, summary.ImportCount);
        Assert.Equal(0x49DE, summary.ImportOffset);
        Assert.Equal(40, summary.ExportCount);
        Assert.Equal(0x4BA7, summary.ExportOffset);
    }

    [RequiresGameFact]
    public void EntryPackage_NameTableEndsExactlyOnImportTable()
    {
        using var package = BioShockPackage.Open(game.EntryPackage);

        // The name table has no length field: landing precisely on the import table is the proof
        // that the per-entry layout (FCompactIndex length, UTF-16LE text, uint64 flags) is correct.
        Assert.Equal("None", package.Names[0].Name);
        Assert.Equal("AIClassName", package.Names[1].Name);
        Assert.Equal("Core", package.Names[148].Name);
    }

    [RequiresGameFact]
    public void EntryPackage_ImportsDecodeToKnownValues()
    {
        using var package = BioShockPackage.Open(game.EntryPackage);

        Assert.Equal("Core", package.Imports[0].ClassPackage);
        Assert.Equal("Package", package.Imports[0].ClassName);
        Assert.Equal("Engine", package.Imports[0].ObjectName);

        Assert.Equal("Polys", package.Imports[6].ObjectName);
        Assert.Equal("Texture", package.Imports[17].ObjectName);
    }

    [RequiresGameFact]
    public void EntryPackage_ExportsDecodeToKnownValues()
    {
        using var package = BioShockPackage.Open(game.EntryPackage);

        var first = package.Exports[0];
        Assert.Equal("Polys11", first.ObjectName);
        Assert.Equal("Polys", package.GetClassName(first));
        Assert.Equal(41, first.SerialSize);
        Assert.Equal(64, first.SerialOffset);

        var second = package.Exports[1];
        Assert.Equal(725, second.SerialSize);
        Assert.Equal(105, second.SerialOffset);

        Assert.Equal("BlackTexture", package.Exports[6].ObjectName);
        Assert.Equal("Texture", package.GetClassName(package.Exports[6]));
    }

    [RequiresGameFact]
    public void EntryPackage_ExportPayloadsChainContiguouslyFromHeaderEnd()
    {
        using var package = BioShockPackage.Open(game.EntryPackage);

        // Export payloads are laid out back to back starting at offset 64. Any layout error in the
        // export record would break this chain immediately.
        int expected = 64;
        foreach (var export in package.Exports.Where(e => e.SerialSize > 0))
        {
            Assert.Equal(expected, export.SerialOffset);
            expected += export.SerialSize;
        }
    }

    [RequiresGameFact]
    public void AllShippedPackages_ParseToExactFileLength()
    {
        var failures = new List<string>();

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            try
            {
                using var package = BioShockPackage.Open(file);
                long length = new FileInfo(file).Length;
                if (package.ExportTableEnd != length)
                {
                    failures.Add($"{Path.GetFileName(file)}: table ended at {package.ExportTableEnd}, file is {length}");
                }
            }
            catch (Exception ex)
            {
                failures.Add($"{Path.GetFileName(file)}: {ex.Message}");
            }
        }

        Assert.Empty(failures);
    }

    [RequiresGameFact]
    public void AllShippedPackages_ExportPayloadsStayInsideTheFile()
    {
        var failures = new List<string>();

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            long length = new FileInfo(file).Length;

            foreach (var export in package.Exports)
            {
                if (export.SerialSize == 0) continue;
                if (export.SerialOffset < 64 || export.SerialOffset + (long)export.SerialSize > length)
                    failures.Add($"{Path.GetFileName(file)}: {export.ObjectName} at {export.SerialOffset}+{export.SerialSize}");
            }
        }

        Assert.Empty(failures);
    }

    [RequiresGameFact]
    public void Lighthouse_ContainsTheFirstPersonTargetAssets()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var byClass = package.Exports
            .Select(e => (Class: package.GetClassName(e), e.ObjectName))
            .ToList();

        // The definition-of-done assets: first-person hands mesh and its animation package.
        Assert.Contains(byClass, x => x is { Class: AssetClasses.SkeletalMesh, ObjectName: "NEWPlayerHands" });
        Assert.Contains(byClass, x => x is { Class: AssetClasses.AnimationPackageWrapper, ObjectName: "UAPW_NEWPlayerHands" });

        // Pistol animation metadata, which the binding resolver will eventually key off.
        foreach (string animation in new[] { "EquipPistol", "FireSinglePistol", "FastReloadPistol", "UnequipPistol" })
        {
            Assert.Contains(byClass, x =>
                x.Class == AssetClasses.SharedSkeletonAnimationMetadata &&
                x.ObjectName == $"USharedSkeletonAnimationMetadata_{animation}");
        }
    }
}
