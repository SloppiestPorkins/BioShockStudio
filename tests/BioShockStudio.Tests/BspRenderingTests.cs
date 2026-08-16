using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Draws brush geometry through the same rasteriser the window uses.
/// </summary>
/// <remarks>
/// <para>
/// "Numeric validation has passed while the result was visibly wrong" is this project's most
/// expensive lesson — the mirrored years, the swapped material sections, the backwards pistol — so a
/// reader is not finished until something has been drawn from it and looked at. The exact-end
/// arithmetic in <see cref="BspGeometryTests"/> says the bytes were consumed correctly; it cannot
/// say the result is a room.
/// </para>
/// <para>
/// <c>BIOSHOCK_BSP_SNAPSHOT=/tmp/bsp.png</c> writes the images out, one per brush.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class BspRenderingTests(GameFixture game)
{
    private const int Width = 480;
    private const int Height = 480;

    private static void Snapshot(PreviewImage image, string suffix)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_BSP_SNAPSHOT") is not { Length: > 0 } path) return;
        string directory = Path.GetDirectoryName(path) ?? ".";
        string name = Path.GetFileNameWithoutExtension(path);
        Directory.CreateDirectory(directory);
        PngWriter.Write(Path.Combine(directory, $"{name}_{suffix}.png"), image.Rgba, image.Width, image.Height);
    }

    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// Whether a brush's polygons form a closed surface: every directed edge appears exactly once,
    /// and its reverse appears exactly once on the neighbouring face.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Positions are welded before comparison, and that is not a convenience.</b> Comparing the
    /// exact bits first reported 88 of 285 Lighthouse brushes as open, which was this check's own
    /// artefact rather than a property of the data. A brush corner is where three authored planes
    /// meet and it is evaluated per face, so the same corner arrives with different values on each
    /// face — and the spread is larger than it looks: the very first brush inspected has a face
    /// whose two "equal" Z values are <c>-219.98438</c> and <c>-220.0</c>, 0.016 apart. A rounding
    /// bucket was tried first and was still too fine; it is a genuine tolerance search now, checking
    /// neighbouring cells so that a pair straddling a cell boundary still welds.
    /// </para>
    /// <para>
    /// The tolerance is 0.05 cm — three times the observed spread, and far below the smallest brush
    /// feature in the game. Reported, never assumed: <see cref="EveryBrushEnclosesAPositiveVolume"/>
    /// counts what is still open rather than folding it into the result.
    /// </para>
    /// </remarks>
    private static bool IsClosed(BspPolys polys)
    {
        const float tolerance = 0.05f;
        var canonical = new Dictionary<(int, int, int), List<(Vector3 Point, int Id)>>();
        int next = 0;

        int Weld(Vector3 point)
        {
            var cell = ((int)MathF.Floor(point.X / tolerance),
                        (int)MathF.Floor(point.Y / tolerance),
                        (int)MathF.Floor(point.Z / tolerance));

            for (int dx = -1; dx <= 1; dx++)
            for (int dy = -1; dy <= 1; dy++)
            for (int dz = -1; dz <= 1; dz++)
            {
                var neighbour = (cell.Item1 + dx, cell.Item2 + dy, cell.Item3 + dz);
                if (!canonical.TryGetValue(neighbour, out var bucket)) continue;
                foreach (var (existing, id) in bucket)
                    if (Vector3.Distance(existing, point) <= tolerance) return id;
            }

            if (!canonical.TryGetValue(cell, out var own)) canonical[cell] = own = [];
            own.Add((point, next));
            return next++;
        }

        var edges = new Dictionary<(int, int), int>();

        foreach (var polygon in polys.Polygons)
        {
            var v = polygon.Vertices;
            var ids = v.Select(Weld).ToArray();
            for (int i = 0; i < ids.Length; i++)
            {
                var edge = (ids[i], ids[(i + 1) % ids.Length]);
                if (edge.Item1 == edge.Item2) continue;   // a welded-away zero-length edge
                edges[edge] = edges.GetValueOrDefault(edge) + 1;
            }
        }

        foreach (var ((from, to), count) in edges)
        {
            if (count != 1) return false;
            if (edges.GetValueOrDefault((to, from)) != 1) return false;
        }

        return edges.Count > 0;
    }

    private static double Coverage(PreviewImage image, byte background = 32)
    {
        int drawn = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            if (image.Rgba[i] != background || image.Rgba[i + 1] != background || image.Rgba[i + 2] != background)
                drawn++;
        }
        return (double)drawn / (image.Width * image.Height);
    }

    private static PreviewImage Draw(BspPolys polys)
    {
        var geometry = BspGeometry.ToGeometry(polys.Polygons);
        var model = PreviewModel.Build(geometry, null);
        return SoftwareRenderer.Render(
            model,
            PreviewCamera.Frame(model.Centre, model.Radius).Orbit(0.6f, 0.3f),
            new RenderOptions { ShowSkeleton = false, ShowSockets = false },
            Width, Height);
    }

    /// <summary>
    /// The biggest brushes in a shipped map draw as solid objects.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Coverage is the assertion that can actually fail here. A brush whose vertices decoded to
    /// nonsense scatters across the frame or collapses to nothing, and both show up as coverage far
    /// outside the range a convex room-sized solid occupies when the camera is framed on it.
    /// </para>
    /// <para>
    /// It is a weak check and it is meant to be. The image is the result; this only stops the test
    /// from passing on an empty frame, which is exactly how three features went unnoticed in an
    /// earlier session.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheLargestBrushesInAShippedMapDrawAsSolids()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var brushes = PolysReader.Enumerate(package)
            .Select(e => PolysReader.Read(package, e))
            .OrderByDescending(p => p.Polygons.Count)
            .Take(5)
            .ToList();

        Assert.Equal(5, brushes.Count);

        foreach (var brush in brushes)
        {
            var image = Draw(brush);
            Snapshot(image, brush.Source.ObjectName);

            double coverage = Coverage(image);
            Assert.True(coverage is > 0.05 and < 0.98,
                $"{brush.Source.ObjectName} ({brush.Polygons.Count} polygons) covers {coverage:P1} of the frame, "
                + "which is not what a solid framed by the camera looks like");
        }
    }

    /// <summary>
    /// A brush's polygons enclose a volume: it is a closed solid, not a scattering of faces.
    /// </summary>
    /// <remarks>
    /// <para>
    /// This is the check with real teeth, and it is one no coverage or count test can substitute
    /// for. The divergence theorem gives a closed surface's enclosed volume from its faces alone:
    /// summing <c>(A · (B × C)) / 6</c> over outward-wound triangles yields the volume, and it comes
    /// out <b>positive</b> only if the winding is consistently outward. Get the winding backwards
    /// and every brush reports a negative volume of the same magnitude — which is precisely the
    /// failure that the mirrored years and the backwards pistol both were, and which no count sees.
    /// </para>
    /// <para>
    /// So this asserts the sign, not just the magnitude. It is the numeric statement of the same
    /// thing the picture shows.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void EveryBrushEnclosesAPositiveVolume()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        int positive = 0, negative = 0, flat = 0, open = 0, sheet = 0;

        foreach (var export in PolysReader.Enumerate(package))
        {
            var polys = PolysReader.Read(package, export);

            // The volume identity only means anything on a closed surface, so closure is checked
            // first rather than assumed: every directed edge must appear exactly once and its
            // reverse exactly once. An open brush is excluded from the sign test and counted, not
            // quietly folded into it.
            // Fewer than four faces cannot bound a volume at all. Nyko's SDK documents these as
            // real authored content — "single-poly UPolys appear for triangle brushes" — so they
            // are counted as sheets rather than reported as a fault.
            if (polys.Polygons.Count < 4) { sheet++; continue; }

            if (!IsClosed(polys))
            {
                open++;
                Log($"  open brush: {polys.Source.ObjectName}, {polys.Polygons.Count} polygons");
                continue;
            }

            double volume = 0;
            foreach (var (a, b, c) in polys.Polygons.SelectMany(p => p.Triangles()))
                volume += Vector3.Dot(a, Vector3.Cross(b, c)) / 6.0;

            if (Math.Abs(volume) < 1.0) flat++;
            else if (volume > 0) positive++;
            else
            {
                negative++;
                Log($"  inward brush: {polys.Source.ObjectName}, {polys.Polygons.Count} polygons, volume {volume:0}");
            }
        }

        Log($"brush volume: {positive} positive, {negative} negative, {flat} flat, {open} not closed, {sheet} sheets");

        Assert.True(positive > 200, $"only {positive} brushes enclose a positive volume");
        Assert.Equal(0, negative);
    }
}
