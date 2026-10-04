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

    /// <summary>
    /// The value of a <see cref="UnrealPropertyType.Bool"/> property, which UE2 stores in the tag
    /// rather than in a payload.
    /// </summary>
    /// <remarks>
    /// Bit 7 of the info byte is the array flag for every other type and <b>the boolean's value</b>
    /// for this one — which is exactly why the array index is not read for <c>Bool</c>. Without
    /// this, a caller can only test whether the property is present, and presence is not the value:
    /// see <see cref="UnrealProperty"/>'s use in <c>TextureReader</c>. Always false for
    /// non-<c>Bool</c> properties.
    /// </remarks>
    public bool BoolValue { get; init; }

    public byte AsByte() => Value.Length >= 1 ? Value[0] : (byte)0;
    public int AsInt() => Value.Length >= 4 ? BinaryPrimitives.ReadInt32LittleEndian(Value) : 0;
    public float AsFloat() => Value.Length >= 4 ? BinaryPrimitives.ReadSingleLittleEndian(Value) : 0f;

    /// <summary>
    /// Reads an <see cref="UnrealPropertyType.Object"/> property's value as a package reference.
    /// </summary>
    /// <remarks>
    /// The value is an <c>FCompactIndex</c>: positive selects an export, negative an import, zero is
    /// null. Returns false rather than throwing when the bytes do not form one, so a caller walking
    /// a property list does not have to guard every reference itself.
    /// </remarks>
    public bool TryAsObjectReference(out PackageIndex reference)
    {
        reference = default;
        if (Value.Length == 0) return false;

        int offset = 0;
        try
        {
            reference = new PackageIndex(UnrealPropertyReader.ReadCompactIndexAt(Value, ref offset));
            return true;
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return false;
        }
    }

    /// <summary>
    /// Reads a <see cref="UnrealPropertyType.Name"/> property's value as its text (name-table entry
    /// plus the disambiguating number, the same form the property list uses for property names).
    /// Returns null rather than throwing when the bytes do not form one.
    /// </summary>
    public string? TryAsNameText(IReadOnlyList<NameEntry> names)
    {
        if (Type != UnrealPropertyType.Name || Value.Length == 0) return null;
        try { return UnrealPropertyReader.ReadFNameAt(Value, names); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return null;
        }
    }

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

    /// <summary>
    /// Diagnostics only: called for every Array property <see cref="Read(ReadOnlySpan{byte}, IReadOnlyList{NameEntry}, out int, out bool, int)"/>
    /// walks, with how its value measures as an array of property-list structs. Null (the default)
    /// costs nothing. Used by the struct-array size census; never set in production code.
    /// </summary>
    public static Action<string, StructArrayMeasure>? ArrayMeasured { get; set; }

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

            // A struct whose value is itself a property list can declare a size that is short of its
            // own content. Corrected only where the struct's own terminator proves it.
            if (type == UnrealPropertyType.Struct)
                size = CorrectedStructSize(payload, offset, size, names);

            if (type == UnrealPropertyType.Array)
            {
                var measure = MeasureStructArray(payload, offset, size, names);
                ArrayMeasured?.Invoke(name, measure);
                size = CorrectedArraySize(measure, offset, payload.Length);
            }

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
                BoolValue = type == UnrealPropertyType.Bool && isArray,
            });
        }

        endOffset = offset;
        return result;
    }

    /// <summary>
    /// The true length of a struct property whose value is a nested property list.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>CONFIRMED_BYTES.</b> A struct's declared size <b>omits the size-encoding bytes of its own
    /// nested properties</b>. A nested property that carries an explicit size — encoding 5, 6 or 7 —
    /// costs 1, 2 or 4 bytes on the wire that the declared size does not count, so the outer walk
    /// advances that many bytes too few, lands inside the next property's name and reads nothing
    /// but rubbish afterwards. That is the whole cause of the "partial material" problem: about half
    /// the shaders in the larger packages stopped at their first <c>MaskMaterial</c>.
    /// </para>
    /// <para>
    /// The evidence is a census of every struct-valued property on every material in the game.
    /// Of <b>14,610 <c>MaskMaterial</c> structs, 9,152 declare their size exactly — every one of
    /// them having no nested property with an explicit size — and the remaining 5,458 are short by
    /// exactly the number of size-encoding bytes their nested properties carry. There are no other
    /// cases.</b> The two readings side by side:
    /// </para>
    /// <code>
    /// PistolShader.SpecularMask        declared 20, content 20
    ///   26 00000000  05 00            Material, size encoding 0 — no size byte
    /// Resurrection_Shader.Opacity      declared 22, content 23
    ///   36 00000000  55 03 7EA301     Material, size encoding 5 — one size byte, uncounted
    /// </code>
    /// <para>
    /// Not every struct is a property list: <c>Color</c> is a plain four-byte BGRA value and has no
    /// nested list at all. So this does not correct on the strength of the rule — it corrects only
    /// when walking the nested list <b>lands exactly on a terminator</b> at the corrected length and
    /// the declared length does not contain one. A struct that is not a property list cannot satisfy
    /// that, and is returned untouched.
    /// </para>
    /// </remarks>
    private static int CorrectedStructSize(
        ReadOnlySpan<byte> payload, int start, int declared, IReadOnlyList<NameEntry> names)
    {
        if (declared <= 0 || start + declared > payload.Length) return declared;

        // Where the nested list actually ends, and what its own size bytes cost.
        if (!TryMeasureNestedList(payload, start, names, out int needed, out int sizeBytes, out _)) return declared;

        // Already correct, or correct for a reason this does not understand: leave it alone.
        if (needed == declared || sizeBytes == 0) return declared;

        // The correction has to be exactly the shortfall the rule predicts, and has to fit.
        if (needed != declared + sizeBytes) return declared;
        if (start + needed > payload.Length) return declared;

        return needed;
    }

    /// <summary>
    /// The true length of an Array whose elements are property-list structs.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>CONFIRMED_BYTES</b>, the array counterpart of <see cref="CorrectedStructSize"/>: an array
    /// of structs declares a size that <b>omits the explicit size byte of every nested Object
    /// property</b> (encoding 5/6/7 on an Object). Census of every Array property in all 21 shipped
    /// packages (4 Oct 2026, 786,871 exports): of the arrays that walk cleanly as structs and carry
    /// Object size bytes, <b>8,296 are short by exactly those bytes and none declare them</b> -
    /// Materials 6,406, resolveInfoList 1,581, MaterialSlot 184, SequenceItems 121,
    /// PatrolEntries 4. Arrays with no Object size bytes (281,147) are always exact, even when
    /// they carry Name size bytes. Found through Medical's Fisheries gate: BooleanStatement61's
    /// resolveInfoList (lhs &lt;- ActionGetNumItemsInPlayersInventory89) is one byte short, so the
    /// getter link was dropped and the gate could never open.
    /// </para>
    /// <code>
    /// ActionFilterItem6.resolveInfoList   declared 39, content 39
    ///   32 00000000  05 00               Action, encoding 0 - no size byte
    /// BooleanStatement61.resolveInfoList  declared 40, content 41
    ///   32 00000000  55 03 7AC603        Action, encoding 5 - one size byte, uncounted
    /// </code>
    /// <para>
    /// Corrected only when the walk is a clean struct list that lands exactly on its terminators at
    /// declared + Object-size-bytes; anything else (plain arrays, other shortfalls) is untouched.
    /// </para>
    /// </remarks>
    private static int CorrectedArraySize(StructArrayMeasure measure, int start, int payloadLength)
    {
        if (!measure.IsStructList || measure.ObjectSizeBytes == 0) return measure.Declared;
        if (measure.Needed != measure.Declared + measure.ObjectSizeBytes) return measure.Declared;
        if (start + measure.Needed > payloadLength) return measure.Declared;
        return measure.Needed;
    }

    /// <summary>
    /// Measures an Array value as <c>FCompactIndex count</c> followed by that many property-list
    /// structs, without trusting the declared length. <see cref="StructArrayMeasure.IsStructList"/>
    /// is false when the bytes are not that shape (plain arrays of ints, names, object refs...).
    /// </summary>
    public static StructArrayMeasure MeasureStructArray(
        ReadOnlySpan<byte> payload, int start, int declared, IReadOnlyList<NameEntry> names)
    {
        var none = new StructArrayMeasure(false, declared, 0, 0, 0, 0);
        if (declared <= 0 || start >= payload.Length) return none;
        int offset = start;
        int count;
        try { count = ReadCompactIndex(payload, ref offset); }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException) { return none; }
        if (count <= 0 || count > 4096) return none;
        int sizeBytes = 0, objectSizeBytes = 0;
        for (int i = 0; i < count; i++)
        {
            if (!TryMeasureNestedList(payload, offset, names, out int needed, out int sb, out int osb)) return none;
            offset += needed;
            sizeBytes += sb;
            objectSizeBytes += osb;
        }
        return new StructArrayMeasure(true, declared, offset - start, sizeBytes, objectSizeBytes, count);
    }

    /// <summary>
    /// Walks a nested property list to its terminator, without trusting any declared length.
    /// </summary>
    /// <param name="needed">Bytes from <paramref name="start"/> to the end of the terminator.</param>
    /// <param name="sizeBytes">Size-encoding bytes the nested properties carry between them.</param>
    /// <returns>False if the bytes are not a property list, which is the common case.</returns>
    private static bool TryMeasureNestedList(
        ReadOnlySpan<byte> payload, int start, IReadOnlyList<NameEntry> names, out int needed, out int sizeBytes,
        out int objectSizeBytes)
    {
        needed = 0;
        sizeBytes = 0;
        objectSizeBytes = 0;
        int offset = start;

        // A nested list is short; a runaway walk means these are not properties.
        for (int guard = 0; guard < 64; guard++)
        {
            if (offset >= payload.Length) return false;

            int nameIndex;
            try { nameIndex = ReadCompactIndex(payload, ref offset); }
            catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException) { return false; }

            if (nameIndex < 0 || nameIndex >= names.Count) return false;

            if (names[nameIndex].Name == "None")
            {
                // The terminator's four-byte number completes the list.
                needed = offset + 4 - start;
                return start + needed <= payload.Length;
            }

            offset += 4;
            if (offset >= payload.Length) return false;

            byte info = payload[offset++];
            var type = (UnrealPropertyType)(info & 0x0F);
            int sizeEncoding = (info >> 4) & 0x07;

            if (type == UnrealPropertyType.Struct)
            {
                try { ReadCompactIndex(payload, ref offset); }
                catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException) { return false; }
                offset += 4;
                if (offset > payload.Length) return false;
            }

            int size;
            int sizeBytesBefore = sizeBytes;
            try
            {
                size = sizeEncoding switch
                {
                    0 => 1,
                    1 => 2,
                    2 => 4,
                    3 => 12,
                    4 => 16,
                    5 => Count(payload, ref offset, ref sizeBytes, 1),
                    6 => Count(payload, ref offset, ref sizeBytes, 2),
                    _ => Count(payload, ref offset, ref sizeBytes, 4),
                };
            }
            catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException) { return false; }

            if (size < 0) return false;
            if (type == UnrealPropertyType.Object) objectSizeBytes += sizeBytes - sizeBytesBefore;
            offset += size;
            if (offset > payload.Length) return false;
        }

        return false;

        static int Count(ReadOnlySpan<byte> data, ref int at, ref int tally, int width)
        {
            int value = width switch
            {
                1 => data[at],
                2 => BinaryPrimitives.ReadUInt16LittleEndian(data[at..]),
                _ => BinaryPrimitives.ReadInt32LittleEndian(data[at..]),
            };

            at += width;
            tally += width;
            return value;
        }
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

    /// <summary>
    /// <see cref="ReadCompactIndex"/>, exposed for <see cref="UnrealProperty.TryAsObjectReference"/>.
    /// </summary>
    internal static int ReadCompactIndexAt(ReadOnlySpan<byte> data, ref int offset) =>
        ReadCompactIndex(data, ref offset);

    /// <summary>An <c>FName</c> value read from the start of <paramref name="data"/>.</summary>
    internal static string ReadFNameAt(ReadOnlySpan<byte> data, IReadOnlyList<NameEntry> names)
    {
        int offset = 0;
        return ReadFName(data, ref offset, names);
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

/// <summary>How an Array property's value measures as property-list structs (see <see cref="UnrealPropertyReader.MeasureStructArray"/>).</summary>
/// <param name="IsStructList">The bytes walk cleanly as a count plus that many terminated property lists.</param>
/// <param name="Declared">The size the property tag declared.</param>
/// <param name="Needed">Bytes the walk actually needed.</param>
/// <param name="SizeBytes">Explicit size-encoding bytes carried by the nested properties.</param>
/// <param name="ObjectSizeBytes">The part of <paramref name="SizeBytes"/> carried by Object properties.</param>
/// <param name="Count">Element count.</param>
public readonly record struct StructArrayMeasure(
    bool IsStructList, int Declared, int Needed, int SizeBytes, int ObjectSizeBytes, int Count);
