namespace BioShockStudio.Core.UI.Swf.Shapes;

/// <summary>ARGB color, 0-255 per channel (matches how PngWriter/BlockCompression expect pixels).</summary>
public readonly record struct SwfColor(byte R, byte G, byte B, byte A)
{
    public static SwfColor Opaque(byte r, byte g, byte b) => new(r, g, b, 255);
}

public enum SwfFillKind { Solid, LinearGradient, RadialGradient, Bitmap }

/// <summary>
/// A fill style. Gradients keep only their stops' average color (see SwfShapeReader) — full
/// gradient rendering is a later enhancement; average color is closer to the real look than
/// treating an unhandled gradient as solid black or skipping the fill entirely.
/// </summary>
public readonly record struct SwfFillStyle(SwfFillKind Kind, SwfColor Color);

public readonly record struct SwfLineStyle(double WidthPx, SwfColor Color);

/// <summary>
/// One flattened edge belonging to a shape, already resolved to absolute twip coordinates.
/// Curves (SWF quadratic beziers) are flattened into short straight segments at parse time —
/// simplest correct path to a scanline-fillable polygon soup; SwfFillStyleIndex0/1 are the raw
/// 1-based indices from the shape's fill style array (0 = no fill on that side).
/// </summary>
public readonly record struct SwfEdge(double X0, double Y0, double X1, double Y1, int FillStyle0, int FillStyle1);

public sealed class SwfShape
{
    public required int CharacterId { get; init; }
    public required SwfRect Bounds { get; init; }
    public required IReadOnlyList<SwfFillStyle> FillStyles { get; init; }
    public required IReadOnlyList<SwfLineStyle> LineStyles { get; init; }
    public required IReadOnlyList<SwfEdge> Edges { get; init; }
}
