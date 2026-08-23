using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class TrainingScriptActorTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalTrainingConceptArraysDecodeExactlyAndReachTheManifest()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var scripts = context.Actors.Where(actor => actor.Source.ClassName == "TrainingScript").ToList();

        Assert.Equal(26, scripts.Count);
        Assert.All(scripts, actor => Assert.NotEmpty(actor.TrainingConcepts));
        Assert.All(scripts.SelectMany(actor => actor.TrainingConcepts), concept =>
            Assert.False(string.IsNullOrWhiteSpace(concept)));

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(325, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.ScriptPending)));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.ClassName == "TrainingScript").ToList();
        Assert.Equal(scripts.Select(actor => actor.TrainingConcepts), exported.Select(actor => actor.TrainingConcepts));
    }
}
