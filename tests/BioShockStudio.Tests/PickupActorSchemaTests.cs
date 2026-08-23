using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class PickupActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalHypoPickupExportsItsResolvedLootSlot()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actors = context.Actors.Where(actor => actor.Source.ClassName == "MedHypoPickup").ToList();

        Assert.Equal(11, actors.Count);
        Assert.All(actors, actor => Assert.Equal(ResolutionStatus.Resolved, actor.LootSlot?.Status));
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(11, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.InteractionPending)));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.ClassName == "MedHypoPickup").ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.Equal(nameof(ResolutionStatus.Resolved), actor.LootSlot?.Status));
    }
}
