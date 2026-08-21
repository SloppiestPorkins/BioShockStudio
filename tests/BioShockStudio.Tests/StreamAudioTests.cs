using BioShockStudio.Core.Audio;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Real-bank coverage for the streamed FSB5 surface.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class StreamAudioTests(GameFixture game)
{
    [RequiresGameFact]
    public void ShippedStreamBanksHaveProvenHeadersAndSampleCounts()
    {
        var banks = new StreamAudioService().List(game.RequireRoot);

        Assert.Equal(65, banks.Count);
        Assert.All(banks, bank =>
        {
            Assert.StartsWith("streams_", bank.Name, StringComparison.OrdinalIgnoreCase);
            Assert.True(bank.SampleCount > 0, bank.Name);
            Assert.True(bank.Size > 60, bank.Name);
        });
        Assert.Equal(10_882, banks.Sum(bank => bank.SampleCount));
    }

    [RequiresGameFact]
    public async Task FmodListsEveryNamedEntryInTheFirstEnglishBank()
    {
        var streams = new StreamAudioService();
        var bank = Assert.Single(streams.List(game.RequireRoot).Where(b => b.Name == "streams_0_audio.fsb"));

        var samples = await streams.ListSamplesAsync(game.RequireRoot, bank);

        Assert.Equal(bank.SampleCount, samples.Count);
        Assert.Equal("ambience_0_bathy", samples[0].Name);
        Assert.Equal("vo_0_planedive", samples[6].Name);
    }
}
