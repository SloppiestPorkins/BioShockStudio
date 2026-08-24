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

        // Both names resolve — to Script actors, not the mover-labelled doors their names suggest.
        Assert.Equal(
            new List<MoverTriggerTarget>
            {
                new() { Name = "MeatLockerDoorScript", Resolved = true, TargetExportIndex = 9434, TargetClassName = "Script" },
                new() { Name = "MeatLockerOn", Resolved = true, TargetExportIndex = 4821, TargetClassName = "Script" },
            },
            meatLockerDoor.Mover.ResolvedTriggers.ToList());

        var turretTrapTop = movers.Single(actor => actor.Source.ExportIndex == 11267);
        Assert.Equal("TurretTrapTop", turretTrapTop.Label);
        Assert.Equal("SteinmanIntro,TurretControlSwitchScript", turretTrapTop.Mover!.TriggeredBy);
        Assert.Equal(0.3f, turretTrapTop.Mover.MoveTime);
        Assert.Equal(new UnrealRotator(0, 16384, 0), turretTrapTop.Mover.BaseRot);

        // One name resolves, one doesn't — a real example of the 15/103 that read as UnrealScript
        // state/event names rather than object references (docs/research/interaction.md §2).
        Assert.Equal(
            new List<MoverTriggerTarget>
            {
                new() { Name = "SteinmanIntro", Resolved = true, TargetExportIndex = 4173, TargetClassName = "Script" },
                new() { Name = "TurretControlSwitchScript", Resolved = false },
            },
            turretTrapTop.Mover.ResolvedTriggers.ToList());

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

        var script = Assert.Single(exported.ResolvedTriggers, t => t.Name == "MeatLockerDoorScript");
        Assert.True(script.Resolved);
        Assert.Equal(9434, script.TargetExportIndex);
        Assert.Equal("Script", script.TargetClassName);
    }

    [RequiresGameFact]
    public void NoTriggeredByNameEverMatchesMoreThanOneActorsLabel()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);

        // Label is otherwise far from unique in this game — auto-numbered names like "Light3"
        // repeat hundreds of times per package (docs/research/interaction.md). This regresses the
        // one property the resolver depends on: every name it does resolve names exactly one actor,
        // never an arbitrary pick among several.
        var names = context.Actors
            .Where(actor => actor.Mover?.TriggeredBy is not null)
            .SelectMany(actor => actor.Mover!.ResolvedTriggers)
            .Where(target => target.Resolved)
            .Select(target => target.Name)
            .ToList();

        Assert.NotEmpty(names);
        Assert.All(names, name => Assert.Single(context.Actors, actor => actor.Label == name));
    }
}
