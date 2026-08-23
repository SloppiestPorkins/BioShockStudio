using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Audio;

/// <summary>How a placed sound actor reached its shipped sound effect specification.</summary>
public enum SoundActorRoute
{
    /// <summary>The actor did not reach one.</summary>
    None = 0,

    /// <summary>One of the actor's own declared names is a <c>SoundEffectSpecification</c>.</summary>
    Direct,

    /// <summary>
    /// The actor's name selects the <c>AmbientSoundSpawned_&lt;name&gt;</c> event response, which
    /// names the specification.
    /// </summary>
    SpawnedEvent,
}

/// <summary>What one placed sound actor resolves to.</summary>
public sealed record SoundActorSpecificationResolution(
    SourceId Actor,
    IReadOnlyList<AudioActorNameCandidate> Candidates,
    SoundActorRoute Route,
    string? MatchedName,
    IReadOnlyList<SoundEffectMetadata> Specifications)
{
    public bool IsResolved => Specifications.Count > 0;

    /// <summary>Every sample name the resolved specifications can play, in shipped order.</summary>
    public IReadOnlyList<string> SampleNames => Specifications
        .SelectMany(specification => specification.SoundSpecs)
        .Select(entry => entry.SoundName)
        .Where(name => !string.IsNullOrEmpty(name))
        .Select(name => name!)
        .ToList();
}

/// <summary>
/// Resolves a placed sound actor to the shipped <c>SoundEffectSpecification</c> objects that carry
/// its volume, attenuation, pitch and sample list.
/// </summary>
/// <remarks>
/// <para>
/// <b>CONFIRMED_BYTES.</b> This is the route <c>docs/research/audio.md</c> SS4 recorded as the
/// blocker. The actors name nothing the level package holds directly — only 7 of 3,247 tags name a
/// <c>Sound</c> export — and matching them against FSB sample names resolves the 177 markers whose
/// names happen to be sample names and no <c>AmbientSound</c> at all. The link the game actually
/// uses is one indirection further out:
/// </para>
/// <code>
/// AmbientSound  Tag "2_sixtywattlight"
///        ↓  the event response named AmbientSoundSpawned_&lt;Tag&gt;
/// EventResponse_SoundEffectsSubsystem  Event "Spawned", SourceClassName "AmbientSound"
///        ↓  its Specification names one
/// SoundEffectSpecification "ambience_2_sixtywattlight"
///        ↓  its SoundSpecs array
/// sample names, in their sound unit
/// </code>
/// <para>
/// The naming is not a resemblance: <b>every one of the 10,360 shipped
/// <c>AmbientSoundSpawned_*</c> responses carries <c>Event == "Spawned"</c> and
/// <c>SourceClassName == "AmbientSound"</c></b>, with no exceptions, which is what makes the prefix
/// structural. <c>SoundMarker</c>s take the other route and name a specification outright through
/// <c>Schema1</c>/<c>Schema2</c>.
/// </para>
/// <para>
/// Matching is exact and nothing is normalised or fuzzily matched. An actor whose only name is a
/// default label (<c>SoundMarker3</c>, <c>AmbientSound</c>) resolves to nothing, and that is
/// reported as unresolved rather than guessed at.
/// </para>
/// </remarks>
public sealed class SoundActorSpecificationIndex
{
    /// <summary>The prefix a spawned-ambience response's object name carries.</summary>
    public const string SpawnedPrefix = "AmbientSoundSpawned_";

    private readonly IReadOnlyDictionary<string, SoundEffectMetadata> _specifications;
    private readonly ILookup<string, SoundEventResponse> _responses;

    private SoundActorSpecificationIndex(
        IReadOnlyDictionary<string, SoundEffectMetadata> specifications,
        ILookup<string, SoundEventResponse> responses)
    {
        _specifications = specifications;
        _responses = responses;
    }

    public int SpecificationCount => _specifications.Count;

    public static SoundActorSpecificationIndex Build(BioShockPackage package)
    {
        var specifications = new Dictionary<string, SoundEffectMetadata>(StringComparer.OrdinalIgnoreCase);
        foreach (var metadata in SoundEffectSpecificationReader.Read(package))
            specifications[metadata.SoundName] = metadata;

        var responses = SoundEventReader.Read(package)
            .ToLookup(response => response.ObjectName, StringComparer.OrdinalIgnoreCase);
        return new SoundActorSpecificationIndex(specifications, responses);
    }

    public SoundActorSpecificationResolution Resolve(LevelActor actor, BioShockPackage package)
    {
        var candidates = Candidates(actor, package);

        foreach (var candidate in candidates)
        {
            if (_specifications.TryGetValue(candidate.Name, out var direct))
                return new SoundActorSpecificationResolution(
                    actor.Source, candidates, SoundActorRoute.Direct, candidate.Name, [direct]);
        }

        foreach (var candidate in candidates)
        {
            var named = _responses[SpawnedPrefix + candidate.Name]
                .SelectMany(response => response.SoundNames)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Select(name => _specifications.GetValueOrDefault(name))
                .Where(metadata => metadata is not null)
                .Select(metadata => metadata!)
                .ToList();
            if (named.Count > 0)
                return new SoundActorSpecificationResolution(
                    actor.Source, candidates, SoundActorRoute.SpawnedEvent, candidate.Name, named);
        }

        return new SoundActorSpecificationResolution(
            actor.Source, candidates, SoundActorRoute.None, null, []);
    }

    /// <summary>
    /// The names an actor declares, in the order the game's own two routes use them. Deduplicated
    /// case-insensitively, because <c>Tag</c> and <c>Label</c> are frequently the same string.
    /// </summary>
    private static IReadOnlyList<AudioActorNameCandidate> Candidates(LevelActor actor, BioShockPackage package)
    {
        var candidates = new List<AudioActorNameCandidate>();
        void Add(string source, string? name)
        {
            if (string.IsNullOrWhiteSpace(name)) return;
            if (candidates.Any(candidate => string.Equals(candidate.Name, name, StringComparison.OrdinalIgnoreCase))) return;
            candidates.Add(new AudioActorNameCandidate(source, name));
        }

        Add("Tag", actor.Tag);
        Add("Label", actor.Label);
        foreach (var property in actor.Properties.Where(property => property.Name is "Schema1" or "Schema2"))
            Add(property.Name, PropertyValues.AsName(property, package));
        return candidates;
    }
}
