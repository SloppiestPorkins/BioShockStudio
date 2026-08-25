using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Pins <see cref="DoorActorData"/> (state fields shared by the game's ~50 door classes, gated on
/// field presence) and <see cref="DoorSwitchActorData"/> (interaction-verb fields, gated on the
/// exact class name instead — see its own doc comment for why). See docs/research/interaction.md.
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

    [RequiresGameFact]
    public void MedicalDoorSwitchesDecodeTheirInteractionVerbFields()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var switches = context.Actors.Where(actor => actor.Source.ClassName == "DoorSwitch").ToList();

        // Exactly the DoorSwitch class -- confirmed whole-game that DamageResistanceSetName,
        // UseVerbText and OverlayMaterial are also carried by dozens of unrelated classes
        // (pickups, furniture, other switches), so this is gated on the class name rather than
        // field presence, unlike DoorActorData.
        Assert.Equal(4, switches.Count);
        Assert.All(switches, actor => Assert.True(actor.DoorSwitch is { Complete: true }));

        var breaker = switches.Single(actor => actor.Source.ExportIndex == 13778);
        Assert.Equal("WelcomeCircuitbreakerresistanceset", breaker.DoorSwitch!.DamageResistanceSetName);
        Assert.Equal(string.Empty, breaker.DoorSwitch.UseVerbText);
        Assert.Null(breaker.DoorSwitch.OverlayMaterial);

        // DamagedReactions/UsedReactions: a generic engine reaction-framework struct array, not
        // door-specific -- Reaction names the handler class that actually fires.
        var damaged = Assert.Single(breaker.DoorSwitch.DamagedReactions);
        Assert.Equal("ReactionNotifyScriptingSystem", damaged.Reaction?.ObjectName);
        Assert.False(damaged.OnceOnly);
        Assert.False(damaged.HasStaticMeshes);
        Assert.False(damaged.HasMaterials);

        Assert.Equal(2, breaker.DoorSwitch.UsedReactions.Count);
        Assert.Equal("ReactionNotifyScriptingSystem", breaker.DoorSwitch.UsedReactions[0].Reaction?.ObjectName);
        Assert.Equal("ReactionTriggerEffectEvent", breaker.DoorSwitch.UsedReactions[1].Reaction?.ObjectName);

        var supplyCloset = switches.Single(actor => actor.Source.ExportIndex == 13821);
        Assert.Null(supplyCloset.DoorSwitch!.DamageResistanceSetName);
        Assert.Equal("LogShimmer_Shader", supplyCloset.DoorSwitch.OverlayMaterial?.ObjectName);
    }

    [RequiresGameFact]
    public void NonDoorClassesCarryingTheSameFieldNamesAreNotGivenADoorSwitchRecord()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);

        // BandagesPickup and NonPhysicalReactiveActor both carry DamageResistanceSetName and/or
        // OverlayMaterial in this exact package -- real classes that would have wrongly received a
        // DoorSwitchActorData under a field-presence gate.
        var pickup = Assert.Single(context.Actors, actor => actor.Source.ExportIndex == 8161);
        Assert.Equal("BandagesPickup", pickup.Source.ClassName);
        Assert.Null(pickup.DoorSwitch);

        var reactive = Assert.Single(context.Actors, actor => actor.Source.ExportIndex == 7145);
        Assert.Equal("NonPhysicalReactiveActor", reactive.Source.ClassName);
        Assert.Null(reactive.DoorSwitch);
    }
}
