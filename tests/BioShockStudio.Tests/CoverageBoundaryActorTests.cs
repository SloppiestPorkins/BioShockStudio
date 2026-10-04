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
        // 504 PathNode and 308 Script exports ship in 1-Medical (`inspect 1-Medical <class>`). These
        // pinned 495 / 300 until 4 Oct 2026, when the struct-array size fix (ArraySizeTests) let the
        // analyzer read the 9 path nodes and 8 scripts whose property lists used to misalign.
        Assert.Equal(504, paths.StatusCounts.GetValueOrDefault(LevelActorCoverage.NavigationPending));
        Assert.Equal(0, paths.StatusCounts.GetValueOrDefault(LevelActorCoverage.Unclassified));

        var scripts = Assert.Single(report.Classes, row => row.ClassName == "Script");
        Assert.Equal(308, scripts.StatusCounts.GetValueOrDefault(LevelActorCoverage.ScriptPending));
        Assert.Equal(0, scripts.StatusCounts.GetValueOrDefault(LevelActorCoverage.Unclassified));
    }
}
