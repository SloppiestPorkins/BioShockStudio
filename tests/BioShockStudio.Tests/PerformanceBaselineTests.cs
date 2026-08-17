using System.Diagnostics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What the expensive operations actually cost, measured rather than assumed.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is a measurement, not a gate.</b> Timings depend on the machine and on the file cache,
/// so the assertions are deliberately loose ceilings that only catch an order-of-magnitude
/// regression — a change that makes opening a package take a second, not one that makes it take
/// 12 ms instead of 9. The numbers themselves go to <c>BIOSHOCK_PROBE_LOG</c>, and the point of
/// having them is that "before optimising, measure" has something to compare against.
/// </para>
/// <para>
/// Every figure is a median of repeated runs after a warm-up, because the first read of a 200 MB
/// package measures the operating system's file cache rather than this code.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class PerformanceBaselineTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>Median milliseconds over <paramref name="runs"/>, after one warm-up.</summary>
    private static double Median(int runs, Action work)
    {
        work();

        var times = new List<double>(runs);
        for (int i = 0; i < runs; i++)
        {
            var watch = Stopwatch.StartNew();
            work();
            watch.Stop();
            times.Add(watch.Elapsed.TotalMilliseconds);
        }

        times.Sort();
        return times[times.Count / 2];
    }

    [RequiresGameFact]
    public void TheCostOfOpeningAPackageAndReadingFromItIsRecorded()
    {
        string lighthouse = game.LighthousePackage;
        string entry = game.EntryPackage;

        double smallOpen = Median(20, () => BioShockPackage.Open(entry).Dispose());
        double largeOpen = Median(20, () => BioShockPackage.Open(lighthouse).Dispose());

        using var package = BioShockPackage.Open(lighthouse);

        // The most-decoded thing in the application: a static mesh's geometry.
        var mesh = package.Exports.FirstOrDefault(e =>
            package.GetClassName(e) == "StaticMesh" && e.SerialSize > 200_000);

        double meshRead = 0, meshDecode = 0;
        if (mesh is not null)
        {
            meshRead = Median(10, () => package.ReadExportData(mesh));
            byte[] payload = package.ReadExportData(mesh);
            meshDecode = Median(10, () => StaticMeshReader.ReadGeometry(payload));
        }

        // The level analyzer, which the Level tab runs on every map selection.
        double analyze = Median(3, () => LevelAnalyzer.Analyze(package));

        Log("--- performance baseline, medians in ms ---");
        Log($"  open Entry.bsm            ({new FileInfo(entry).Length / 1024 / 1024,4} MB)  {smallOpen,8:0.###}");
        Log($"  open 0-Lighthouse.bsm     ({new FileInfo(lighthouse).Length / 1024 / 1024,4} MB)  {largeOpen,8:0.###}");
        Log($"  read one large mesh payload                {meshRead,8:0.###}");
        Log($"  decode that mesh's geometry                {meshDecode,8:0.###}");
        Log($"  analyze the level's actors                 {analyze,8:0.###}");
        Log($"  Lighthouse: {package.Exports.Count:N0} exports, {package.Names.Count:N0} names");

        // Order-of-magnitude ceilings only. These exist so a change that makes opening a package
        // pathological fails here rather than being noticed as "the app feels slow".
        Assert.True(largeOpen < 2_000, $"opening a map package takes {largeOpen:0} ms");
        Assert.True(analyze < 60_000, $"analyzing a level's actors takes {analyze:0} ms");
    }

    /// <summary>
    /// How much of a package selection's cost is re-parsing the package's tables.
    /// </summary>
    /// <remarks>
    /// Every service opens a package for itself — <c>Describe</c> then <c>Decode</c> on a texture is
    /// two opens for one selection, and the details, diagnostics and preview services each add
    /// their own. This measures what one open costs against what the work inside it costs, which is
    /// the number that says whether a shared package handle is worth building.
    /// </remarks>
    [RequiresGameFact]
    public void TheShareOfATextureSelectionSpentReopeningThePackageIsRecorded()
    {
        string medical = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");

        double open = Median(10, () => BioShockPackage.Open(medical).Dispose());

        using var package = BioShockPackage.Open(medical);
        var texture = package.Exports.FirstOrDefault(e => package.GetClassName(e) == "Texture");
        if (texture is null) return;

        double read = Median(10, () => package.ReadExportData(texture));

        Log($"  open 1-Medical.bsm {open:0.###} ms against {read:0.###} ms to read one texture payload "
            + $"— a selection that opens the package twice spends {open * 2:0.###} ms on tables alone");

        Assert.True(open > 0, "the package open was not measured at all");
    }
}
