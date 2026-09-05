using System.Buffers.Binary;
using System.IO.Compression;

namespace BioShockStudio.Core.UI.Swf;

/// <summary>One SWF tag: its type code and raw body (RECORDHEADER already stripped).</summary>
public readonly record struct SwfTag(int Code, byte[] Body);

/// <summary>
/// A parsed SWF file: header fields and its flat top-level tag stream. Every BioShock Remastered
/// UI file checked so far (5 Sept 2026 — HUD, shared component library, fonts, hacking minigame)
/// is signature "FWS" (uncompressed); "CWS" (zlib) and "ZWS" (LZMA) are handled too since nothing
/// guarantees every one of the 48 FlashMovies files stays uncompressed.
/// </summary>
public sealed class SwfFile
{
    public required int Version { get; init; }
    public required SwfRect FrameSize { get; init; }
    public required double FrameRate { get; init; }
    public required int FrameCount { get; init; }
    public required IReadOnlyList<SwfTag> Tags { get; init; }

    public static SwfFile Read(string path) => Read(File.ReadAllBytes(path));

    public static SwfFile Read(byte[] raw)
    {
        if (raw.Length < 8) throw new InvalidDataException("SWF file too short for a header.");

        string signature = System.Text.Encoding.ASCII.GetString(raw, 0, 3);
        int version = raw[3];
        uint fileLength = BinaryPrimitives.ReadUInt32LittleEndian(raw.AsSpan(4, 4));

        byte[] body = signature switch
        {
            "FWS" => raw[8..],
            "CWS" => Inflate(raw.AsSpan(8)),
            "ZWS" => throw new NotSupportedException(
                "LZMA-compressed SWF (ZWS) not yet supported — none of the checked FlashMovies files use it."),
            _ => throw new InvalidDataException($"Not an SWF file (signature '{signature}').")
        };

        var bits = new SwfBitReader(body);
        SwfRect frameSize = bits.ReadRect();
        bits.AlignToByte();
        int pos = bits.BytePosition;

        // FrameRate: 8.8 fixed point. FrameCount: u16. Both byte-aligned, right after the RECT.
        double frameRate = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos, 2)) / 256.0;
        int frameCount = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(pos + 2, 2));
        pos += 4;

        var tags = ReadTagStream(body, pos);

        return new SwfFile
        {
            Version = version,
            FrameSize = frameSize,
            FrameRate = frameRate,
            FrameCount = frameCount,
            Tags = tags,
        };
    }

    /// <summary>
    /// Shared by the top-level file and DefineSprite (a sprite's body is the same tag-stream
    /// format, minus the outer file header).
    /// </summary>
    public static IReadOnlyList<SwfTag> ReadTagStream(byte[] data, int start)
    {
        var tags = new List<SwfTag>();
        int pos = start;
        while (pos + 2 <= data.Length)
        {
            ushort tagCodeAndLength = BinaryPrimitives.ReadUInt16LittleEndian(data.AsSpan(pos, 2));
            int code = tagCodeAndLength >> 6;
            int length = tagCodeAndLength & 0x3F;
            pos += 2;
            if (length == 0x3F)
            {
                length = (int)BinaryPrimitives.ReadUInt32LittleEndian(data.AsSpan(pos, 4));
                pos += 4;
            }
            if (code == 0) break; // End tag.
            if (pos + length > data.Length)
            {
                // A truncated/corrupt tail is a data problem, not a parser bug — stop cleanly
                // rather than throw, so callers can still use whatever tags decoded so far.
                break;
            }
            tags.Add(new SwfTag(code, data.AsSpan(pos, length).ToArray()));
            pos += length;
        }
        return tags;
    }

    private static byte[] Inflate(ReadOnlySpan<byte> zlibBody)
    {
        // .NET's ZLibStream expects the raw zlib stream (2-byte header + deflate + adler32),
        // which is exactly what follows an SWF's 8-byte header for a "CWS" file.
        using var input = new MemoryStream(zlibBody.ToArray());
        using var zlib = new ZLibStream(input, CompressionMode.Decompress);
        using var output = new MemoryStream();
        zlib.CopyTo(output);
        return output.ToArray();
    }
}
