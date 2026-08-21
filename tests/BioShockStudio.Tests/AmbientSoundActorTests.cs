using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Measures the on-disk boundary of placed <c>AmbientSound</c> actors.</summary>
/// <remarks>
/// This is deliberately a container probe, not an audio decoder. The map stores AmbientSound as
/// an ordinary actor: its validated actor header is followed by tagged properties and the shared
/// actor trailer. Until a different, class-specific byte region is observed, there is no sound tail
/// to interpret as radius, volume, pitch or a sound reference.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class AmbientSoundActorTests(GameFixture game)
{
    /// <summary>
    /// Every sampled AmbientSound ends precisely at the shared actor trailer, with no class-specific
    /// post-property bytes available to decode.
    /// </summary>
    [RequiresGameFact]
    public void MedicalAmbientSoundsUseTheOrdinaryActorTrailerAndNoMore()
    {
        string map = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        using var package = BioShockPackage.Open(map);

        var sounds = package.Exports
            .Where(export => package.GetClassName(export) == "AmbientSound")
            .Select(export => (Export: export, Payload: ActorPayloadReader.TryRead(package, export)))
            .ToList();

        Assert.True(sounds.Count > 100, $"only {sounds.Count} AmbientSound actors found");
        Assert.All(sounds, sound => Assert.NotNull(sound.Payload));

        foreach (var (export, payload) in sounds)
        {
            var actor = payload!;
            Assert.False(actor.Truncated);
            Assert.Equal(export.SerialSize, actor.PropertyListEnd + actor.Trailer.Length);
            Assert.Equal(ActorPayloadReader.StandardTrailerLength, actor.Trailer.Length);
            Assert.Equal(new byte[] { 4, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0 }, actor.Trailer);
        }
    }
}
