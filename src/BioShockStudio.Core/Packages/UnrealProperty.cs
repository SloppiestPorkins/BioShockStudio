using System.Buffers.Binary;

namespace BioShockStudio.Core.Packages;

/// <summary>Unreal property value types, as encoded in the low nibble of a property's info byte.</summary>
public enum UnrealPropertyType
{
    None = 0,
    Byte = 1,
    Int = 2,
    Bool = 3,
    Float = 4,
    Object = 5,
    Name = 6,
    String = 7,
    Class = 8,
    Array = 9,
    Struct = 10,
    Vector = 11,
    Rotator = 12,
    Str = 13,
    Map = 14,
    FixedArray = 15,
}

/// <summary>One entry of an Unreal property list.</summary>
public sealed record UnrealProperty
{
    public required string Name { get; init; }
    public required UnrealPropertyType Type { get; init; }

    /// <summary>Struct type name, for <see cref="UnrealPropertyType.Struct"/> properties.</summary>
    public string? StructName { get; init; }

    public required int ArrayIndex { get; init; }
    public required byte[] Value { get; init; }

    public byte AsByte() => Value.Length >= 1 ? Value[0] : (byte)0;
    public int AsInt() => Value.Length >= 4 ? BinaryPrimitives.ReadInt32LittleEndian(Value) : 0;
    public float AsFloat() => Value.Length >= 4 ? BinaryPrimitives.ReadSingleLittleEndian(Value) : 0f;

    public override string ToString() => $"{Name} ({Type})";
}

/// <summary>
/// Reads an Unreal property list, the tagged key/value block that prefixes most export payloads.
/// <para>
/// CONFIRMED_BYTES: BioShock Remastered export payloads carry an 8-byte prefix ahead of the list.
/// Reading from offset 8 yields clean property names (<c>Format</c>, <c>USize</c>, <c>VSize</c>,
/// <c>SourcePath</c>) and terminates on a <c>None</c> tag, while reading from 0 produces garbage.
/// </para>
/// <code>
/// FName  name                        // "None" terminates the list
/// byte   info                        // bits 0-3 type, bits 4-6 size encoding, bit 7 array flag
/// FName  structName                  // only when type == Struct
/// ...    size                        // per the size encoding
/// ...    arrayIndex                  // FCompactIndex, only when the array flag is set and type != Bool
/// byte[] value
/// </code>
/// </summary>
public static class UnrealPropertyReader
{
    /// <summary>Offset at which the property list begins within an export payload.</summary>
    public const int PayloadPropertyOffset = 8;

    public static List<UnrealProperty> Read(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names, out int endOffset, int start = PayloadPropertyOffset)
        => Read(payload, names, out endOffset, out _, start);

    /// <summary>
    /// Reads a property list, reporting whether it ended on a clean terminator.
    /// </summary>
    /// <param name="truncated">
    /// True when the list stopped on a numbered <c>None</c>. A terminator carries no number, so a
    /// numbered one means the walk lost alignment inside the preceding property and everything after
    /// it would be invented. See <c>docs/research/materials.md</c> for the case that produces it.
    /// </param>
    public static List<UnrealProperty> Read(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names, out int endOffset, out bool truncated,
        int start = PayloadPropertyOffset)
    {
        var result = new List<UnrealProperty>();
        int offset = start;
        truncated = false;

        // Bounded: a malformed list must not spin forever on a huge payload.
        for (int guard = 0; guard < 4096; guard++)
        {
            string name = ReadFName(payload, ref offset, names, out bool numbered);
            if (name.StartsWith("None", StringComparison.Ordinal) && (name == "None" || numbered))
            {
                truncated = numbered;
                break;
            }

            byte info = payload[offset++];
            var type = (UnrealPropertyType)(info & 0x0F);
            int sizeEncoding = (info >> 4) & 0x07;
            bool isArray = (info & 0x80) != 0;

            string? structName = null;
            if (type == UnrealPropertyType.Struct) structName = ReadFName(payload, ref offset, names);

            int size = sizeEncoding switch
            {
                0 => 1,
                1 => 2,
                2 => 4,
                3 => 12,
                4 => 16,
                5 => payload[offset++],
                6 => ReadUInt16(payload, ref offset),
                _ => ReadInt32(payload, ref offset),
            };

            int arrayIndex = 0;
            if (isArray && type != UnrealPropertyType.Bool) arrayIndex = ReadCompactIndex(payload, ref offset);

            if (size < 0 || offset + size > payload.Length) throw new InvalidDataException($"Property '{name}' overruns the payload.");

            var value = payload.Slice(offset, size).ToArray();
            offset += size;

            result.Add(new UnrealProperty
            {
                Name = name,
                Type = type,
                StructName = structName,
                ArrayIndex = arrayIndex,
                Value = value,
            });
        }

        endOffset = offset;
        return result;
    }

    private static string ReadFName(ReadOnlySpan<byte> data, ref int offset, IReadOnlyList<NameEntry> names) =>
        ReadFName(data, ref offset, names, out _);

    /// <summary>
    /// Reads an <c>FName</c>: a name-table index plus a number that disambiguates repeated names.
    /// </summary>
    /// <param name="numbered">True when the name carries a disambiguating number.</param>
    private static string ReadFName(
        ReadOnlySpan<byte> data, ref int offset, IReadOnlyList<NameEntry> names, out bool numbered)
    {
        int index = ReadCompactIndex(data, ref offset);
        int extra = ReadInt32(data, ref offset);
        if (index < 0 || index >= names.Count) throw new InvalidDataException($"Name index {index} out of range.");
        numbered = extra != 0;
        string baseName = names[index].Name;
        return extra == 0 ? baseName : baseName + (extra - 1);
    }

    private static ushort ReadUInt16(ReadOnlySpan<byte> data, ref int offset)
    {
        ushort value = BinaryPrimitives.ReadUInt16LittleEndian(data[offset..]);
        offset += 2;
        return value;
    }

    private static int ReadInt32(ReadOnlySpan<byte> data, ref int offset)
    {
        int value = BinaryPrimitives.ReadInt32LittleEndian(data[offset..]);
        offset += 4;
        return value;
    }

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
