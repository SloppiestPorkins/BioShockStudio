using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// How a brush actor's transform composes, measured against the compiled world.
/// </summary>
/// <remarks>
/// <para>
/// <see cref="LevelSceneBuilder.BrushPlacement"/> places a brush by <c>Location − PrePivot</c> with
/// no rotation or scale and is labelled <c>LIKELY</c>. "The level assembles" is weak evidence for
/// that, because a level whose brushes are all unrotated looks the same under several wrong rules.
/// </para>
/// <para>
/// <b>The compiled world is the ground truth this needed.</b> CSG built it from the same brushes,
/// and every <c>FBspSurf</c> names the brush actor it came from — so the same polygon exists twice,
/// once in brush space and once in world space, and the placement rule is whatever maps one onto the
/// other. That comparison can fail: each candidate rule is measured, not just the one in use.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BrushPlacementTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>The candidate rules. Only one of these can put a brush where CSG put it.</summary>
    private static readonly (string Name, Func<ActorTransform, Matrix4x4> Rule)[] Candidates =
    [
        ("Location - PrePivot", LevelSceneBuilder.BrushPlacement),
        ("Location only", t => Matrix4x4.CreateTranslation(GameBasis.Convert(t.Location))),
        ("full actor transform", LevelSceneBuilder.MeshPlacement),
        ("no placement", _ => Matrix4x4.Identity),
    ];

    /// <summary>
    /// Every drawn world polygon is matched back to its own brush, under each candidate rule.
    /// </summary>
    /// <remarks>
    /// The metric is the plane offset: a world polygon's plane must coincide with a plane of the
    /// brush it names once that brush is placed. CSG clips a brush's polygons against its
    /// neighbours, so vertices need not survive and areas need not match — but a clipped polygon
    /// stays in the plane it was cut from, so the plane does.
    /// </remarks>
    [RequiresGameFact]
    public void EachCandidatePlacementRuleIsMeasuredAgainstTheCompiledWorld()
    {
        string[] maps =
        [
            "0-Lighthouse", "1-Medical", "2-Fisheries", "3-Arcadia", "6-Slums", "7-Science",
        ];

        var totals = Candidates.ToDictionary(c => c.Name, _ => (Matched: 0, Checked: 0, Worst: 0f));
        int surfacesWithActor = 0, surfacesResolved = 0, polygonsChecked = 0;
        int facingSame = 0, facingOpposite = 0;
        var unmatched = new List<string>();

        foreach (string name in maps)
        {
            string path = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm");
            using var package = BioShockPackage.Open(path);
            var context = LevelAnalyzer.Analyze(package);

            var model = ModelReader.BuiltWorld(package);
            Assert.NotNull(model);
            var world = BspWorldReader.Read(package, package.Exports[model!.Source.ExportIndex]);
            Assert.NotNull(world);

            // exportIndex → the brush actor, so a surface's Actor reference becomes a transform.
            var brushes = context.Brushes.ToDictionary(a => a.Source.ExportIndex);
            var polyCache = new Dictionary<int, IReadOnlyList<BspPolygon>>();

            var perMap = Candidates.ToDictionary(c => c.Name, _ => (Matched: 0, Checked: 0));

            foreach (var node in world!.Nodes)
            {
                if (!node.IsPolygon || node.Surface < 0 || node.Surface >= world.Surfaces.Count) continue;

                var surface = world.Surfaces[node.Surface];
                if (!surface.Actor.IsExport) continue;
                surfacesWithActor++;

                if (!brushes.TryGetValue(surface.Actor.ExportIndex, out var actor)) continue;
                surfacesResolved++;

                var polygon = world.PolygonOf(node);
                if (polygon.Count < 3) continue;

                if (!polyCache.TryGetValue(surface.Actor.ExportIndex, out var source))
                    polyCache[surface.Actor.ExportIndex] = source = SourcePolygons(package, actor);
                if (source.Count == 0) continue;

                polygonsChecked++;

                foreach (var (candidate, rule) in Candidates)
                {
                    var placement = rule(actor.Transform);
                    var (best, sameFacing) = BestPlaneOffset(node.Plane, polygon, source, placement);

                    var running = totals[candidate];
                    var mapRunning = perMap[candidate];

                    bool matched = best <= 1f;                      // one centimetre
                    totals[candidate] = (running.Matched + (matched ? 1 : 0), running.Checked + 1,
                        matched ? Math.Max(running.Worst, best) : running.Worst);
                    perMap[candidate] = (mapRunning.Matched + (matched ? 1 : 0), mapRunning.Checked + 1);

                    if (candidate != Candidates[0].Name) continue;

                    if (!matched) unmatched.Add($"{name} {actor.Source.ObjectName}: nearest plane {best:0.##} cm");
                    else if (sameFacing) facingSame++;
                    else facingOpposite++;
                }
            }

            foreach (var (candidate, counts) in perMap)
            {
                Log($"{name,-14} {candidate,-22} {counts.Matched,6}/{counts.Checked,-6} "
                    + $"{(counts.Checked == 0 ? 0 : 100.0 * counts.Matched / counts.Checked):0.0}%");
            }
        }

        Log($"surfaces naming an actor {surfacesWithActor}, of which brush actors {surfacesResolved}; "
            + $"{polygonsChecked} polygons compared");
        foreach (var (candidate, counts) in totals)
        {
            Log($"ALL {candidate,-22} {counts.Matched,7}/{counts.Checked,-7} "
                + $"{(counts.Checked == 0 ? 0 : 100.0 * counts.Matched / counts.Checked):0.0}% "
                + $"worst matched offset {counts.Worst:0.###} cm");
        }

        Log($"facing the same way {facingSame}, facing the opposite way {facingOpposite}");
        foreach (string line in unmatched.Take(20)) Log("  unmatched: " + line);

        // Not vacuous: the comparison has to have had real polygons to compare.
        Assert.True(polygonsChecked > 1_000, $"only {polygonsChecked} world polygons were compared");

        // The rule in use puts essentially every compiled polygon back in a plane of its own brush.
        var placed = totals["Location - PrePivot"];
        Assert.True(placed.Matched >= 0.999 * placed.Checked,
            $"only {placed.Matched} of {placed.Checked} world polygons land in a plane of the brush "
            + "they name, so Location − PrePivot is not how a brush is placed");

        // And the check can fail: dropping the pre-pivot moves almost everything off its plane, so
        // the pass above is a measurement rather than a tolerance wide enough to accept anything.
        var withoutPrePivot = totals["Location only"];
        Assert.True(withoutPrePivot.Matched < 0.1 * withoutPrePivot.Checked,
            $"{withoutPrePivot.Matched} of {withoutPrePivot.Checked} polygons match without the "
            + "pre-pivot too, so this comparison does not distinguish the rules");

        // Both orientations occur, which is why the match is on the plane rather than on the facing:
        // a subtracted brush's face points into the world it cut, not out of it.
        Assert.True(facingOpposite > 0 && facingSame > 0,
            $"{facingSame} polygons face their source poly and {facingOpposite} oppose it");
    }

    /// <summary>The brush's own polygons, in the studio's basis, in brush space.</summary>
    private static IReadOnlyList<BspPolygon> SourcePolygons(BioShockPackage package, LevelActor actor)
    {
        if (actor.Brush?.Source is not { } brushSource) return [];

        try
        {
            var model = ModelReader.Read(package, package.Exports[brushSource.ExportIndex]);
            if (model is null) return [];
            if (ModelReader.ResolvePolys(package, model) is not { } polys) return [];
            return PolysReader.Read(package, polys).Polygons;
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException)
        {
            return [];
        }
    }

    /// <summary>
    /// How far the world polygon's plane sits from the nearest parallel plane of the placed brush.
    /// </summary>
    /// <remarks>
    /// Only planes facing the same way are compared — a brush's opposite face is parallel too, and
    /// matching against it would let a rule that is wrong by the brush's own thickness pass.
    /// </remarks>
    private static (float Offset, bool SameFacing) BestPlaneOffset(
        Plane worldPlane, IReadOnlyList<Vector3> worldPolygon,
        IReadOnlyList<BspPolygon> source, Matrix4x4 placement)
    {
        var centre = worldPolygon.Aggregate(Vector3.Zero, (a, v) => a + v) / worldPolygon.Count;
        float best = float.MaxValue;
        bool sameFacing = false;

        foreach (var polygon in source)
        {
            if (polygon.Vertices.Count < 3) continue;

            var normal = Vector3.TransformNormal(polygon.Normal, placement);
            if (normal.LengthSquared() < 1e-12f) continue;
            normal = Vector3.Normalize(normal);

            float alignment = Vector3.Dot(normal, worldPlane.Normal);
            if (Math.Abs(alignment) < 0.999f) continue;

            var point = Vector3.Transform(polygon.Vertices[0], placement);
            float offset = Math.Abs(Vector3.Dot(normal, centre - point));

            if (offset >= best) continue;
            best = offset;
            sameFacing = alignment > 0f;
        }

        return (best, sameFacing);
    }
}
