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

    /// <summary>
    /// 3DC — BC5 / ATI2, two channels, used for normal maps.
    /// </summary>
    /// <remarks>
    /// <c>CONFIRMED_EXTERNAL</c> from Nyko's texture note, whose <c>ETextureFormat</c> table gives
    /// ordinal 12 as 3DC at 16 bytes per 4x4 block, and <c>CONFIRMED_BYTES</c> here: 274 exports in
    /// the game declare it, their mip chains decompose exactly against that block size, and all 64
    /// distinct names are normal maps. Only the four ordinals this reader can actually decode are
    /// declared — the enum is what <c>Enum.IsDefined</c> gates the reader on, so a name without a
    /// decoder would turn a clean refusal into a failure further in.
    /// </remarks>
    ThreeDc = 12,
}

/// <summary>
/// How a texture is addressed outside 0..1. <c>CONFIRMED_EXTERNAL</c>: UModel's
/// <c>ETexClampMode</c> (<c>UnMaterial2.h</c>) gives <c>TC_Wrap = 0</c>, <c>TC_Clamp = 1</c>.
/// </summary>
/// <remarks>
/// <c>CONFIRMED_BYTES</c>: censused across all 33 packages, <c>UClampMode</c> appears on 3,467
/// textures and <c>VClampMode</c> on 3,586, and <b>every one of them carries the value 1</b>. The
/// property is written only to say "clamp"; wrap is the default and is left absent, which is why
/// this maps an absent property to <see cref="Wrap"/> rather than to unknown.
/// </remarks>
[System.Text.Json.Serialization.JsonConverter(typeof(System.Text.Json.Serialization.JsonStringEnumConverter))]
public enum TextureAddress
{
    Wrap = 0,
    Clamp = 1,
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

    /// <summary>Addressing outside 0..1, which UE5 needs as a sampler setting.</summary>
    public TextureAddress AddressU { get; init; }

    /// <summary>Addressing outside 0..1, which UE5 needs as a sampler setting.</summary>
    public TextureAddress AddressV { get; init; }

    /// <summary>
    /// The texture declares <c>bMasked</c> — its alpha is a cutout.
    /// </summary>
    /// <remarks>
    /// <c>CONFIRMED_EXTERNAL</c> from UModel's <c>UTexture</c> property table; 105 textures in the
    /// game declare it. See <c>docs/research/materials.md</c> for why this matters to rendering:
    /// an alpha channel here is frequently a gloss mask rather than opacity.
    /// </remarks>
    public bool DeclaresMasked { get; init; }

    /// <summary>
    /// The texture declares <c>bAlphaTexture</c> — its alpha is meant for blending. 722 in the game.
    /// </summary>
    public bool DeclaresAlphaTexture { get; init; }

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
        if (uSize is null || vSize is null) return null;

        int width = uSize.AsInt();
        int height = vSize.AsInt();
        if (width <= 0 || height <= 0 || width > 8192 || height > 8192) return null;

        // UE2 also ships small utility textures as a solid MipZero Color with no Format or mip
        // chain at all (WhiteTexture, BlackTexture, SubActionIndicator). The colour is the payload,
        // not a missing header, so model it as generated RGBA8 rather than reporting a false gap.
        if (format is null)
            return SolidColour(properties, width, height) is not null
                ? (BioShockTextureFormat.Rgba8, width, height)
                : null;

        var textureFormat = (BioShockTextureFormat)format.AsByte();
        if (!Enum.IsDefined(textureFormat)) return null;

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
    /// <param name="group">
    /// The asset group, used to disambiguate a name that appears in several. When null it is taken
    /// from the export's own outer, which is what the package itself says the texture belongs to.
    /// <para>
    /// This matters more than it looks. Texture names are <b>not</b> unique across groups, and the
    /// duplicates are not copies of the same art: 112 names in the bulk catalogue appear in more
    /// than one group and <b>every one of them points at different bytes</b>. Guessing — taking the
    /// first entry with a matching name — put another group's texture on 340 of the game's 30,831
    /// texture exports. The clearest was <c>Atlas_Diffuse</c>: the boss's skin was being drawn with
    /// the <c>Gen_Graffiti</c> wall decal that shares its name, which is why he rendered black with
    /// white streaks across him.
    /// </para>
    /// </param>
    public static BioShockTexture? Read(
        BioShockPackage package, ObjectExport export, BulkTextureCatalog? bulk = null, string? group = null)
    {
        // The export's outer names its group. It resolves to a catalogue group for 24,950 of the
        // 30,831 texture exports, and it is the package's own statement rather than an inference.
        group ??= package.ResolveName(export.OuterIndex);

        byte[] payload = package.ReadExportData(export);
        if (payload.Length < 64) return null;

        var properties = UnrealPropertyReader.Read(payload, package.Names, out _);

        var format = properties.FirstOrDefault(p => p.Name == "Format");
        var uSize = properties.FirstOrDefault(p => p.Name == "USize");
        var vSize = properties.FirstOrDefault(p => p.Name == "VSize");
        if (uSize is null || vSize is null) return null;

        int width = uSize.AsInt();
        int height = vSize.AsInt();
        if (width <= 0 || height <= 0 || width > 8192 || height > 8192) return null;

        // Normal textures may also carry MipZero metadata. It is a texture variant only when the
        // normal Format field is absent; otherwise the on-disk mip chain remains authoritative.
        byte[]? solid = format is null ? SolidColour(properties, width, height) : null;
        if (format is null && solid is null) return null;

        var textureFormat = format is null ? BioShockTextureFormat.Rgba8 : (BioShockTextureFormat)format.AsByte();
        if (!Enum.IsDefined(textureFormat)) return null;

        var mips = solid is null
            ? ReadMips(payload, textureFormat)
            : new List<TextureMip> { new() { Width = width, Height = height, Data = solid } };
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
            AddressU = Address(properties, "UClampMode"),
            AddressV = Address(properties, "VClampMode"),
            DeclaresMasked = Flag(properties, "bMasked"),
            DeclaresAlphaTexture = Flag(properties, "bAlphaTexture"),
        };
    }

    /// <summary>Clamp mode, defaulting to wrap when the property is absent.</summary>
    private static TextureAddress Address(IReadOnlyList<UnrealProperty> properties, string name)
    {
        var property = properties.FirstOrDefault(p => p.Name == name);
        if (property is null) return TextureAddress.Wrap;

        // One byte, not four: AsInt() returns 0 for anything shorter and would silently report
        // every clamped texture as wrapping.
        return property.AsByte() == 1 ? TextureAddress.Clamp : TextureAddress.Wrap;
    }

    /// <summary>
    /// A UE2 bool property, which carries its value in the tag rather than in a payload.
    /// </summary>
    /// <remarks>
    /// <b>Presence is not the value.</b> This game does serialise false bools: censused across all
    /// 33 packages, <c>bStreamable</c> is written on 4,374 textures and is <c>False</c> on every
    /// one of them. <c>bMasked</c>, <c>bAlphaTexture</c> and <c>bTwoSided</c> happen to be true
    /// wherever they appear, so a presence test would give the right answer for these three today
    /// and the wrong one the moment it were reused for a fourth.
    /// </remarks>
    private static bool Flag(IReadOnlyList<UnrealProperty> properties, string name) =>
        properties.Any(p => p.Name == name && p.BoolValue);

    /// <summary>
    /// Reads UE2's constant-colour texture variant. <c>Color</c> stores BGRA on disk; previews
    /// and PNG export consume RGBA, so the conversion belongs at this byte boundary.
    /// </summary>
    private static byte[]? SolidColour(IReadOnlyList<UnrealProperty> properties, int width, int height)
    {
        var mipZero = properties.FirstOrDefault(property => property.Name == "MipZero"
            && property.StructName == "Color" && property.Value.Length >= 4);
        if (mipZero is null) return null;

        byte b = mipZero.Value[0], g = mipZero.Value[1], r = mipZero.Value[2], a = mipZero.Value[3];
        var rgba = new byte[checked(width * height * 4)];
        for (int i = 0; i < rgba.Length; i += 4)
        {
            rgba[i] = r;
            rgba[i + 1] = g;
            rgba[i + 2] = b;
            rgba[i + 3] = a;
        }
        return rgba;
    }

    /// <summary>
    /// Why <see cref="Read"/> returned nothing, in the format's own terms.
    /// </summary>
    /// <remarks>
    /// <para>
    /// For diagnostics. "This texture could not be decoded" is a symptom; the ordinal in the
    /// <c>Format</c> property is the thing a future session can act on, and the reader is the only
    /// place that knows which ordinals it implements.
    /// </para>
    /// <para>
    /// It reports what it found and nothing more — an unknown ordinal is named, not guessed at.
    /// </para>
    /// </remarks>
    public static string DescribeFailure(BioShockPackage package, ObjectExport export)
    {
        byte[] payload;
        List<UnrealProperty> properties;

        try
        {
            payload = package.ReadExportData(export);
            if (payload.Length < 64) return $"payload is only {payload.Length} bytes";
            properties = UnrealPropertyReader.Read(payload, package.Names, out _);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException or IOException)
        {
            return $"the property list would not read: {ex.GetType().Name}: {ex.Message}";
        }

        var format = properties.FirstOrDefault(p => p.Name == "Format");
        var uSize = properties.FirstOrDefault(p => p.Name == "USize");
        var vSize = properties.FirstOrDefault(p => p.Name == "VSize");

        if (format is null || uSize is null || vSize is null)
        {
            var missing = new[] { ("Format", format), ("USize", uSize), ("VSize", vSize) }
                .Where(p => p.Item2 is null)
                .Select(p => p.Item1);
            return $"no {string.Join(", no ", missing)} property";
        }

        byte ordinal = format.AsByte();
        string size = $"{uSize.AsInt()}×{vSize.AsInt()}";

        if (!Enum.IsDefined((BioShockTextureFormat)ordinal))
        {
            string known = string.Join(", ", Enum.GetValues<BioShockTextureFormat>()
                .Select(f => $"{(int)f} {f}"));
            return $"Format ordinal {ordinal} is not one this reader decodes ({known}); {size}";
        }

        return $"Format {(BioShockTextureFormat)ordinal}, {size}, but no mip chain was found in the payload";
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
        BioShockTextureFormat.Dxt3 or BioShockTextureFormat.Dxt5 or BioShockTextureFormat.ThreeDc =>
            Blocks(width) * Blocks(height) * 16,
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
