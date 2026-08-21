using BioShockStudio.Core.Level;
using BioShockStudio.Core.Game;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Phase 2, first measurement: what the level analyzer actually reports on a shipped map.
/// </summary>
/// <remarks>
/// <para>
/// <c>Core/Level</c> was written before this session and <b>had no test and no caller</b> — nothing
/// in the repository ran it, so its state was unknown rather than good or bad. Phase 2 starts by
/// measuring it rather than by writing more of it, which is the instruction in
/// <c>docs/ENGINEERING_RULES.md</c> §60: the unlock is permission to start the phase, not permission
/// to rewrite what is there.
/// </para>
/// <para>
/// These assertions are deliberately weak. They pin that the analyzer runs on real shipped bytes and
/// reports honestly, <b>not</b> that level extraction works — it does not, and a test claiming
/// otherwise would be the kind of false completeness this project keeps correcting. The numbers it
/// prints under <c>BIOSHOCK_PROBE_LOG</c> are the actual deliverable here.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelAnalysisTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// The analyzer runs on a shipped map and accounts for what it found.
    /// </summary>
    /// <remarks>
    /// The load-bearing assertion is the last one: an actor whose property walk lost alignment must
    /// be reported as failed rather than returned as a half-read actor, because a level made of
    /// silently truncated actors is exactly the plausible-but-wrong result this project exists to
    /// avoid.
    /// </remarks>
    [RequiresGameFact]
    public void TheAnalyzerReadsAShippedLevelAndAccountsForWhatItFound()
    {
        var context = LevelAnalyzer.Analyze(game.LighthousePackage);

        Assert.Equal("0-Lighthouse", context.PackageName);
        Assert.True(context.Actors.Count > 0, "no actors were found in a shipped map package");

        // Every actor has a source and a transform, whatever else did or did not resolve.
        Assert.All(context.Actors, a =>
        {
            Assert.False(string.IsNullOrWhiteSpace(a.Source.ClassName));
            Assert.False(string.IsNullOrWhiteSpace(a.Source.ObjectName));
        });

        // An actor that would not walk is reported, not silently returned half-read.
        Assert.All(context.Actors, a => Assert.False(a.Truncated));

        Log($"=== {context.PackageName}: {context.ExportCount:N0} exports, {context.ImportCount:N0} imports, "
            + $"{context.NameCount:N0} names");
        Log($"    actors                     {context.Actors.Count,7:N0}");
        Log($"    failed to walk             {context.FailedActors.Count,7:N0}");
        Log($"    with a static mesh         {context.WithStaticMesh.Count(),7:N0}");
        Log($"    with a skeletal mesh       {context.WithSkeletalMesh.Count(),7:N0}");
        Log($"    BSP brushes                {context.Brushes.Count(),7:N0}");
        Log($"    lights                     {context.Lights.Count(),7:N0}");
        Log($"    volumes                    {context.Volumes.Count(),7:N0}");
        Log($"    distinct static meshes     {context.StaticMeshUsage.Count,7:N0}");
        Log($"    distinct skeletal meshes   {context.SkeletalMeshUsage.Count,7:N0}");
        Log($"    external references        {context.ExternalReferences.Count,7:N0}");
        Log($"    unresolved references      {context.UnresolvedReferences.Count,7:N0}");
        Log($"    actors with any geometry   {context.Actors.Count(a => a.HasGeometry),7:N0}");

        var (min, max) = LevelAnalyzer.Bounds(context.Actors);
        Log($"    world bounds               ({min.X:0},{min.Y:0},{min.Z:0}) .. ({max.X:0},{max.Y:0},{max.Z:0})");

        Log("    most common classes without geometry:");
        foreach (var (className, count) in context.ClassesWithoutGeometry
                     .OrderByDescending(p => p.Value).Take(12))
        {
            Log($"        {className,-34} {count,6:N0}");
        }

        Log("    most common uninterpreted properties:");
        foreach (var (name, count) in context.UninterpretedProperties
                     .OrderByDescending(p => p.Value).Take(20))
        {
            Log($"        {name,-34} {count,6:N0}");
        }
    }

    /// <summary>
    /// The UE5 backlog is generated from the shipped actor inventory, not maintained as a list of
    /// class-name guesses. Every actor must appear in exactly one coverage status.
    /// </summary>
    [RequiresGameFact]
    public void CoverageLedgerAccountsForEveryShippedActor()
    {
        var context = LevelAnalyzer.Analyze(game.LighthousePackage);
        var report = LevelCoverageReport.Build(context);

        Assert.Equal(context.PackageName, report.PackageName);
        Assert.Equal(context.Actors.Count, report.ActorCount);
        Assert.Equal(report.ActorCount, report.ClassifiedCount);
        Assert.All(report.Classes, row =>
        {
            Assert.True(row.ActorCount > 0, $"empty row for {row.ClassName}");
            Assert.Equal(row.ActorCount, row.StatusCounts.Values.Sum());
        });

        // A map without a geometry-in-scene entry would mean this audit stopped describing the
        // existing exporter, rather than only revealing the work it still has to do.
        Assert.Contains(report.Classes, row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.GeometryInScene) > 0);

        // A volume can own a brush, but that brush is a source/debug shape, not a completed UE5
        // gameplay export. The ledger must keep that distinction visible.
        Assert.True(report.Classes.Sum(row => row.StatusCounts.GetValueOrDefault(LevelActorCoverage.RegionPending)) > 0,
            "the shipped map has no reported gameplay-region actors");

        // These labels come from stored property families, so the roadmap distinguishes an emitter
        // from a navigation node or script rather than leaving all three in one opaque bucket.
        Assert.True(report.Classes.Sum(row => row.StatusCounts.GetValueOrDefault(LevelActorCoverage.EffectPending)) > 0,
            "the shipped map has no decoded emitter placeholders");
        Assert.True(report.Classes.Sum(row => row.StatusCounts.GetValueOrDefault(LevelActorCoverage.NavigationPending)) > 0,
            "the shipped map has no decoded navigation placeholders");
    }

    [RequiresGameFact]
    public void NavigationActorsPreserveTheirPathReferencesAndTypedRadius()
    {
        var context = LevelAnalyzer.Analyze(Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var node = context.Actors.First(actor => actor.Source.ClassName == "FlyingPathNode"
                                                 && actor.Navigation?.PathLinks.Count > 0);

        Assert.NotNull(node.Navigation);
        Assert.NotEmpty(node.Navigation!.PathLinks);
        Assert.All(node.Navigation.PathLinks, link => Assert.NotEqual(0, link.Index.Value));
        Assert.True(node.Navigation.PathCollisionRadius is > 0f);

        // This is not an inferred boolean: the field says that the UE Bool tag was physically
        // serialised, while its raw property remains in the actor document for its value encoding.
        Assert.True(node.Navigation.AutoGeneratedFlagSerialized);
    }

    /// <summary>
    /// A Script actor's Actions property is a compact count followed by exactly that many object
    /// references. The action order and source identity survive analysis; no gameplay behaviour is
    /// inferred from the referenced classes.
    /// </summary>
    [RequiresGameFact]
    public void ScriptActorsPreserveTheirCompleteOrderedActionReferences()
    {
        var context = LevelAnalyzer.Analyze(Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var script = context.Actors.Single(actor => actor.Source.ClassName == "Script"
                                                    && actor.Source.ObjectName == "Script79");

        Assert.NotNull(script.ScriptActions);
        Assert.True(script.ScriptActions!.Complete);
        Assert.Equal(17, script.ScriptActions.Actions.Count);
        Assert.All(script.ScriptActions.Actions, action =>
        {
            Assert.NotEqual(0, action.Index.Value);
            Assert.False(string.IsNullOrWhiteSpace(action.ObjectName));
            Assert.False(string.IsNullOrWhiteSpace(action.ClassName));
        });
    }

    /// <summary>
    /// Effect placements retain the exact template references their Emitters array names. The
    /// template's parameters are intentionally a later decoder; this only proves the placement
    /// graph is not lost or partially accepted.
    /// </summary>
    [RequiresGameFact]
    public void EmitterActorsPreserveTheirCompleteTemplateReferences()
    {
        var context = LevelAnalyzer.Analyze(Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var emitter = context.Actors.Single(actor => actor.Source.ClassName == "BrineOmni"
                                                     && actor.Source.ObjectName == "BrineOmni9");

        Assert.NotNull(emitter.Emitters);
        Assert.True(emitter.Emitters!.Complete);
        var template = Assert.Single(emitter.Emitters.Templates);
        Assert.NotEqual(0, template.Source.Index.Value);
        Assert.False(string.IsNullOrWhiteSpace(template.Source.ObjectName));
        Assert.False(string.IsNullOrWhiteSpace(template.Source.ClassName));
        Assert.True(template.PropertiesComplete);
        Assert.Equal("OceanBrine_O_BSG", template.Material?.ObjectName);
        Assert.Equal(200, template.MaxParticles);
        Assert.Equal(10f, template.ParticlesPerSecond);
        Assert.Equal(10f, template.InitialParticlesPerSecond);
    }
}
