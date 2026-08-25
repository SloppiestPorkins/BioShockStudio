using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Pins <see cref="ScriptedSequenceActorData"/> — chained animation clips on placed actors, not a
/// door field. See docs/research/interaction.md §5.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ScriptedSequenceActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalDoorBuckleDecodesItsBentClip()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var buckle = context.Actors.Single(actor => actor.Source.ObjectName == "Wel_BHDoorBuckle0");

        Assert.Equal("Wel_BHDoorBuckle", buckle.Source.ClassName);
        Assert.True(buckle.ScriptedSequence is { Complete: true, Entries.Count: 1 });
        var entry = buckle.ScriptedSequence!.Entries[0];
        var choice = Assert.Single(entry.Animations);
        Assert.Equal("BHBuckle_Bent", choice.Animation);
        Assert.Equal(1, choice.Chance);
        Assert.Equal(new FloatRange(3f, 3f), entry.LoopCount);
        Assert.Equal(0, entry.RunNext);
        Assert.Equal(0, entry.TotalChance);
        Assert.Null(buckle.Door);
    }

    [RequiresGameFact]
    public void EveryMedicalScriptedSequenceIsCompleteAndAtLeastTwoClassesCarryIt()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var sequenced = context.Actors.Where(actor => actor.ScriptedSequence is not null).ToList();

        Assert.True(sequenced.Count >= 2, "Medical held fewer than two ScriptedSequence actors");
        Assert.All(sequenced, actor => Assert.True(actor.ScriptedSequence!.Complete));
        Assert.All(sequenced, actor => Assert.All(actor.ScriptedSequence!.Entries,
            entry => Assert.NotEmpty(entry.Animations)));
        Assert.True(sequenced.Select(actor => actor.Source.ClassName).Distinct().Count() >= 2,
            "only one class on Medical carried ScriptedSequence — need a second sample");
    }

    [RequiresGameFact]
    public void TheSequenceReachesTheLevelSceneExportManifest()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);

        var exported = Assert.Single(document.Actors, actor => actor.Name == "Wel_BHDoorBuckle0").ScriptedSequence;
        Assert.True(exported is { Complete: true, Entries.Count: 1 });
        Assert.Equal("BHBuckle_Bent", Assert.Single(exported.Entries[0].Animations).Animation);
        Assert.Equal(new[] { 3f, 3f }, exported.Entries[0].LoopCount);
    }
}
