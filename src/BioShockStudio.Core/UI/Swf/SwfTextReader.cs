using System.Buffers.Binary;
using BioShockStudio.Core.UI.Swf.Shapes;

namespace BioShockStudio.Core.UI.Swf;

/// <summary>One glyph placement from a DefineText/DefineText2 tag: which font, which glyph
/// (by index into that font's glyph table — not character code), and where.</summary>
public readonly record struct SwfTextGlyphPlacement(
    int FontId, int GlyphIndex, double X, double Y, double HeightTwips, SwfColor Color);

public sealed class SwfTextRun
{
    public required int CharacterId { get; init; }
    public required SwfRect Bounds { get; init; }
    public required SwfMatrix TextMatrix { get; init; }
    public required IReadOnlyList<SwfTextGlyphPlacement> Glyphs { get; init; }
}

/// <summary>
/// Parses DefineText (tag 11) / DefineText2 (tag 33) — static text laid out as a sequence of
/// TEXTRECORDs, each a run of glyphs (by index into a font's own glyph table, not character code)
/// at a shared font/color/height until the next record changes one of those.
/// </summary>
public static class SwfTextReader
{
    public static SwfTextRun Read(byte[] body, int tagCode)
    {
        bool hasAlpha = tagCode == 33;
        int pos = 0;
        int characterId = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
        pos += 2;

        var boundsBits = new SwfBitReader(body.AsSpan(pos));
        SwfRect bounds = boundsBits.ReadRect();
        pos += boundsBits.BytePosition;

        var matrixBits = new SwfBitReader(body.AsSpan(pos));
        SwfMatrix matrix = SwfMatrixReader.Read(ref matrixBits);
        pos += matrixBits.BytePosition;

        int glyphBits = body[pos]; pos += 1;
        int advanceBits = body[pos]; pos += 1;

        var placements = new List<SwfTextGlyphPlacement>();
        int fontId = 0;
        double textHeight = 240; // spec default is undefined until the first HasFont record; 12pt-ish fallback
        double x = 0, y = 0;
        SwfColor color = SwfColor.Opaque(0, 0, 0);

        while (pos < body.Length)
        {
            int flags = body[pos];
            if (flags == 0) { pos += 1; break; } // TEXTRECORD terminator
            pos += 1;

            bool hasFont = (flags & 0x08) != 0;
            bool hasColor = (flags & 0x04) != 0;
            bool hasYOffset = (flags & 0x02) != 0;
            bool hasXOffset = (flags & 0x01) != 0;

            if (hasFont)
            {
                fontId = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
                pos += 2;
            }
            if (hasColor)
            {
                color = hasAlpha
                    ? new SwfColor(body[pos], body[pos + 1], body[pos + 2], body[pos + 3])
                    : SwfColor.Opaque(body[pos], body[pos + 1], body[pos + 2]);
                pos += hasAlpha ? 4 : 3;
            }
            if (hasXOffset)
            {
                x = (short)BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
                pos += 2;
            }
            if (hasYOffset)
            {
                y = (short)BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
                pos += 2;
            }
            if (hasFont)
            {
                textHeight = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
                pos += 2;
            }

            int glyphCount = body[pos]; pos += 1;
            var glyphBitsReader = new SwfBitReader(body.AsSpan(pos));
            for (int i = 0; i < glyphCount; i++)
            {
                int glyphIndex = (int)glyphBitsReader.ReadUnsigned(glyphBits);
                int advance = glyphBitsReader.ReadSigned(advanceBits);
                placements.Add(new SwfTextGlyphPlacement(fontId, glyphIndex, x, y, textHeight, color));
                x += advance;
            }
            pos += glyphBitsReader.BytePosition;
        }

        return new SwfTextRun
        {
            CharacterId = characterId,
            Bounds = bounds,
            TextMatrix = matrix,
            Glyphs = placements,
        };
    }
}
