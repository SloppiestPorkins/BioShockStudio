using BioShockStudio.Core.UI.Swf.Shapes;

namespace BioShockStudio.Core.UI.Swf;

/// <summary>
/// Flattens a DefineSprite (or a bare DefineShape) into one combined edge/fill-style list —
/// the first frame only (a static render, matching how BioShock's UI files ship: HUDPC.swf
/// itself is a single-frame movie). Depth-ordered children are composited back-to-front, each
/// transformed by its own PlaceObject2 matrix composed with every ancestor sprite's matrix.
/// </summary>
public static class SwfSpriteComposer
{
    private const int MaxDepthGuard = 32; // real BioShock UI nesting is shallow; this only guards against a malformed/cyclic reference looping forever.

    public static SwfShape Compose(int characterId, SwfCharacterDictionary dict)
    {
        var edges = new List<SwfEdge>();
        var fillStyles = new List<SwfFillStyle>();
        ComposeInto(characterId, dict, SwfMatrix.Identity, edges, fillStyles, 0);

        return new SwfShape
        {
            CharacterId = characterId,
            Bounds = MeasureBounds(edges),
            FillStyles = fillStyles,
            LineStyles = [],
            Edges = edges,
        };
    }

    private static void ComposeInto(
        int characterId, SwfCharacterDictionary dict, SwfMatrix transform,
        List<SwfEdge> edges, List<SwfFillStyle> fillStyles, int depthGuard)
    {
        if (depthGuard > MaxDepthGuard) return;

        if (dict.TryGetShape(characterId, out SwfShape shape))
        {
            int offset = fillStyles.Count;
            fillStyles.AddRange(shape.FillStyles);
            foreach (SwfEdge e in shape.Edges)
            {
                var (x0, y0) = transform.Apply(e.X0, e.Y0);
                var (x1, y1) = transform.Apply(e.X1, e.Y1);
                edges.Add(new SwfEdge(
                    x0, y0, x1, y1,
                    e.FillStyle0 == 0 ? 0 : e.FillStyle0 + offset,
                    e.FillStyle1 == 0 ? 0 : e.FillStyle1 + offset));
            }
            return;
        }

        if (!dict.TryGetSprite(characterId, out IReadOnlyList<SwfTag> controlTags)) return;

        // Depth -> current placement. A later PlaceObject2 at the same depth (Move flag) replaces
        // it; RemoveObject/2 clears it. Rendered once the first ShowFrame is hit (or the control
        // stream ends) — first-frame-only, matching every checked BioShock UI file being a single
        // frame movie.
        var placements = new SortedDictionary<int, (int CharId, SwfMatrix Matrix)>();
        foreach (SwfTag tag in controlTags)
        {
            switch (tag.Code)
            {
                case 26: // PlaceObject2
                {
                    SwfPlaceObject place = SwfPlaceObjectReader.ReadPlaceObject2(tag.Body);
                    SwfMatrix matrix = place.Matrix ?? SwfMatrix.Identity;
                    if (place.CharacterId is int cid)
                    {
                        placements[place.Depth] = (cid, matrix);
                    }
                    else if (place.Move && placements.TryGetValue(place.Depth, out var existing))
                    {
                        placements[place.Depth] = (existing.CharId, matrix);
                    }
                    break;
                }
                case 5: // RemoveObject
                case 28: // RemoveObject2
                {
                    // Both carry Depth as their last U16; RemoveObject also has a leading
                    // CharacterId U16 RemoveObject2 doesn't. Depth is always the final 2 bytes.
                    if (tag.Body.Length >= 2)
                    {
                        int depth = System.Buffers.Binary.BinaryPrimitives.ReadUInt16LittleEndian(
                            tag.Body.AsSpan(tag.Body.Length - 2, 2));
                        placements.Remove(depth);
                    }
                    break;
                }
                case 1: // ShowFrame — first frame is fully assembled, stop here.
                    goto renderPlacements;
            }
        }

        renderPlacements:
        foreach (var (_, placement) in placements)
        {
            SwfMatrix childTransform = placement.Matrix.Then(transform);
            ComposeInto(placement.CharId, dict, childTransform, edges, fillStyles, depthGuard + 1);
        }
    }

    private static SwfRect MeasureBounds(List<SwfEdge> edges)
    {
        if (edges.Count == 0) return new SwfRect(0, 0, 0, 0);
        double minX = double.MaxValue, minY = double.MaxValue, maxX = double.MinValue, maxY = double.MinValue;
        foreach (SwfEdge e in edges)
        {
            minX = Math.Min(minX, Math.Min(e.X0, e.X1));
            maxX = Math.Max(maxX, Math.Max(e.X0, e.X1));
            minY = Math.Min(minY, Math.Min(e.Y0, e.Y1));
            maxY = Math.Max(maxY, Math.Max(e.Y0, e.Y1));
        }
        return new SwfRect((int)minX, (int)maxX, (int)minY, (int)maxY);
    }
}
