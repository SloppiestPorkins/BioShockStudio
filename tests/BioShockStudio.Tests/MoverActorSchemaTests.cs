using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Pins the typed <see cref="MoverActorData"/> subset — what triggers a <c>Mover</c>/
/// <c>ScriptableMover</c> and its start pose, not its keyframe path (deliberately deferred; see
/// docs/research/interaction.md). Gate 4 item 4's "movers ... once the source object graph backing
/// them is known" — <c>TriggeredBy</c> is that graph, by Script/Tag name.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class MoverActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalScriptableMoverDecodesItsTriggerWiringAndStartPose()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var movers = context.Actors.Where(actor => actor.Source.ClassName == "ScriptableMover").ToList();

        Assert.Equal(8, movers.Count);
        Assert.All(movers, actor => Assert.True(actor.Mover is { Complete: true }));

        var meatLockerDoor = movers.Single(actor => actor.Source.ExportIndex == 10011);
        Assert.Equal("MeatLockerDoor", meatLockerDoor.Label);
        Assert.Equal("TriggerToggle", meatLockerDoor.Mover!.InitialState);
        Assert.Equal("MeatLockerDoorScript, MeatLockerOn", meatLockerDoor.Mover.TriggeredBy);
        Assert.Equal((byte)3, meatLockerDoor.Mover.MoverEncroachType);
        // UE2 serialises only non-default properties — this mover has no MoveTime because it
        // never got one authored, not because the reader failed to find it.
        Assert.Null(meatLockerDoor.Mover.MoveTime);

        var turretTrapTop = movers.Single(actor => actor.Source.ExportIndex == 11267);
        Assert.Equal("TurretTrapTop", turretTrapTop.Label);
        Assert.Equal("SteinmanIntro,TurretControlSwitchScript", turretTrapTop.Mover!.TriggeredBy);
        Assert.Equal(0.3f, turretTrapTop.Mover.MoveTime);
        Assert.Equal(new UnrealRotator(0, 16384, 0), turretTrapTop.Mover.BaseRot);

        // Every ScriptableMover in Medical carries a StaticMesh, so the coverage classifier's
        // geometry precedence wins over MoverPending here — the same precedence EffectPending
        // already documents for emitter-bearing actors. The typed record itself is unaffected;
        // only the reporting bucket is.
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(0, coverage.Classes.Sum(row => row.ClassName == "ScriptableMover"
            ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.MoverPending) : 0));
        Assert.Equal(8, coverage.Classes.Sum(row => row.ClassName == "ScriptableMover"
            ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.GeometryInScene) : 0));
    }

    [RequiresGameFact]
    public void AnUnrelatedMoverNamedClassIsNotGivenAnEmptyMoverRecord()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);
        var fireMover = context.Actors.Single(actor => actor.Source.ClassName == "Int_FireMover");

        Assert.Null(fireMover.Mover);
    }

    [RequiresGameFact]
    public void TheMoverWiringReachesTheLevelSceneExportManifest()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);

        var exported = Assert.Single(document.Actors, actor => actor.ExportIndex == 10011).Mover;
        Assert.True(exported is { Complete: true });
        Assert.Equal("TriggerToggle", exported.InitialState);
        Assert.Equal("MeatLockerDoorScript, MeatLockerOn", exported.TriggeredBy);
        Assert.Equal((byte)3, exported.MoverEncroachType);
    }
}
