using System.Buffers.Binary;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.UI.Swf;

/// <summary>
/// Parses Scaleform tag 512 (raw DXT bitmap) into an RGBA8 <see cref="SwfBitmap"/>. Header layout
/// confirmed 5 Sept 2026 on HUDPC.swf (14 blocks) and mirrored across sharedlibrary / HUDRadial /
/// pausePC — see <c>docs/UI_ROADMAP.md</c>. Payload is handed to
/// <see cref="BlockCompression.Decode"/>; this reader does not reimplement DXT.
/// </summary>
public static class SwfBitmapReader
{
    /// <summary>Scaleform / GFx DefineBits DXT tag code used by BioShock FlashMovies.</summary>
    public const int TagCode = 512;

    public static SwfBitmap Read(byte[] body)
    {
        if (body.Length < 10)
            throw new InvalidDataException($"tag {TagCode} body too short ({body.Length} bytes).");

        int characterId = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(0, 2));
        int width = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(2, 2));
        int height = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(4, 2));
        ushort formatRaw = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(6, 2));
        ushort flags = BinaryPrimitives.ReadUInt16LittleEndian(body.AsSpan(8, 2));
        ReadOnlySpan<byte> payload = body.AsSpan(10);

        if (width <= 0 || height <= 0)
            throw new InvalidDataException($"tag {TagCode} id {characterId}: invalid size {width}x{height}.");

        SwfBitmapFormat format = formatRaw switch
        {
            (ushort)SwfBitmapFormat.Dxt1 => SwfBitmapFormat.Dxt1,
            (ushort)SwfBitmapFormat.Dxt5 => SwfBitmapFormat.Dxt5,
            _ => throw new NotSupportedException(
                $"tag {TagCode} id {characterId}: unknown format {formatRaw} (expected 0=DXT1 or 4=DXT5)."),
        };

        int expected = format switch
        {
            SwfBitmapFormat.Dxt5 => width * height,       // 1 byte/px (16 bytes per 4x4)
            SwfBitmapFormat.Dxt1 => width * height / 2,   // 0.5 byte/px (8 bytes per 4x4)
            _ => throw new NotSupportedException($"tag {TagCode}: format {format}"),
        };
        if (payload.Length < expected)
        {
            throw new InvalidDataException(
                $"tag {TagCode} id {characterId}: payload {payload.Length} bytes, expected >= {expected} for {width}x{height} {format}.");
        }

        BioShockTextureFormat dxt = format == SwfBitmapFormat.Dxt5
            ? BioShockTextureFormat.Dxt5
            : BioShockTextureFormat.Dxt1;
        byte[] rgba = BlockCompression.Decode(dxt, payload[..expected], width, height);

        return new SwfBitmap
        {
            CharacterId = characterId,
            Width = width,
            Height = height,
            Format = format,
            Flags = flags,
            Rgba = rgba,
        };
    }
}
