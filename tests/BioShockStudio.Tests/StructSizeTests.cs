using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A struct property's declared size omits the size-encoding bytes of its own nested properties.
/// </summary>
/// <remarks>
/// This was the last place the tagged-property walk lost alignment. A nested property carrying an
/// explicit size costs 1, 2 or 4 bytes the declared size does not count, so the outer walk advanced
/// that many bytes too few, landed inside the next property's name, and stopped — which is why about
/// half the shaders in the larger packages decoded partially.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class StructSizeTests(GameFixture game)
{
    private BioShockPackage Map(string name) => BioShockPackage.Open(
        name == "ShockGame"
            ? Core.Game.GameLocator.WeaponPackage(game.RequireRoot)!
            : Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm"));

    private BioShockMaterial Read(string map, string shader)
    {
        using var package = Map(map);
        var export = package.Exports
            .Where(e => string.Equals(e.ObjectName, shader, StringComparison.OrdinalIgnoreCase)
                        && MaterialReader.IsMaterialClass(package.GetClassName(e)))
            .MaxBy(e => e.SerialSize);
        Assert.True(export is not null, $"{shader} is not in {map}");

        var material = MaterialReader.Read(package, export!);
        Assert.True(material is not null, $"{shader} did not decode");
        return material!;
    }

    /// <summary>
    /// The two shaders the rule was read off, one on each side of it.
    /// </summary>
    /// <remarks>
    /// <c>PistolShader</c>'s <c>SpecularMask</c> declares 20 and contains 20: its nested
    /// <c>Material</c> is a null object with an implicit size, so there is no size byte to lose.
    /// <c>Resurrection_Shader</c>'s <c>Opacity</c> declares 22 and contains 23: its nested
    /// <c>Material</c> carries an explicit size byte. Both must now walk to the end.
    /// </remarks>
    [RequiresGameFact]
    public void BothSidesOfTheStructSizeRuleDecodeCompletely()
    {
        var pistol = Read("ShockGame", "PistolShader");
        Assert.False(pistol.Truncated, "PistolShader has no uncounted size byte and never truncated");
        Assert.Equal("Pistol_DIFF", pistol.DiffuseTexture);
        Assert.Equal("Pistol_NORM", pistol.NormalTexture);

        // This one is the case that used to stop at its first MaskMaterial.
        var resurrection = Read("1-Medical", "Resurrection_Shader");
        Assert.False(resurrection.Truncated,
            "Resurrection_Shader's Opacity declares 22 bytes for 23 and used to truncate the walk");

        // Properties after the struct are the ones that used to be lost entirely.
        Assert.NotEmpty(resurrection.Textures);
    }

    /// <summary>
    /// Game-wide: every material decodes to its terminator.
    /// </summary>
    /// <remarks>
    /// Before this fix 432 of <c>1-Medical</c>'s 819 materials were partial. The check is not
    /// vacuous — it reads every material in every shipped package, and a single reintroduced
    /// off-by-one puts thousands of them back.
    /// </remarks>
    [RequiresGameFact]
    public void EveryMaterialInTheGameDecodesCompletely()
    {
        int total = 0, truncated = 0;
        var examples = new List<string>();

        var files = Core.Game.GameLocator.EnumeratePackages(game.RequireRoot).ToList();
        if (Core.Game.GameLocator.WeaponPackage(game.RequireRoot) is { } weapons) files.Add(weapons);

        foreach (string file in files)
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports)
            {
                if (!MaterialReader.IsMaterialClass(package.GetClassName(export)) || export.SerialSize <= 0)
                    continue;

                BioShockMaterial? material;
                try { material = MaterialReader.Read(package, export); }
                catch { continue; }
                if (material is null) continue;

                total++;
                if (!material.Truncated) continue;

                truncated++;
                if (examples.Count < 10)
                    examples.Add($"{Path.GetFileNameWithoutExtension(file)}/{export.ObjectName}");
            }
        }

        Assert.True(total > 13_000, $"only {total} materials read — the sweep is not covering the game");
        Assert.True(truncated == 0, $"{truncated} of {total} materials are still partial: {string.Join(", ", examples)}");
    }

    /// <summary>
    /// The correction must not invent property names, which is what a misaligned walk produces.
    /// </summary>
    /// <remarks>
    /// Extending a struct by the wrong amount would resume the outer walk mid-property and read
    /// plausible-looking rubbish. Every name a material reports has to be a real name from the
    /// package's own table.
    /// </remarks>
    [RequiresGameFact]
    public void NoMaterialReportsAnInventedPropertyName()
    {
        using var package = Map("1-Medical");
        var known = package.Names.Select(n => n.Name).ToHashSet(StringComparer.Ordinal);

        int checkedCount = 0;

        foreach (var export in package.Exports)
        {
            if (!MaterialReader.IsMaterialClass(package.GetClassName(export)) || export.SerialSize <= 0) continue;

            BioShockMaterial? material;
            try { material = MaterialReader.Read(package, export); }
            catch { continue; }
            if (material is null) continue;

            checkedCount++;

            foreach (string property in material.UnhandledProperties)
            {
                // A numbered FName renders as its base name plus a number; the base must be real.
                string bare = property.TrimEnd("0123456789".ToCharArray());
                Assert.True(known.Contains(property) || known.Contains(bare),
                    $"{export.ObjectName} reports property '{property}', which is not in the name table");
            }

            foreach (var texture in material.Textures)
                Assert.True(known.Contains(texture.Slot) || known.Contains(texture.Slot.TrimEnd("0123456789".ToCharArray())),
                    $"{export.ObjectName} binds a texture to invented slot '{texture.Slot}'");
        }

        Assert.True(checkedCount > 500, $"only {checkedCount} materials checked");
    }
}
