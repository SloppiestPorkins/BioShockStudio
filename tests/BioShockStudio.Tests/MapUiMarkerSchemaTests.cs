using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class MapUiMarkerSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalMapLayerAndScaleMarkersAreComplete()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var layers = context.Actors.Where(actor => actor.Source.ClassName == "MapUILayerMarker").ToList();

        Assert.Equal(3, layers.Count);
        Assert.All(layers, actor => Assert.True(actor.MapUiMarker is { Complete: true, RegionNames.Count: > 0 }));
        Assert.Equal(new[] { 1, 15, 24 }, layers.Select(actor => actor.MapUiMarker!.RegionNames.Count).Order().ToArray());
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(3, coverage.Classes.Sum(row => row.StatusCounts.GetValueOrDefault(LevelActorCoverage.MapMarkerPending)));
        Assert.Equal(3, coverage.Classes.Sum(row => row.ClassName == "MapUILayerScaleMarker"
            ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.MarkerPending) : 0));

        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.MapUiMarker is not null).ToList();
        Assert.Equal(layers.Count, exported.Count);
        Assert.All(exported, actor => Assert.True(actor.MapUiMarker!.Complete));
    }
}
