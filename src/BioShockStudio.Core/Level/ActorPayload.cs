using System.Buffers.Binary;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// A placed world object's payload: the fixed header the game writes ahead of every actor, the
/// Unreal property list, and the twelve-byte trailer that follows it.
/// </summary>
public sealed record ActorPayload
{
    public required ObjectExport Export { get; init; }
    public required string ClassName { get; init; }
    public required IReadOnlyList<UnrealProperty> Properties { get; init; }

    /// <summary>Offset at which the property list begins — the end of the actor header.</summary>
    public required int PropertyListStart { get; init; }

    /// <summary>Offset one past the list's terminator.</summary>
    public required int PropertyListEnd { get; init; }

    /// <summary>
    /// True when the walk stopped on a numbered <c>None</c>, meaning alignment was lost and anything
    /// after it would be invented. Reported, never hidden.
    /// </summary>
    public required bool Truncated { get; init; }

    /// <summary>
    /// The int32 at +24 of the header. UNKNOWN: it varies between actors and nothing correlates with
    /// it yet, so it is preserved rather than skipped by a hardcoded constant.
    /// </summary>
    public required int UnknownHeaderField { get; init; }

    /// <summary>
    /// The <c>FCompactIndex</c> that follows the self reference. UNKNOWN: -1 in every actor
    /// inspected. Preserved for the same reason.
    /// </summary>
    public required int UnknownHeaderIndex { get; init; }

    /// <summary>Bytes after the property list's terminator. Twelve — <c>4, 5, 0</c> — on every actor seen.</summary>
    public required byte[] Trailer { get; init; }

    public UnrealProperty? Find(string name) =>
        Properties.FirstOrDefault(p => string.Equals(p.Name, name, StringComparison.Ordinal));
}

/// <summary>
/// Reads the payload of a placed actor.
/// <para>
/// CONFIRMED_BYTES. A map's actors do not begin their property list at the offset-8 position the
/// other export classes use. They carry a header that ends with the export's own index, which is
/// what makes the header self-validating rather than a guessed constant:
/// </para>
/// <code>
/// +0    int32   4                     // constant
/// +4    int32   3                     // constant
/// +8    int32   4                     // constant
/// +12   int32   1                     // constant
/// +16   int32   0
/// +20   int32   0
/// +24   int32   UNKNOWN               // varies between actors
/// +28   int32   -1
/// +32   int32   -1
/// +36   int32   0
/// +40   byte    0
/// +41   FCompactIndex  class index    // equals the export record's ClassIndex
///       FCompactIndex  class index    // the same value again
///       FCompactIndex  self index     // equals this export's PackageIndex, i.e. Index + 1
///       int32   0
///       byte    0
///       FCompactIndex  UNKNOWN        // -1 in every actor inspected
///       int32   0
///       ...     property list
///       int32   4, int32 5, int32 0   // trailer
/// </code>
/// <para>
/// Three of those fields are checked against the export table — the class index twice and the
/// export's own index — so a misread header cannot pass. The class index is variable-length, which
/// is why the list starts at 55 on some actors and 56 on others; deriving the offset from the class
/// index rather than hardcoding either value is what makes it hold across every class.
/// </para>
/// </summary>
public static class ActorPayloadReader
{
    /// <summary>Bytes of fixed header before the first variable-length field.</summary>
    private const int FixedHeaderLength = 41;

    /// <summary>Trailer written after the property list: <c>int32 4, int32 5, int32 0</c>.</summary>
    public const int TrailerLength = 12;

    /// <summary>
    /// True when the payload carries the actor header. This is the level's own answer to "which
    /// exports are placed world objects" — it is a property of the serialised form, not a guess
    /// from the class name, so a gameplay class nobody has heard of is still recognised.
    /// </summary>
    public static bool IsActor(BioShockPackage package, ObjectExport export)
    {
        if (export.SerialSize < FixedHeaderLength + TrailerLength) return false;
        try { return TryReadHeader(package.ReadExportData(export), export, out _, out _, out _); }
        catch { return false; }
    }

    /// <summary>Reads an actor payload, or returns null when the export is not an actor.</summary>
    public static ActorPayload? TryRead(BioShockPackage package, ObjectExport export)
    {
        byte[] data;
        try { data = package.ReadExportData(export); }
        catch { return null; }
        return TryRead(package, export, data);
    }

    /// <summary>Reads an actor payload from bytes already in hand.</summary>
    public static ActorPayload? TryRead(BioShockPackage package, ObjectExport export, byte[] data)
    {
        if (!TryReadHeader(data, export, out int listStart, out int unknownField, out int unknownIndex))
            return null;

        List<UnrealProperty> properties;
        int end;
        bool truncated;
        try { properties = UnrealPropertyReader.Read(data, package.Names, out end, out truncated, listStart); }
        catch { return null; }

        return new ActorPayload
        {
            Export = export,
            ClassName = package.GetClassName(export),
            Properties = properties,
            PropertyListStart = listStart,
            PropertyListEnd = end,
            Truncated = truncated,
            UnknownHeaderField = unknownField,
            UnknownHeaderIndex = unknownIndex,
            Trailer = end <= data.Length ? data[end..] : [],
        };
    }

    private static bool TryReadHeader(
        ReadOnlySpan<byte> data, ObjectExport export, out int listStart, out int unknownField, out int unknownIndex)
    {
        listStart = -1;
        unknownField = 0;
        unknownIndex = 0;

        if (data.Length < FixedHeaderLength + TrailerLength) return false;
        if (Int32At(data, 0) != 4 || Int32At(data, 4) != 3 || Int32At(data, 8) != 4 || Int32At(data, 12) != 1) return false;
        if (Int32At(data, 16) != 0 || Int32At(data, 20) != 0) return false;
        if (Int32At(data, 28) != -1 || Int32At(data, 32) != -1) return false;
        if (Int32At(data, 36) != 0 || data[40] != 0) return false;

        unknownField = Int32At(data, 24);

        int offset = FixedHeaderLength;
        try
        {
            // The class index, twice, then this export's own index. All three are checked against
            // the export table, so an accidental match is not credible.
            if (ReadCompactIndex(data, ref offset) != export.ClassIndex.Value) return false;
            if (ReadCompactIndex(data, ref offset) != export.ClassIndex.Value) return false;
            if (ReadCompactIndex(data, ref offset) != export.Index + 1) return false;

            if (Int32At(data, offset) != 0) return false;
            offset += 4;
            if (data[offset++] != 0) return false;
            unknownIndex = ReadCompactIndex(data, ref offset);
            if (Int32At(data, offset) != 0) return false;
            offset += 4;
        }
        catch (ArgumentOutOfRangeException) { return false; }
        catch (IndexOutOfRangeException) { return false; }
        catch (InvalidDataException) { return false; }

        if (offset >= data.Length) return false;
        listStart = offset;
        return true;
    }

    private static int Int32At(ReadOnlySpan<byte> data, int offset) =>
        offset + 4 <= data.Length ? BinaryPrimitives.ReadInt32LittleEndian(data[offset..]) : int.MinValue;

    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        byte b = data[offset++];
        bool negative = (b & 0x80) != 0;
        int value = b & 0x3F;

        if ((b & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte c = data[offset++];
                value |= (c & 0x7F) << shift;
                shift += 7;
                if ((c & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }

        return negative ? -value : value;
    }
}
