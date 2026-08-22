using BioShockStudio.Core.Game;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// How many skeletal meshes resolve a section table, and whether the two routes to it agree.
/// </summary>
/// <remarks>
/// <para>
/// <b>Gate 1 item 2: the table was reachable only through the socket table.</b> The forward walk
/// starts at the sockets and steps over <c>AttachCoords</c>, the LOD count and the header to reach
/// the sections, so a mesh carrying no sockets — or whose socket names will not resolve — lost its
/// section table for a reason with nothing to do with the sections, and drew entirely in its first
/// material. That is the invisible kind of fault: every count agrees and the mesh is complete, it is
/// just wearing the wrong paint (<c>docs/HANDOFF.md</c> §4).
/// </para>
/// <para>
/// <b>The backward route needs only the geometry.</b> The section array ends exactly where the bone
/// map's count begins, so a candidate count can be tested by whether its own <c>FCompactIndex</c>
/// ends exactly where the array would start.
/// </para>
/// <para>
/// <b>The agreement check is the evidence, not the coverage number.</b> A second locator that found
/// <i>more</i> tables would be worthless if it found different ones; two independent walks — one
/// forward from the sockets, one backward from the bone map — producing byte-identical tables
/// wherever both succeed is what says the new route decodes the same structure rather than something
/// that merely passes the same arithmetic.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SkeletalMeshSectionCoverageTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void BothRoutesToTheSectionTableAgreeAndTogetherCoverMoreMeshes()
    {
        int withGeometry = 0, resolved = 0, forwardOnly = 0, backwardOnly = 0, both = 0, disagreeing = 0;

        // Counted per EXPORT as well as per distinct mesh, because the figure this replaces — 331 of
        // 944 — is a per-export one, and comparing a distinct-mesh count against it would be exactly
        // the sort of denominator swap that makes a number look like progress it has not made.
        int exports = 0, exportsResolved = 0;
        var disagreements = new List<string>();
        var seen = new HashSet<string>(StringComparer.Ordinal);

        // Every package, not just the maps: the first-person weapon viewmodels live in the script
        // packages, and they are exactly the meshes whose section tables matter most.
        var files = GameLocator.EnumeratePackages(game.RequireRoot).ToList();
        if (GameLocator.WeaponPackage(game.RequireRoot) is { } weapons) files.Add(weapons);
        if (Directory.Exists(GameLocator.ScriptPackageDirectory(game.RequireRoot)))
            files.AddRange(Directory.GetFiles(GameLocator.ScriptPackageDirectory(game.RequireRoot), "*.u"));

        foreach (string file in files.OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports)
            {
                if (package.GetClassName(export) != "SkeletalMesh") continue;

                byte[] payload;
                try { payload = package.ReadExportData(export); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

                if (SkeletalMeshReader.DescribeGeometry(payload) is null) continue;

                exports++;
                if (SkeletalMeshSectionReader.Read(payload, package.Names) is not null) exportsResolved++;

                // One row per distinct mesh for everything below: every map embeds its own copy of
                // what it uses, so a per-export count weights a mesh by how many maps contain it.
                if (!seen.Add(export.ObjectName)) continue;

                withGeometry++;

                var forward = SkeletalMeshSectionReader.ReadViaSockets(payload, package.Names);
                var backward = SkeletalMeshSectionReader.ReadViaBoneMap(payload);
                var combined = SkeletalMeshSectionReader.Read(payload, package.Names);

                if (combined is not null) resolved++;
                if (forward is not null && backward is null) forwardOnly++;
                if (forward is null && backward is not null) backwardOnly++;

                if (forward is null || backward is null) continue;
                both++;

                bool same = forward.Count == backward.Count;
                if (same)
                    for (int i = 0; i < forward.Count && same; i++)
                        same = forward[i].MaterialIndex == backward[i].MaterialIndex
                               && forward[i].NumFaces == backward[i].NumFaces
                               && forward[i].FirstFaceInBuffer == backward[i].FirstFaceInBuffer;

                if (!same)
                {
                    disagreeing++;
                    if (disagreements.Count < 12)
                        disagreements.Add($"    {export.ObjectName}: forward {forward.Count} sections, "
                                          + $"backward {backward.Count}");
                }
            }
        }

        Log($"skeletal mesh EXPORTS with geometry: {exports:N0}, "
            + $"{exportsResolved:N0} resolve a section table "
            + $"({(exports == 0 ? 0 : (double)exportsResolved / exports):P1}) — comparable to the old 331 of 944");
        Log($"distinct skeletal meshes with geometry: {withGeometry:N0}");
        Log($"  resolve a section table now: {resolved:N0} "
            + $"({(withGeometry == 0 ? 0 : (double)resolved / withGeometry):P1})");
        Log($"  both routes {both:N0}, forward only {forwardOnly:N0}, backward only {backwardOnly:N0}");
        Log($"  disagreements where both succeeded: {disagreeing:N0}");
        foreach (string line in disagreements) Log(line);

        Assert.True(withGeometry > 100, $"only {withGeometry} distinct skeletal meshes with geometry");

        // The evidence: wherever both routes find a table, it is the same table.
        Assert.Equal(0, disagreeing);

        // The backward route has to be pulling its weight, or it is untested code.
        Assert.True(backwardOnly > 0,
            "the backward route never finds a table the forward one misses, so it adds nothing");

        // Coverage was 331 of 944 EXPORTS (35%) when the socket table was the only way in, so the
        // per-export figure is the one that answers the roadmap.
        Assert.True((double)exportsResolved / exports > 0.90,
            $"only {exportsResolved} of {exports} skeletal mesh exports resolve a section table");
        Assert.True((double)resolved / withGeometry > 0.90,
            $"only {resolved} of {withGeometry} distinct skeletal meshes resolve a section table");
    }
}
