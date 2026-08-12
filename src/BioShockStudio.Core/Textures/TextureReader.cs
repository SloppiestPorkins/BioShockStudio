using System.Buffers.Binary;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Textures;

/// <summary>
/// BioShock texture formats, from the <c>Format</c> property.
/// CONFIRMED_BYTES: measured bytes-per-pixel across 0-Lighthouse gives 0.5 for 3, 1.0 for 7 and 8,
/// and 4.0 for 5.
/// </summary>
public enum BioShockTextureFormat
{
    Dxt1 = 3,
    Rgba8 = 5,
    Dxt3 = 7,
    Dxt5 = 8,
}

/// <summary>One mip level.</summary>
public sealed record TextureMip
{
    public required int Width { get; init; }
    public required int Height { get; init; }
    public required byte[] Data { get; init; }
}

/// <summary>A decoded texture: format, dimensions and its mip chain.</summary>
public sealed record BioShockTexture
{
    public required string Name { get; init; }
    public required BioShockTextureFormat Format { get; init; }
    public required int Width { get; init; }
    public required int Height { get; init; }
    public required IReadOnlyList<TextureMip> Mips { get; init; }

    /// <summary>Original authoring path, e.g. a <c>.tga</c> under the art tree. May be empty.</summary>
    public required string SourcePath { get; init; }

    public bool HasAlpha => Format is BioShockTextureFormat.Dxt3 or BioShockTextureFormat.Dxt5 or BioShockTextureFormat.Rgba8;
}

/// <summary>
/// Reads <c>Texture</c> exports.
/// <para>
/// The payload is an Unreal property list (<c>Format</c>, <c>USize</c>, <c>VSize</c>,
/// <c>SourcePath</c>) followed by the mip chain. Mips are located by their trailer rather than by
/// walking the array header, because the header carries a field whose meaning is still unknown:
/// each mip ends with <c>int32 USize, int32 VSize, byte UBits, byte VBits</c>, and
/// <c>USize == 1 &lt;&lt; UBits</c> makes that a reliable signature. The data for a mip is the
/// format's byte count immediately preceding its trailer.
/// </para>
/// </summary>
public static class TextureReader
{
    public const string ClassName = "Texture";

    public static BioShockTexture? Read(BioShockPackage package, ObjectExport export)
    {
        byte[] payload = package.ReadExportData(export);
        if (payload.Length < 64) return null;

        var properties = UnrealPropertyReader.Read(payload, package.Names, out _);

        var format = properties.FirstOrDefault(p => p.Name == "Format");
        var uSize = properties.FirstOrDefault(p => p.Name == "USize");
        var vSize = properties.FirstOrDefault(p => p.Name == "VSize");
        if (format is null || uSize is null || vSize is null) return null;

        var textureFormat = (BioShockTextureFormat)format.AsByte();
        if (!Enum.IsDefined(textureFormat)) return null;

        int width = uSize.AsInt();
        int height = vSize.AsInt();
        if (width <= 0 || height <= 0 || width > 8192 || height > 8192) return null;

        var mips = ReadMips(payload, textureFormat);
        if (mips.Count == 0) return null;

        return new BioShockTexture
        {
            Name = export.ObjectName,
            Format = textureFormat,
            Width = mips[0].Width,
            Height = mips[0].Height,
            Mips = mips,
            SourcePath = ReadSourcePath(properties),
        };
    }

    /// <summary>Bytes needed for one mip at the given size.</summary>
    public static int DataSize(BioShockTextureFormat format, int width, int height) => format switch
    {
        BioShockTextureFormat.Dxt1 => Blocks(width) * Blocks(height) * 8,
        BioShockTextureFormat.Dxt3 or BioShockTextureFormat.Dxt5 => Blocks(width) * Blocks(height) * 16,
        BioShockTextureFormat.Rgba8 => width * height * 4,
        _ => throw new NotSupportedException($"Unsupported texture format {format}."),
    };

    private static int Blocks(int size) => Math.Max(1, (size + 3) / 4);

    private static List<TextureMip> ReadMips(byte[] payload, BioShockTextureFormat format)
    {
        var mips = new List<TextureMip>();

        for (int offset = 0; offset + 10 <= payload.Length; offset++)
        {
            int width = BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(offset));
            int height = BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(offset + 4));
            byte widthBits = payload[offset + 8];
            byte heightBits = payload[offset + 9];

            if (width <= 0 || height <= 0 || width > 8192 || height > 8192) continue;
            if (widthBits > 13 || heightBits > 13) continue;
            if (1 << widthBits != width || 1 << heightBits != height) continue;

            int size = DataSize(format, width, height);
            int start = offset - size;
            if (start < 0) continue;

            mips.Add(new TextureMip
            {
                Width = width,
                Height = height,
                Data = payload.AsSpan(start, size).ToArray(),
            });

            offset += 9;
        }

        // Largest first, which is the order every consumer expects.
        return mips.OrderByDescending(m => m.Width * m.Height).ToList();
    }

    private static string ReadSourcePath(List<UnrealProperty> properties)
    {
        var property = properties.FirstOrDefault(p => p.Name == "SourcePath");
        if (property is null || property.Value.Length < 6) return string.Empty;

        // FCompactIndex character count, then UTF-16LE including a terminator.
        int offset = 0;
        byte first = property.Value[offset++];
        int count = first & 0x3F;
        if ((first & 0x40) != 0)
        {
            int shift = 6;
            while (offset < property.Value.Length)
            {
                byte b = property.Value[offset++];
                count |= (b & 0x7F) << shift;
                shift += 7;
                if ((b & 0x80) == 0) break;
            }
        }

        int bytes = Math.Max(0, (count - 1) * 2);
        if (offset + bytes > property.Value.Length) return string.Empty;
        return System.Text.Encoding.Unicode.GetString(property.Value, offset, bytes);
    }
}
