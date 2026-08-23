using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ProjectorActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalProjectorHasACompleteManifestSchema()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actors = context.Actors.Where(actor => actor.Projector is not null).ToList();

        Assert.Equal(21, actors.Count);
        Assert.All(actors, actor => Assert.True(actor.Projector!.Complete, actor.Source.ToString()));
        Assert.Equal(8, actors.Count(actor => actor.Projector!.AngleGradient is not null));

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(21, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.ProjectorPending)));
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.Projector is not null).ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.True(actor.Projector!.Complete));
    }
}
