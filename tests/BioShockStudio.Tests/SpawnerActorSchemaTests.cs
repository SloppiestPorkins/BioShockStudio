using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SpawnerActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalAggressorSpawnerHasACompleteTypedPopulationDeclaration()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actors = context.Actors.Where(actor => actor.Source.ClassName == "AggressorSpawner").ToList();

        Assert.Equal(19, actors.Count);
        Assert.All(actors, actor =>
        {
            Assert.NotNull(actor.Spawner);
            Assert.True(actor.Spawner.Complete, actor.Source.ToString());
            Assert.NotEmpty(actor.Spawner.SpawnZones);
            Assert.True(actor.Spawner.GlobalAiTypes.Count + actor.Spawner.InitialAiTypes.Count
                        + actor.Spawner.RepopulationAiTypes.Count > 0, actor.Source.ToString());
        });

        var coverage = LevelCoverageReport.Build(context);
        // Four ProtectorSpawner actors share the same byte-backed population schema.
        Assert.Equal(23, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.SpawnerPending)));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.ClassName == "AggressorSpawner").ToList();
        Assert.Equal(actors.Count, exported.Count);
        Assert.All(exported, actor => Assert.True(actor.Spawner is { Complete: true, SpawnZones.Count: > 0 }));
    }
}
