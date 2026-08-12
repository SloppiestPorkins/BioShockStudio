using System.Buffers.Binary;

namespace BioShockStudio.Core.Havok.Packfile;

/// <summary>A pointer inside one section pointing elsewhere in the same section. 8 bytes.</summary>
public readonly record struct LocalFixup(int SourceOffset, int DestinationOffset);

/// <summary>A pointer into another section. 12 bytes.</summary>
public readonly record struct GlobalFixup(int SourceOffset, int DestinationSection, int DestinationOffset);

/// <summary>
/// Marks the start of an object and names its class. 12 bytes.
/// <para>
/// This is the object table: every entry is one Havok object, at <see cref="SourceOffset"/> within
/// the owning section, whose class name lives at <see cref="ClassNameOffset"/> in the
/// <c>__classnames__</c> section.
/// </para>
/// </summary>
public readonly record struct VirtualFixup(int SourceOffset, int ClassNameSection, int ClassNameOffset);

/// <summary>
/// Parses the three fixup tables of a section.
/// <para>
/// CONFIRMED_BYTES: entries are 8/12/12 bytes and each region is padded to a 16-byte boundary with
/// <c>0xFF</c>, so parsing stops at the first all-<c>0xFF</c> entry rather than trusting the region
/// size to be an exact multiple.
/// </para>
/// </summary>
public static class PackfileFixups
{
    public static List<LocalFixup> ReadLocal(ReadOnlySpan<byte> region)
    {
        var result = new List<LocalFixup>();
        for (int i = 0; i + 8 <= region.Length; i += 8)
        {
            var entry = region.Slice(i, 8);
            if (IsPadding(entry)) continue;
            result.Add(new LocalFixup(
                BinaryPrimitives.ReadInt32LittleEndian(entry),
                BinaryPrimitives.ReadInt32LittleEndian(entry[4..])));
        }
        return result;
    }

    public static List<GlobalFixup> ReadGlobal(ReadOnlySpan<byte> region)
    {
        var result = new List<GlobalFixup>();
        for (int i = 0; i + 12 <= region.Length; i += 12)
        {
            var entry = region.Slice(i, 12);
            if (IsPadding(entry)) continue;
            result.Add(new GlobalFixup(
                BinaryPrimitives.ReadInt32LittleEndian(entry),
                BinaryPrimitives.ReadInt32LittleEndian(entry[4..]),
                BinaryPrimitives.ReadInt32LittleEndian(entry[8..])));
        }
        return result;
    }

    public static List<VirtualFixup> ReadVirtual(ReadOnlySpan<byte> region)
    {
        var result = new List<VirtualFixup>();
        for (int i = 0; i + 12 <= region.Length; i += 12)
        {
            var entry = region.Slice(i, 12);
            if (IsPadding(entry)) continue;
            result.Add(new VirtualFixup(
                BinaryPrimitives.ReadInt32LittleEndian(entry),
                BinaryPrimitives.ReadInt32LittleEndian(entry[4..]),
                BinaryPrimitives.ReadInt32LittleEndian(entry[8..])));
        }
        return result;
    }

    private static bool IsPadding(ReadOnlySpan<byte> entry)
    {
        foreach (byte b in entry)
            if (b != 0xFF) return false;
        return true;
    }
}
