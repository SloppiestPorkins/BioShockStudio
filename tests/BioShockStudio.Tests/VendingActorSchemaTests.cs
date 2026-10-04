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
        var actors = context.Actors.Where(actor =>
            actor.Source.ClassName is "PlaceableVendingStation" or "PlaceableVendingStationAlt").ToList();

        // 1-Medical ships 4 PlaceableVendingStation + 1 PlaceableVendingStationAlt. The station count
        // pinned 3 until 4 Oct 2026 (struct-array size fix, ArraySizeTests); Alt was unclassified
        // until the same day because Vending() only matched the base class name.
        Assert.Equal(5, actors.Count);
        Assert.All(actors, actor => Assert.True(actor.Vending is { Complete: true }, actor.Source.ToString()));
        Assert.Equal(1, actors.Count(actor => actor.Vending!.CanBeHacked is not null));
        Assert.All(actors, actor => Assert.NotNull(actor.Vending!.DestructionNotification));

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(5, coverage.Classes.Sum(row =>
            row.ClassName is "PlaceableVendingStation" or "PlaceableVendingStationAlt"
                ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.InteractionPending) : 0));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.Vending is not null).ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.True(actor.Vending!.Complete));
    }
}
