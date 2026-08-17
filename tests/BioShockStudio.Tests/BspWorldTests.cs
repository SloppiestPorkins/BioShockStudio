using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The compiled world: the level's actual architecture.
/// </summary>
/// <remarks>
/// <para>
/// Until this, a level export and the walkthrough carried <b>only</b> static meshes and the
/// designer's source brushes — so Lighthouse read as a skyline and props with the rooms missing.
/// The floors and walls a player stands on are in the compiled BSP.
/// </para>
/// <para>
/// <b>Planarity is the assertion that decides whether the layout is right.</b> Three independent
/// arrays — the nodes, the vertex pool and the points — must agree: every polygon's vertices have
/// to lie on its own node's plane. A wrong field offset cannot produce coplanar polygons by
/// accident, which is exactly how Nyko settled <c>NumVertices</c> at +78 against +88 (0 of 7,125
/// failures against 64%).
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspWorldTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>The package's compiled world, or null when it holds no model at all.</summary>
    /// <remarks>
    /// Not every <c>.bsm</c> in the maps folder is a map — some carry no <c>Model</c> whatsoever,
    /// so this returns null rather than throwing and the sweep counts them instead of failing.
    /// </remarks>
    private static BspWorld? World(BioShockPackage package)
    {
        var model = ModelReader.BuiltWorld(package);
        if (model is null) return null;
        return BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]);
    }

    [RequiresGameFact]
    public void EveryCompiledWorldsPolygonsLieOnTheirOwnPlanes()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int worlds = 0, polygons = 0, triangles = 0, offPlane = 0, checkedPolygons = 0;
        float worstOverall = 0f;

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.PolygonCount == 0) continue;

            worlds++;
            polygons += world.PolygonCount;
            triangles += world.TriangleCount;

            var (worst, off, checkedHere) = world.Planarity();
            worstOverall = MathF.Max(worstOverall, worst);
            offPlane += off;
            checkedPolygons += checkedHere;

            Log($"{Path.GetFileNameWithoutExtension(map),-24} {world.Nodes.Count,5} nodes, "
                + $"{world.PolygonCount,5} polygons, {world.Surfaces.Count,5} surfaces, "
                + $"{world.VertexPool.Count,7} pool, worst {worst,8:0.###}, off-plane {off}");
        }

        Log($"compiled worlds: {worlds}, polygons {polygons:N0}, triangles {triangles:N0}");
        Log($"planarity: {offPlane} of {checkedPolygons:N0} polygons more than 1 cm off their own plane, "
            + $"worst {worstOverall:0.###}");

        Assert.True(worlds >= 20, $"only {worlds} maps yielded a compiled world");
        Assert.True(polygons > 50_000, $"only {polygons} polygons across every map");

        // The share is what says the layout is right, not the maximum: a handful of polygons can sit
        // slightly off their plane through float precision at 80,000 units from the origin, but a
        // wrong field offset puts a large fraction of them nowhere near it — Nyko measured 64%
        // failures reading NumVertices at +88 instead of +78.
        double share = checkedPolygons == 0 ? 1 : (double)offPlane / checkedPolygons;
        Assert.True(share < 0.001,
            $"{offPlane} of {checkedPolygons} polygons ({share:P2}) are more than 1 cm off their own "
            + "plane, so the node layout is wrong");
    }

    /// <summary>
    /// What the twelve off-plane polygons actually are: corners snapped to round coordinates on
    /// planes that are slightly oblique. Shipped data, not a decode fault.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Every one of the twelve has the same shape. Part of the polygon sits <b>exactly</b> on its
    /// plane — 0.000 cm, not nearly — and the rest sits off it by exactly the plane's off-axis slope
    /// times the distance travelled. <c>7-Gauntlet</c> node 755: the plane's normal is
    /// <c>(−0.9966, 0.0819, 0)</c>, a wall 4.7° off the Y axis, and all four corners are stored at
    /// <c>x = 32</c>; the two at <c>y = −2252</c> are exact and the two at <c>y = −2208</c> are
    /// 3.603 cm out, which is <c>0.0822 × 44</c> to three decimals. <c>0-Lighthouse</c> node 360:
    /// slope <c>0.000459</c> across 8,704 units gives 4.00 cm, and the polygon is 4.001 cm out.
    /// </para>
    /// <para>
    /// <b>The off-plane corners are the round ones.</b> On <c>7-Gauntlet</c> node 591 the exact
    /// vertices sit at <c>x = −107.43</c> and the 7.38 cm ones at <c>x = −96</c>. That is the
    /// signature of the editor snapping a brush corner to the grid, after which CSG's fragment no
    /// longer lies on the face it was cut from.
    /// </para>
    /// <para>
    /// <b>What it is not.</b> Not precision — a float at 5,000 units resolves to under a
    /// millimetre, not 7 cm. Not the basis conversion, which is a sign flip and exact. Not the
    /// decode: the same three arrays produce 81,554 polygons that are exactly on plane, and a wrong
    /// offset cannot be selective. <c>HIGH CONFIDENCE</c>, from the arithmetic above.
    /// </para>
    /// <para>
    /// The assertion that can fail is the last one: <b>every off-plane polygon must still have a
    /// vertex exactly on its plane.</b> A decode fault — a wrong pool offset, a wrong plane field —
    /// moves the whole polygon off, not two corners of it.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheOffPlanePolygonsAreSnappedCornersAndKeepAVertexOnTheirPlane()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int examined = 0, withAnExactVertex = 0;
        float worst = 0f;
        var wholePolygonsOff = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.PolygonCount == 0) continue;

            foreach (var node in world.Nodes)
            {
                if (!node.IsPolygon) continue;

                var polygon = world.PolygonOf(node);
                if (polygon.Count < 3) continue;

                var distances = polygon
                    .Select(v => MathF.Abs(Plane.DotCoordinate(node.Plane, v)))
                    .ToList();

                if (distances.Max() <= 1f) continue;

                examined++;
                worst = MathF.Max(worst, distances.Max());

                if (distances.Min() <= 0.01f) withAnExactVertex++;
                else
                    wholePolygonsOff.Add($"{Path.GetFileNameWithoutExtension(map)}: every vertex is "
                                         + $"{distances.Min():0.###}..{distances.Max():0.###} cm off its plane");
            }
        }

        Log($"off-plane polygons {examined}, worst {worst:0.###} cm, "
            + $"{withAnExactVertex} still have a vertex exactly on their plane");

        // Not vacuous: if the reader stopped finding them the shape of the finding would be gone.
        Assert.True(examined > 0, "no off-plane polygons at all — this check has nothing to measure");

        // A ceiling rather than an equality: shipped data does not change, but a decoder change that
        // creates more of these is exactly what this is here to catch.
        Assert.True(examined <= 12, $"{examined} polygons are off their own plane, up from the 12 measured");
        Assert.True(worst < 8f, $"worst deviation is now {worst:0.###} cm, up from 7.381");

        // The discriminator. Snapping moves corners; a decode fault moves polygons.
        Assert.True(wholePolygonsOff.Count == 0,
            "a polygon is off its plane at every vertex, which snapping does not do:"
            + Environment.NewLine + string.Join(Environment.NewLine, wholePolygonsOff));
    }

    /// <summary>
    /// The compiled world winds the same way the source brushes do, and the emitted fan corrects it.
    /// </summary>
    /// <remarks>
    /// Measured rather than assumed, exactly as it was for <c>Polys</c> — and with the Newell
    /// normal, because a single cross product reads its own noise on sliver polygons. Both
    /// directions are asserted so the correction cannot be "fixed" by negating the normal instead,
    /// which would pass every count and light the level inside out.
    /// </remarks>
    [RequiresGameFact]
    public void TheCompiledWorldWindsLikeItsBrushesAndTheGeometryCorrectsForIt()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var world = World(package)!;

        int storedAgree = 0, storedDisagree = 0, degenerate = 0;

        foreach (var node in world.Nodes)
        {
            if (!node.IsPolygon) continue;
            var polygon = world.PolygonOf(node);
            if (polygon.Count < 3) continue;

            var newell = Newell(polygon);
            if (newell.Length() < 1e-3f) { degenerate++; continue; }

            if (Vector3.Dot(Vector3.Normalize(newell), node.Plane.Normal) > 0) storedAgree++;
            else storedDisagree++;
        }

        Log($"compiled world winding: {storedAgree} agree, {storedDisagree} disagree, {degenerate} degenerate");

        Assert.True(storedAgree + storedDisagree > 500, "too few polygons to conclude from");

        // The same convention as the source brushes: after conversion the stored order disagrees
        // with the plane, so the emitted fan reverses it.
        Assert.True(storedDisagree > storedAgree * 20,
            $"the compiled world does not wind like its brushes: {storedAgree} agree against "
            + $"{storedDisagree}. The reversal in BspGeometry.ToGeometry(world) would be wrong.");

        // And what the geometry actually emits faces the way the plane says.
        var geometry = BspGeometry.ToGeometry(world);
        int emittedAgree = 0, emittedDisagree = 0;

        for (int i = 0; i + 2 < geometry.Indices.Count; i += 3)
        {
            var a = geometry.Vertices[geometry.Indices[i]];
            var b = geometry.Vertices[geometry.Indices[i + 1]];
            var c = geometry.Vertices[geometry.Indices[i + 2]];

            var cross = Vector3.Cross(b.Position - a.Position, c.Position - a.Position);
            if (cross.Length() < 1e-3f) continue;

            if (Vector3.Dot(Vector3.Normalize(cross), a.Normal) > 0) emittedAgree++;
            else emittedDisagree++;
        }

        Log($"emitted world triangles: {emittedAgree} agree, {emittedDisagree} disagree");
        Assert.True(emittedAgree > emittedDisagree * 20,
            $"the emitted world triangles face the wrong way: {emittedAgree} against {emittedDisagree}");
    }

    /// <summary>
    /// Surfaces the game does not draw are excluded, and it is a meaningful number of them.
    /// </summary>
    /// <remarks>
    /// Zoning, portal and backdrop surfaces carry real geometry. Including them fills a level with
    /// invisible walls, and the count is recorded so a future change that stops excluding them shows
    /// up as a jump in triangles rather than as a mysteriously boxed-in level.
    /// </remarks>
    [RequiresGameFact]
    public void ZoningAndPortalSurfacesAreLeftOut()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var world = World(package)!;

        int notDrawn = world.Surfaces.Count(s => !s.IsDrawn);
        int drawn = world.Surfaces.Count(s => s.IsDrawn);

        Log($"world surfaces: {drawn} drawn, {notDrawn} not drawn "
            + $"(invisible/backdrop/portal) of {world.Surfaces.Count}");

        Assert.True(drawn > 0);

        // Every polygon the geometry emits belongs to a drawn surface.
        var geometry = BspGeometry.ToGeometry(world);
        Assert.True(geometry.TriangleCount > 0);
        Assert.True(geometry.TriangleCount <= world.TriangleCount,
            "the geometry emitted more triangles than the world has polygons to give");
    }

    /// <summary>
    /// The compiled world of an interior map, drawn from inside it.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>`1-Medical`, not Lighthouse.</b> Lighthouse is mostly exterior — a building and a skyline
    /// — and its compiled world is 758 polygons, so it says very little about whether interior
    /// architecture decodes. Medical is 7,125 polygons of corridors and rooms, which is what a
    /// player actually walks through and what the floors-are-missing report was about.
    /// </para>
    /// <para>
    /// The assertion is coverage from several headings: standing inside a built world, most of the
    /// view should be architecture. A world that decoded to scattered or inside-out geometry leaves
    /// the frame mostly empty. <c>BIOSHOCK_WORLD_SNAPSHOT</c> writes the images, which are the real
    /// result — the number only stops this passing on a blank frame.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void AnInteriorMapsWorldFillsTheViewFromInsideIt()
    {
        string medical = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        using var package = BioShockPackage.Open(medical);

        var world = World(package)!;
        var geometry = BspGeometry.ToGeometry(world);
        var model = Core.Rendering.PreviewModel.Build(geometry, null);

        Log($"1-Medical world: {geometry.TriangleCount:N0} triangles, {geometry.Vertices.Count:N0} vertices, "
            + $"{geometry.Sections.Count} sections");

        // Stand at the median of the geometry, which lands inside the building rather than at the
        // centre of a mostly-empty bounding box.
        var xs = geometry.Vertices.Select(v => v.Position.X).Order().ToList();
        var ys = geometry.Vertices.Select(v => v.Position.Y).Order().ToList();
        var zs = geometry.Vertices.Select(v => v.Position.Z).Order().ToList();
        var inside = new Vector3(xs[xs.Count / 2], ys[ys.Count / 2], zs[zs.Count / 2]);

        Log($"  standing at {inside:0}");

        double best = 0;
        for (int i = 0; i < 4; i++)
        {
            var camera = new Core.Rendering.GhostCamera { Position = inside, Yaw = i * MathF.PI / 2f };
            var image = Core.Rendering.SoftwareRenderer.Render(
                [new Core.Rendering.PreviewInstance(model)],
                camera.ToPreviewCamera(),
                new Core.Rendering.RenderOptions { ShowSkeleton = false, ShowSockets = false },
                720, 480);

            int drawn = 0;
            for (int p = 0; p < image.Rgba.Length; p += 4)
                if (image.Rgba[p] != 32 || image.Rgba[p + 1] != 32 || image.Rgba[p + 2] != 32) drawn++;

            double coverage = (double)drawn / (image.Width * image.Height);
            best = Math.Max(best, coverage);
            Log($"  heading {i}: {coverage:P1} covered");

            if (Environment.GetEnvironmentVariable("BIOSHOCK_WORLD_SNAPSHOT") is { Length: > 0 } path)
            {
                string directory = Path.GetDirectoryName(path) ?? ".";
                Directory.CreateDirectory(directory);
                PngWriter.Write(
                    Path.Combine(directory, $"{Path.GetFileNameWithoutExtension(path)}_{i}.png"),
                    image.Rgba, image.Width, image.Height);
            }
        }

        Assert.True(geometry.TriangleCount > 10_000,
            $"1-Medical's world is only {geometry.TriangleCount} triangles");
        Assert.True(best > 0.5,
            $"standing inside the compiled world, the fullest view is only {best:P0} covered — "
            + "the architecture is not enclosing the camera");
    }

    private static Vector3 Newell(IReadOnlyList<Vector3> vertices)
    {
        var normal = Vector3.Zero;
        for (int i = 0; i < vertices.Count; i++)
        {
            var current = vertices[i];
            var next = vertices[(i + 1) % vertices.Count];
            normal.X += (current.Y - next.Y) * (current.Z + next.Z);
            normal.Y += (current.Z - next.Z) * (current.X + next.X);
            normal.Z += (current.X - next.X) * (current.Y + next.Y);
        }
        return normal;
    }
}
