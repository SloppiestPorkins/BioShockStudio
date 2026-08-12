using System.Buffers.Binary;
using System.Text;

namespace BioShockStudio.Core.Havok.Packfile;

/// <summary>
/// Havok packfile section header (<c>hkPackfileSectionHeader</c>), 48 bytes for a 4-byte-pointer layout.
/// <para>
/// Offsets inside a section are relative to <see cref="AbsoluteDataStart"/>, and each successive
/// "end" field also marks the start of the next region, so the region sizes are differences.
/// </para>
/// </summary>
public sealed record PackfileSectionHeader
{
    public const int Size = 48;

    /// <summary>Section name, e.g. <c>__classnames__</c>, <c>__types__</c>, <c>__data__</c>.</summary>
    public required string SectionTag { get; init; }

    public required int AbsoluteDataStart { get; init; }
    public required int LocalFixupsOffset { get; init; }
    public required int GlobalFixupsOffset { get; init; }
    public required int VirtualFixupsOffset { get; init; }
    public required int ExportsOffset { get; init; }
    public required int ImportsOffset { get; init; }
    public required int EndOffset { get; init; }

    /// <summary>Size of the raw object data, i.e. everything before the first fixup table.</summary>
    public int DataSize => LocalFixupsOffset;

    public int LocalFixupsSize => GlobalFixupsOffset - LocalFixupsOffset;
    public int GlobalFixupsSize => VirtualFixupsOffset - GlobalFixupsOffset;
    public int VirtualFixupsSize => ExportsOffset - VirtualFixupsOffset;
    public int ExportsSize => ImportsOffset - ExportsOffset;
    public int ImportsSize => EndOffset - ImportsOffset;

    public static PackfileSectionHeader Read(ReadOnlySpan<byte> data)
    {
        if (data.Length < Size) throw new ArgumentException("Section header truncated.", nameof(data));

        // 19-byte null-padded tag followed by a single 0xFF pad byte (CONFIRMED_BYTES).
        // Tags are truncated to fit; names that would collide after truncation carry a numeric
        // suffix in the shipped data, e.g. "chemical200249441".
        var tagSpan = data[..19];
        int nul = tagSpan.IndexOf((byte)0);
        string tag = Encoding.ASCII.GetString(nul >= 0 ? tagSpan[..nul] : tagSpan);

        return new PackfileSectionHeader
        {
            SectionTag = tag,
            AbsoluteDataStart = BinaryPrimitives.ReadInt32LittleEndian(data[20..]),
            LocalFixupsOffset = BinaryPrimitives.ReadInt32LittleEndian(data[24..]),
            GlobalFixupsOffset = BinaryPrimitives.ReadInt32LittleEndian(data[28..]),
            VirtualFixupsOffset = BinaryPrimitives.ReadInt32LittleEndian(data[32..]),
            ExportsOffset = BinaryPrimitives.ReadInt32LittleEndian(data[36..]),
            ImportsOffset = BinaryPrimitives.ReadInt32LittleEndian(data[40..]),
            EndOffset = BinaryPrimitives.ReadInt32LittleEndian(data[44..]),
        };
    }
}
