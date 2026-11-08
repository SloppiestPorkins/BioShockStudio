using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class HavokForceActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalHavokForceHasTypedObjectReferences()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actors = context.Actors.Where(actor => actor.Source.ClassName == "HavokForceActor").ToList();

        // 1-Medical ships 14 HavokForceActor exports. This pinned 12 until 4 Oct 2026: two actors'
        // property lists misaligned on a struct array the reader under-sized (ArraySizeTests).
        Assert.Equal(14, actors.Count);
        Assert.All(actors, actor => Assert.True(actor.HavokForce is { Complete: true }, actor.Source.ToString()));
        Assert.Equal(9, actors.Count(actor => actor.HavokForce!.ForceFilter is not null));
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(14, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.PhysicsForcePending)));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.HavokForce is not null).ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.True(actor.HavokForce!.Complete));
    }
}
