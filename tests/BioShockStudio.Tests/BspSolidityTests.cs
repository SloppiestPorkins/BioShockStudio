using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Classifying a point against the compiled world's own BSP tree: is it inside architecture, or in
/// the space a player can occupy?
/// </summary>
/// <remarks>
/// <para>
/// <b>This is the ground truth the placement checks were missing.</b> Everything else compares this
/// project against Nyko's level editor, which establishes agreement rather than correctness — if the
/// reference composes a rotation wrongly, matching it reproduces the error. The BSP tree is
/// different in kind: it is the game's own spatial partition, shipped in the package, and it answers
/// a question no reference implementation is involved in.
/// </para>
/// <para>
/// <b>Which side of a leaf is solid is measured, not assumed.</b> Unreal's convention could be
/// stated from memory and would be exactly the sort of inherited claim this project keeps being
/// caught by. Instead the classifier is validated against the game's own answer to "where can a
/// character stand": <c>PathNode</c> actors are the shipped AI navigation graph, so their positions
/// are open space by construction. Whichever leaf side contains them is the empty one.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspSolidityTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// Walks the BSP tree to the leaf containing a point, and reports which side of the last plane
    /// it fell on. <c>true</c> = front leaf.
    /// </summary>
    /// <remarks>
    /// A child index of <c>-1</c> is a leaf — the reference parser's own note
    /// (<c>bsp_parser.cpp</c>: "<c>iFront</c> — front child (-1 = leaf)"). The plane is
    /// <c>dot(n, p) + D = 0</c> with <c>D = -distance</c>, so a non-negative dot puts the point in
    /// front.
    /// </remarks>
    private static bool FrontLeaf(BspWorld world, Vector3 point)
    {
        int index = 0;
        bool front = true;

        // The depth cap is a cycle guard, not a tree-depth assumption: a malformed link would
        // otherwise spin forever, and a silently wrong answer is worse than a bounded one.
        for (int step = 0; step < 512; step++)
        {
            if (index < 0 || index >= world.Nodes.Count) break;
            var node = world.Nodes[index];

            float side = Vector3.Dot(node.Plane.Normal, point) + node.Plane.D;
            front = side >= 0f;

            int next = front ? node.Front : node.Back;
            if (next < 0) break;
            index = next;
        }

        return front;
    }

    /// <summary>
    /// Establishes which leaf side is open space, using the shipped navigation graph.
    /// </summary>
    [RequiresGameFact]
    public void TheOpenSideOfTheTreeIsIdentifiedByTheNavigationGraph()
    {
        int totalNodes = 0, totalFront = 0, maps = 0;

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);
            var built = ModelReader.BuiltWorld(package);
            if (built is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[built.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;

            var context = LevelAnalyzer.Analyze(package);

            // The AI's own walkable points. A PathNode sits slightly above the floor a character
            // stands on, so it is open space by construction.
            var nodes = context.Actors
                .Where(a => a.Source.ClassName is "PathNode" or "PatrolPoint")
                .Where(a => a.Transform.Location != Vector3.Zero)
                .ToList();

            if (nodes.Count < 20) continue;
            maps++;

            int front = nodes.Count(a => FrontLeaf(world, GameBasis.Convert(a.Transform.Location)));
            totalNodes += nodes.Count;
            totalFront += front;

            Log($"  {Path.GetFileNameWithoutExtension(map),-24} {nodes.Count,5} path nodes, "
                + $"{front,5} in a FRONT leaf ({(double)front / nodes.Count:P1})");
        }

        double share = (double)totalFront / totalNodes;
        Log($"{maps} maps, {totalNodes:N0} navigation points, {totalFront:N0} front ({share:P1})");

        Assert.True(maps >= 15, $"only {maps} maps had a navigation graph to check");
        Assert.True(totalNodes > 2_000, $"only {totalNodes} navigation points");

        // The whole point: the navigation graph must land overwhelmingly on ONE side, or the
        // classifier is not classifying anything and every result built on it is meaningless.
        Assert.True(share > 0.90 || share < 0.10,
            $"the navigation graph splits {share:P1}/{1 - share:P1} across the two leaf sides, so "
            + "this classifier does not distinguish solid from open space and must not be used");

        // Established: the FRONT leaf is open space. Anything below depends on this.
        Assert.True(share > 0.90,
            $"only {share:P1} of navigation points are in a front leaf, so 'front means open' — "
            + "which every solidity result below assumes — is not what the shipped data says");
    }

    private static Quaternion Axis(Vector3 axis, float degrees) =>
        Quaternion.CreateFromAxisAngle(axis, degrees * MathF.PI / 180f);

    /// <summary>
    /// Every candidate rotation composition, scored by how much of the game's rotated geometry it
    /// buries inside architecture.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>The test that can actually settle the roll question.</b> A prop stands in a room, against
    /// a wall or on a floor; it does not sit inside the masonry. So the share of a rotated actor's
    /// vertices that land in a solid leaf is a cost that the <i>correct</i> composition minimises,
    /// measured against the game's own spatial partition with no reference implementation involved.
    /// </para>
    /// <para>
    /// <b>Restricted to actors with a non-zero roll</b>, because that is the term in dispute and
    /// every candidate places a yaw-only actor identically — including the majority would dilute the
    /// comparison with actors that cannot distinguish anything, which is what made two earlier
    /// metrics inconclusive.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void EveryCandidateCompositionIsScoredByHowMuchGeometryItBuriesInSolid()
    {
        var candidates = new (string Name, Func<Vector3, Quaternion> Build)[]
        {
            ("shipped   Rz(y) Ry(-p) Rx(r)", d => Axis(Vector3.UnitZ, d.Z) * Axis(Vector3.UnitY, -d.Y) * Axis(Vector3.UnitX, d.X)),
            ("pre-fix   Rz(y) Ry(+p) Rx(r)", d => Axis(Vector3.UnitZ, d.Z) * Axis(Vector3.UnitY, d.Y) * Axis(Vector3.UnitX, d.X)),
            ("neg-roll  Rz(y) Ry(-p) Rx(-r)", d => Axis(Vector3.UnitZ, d.Z) * Axis(Vector3.UnitY, -d.Y) * Axis(Vector3.UnitX, -d.X)),
            ("neg-yaw   Rz(-y) Ry(-p) Rx(r)", d => Axis(Vector3.UnitZ, -d.Z) * Axis(Vector3.UnitY, -d.Y) * Axis(Vector3.UnitX, d.X)),
            ("reversed  Rx(r) Ry(-p) Rz(y)", d => Axis(Vector3.UnitX, d.X) * Axis(Vector3.UnitY, -d.Y) * Axis(Vector3.UnitZ, d.Z)),
            ("rev-negr  Rx(-r) Ry(-p) Rz(y)", d => Axis(Vector3.UnitX, -d.X) * Axis(Vector3.UnitY, -d.Y) * Axis(Vector3.UnitZ, d.Z)),
        };

        var buried = new long[candidates.Length];
        var sampled = new long[candidates.Length];
        int mapsUsed = 0;

        foreach (string mapName in new[] { "1-Medical", "3-Arcadia", "6-Resi", "4-Recreation", "7-Science", "2-Fisheries" })
        {
            string map = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), mapName + ".bsm");
            if (!File.Exists(map)) continue;

            using var package = BioShockPackage.Open(map);
            var built = ModelReader.BuiltWorld(package);
            if (built is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[built.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;

            var context = LevelAnalyzer.Analyze(package);
            var cache = new Dictionary<int, Core.Mesh.MeshGeometry?>();

            var actors = context.WithStaticMesh
                .Where(a => a.Transform.Rotation.Roll != 0 && a.StaticMesh?.Source is not null)
                .Take(400)
                .ToList();
            if (actors.Count == 0) continue;

            mapsUsed++;
            var perMap = new long[candidates.Length];
            long perMapSampled = 0;

            foreach (var actor in actors)
            {
                int export = actor.StaticMesh!.Source!.Value.ExportIndex;
                if (!cache.TryGetValue(export, out var geometry))
                    cache[export] = geometry = Core.Mesh.StaticMeshReader.ReadGeometry(
                        package.ReadExportData(package.Exports[export]));
                if (geometry is null || geometry.Vertices.Count == 0) continue;

                // A fixed stride rather than the first N: the first vertices of a mesh are often one
                // corner of it, and a corner is not a sample of the shape.
                int stride = Math.Max(1, geometry.Vertices.Count / 60);

                for (int ci = 0; ci < candidates.Length; ci++)
                {
                    var t = actor.Transform;
                    var placement = GameBasis.Convert(
                        Matrix4x4.CreateTranslation(-t.PrePivot)
                        * Matrix4x4.CreateScale(t.Scale)
                        * Matrix4x4.CreateFromQuaternion(candidates[ci].Build(t.Rotation.ToDegrees()))
                        * Matrix4x4.CreateTranslation(t.Location));

                    for (int v = 0; v < geometry.Vertices.Count; v += stride)
                    {
                        var p = Vector3.Transform(geometry.Vertices[v].Position, placement);
                        if (!FrontLeaf(world, p)) perMap[ci]++;
                        if (ci == 0) perMapSampled++;
                    }
                }
            }

            if (perMapSampled == 0) continue;

            Log($"{mapName}: {actors.Count} rolled actors, {perMapSampled:N0} points each");
            for (int ci = 0; ci < candidates.Length; ci++)
            {
                buried[ci] += perMap[ci];
                sampled[ci] += perMapSampled;
                Log($"    {candidates[ci].Name,-30} buried {perMap[ci],7:N0} ({(double)perMap[ci] / perMapSampled:P2})");
            }
        }

        Assert.True(mapsUsed >= 5, $"only {mapsUsed} maps contributed");

        Log("TOTAL across all maps:");
        var shares = new double[candidates.Length];
        for (int ci = 0; ci < candidates.Length; ci++)
        {
            shares[ci] = (double)buried[ci] / sampled[ci];
            Log($"    {candidates[ci].Name,-30} {buried[ci],8:N0} / {sampled[ci]:N0} = {shares[ci]:P2}");
        }

        int bestIndex = Array.IndexOf(shares, shares.Min());
        Log($"  least geometry buried in solid: {candidates[bestIndex].Name}");

        Assert.True(sampled[0] > 100_000, $"only {sampled[0]} points sampled; too few to conclude from");
    }
}
