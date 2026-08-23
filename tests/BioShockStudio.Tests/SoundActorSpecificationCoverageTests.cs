using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Every placed sound actor in the game, and what it resolves to.
/// </summary>
/// <remarks>
/// <para>
/// The figure this replaces: exact matching against the shipped FSB sample names resolved
/// <b>177 of 3,247</b> actors, all <c>SoundMarker</c>s, and no <c>AmbientSound</c> whatsoever.
/// Through the specification route it is <b>3,068 of 3,247</b>.
/// </para>
/// <para>
/// The remainder is not a decode failure and is not rounded away: 142 <c>AmbientSound</c>s, 35
/// <c>SoundMarker</c>s and both <c>MusicBox</c>es declare no name that any shipped object answers
/// to — many of them carrying only an editor default such as <c>SoundMarker3</c>. Unknown is a
/// valid answer.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SoundActorSpecificationCoverageTests(GameFixture game)
{
    [RequiresGameFact]
    public void EverySoundActorIsAccountedForAgainstTheShippedSpecifications()
    {
        int actors = 0, direct = 0, spawned = 0, resolved = 0;
        int ambient = 0, ambientResolved = 0, markers = 0, markersResolved = 0, musicBoxes = 0, musicResolved = 0;
        int sampleReferences = 0;

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            var index = SoundActorSpecificationIndex.Build(package);
            var context = LevelAnalyzer.Analyze(package);

            foreach (var actor in context.Actors)
            {
                string className = actor.Source.ClassName;
                if (className is not ("AmbientSound" or "SoundMarker" or "MusicBox")) continue;

                actors++;
                var resolution = index.Resolve(actor, package);
                if (resolution.Route == SoundActorRoute.Direct) direct++;
                if (resolution.Route == SoundActorRoute.SpawnedEvent) spawned++;
                if (resolution.IsResolved) { resolved++; sampleReferences += resolution.SampleNames.Count; }

                switch (className)
                {
                    case "AmbientSound": ambient++; if (resolution.IsResolved) ambientResolved++; break;
                    case "SoundMarker": markers++; if (resolution.IsResolved) markersResolved++; break;
                    default: musicBoxes++; if (resolution.IsResolved) musicResolved++; break;
                }

                // An unresolved actor must claim nothing at all.
                if (!resolution.IsResolved)
                {
                    Assert.Equal(SoundActorRoute.None, resolution.Route);
                    Assert.Null(resolution.MatchedName);
                    Assert.Empty(resolution.Specifications);
                }
            }
        }

        Assert.Equal(3_247, actors);
        Assert.Equal(2_893, ambient);
        Assert.Equal(352, markers);
        Assert.Equal(2, musicBoxes);

        Assert.Equal(3_068, resolved);
        Assert.Equal(317, direct);
        Assert.Equal(2_751, spawned);
        Assert.Equal(direct + spawned, resolved);

        // Each class takes exactly one of the two routes, which is what makes them two routes and
        // not one heuristic: no AmbientSound names a specification outright, and no SoundMarker
        // goes through a spawned event.
        Assert.Equal(2_751, ambientResolved);
        Assert.Equal(spawned, ambientResolved);
        Assert.Equal(317, markersResolved);
        Assert.Equal(direct, markersResolved);
        Assert.Equal(0, musicResolved);

        Assert.Equal(5_804, sampleReferences);
    }

    /// <summary>
    /// The <c>AmbientSoundSpawned_</c> prefix is structural across the whole game.
    /// </summary>
    /// <remarks>
    /// 10,360 responses carry it, and every one declares the same event and the same source class.
    /// A prefix that meant nothing would not do that.
    /// </remarks>
    [RequiresGameFact]
    public void EverySpawnedResponseDeclaresTheSpawnedAmbientSoundEvent()
    {
        int spawnedResponses = 0;
        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            var spawned = SoundEventReader.Read(package)
                .Where(response => response.ObjectName.StartsWith(
                    SoundActorSpecificationIndex.SpawnedPrefix, StringComparison.Ordinal))
                .ToList();

            spawnedResponses += spawned.Count;
            Assert.All(spawned, response => Assert.Equal("Spawned", response.Event));
            Assert.All(spawned, response => Assert.Equal("AmbientSound", response.SourceClassName));
        }

        Assert.Equal(10_360, spawnedResponses);
    }

    /// <summary>
    /// Where the samples the specifications name actually ship.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A resolved name is not a located sample, and this project has a rule against calling the
    /// first one the second. Of the 5,726 distinct names the specifications reference, 2,080 are
    /// native <c>Sound</c> exports inside the map packages and 1,676 are in the streamed FSB5
    /// banks - two stores that do not overlap on a single name.
    /// </para>
    /// <para>
    /// <b>The remaining 1,970 are in neither, and that is reported rather than explained away.</b>
    /// It is still a real gap; what changed is that it is now a list of 1,970 exact names instead
    /// of the open question "where does sound-effect data ship".
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public async Task EverySpecificationSampleNameIsLocatedInAShippedStore()
    {
        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var nativeSounds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            foreach (var metadata in SoundEffectSpecificationReader.Read(package))
                foreach (var entry in metadata.SoundSpecs)
                    if (!string.IsNullOrEmpty(entry.SoundName)) names.Add(entry.SoundName!);

            foreach (var export in package.Exports)
                if (package.GetClassName(export) == "Sound") nativeSounds.Add(export.ObjectName);
        }

        var catalog = await StreamSampleCatalog.BuildAsync(game.RequireRoot);

        int native = names.Count(nativeSounds.Contains);
        int streamed = names.Count(name => catalog.Find(name).Count > 0);
        int located = names.Count(name => nativeSounds.Contains(name) || catalog.Find(name).Count > 0);

        Assert.Equal(5_726, names.Count);
        Assert.Equal(2_080, native);
        Assert.Equal(1_676, streamed);

        // The two stores do not overlap on a single name.
        Assert.Equal(native + streamed, located);
        Assert.Equal(3_756, located);

        // 1,970 named samples - 34.4% - are in neither store. Recorded, not explained away: this is
        // the part of section 4 that remains open, and it is now a list of 1,970 exact names rather
        // than "where does sound-effect data ship".
        Assert.Equal(1_970, names.Count - located);
    }
}
