using System.Buffers.Binary;

namespace BioShockStudio.Core.UI.Swf.Shapes;

/// <summary>
/// Parses a DefineShape/DefineShape2/DefineShape3/DefineShape4 tag body into a flattened edge
/// list ready for scanline rasterization. None of the checked BioShock Remastered UI files
/// (HUD, shared component library, fonts, hacking minigame) declare a single bitmap fill —
/// bitmap fill styles are recognized (so stream position stays correct) but rendered as a flat
/// mid-grey placeholder rather than decoded, since there's nothing in this game's data to
/// exercise that path against.
/// </summary>
public static class SwfShapeReader
{
    /// <summary>
    /// A glyph's shape record stream (used by DefineFont2/3): no FILLSTYLEARRAY/LINESTYLEARRAY
    /// precedes it — just NumFillBits(4)/NumLineBits(4) directly, then the same StyleChangeRecord/
    /// edge stream as a full shape, with a single implicit fill (index 1 = "inside the glyph").
    /// Glyph shapes never carry StateNewStyles (no style array exists to replace).
    /// </summary>
    public static IReadOnlyList<SwfEdge> ReadGlyphShapeRecords(ref SwfBitReader bits, byte[] body)
    {
        int numFillBits = (int)bits.ReadUnsigned(4);
        int numLineBits = (int)bits.ReadUnsigned(4);
        return ReadShapeRecords(ref bits, body, 1, [], [], numFillBits, numLineBits);
    }

    public static SwfShape Read(byte[] body, int tagCode)
    {
        int version = tagCode switch
        {
            2 => 1,
            22 => 2,
            32 => 3,
            83 => 4,
            _ => throw new ArgumentException($"tag {tagCode} is not a DefineShape variant"),
        };

        int pos = 0;
        int characterId = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
        pos += 2;

        var bitsForBounds = new SwfBitReader(body.AsSpan(pos));
        SwfRect bounds = bitsForBounds.ReadRect();
        pos += bitsForBounds.BytePosition;

        if (version == 4)
        {
            // EdgeBounds RECT, then Reserved(5) UsesFillWindingRule(1) UsesNonScalingStrokes(1)
            // UsesScalingStrokes(1) — one byte-aligned byte's worth of flag bits after the RECT
            // aligns back to a byte boundary, so just skip the RECT and one flag byte.
            var edgeBoundsReader = new SwfBitReader(body.AsSpan(pos));
            edgeBoundsReader.ReadRect();
            pos += edgeBoundsReader.BytePosition;
            pos += 1; // flag byte (winding rule / stroke scaling flags)
        }

        var (fillStyles, afterFills) = ReadFillStyleArray(body, pos, version);
        pos = afterFills;
        var (lineStyles, afterLines) = ReadLineStyleArray(body, pos, version);
        pos = afterLines;

        var shapeBits = new SwfBitReader(body.AsSpan(pos));
        int numFillBits = (int)shapeBits.ReadUnsigned(4);
        int numLineBits = (int)shapeBits.ReadUnsigned(4);

        var edges = ReadShapeRecords(ref shapeBits, body, version, fillStyles, lineStyles, numFillBits, numLineBits);

        return new SwfShape
        {
            CharacterId = characterId,
            Bounds = bounds,
            FillStyles = fillStyles,
            LineStyles = lineStyles,
            Edges = edges,
        };
    }

    private static (List<SwfFillStyle> styles, int pos) ReadFillStyleArray(byte[] body, int pos, int version)
    {
        int count = body[pos];
        pos += 1;
        if (count == 0xFF)
        {
            count = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
            pos += 2;
        }

        var styles = new List<SwfFillStyle>(count);
        for (int i = 0; i < count; i++)
        {
            byte type = body[pos];
            pos += 1;
            switch (type)
            {
                case 0x00:
                {
                    SwfColor color = version >= 3 ? ReadRgba(body, ref pos) : ReadRgbOpaque(body, ref pos);
                    styles.Add(new SwfFillStyle(SwfFillKind.Solid, color));
                    break;
                }
                case 0x10:
                case 0x12:
                case 0x13: // Focal radial gradient (SWF8+): same GRADIENT plus a focal-point fixed8.8 after it.
                {
                    // GradientMatrix is a MATRIX record (variable bit width, not a fixed size).
                    var matrixBits = new SwfBitReader(body.AsSpan(pos));
                    SkipMatrix(ref matrixBits);
                    pos += matrixBits.BytePosition;

                    SwfColor avg = ReadGradientAverageColor(body, ref pos, version);
                    if (type == 0x13) pos += 2; // FocalPoint: FIXED8

                    var kind = type == 0x12 || type == 0x13 ? SwfFillKind.RadialGradient : SwfFillKind.LinearGradient;
                    styles.Add(new SwfFillStyle(kind, avg));
                    break;
                }
                case 0x40:
                case 0x41:
                case 0x42:
                case 0x43:
                    pos += 2; // BitmapId (U16); BitmapMatrix (MATRIX) follows, variable-length.
                    var bmpMatrixBits = new SwfBitReader(body.AsSpan(pos));
                    SkipMatrix(ref bmpMatrixBits);
                    pos += bmpMatrixBits.BytePosition;
                    styles.Add(new SwfFillStyle(SwfFillKind.Bitmap, new SwfColor(160, 160, 160, 255)));
                    break;
                default:
                    throw new InvalidDataException($"unknown fill style type 0x{type:X2}");
            }
        }
        return (styles, pos);
    }

    private static (List<SwfLineStyle> styles, int pos) ReadLineStyleArray(byte[] body, int pos, int version)
    {
        int count = body[pos];
        pos += 1;
        if (count == 0xFF)
        {
            count = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
            pos += 2;
        }

        var styles = new List<SwfLineStyle>(count);
        for (int i = 0; i < count; i++)
        {
            int widthTwips = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2));
            pos += 2;
            if (version < 4)
            {
                SwfColor color = version >= 3 ? ReadRgba(body, ref pos) : ReadRgbOpaque(body, ref pos);
                styles.Add(new SwfLineStyle(widthTwips / 20.0, color));
            }
            else
            {
                // LINESTYLE2: a run of cap/join/flag bits then optional MiterLimit, then a Color
                // (always RGBA) unless HasFillFlag routes it through a nested FILLSTYLE instead.
                var flagsReader = new SwfBitReader(body.AsSpan(pos));
                flagsReader.ReadUnsigned(2);  // StartCapStyle
                int joinStyle = (int)flagsReader.ReadUnsigned(2);
                bool hasFill = flagsReader.ReadUnsigned(1) != 0;
                flagsReader.ReadUnsigned(1); // NoHScaleFlag
                flagsReader.ReadUnsigned(1); // NoVScaleFlag
                flagsReader.ReadUnsigned(1); // PixelHintingFlag
                flagsReader.ReadUnsigned(5); // Reserved
                flagsReader.ReadUnsigned(1); // NoClose
                flagsReader.ReadUnsigned(2); // EndCapStyle
                pos += flagsReader.BytePosition;
                if (joinStyle == 1) pos += 2; // MiterLimitFactor: FIXED8

                if (hasFill)
                {
                    var (nested, afterNested) = ReadFillStyleArray(body, pos, version);
                    pos = afterNested;
                    SwfColor c = nested.Count > 0 ? nested[0].Color : new SwfColor(0, 0, 0, 255);
                    styles.Add(new SwfLineStyle(widthTwips / 20.0, c));
                }
                else
                {
                    SwfColor color = ReadRgba(body, ref pos);
                    styles.Add(new SwfLineStyle(widthTwips / 20.0, color));
                }
            }
        }
        return (styles, pos);
    }

    private static SwfColor ReadRgbOpaque(byte[] body, ref int pos)
    {
        var c = new SwfColor(body[pos], body[pos + 1], body[pos + 2], 255);
        pos += 3;
        return c;
    }

    private static SwfColor ReadRgba(byte[] body, ref int pos)
    {
        var c = new SwfColor(body[pos], body[pos + 1], body[pos + 2], body[pos + 3]);
        pos += 4;
        return c;
    }

    /// <summary>
    /// GRADIENT/FOCALGRADIENT record: SpreadMode(2) InterpolationMode(2) NumGradients(4), then
    /// that many (Ratio: u8, Color) pairs. Averaged rather than fully rendered — see file summary.
    /// </summary>
    private static SwfColor ReadGradientAverageColor(byte[] body, ref int pos, int version)
    {
        var bits = new SwfBitReader(body.AsSpan(pos));
        bits.ReadUnsigned(2);
        bits.ReadUnsigned(2);
        int numGradients = (int)bits.ReadUnsigned(4);
        pos += bits.BytePosition;

        long r = 0, g = 0, b = 0, a = 0;
        for (int i = 0; i < numGradients; i++)
        {
            pos += 1; // Ratio
            SwfColor c = version >= 3 ? ReadRgba(body, ref pos) : ReadRgbOpaque(body, ref pos);
            r += c.R; g += c.G; b += c.B; a += c.A;
        }
        if (numGradients == 0) return new SwfColor(128, 128, 128, 255);
        return new SwfColor(
            (byte)(r / numGradients), (byte)(g / numGradients), (byte)(b / numGradients), (byte)(a / numGradients));
    }

    /// <summary>MATRIX record: variable-width scale/rotate/translate fields — read and discard.</summary>
    private static void SkipMatrix(ref SwfBitReader bits)
    {
        if (bits.ReadUnsigned(1) != 0)
        {
            int n = (int)bits.ReadUnsigned(5);
            bits.ReadSigned(n);
            bits.ReadSigned(n);
        }
        if (bits.ReadUnsigned(1) != 0)
        {
            int n = (int)bits.ReadUnsigned(5);
            bits.ReadSigned(n);
            bits.ReadSigned(n);
        }
        int nTranslate = (int)bits.ReadUnsigned(5);
        bits.ReadSigned(nTranslate);
        bits.ReadSigned(nTranslate);
    }

    private static List<SwfEdge> ReadShapeRecords(
        ref SwfBitReader bits, byte[] body, int version,
        List<SwfFillStyle> fillStyles, List<SwfLineStyle> lineStyles,
        int numFillBits, int numLineBits)
    {
        var edges = new List<SwfEdge>();
        double x = 0, y = 0;
        int fill0 = 0, fill1 = 0, line = 0;
        // A StateNewStyles record appends a fresh style array rather than replacing it, so edges
        // recorded before the change keep indexing the original array while edges recorded after
        // index into the appended region. Applied the instant fill0/fill1/line are (re-)read, so
        // a value carried over unset across the boundary still means whatever it meant before.
        int fillOffset = 0, lineOffset = 0;

        while (true)
        {
            bool isEdge = bits.ReadUnsigned(1) != 0;
            if (!isEdge)
            {
                uint flags = bits.ReadUnsigned(5);
                if (flags == 0) break; // End-of-shape record.

                bool stateNewStyles = (flags & 0b10000) != 0;
                bool stateLineStyle = (flags & 0b01000) != 0;
                bool stateFillStyle1 = (flags & 0b00100) != 0;
                bool stateFillStyle0 = (flags & 0b00010) != 0;
                bool stateMoveTo = (flags & 0b00001) != 0;

                if (stateMoveTo)
                {
                    int moveBits = (int)bits.ReadUnsigned(5);
                    x = bits.ReadSigned(moveBits);
                    y = bits.ReadSigned(moveBits);
                }
                if (stateFillStyle0)
                {
                    int raw = (int)bits.ReadUnsigned(numFillBits);
                    fill0 = raw == 0 ? 0 : raw + fillOffset; // 0 always means "no fill", never an index.
                }
                if (stateFillStyle1)
                {
                    int raw = (int)bits.ReadUnsigned(numFillBits);
                    fill1 = raw == 0 ? 0 : raw + fillOffset;
                }
                if (stateLineStyle)
                {
                    int raw = (int)bits.ReadUnsigned(numLineBits);
                    line = raw == 0 ? 0 : raw + lineOffset;
                }

                if (stateNewStyles)
                {
                    // Only DefineShape2+ allows mid-shape style changes; reading here mirrors the
                    // writer's own version gate, so an (invalid) v1 file can't desync the reader.
                    byte[] rest = bits.AlignAndCopyRemaining();
                    var (newFills, afterFills) = ReadFillStyleArray(rest, 0, version);
                    var (newLines, afterLines) = ReadLineStyleArray(rest, afterFills, version);

                    fillOffset = fillStyles.Count;
                    lineOffset = lineStyles.Count;
                    fillStyles.AddRange(newFills);
                    lineStyles.AddRange(newLines);

                    bits.SkipBytes(afterLines);
                    numFillBits = (int)bits.ReadUnsigned(4);
                    numLineBits = (int)bits.ReadUnsigned(4);
                }
                continue;
            }

            bool isStraight = bits.ReadUnsigned(1) != 0;
            if (!isStraight)
            {
                int numBits = (int)bits.ReadUnsigned(4) + 2;
                double controlDx = bits.ReadSigned(numBits);
                double controlDy = bits.ReadSigned(numBits);
                double controlX = x + controlDx, controlY = y + controlDy;
                double anchorDx = bits.ReadSigned(numBits);
                double anchorDy = bits.ReadSigned(numBits);
                double anchorX = controlX + anchorDx, anchorY = controlY + anchorDy;

                FlattenQuadratic(x, y, controlX, controlY, anchorX, anchorY, fill0, fill1, edges);
                x = anchorX; y = anchorY;
            }
            else
            {
                int numBits = (int)bits.ReadUnsigned(4) + 2;
                bool general = bits.ReadUnsigned(1) != 0;
                double dx = 0, dy = 0;
                if (general)
                {
                    dx = bits.ReadSigned(numBits);
                    dy = bits.ReadSigned(numBits);
                }
                else
                {
                    bool vertical = bits.ReadUnsigned(1) != 0;
                    double delta = bits.ReadSigned(numBits);
                    if (vertical) dy = delta; else dx = delta;
                }
                double nx = x + dx, ny = y + dy;
                if (fill0 != 0 || fill1 != 0)
                {
                    edges.Add(new SwfEdge(x, y, nx, ny, fill0, fill1));
                }
                x = nx; y = ny;
            }
        }

        return edges;
    }

    private static void FlattenQuadratic(
        double x0, double y0, double cx, double cy, double x1, double y1,
        int fill0, int fill1, List<SwfEdge> edges)
    {
        if (fill0 == 0 && fill1 == 0) return;
        const int steps = 8; // UI-scale glyphs/icons: visually smooth, cheap enough to not matter.
        double px = x0, py = y0;
        for (int i = 1; i <= steps; i++)
        {
            double t = (double)i / steps;
            double mt = 1 - t;
            double x = mt * mt * x0 + 2 * mt * t * cx + t * t * x1;
            double y = mt * mt * y0 + 2 * mt * t * cy + t * t * y1;
            edges.Add(new SwfEdge(px, py, x, y, fill0, fill1));
            px = x; py = y;
        }
    }
}
