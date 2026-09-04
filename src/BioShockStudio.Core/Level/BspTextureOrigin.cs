using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// Resolves a compiled-world surface's texture origin from the source brush polygon it was cut from.
/// </summary>
/// <remarks>
/// <para>
/// <b>Measured on 1-Medical and rejected as a production UV origin</b> (<c>docs/research/bsp.md</c>
/// §5.3a, <c>BspTextureOriginTests</c>). The chain works: surface actor → brush → Polys →
/// <c>polygons[BrushPoly].Base</c> placed by <c>Location − PrePivot</c> resolves for <b>6,242 of
/// 6,667</b> drawn surfaces (93.6%). That world-space point is <b>exactly</b>
/// <c>Model.Points[pBase]</c> (6,242 / 6,242 comparable), and the source poly's <c>Base</c> is
/// already tens of metres from its own vertices in brush space (median ~25,750 cm) — the pan is
/// baked into a distant origin. Absolute texel peaks stay huge (median ~60,700); only the
/// origin-independent span is sane. <see cref="BspGeometry.ToGeometry(BspWorld)"/> therefore keeps
/// measuring from <c>polygon[0]</c>.
/// </para>
/// <para>
/// Kept as a resolver because the equality with <c>Points[pBase]</c> is itself a finding: compiled
/// <c>pBase</c> <i>is</i> a Points index into the pan-baked origin, and the source poly confirms it.
/// Axis cross-check: source <c>TextureU</c>/<c>TextureV</c> agree with
/// <c>Vectors[surface.TextureU/V]</c> within 1% on 2,918 / 2,918 drawn surfaces that resolve.
/// </para>
/// </remarks>
public static class BspTextureOrigin
{
    /// <summary>
    /// World-space texture origin per surface index, or null where the source brush poly cannot be
    /// resolved. Length equals <paramref name="world"/>.Surfaces.Count.
    /// </summary>
    public static IReadOnlyList<Vector3?> Resolve(
        BioShockPackage package, BspWorld world, LevelContext context)
    {
        var origins = new Vector3?[world.Surfaces.Count];
        var brushes = context.Brushes.ToDictionary(a => a.Source.ExportIndex);
        var polyCache = new Dictionary<int, IReadOnlyList<BspPolygon>>();

        for (int i = 0; i < world.Surfaces.Count; i++)
        {
            var surface = world.Surfaces[i];
            if (surface.BrushPoly < 0 || !surface.Actor.IsExport) continue;
            if (!brushes.TryGetValue(surface.Actor.ExportIndex, out var actor)) continue;
            if (actor.Brush?.Source is not { } brushSource) continue;

            if (!polyCache.TryGetValue(surface.Actor.ExportIndex, out var polys))
            {
                polys = ReadBrushPolygons(package, brushSource);
                polyCache[surface.Actor.ExportIndex] = polys;
            }

            if (surface.BrushPoly >= polys.Count) continue;

            // Brush polygon Base is already in the studio basis; Location/PrePivot are game-space.
            // BrushPlacement is CreateTranslation(Convert(Location − PrePivot)) — no rotation/scale
            // on CSG brushes (BrushPlacementTests).
            var poly = polys[surface.BrushPoly];
            var translation = GameBasis.Convert(actor.Transform.Location - actor.Transform.PrePivot);
            origins[i] = poly.Base + translation;
        }

        return origins;
    }

    /// <summary>
    /// The source brush polygon for a surface, when resolvable. Used by diagnostics that also want
    /// the poly's own <c>TextureU</c>/<c>TextureV</c>.
    /// </summary>
    public static BspPolygon? SourcePolygon(
        BioShockPackage package,
        BspSurface surface,
        IReadOnlyDictionary<int, LevelActor> brushes,
        Dictionary<int, IReadOnlyList<BspPolygon>> polyCache)
    {
        if (surface.BrushPoly < 0 || !surface.Actor.IsExport) return null;
        if (!brushes.TryGetValue(surface.Actor.ExportIndex, out var actor)) return null;
        if (actor.Brush?.Source is not { } brushSource) return null;

        if (!polyCache.TryGetValue(surface.Actor.ExportIndex, out var polys))
        {
            polys = ReadBrushPolygons(package, brushSource);
            polyCache[surface.Actor.ExportIndex] = polys;
        }

        if (surface.BrushPoly >= polys.Count) return null;
        return polys[surface.BrushPoly];
    }

    private static IReadOnlyList<BspPolygon> ReadBrushPolygons(BioShockPackage package, SourceId brushSource)
    {
        try
        {
            var brushModel = ModelReader.Read(package, package.Exports[brushSource.ExportIndex]);
            if (brushModel is null) return [];
            if (ModelReader.ResolvePolys(package, brushModel) is not { } export) return [];
            return PolysReader.Read(package, export).Polygons;
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException)
        {
            return [];
        }
    }
}
