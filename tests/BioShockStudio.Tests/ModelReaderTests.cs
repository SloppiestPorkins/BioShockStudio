using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Walking a <c>Model</c> to the <c>Polys</c> reference it holds.
/// </summary>
/// <remarks>
/// <para>
/// This is the first time <c>docs/research/bsp.md</c> §5's layout — Nyko's §C.1.1, previously
/// <c>CONFIRMED_EXTERNAL</c> and verified against nothing here — has been run against shipped bytes.
/// </para>
/// <para>
/// <b>The assertion is that the walk lands on a reference resolving to a <c>Polys</c> export.</b>
/// Every array length ahead of that reference is read from the data, so one wrong field size puts
/// the final read at an arbitrary offset; an arbitrary <c>FCompactIndex</c> resolving to an export
/// of exactly the right class, across every map in the game, is not a coincidence available to a
/// wrong layout.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ModelReaderTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void EveryModelInEveryMapWalksToAPolysReference()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int read = 0, empty = 0, resolved = 0, builtWorlds = 0;
        var failures = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            foreach (var export in ModelReader.Enumerate(package))
            {
                BspModel? model;
                try { model = ModelReader.Read(package, export); }
                catch (Exception ex) { failures.Add(ex.Message); continue; }

                if (model is null) { empty++; continue; }
                read++;

                if (ModelReader.ResolvePolys(package, model) is not null) resolved++;
                else failures.Add($"{model.Source}: Polys reference {model.Polys} does not resolve to a Polys export");
            }

            // The compiled world, by the SDK's own rule: the model with the most nodes. Logged with
            // the runner-up, because the claim rests on the gap between them being enormous.
            if (ModelReader.BuiltWorld(package) is { } world)
            {
                builtWorlds++;
                int runnerUp = ModelReader.Enumerate(package)
                    .Select(e => { try { return ModelReader.Read(package, e)?.NodeCount ?? 0; } catch { return 0; } })
                    .OrderByDescending(n => n).Skip(1).FirstOrDefault();
                Log($"  {world.Source.Package}: world {world}, next largest {runnerUp} nodes");
            }
        }

        Log($"Models read {read}, empty {empty}, resolving a Polys export {resolved}, built worlds {builtWorlds}");
        foreach (string failure in failures.Take(15)) Log("  FAILED " + failure);

        Assert.True(failures.Count == 0,
            $"{failures.Count} of {read} Model exports did not reach a Polys reference:"
            + Environment.NewLine + string.Join(Environment.NewLine, failures.Take(10)));

        Assert.Equal(read, resolved);
        Assert.True(read > 1000, $"only {read} Model exports were read across {maps.Count} maps");

        // Exactly one compiled world per map that has one — the 8 MB container beside the brushes.
        Assert.True(builtWorlds > 0, "no map declared a built world, so the node array is never being read");
    }

    /// <summary>
    /// The export table does <b>not</b> state the model → polys link, which is why
    /// <see cref="ModelReader"/> exists at all.
    /// </summary>
    /// <remarks>
    /// A negative result, kept as a test rather than only as a sentence in the notes. Walking
    /// <c>UModel</c>'s body is real work, and the obvious cheaper routes — the outer link, or index
    /// adjacency — have to be shown not to work or a later session will try them again. If this ever
    /// starts failing because the outer link became reliable, that is worth knowing: the reader
    /// could be simplified.
    /// </remarks>
    [RequiresGameFact]
    public void TheExportTableDoesNotStateTheModelToPolysLink()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var polys = package.Exports.Where(e => package.GetClassName(e) == PolysReader.ClassName).ToList();
        Assert.Equal(285, polys.Count);

        string OuterClass(ObjectExport e) =>
            e.OuterIndex.IsExport && e.OuterIndex.ExportIndex < package.Exports.Count
                ? package.GetClassName(package.Exports[e.OuterIndex.ExportIndex])
                : "(none)";

        var byOuter = polys.GroupBy(OuterClass).ToDictionary(g => g.Key, g => g.Count());
        Log("Polys outer classes: " + string.Join(", ", byOuter.Select(e => $"{e.Key}={e.Value}")));

        // Most do not have a Model as their outer, and a good many name something unrelated.
        Assert.True(byOuter.GetValueOrDefault(ModelReader.ClassName) < polys.Count / 2,
            "the outer link now reaches a Model for most Polys exports; the reader could be simpler");
        Assert.True(byOuter.ContainsKey("SkeletalMesh"),
            "no Polys export has a SkeletalMesh outer any more; re-check whether the outer link is usable");

        // Nor is a Polys simply the export after its Model.
        int adjacent = package.Exports
            .Where(e => package.GetClassName(e) == ModelReader.ClassName)
            .Count(m => m.Index + 1 < package.Exports.Count
                        && package.GetClassName(package.Exports[m.Index + 1]) == PolysReader.ClassName);
        Assert.Equal(0, adjacent);
    }

    /// <summary>
    /// The link this reader exists for: every brush actor reaches real geometry.
    /// </summary>
    /// <remarks>
    /// The export table does not state it — of 285 <c>Polys</c> exports in <c>0-Lighthouse</c> only
    /// 60 have a <c>Model</c> outer, 54 have a <c>SkeletalMesh</c>, and 171 have none. Going through
    /// <c>UModel</c>'s body is what closes actor → model → polygons.
    /// </remarks>
    [RequiresGameFact]
    public void EveryBrushActorReachesItsPolygons()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);

        int brushes = 0, reached = 0, polygons = 0;

        foreach (var actor in context.Brushes)
        {
            if (actor.Brush?.Source is not { } source) continue;
            brushes++;

            var model = ModelReader.Read(package, package.Exports[source.ExportIndex]);
            if (model is null) continue;
            if (ModelReader.ResolvePolys(package, model) is not { } polysExport) continue;

            reached++;
            polygons += PolysReader.Read(package, polysExport).Polygons.Count;
        }

        Log($"brush actors {brushes}, reaching polygons {reached}, total polygons {polygons}");

        Assert.Equal(230, brushes);
        Assert.Equal(brushes, reached);
        Assert.True(polygons > 1000, $"only {polygons} polygons across {reached} brushes");
    }
}
