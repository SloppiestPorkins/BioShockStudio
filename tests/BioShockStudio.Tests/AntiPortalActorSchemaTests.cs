using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class AntiPortalActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalAntiPortalExportsItsResolvedOcclusionReference()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actors = context.Actors.Where(actor => actor.Source.ClassName == "AntiPortalActor").ToList();

        Assert.Equal(3, actors.Count);
        Assert.All(actors, actor => Assert.Equal(ResolutionStatus.Resolved, actor.AntiPortal?.Status));
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(3, coverage.Classes.Sum(row => row.ClassName == "AntiPortalActor"
            ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.VisibilityPending) : 0));
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.ClassName == "AntiPortalActor").ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.Equal(nameof(ResolutionStatus.Resolved), actor.AntiPortal?.Status));
    }
}
