using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Gate 3 item 2's real question: are transforms, base links, draw scale, tags and material
/// overrides read for <b>every</b> actor class, or only the geometry-bearing ones?
/// </summary>
/// <remarks>
/// <c>LevelAnalyzer.BuildActor</c> applies no class filter, so the answer should be "every class".
/// This measures it rather than trusting the code shape, and pins the result so a future filter
/// cannot quietly narrow it.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ActorFieldCoverageTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void EveryActorClassGetsTheSameFieldsRead()
    {
        long actors = 0, withTransform = 0, withTag = 0, withBase = 0, withSkins = 0, withScale = 0;
        var classes = new Dictionary<string, int>(StringComparer.Ordinal);
        var classesWithTransform = new HashSet<string>(StringComparer.Ordinal);
        var classesWithBase = new HashSet<string>(StringComparer.Ordinal);
        var classesWithSkins = new HashSet<string>(StringComparer.Ordinal);

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            LevelContext context;
            try { context = LevelAnalyzer.Analyze(map); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            foreach (var actor in context.Actors)
            {
                actors++;
                string className = actor.Source.ClassName;
                classes[className] = classes.GetValueOrDefault(className) + 1;

                if (!actor.Transform.IsIdentity)
                {
                    withTransform++;
                    classesWithTransform.Add(className);
                }

                if (actor.Transform.DrawScale != 1f || actor.Transform.DrawScale3D != Vector3.One)
                    withScale++;

                if (!string.IsNullOrEmpty(actor.Tag)) withTag++;

                if (actor.Attachment is not null)
                {
                    withBase++;
                    classesWithBase.Add(className);
                }

                if (actor.MaterialOverrides.Count > 0)
                {
                    withSkins++;
                    classesWithSkins.Add(className);
                }
            }
        }

        Log($"{actors:N0} actors across {classes.Count} classes");
        Log($"  non-identity transform: {withTransform:N0} ({classesWithTransform.Count} classes)");
        Log($"  non-unit draw scale:    {withScale:N0}");
        Log($"  tag:                    {withTag:N0}");
        Log($"  base/owner link:        {withBase:N0} ({classesWithBase.Count} classes)");
        Log($"  material overrides:     {withSkins:N0} ({classesWithSkins.Count} classes)");
        Log("  top classes by count:");
        foreach (var (name, count) in classes.OrderByDescending(p => p.Value).Take(20))
            Log($"    {name,-36} {count,6:N0}   transform={classesWithTransform.Contains(name)}");

        Assert.True(actors > 10_000, $"only {actors} actors were analysed");
        Assert.True(classes.Count > 100, $"only {classes.Count} actor classes were seen");

        // The item's own qualifier: this must not be limited to geometry-bearing classes.
        Assert.True(classesWithTransform.Count > 100,
            $"only {classesWithTransform.Count} classes carry a transform");

        // Each of the item's named fields is read somewhere, across many classes.
        Assert.True(withBase > 0 && classesWithBase.Count > 5);
        Assert.True(withSkins > 0);
        Assert.True(withTag > 0);
        Assert.True(withScale > 0);
    }
}
