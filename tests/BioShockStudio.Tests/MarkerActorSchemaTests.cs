using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Proves Medical's plain markers contain no hidden class-specific schema.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class MarkerActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalMarkerIsOnlyAPlacedCommonActorRecord()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var markers = context.Actors.Where(actor => actor.Source.ClassName == "Marker").ToList();

        Assert.Equal(150, markers.Count);

        var coverage = LevelCoverageReport.Build(context);
        var markerRow = Assert.Single(coverage.Classes, row => row.ClassName == "Marker");
        Assert.Equal(new[] { "CheckpointTypePadding", "Level", "PhysicsVolume" }, markerRow.OutstandingProperties);
        Assert.Equal(150, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.MarkerPending)));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.ClassName == "Marker").ToList();
        Assert.Equal(markers.Count, exported.Count);
        Assert.All(exported, marker =>
        {
            Assert.Equal(3, marker.Location.Length);
            Assert.NotNull(marker.Region);
        });
    }

    [RequiresGameFact]
    public void TrainingMarkersAlsoContainOnlyTheCommonActorRecord()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var markers = context.Actors.Where(actor => actor.Source.ClassName == "TrainingMarker").ToList();

        Assert.Equal(6, markers.Count);
        var row = Assert.Single(LevelCoverageReport.Build(context).Classes, item => item.ClassName == "TrainingMarker");
        Assert.Equal(new[] { "CheckpointTypePadding", "ColLocation", "Level", "PhysicsVolume", "Touching" },
            row.OutstandingProperties);
        Assert.Equal(6, row.StatusCounts.GetValueOrDefault(LevelActorCoverage.MarkerPending));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        Assert.Equal(markers.Count, document.Actors.Count(actor => actor.ClassName == "TrainingMarker"));
    }
}
