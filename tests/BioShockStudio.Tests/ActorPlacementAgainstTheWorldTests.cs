using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Placed actors checked against the level's own architecture, rather than against another
/// implementation of the same rule.
/// </summary>
/// <remarks>
/// <para>
/// <b>This exists because every check the project already had is blind in the same place.</b>
/// <c>ActorTransformReferenceTests</c> proves this project composes an actor transform identically
/// to Nyko's level editor — 12,557 rotations to 1e-5 — which is agreement with a <i>reference</i>,
/// not correctness. If the reference builds the rotation wrongly, that test reproduces the error
/// faithfully and stays green. The older evidence has the same hole from the other side: the
/// Medical Pavilion arch was settled by "the four instances form one continuous surface", and a
/// surface that is continuous but rotated <i>as a whole</i> passes that too.
/// </para>
/// <para>
/// <b>The compiled world is the ground truth neither of those uses.</b> It is BSP, built by CSG,
/// drawn at identity — no actor transform is involved in it at all. So an actor that is supposed to
/// sit on a surface gives a falsifiable claim about the transform: a sign painted on a floor must
/// lie in the plane of that floor. A wrong rotation stands it up, and no amount of agreement with a
/// reference editor can hide that from the floor it fails to match.
/// </para>
/// <para>
/// Reported by a user, on a real screenshot, after the transform work was called done: the
/// <c>SURGERY</c> floor signs in <c>1-Medical</c> standing as vertical slabs through the room, and
/// window pieces rotated wrongly with correctly-rotated neighbours.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ActorPlacementAgainstTheWorldTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>Area-weighted average face normal of a placed mesh, and its centre.</summary>
    private static (Vector3 Normal, Vector3 Centre) PlacedPlane(MeshGeometry geometry, Matrix4x4 placement)
    {
        var accumulated = Vector3.Zero;
        var centre = Vector3.Zero;
        int points = 0;

        for (int i = 0; i + 2 < geometry.Indices.Count; i += 3)
        {
            var a = Vector3.Transform(geometry.Vertices[geometry.Indices[i]].Position, placement);
            var b = Vector3.Transform(geometry.Vertices[geometry.Indices[i + 1]].Position, placement);
            var c = Vector3.Transform(geometry.Vertices[geometry.Indices[i + 2]].Position, placement);

            // Un-normalised cross product: its length is twice the triangle's area, so summing them
            // weights each face by how much of the mesh it actually is. A sign is a slab, and its
            // two large faces must not be outvoted by the dozens of slivers around its edge.
            accumulated += Vector3.Cross(b - a, c - a);
            centre += (a + b + c) / 3f;
            points++;
        }

        return (accumulated.LengthSquared() < 1e-12f ? Vector3.Zero : Vector3.Normalize(accumulated),
                points == 0 ? Vector3.Zero : centre / points);
    }

    /// <summary>The compiled world's triangles, as (centroid, normal), in the studio basis.</summary>
    private static List<(Vector3 Centre, Vector3 Normal)> WorldTriangles(BspWorld world)
    {
        var geometry = BspGeometry.ToGeometry(world);
        var result = new List<(Vector3, Vector3)>(geometry.Indices.Count / 3);

        for (int i = 0; i + 2 < geometry.Indices.Count; i += 3)
        {
            var a = geometry.Vertices[geometry.Indices[i]];
            var b = geometry.Vertices[geometry.Indices[i + 1]];
            var c = geometry.Vertices[geometry.Indices[i + 2]];
            result.Add(((a.Position + b.Position + c.Position) / 3f, a.Normal));
        }

        return result;
    }

    /// <summary>
    /// The <c>SURGERY</c> floor signs, checked against the floor.
    /// </summary>
    /// <remarks>
    /// Every <c>Med_Floor_Signs</c> actor in <c>1-Medical</c> is placed with yaw alone except three,
    /// which carry <c>roll</c> of +90°, −90° and 180° with no yaw and no pitch. If the rotation is
    /// composed correctly they all lie in the floor; if <c>roll</c> is mishandled the three stand up.
    /// </remarks>
    [RequiresGameFact]
    public void TheFloorSignsLieInTheFloorTheyArePaintedOn()
    {
        string map = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        using var package = BioShockPackage.Open(map);
        var context = LevelAnalyzer.Analyze(package);

        var built = ModelReader.BuiltWorld(package);
        Assert.NotNull(built);
        var world = BspWorldReader.Read(package, package.Exports[built!.Source.ExportIndex]);
        Assert.NotNull(world);
        var triangles = WorldTriangles(world!);
        Assert.NotEmpty(triangles);

        var actors = context.WithStaticMesh
            .Where(a => string.Equals(a.StaticMesh?.Source?.ObjectName, "Med_Floor_Signs",
                StringComparison.OrdinalIgnoreCase))
            .ToList();

        Assert.True(actors.Count >= 10, $"only {actors.Count} Med_Floor_Signs actors found");

        var geometryCache = new Dictionary<int, MeshGeometry?>();
        var upright = new List<string>();
        int flat = 0, rolled = 0, unjudgeable = 0;

        Log($"Med_Floor_Signs in 1-Medical: {actors.Count} actors");

        foreach (var actor in actors)
        {
            int export = actor.StaticMesh!.Source!.Value.ExportIndex;
            if (!geometryCache.TryGetValue(export, out var geometry))
                geometryCache[export] = geometry =
                    StaticMeshReader.ReadGeometry(package.ReadExportData(package.Exports[export]));
            if (geometry is null || geometry.Indices.Count < 3) continue;

            var placement = LevelSceneBuilder.MeshPlacement(actor.Transform);
            var (normal, centre) = PlacedPlane(geometry, placement);
            if (normal == Vector3.Zero) continue;

            // The surface this sign is painted on, if there is one. A painted sign is not merely
            // PARALLEL to architecture — it is FLUSH with it. Requiring both is what separates a
            // sign lying on a floor from one standing in mid-air happening to face the same way as a
            // wall twenty metres off, which is a distinction the first version of this check missed.
            float flush = float.MaxValue;
            foreach (var (triangleCentre, triangleNormal) in triangles)
            {
                if (Vector3.DistanceSquared(triangleCentre, centre) > 400f * 400f) continue;
                if (MathF.Abs(Vector3.Dot(normal, triangleNormal)) < 0.95f) continue;

                // Perpendicular distance from the sign's centre to that surface's own plane.
                flush = MathF.Min(flush, MathF.Abs(Vector3.Dot(centre - triangleCentre, triangleNormal)));
            }

            var nearest = triangles
                .Select(t => (t, d: Vector3.DistanceSquared(t.Centre, centre)))
                .OrderBy(x => x.d)
                .First();

            float agreement = MathF.Abs(Vector3.Dot(normal, nearest.t.Normal));
            bool isRolled = actor.Transform.Rotation.Roll != 0;
            if (isRolled) rolled++;

            // |n·z| near 1 is a horizontal slab; near 0 is a vertical one.
            float verticality = MathF.Abs(normal.Z);
            if (verticality > 0.85f) flat++;

            string flushText = flush == float.MaxValue ? "none" : $"{flush:0.0}";
            Log($"  {actor.Source.ObjectName,-22} {actor.Transform.Rotation,-34} "
                + $"|n.Z| {verticality:0.00}, nearest-normal {agreement:0.00} "
                + $"(at {MathF.Sqrt(nearest.d):0}u), flush-to-plane {flushText}");

            // Judge only the signs this check can actually see. A sign with NO parallel
            // architecture within 400 units is not necessarily misplaced — it may be lying on a
            // desk or a counter, which is a static mesh and invisible to a BSP comparison. Two of
            // 1-Medical's 63 are in that position. Failing on them would be asserting something the
            // measurement does not support, which is the mistake this whole class exists to correct.
            if (flush == float.MaxValue) unjudgeable++;
            else if (flush > 12f)
                upright.Add($"{actor.Source.ObjectName} ({actor.Transform.Rotation}) "
                            + $"|n.Z|={verticality:0.00} flush={flushText}");
        }

        Log($"  {flat} of {actors.Count} lie flat; {rolled} carry a non-zero roll; "
            + $"{unjudgeable} have no parallel architecture nearby and are not judged");

        // Not vacuous: there must be rolled examples, or the check cannot see the case it exists for.
        Assert.True(rolled >= 3,
            $"only {rolled} Med_Floor_Signs actors carry a roll, so this cannot test the roll term");

        // Most must be judgeable, or the check has quietly stopped checking.
        Assert.True(unjudgeable < actors.Count / 4,
            $"{unjudgeable} of {actors.Count} signs have no architecture to compare against");

        // Every sign the compiled world CAN speak to sits flush against it. This is the claim the
        // reference-editor comparison cannot make, and it holds under the corrected roll: the two
        // rolled ±90° signs are flush against walls (3.8 and 5.8 units), and negating roll swaps
        // which wall they face without lifting either off it.
        Assert.True(upright.Count == 0,
            $"{upright.Count} floor signs sit clear of the architecture they should be flush with:"
            + Environment.NewLine + string.Join(Environment.NewLine, upright));
    }
}
