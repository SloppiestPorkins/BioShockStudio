using System.Text.Json;
using System.Text.Json.Serialization;
using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Export;

/// <summary>A shipped <c>Range</c>, carried through as declared.</summary>
public sealed record AudioRangeDocument(float Min, float Max);

/// <summary>
/// One playable source an import should create as a <c>USoundWave</c>.
/// </summary>
/// <remarks>
/// <para>
/// <c>File</c> is null for a sample this run did not write - one in another package, or in a
/// streamed FSB5 bank. <b>That is not a missing asset</b>: <c>Source</c>, <c>Container</c> and
/// <c>BankIndex</c> say exactly where it ships. Writing every store's payloads on every export would
/// start a very large job implicitly, which the standing deferral in
/// <c>docs/ENGINEERING_RULES.md</c> §60 forbids.
/// </para>
/// <para>
/// Nothing is transcoded. A native payload is the game's own MP3 bytes; a decoded stream is the
/// WAV the game's own FMOD produced.
/// </para>
/// </remarks>
public sealed record AudioWaveDocument
{
    public required string Name { get; init; }

    /// <summary>
    /// <c>ThisPackage</c>, or the store the locator found it in: <c>CoreMap</c>,
    /// <c>LocalisedMap</c>, <c>ScriptPackage</c>, <c>StreamedBank</c>.
    /// </summary>
    public required string Source { get; init; }

    /// <summary>Path relative to the manifest, or null when the payload was not written.</summary>
    public string? File { get; init; }

    /// <summary><c>mp3</c> or <c>wav</c>; null when nothing was written.</summary>
    public string? Format { get; init; }

    /// <summary>The package or bank file the sample ships in.</summary>
    public string? Container { get; init; }

    /// <summary>Subsound index, for a streamed bank only.</summary>
    public int? BankIndex { get; init; }
}

/// <summary>
/// One alternative a cue can play.
/// </summary>
/// <remarks>
/// <c>SurfaceType</c> is the game's own <see cref="MaterialVisualType"/> for this alternative,
/// exported under its declared name. <b>Nothing here selects by it.</b> The identity of the field is
/// confirmed, but that the runtime dispatches on it is only <c>LIKELY</c> — <c>PickSoundToPlay</c> is
/// native and its body cannot be read. See <c>docs/research/audio.md</c>.
/// </remarks>
public sealed record AudioAlternativeDocument
{
    public required string Wave { get; init; }

    /// <summary>The logical audio unit the game files this sample under. Not a bank filename.</summary>
    public string? Unit { get; init; }

    public byte? SurfaceTypeValue { get; init; }
    public string? SurfaceType { get; init; }
}

/// <summary>
/// One shipped <c>SoundEffectSpecification</c>, in the shape a UE5 <c>USoundCue</c> wants.
/// </summary>
/// <remarks>
/// <para>
/// A null field means the object did not serialize it and the script-class default stands
/// (<c>OuterRadius=3000</c>, <c>Volume=100</c>, <c>Pitch=1</c>). <b>Absence is never written as a
/// zero</b>, because an importer cannot tell those apart afterwards and would silently mute or
/// un-attenuate whatever it guessed wrong.
/// </para>
/// <para>
/// <b>Selection weight is deliberately absent from this document.</b> <c>Chance</c> is a property of
/// an <c>EventResponse_SoundEffectsSubsystem</c> and is parallel to that response's list of
/// <i>specifications</i> — it chooses which cue fires, not which sample inside one. Putting it here
/// would move it down a level and misrepresent what the game declares. How a cue picks among its own
/// alternatives is not decoded.
/// </para>
/// </remarks>
public sealed record AudioCueDocument
{
    public required string Name { get; init; }

    // Attenuation.
    public float? InnerRadius { get; init; }
    public float? OuterRadius { get; init; }
    public bool? Is2DPositional { get; init; }
    public bool? AttachToSource { get; init; }

    // Level and pitch.
    public int? Volume { get; init; }
    public byte? VolumeCategory { get; init; }
    public AudioRangeDocument? VolumeRange { get; init; }
    public float? Pitch { get; init; }
    public AudioRangeDocument? PitchRange { get; init; }

    // Timing and looping.
    public AudioRangeDocument? DelayRange { get; init; }
    public float? FadeInTime { get; init; }
    public float? FadeOutTime { get; init; }
    public AudioRangeDocument? Monoloop { get; init; }
    public AudioRangeDocument? PolyloopRange { get; init; }
    public int? LoopSoundLimit { get; init; }
    public bool? NeverRepeat { get; init; }
    public bool? NoRepeat { get; init; }
    public bool? Retriggerable { get; init; }
    public bool? PlayOnce { get; init; }

    public required IReadOnlyList<AudioAlternativeDocument> Alternatives { get; init; }
}

/// <summary>What a placed sound actor plays, so a level import can wire audio to a position.</summary>
public sealed record AudioActorDocument
{
    public required string Actor { get; init; }
    public required string ClassName { get; init; }

    /// <summary><c>direct</c> or <c>spawnedEvent</c> — which of the game's two routes resolved it.</summary>
    public required string Route { get; init; }

    public required string MatchedName { get; init; }
    public required IReadOnlyList<string> Cues { get; init; }
}

/// <summary>The audio half of a package's UE5 import set.</summary>
public sealed record AudioManifest
{
    /// <summary>Schema version. Bump only for incompatible changes.</summary>
    public int Version { get; init; } = AudioExporter.ManifestVersion;

    public required string SourcePackage { get; init; }

    public required IReadOnlyList<AudioWaveDocument> Waves { get; init; }
    public required IReadOnlyList<AudioCueDocument> Cues { get; init; }
    public required IReadOnlyList<AudioActorDocument> Actors { get; init; }

    /// <summary>
    /// Sample names a cue references that no shipped store holds.
    /// </summary>
    /// <remarks>
    /// Reported rather than dropped. With a full <see cref="AudioSampleLocator"/> there are exactly
    /// <b>four</b> game-wide, and they read as references to cut content — see
    /// <c>docs/research/audio.md</c>. An importer should skip them and say so, not substitute
    /// silence for a sample it never had. <b>Without a locator this list is not a finding</b>: it is
    /// simply everything the package does not hold itself.
    /// </remarks>
    public required IReadOnlyList<string> UnresolvedSamples { get; init; }
}

/// <summary>
/// Writes a package's audio as a UE5 <c>SoundWave</c>/<c>SoundCue</c> manifest, keeping the shipped
/// payloads byte-for-byte. ROADMAP Gate 4 item 2.
/// </summary>
/// <remarks>
/// <para>
/// The mapping is close to one-to-one because BioShock's own structure already is one: a
/// <c>SoundEffectSpecification</c> carries alternatives, attenuation radii, volume and pitch ranges
/// and looping state — which is what a <c>USoundCue</c> is made of. Nothing here invents a graph the
/// game does not declare.
/// </para>
/// <para>
/// <b>This writes what one package declares.</b> Native <c>Sound</c> payloads are written; streamed
/// samples are located but not decoded unless asked for, because the full bank sweep is slow and the
/// project has a standing instruction against starting large extractions implicitly.
/// </para>
/// </remarks>
public static class AudioExporter
{
    private static readonly JsonSerializerOptions ManifestOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    public const string ManifestFileName = "ue5_audio_manifest.json";

    /// <summary>Schema version of <see cref="ManifestFileName"/>.</summary>
    /// <remarks><b>1</b> — cues, native waves, located streamed waves, and resolved actors.</remarks>
    public const int ManifestVersion = 1;

    /// <summary>Sub-directory the native payloads are written into, relative to the manifest.</summary>
    public const string WaveDirectoryName = "waves";

    /// <summary>
    /// Builds the manifest for a package without writing anything.
    /// </summary>
    /// <param name="locator">
    /// Where samples this package does not itself hold are shipped. <b>Pass one.</b> Without it,
    /// every sample living in another store is reported as unresolved - 908 of them for
    /// <c>0-Lighthouse</c> alone - which reads as missing audio when it is nothing of the kind.
    /// It is optional only so that a caller wanting one package's own payloads need not pay for a
    /// whole-game index.
    /// </param>
    public static AudioManifest Build(
        BioShockPackage package,
        string packageName,
        AudioSampleLocator? locator = null)
    {
        var specifications = SoundEffectSpecificationReader.Read(package);

        var cues = specifications
            .Select(ToCue)
            .OrderBy(cue => cue.Name, StringComparer.Ordinal)
            .ToList();

        var referenced = new HashSet<string>(
            specifications.SelectMany(specification => specification.SoundSpecs)
                .Select(entry => entry.SoundName)
                .Where(name => !string.IsNullOrEmpty(name))
                .Select(name => name!),
            StringComparer.OrdinalIgnoreCase);

        var nativeByName = SoundReader.Read(package)
            .GroupBy(sound => sound.Name, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(group => group.Key, group => group.First(), StringComparer.OrdinalIgnoreCase);

        var waves = new List<AudioWaveDocument>();
        var unresolved = new List<string>();
        foreach (string name in referenced.OrderBy(name => name, StringComparer.Ordinal))
        {
            if (nativeByName.TryGetValue(name, out var sound))
            {
                waves.Add(new AudioWaveDocument
                {
                    Name = sound.Name,
                    Source = "ThisPackage",
                    File = $"{WaveDirectoryName}/{SanitizeFileName(sound.Name)}{Extension(sound)}",
                    Format = sound.Format == SoundFormat.Mp3 ? "mp3" : null,
                });
                continue;
            }

            var location = locator?.Locate(name);
            if (location is not null)
                waves.Add(new AudioWaveDocument
                {
                    Name = name,
                    Source = location.Store,
                    Container = location.Container,
                    BankIndex = location.Index,
                });
            else unresolved.Add(name);
        }

        var index = SoundActorSpecificationIndex.Build(package);
        var context = Level.LevelAnalyzer.Analyze(package);
        var actors = new List<AudioActorDocument>();
        foreach (var actor in context.Actors)
        {
            if (actor.Source.ClassName is not ("AmbientSound" or "SoundMarker" or "MusicBox")) continue;
            var resolution = index.Resolve(actor, package);
            if (!resolution.IsResolved) continue;

            actors.Add(new AudioActorDocument
            {
                Actor = actor.Source.ObjectName,
                ClassName = actor.Source.ClassName,
                Route = resolution.Route == SoundActorRoute.Direct ? "direct" : "spawnedEvent",
                MatchedName = resolution.MatchedName!,
                Cues = resolution.Specifications.Select(specification => specification.SoundName).ToList(),
            });
        }

        return new AudioManifest
        {
            SourcePackage = packageName,
            Waves = waves,
            Cues = cues,
            Actors = actors,
            UnresolvedSamples = unresolved,
        };
    }

    /// <summary>
    /// Writes the manifest and every native payload it names, and returns the manifest path.
    /// </summary>
    public static string Write(
        BioShockPackage package,
        string packageName,
        string directory,
        AudioSampleLocator? locator = null)
    {
        var manifest = Build(package, packageName, locator);

        Directory.CreateDirectory(directory);
        string waveDirectory = Path.Combine(directory, WaveDirectoryName);

        var nativeNames = new HashSet<string>(
            manifest.Waves.Where(wave => wave.Source == "ThisPackage").Select(wave => wave.Name),
            StringComparer.OrdinalIgnoreCase);
        foreach (var sound in SoundReader.Read(package))
            if (nativeNames.Contains(sound.Name))
                SoundExporter.Write(sound, waveDirectory);

        string path = Path.Combine(directory, ManifestFileName);
        File.WriteAllText(path, JsonSerializer.Serialize(manifest, ManifestOptions));
        return path;
    }

    private static AudioCueDocument ToCue(SoundEffectMetadata metadata) => new()
    {
        Name = metadata.SoundName,
        InnerRadius = metadata.InnerRadius,
        OuterRadius = metadata.OuterRadius,
        Is2DPositional = metadata.Is2DPositional,
        AttachToSource = metadata.AttachToSource,
        Volume = metadata.Volume,
        VolumeCategory = metadata.VolumeCategory,
        VolumeRange = Range(metadata.VolumeRange),
        Pitch = metadata.Pitch,
        PitchRange = Range(metadata.PitchRange),
        DelayRange = Range(metadata.DelayRange),
        FadeInTime = metadata.FadeInTime,
        FadeOutTime = metadata.FadeOutTime,
        Monoloop = Range(metadata.Monoloop),
        PolyloopRange = Range(metadata.Polyloop?.Range),
        LoopSoundLimit = metadata.Polyloop?.LoopSoundLimit,
        NeverRepeat = metadata.NeverRepeat,
        NoRepeat = metadata.NoRepeat,
        Retriggerable = metadata.Retriggerable,
        PlayOnce = metadata.PlayOnce,
        Alternatives = metadata.SoundSpecs
            .Where(entry => !string.IsNullOrEmpty(entry.SoundName))
            .Select(entry => new AudioAlternativeDocument
            {
                Wave = entry.SoundName!,
                Unit = entry.SoundUnit,
                SurfaceTypeValue = entry.Flag,
                SurfaceType = entry.MaterialVisualType()?.ToString(),
            })
            .ToList(),
    };

    private static AudioRangeDocument? Range(SoundEffectRange? range) =>
        range is null ? null : new AudioRangeDocument(range.Min, range.Max);

    private static string Extension(BioShockSound sound) => sound.Format == SoundFormat.Mp3 ? ".mp3" : ".bin";

    private static string SanitizeFileName(string value)
    {
        foreach (char invalid in Path.GetInvalidFileNameChars())
            value = value.Replace(invalid, '_');
        return value;
    }
}
