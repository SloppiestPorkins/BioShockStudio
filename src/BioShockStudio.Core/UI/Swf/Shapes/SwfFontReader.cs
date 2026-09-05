using System.Buffers.Binary;
using System.Text;

namespace BioShockStudio.Core.UI.Swf.Shapes;

/// <summary>
/// Parses a DefineFont2 (tag 48) or DefineFont3 (tag 75) body into per-glyph edge lists, reusing
/// <see cref="SwfShapeReader.ReadGlyphShapeRecords"/> for the actual glyph outlines.
/// </summary>
/// <remarks>
/// Glyph coordinates live in an EM-square design space: 1024 units/em for DefineFont2, 20480 for
/// DefineFont3 (SWF spec) — DefineFont3 coordinates are divided by 20 here so every
/// <see cref="SwfGlyph"/> this reader produces is in the same 1024-unit space regardless of which
/// tag it came from.
/// </remarks>
public static class SwfFontReader
{
    private const int HasLayout = 0x80;
    private const int WideOffsets = 0x08;
    private const int WideCodes = 0x04;
    private const int Italic = 0x02;
    private const int Bold = 0x01;

    public static SwfFont Read(byte[] body, int tagCode)
    {
        if (tagCode is not (48 or 75))
            throw new ArgumentException($"tag {tagCode} is not DefineFont2/3");
        double unitScale = tagCode == 75 ? 1.0 / 20.0 : 1.0;

        int pos = 0;
        int fontId = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
        pos += 2;
        int flags = body[pos];
        pos += 1;
        bool wideOffsets = (flags & WideOffsets) != 0;
        bool wideCodes = (flags & WideCodes) != 0;
        bool hasLayout = (flags & HasLayout) != 0;
        bool isItalic = (flags & Italic) != 0;
        bool isBold = (flags & Bold) != 0;

        pos += 1; // LanguageCode
        int nameLen = body[pos];
        pos += 1;
        string name = Encoding.UTF8.GetString(body, pos, nameLen);
        pos += nameLen;

        int numGlyphs = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
        pos += 2;

        int offsetTableStart = pos;
        var glyphOffsets = new int[numGlyphs];
        for (int i = 0; i < numGlyphs; i++)
        {
            glyphOffsets[i] = wideOffsets
                ? (int)BinaryPrimitives.ReadUInt32LittleEndian(body.AsSpan(pos, 4))
                : BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
            pos += wideOffsets ? 4 : 2;
        }
        // CodeTableOffset immediately follows the NumGlyphs-th offset table entry, same width.
        // (Empirically verified 5 Sept 2026 against fonts.swf's font 7: this layout gives a clean
        // ascending ASCII code table starting at 32 (space); a NumGlyphs+1-entry table does not.)
        int codeTableOffset = wideOffsets
            ? (int)BinaryPrimitives.ReadUInt32LittleEndian(body.AsSpan(pos, 4))
            : BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));

        var edgesByGlyph = new List<SwfEdge>[numGlyphs];
        for (int i = 0; i < numGlyphs; i++)
        {
            int glyphPos = offsetTableStart + glyphOffsets[i];
            var bits = new SwfBitReader(body.AsSpan(glyphPos));
            IReadOnlyList<SwfEdge> raw = SwfShapeReader.ReadGlyphShapeRecords(ref bits, body);
            edgesByGlyph[i] = unitScale == 1.0
                ? new List<SwfEdge>(raw)
                : raw.Select(e => new SwfEdge(
                    e.X0 * unitScale, e.Y0 * unitScale, e.X1 * unitScale, e.Y1 * unitScale,
                    e.FillStyle0, e.FillStyle1)).ToList();
        }

        pos = offsetTableStart + codeTableOffset;
        var codes = new int[numGlyphs];
        for (int i = 0; i < numGlyphs; i++)
        {
            codes[i] = wideCodes
                ? BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2))
                : body[pos];
            pos += wideCodes ? 2 : 1;
        }

        var advances = new double[numGlyphs];
        if (hasLayout)
        {
            pos += 6; // FontAscent, FontDescent, FontLeading — not carried on SwfGlyph yet.
            for (int i = 0; i < numGlyphs; i++)
            {
                short raw = (short)BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
                advances[i] = raw * unitScale;
                pos += 2;
            }
            // FontBoundsTable (RECT[NumGlyphs]) and KerningTable follow. Not read: RECT entries in
            // this table do not reliably byte-align between entries (tested 5 Sept 2026 against
            // fonts.swf — trusting them produced degenerate (0,0,0,0) bounds, rendering every
            // glyph as fully transparent), and nothing downstream of this reader needs kerning.
            // MeasureBounds from the glyph's own edges below is unambiguous and always correct.
        }

        var glyphs = new SwfGlyph[numGlyphs];
        for (int i = 0; i < numGlyphs; i++)
        {
            SwfRect bounds = MeasureBounds(edgesByGlyph[i]);
            glyphs[i] = new SwfGlyph
            {
                CharCode = codes[i],
                Edges = edgesByGlyph[i],
                Bounds = bounds,
                AdvanceWidth = advances[i],
            };
        }

        return new SwfFont
        {
            FontId = fontId,
            Name = name,
            Bold = isBold,
            Italic = isItalic,
            Glyphs = glyphs,
        };
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
