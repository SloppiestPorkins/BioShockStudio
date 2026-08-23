using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SoundEventCoverageTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryShippedResponseAndVariationDecodesExactly()
    {
        int exports = 0, responses = 0, entries = 0, multiple = 0, mode6 = 0, mode7 = 0, unresolved = 0;
        int responsesWithChance = 0, chanceEntries = 0, responsesWithContext = 0, contextEntries = 0;
        var chanceValues = new HashSet<int>();
        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);
            exports += package.Exports.Count(export => package.GetClassName(export) == SoundEventReader.ClassName);
            var decoded = SoundEventReader.Read(package);
            responses += decoded.Count;
            entries += decoded.Sum(response => response.Specifications.Count);
            multiple += decoded.Count(response => response.Specifications.Count > 1);
            mode6 += decoded.Sum(response => response.Specifications.Count(specification => specification.Mode == 0x06));
            mode7 += decoded.Sum(response => response.Specifications.Count(specification => specification.Mode == 0x07));
            unresolved += decoded.Count(response => !response.IsResolved);
            responsesWithChance += decoded.Count(response => response.Chances.Count > 0);
            chanceEntries += decoded.Sum(response => response.Chances.Count);
            responsesWithContext += decoded.Count(response => response.LevelContexts.Count > 0);
            contextEntries += decoded.Sum(response => response.LevelContexts.Count);
            foreach (int chance in decoded.SelectMany(response => response.Chances)) chanceValues.Add(chance);
            Assert.All(decoded, response => Assert.True(response.SpecificationComplete, response.ObjectName));
            Assert.All(decoded, response => Assert.True(response.ConditionsComplete, response.ObjectName));
            Assert.All(decoded.Where(response => !response.IsResolved), response => Assert.False(response.SpecificationPresent));
            Assert.All(decoded.Where(response => response.SpecificationPresent), response =>
                Assert.Equal(response.Specifications.Count, response.Chances.Count));
        }
        Assert.Equal(106_000, exports);
        Assert.Equal(exports, responses);
        Assert.Equal(110_120, entries);
        Assert.Equal(1_760, multiple);
        Assert.Equal(62_084, mode6);
        Assert.Equal(48_036, mode7);
        Assert.Equal(420, unresolved);
        Assert.Equal(105_580, responsesWithChance);
        Assert.Equal(110_120, chanceEntries);
        Assert.Equal(51_620, responsesWithContext);
        Assert.Equal(123_500, contextEntries);
        Assert.Equal(new[] { 0, 20, 30, 50, 70, 75, 80, 100 }, chanceValues.Order().ToArray());
    }
}
