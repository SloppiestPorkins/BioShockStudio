using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelInfoActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalLevelInfoExportsItsCompleteWorldSettingsGraph()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var actor = Assert.Single(context.Actors, actor => actor.Source.ClassName == "LevelInfo");

        Assert.True(actor.LevelInfo is { Complete: true });
        Assert.Equal(974, actor.LevelInfo.NavigationPoints.Count);
        Assert.Equal(4, actor.LevelInfo.PressureRegions.Count);
        Assert.Equal(44, actor.LevelInfo.MapUiRegions.Count);
        Assert.Equal(11, actor.LevelInfo.MapHudRegions.Count);
        Assert.Equal(2, actor.LevelInfo.RequiredAnimationGroups.Count);
        Assert.All(actor.LevelInfo.NavigationPoints, reference => Assert.NotEqual(ResolutionStatus.Failed, reference.Status));

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(1, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.WorldSettingsPending)));
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = Assert.Single(document.Actors, item => item.ClassName == "LevelInfo").LevelInfo;
        Assert.True(exported is { Complete: true });
        Assert.Equal(actor.LevelInfo.NavigationPoints.Count, exported.NavigationPoints.Count);
        Assert.Equal(actor.LevelInfo.MapUiRegions.Count, exported.MapUiRegions.Count);
    }
}
