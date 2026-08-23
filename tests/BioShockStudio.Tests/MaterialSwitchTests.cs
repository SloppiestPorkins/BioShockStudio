using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A <c>MaterialSwitch</c>'s candidate array — Gate 1 item 4's "dynamic candidate selection".
/// </summary>
/// <remarks>
/// <para>
/// The array is an <c>FCompactIndex</c> count followed by that many <c>FCompactIndex</c> object
/// references, consuming its declared size exactly.
/// </para>
/// <para>
/// <b>This settles the candidates, not the selection.</b> Which one a running game picks is
/// <c>UNKNOWN</c> — it is game logic, not package data — so the switch still resolves to its
/// authored default for rendering and export, and the candidate list rides alongside. The
/// candidates are useful on their own: they are the material's full set of states.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class MaterialSwitchTests(GameFixture game)
{
    private static ObjectExport Switch(BioShockPackage package, string name) =>
        package.Exports.Single(e => e.ObjectName == name
                                    && package.GetClassName(e) == MaterialSwitchReader.ClassName);

    [RequiresGameFact]
    public void ASwitchExposesEveryCandidateItCouldSelect()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);

        var material = MaterialReader.Read(package, Switch(package, "Resurrection_Switch"));
        Assert.NotNull(material);

        // Still resolves to the authored default, exactly as before.
        Assert.Equal("Resurrection_Switch", material!.SwitchName);
        Assert.Equal("Resurrection_Shader", material.Name);

        // ...and now carries both states.
        Assert.Equal(2, material.SwitchCandidates.Count);
        Assert.Equal(
            new[] { "Resurrection_Shader", "Resurrection_Shader_NoLights" },
            material.SwitchCandidates.Select(c => c.Name).ToArray());

        Assert.All(material.SwitchCandidates, c => Assert.Equal("Shader", c.ClassName));

        // The default is flagged, and there is exactly one of it.
        Assert.Single(material.SwitchCandidates.Where(c => c.IsDefault));
        Assert.Equal("Resurrection_Shader", material.SwitchCandidates.Single(c => c.IsDefault).Name);
    }

    [RequiresGameFact]
    public void AThreeWaySwitchReadsAllThree()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);

        var material = MaterialReader.Read(package, Switch(package, "SteinmanTVSwitch"));
        Assert.NotNull(material);

        Assert.Equal(
            new[] { "Blink1", "Steinman_TVScreen", "TVStaticNew_Shader" },
            material!.SwitchCandidates.Select(c => c.Name).ToArray());

        // Indices are the array positions, so a consumer can refer to a candidate stably.
        Assert.Equal(new[] { 0, 1, 2 }, material.SwitchCandidates.Select(c => c.Index).ToArray());
    }

    /// <summary>
    /// A material not reached through a switch carries no switch data.
    /// </summary>
    [RequiresGameFact]
    public void AnOrdinaryMaterialHasNoCandidates()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var export = package.Exports.First(e => package.GetClassName(e) == "Shader");
        var material = MaterialReader.Read(package, export);

        Assert.NotNull(material);
        Assert.Null(material!.SwitchName);
        Assert.Empty(material.SwitchCandidates);
    }
}
