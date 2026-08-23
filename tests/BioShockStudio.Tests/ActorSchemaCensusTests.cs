using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Probe: what do the still-open actor categories actually carry?</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ActorSchemaCensusTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void CensusOpenActorCategories()
    {
        var byCategory = new Dictionary<string, Dictionary<string, int>>(StringComparer.Ordinal);
        var categoryCounts = new Dictionary<string, int>(StringComparer.Ordinal);
        var classesByCategory = new Dictionary<string, Dictionary<string, int>>(StringComparer.Ordinal);

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            LevelContext context;
            try { context = LevelAnalyzer.Analyze(map); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            var report = LevelCoverageReport.Build(context);

            foreach (var row in report.Classes)
            {
                foreach (var (status, count) in row.StatusCounts)
                {
                    string key = status.ToString();
                    if (key is not ("AudioPending" or "RegionPending" or "EffectPending" or "MarkerPending" or "Unclassified"))
                        continue;

                    categoryCounts[key] = categoryCounts.GetValueOrDefault(key) + count;

                    if (!classesByCategory.TryGetValue(key, out var classes))
                        classesByCategory[key] = classes = new Dictionary<string, int>(StringComparer.Ordinal);
                    classes[row.ClassName] = classes.GetValueOrDefault(row.ClassName) + count;

                    if (!byCategory.TryGetValue(key, out var props))
                        byCategory[key] = props = new Dictionary<string, int>(StringComparer.Ordinal);

                    foreach (string property in row.OutstandingProperties)
                        props[property] = props.GetValueOrDefault(property) + count;
                }
            }
        }

        foreach (var (category, count) in categoryCounts.OrderByDescending(p => p.Value))
        {
            Log($"=== {category}: {count:N0} actors ===");
            Log("  top classes:");
            foreach (var (name, n) in classesByCategory[category].OrderByDescending(p => p.Value).Take(8))
                Log($"    {name,-34} {n,6:N0}");
            Log("  most common uninterpreted properties:");
            foreach (var (name, n) in byCategory[category].OrderByDescending(p => p.Value).Take(18))
                Log($"    {name,-34} {n,6:N0}");
        }

        Assert.NotEmpty(categoryCounts);
    }
}
