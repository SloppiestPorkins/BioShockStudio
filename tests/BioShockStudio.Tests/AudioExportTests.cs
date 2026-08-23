using System.Text.Json;
using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The audio half of a package's UE5 import set — ROADMAP Gate 4 item 2.
/// </summary>
/// <remarks>
/// <para>
/// The mapping is close to one-to-one because BioShock's own structure already is one: a
/// <c>SoundEffectSpecification</c> carries alternatives, attenuation radii, volume and pitch ranges
/// and looping state, which is what a <c>USoundCue</c> is made of. These tests pin that nothing is
/// invented and, in particular, that <b>inheritance is not flattened into zero</b>.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class AudioExportTests(GameFixture game)
{
    private static AudioCueDocument Cue(AudioManifest manifest, string name) =>
        Assert.Single(manifest.Cues, cue => cue.Name == name);

    /// <summary>
    /// An absent property stays absent through the export, rather than becoming a zero.
    /// </summary>
    /// <remarks>
    /// This is the assertion that matters most in this file. <c>weapons_pistol_reload_one</c>
    /// serializes <c>InnerRadius</c>, <c>Volume</c> and <c>VolumeCategory</c> and does <b>not</b>
    /// serialize <c>OuterRadius</c> or <c>Pitch</c>, so the script-class defaults (3000 and 1) stand.
    /// An exporter that wrote 0 for those would silently un-attenuate the sound and drop it to no
    /// pitch, and the manifest would look complete while being wrong.
    /// </remarks>
    [RequiresGameFact]
    public void AnAbsentPropertyIsExportedAsAbsentNotAsZero()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var manifest = AudioExporter.Build(package, "0-Lighthouse");
        var cue = Cue(manifest, "weapons_pistol_reload_one");

        Assert.Equal(1000f, cue.InnerRadius);
        Assert.Equal(80, cue.Volume);
        Assert.Equal((byte)3, cue.VolumeCategory);

        Assert.Null(cue.OuterRadius);   // inherits 3000
        Assert.Null(cue.Pitch);         // inherits 1
        Assert.Null(cue.PitchRange);
        Assert.Null(cue.DelayRange);
    }

    /// <summary>
    /// The JSON drops nulls, so an importer reading it sees the same absence.
    /// </summary>
    [RequiresGameFact]
    public void TheWrittenJsonOmitsInheritedPropertiesEntirely()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        string directory = Path.Combine(Path.GetTempPath(), "bioshock-audio-" + Guid.NewGuid().ToString("N"));
        try
        {
            string path = AudioExporter.Write(package, "0-Lighthouse", directory);
            using var document = JsonDocument.Parse(File.ReadAllText(path));

            Assert.Equal(AudioExporter.ManifestVersion, document.RootElement.GetProperty("version").GetInt32());

            var cue = document.RootElement.GetProperty("cues").EnumerateArray()
                .Single(element => element.GetProperty("name").GetString() == "weapons_pistol_reload_one");

            Assert.Equal(1000, cue.GetProperty("innerRadius").GetSingle());
            Assert.False(cue.TryGetProperty("outerRadius", out _));
            Assert.False(cue.TryGetProperty("pitch", out _));
        }
        finally
        {
            try { Directory.Delete(directory, recursive: true); } catch { /* best effort */ }
        }
    }

    /// <summary>
    /// A cue's alternatives survive as a list, with the surface class named.
    /// </summary>
    /// <remarks>
    /// 78 alternatives, 62 distinct names — the repeats differ only by surface, so a set would lose
    /// them. The <c>MVT_*</c> name is exported; <b>nothing selects by it</b>, because that the
    /// runtime dispatches on it is <c>LIKELY</c> and not confirmed.
    /// </remarks>
    [RequiresGameFact]
    public void AlternativesKeepTheirOrderCountAndSurfaceClass()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var cue = Cue(AudioExporter.Build(package, "0-Lighthouse"), "bullet_hit");

        Assert.Equal(78, cue.Alternatives.Count);
        Assert.All(cue.Alternatives, alternative => Assert.Equal("Weapons", alternative.Unit));
        Assert.All(cue.Alternatives, alternative => Assert.NotNull(alternative.SurfaceType));

        Assert.Equal("MVT_Cardboard",
            Assert.Single(cue.Alternatives, a => a.Wave == "bullet_hit_cardboard_01").SurfaceType);
        Assert.Equal("MVT_Carpet",
            Assert.Single(cue.Alternatives, a => a.Wave == "bullet_hit_carpet_01").SurfaceType);

        Assert.Equal(500f, cue.InnerRadius);
        Assert.Equal(10000f, cue.OuterRadius);
        Assert.Equal(0.79f, cue.PitchRange!.Min, 3);
        Assert.Equal(1.34f, cue.PitchRange.Max, 3);
    }

    /// <summary>
    /// Payloads are written byte-for-byte, never transcoded.
    /// </summary>
    [RequiresGameFact]
    public void NativePayloadsAreWrittenUnchanged()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        string directory = Path.Combine(Path.GetTempPath(), "bioshock-audio-" + Guid.NewGuid().ToString("N"));
        try
        {
            AudioExporter.Write(package, "0-Lighthouse", directory);

            var sound = Assert.Single(SoundReader.Read(package), item => item.Name == "weapons_pistol_reload_one");
            string written = Path.Combine(directory, AudioExporter.WaveDirectoryName, "weapons_pistol_reload_one.mp3");

            Assert.True(File.Exists(written));
            Assert.Equal(sound.RawData, File.ReadAllBytes(written));
        }
        finally
        {
            try { Directory.Delete(directory, recursive: true); } catch { /* best effort */ }
        }
    }

    /// <summary>
    /// A placed actor reaches its cue, so a level import can put the sound in the right place.
    /// </summary>
    [RequiresGameFact]
    public void ResolvedSoundActorsCarryTheirCue()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var manifest = AudioExporter.Build(package, "0-Lighthouse");

        var actor = Assert.Single(manifest.Actors, item => item.Actor == "AmbientSound2");
        Assert.Equal("AmbientSound", actor.ClassName);
        Assert.Equal("spawnedEvent", actor.Route);
        Assert.Equal("LighthouseWavelets", actor.MatchedName);
        Assert.Equal("ambience_0_wavelets", Assert.Single(actor.Cues));
    }

    /// <summary>
    /// Without a locator, "unresolved" means "not in this package" — and must not be read as missing.
    /// </summary>
    /// <remarks>
    /// Pinned deliberately. The first cut of this exporter reported 908 unresolved samples for
    /// <c>0-Lighthouse</c>, every one of which ships perfectly well in another store. A figure that
    /// looks like missing audio and is not is exactly the kind of plausible-wrong result this
    /// project exists to avoid, so the two cases are kept distinguishable rather than merged.
    /// </remarks>
    [RequiresGameFact]
    public void WithoutALocatorUnresolvedMeansOnlyNotInThisPackage()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var manifest = AudioExporter.Build(package, "0-Lighthouse");

        Assert.NotEmpty(manifest.UnresolvedSamples);
        Assert.All(manifest.Waves, wave => Assert.Equal("ThisPackage", wave.Source));

        // Every one of them is a real, shipped sample - just not one this package holds.
        Assert.Contains("ambience_0_bathy", manifest.UnresolvedSamples);
    }
}
