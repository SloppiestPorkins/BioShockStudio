using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// How often each scripted <c>Action</c> class is actually used across the shipped maps.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is what turns "port the AI" into a countable, ordered job.</b>
/// <c>docs/UE5_FULL_PORT_PLAN.md</c> Phase 4 implements BioShock's action library by hand in UE5,
/// using the decompiled UnrealScript as the specification. There are 66 <c>Action</c> classes in
/// <c>ShockAI</c> alone and more in <c>Scripting</c>, so the order matters: an action used in
/// hundreds of places earns an implementation long before one used twice.
/// </para>
/// <para>
/// The data was already there. <c>LevelAnalyzer.ScriptActions</c> resolves each <c>Script</c>
/// actor's <c>Actions</c> array to typed class-and-object references; this only counts them.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ActionUsageCensusTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void CensusActionUsageAcrossEveryMap()
    {
        var byClass = new Dictionary<string, int>(StringComparer.Ordinal);
        var byMap = new Dictionary<string, int>(StringComparer.Ordinal);
        long scriptActors = 0, references = 0, incomplete = 0, unresolved = 0;

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            LevelContext context;
            try { context = LevelAnalyzer.Analyze(map); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            string name = Path.GetFileNameWithoutExtension(map);

            foreach (var actor in context.Actors)
            {
                if (actor.ScriptActions is not { } script) continue;

                scriptActors++;
                if (!script.Complete) incomplete++;

                foreach (var action in script.Actions)
                {
                    references++;
                    byMap[name] = byMap.GetValueOrDefault(name) + 1;

                    // An action whose class did not resolve is counted separately rather than
                    // bucketed under a guessed name - the port needs to know what it cannot see.
                    string className = action.ClassName;
                    if (string.IsNullOrEmpty(className))
                    {
                        unresolved++;
                        continue;
                    }

                    byClass[className] = byClass.GetValueOrDefault(className) + 1;
                }
            }
        }

        Log($"{scriptActors:N0} Script actors, {references:N0} action references, "
            + $"{byClass.Count} distinct action classes");
        Log($"  incomplete Actions arrays: {incomplete:N0}; unresolved class names: {unresolved:N0}");
        Log("  action classes by usage (the Phase 4 work order):");
        foreach (var (className, count) in byClass.OrderByDescending(p => p.Value))
            Log($"    {className,-46} {count,6:N0}");
        // The coverage curve is the number that actually sizes Phase 4: how many actions have to
        // be implemented before most of the game's scripted behaviour runs.
        var ordered = byClass.OrderByDescending(p => p.Value).Select(p => p.Value).ToList();
        long resolved = ordered.Sum();
        Log("  coverage curve (the number that sizes the port):");
        foreach (int n in new[] { 5, 10, 20, 30, 50, 75, 100, 150, ordered.Count })
        {
            if (n > ordered.Count) continue;
            long covered = ordered.Take(n).Sum();
            Log($"    top {n,-4} actions -> {covered * 100.0 / resolved,6:F2}% of all references");
        }

        Log("  references per map:");
        foreach (var (name, count) in byMap.OrderByDescending(p => p.Value))
            Log($"    {name,-24} {count,6:N0}");

        Assert.True(scriptActors > 1_000, $"only {scriptActors} Script actors were found");
        Assert.True(references > 1_000, $"only {references} action references were resolved");
        Assert.True(byClass.Count > 10, $"only {byClass.Count} distinct action classes");

        // The long tail is the point: if a handful of classes accounted for everything, the work
        // order would not be worth computing.
        Assert.True(byClass.Values.Max() > byClass.Values.Min(),
            "every action class is used equally often, which would make prioritisation meaningless");

        // Measured 23 Aug 2026: top 20 cover 73%, top 50 cover 90%. Asserted loosely, because the
        // claim being protected is "a small head covers most of the game", not an exact figure.
        var top20 = byClass.OrderByDescending(p => p.Value).Take(20).Sum(p => p.Value);
        Assert.True(top20 * 100.0 / byClass.Values.Sum() > 60,
            "the top 20 actions no longer cover most references, so the port cannot be prioritised "
            + "by usage the way UE5_FULL_PORT_PLAN.md Phase 4 assumes");
    }
}
