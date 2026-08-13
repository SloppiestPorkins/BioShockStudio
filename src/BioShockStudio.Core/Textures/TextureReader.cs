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

    /// <summary>
    /// The size the texture declares, which is not the size the package carries: most are shipped
    /// with their top levels stripped into the bulk store.
    /// </summary>
    public int DeclaredWidth { get; init; }

    public int DeclaredHeight { get; init; }

    /// <summary>How many top levels were stripped out.</summary>
    public int StrippedMipCount { get; init; }

    /// <summary>True when the mips present reach the size the texture declares.</summary>
    public bool IsComplete => DeclaredWidth == 0 || Width >= DeclaredWidth;

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

    /// <summary>Format and dimensions, without locating or decoding the mip chain.</summary>
    /// <remarks>
    /// The property list sits at the front of the payload, so this reads a couple of kilobytes
    /// rather than the whole export. That matters at catalogue scale: the shipped textures total
    /// gigabytes, and listing them should not read any of it.
    /// </remarks>
    public static (BioShockTextureFormat Format, int Width, int Height)? ReadHeader(
        BioShockPackage package, ObjectExport export)
    {
        if (export.SerialSize < 64) return null;

        var buffer = new byte[Math.Min(HeaderProbeSize, export.SerialSize)];
        using (var stream = package.OpenExportStream(export))
        {
            int read = stream.ReadAtLeast(buffer, buffer.Length, throwOnEndOfStream: false);
            if (read < 64) return null;
        }

        List<UnrealProperty> properties;
        try { properties = UnrealPropertyReader.Read(buffer, package.Names, out _); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        var format = properties.FirstOrDefault(p => p.Name == "Format");
        var uSize = properties.FirstOrDefault(p => p.Name == "USize");
        var vSize = properties.FirstOrDefault(p => p.Name == "VSize");
        if (format is null || uSize is null || vSize is null) return null;

        var textureFormat = (BioShockTextureFormat)format.AsByte();
        if (!Enum.IsDefined(textureFormat)) return null;

        int width = uSize.AsInt();
        int height = vSize.AsInt();
        if (width <= 0 || height <= 0 || width > 8192 || height > 8192) return null;

        return (textureFormat, width, height);
    }

    /// <summary>How much of a texture payload the header probe reads.</summary>
    private const int HeaderProbeSize = 4096;

    /// <summary>
    /// Reads a texture, restoring its stripped mips from the bulk store when one is supplied.
    /// </summary>
    /// <param name="bulk">
    /// The bulk catalogue, or null to read only what the package carries — which for most textures
    /// is the bottom of the chain, 64 square or less.
    /// </param>
    /// <param name="group">The asset group, used to disambiguate a name that appears in several.</param>
    public static BioShockTexture? Read(
        BioShockPackage package, ObjectExport export, BulkTextureCatalog? bulk = null, string? group = null)
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

        // Most textures ship with their top levels removed and kept in the bulk store, so what the
        // package holds is the tail of the chain. Put the rest back when it can be found.
        int stripped = properties.FirstOrDefault(p => p.Name == "StrippedNumMips")?.AsByte() ?? 0;
        if (stripped > 0 && bulk is not null)
        {
            var recovered = RecoverStrippedMips(bulk, export.ObjectName, group, textureFormat, width, height, mips[0].Width);
            if (recovered.Count > 0) mips.InsertRange(0, recovered);
        }

        return new BioShockTexture
        {
            Name = export.ObjectName,
            Format = textureFormat,
            Width = mips[0].Width,
            Height = mips[0].Height,
            Mips = mips,
            SourcePath = ReadSourcePath(properties),
            DeclaredWidth = width,
            DeclaredHeight = height,
            StrippedMipCount = stripped,
        };
    }

    /// <summary>
    /// Splits a bulk blob into the mip levels it holds, largest first.
    /// </summary>
    /// <remarks>
    /// The blob is the stripped levels concatenated, and the catalogue's size is their exact sum, so
    /// the split is arithmetic rather than a search. It is only accepted when it consumes the blob
    /// to the byte and lands on the size the package's own top mip already is — which is what makes
    /// this the right texture's data and not a plausible offset into eight gigabytes.
    /// </remarks>
    private static List<TextureMip> RecoverStrippedMips(
        BulkTextureCatalog bulk,
        string textureName,
        string? group,
        BioShockTextureFormat format,
        int declaredWidth,
        int declaredHeight,
        int packageTopWidth)
    {
        var entry = bulk.Find(textureName, group);
        if (entry is null) return [];

        // The blob's size is the sum of the levels it holds, exactly — so rather than trusting
        // StrippedNumMips, find the run of levels that adds up to it. The count in the property is
        // right on most textures and wrong on about two thirds, and the arithmetic is not.
        var sizes = FindChain(format, declaredWidth, declaredHeight, entry.Size);
        if (sizes.Count == 0) return [];

        // It has to stop exactly where the package's own chain starts, or it is not this texture's
        // missing head — the seam is the whole point.
        if (sizes[^1].Width != packageTopWidth * 2) return [];

        byte[]? blob = bulk.Read(entry);
        if (blob is null || blob.Length != entry.Size) return [];

        var mips = new List<TextureMip>(sizes.Count);
        int offset = 0;

        foreach (var (width, height) in sizes)
        {
            int size = DataSize(format, width, height);
            mips.Add(new TextureMip
            {
                Width = width,
                Height = height,
                Data = blob.AsSpan(offset, size).ToArray(),
            });
            offset += size;
        }

        return mips;
    }

    /// <summary>
    /// The run of mip levels, largest first, whose sizes add up to exactly <paramref name="total"/>.
    /// </summary>
    /// <remarks>
    /// Starts at the declared size and walks down, and if that does not add up, starts a level lower
    /// and tries again — some textures store fewer levels than their dimensions would suggest.
    /// Returns nothing rather than a near miss: a chain that does not add up exactly is not the
    /// chain, and reading it would put one texture's bytes into another's mip.
    /// </remarks>
    private static List<(int Width, int Height)> FindChain(
        BioShockTextureFormat format, int declaredWidth, int declaredHeight, int total)
    {
        int width = declaredWidth, height = declaredHeight;

        while (width >= 1 && height >= 1)
        {
            var levels = new List<(int Width, int Height)>();
            long sum = 0;
            int w = width, h = height;

            while (w >= 1 && h >= 1 && sum < total)
            {
                levels.Add((w, h));
                sum += DataSize(format, w, h);
                if (sum == total) return levels;
                w = Math.Max(1, w / 2);
                h = Math.Max(1, h / 2);
                if (w == 1 && h == 1 && sum < total) break;
            }

            width = Math.Max(1, width / 2);
            height = Math.Max(1, height / 2);
            if (width == 1 && height == 1) break;
        }

        return [];
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
