using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Proves the Medical effect category is already a complete typed template graph.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class EffectActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalEffectActorReachesTheManifestWithCompleteTemplates()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var effects = context.Actors.Where(actor => actor.Emitters is not null).ToList();

        Assert.Equal(142, effects.Count);
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(134, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.EffectPending)));
        Assert.All(effects, actor =>
        {
            Assert.True(actor.Emitters!.Complete, actor.Source.ToString());
            Assert.NotEmpty(actor.Emitters.Templates);
            Assert.All(actor.Emitters.Templates, template =>
            {
                Assert.NotEqual(0, template.Source.Index.Value);
                Assert.True(template.PropertiesComplete, template.Source.ToString());
            });
        });

        var scene = LevelSceneBuilder.Build(package, context);
        var document = LevelSceneExporter.ToDocument(scene, includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.Emitters is not null).ToList();
        Assert.Equal(effects.Count, exported.Count);
        Assert.All(exported, actor =>
        {
            Assert.True(actor.Emitters!.Complete);
            Assert.NotEmpty(actor.Emitters.Templates);
            Assert.All(actor.Emitters.Templates, template => Assert.True(template.PropertiesComplete));
        });
    }
}
