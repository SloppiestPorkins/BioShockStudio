using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The whole-game <c>SoundEffectSpecification</c> census that <c>docs/research/audio.md</c> asked
/// for before this sub-part of Gate 4 item 1 could be closed.
/// </summary>
/// <remarks>
/// <para>
/// The sweep is over the 21 shipped non-localised map packages
/// (<see cref="GameLocator.EnumeratePackages"/>). The 140 localised variants repeat the same
/// objects, so counting them would multiply every figure here by nothing meaningful.
/// </para>
/// <para>
/// <b>Never trust a single sample</b> — §7. The pistol reload has one alternative and no ranges;
/// <c>bullet_hit</c> has 78 alternatives, a pitch range and a delay range. Only a whole-game pass
/// shows that neither is the general case and that nothing in between fails to decode.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SoundEffectSpecificationCoverageTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryShippedSpecificationDecodesCompletely()
    {
        int packages = 0, declared = 0, decoded = 0, arrayAbsent = 0, arrayIncomplete = 0,
            withAlternatives = 0, multipleAlternatives = 0;
        int entries = 0, named = 0, withUnit = 0, resolvedSoundToPlay = 0;
        var samples = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var units = new HashSet<string>(StringComparer.Ordinal);

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            int here = package.Exports.Count(export => export.SerialSize > 0
                && package.GetClassName(export) == SoundEffectSpecificationReader.ClassName);
            if (here == 0) continue;

            packages++;
            declared += here;
            var read = SoundEffectSpecificationReader.Read(package);
            decoded += read.Count;

            foreach (var metadata in read)
            {
                if (!metadata.SoundSpecsPresent) arrayAbsent++;
                else if (!metadata.SoundSpecsComplete) arrayIncomplete++;
                if (metadata.SoundSpecs.Count > 0) withAlternatives++;
                if (metadata.SoundSpecs.Count > 1) multipleAlternatives++;
                entries += metadata.SoundSpecs.Count;

                foreach (var entry in metadata.SoundSpecs)
                {
                    if (!string.IsNullOrEmpty(entry.SoundName)) { named++; samples.Add(entry.SoundName!); }
                    if (!string.IsNullOrEmpty(entry.SoundUnit)) { withUnit++; units.Add(entry.SoundUnit!); }
                    if (entry.SoundToPlay is { IsNull: false }) resolvedSoundToPlay++;
                }
            }
        }

        Assert.Equal(20, packages);              // Entry ships none
        Assert.Equal(33_227, declared);
        Assert.Equal(declared, decoded);         // no object failed to read
        Assert.Equal(0, arrayAbsent);
        Assert.Equal(0, arrayIncomplete);

        Assert.Equal(33_227, withAlternatives);  // every specification names at least one sample
        Assert.Equal(8_561, multipleAlternatives);
        Assert.Equal(81_775, entries);
        Assert.Equal(entries, named);
        Assert.Equal(entries, withUnit);
        Assert.Equal(5_726, samples.Count);
        Assert.Equal(91, units.Count);

        // An honest negative: the object reference beside every sample name is null in every
        // shipped entry, so the name is the only link to the sample and must not be skipped.
        Assert.Equal(0, resolvedSoundToPlay);
    }

    /// <summary>
    /// How many specifications serialize each modulation field, rather than inheriting the default.
    /// </summary>
    /// <remarks>
    /// These are the "attenuation, pitch/volume, chance/variation" figures Gate 4 item 1 asked for.
    /// They are counts of explicit overrides — a specification without a <c>PitchRange</c> is not a
    /// specification with a zero one.
    /// </remarks>
    [RequiresGameFact]
    public void ModulationOverridesAreCountedWhereTheyAreSerialized()
    {
        int outerRadius = 0, innerRadius = 0, volume = 0, volumeRange = 0, pitchRange = 0,
            delayRange = 0, monoloop = 0, polyloop = 0, threePartLoopPoints = 0;
        var volumeCategories = new SortedSet<byte>();
        var perSoundVolumeMods = new SortedSet<byte>();

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            foreach (var metadata in SoundEffectSpecificationReader.Read(package))
            {
                if (metadata.OuterRadius is not null) outerRadius++;
                if (metadata.InnerRadius is not null) innerRadius++;
                if (metadata.Volume is not null) volume++;
                if (metadata.VolumeRange is not null) volumeRange++;
                if (metadata.PitchRange is not null) pitchRange++;
                if (metadata.DelayRange is not null) delayRange++;
                if (metadata.Monoloop is not null) monoloop++;
                if (metadata.Polyloop is not null) polyloop++;
                if (metadata.ThreePartLoopPoints is not null) threePartLoopPoints++;
                if (metadata.VolumeCategory is { } category) volumeCategories.Add(category);
                foreach (var entry in metadata.SoundSpecs)
                    if (entry.PerSoundVolumeMod is { } mod) perSoundVolumeMods.Add(mod);
            }
        }

        Assert.Equal(12_225, outerRadius);
        Assert.Equal(19_438, innerRadius);
        Assert.Equal(31_669, volume);
        Assert.Equal(32_693, volumeRange);
        Assert.Equal(3_048, pitchRange);
        Assert.Equal(1_327, delayRange);
        Assert.Equal(30_414, monoloop);
        Assert.Equal(32_995, polyloop);
        Assert.Equal(387, threePartLoopPoints);

        Assert.Equal(new byte[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15 }, volumeCategories.ToArray());

        // Shipped as zero on all 81,775 entries. Recorded, not interpreted.
        Assert.Equal(new byte[] { 0 }, perSoundVolumeMods.ToArray());
    }
}
