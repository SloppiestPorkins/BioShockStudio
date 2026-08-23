using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ShockAiScoutActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalSavedScoutRuntimeStateIsTypedAndLeavesNoUnclassifiedActors()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actor = Assert.Single(context.Actors, actor => actor.Source.ClassName == "ShockAIScout");

        Assert.True(actor.ShockAiScout is { Complete: true });
        Assert.Equal(new[] { 0 }, actor.ShockAiScout.PointCollectionReferences);
        Assert.NotNull(actor.ShockAiScout.LastPathfindingOrigin);
        Assert.NotNull(actor.ShockAiScout.LastPathfindingLocation);
        Assert.NotNull(actor.ShockAiScout.CollisionRadius);
        Assert.NotNull(actor.ShockAiScout.CollisionHeight);

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(1, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.RuntimeStatePending)));
        Assert.Equal(0, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.Unclassified)));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = Assert.Single(document.Actors, item => item.ClassName == "ShockAIScout").ShockAiScout;
        Assert.True(exported is { Complete: true });
        Assert.Equal(actor.ShockAiScout.PointCollectionReferences, exported.PointCollectionReferences);
    }
}
