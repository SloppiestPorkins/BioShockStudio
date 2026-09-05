using BioShockStudio.Core.UI.Swf.Shapes;

namespace BioShockStudio.Core.UI.Swf.Rendering;

/// <summary>
/// Renders a parsed <see cref="SwfShape"/> to a flat RGBA buffer (row-major, 4 bytes/pixel — the
/// layout <c>PngWriter.Write</c> already expects) using a nonzero-winding scanline fill.
/// </summary>
/// <remarks>
/// SWF's shape model has no notion of "polygon boundary" — every edge just carries which fill
/// style is on its left (<c>FillStyle1</c>) and right (<c>FillStyle0</c>) side, per the spec's
/// edge-direction convention. For a given fill style, orienting every contributing edge so the
/// fill is consistently on the left (reversing edges where the style is on <c>FillStyle0</c>
/// instead of <c>FillStyle1</c>) turns that into an ordinary directed-edge soup a standard
/// nonzero-winding scanline fill already knows how to handle — no explicit polygon/contour
/// extraction needed.
/// </remarks>
public static class SwfShapeRasterizer
{
    public static byte[] Rasterize(SwfShape shape, int width, int height)
    {
        var pixels = new byte[width * height * 4];

        double twipsWidth = shape.Bounds.XMax - shape.Bounds.XMin;
        double twipsHeight = shape.Bounds.YMax - shape.Bounds.YMin;
        if (twipsWidth <= 0 || twipsHeight <= 0) return pixels;

        // Anti-aliasing via supersampling: render N sub-scanlines per output row and average
        // coverage. Cheap and simple, and this renderer never needs to run at real-time rates.
        const int samplesPerPixel = 4;

        for (int styleIndex = 1; styleIndex <= shape.FillStyles.Count; styleIndex++)
        {
            SwfFillStyle style = shape.FillStyles[styleIndex - 1];
            var directedEdges = new List<(double x0, double y0, double x1, double y1)>();
            foreach (SwfEdge edge in shape.Edges)
            {
                if (edge.FillStyle1 == styleIndex)
                {
                    directedEdges.Add((edge.X0, edge.Y0, edge.X1, edge.Y1));
                }
                if (edge.FillStyle0 == styleIndex)
                {
                    directedEdges.Add((edge.X1, edge.Y1, edge.X0, edge.Y0));
                }
            }
            if (directedEdges.Count == 0) continue;

            RasterizeFill(pixels, width, height, shape.Bounds, directedEdges, style.Color, samplesPerPixel);
        }

        return pixels;
    }

    private static void RasterizeFill(
        byte[] pixels, int width, int height, SwfRect bounds,
        List<(double x0, double y0, double x1, double y1)> edges, SwfColor color, int samplesPerPixel)
    {
        double twipsWidth = bounds.XMax - bounds.XMin;
        double twipsHeight = bounds.YMax - bounds.YMin;
        var coverage = new float[width];

        for (int py = 0; py < height; py++)
        {
            Array.Clear(coverage);

            for (int s = 0; s < samplesPerPixel; s++)
            {
                double sampleY = py + (s + 0.5) / samplesPerPixel;
                double shapeY = bounds.YMin + sampleY / height * twipsHeight;

                var crossings = new List<(double x, int winding)>();
                foreach (var (x0, y0, x1, y1) in edges)
                {
                    bool crossesUp = y0 <= shapeY && shapeY < y1;
                    bool crossesDown = y1 <= shapeY && shapeY < y0;
                    if (!crossesUp && !crossesDown) continue;

                    double t = (shapeY - y0) / (y1 - y0);
                    double xAtY = x0 + t * (x1 - x0);
                    int winding = y1 > y0 ? 1 : -1;
                    crossings.Add((xAtY, winding));
                }
                if (crossings.Count == 0) continue;
                crossings.Sort((a, b) => a.x.CompareTo(b.x));

                // Sweep left to right, turning nonzero-winding transitions into filled (start, end)
                // spans directly.
                int windingSum = 0;
                double spanStartX = 0;
                bool inSpan = false;
                foreach (var (x, winding) in crossings)
                {
                    bool wasInside = windingSum != 0;
                    windingSum += winding;
                    bool nowInside = windingSum != 0;
                    if (!wasInside && nowInside)
                    {
                        spanStartX = x;
                        inSpan = true;
                    }
                    else if (wasInside && !nowInside && inSpan)
                    {
                        AccumulateSpanCoverage(coverage, width, bounds.XMin, twipsWidth, spanStartX, x, 1.0f / samplesPerPixel);
                        inSpan = false;
                    }
                }
            }

            int rowOffset = py * width * 4;
            for (int px = 0; px < width; px++)
            {
                float alpha = Math.Clamp(coverage[px], 0f, 1f) * (color.A / 255f);
                if (alpha <= 0f) continue;
                int o = rowOffset + px * 4;
                // Straight (non-premultiplied) alpha-over-existing-transparent-background compose —
                // fine here because fills within one shape don't overlap by construction (SWF edges
                // partition the plane), so there's never a non-transparent destination to blend onto.
                pixels[o + 0] = color.R;
                pixels[o + 1] = color.G;
                pixels[o + 2] = color.B;
                pixels[o + 3] = (byte)Math.Clamp(alpha * 255f, 0f, 255f);
            }
        }
    }

    private static void AccumulateSpanCoverage(
        float[] coverage, int width, double boundsXMin, double twipsWidth,
        double spanStartTwips, double spanEndTwips, float weight)
    {
        double startPx = (spanStartTwips - boundsXMin) / twipsWidth * width;
        double endPx = (spanEndTwips - boundsXMin) / twipsWidth * width;
        if (endPx < startPx) (startPx, endPx) = (endPx, startPx);

        int firstPixel = Math.Max(0, (int)Math.Floor(startPx));
        int lastPixel = Math.Min(width - 1, (int)Math.Ceiling(endPx) - 1);
        for (int px = firstPixel; px <= lastPixel; px++)
        {
            double pixelStart = px, pixelEnd = px + 1;
            double overlap = Math.Min(pixelEnd, endPx) - Math.Max(pixelStart, startPx);
            if (overlap > 0) coverage[px] += (float)(overlap * weight);
        }
    }
}
