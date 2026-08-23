using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class VendingActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalVendingStationExportsItsInteractionDeclaration()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actors = context.Actors.Where(actor => actor.Source.ClassName == "PlaceableVendingStation").ToList();

        Assert.Equal(3, actors.Count);
        Assert.All(actors, actor => Assert.True(actor.Vending is { Complete: true }, actor.Source.ToString()));
        Assert.Equal(1, actors.Count(actor => actor.Vending!.CanBeHacked is not null));
        Assert.All(actors, actor => Assert.NotNull(actor.Vending!.DestructionNotification));

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(3, coverage.Classes.Sum(row => row.ClassName == "PlaceableVendingStation"
            ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.InteractionPending) : 0));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.Vending is not null).ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.True(actor.Vending!.Complete));
    }
}
