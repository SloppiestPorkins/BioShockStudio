using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class CoverageBoundaryActorTests(GameFixture game)
{
    [RequiresGameFact]
    public void EmptyPathAndScriptInstancesRetainTheirClassTranslationCategory()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var report = LevelCoverageReport.Build(LevelAnalyzer.Analyze(package));

        var paths = Assert.Single(report.Classes, row => row.ClassName == "PathNode");
        Assert.Equal(495, paths.StatusCounts.GetValueOrDefault(LevelActorCoverage.NavigationPending));
        Assert.Equal(0, paths.StatusCounts.GetValueOrDefault(LevelActorCoverage.Unclassified));

        var scripts = Assert.Single(report.Classes, row => row.ClassName == "Script");
        Assert.Equal(300, scripts.StatusCounts.GetValueOrDefault(LevelActorCoverage.ScriptPending));
        Assert.Equal(0, scripts.StatusCounts.GetValueOrDefault(LevelActorCoverage.Unclassified));
    }
}
