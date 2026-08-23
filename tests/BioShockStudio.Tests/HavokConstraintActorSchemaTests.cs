using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class HavokConstraintActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalHavokConstraintExportsItsActorLinksAndHingeSettings()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actors = context.Actors.Where(actor => actor.HavokConstraint is not null).ToList();

        Assert.Equal(6, actors.Count);
        Assert.All(actors, actor => Assert.True(actor.HavokConstraint!.Complete, actor.Source.ToString()));
        Assert.Equal(3, actors.Count(actor => actor.HavokConstraint!.AttachedActorB is not null));
        Assert.Equal(3, actors.Count(actor => actor.HavokConstraint!.LimitedHingeFrictionValue is not null));
        Assert.Equal(2, actors.Count(actor => actor.HavokConstraint!.UseLimitedHinge is not null));

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(6, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.PhysicsConstraintPending)));
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.HavokConstraint is not null).ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.True(actor.HavokConstraint!.Complete));
    }
}
