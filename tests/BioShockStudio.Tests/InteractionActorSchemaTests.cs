using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class InteractionActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalKeypadAndToolboxInteractionFlagsReachTheManifest()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var keypad = Assert.Single(context.Actors, actor => actor.Source.ClassName == "DoorKeypadControl");
        Assert.False(string.IsNullOrWhiteSpace(keypad.Interaction?.DoorLabel));
        Assert.False(string.IsNullOrWhiteSpace(keypad.Interaction?.HackInfoName));
        Assert.NotNull(keypad.Interaction?.Hackable);
        var toolbox = Assert.Single(context.Actors, actor => actor.Source.ClassName == "dyn_toolbox_open");
        Assert.NotNull(toolbox.Interaction?.ShowHudElements);

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(2, coverage.Classes.Sum(row =>
            row.ClassName is "DoorKeypadControl" or "dyn_toolbox_open"
                ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.InteractionPending) : 0));
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        Assert.NotNull(Assert.Single(document.Actors, actor => actor.ClassName == "DoorKeypadControl").Interaction);
        Assert.NotNull(Assert.Single(document.Actors, actor => actor.ClassName == "dyn_toolbox_open").Interaction);
    }
}
