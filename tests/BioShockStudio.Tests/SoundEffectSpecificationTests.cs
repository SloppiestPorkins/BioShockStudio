using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The shipped <c>SoundEffectSpecification</c> object — where BioShock actually keeps per-sound
/// attenuation, volume, pitch and variation.
/// </summary>
/// <remarks>
/// <para>
/// Gate 4 item 1 asks for "chance/variation, attenuation, pitch/volume". The placed level actors
/// carry none of it (<c>SoundActorSchemaTests</c> proves that across all 21 maps), and the earlier
/// conclusion drawn from it — that the settings do not exist — was wrong about <i>where</i>, not
/// about the actors. They are here, on 33,227 shipped objects.
/// </para>
/// <para>
/// A null field means the object did not serialize it and the script-class default in
/// <c>IGSoundEffectsSubsystem.U</c> stands. Absence is never collapsed into zero.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class SoundEffectSpecificationTests(GameFixture game)
{
    private SoundEffectMetadata Specification(BioShockPackage package, string name) =>
        Assert.Single(SoundEffectSpecificationReader.Read(package), item => item.SoundName == name);

    /// <summary>
    /// The overrides the pistol reload serializes, and the defaults it leaves alone.
    /// </summary>
    [RequiresGameFact]
    public void PistolReloadCarriesExplicitSoundEffectOverrides()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadata = Specification(package, "weapons_pistol_reload_one");

        Assert.Null(metadata.OuterRadius); // inherits the shipped class default of 3000
        Assert.Equal(1000f, metadata.InnerRadius);
        Assert.Equal(80, metadata.Volume);
        Assert.Null(metadata.Pitch); // inherits the shipped class default of 1
        Assert.Equal((byte)3, metadata.VolumeCategory);
    }

    /// <summary>
    /// The specification names the sample it plays. This is the link the level actors do not carry.
    /// </summary>
    /// <remarks>
    /// <c>SoundUnit</c> is a logical unit name, not a bank filename — <c>Weapons</c> is not any
    /// shipped <c>.fsb</c>. It is exported as declared rather than resolved to a file.
    /// </remarks>
    [RequiresGameFact]
    public void PistolReloadNamesItsSample()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadata = Specification(package, "weapons_pistol_reload_one");

        Assert.True(metadata.SoundSpecsPresent);
        Assert.True(metadata.SoundSpecsComplete);
        var entry = Assert.Single(metadata.SoundSpecs);
        Assert.Equal("Weapons", entry.SoundUnit);
        Assert.Equal("weapons_pistol_reload_one", entry.SoundName);
    }

    /// <summary>
    /// Variation is an array of alternatives on one specification, not a field on the actor.
    /// </summary>
    /// <remarks>
    /// <c>bullet_hit</c> ships 78 of them — one per surface and take. A reader that took only the
    /// first entry would silently discard 77 shipped samples, which is exactly why the array is
    /// required to consume its own value exactly before any entry is reported.
    /// </remarks>
    [RequiresGameFact]
    public void BulletHitShipsSeventyEightAlternatives()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadata = Specification(package, "bullet_hit");

        Assert.True(metadata.SoundSpecsComplete);
        Assert.Equal(78, metadata.SoundSpecs.Count);
        Assert.All(metadata.SoundSpecs, entry => Assert.Equal("Weapons", entry.SoundUnit));
        Assert.Contains(metadata.SoundSpecs, entry => entry.SoundName == "bullet_hit_cardboard_01");
    }

    /// <summary>
    /// The 78 alternatives are not 78 distinct samples: 62 are, and 16 repeat under a second
    /// <c>Flag</c>.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b><c>Flag</c> groups the alternatives — `PLAUSIBLE`, from the names.</b> The entries
    /// carrying <c>Flag</c> 0 and 1 are all <c>bullet_hit_default_*</c>; 7 and 8 are all
    /// <c>bullet_hit_metalThin_*</c> and <c>bullet_hit_metalThick_*</c>; 11 is
    /// <c>bullet_hit_cardboard_*</c>. The repeats are the same sample offered under two of those
    /// groups, which is why a set of names is not the right shape for this array and the entries
    /// are kept as a list.
    /// </para>
    /// <para>
    /// What the flag <i>selects</i> — impact surface is the obvious reading — is not asserted here.
    /// It is a number in the bytes; the correspondence to a surface type is a hypothesis until
    /// something outside these names confirms it.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void RepeatedAlternativesDifferOnlyByFlag()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadata = Specification(package, "bullet_hit");

        Assert.Equal(62, metadata.SoundSpecs.Select(entry => entry.SoundName).Distinct().Count());
        var repeated = metadata.SoundSpecs
            .GroupBy(entry => entry.SoundName)
            .Where(group => group.Count() > 1)
            .ToList();
        Assert.Equal(16, repeated.Count);
        Assert.All(repeated, group =>
            Assert.Equal(group.Count(), group.Select(entry => entry.Flag).Distinct().Count()));

        Assert.All(metadata.SoundSpecs.Where(entry => entry.Flag is 0 or 1),
            entry => Assert.StartsWith("bullet_hit_default_", entry.SoundName));
        Assert.All(metadata.SoundSpecs.Where(entry => entry.Flag is 11),
            entry => Assert.StartsWith("bullet_hit_cardboard_", entry.SoundName));
    }

    /// <summary>
    /// The modulation ranges decode as the nested tagged <c>Min</c>/<c>Max</c> lists they are.
    /// </summary>
    /// <remarks>
    /// Reading a <c>Range</c> as a bare pair of floats would appear to work — the first four bytes
    /// are a name index, not a float, so it would produce a plausible tiny number rather than an
    /// error. Requiring both tagged field names is what makes this a decode.
    /// </remarks>
    [RequiresGameFact]
    public void BulletHitPitchAndDelayRangesDecode()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadata = Specification(package, "bullet_hit");

        Assert.NotNull(metadata.PitchRange);
        Assert.Equal(0.79f, metadata.PitchRange!.Min, 3);
        Assert.Equal(1.34f, metadata.PitchRange.Max, 3);

        Assert.NotNull(metadata.DelayRange);
        Assert.Equal(0.05f, metadata.DelayRange!.Min, 3);
        Assert.Equal(0.05f, metadata.DelayRange.Max, 3);

        Assert.Equal(10000f, metadata.OuterRadius);
        Assert.Equal(500f, metadata.InnerRadius);
    }

    /// <summary>
    /// <c>Polyloop</c> is a struct containing a struct, and both levels decode.
    /// </summary>
    [RequiresGameFact]
    public void PolyLoopCarriesANestedRangeAndAVoiceLimit()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadata = Specification(package, "bullet_hit");

        Assert.NotNull(metadata.Polyloop);
        Assert.Equal(0, metadata.Polyloop!.LoopSoundLimit);
        Assert.NotNull(metadata.Polyloop.Range);
        Assert.Equal(-1f, metadata.Polyloop.Range!.Min);
        Assert.Equal(-1f, metadata.Polyloop.Range.Max);
    }

    /// <summary>
    /// A UE2 <c>Bool</c> keeps its value in the property tag, so presence is not the value.
    /// </summary>
    /// <remarks>
    /// Both booleans below are present on <c>bullet_hit</c>; reporting presence alone would make
    /// every serialized flag in the game read as true.
    /// </remarks>
    [RequiresGameFact]
    public void SerializedFlagsCarryTheirValueAndAbsenceStaysNull()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadata = Specification(package, "bullet_hit");

        Assert.True(metadata.NeverRepeat);
        Assert.True(metadata.AttachToSource);
        Assert.Null(metadata.NoRepeat);         // not serialized at all
        Assert.Null(metadata.Is2DPositional);
    }
}
