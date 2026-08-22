using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Does all of the compiled world reach the viewport, or only the part that carries a lightmap?
/// </summary>
/// <remarks>
/// <para>
/// <b>The suspicion this measures.</b> <c>LevelViewportService.Prepare</c> draws a compiled world
/// through <c>LightMappedWorld</c> whenever the map has a proven atlas pool, and then
/// <c>continue</c>s — the material-only model is never built for that map. But
/// <c>LightMappedWorld</c> only ever iterates <c>world.LightMapBatches</c>, and
/// <c>BspGeometry.ToLightMapBatches</c> keeps a node only when its layer names an atlas that is in
/// range. It also skips any batch whose atlas fails to decode. So a compiled-world surface with no
/// usable lightmap layer has no path into the viewport at all.
/// </para>
/// <para>
/// <b>Missing geometry and unpainted geometry are very different faults</b>, and the surface census
/// cannot tell them apart — a surface that was never added is not a surface with no material, it is
/// simply absent, and every count taken over what <i>is</i> drawn stays green. This measures the
/// compiled world's own triangle count against what the batches carry.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspWorldCoverageTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// Renders the surfaces the atlas batches leave behind, so what the fix restored can be looked
    /// at rather than counted. <c>BIOSHOCK_REMAINDER_SNAPSHOT=/tmp/r.png</c>, one image per map.
    /// </summary>
    /// <remarks>
    /// <b>The count alone would not have settled this.</b> "23,714 triangles were missing" is
    /// equally consistent with real walls and with degenerate slivers that should never have been
    /// drawn — and adding junk geometry would make the coverage assertion pass while making the
    /// viewport worse. The pictures show the remainder is architecture: floors, ceilings and wall
    /// panels, in recognisable room shapes.
    /// </remarks>
    [RequiresGameFact]
    public void TheSurfacesTheBatchesLeaveBehindAreRendered()
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_REMAINDER_SNAPSHOT") is not { Length: > 0 } path)
            return;

        string directory = Path.GetDirectoryName(path) ?? ".";
        Directory.CreateDirectory(directory);

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);
            var model = ModelReader.BuiltWorld(package);
            if (model is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;
            if (BspGeometry.ToLightMapBatches(world).Count == 0) continue;

            var remainder = BspGeometry.ToGeometry(world, n => !BspGeometry.HasLightMapAtlas(world, n));
            if (remainder.Indices.Count < 3) continue;

            string name = Path.GetFileNameWithoutExtension(map);
            foreach (var (label, geometry) in new[]
                     {
                         ("whole", BspGeometry.ToGeometry(world)),
                         ("remainder", remainder),
                     })
            {
                var preview = PreviewModel.Build(geometry, null);
                var min = geometry.Vertices.Aggregate(new Vector3(float.MaxValue), (a, v) => Vector3.Min(a, v.Position));
                var max = geometry.Vertices.Aggregate(new Vector3(float.MinValue), (a, v) => Vector3.Max(a, v.Position));
                var camera = PreviewCamera
                    .Frame((min + max) / 2f, Vector3.Distance(min, max) / 2f)
                    .Orbit(0.9f, 0.5f);

                var image = SoftwareRenderer.Render(
                    [new PreviewInstance(preview, null, Matrix4x4.Identity)],
                    camera, new RenderOptions { ShowSkeleton = false, ShowSockets = false }, 900, 600);

                PngWriter.Write(Path.Combine(directory, $"{name}_{label}.png"),
                    image.Rgba, image.Width, image.Height);
            }

            Log($"rendered {name}: {remainder.TriangleCount:N0} remainder triangles");
        }
    }

    /// <summary>
    /// The compiled-world surfaces that name no material at all — read from the BSP itself, not from
    /// what the resolver made of it.
    /// </summary>
    /// <remarks>
    /// The surface census finds a small residue of drawn compiled-world surfaces with no material.
    /// This says whether that is the game's own data (the surface's <c>Material</c> index is none)
    /// or this project failing to resolve a reference that is present — the same distinction
    /// <c>docs/research/bsp.md</c> already settled for source brushes, where 17,802 of 93,264
    /// polygons carry neither texture axes nor a material and that is content.
    /// </remarks>
    [RequiresGameFact]
    public void TheCompiledWorldSurfacesWithoutAMaterialAreClassified()
    {
        int drawn = 0, noReference = 0, referenceNotAnExport = 0;

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);
            var model = ModelReader.BuiltWorld(package);
            if (model is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;

            foreach (var node in world.Nodes)
            {
                if (!node.IsPolygon) continue;
                if (node.Surface < 0 || node.Surface >= world.Surfaces.Count) continue;
                var surface = world.Surfaces[node.Surface];
                if (!surface.IsDrawn) continue;

                drawn++;
                if (surface.Material.IsNull) noReference++;
                else if (!surface.Material.IsExport) referenceNotAnExport++;
            }
        }

        Log($"compiled-world drawn polygons {drawn:N0}: "
            + $"{noReference:N0} name no material at all, "
            + $"{referenceNotAnExport:N0} name something that is not an export in this package");

        Assert.True(drawn > 50_000, $"only {drawn} drawn compiled-world polygons were examined");
    }

    [RequiresGameFact]
    public void TheLightMapBatchesAreComparedAgainstTheWholeCompiledWorld()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
            .OrderBy(f => f, StringComparer.Ordinal)
            .ToList();

        long worldTriangles = 0, batchTriangles = 0;
        int mapsWithBatches = 0, mapsWithWorld = 0;
        var rows = new List<(string Map, int World, int Batched, double Share)>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);

            var model = ModelReader.BuiltWorld(package);
            if (model is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;

            mapsWithWorld++;
            int whole = BspGeometry.ToGeometry(world).TriangleCount;
            var batches = BspGeometry.ToLightMapBatches(world);
            int batched = batches.Sum(b => b.Geometry.TriangleCount);

            worldTriangles += whole;
            batchTriangles += batched;
            if (batches.Count > 0) mapsWithBatches++;

            rows.Add((Path.GetFileNameWithoutExtension(map), whole, batched,
                whole == 0 ? 0 : (double)batched / whole));
        }

        Log($"compiled worlds: {mapsWithWorld} read, {mapsWithBatches} with lightmap batches");
        Log($"  triangles: {worldTriangles:N0} in the compiled worlds, {batchTriangles:N0} in batches "
            + $"({(worldTriangles == 0 ? 0 : (double)batchTriangles / worldTriangles):P1})");

        foreach (var (name, whole, batched, share) in rows.OrderBy(r => r.Share))
            Log($"  {name,-24} {whole,7:N0} world, {batched,7:N0} batched, {share,7:P1}"
                + (batched < whole ? $"  MISSING {whole - batched:N0}" : ""));

        Assert.True(mapsWithWorld >= 20, $"only {mapsWithWorld} compiled worlds were read");
        Assert.True(worldTriangles > 100_000, $"only {worldTriangles} compiled-world triangles");
    }

    /// <summary>
    /// The decisive, end-to-end check: what the compiled world contains against what actually
    /// reaches the viewport.
    /// </summary>
    /// <remarks>
    /// The batch comparison above is an argument about two functions. This one asks the question
    /// that matters — is the geometry on screen? — by preparing each map exactly as the application
    /// does and counting the <c>BuiltWorld</c> triangles that came out.
    /// </remarks>
    [RequiresGameFact]
    public void TheViewportDrawsTheWholeCompiledWorld()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
            .OrderBy(f => f, StringComparer.Ordinal)
            .ToList();

        var service = new LevelViewportService(new AssetCatalogService());
        long worldTriangles = 0, drawnTriangles = 0;
        var shortfall = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var model = ModelReader.BuiltWorld(package);
            if (model is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;

            int whole = BspGeometry.ToGeometry(world).TriangleCount;
            if (whole == 0) continue;

            var level = service.Prepare(map);
            int drawn = level.Viewport.Items
                .Where(i => i.Kind == LevelGeometryKind.BuiltWorld)
                .Sum(i => i.Model.Vertices.Count == 0 ? 0 : i.Model.Surfaces.Sum(s => s.TriangleCount));

            worldTriangles += whole;
            drawnTriangles += drawn;

            string name = Path.GetFileNameWithoutExtension(map);
            Log($"  {name,-24} world {whole,7:N0}, drawn {drawn,7:N0}, "
                + $"{(double)drawn / whole,7:P1}" + (drawn < whole ? $"  MISSING {whole - drawn:N0}" : ""));

            if (drawn < whole) shortfall.Add($"{name}: {whole - drawn:N0} of {whole:N0} triangles never drawn");
        }

        Log($"compiled world reaching the viewport: {drawnTriangles:N0} of {worldTriangles:N0} "
            + $"({(worldTriangles == 0 ? 0 : (double)drawnTriangles / worldTriangles):P1})");

        Assert.True(worldTriangles > 100_000, $"only {worldTriangles} compiled-world triangles examined");

        // Every drawn BSP surface must reach the screen. A surface the game flags as visible and the
        // viewer never adds is not grey, it is absent — and no count taken over what IS drawn can
        // see it.
        Assert.True(shortfall.Count == 0,
            $"{shortfall.Count} maps draw less of their compiled world than it contains:"
            + Environment.NewLine + string.Join(Environment.NewLine, shortfall.Take(25)));
    }
}
