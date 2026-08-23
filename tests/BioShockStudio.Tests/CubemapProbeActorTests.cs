using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// <c>CubemapProbe</c> actors: the level's answer to "which cubemap does a surface reflect?"
/// </summary>
/// <remarks>
/// <para>
/// Closes a question left <c>UNKNOWN</c> earlier the same day. The material side was censused first
/// (<c>docs/research/materials.md</c>): across all 33 packages, <b>no material anywhere binds a
/// cubemap object</b> - materials only declare <i>that</i> they want a specular cubemap
/// (<c>UseSpecularCubemaps</c>) and <i>how strongly</i>, never <i>which</i>. The conclusion recorded
/// then was that cubemap identity must live in the level rather than the material.
/// </para>
/// <para>
/// <b>It does.</b> The level places <c>CubemapProbe</c> actors, each naming a <c>Cubemap</c> and
/// carrying a world position - which is UE5's reflection-capture model almost exactly, and makes
/// this directly bridgeable rather than merely decoded.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class CubemapProbeActorTests(GameFixture game)
{
    [RequiresGameFact]
    public void EveryMedicalProbeReachesTheManifestAsAResolvedReflectionCapture()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var probes = context.Actors.Where(actor => actor.Source.ClassName == "CubemapProbe").ToList();

        Assert.Equal(29, probes.Count);
        Assert.All(probes, probe => Assert.Equal(ResolutionStatus.Resolved, probe.Cubemap?.Status));
        var coverage = LevelCoverageReport.Build(context);
        Assert.Equal(29, coverage.Classes.Sum(row => row.ClassName == "CubemapProbe"
            ? row.StatusCounts.GetValueOrDefault(LevelActorCoverage.ReflectionProbePending) : 0));

        var document = BioShockStudio.Core.Export.LevelSceneExporter.ToDocument(
            LevelSceneBuilder.Build(package, context), includeGeometry: false);
        var exported = document.Actors.Where(actor => actor.ClassName == "CubemapProbe").ToList();
        Assert.Equal(probes.Count, exported.Count);
        Assert.All(exported, probe => Assert.Equal(nameof(ResolutionStatus.Resolved), probe.Cubemap?.Status));
    }

    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void EveryCubemapProbeNamesACubemapAndAPosition()
    {
        int probes = 0, shown = 0;
        var propertyNames = new Dictionary<string, int>(StringComparer.Ordinal);
        var targets = new Dictionary<string, int>(StringComparer.Ordinal);

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);

            LevelContext context;
            try { context = LevelAnalyzer.Analyze(package); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            foreach (var actor in context.Actors)
            {
                if (actor.Source.ClassName != "CubemapProbe") continue;
                probes++;

                foreach (var p in actor.Properties)
                {
                    propertyNames[$"{p.Name} ({p.Type})"] = propertyNames.GetValueOrDefault($"{p.Name} ({p.Type})") + 1;

                    if (p.Type != UnrealPropertyType.Object) continue;
                    if (!p.TryAsObjectReference(out var r)) continue;

                    string what = "unresolved";
                    if (r.IsExport && r.ExportIndex < package.Exports.Count)
                    {
                        var t = package.Exports[r.ExportIndex];
                        what = $"export {package.GetClassName(t)}";
                        if (shown < 10)
                        {
                            Log($"    {actor.Source.ObjectName} .{p.Name} -> {package.GetClassName(t)} '{t.ObjectName}' "
                                + $"@ {actor.Transform.Location}");
                            shown++;
                        }
                    }
                    else if (r.IsImport) what = "import";

                    targets[$"{p.Name} -> {what}"] = targets.GetValueOrDefault($"{p.Name} -> {what}") + 1;
                }
            }
        }

        Log($"{probes} CubemapProbe actors");
        Log("  properties:");
        foreach (var (n, c) in propertyNames.OrderByDescending(x => x.Value)) Log($"    {n,-40} {c,5}");
        Log("  object property targets:");
        foreach (var (n, c) in targets.OrderByDescending(x => x.Value)) Log($"    {n,-50} {c,5}");

        Assert.True(probes > 0, "no CubemapProbe actors found");

        // Every probe names a cubemap - that is the whole finding, and it holds without exception.
        Assert.Equal(probes, targets.GetValueOrDefault("Cubemap -> export Cubemap"));

        // ...and every one is positioned, since a reflection probe without a position is useless.
        Assert.Equal(probes, propertyNames.GetValueOrDefault("Location (Struct)"));

        // The probes are a meaningful fraction of the game's 287 cubemaps rather than a stray few.
        Assert.InRange(probes, 200, 400);
    }
}
