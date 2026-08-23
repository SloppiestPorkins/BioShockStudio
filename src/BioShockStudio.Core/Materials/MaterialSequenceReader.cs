using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Materials;

/// <summary>One timed entry in a UE2 <c>MaterialSequence</c>.</summary>
/// <remarks>
/// The action ordinal is retained exactly as stored.  Values 0 and 1 are corroborated by the UE2
/// declaration as ShowMaterial and FadeToMaterial respectively, but callers should preserve an
/// unfamiliar value rather than treating it as one of those two actions.
/// </remarks>
public sealed record MaterialSequenceItem
{
    public required PackageIndex Material { get; init; }
    public required float Time { get; init; }
    public required byte Action { get; init; }
}

/// <summary>A decoded UE2 <c>MaterialSequence</c> timeline, without inventing a static shader choice.</summary>
public sealed record MaterialSequence
{
    public required string Name { get; init; }
    public required IReadOnlyList<MaterialSequenceItem> Items { get; init; }

    /// <summary>False if a declared item could not be walked to its own terminator.</summary>
    public required bool Complete { get; init; }

    /// <summary>Byte-backed reason an item could not be represented, when <see cref="Complete"/> is false.</summary>
    public string? Failure { get; init; }
}

/// <summary>Reads the nested tagged structs in a UE2 <c>MaterialSequence.SequenceItems</c> array.</summary>
/// <remarks>
/// <para>
/// A sequence item is a tagged struct containing <c>Material</c> (object), <c>Time</c> (float) and
/// <c>Action</c> (byte).  That structure is corroborated by the UE2 class declaration and by the
/// shipped <c>drip_sequence</c> bytes.
/// </para>
/// <para>
/// BioShock's declared array length may stop within the final nested struct, in the same family of
/// size under-counting that affects material structs.  The item count is stored at the start of the
/// array and every item has its own <c>None</c> terminator, so this reader follows that independent
/// structure and never infers an element stride.
/// </para>
/// </remarks>
public static class MaterialSequenceReader
{
    public const string ClassName = "MaterialSequence";

    public static MaterialSequence? Read(BioShockPackage package, ObjectExport export)
    {
        if (export.SerialSize <= 0 || package.GetClassName(export) != ClassName) return null;

        byte[] payload = package.ReadExportData(export);
        List<UnrealProperty> properties;
        try { properties = UnrealPropertyReader.Read(payload, package.Names, out _, out _); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        var array = properties.FirstOrDefault(property =>
            property.Name == "SequenceItems" && property.Type == UnrealPropertyType.Array);
        if (array is null) return null;

        // The property's Value stops at the size it declared.  Find that exact slice in the source
        // payload, then append the bytes immediately after its declared end.  The root walker may
        // already have stepped into the under-counted final item before it notices a numbered None,
        // so its end offset is not the boundary we need here.
        int declaredStart = payload.AsSpan().IndexOf(array.Value);
        if (declaredStart < 0) return null;
        int declaredEnd = declaredStart + array.Value.Length;
        byte[] bytes = [.. array.Value, .. payload.AsSpan(declaredEnd).ToArray()];
        int offset = 0;
        int count;
        try { count = ReadCompactIndex(bytes, ref offset); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        if (count is < 0 or > 4096) return null;

        var items = new List<MaterialSequenceItem>(count);
        bool complete = true;
        string? failure = null;
        for (int index = 0; index < count; index++)
        {
            List<UnrealProperty> item;
            try
            {
                item = UnrealPropertyReader.Read(bytes, package.Names, out int itemEnd, out bool truncated, offset);
                offset = itemEnd;
                complete &= !truncated;
            }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
            {
                complete = false;
                failure = $"item {index}: nested property walk failed ({ex.Message})";
                break;
            }

            var materialProperty = item.FirstOrDefault(property =>
                property.Name == "Material" && property.Type == UnrealPropertyType.Object);
            var timeProperty = item.FirstOrDefault(property =>
                property.Name == "Time" && property.Type == UnrealPropertyType.Float);
            var actionProperty = item.FirstOrDefault(property =>
                property.Name == "Action" && property.Type == UnrealPropertyType.Byte);

            if (materialProperty is null || timeProperty is null || actionProperty is null
                || !TryReadObjectReference(materialProperty, out var material))
            {
                complete = false;
                failure = $"item {index}: missing Material, Time or Action ({string.Join(", ", item.Select(p => p.Name))})";
                break;
            }

            items.Add(new MaterialSequenceItem
            {
                Material = material,
                Time = timeProperty.AsFloat(),
                Action = actionProperty.AsByte(),
            });
        }

        return new MaterialSequence
        {
            Name = export.ObjectName,
            Items = items,
            Complete = complete && items.Count == count,
            Failure = failure,
        };
    }

    private static bool TryReadObjectReference(UnrealProperty property, out PackageIndex reference)
    {
        reference = default;
        int offset = 0;
        try
        {
            reference = new PackageIndex(ReadCompactIndex(property.Value, ref offset));
            return true;
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return false;
        }
    }

    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        if (offset >= data.Length) throw new IndexOutOfRangeException();
        byte first = data[offset++];
        bool negative = (first & 0x80) != 0;
        int value = first & 0x3F;
        if ((first & 0x40) != 0)
        {
            int shift = 6;
            for (int guard = 0; guard < 4; guard++)
            {
                if (offset >= data.Length) throw new IndexOutOfRangeException();
                byte next = data[offset++];
                value |= (next & 0x7F) << shift;
                if ((next & 0x80) == 0) return negative ? -value : value;
                shift += 7;
            }
            throw new InvalidDataException("FCompactIndex exceeds five bytes.");
        }

        return negative ? -value : value;
    }
}

/// <summary>A <see cref="MaterialSequence"/> together with the material slot that binds it.</summary>
/// <remarks>
/// The slot is what says which channel the timeline drives — the census found sequences bound under
/// <c>Emissive</c>, <c>NormalMap</c>, <c>FluidNormalMap</c> and <c>Material</c>, which are four very
/// different things to animate.
/// </remarks>
public sealed record MaterialSlotSequence
{
    public required string Slot { get; init; }
    public required MaterialSequence Sequence { get; init; }
}
