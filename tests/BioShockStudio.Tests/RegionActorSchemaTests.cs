using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Pins the real tagged-property vocabulary of Medical's region and volume actors.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class RegionActorSchemaTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void MedicalRegionActorsExposeTheirSerializedSchema()
    {
        var actors = LevelAnalyzer.Analyze(game.MedicalPackage).Actors
            .Where(IsRegionActor)
            .ToList();

        // 1-Medical's Volume/Trigger/Zone export set is 274 actors (RegionPending in level-audit).
        // This pinned 253 until 4 Oct 2026: twenty-one region actors' property lists misaligned on
        // a struct array the reader under-sized (ArraySizeTests).
        Assert.Equal(274, actors.Count);
        Assert.All(actors, actor =>
        {
            Assert.NotNull(actor.Region);
            Assert.NotNull(actor.RegionActor);
            Assert.True(actor.RegionActor.Complete, actor.Source.ToString());
        });

        var triggers = actors.Where(actor => actor.Source.ClassName == "TriggerVolume").ToList();
        Assert.Equal(87, triggers.Count);
        Assert.Equal(77, triggers.Count(actor => actor.RegionActor!.TriggerOnlyByLabels.Count > 0));
        Assert.Equal(64, triggers.Count(actor => actor.RegionActor!.TriggerOnlyOnce is not null));
        Assert.Equal(26, triggers.Count(actor => actor.RegionActor!.Disabled is not null));
        Assert.Equal(8, triggers.Count(actor => actor.RegionActor!.TriggerOnlyByClasses.Count > 0));
        Assert.Single(triggers.Where(actor => actor.RegionActor!.TriggeredBy is not null));

        var blocking = actors.Where(actor => actor.Source.ClassName == "BlockingVolume").ToList();
        Assert.Equal(57, blocking.Count);
        Assert.Equal(14, blocking.Count(actor => actor.RegionActor!.BlockActors is not null));
        Assert.Equal(13, blocking.Count(actor => actor.RegionActor!.BlockHavok is not null));
        Assert.Equal(11, blocking.Count(actor => actor.RegionActor!.BlockPlayers is not null));

        var zones = actors.Where(actor => actor.Source.ClassName == "ZoneInfo").ToList();
        Assert.Equal(74, zones.Count);
        Assert.All(zones, actor => Assert.NotNull(actor.RegionActor!.Zone?.CurrentAmbient));
        Assert.Equal(71, zones.Count(actor => actor.RegionActor!.Zone!.ReverbType is not null));
        Assert.Equal(70, zones.Count(actor => actor.RegionActor!.Zone!.SpawnZones.Count > 0));
        Assert.Equal(70, zones.Count(actor => actor.RegionActor!.Zone!.MapUiRegion is not null));
        Assert.Equal(15, zones.Count(actor => actor.RegionActor!.Zone!.CurrentFog is not null));
        Assert.Equal(15, zones.Count(actor => actor.RegionActor!.Zone!.NormalFog is not null));
        Assert.Equal(3, zones.Count(actor => actor.RegionActor!.Zone!.HighFog is not null));
        Assert.Equal(4, zones.Count(actor => actor.RegionActor!.Zone!.ManualExcludes.Count > 0));

        Assert.Equal(176, actors.Count(actor => actor.RegionActor!.MainScale is not null));
        Assert.Equal(176, actors.Count(actor => actor.RegionActor!.PostScale is not null));
        var water = actors.Where(actor => actor.Source.ClassName == "CascadingWaterVolume").ToList();
        Assert.Equal(14, water.Count);
        Assert.All(water, actor => Assert.NotNull(actor.RegionActor!.WaterMesh));
        Assert.Equal(6, water.Count(actor => actor.RegionActor!.WaterAxis is not null));
        var fluid = actors.Where(actor => actor.Source.ClassName == "FluidVolume").ToList();
        Assert.Equal(3, fluid.Count(actor => actor.RegionActor!.MovingInWaterPenalty is not null));
        Assert.Single(fluid.Where(actor => actor.RegionActor!.Enabled is not null));
        var defaultPhysics = Assert.Single(actors.Where(actor => actor.Source.ClassName == "DefaultPhysicsVolume"));
        Assert.NotNull(defaultPhysics.RegionActor!.Priority);
        Assert.NotNull(defaultPhysics.RegionActor.NoDelete);

        // The manifest is the UE5 handoff. A field decoded only in LevelActor is not done.
        using (var package = BioShockPackage.Open(game.MedicalPackage))
        {
            var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));
            var document = LevelSceneExporter.ToDocument(scene, includeGeometry: false);
            Assert.Equal(274, document.Actors.Count(actor => actor.RegionActor is not null));
            Assert.Equal(scene.Actors.Count(actor => actor.Region is not null),
                document.Actors.Count(actor => actor.Region is not null));
            var triggerDocuments = document.Actors
                .Where(actor => actor.ClassName == "TriggerVolume").ToList();
            Assert.Equal(77, triggerDocuments.Count(actor => actor.RegionActor!.TriggerOnlyByLabels.Count > 0));
            Assert.All(triggerDocuments, actor => Assert.True(actor.RegionActor!.Complete));
            var zoneDocuments = document.Actors.Where(actor => actor.ClassName == "ZoneInfo").ToList();
            Assert.Equal(74, zoneDocuments.Count);
            Assert.All(zoneDocuments, actor => Assert.NotNull(actor.RegionActor!.Zone!.CurrentAmbient));
            Assert.Equal(15, zoneDocuments.Count(actor => actor.RegionActor!.Zone!.CurrentFog is not null));
        }

        foreach (var group in actors.GroupBy(actor => actor.Source.ClassName).OrderByDescending(group => group.Count()))
        {
            Log($"{group.Key}: {group.Count():N0}");
            foreach (var property in group.SelectMany(actor => actor.Properties)
                         .GroupBy(property => (property.Name, property.Type, property.StructName))
                         .OrderByDescending(properties => properties.Count()))
            {
                var example = property.First();
                string value = example.Value.Length <= 16 ? Convert.ToHexString(example.Value) : $"{example.Value.Length} bytes";
                Log($"  {property.Key.Name,-32} {property.Key.Type,-12} {property.Key.StructName,-18} "
                    + $"{property.Count(),4:N0}/{group.Count(),-4:N0} {value}");
            }
        }
    }

    private static bool IsRegionActor(LevelActor actor) =>
        actor.Source.ClassName.EndsWith("Volume", StringComparison.Ordinal)
        || actor.Source.ClassName.Contains("Trigger", StringComparison.Ordinal)
        || actor.Source.ClassName.Contains("Zone", StringComparison.Ordinal);
}
