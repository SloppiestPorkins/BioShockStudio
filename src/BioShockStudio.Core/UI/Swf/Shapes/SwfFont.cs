namespace BioShockStudio.Core.UI.Swf.Shapes;

/// <summary>
/// One glyph from a DefineFont2/3 tag. Edges are in the font's own EM-square design units —
/// 1024 units/em for DefineFont2, 20480 for DefineFont3 (SwfFontReader normalizes both to 1024
/// so callers never need to know which tag a font came from).
/// </summary>
public sealed class SwfGlyph
{
    public required int CharCode { get; init; }
    public required IReadOnlyList<SwfEdge> Edges { get; init; }
    public required SwfRect Bounds { get; init; }
    public double AdvanceWidth { get; init; }
}

public sealed class SwfFont
{
    public required int FontId { get; init; }
    public required string Name { get; init; }
    public required bool Bold { get; init; }
    public required bool Italic { get; init; }
    public required IReadOnlyList<SwfGlyph> Glyphs { get; init; }

    public SwfGlyph? FindByChar(char c) => Glyphs.FirstOrDefault(g => g.CharCode == c);
}
