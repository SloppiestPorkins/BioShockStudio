using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What the int32 at <c>FBspSurf +20</c> indexes, settled against shipped bytes.
/// </summary>
/// <remarks>
/// <para>
/// Three statements from one reference project disagreed: its spec §C.1.3 calls the field
/// <c>iBrushPoly</c>, its level editor's parser reads the same position as <c>iLightMap</c> and uses
/// it to choose a lightmap atlas, and its lightmap note puts <c>iLightMap</c> on the <i>node</i>.
/// Nobody had measured it, and the answer is a precondition for reading lightmaps at all — a project
/// that took the editor's reading would go looking for atlases with a brush-polygon index.
/// </para>
/// <para>
/// <b>The discriminator is the normal.</b> A surface names the brush actor it was cut from, and that
/// brush's <c>Polys</c> export holds its faces with their own normals. If +20 indexes those faces,
/// the face it names must be the one this surface came from, so the two normals must agree. An
/// unrelated index would agree by chance about a sixth of the time on a six-sided brush.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SurfaceBrushPolyTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void TheFieldAtTwentyIndexesTheSourceBrushsOwnPolygons()
    {
        int checkedSurfaces = 0, inRange = 0, normalAgrees = 0, totalSurfaces = 0;
        var ranges = new List<string>();

        foreach (string name in new[] { "0-Lighthouse", "1-Medical", "3-Arcadia" })
        {
            using var package = BioShockPackage.Open(
                Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm"));

            var model = ModelReader.BuiltWorld(package);
            if (model is null) continue;
            var world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]);
            if (world is null || world.Surfaces.Count == 0) continue;

            var context = LevelAnalyzer.Analyze(package);
            var brushes = context.Brushes.ToDictionary(a => a.Source.ExportIndex);
            var polyCache = new Dictionary<int, IReadOnlyList<BspPolygon>>();

            totalSurfaces += world.Surfaces.Count;
            int distinct = world.Surfaces.Select(s => s.BrushPoly).Distinct().Count();

            ranges.Add($"{name}: {world.Surfaces.Count} surfaces, +20 in "
                       + $"{world.Surfaces.Min(s => s.BrushPoly)}..{world.Surfaces.Max(s => s.BrushPoly)}, "
                       + $"{distinct} distinct values");

            foreach (var surface in world.Surfaces)
            {
                if (surface.BrushPoly < 0 || !surface.Actor.IsExport) continue;
                if (!brushes.TryGetValue(surface.Actor.ExportIndex, out var actor)) continue;
                if (actor.Brush?.Source is not { } brushSource) continue;

                if (!polyCache.TryGetValue(surface.Actor.ExportIndex, out var polys))
                {
                    polys = [];
                    try
                    {
                        var brushModel = ModelReader.Read(package, package.Exports[brushSource.ExportIndex]);
                        if (brushModel is not null
                            && ModelReader.ResolvePolys(package, brushModel) is { } export)
                            polys = PolysReader.Read(package, export).Polygons;
                    }
                    catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { }

                    polyCache[surface.Actor.ExportIndex] = polys;
                }

                if (polys.Count == 0) continue;
                checkedSurfaces++;

                if (surface.BrushPoly >= polys.Count) continue;
                inRange++;

                if (surface.Normal >= 0 && surface.Normal < world.Vectors.Count
                    && MathF.Abs(Vector3.Dot(polys[surface.BrushPoly].Normal, world.Vectors[surface.Normal])) > 0.999f)
                    normalAgrees++;
            }
        }

        foreach (string line in ranges) Log(line);
        Log($"+20 as iBrushPoly: {checkedSurfaces} surfaces resolved to a brush, {inRange} in range, "
            + $"{normalAgrees} name a polygon whose normal matches the surface's");

        // Not vacuous: a real population, from three maps.
        Assert.True(checkedSurfaces > 1_000, $"only {checkedSurfaces} surfaces could be checked");

        // Every value indexes its own brush's polygon list…
        Assert.Equal(checkedSurfaces, inRange);

        // …and names the face the surface was actually cut from. This is the assertion that decides
        // between the two readings, and the one that would fail if the field were a lightmap index.
        Assert.Equal(inRange, normalAgrees);
    }
}
