using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A placed sound actor resolved to the shipped object that carries its sound settings.
/// </summary>
/// <remarks>
/// <para>
/// This is the blocker <c>docs/research/audio.md</c> SS4 recorded: the actors name their audio, but
/// only 7 of 3,247 names hit anything in the level package and matching them against FSB sample
/// names resolved no <c>AmbientSound</c> at all. The missing step was one indirection further out —
/// the <c>AmbientSoundSpawned_&lt;Tag&gt;</c> event response, which names a
/// <c>SoundEffectSpecification</c>.
/// </para>
/// <para>
/// Nothing here is normalised or fuzzily matched. Every match is an exact name.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class SoundActorSpecificationTests(GameFixture game)
{
    private static SoundActorSpecificationResolution Resolve(
        BioShockPackage package, LevelContext context, string objectName)
    {
        var index = SoundActorSpecificationIndex.Build(package);
        var actor = Assert.Single(context.Actors, item => item.Source.ObjectName == objectName);
        return index.Resolve(actor, package);
    }

    /// <summary>
    /// An <c>AmbientSound</c>'s <c>Tag</c> reaches its specification through the spawned event.
    /// </summary>
    [RequiresGameFact]
    public void AnAmbientSoundResolvesThroughItsSpawnedEvent()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);
        var resolution = Resolve(package, context, "AmbientSound2");

        Assert.Equal(SoundActorRoute.SpawnedEvent, resolution.Route);
        Assert.Equal("LighthouseWavelets", resolution.MatchedName);
        var specification = Assert.Single(resolution.Specifications);
        Assert.Equal("ambience_0_wavelets", specification.SoundName);
        Assert.Equal("ambience_0_wavelets", Assert.Single(resolution.SampleNames));
        Assert.Equal("ambience_0_Lighthouse", Assert.Single(specification.SoundSpecs).SoundUnit);
    }

    /// <summary>
    /// The resolved specification is where that actor's variation lives.
    /// </summary>
    /// <remarks>
    /// The actor itself carries a tag and nothing else. Its specification offers five takes of the
    /// same light buzz, in a unit named for a different level — which is why the sample name cannot
    /// be derived from the actor's own name and has to be read.
    /// </remarks>
    [RequiresGameFact]
    public void TheResolvedSpecificationCarriesTheActorsVariation()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);
        var resolution = Resolve(package, context, "AmbientSound14");

        Assert.Equal(SoundActorRoute.SpawnedEvent, resolution.Route);
        Assert.Equal("ambience_1_lightbuzz_welcome",
            Assert.Single(resolution.Specifications).SoundName);
        Assert.Equal(
            ["scripted_2_lightbuzz_01", "scripted_2_lightbuzz_02", "scripted_2_lightbuzz_03",
             "scripted_2_lightbuzz_04", "scripted_2_lightbuzz_05"],
            resolution.SampleNames);
    }

    /// <summary>
    /// A <c>SoundMarker</c> takes the other route: its schema name is the specification's name.
    /// </summary>
    [RequiresGameFact]
    public void ASoundMarkerNamesItsSpecificationOutright()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var resolution = Resolve(package, context, "SoundMarker134");

        Assert.Equal(SoundActorRoute.Direct, resolution.Route);
        Assert.Equal("ambience_1_calm_awe_1", resolution.MatchedName);
        Assert.Equal("ambience_1_calm_awe_1", Assert.Single(resolution.Specifications).SoundName);
        Assert.Equal("ambience_1_calm_awe_01", Assert.Single(resolution.SampleNames));
    }

    /// <summary>
    /// The <c>AmbientSoundSpawned_</c> prefix is structural, not a name resemblance.
    /// </summary>
    /// <remarks>
    /// Every response carrying the prefix also declares <c>Event == "Spawned"</c> and
    /// <c>SourceClassName == "AmbientSound"</c>. If the prefix were coincidence, those two fields
    /// would vary; they do not, on any of the 10,360 shipped in the whole game — see
    /// <c>SoundActorSpecificationCoverageTests</c> for that sweep. This is the same check on one
    /// package.
    /// </remarks>
    [RequiresGameFact]
    public void SpawnedResponsesAllDeclareTheSpawnedAmbientSoundEvent()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var spawned = SoundEventReader.Read(package)
            .Where(response => response.ObjectName.StartsWith(
                SoundActorSpecificationIndex.SpawnedPrefix, StringComparison.Ordinal))
            .ToList();

        Assert.NotEmpty(spawned);
        Assert.All(spawned, response => Assert.Equal("Spawned", response.Event));
        Assert.All(spawned, response => Assert.Equal("AmbientSound", response.SourceClassName));
    }

    /// <summary>
    /// A numbered specification name renders with no separator, the same as every export name.
    /// </summary>
    /// <remarks>
    /// <c>ambience_0_fire</c> with FName number 2 is the export <c>ambience_0_fire2</c>. Rendering
    /// it <c>ambience_0_fire_2</c> instead — which this reader did — costs nothing visible and
    /// silently loses 100 references game-wide, because the name it produces matches no export at
    /// all. The package's own FName reader has always used the no-separator form, confirmed against
    /// UEViewer's BioShock branch.
    /// </remarks>
    [RequiresGameFact]
    public void ANumberedSpecificationNameMatchesItsExport()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);
        var resolution = Resolve(package, context, "AmbientSound12");

        Assert.Equal("ambience_0_fire2", Assert.Single(resolution.Specifications).SoundName);
        Assert.Contains(package.Exports, export => export.ObjectName == "ambience_0_fire2");
        Assert.DoesNotContain(package.Exports, export => export.ObjectName == "ambience_0_fire_2");
    }

    /// <summary>
    /// An actor whose only name is an editor default resolves to nothing, and says so.
    /// </summary>
    [RequiresGameFact]
    public void AnActorWithOnlyADefaultLabelStaysUnresolved()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var index = SoundActorSpecificationIndex.Build(package);

        var unresolved = context.Actors
            .Where(actor => actor.Source.ClassName is "AmbientSound" or "SoundMarker")
            .Select(actor => index.Resolve(actor, package))
            .Where(resolution => !resolution.IsResolved)
            .ToList();

        Assert.NotEmpty(unresolved);
        Assert.All(unresolved, resolution => Assert.Equal(SoundActorRoute.None, resolution.Route));
        Assert.All(unresolved, resolution => Assert.Null(resolution.MatchedName));
        Assert.All(unresolved, resolution => Assert.Empty(resolution.SampleNames));
    }
}
