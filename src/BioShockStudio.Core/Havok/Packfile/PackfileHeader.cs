using System.Buffers.Binary;
using System.Text;

namespace BioShockStudio.Core.Havok.Packfile;

/// <summary>
/// Havok packfile header (<c>hkPackfileHeader</c>), 64 bytes.
/// <para>
/// CONFIRMED_BYTES for BioShock 1 Remastered: <c>fileVersion = 9</c>,
/// <c>contentsVersion = "hk_2012.2.0-r1"</c>, 4-byte pointers, little-endian.
/// </para>
/// <para>
/// <c>numSections</c> is content-dependent, not fixed: simple payloads ship the stock 3 sections
/// (<c>208</c>-byte data start), while the first-person hands package ships 12 because 2K adds one
/// section per weapon. Only the arithmetic <c>64 + numSections * 48</c> is invariant.
/// </para>
/// </summary>
public sealed record PackfileHeader
{
    public const int Size = 64;

    /// <summary>First half of the packfile magic: <c>0x57E0E057</c>.</summary>
    public const uint Magic0 = 0x57E0E057;

    /// <summary>Second half of the packfile magic: <c>0x10C0C010</c>.</summary>
    public const uint Magic1 = 0x10C0C010;

    /// <summary>Section header size implied by <see cref="LayoutRules"/> for 4-byte pointers.</summary>
    public const int SectionHeaderSize = 48;

    public required int UserTag { get; init; }
    public required int FileVersion { get; init; }

    /// <summary>{ bytesInPointer, littleEndian, reusePaddingOptimization, emptyBaseClassOptimization }.</summary>
    public required byte[] LayoutRules { get; init; }

    public required int NumSections { get; init; }
    public required int ContentsSectionIndex { get; init; }
    public required int ContentsSectionOffset { get; init; }
    public required int ContentsClassNameSectionIndex { get; init; }
    public required int ContentsClassNameSectionOffset { get; init; }

    /// <summary>e.g. <c>hk_2012.2.0-r1</c>.</summary>
    public required string ContentsVersion { get; init; }

    public required int Flags { get; init; }

    public byte BytesInPointer => LayoutRules[0];
    public bool IsLittleEndian => LayoutRules[1] != 0;

    /// <summary>Offset of the first section header, i.e. immediately after this header.</summary>
    public int SectionHeadersStart => Size;

    /// <summary>Offset at which section data begins: header plus all section headers.</summary>
    public int AbsoluteDataStart => Size + NumSections * SectionHeaderSize;

    public static bool TryRead(ReadOnlySpan<byte> data, out PackfileHeader? header)
    {
        header = null;
        if (data.Length < Size) return false;
        if (BinaryPrimitives.ReadUInt32LittleEndian(data) != Magic0) return false;
        if (BinaryPrimitives.ReadUInt32LittleEndian(data[4..]) != Magic1) return false;

        var layout = data.Slice(16, 4).ToArray();
        int numSections = BinaryPrimitives.ReadInt32LittleEndian(data[20..]);
        if (numSections is <= 0 or > 64) return false;

        // 16-byte fixed-width, null-padded version string.
        var versionSpan = data.Slice(40, 16);
        int nul = versionSpan.IndexOf((byte)0);
        string version = Encoding.ASCII.GetString(nul >= 0 ? versionSpan[..nul] : versionSpan);

        header = new PackfileHeader
        {
            UserTag = BinaryPrimitives.ReadInt32LittleEndian(data[8..]),
            FileVersion = BinaryPrimitives.ReadInt32LittleEndian(data[12..]),
            LayoutRules = layout,
            NumSections = numSections,
            ContentsSectionIndex = BinaryPrimitives.ReadInt32LittleEndian(data[24..]),
            ContentsSectionOffset = BinaryPrimitives.ReadInt32LittleEndian(data[28..]),
            ContentsClassNameSectionIndex = BinaryPrimitives.ReadInt32LittleEndian(data[32..]),
            ContentsClassNameSectionOffset = BinaryPrimitives.ReadInt32LittleEndian(data[36..]),
            ContentsVersion = version,
            Flags = BinaryPrimitives.ReadInt32LittleEndian(data[56..]),
        };
        return true;
    }
}
