using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Audio;

/// <summary>One exact FMOD-reported stream location, including its shipped language bank.</summary>
public sealed record StreamSampleLocation(StreamBank Bank, int Index, string Name, string Language);

/// <summary>An immutable exact-name index over every shipped FSB5 bank.</summary>
public sealed class StreamSampleCatalog
{
    private readonly IReadOnlyDictionary<string, IReadOnlyList<StreamSampleLocation>> _byName;

    private StreamSampleCatalog(
        IReadOnlyList<StreamSampleLocation> locations,
        IReadOnlyDictionary<string, IReadOnlyList<StreamSampleLocation>> byName)
    {
        Locations = locations;
        _byName = byName;
    }

    public IReadOnlyList<StreamSampleLocation> Locations { get; }
    public int DistinctNameCount => _byName.Count;

    public IReadOnlyList<StreamSampleLocation> Find(string name) =>
        _byName.TryGetValue(name, out var found) ? found : [];

    public static async Task<StreamSampleCatalog> BuildAsync(
        string gameRoot, CancellationToken cancellation = default)
    {
        var service = new StreamAudioService();
        var locations = new List<StreamSampleLocation>();
        foreach (var bank in service.List(gameRoot))
        {
            cancellation.ThrowIfCancellationRequested();
            string language = LanguageFrom(bank.Name);
            foreach (var sample in await service.ListSamplesAsync(gameRoot, bank, cancellation))
                if (!string.IsNullOrWhiteSpace(sample.Name))
                    locations.Add(new StreamSampleLocation(bank, sample.Index, sample.Name, language));
        }

        var byName = locations
            .GroupBy(location => location.Name, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(group => group.Key, group => (IReadOnlyList<StreamSampleLocation>)group.ToList(),
                StringComparer.OrdinalIgnoreCase);
        return new StreamSampleCatalog(locations, byName);
    }

    private static string LanguageFrom(string bankName)
    {
        if (bankName.EndsWith(".fsb", StringComparison.OrdinalIgnoreCase)) return "English";
        int dot = bankName.LastIndexOf('.');
        int suffix = bankName.LastIndexOf("_fsb", StringComparison.OrdinalIgnoreCase);
        return dot >= 0 && suffix > dot ? bankName[(dot + 1)..suffix] : "Unknown";
    }
}

public sealed record AudioActorNameCandidate(string Source, string Name);

public sealed record AudioActorSampleMatch(
    AudioActorNameCandidate Candidate, IReadOnlyList<StreamSampleLocation> Locations);

public sealed record AudioActorResolution(
    SourceId Actor, IReadOnlyList<AudioActorNameCandidate> Candidates,
    IReadOnlyList<AudioActorSampleMatch> Matches)
{
    public bool IsResolved => Matches.Count > 0;
}

/// <summary>Matches only exact actor-declared names to FMOD-reported stream names.</summary>
public static class AudioActorResolver
{
    public static AudioActorResolution Resolve(
        LevelActor actor, BioShockPackage package, StreamSampleCatalog catalog)
    {
        var candidates = new List<AudioActorNameCandidate>();
        void Add(string source, string? name)
        {
            if (string.IsNullOrWhiteSpace(name)) return;
            if (candidates.Any(candidate => candidate.Source == source
                                            && string.Equals(candidate.Name, name, StringComparison.OrdinalIgnoreCase))) return;
            candidates.Add(new AudioActorNameCandidate(source, name));
        }

        Add("Tag", actor.Tag);
        Add("Label", actor.Label);
        foreach (var property in actor.Properties.Where(property => property.Name is "Schema1" or "Schema2"))
            Add(property.Name, PropertyValues.AsName(property, package));

        var matches = candidates
            .Select(candidate => new AudioActorSampleMatch(candidate, catalog.Find(candidate.Name)))
            .Where(match => match.Locations.Count > 0)
            .ToList();
        return new AudioActorResolution(actor.Source, candidates, matches);
    }
}
