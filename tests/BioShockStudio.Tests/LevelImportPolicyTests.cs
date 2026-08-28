using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The UE5 level importer must match the studio viewer's default draw policy: compiled world and
/// mesh props only, not CSG source brushes. Gameplay volumes are placed as invisible UE5 volume
/// actors separately — see `tools/ue5/import_level.py` `_import_region_volumes`.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class LevelImportPolicyTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalKeepsCompiledWorldSeparateFromNonDrawableBrushInstances()
    {
        using var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));

        var built = scene.Instances.Where(i => i.Kind == LevelGeometryKind.BuiltWorld).ToList();
        var brushes = scene.Instances.Where(i => i.Kind == LevelGeometryKind.Brush).ToList();

        Assert.Single(built);
        Assert.True(built[0].Geometry.TriangleCount > 10_000,
            "the compiled world should carry the map's walkable architecture");
        Assert.True(brushes.Count > 800,
            $"expected hundreds of CSG source brushes, got {brushes.Count}");

        var filter = new LevelViewFilter();
        foreach (var instance in brushes)
        {
            var item = new ViewportItem(
                null!, instance.Transform, System.Numerics.Vector3.Zero, 1)
            {
                Kind = instance.Kind,
                ActorClass = instance.Actor.ClassName,
            };
            Assert.False(filter.Accepts(item),
                $"{instance.Actor.ClassName} brush instance should be hidden by default");
        }
    }

    [RequiresGameFact]
    public void MedicalExportsBrushBackedVolumesForUe5Placement()
    {
        using var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));

        int volumes = scene.Instances.Count(instance =>
            instance.Kind == LevelGeometryKind.Brush
            && (instance.Actor.ClassName.EndsWith("Volume", StringComparison.Ordinal)
                || instance.Actor.ClassName.EndsWith("Trigger", StringComparison.Ordinal)));

        Assert.InRange(volumes, 150, 250);
    }

    [RequiresGameFact]
    public void MedicalDeadBodiesReferenceSkeletalMeshes()
    {
        using var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));

        var deadBodies = scene.Actors.Where(actor =>
                actor.Source.ClassName is "DeadBodyContainer"
                    or "KeyframedDeadBodyContainer"
                    or "CorpseMaleBooty")
            .ToList();

        Assert.InRange(deadBodies.Count, 15, 30);
        Assert.All(deadBodies, actor =>
            Assert.Equal(ResolutionStatus.Resolved, actor.SkeletalMesh?.Status));
    }
}
