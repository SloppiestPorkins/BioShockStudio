using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Whole-game coverage of <c>MaterialSwitch</c> candidate decoding.
/// </summary>
/// <remarks>
/// Separate class because it reads every package: the tier belongs to the class, and
/// <see cref="MaterialSwitchTests"/> is the single-package one.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class MaterialSwitchCoverageTests(GameFixture game)
{
    /// <summary>
    /// Every switch in the game yields its candidates.
    /// </summary>
    /// <remarks>
    /// One package was not enough here: the first cut attached candidates only on the path where
    /// the switch's default child resolves as a shader, and <c>LangScreenSwitch</c> — whose default
    /// is a class this reader does not parse as one — was the single switch in the game reporting
    /// none, while its array decoded perfectly well. 44 of 45 looked like success.
    /// </remarks>
    [RequiresGameFact]
    public void EverySwitchInTheGameYieldsItsCandidates()
    {
        int switches = 0, withCandidates = 0;
        var empty = new List<string>();

        foreach (string file in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports)
            {
                if (package.GetClassName(export) != MaterialSwitchReader.ClassName) continue;

                switches++;
                var material = MaterialReader.Read(package, export);

                if (material is { SwitchCandidates.Count: > 0 }) withCandidates++;
                else empty.Add($"{Path.GetFileNameWithoutExtension(file)}/{export.ObjectName}");
            }
        }

        Assert.True(switches >= 40, $"only {switches} MaterialSwitch exports were found");
        Assert.True(empty.Count == 0,
            "these switches yielded no candidates: " + string.Join(", ", empty.Take(10)));
        Assert.Equal(switches, withCandidates);
    }
}
