using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Pins <see cref="DoorActorData"/> — the state fields shared by the game's ~50 door classes, gated
/// on field presence rather than an enumerated class name. See docs/research/interaction.md.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class DoorActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalDoorsDecodeTheirPortalLockAndAnimationState()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);

        var solidDoor = context.Actors.Single(actor => actor.Source.ExportIndex == 3438);
        Assert.Equal("MedicalDoors_Solid", solidDoor.Source.ClassName);
        Assert.True(solidDoor.Door is { Complete: true });
        Assert.Equal("Brush118", solidDoor.Door!.Portal?.ObjectName);
        Assert.True(solidDoor.Door.Locked);
        Assert.Equal(0.3f, solidDoor.Door.OpenAnimationRate);
        // Not every field is authored on every door -- these three are genuinely absent here,
        // not a decode failure.
        Assert.Null(solidDoor.Door.InitiallyOpen);
        Assert.Null(solidDoor.Door.CloseAnimationRate);
        Assert.Null(solidDoor.Door.StayOpenDuration);

        var openDoor = context.Actors.Single(actor => actor.Source.ExportIndex == 3447);
        Assert.Equal("MedicalDoors", openDoor.Source.ClassName);
        Assert.True(openDoor.Door!.InitiallyOpen);
        Assert.Null(openDoor.Door.Portal);
        Assert.Null(openDoor.Door.Locked);

        // Every Medical door carries a mesh, so the coverage classifier's geometry precedence wins
        // over DoorPending -- the same precedence EffectPending/MoverPending already document. The
        // typed record is unaffected; only the reporting bucket is.
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(0, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.DoorPending)));
    }

    [RequiresGameFact]
    public void DoorKeypadControlIsNotGivenADoorRecord()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var keypad = Assert.Single(context.Actors, actor => actor.Source.ClassName == "DoorKeypadControl");

        // DoorKeypadControl is a singleton interaction record (InteractionActorData), decoded
        // separately -- it carries none of the door-state fields, confirmed by census rather than
        // assumed from the class name containing "Door".
        Assert.Null(keypad.Door);
        Assert.NotNull(keypad.Interaction);
    }

    [RequiresGameFact]
    public void TheDoorStateReachesTheLevelSceneExportManifest()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);

        var exported = Assert.Single(document.Actors, actor => actor.ExportIndex == 3438).Door;
        Assert.True(exported is { Complete: true });
        Assert.Equal("Brush118", exported.Portal?.ObjectName);
        Assert.True(exported.Locked);
        Assert.Equal(0.3f, exported.OpenAnimationRate);
    }
}
