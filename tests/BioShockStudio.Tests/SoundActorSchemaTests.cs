using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What a sound-bearing actor actually declares - which is not what Gate 4 item 1 assumed.
/// </summary>
/// <remarks>
/// <para>
/// Gate 4 item 1 asks for "chance/variation, attenuation, pitch/volume" on sound actors.
/// <b>None of those exist.</b> Across all 21 maps, 3,247 sound-bearing actors
/// (<c>AmbientSound</c> 2,893, <c>SoundMarker</c> 352, <c>MusicBox</c> 2) and <b>not one carries
/// <c>SoundVolume</c>, <c>SoundPitch</c>, <c>SoundRadius</c> or an <c>AmbientSound</c> object
/// property</b>. They carry position, <c>Tag</c>, <c>Label</c>, <c>Region</c> and little else.
/// </para>
/// <para>
/// <b>The link to audio is by name, not by reference.</b> <c>AmbientSound</c> actors name their
/// sound through <c>Tag</c>/<c>Label</c> (<c>2_sixtywattlight</c>, <c>1_water_lapping</c>,
/// <c>sparksloop</c>), and <c>SoundMarker</c> carries <c>Schema1</c>/<c>Schema2</c> naming audio
/// schemas (<c>ambience_5_oneOff_machine</c>, <c>ambience_9_mainroom</c>,
/// <c>ambience_4_beckoning</c>). Only <b>7 of 3,247</b> tags name a <c>Sound</c> object present in
/// the same package, so resolution happens through the sound-event system rather than through the
/// level package - which <c>docs/research/audio.md</c> SS4 already records as the standing blocker.
/// </para>
/// <para>
/// This test therefore pins <i>what the actors do and do not carry</i>, which is the part that is
/// byte-backed. It deliberately does not chase where <c>ambience_*</c> resolves: that is the audio
/// track, worked concurrently by another session.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SoundActorSchemaTests(GameFixture game)
{
    [RequiresGameFact]
    public void MedicalSoundMarkersAreClassifiedByTheirDecodedSchemaNames()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var markers = context.Actors.Where(actor => actor.Source.ClassName == "SoundMarker").ToList();

        Assert.Equal(36, markers.Count);
        var withSchema = markers.Where(marker =>
            marker.Properties.Any(property => property.Name is "Schema1" or "Schema2")).ToList();
        Assert.Equal(26, withSchema.Count);
        Assert.All(withSchema, marker =>
        {
            var schemaProperties = marker.Properties.Where(property => property.Name is "Schema1" or "Schema2").ToList();
            Assert.All(schemaProperties, property => Assert.False(string.IsNullOrWhiteSpace(PropertyValues.AsName(property, package))));
        });

        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(345, coverage.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.AudioPending)));
        Assert.Equal(0, Assert.Single(coverage.Classes, row => row.ClassName == "SoundMarker")
            .StatusCounts.GetValueOrDefault(LevelActorCoverage.Unclassified));
    }

    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void CensusSoundActorProperties()
    {
        var properties = new Dictionary<string, int>(StringComparer.Ordinal);
        var classes = new Dictionary<string, int>(StringComparer.Ordinal);
        var values = new Dictionary<string, Dictionary<string, int>>(StringComparer.Ordinal);
        int soundActors = 0;
        var samples = new List<string>();
        var tags = new Dictionary<string, int>(StringComparer.Ordinal);
        var labels = new Dictionary<string, int>(StringComparer.Ordinal);
        var schemas = new Dictionary<string, int>(StringComparer.Ordinal);
        int tagged = 0, tagResolves = 0;
        var unresolvedTags = new List<string>();

        string[] interesting = ["SoundVolume", "SoundPitch", "SoundRadius", "AmbientSound", "SoundOcclusion"];

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);

            // Every Sound export in this package, by name, to test whether an AmbientSound actor's
            // Tag names a real sound rather than merely looking like one.
            var soundNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var e in package.Exports)
                if (package.GetClassName(e).Contains("Sound", StringComparison.OrdinalIgnoreCase))
                    soundNames.Add(e.ObjectName);
            foreach (var im in package.Imports)
                if (im.ClassName.Contains("Sound", StringComparison.OrdinalIgnoreCase))
                    soundNames.Add(im.ObjectName);

            LevelContext context;
            try { context = LevelAnalyzer.Analyze(package); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            foreach (var actor in context.Actors)
            {
                bool hasSound = actor.Source.ClassName.Contains("Sound", StringComparison.OrdinalIgnoreCase)
                                || actor.Source.ClassName.Contains("Ambient", StringComparison.OrdinalIgnoreCase)
                                || actor.Source.ClassName.Contains("Music", StringComparison.OrdinalIgnoreCase);
                if (!hasSound) continue;

                soundActors++;
                classes[actor.Source.ClassName] = classes.GetValueOrDefault(actor.Source.ClassName) + 1;

                if (actor.Tag is { Length: > 0 } t)
                {
                    tags[t] = tags.GetValueOrDefault(t) + 1;
                    tagged++;
                    if (soundNames.Contains(t)) tagResolves++;
                    else if (unresolvedTags.Count < 10) unresolvedTags.Add($"{Path.GetFileNameWithoutExtension(map)}/{t}");
                }
                if (actor.Label is { Length: > 0 } l) labels[l] = labels.GetValueOrDefault(l) + 1;

                foreach (var p in actor.Properties)
                {
                    if (p.Name is "Schema1" or "Schema2")
                    {
                        string sv = PropertyValues.AsName(p, package) ?? "<unreadable>";
                        schemas[$"{p.Name}={sv}"] = schemas.GetValueOrDefault($"{p.Name}={sv}") + 1;
                    }

                    properties[$"{p.Name} ({p.Type})"] = properties.GetValueOrDefault($"{p.Name} ({p.Type})") + 1;

                    if (!interesting.Contains(p.Name)) continue;

                    string v = p.Type switch
                    {
                        UnrealPropertyType.Byte => p.AsByte().ToString(),
                        UnrealPropertyType.Float => p.AsFloat().ToString("F3"),
                        UnrealPropertyType.Int => p.AsInt().ToString(),
                        UnrealPropertyType.Object when p.TryAsObjectReference(out var r)
                            && r.IsExport && r.ExportIndex < package.Exports.Count
                            => $"-> {package.GetClassName(package.Exports[r.ExportIndex])}",
                        UnrealPropertyType.Object => "-> import/null",
                        _ => $"({p.Value.Length} bytes)",
                    };

                    if (!values.TryGetValue(p.Name, out var hist))
                        values[p.Name] = hist = new Dictionary<string, int>(StringComparer.Ordinal);
                    hist[v] = hist.GetValueOrDefault(v) + 1;
                }

                if (samples.Count < 8)
                    samples.Add($"{actor.Source.ClassName}/{actor.Source.ObjectName}: "
                        + string.Join(", ", actor.Properties.Select(p => $"{p.Name}({p.Type})")));
            }
        }

        Log($"{soundActors:N0} sound-bearing actors");
        Log("  classes:");
        foreach (var (n, c) in classes.OrderByDescending(x => x.Value).Take(12)) Log($"    {n,-30} {c,6:N0}");
        Log("  properties:");
        foreach (var (n, c) in properties.OrderByDescending(x => x.Value).Take(22)) Log($"    {n,-34} {c,6:N0}");
        foreach (var (name, hist) in values.OrderBy(x => x.Key, StringComparer.Ordinal))
        {
            Log($"  {name} values (top 8 of {hist.Count}):");
            foreach (var (v, c) in hist.OrderByDescending(x => x.Value).Take(8)) Log($"    {v,-18} {c,6:N0}");
        }
        Log($"  tags that name a real Sound object: {tagResolves:N0} of {tagged:N0}");
        foreach (string u in unresolvedTags) Log($"    unresolved: {u}");
        Log("  Tag values on sound actors (top 20):");
        foreach (var (v, c) in tags.OrderByDescending(x => x.Value).Take(20)) Log($"    {v,-42} {c,5}");
        Log("  Label values (top 10):");
        foreach (var (v, c) in labels.OrderByDescending(x => x.Value).Take(10)) Log($"    {v,-42} {c,5}");
        Log("  Schema1/Schema2 values (top 20):");
        foreach (var (v, c) in schemas.OrderByDescending(x => x.Value).Take(20)) Log($"    {v,-42} {c,5}");

        Assert.True(soundActors > 3_000, $"only {soundActors} sound-bearing actors were found");

        // THE CORRECTION: the properties the roadmap item names are simply not there.
        foreach (string absent in new[] { "SoundVolume", "SoundPitch", "SoundRadius", "AmbientSound" })
            Assert.False(properties.Keys.Any(k => k.StartsWith(absent + " (", StringComparison.Ordinal)),
                $"{absent} is declared after all, so it need not be recovered by name");

        // What IS there: names. SoundMarker's schema pair is the newly surfaced vocabulary.
        Assert.True(schemas.Count > 50, $"only {schemas.Count} distinct Schema1/Schema2 values");
        Assert.Contains(schemas.Keys, k => k.Contains("ambience_", StringComparison.Ordinal));

        // ...and those names do not resolve locally, which is why the audio chain is the blocker.
        Assert.True(tagResolves < tagged / 100,
            $"{tagResolves} of {tagged} tags resolve to a local Sound object, so resolution is local "
            + "after all and the sound-event route is not needed");
    }
}
