using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Whole-install coverage for native Sound payload extraction.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SoundAuditTests(GameFixture game)
{
    /// <summary>
    /// Every shipped native Sound export has an exact lazy-array boundary and starts with an MP3 frame.
    /// </summary>
    [RequiresGameFact]
    public void EveryNativeSoundInTheInstallIsAnMp3Payload()
    {
        int packages = 0, sounds = 0, mp3 = 0, unknown = 0;

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot)
                     .Concat(GameLocator.EnumerateScriptPackages(game.RequireRoot)))
        {
            using var package = BioShockPackage.Open(file);
            var found = SoundReader.Read(package);
            if (found.Count == 0) continue;

            packages++;
            sounds += found.Count;
            mp3 += found.Count(sound => sound.Format == SoundFormat.Mp3);
            unknown += found.Count(sound => sound.Format == SoundFormat.Unknown);
        }

        Assert.Equal(21, packages);
        Assert.Equal(25848, sounds);
        Assert.Equal(sounds, mp3);
        Assert.Equal(0, unknown);
    }
}
