using BioShockStudio.Core.Game;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// How many levels of detail a static mesh actually carries, across the whole game.
/// </summary>
/// <remarks>
/// <para>
/// <b>Gate 1 item 1 listed LODs as unchecked; the reader had been relying on them for longer than
/// that.</b> <c>StaticMeshReader</c> scans every geometry chain in a payload and keeps the densest,
/// on the reasoning that the first one stored is often the crude one — but "a payload holds several
/// levels of detail" was a sentence in a comment, and <c>docs/research/staticmesh.md</c> still had
/// LODs under "still unknown". Neither is evidence. This counts them.
/// </para>
/// <para>
/// <b>The answer: every one of the 8,668 shipped static meshes carries exactly one chain.</b> So
/// "take the densest" was a no-op dressed as a decision, and BioShock Remastered's static meshes
/// ship a single level of detail. That is worth knowing for the UE5 bridge, which would otherwise
/// be built expecting an LOD chain to carry across.
/// </para>
/// <para>
/// <b>What this does and does not rule out.</b> It says no second block satisfies the constraints
/// the reader uses — a UV stream as long as its vertex array, a whole number of triangles, a largest
/// index of <c>vertexCount - 1</c>, unit basis vectors, and every position inside the mesh's own
/// <c>FBox</c>. A cruder LOD stored in a different vertex format would not be found by this, and
/// that remains unexcluded. Five independent constraints agreeing 8,668 times is strong, not
/// absolute.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class StaticMeshLevelOfDetailTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void EveryStaticMeshInTheGameIsCensusedForLevelsOfDetail()
    {
        var counts = new Dictionary<int, int>();
        int meshes = 0, multiLevel = 0, densestIsFirst = 0, densestIsLast = 0;
        long totalLevels = 0;
        var examples = new List<string>();

        foreach (string file in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports)
            {
                if (package.GetClassName(export) != "StaticMesh") continue;

                byte[] payload;
                try { payload = package.ReadExportData(export); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

                var levels = StaticMeshReader.LevelsOfDetail(payload);
                if (levels.Count == 0) continue;

                meshes++;
                totalLevels += levels.Count;
                counts[levels.Count] = counts.GetValueOrDefault(levels.Count) + 1;

                if (levels.Count == 1) continue;
                multiLevel++;

                int densest = 0;
                for (int i = 1; i < levels.Count; i++)
                    if (levels[i].VertexCount > levels[densest].VertexCount) densest = i;

                if (densest == 0) densestIsFirst++;
                if (densest == levels.Count - 1) densestIsLast++;

                if (examples.Count < 10)
                    examples.Add($"    {export.ObjectName,-30} "
                                 + string.Join(" → ", levels.Select(l => $"{l.VertexCount}v/{l.TriangleCount}t")));
            }
        }

        Log($"static meshes with geometry: {meshes:N0}, {totalLevels:N0} chains in total");
        foreach (var (levels, count) in counts.OrderBy(p => p.Key))
            Log($"    {levels} level(s): {count,6:N0} meshes");
        Log($"  of the {multiLevel:N0} with more than one: densest is first {densestIsFirst:N0}, "
            + $"densest is last {densestIsLast:N0}");
        foreach (string line in examples) Log(line);

        Assert.True(meshes > 5_000, $"only {meshes} static meshes yielded geometry");

        // THE ANSWER, and it is the opposite of what the reader's comment assumed: every shipped
        // static mesh carries exactly ONE geometry chain. "Keep looking and take the densest" was
        // choosing between a single candidate on all 8,668 of them.
        //
        // Asserted as the census it is, so a mesh with a second chain would fail here rather than
        // being silently collapsed to whichever is denser.
        Assert.Equal(0, multiLevel);
        Assert.Equal(meshes, (int)totalLevels);
    }
}
