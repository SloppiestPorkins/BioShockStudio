using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class AudioActorResolutionTests(GameFixture game)
{
    [RequiresGameFact]
    public async Task ExactFmodNamesResolveOnlyTheShippedSoundMarkerSubset()
    {
        var catalog = await StreamSampleCatalog.BuildAsync(game.RequireRoot);
        Assert.Equal(10_882, catalog.Locations.Count);
        Assert.Equal(2_047, catalog.DistinctNameCount);
        Assert.Equal(2_047, catalog.Locations.Count(location => location.Language == "English"));

        var resolutions = new List<AudioActorResolution>();
        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);
            foreach (var actor in LevelAnalyzer.Analyze(package).Actors.Where(actor =>
                         actor.Source.ClassName is "AmbientSound" or "SoundMarker" or "MusicBox"))
                resolutions.Add(AudioActorResolver.Resolve(actor, package, catalog));
        }

        Assert.Equal(3_247, resolutions.Count);
        var resolved = resolutions.Where(resolution => resolution.IsResolved).ToList();
        Assert.Equal(177, resolved.Count);
        Assert.All(resolved, resolution => Assert.Equal("SoundMarker", resolution.Actor.ClassName));
        Assert.Equal(0, resolutions.Count(resolution => resolution.Actor.ClassName == "AmbientSound" && resolution.IsResolved));
        Assert.Equal(0, resolutions.Count(resolution => resolution.Actor.ClassName == "MusicBox" && resolution.IsResolved));
        Assert.All(resolved.SelectMany(resolution => resolution.Matches), match =>
            Assert.Contains(match.Candidate.Source, new[] { "Label", "Schema1", "Schema2" }));
    }
}
