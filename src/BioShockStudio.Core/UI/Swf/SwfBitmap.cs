namespace BioShockStudio.Core.UI.Swf;

/// <summary>
/// Scaleform tag-512 bitmap format byte (little-endian u16 in the tag header). Observed values
/// across HUD / pause / radial / sharedlibrary samples: 4 = DXT5, 0 = DXT1.
/// </summary>
public enum SwfBitmapFormat : ushort
{
    Dxt1 = 0,
    Dxt5 = 4,
}

/// <summary>
/// One decoded Scaleform tag-512 bitmap: character ID, dimensions, on-disk format, and RGBA8
/// pixels (row-major, four bytes per pixel) from <see cref="Textures.BlockCompression"/>.
/// </summary>
public sealed class SwfBitmap
{
    public required int CharacterId { get; init; }
    public required int Width { get; init; }
    public required int Height { get; init; }
    public required SwfBitmapFormat Format { get; init; }
    public required ushort Flags { get; init; }

    /// <summary>Straight RGBA8, length = Width * Height * 4.</summary>
    public required byte[] Rgba { get; init; }
}
