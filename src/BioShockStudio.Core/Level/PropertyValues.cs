using System.Buffers.Binary;
using System.Numerics;
using System.Text;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// Decodes the value bytes of an <see cref="UnrealProperty"/>.
/// <para>
/// The property reader deliberately keeps values as bytes, because what a value means depends on
/// the property's type and, for structs, on its struct name. These helpers do that reading in one
/// place so no caller has to know that an <c>Object</c> value is an <c>FCompactIndex</c> and a
/// <c>Name</c> value is an index plus a number.
/// </para>
/// </summary>
public static class PropertyValues
{
    public readonly record struct ProjectorGradient(float FadeInEnd, float FadeOutStart);

    /// <summary>An <c>Object</c> or <c>Class</c> property's reference, or null when it will not decode.</summary>
    public static PackageIndex? AsReference(UnrealProperty property)
    {
        int offset = 0;
        try { return new PackageIndex(ReadCompactIndex(property.Value, ref offset)); }
        catch { return null; }
    }

    /// <summary>A <c>Name</c> property's text, resolved against the package's name table.</summary>
    public static string? AsName(UnrealProperty property, BioShockPackage package)
    {
        int offset = 0;
        int index;
        try { index = ReadCompactIndex(property.Value, ref offset); }
        catch { return null; }
        if (index < 0 || index >= package.Names.Count || offset + 4 > property.Value.Length) return null;
        int number = BinaryPrimitives.ReadInt32LittleEndian(property.Value.AsSpan(offset));
        string name = package.Names[index].Name;
        return number == 0 ? name : name + (number - 1);
    }

    /// <summary>A BioShock UTF-16 <c>Str</c>: compact character count, text, and a null terminator.</summary>
    public static string? AsString(UnrealProperty property)
    {
        int offset = 0;
        int count;
        try { count = ReadCompactIndex(property.Value, ref offset); }
        catch { return null; }
        if (count <= 0) return count == 0 ? string.Empty : null;
        int bytes = (count - 1) * 2;
        if (offset + bytes + 2 != property.Value.Length) return null;
        return Encoding.Unicode.GetString(property.Value, offset, bytes);
    }

    /// <summary>An exact array of FNames: compact count, then name-index/number pairs.</summary>
    public static bool TryAsNameArrayExact(
        UnrealProperty property, BioShockPackage package, out IReadOnlyList<string> values)
    {
        values = [];
        int offset = 0;
        try
        {
            int count = ReadCompactIndex(property.Value, ref offset);
            if (count < 0 || count > property.Value.Length) return false;
            var result = new List<string>(count);
            for (int i = 0; i < count; i++)
            {
                int nameIndex = ReadCompactIndex(property.Value, ref offset);
                if (nameIndex < 0 || nameIndex >= package.Names.Count || offset + 4 > property.Value.Length)
                    return false;
                int number = BinaryPrimitives.ReadInt32LittleEndian(property.Value.AsSpan(offset));
                offset += 4;
                string name = package.Names[nameIndex].Name;
                result.Add(number == 0 ? name : name + (number - 1));
            }
            if (offset != property.Value.Length) return false;
            values = result;
            return true;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException
                                       or InvalidDataException)
        {
            return false;
        }
    }

    /// <summary>An exact compact array of name-table indices, without the numbered-name suffix.</summary>
    public static bool TryAsNameIndexArrayExact(
        UnrealProperty property, BioShockPackage package, out IReadOnlyList<string> values)
    {
        values = [];
        int offset = 0;
        try
        {
            int count = ReadCompactIndex(property.Value, ref offset);
            if (count < 0 || count > property.Value.Length) return false;
            var result = new List<string>(count);
            for (int i = 0; i < count; i++)
            {
                int nameIndex = ReadCompactIndex(property.Value, ref offset);
                if (nameIndex < 0 || nameIndex >= package.Names.Count) return false;
                result.Add(package.Names[nameIndex].Name);
            }
            if (offset != property.Value.Length) return false;
            values = result;
            return true;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException
                                       or InvalidDataException)
        {
            return false;
        }
    }

    /// <summary>The exact two-float tagged layout of a BioShock <c>ProjectorGradient</c>.</summary>
    public static bool TryAsProjectorGradientExact(
        UnrealProperty property, BioShockPackage package, out ProjectorGradient gradient)
    {
        gradient = default;
        int offset = 0;
        try
        {
            float ReadFloat(string expectedName)
            {
                int nameIndex = ReadCompactIndex(property.Value, ref offset);
                if (nameIndex < 0 || nameIndex >= package.Names.Count
                    || package.Names[nameIndex].Name != expectedName || offset + 9 > property.Value.Length)
                    throw new InvalidDataException();
                int number = BinaryPrimitives.ReadInt32LittleEndian(property.Value.AsSpan(offset));
                offset += 4;
                if (number != 0 || property.Value[offset++] != 0x24) throw new InvalidDataException();
                float value = BinaryPrimitives.ReadSingleLittleEndian(property.Value.AsSpan(offset));
                offset += 4;
                return value;
            }

            float fadeInEnd = ReadFloat("FadeInEnd");
            float fadeOutStart = ReadFloat("FadeOutStart");
            int terminator = ReadCompactIndex(property.Value, ref offset);
            if (terminator < 0 || terminator >= package.Names.Count
                || package.Names[terminator].Name != "None" || offset + 4 != property.Value.Length
                || BinaryPrimitives.ReadInt32LittleEndian(property.Value.AsSpan(offset)) != 0) return false;
            gradient = new ProjectorGradient(fadeInEnd, fadeOutStart);
            return true;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException
                                       or InvalidDataException)
        {
            return false;
        }
    }

    /// <summary>A twelve-byte <c>Vector</c> struct.</summary>
    public static Vector3? AsVector(UnrealProperty property)
    {
        if (property.Value.Length < 12) return null;
        return new Vector3(
            BinaryPrimitives.ReadSingleLittleEndian(property.Value),
            BinaryPrimitives.ReadSingleLittleEndian(property.Value.AsSpan(4)),
            BinaryPrimitives.ReadSingleLittleEndian(property.Value.AsSpan(8)));
    }

    /// <summary>A four-byte Unreal <c>Color</c> struct, stored BGRA.</summary>
    public static LightColor? AsColor(UnrealProperty property) => property.Value.Length >= 4
        ? new LightColor(property.Value[2], property.Value[1], property.Value[0], property.Value[3])
        : null;

    /// <summary>A twelve-byte <c>Rotator</c> struct: three int32 angles in Unreal's 65,536-per-turn units.</summary>
    public static UnrealRotator? AsRotator(UnrealProperty property)
    {
        if (property.Value.Length < 12) return null;
        return new UnrealRotator(
            BinaryPrimitives.ReadInt32LittleEndian(property.Value),
            BinaryPrimitives.ReadInt32LittleEndian(property.Value.AsSpan(4)),
            BinaryPrimitives.ReadInt32LittleEndian(property.Value.AsSpan(8)));
    }

    /// <summary>
    /// The elements of an array of object references: an <c>FCompactIndex</c> count followed by that
    /// many <c>FCompactIndex</c> references. Returns what it could read rather than throwing, so a
    /// list whose element type is something else yields nothing instead of nonsense.
    /// </summary>
    public static IReadOnlyList<PackageIndex> AsReferenceArray(UnrealProperty property)
    {
        var result = new List<PackageIndex>();
        int offset = 0;
        int count;
        try { count = ReadCompactIndex(property.Value, ref offset); }
        catch { return result; }
        if (count <= 0 || count > property.Value.Length) return result;

        for (int i = 0; i < count; i++)
        {
            int value;
            try { value = ReadCompactIndex(property.Value, ref offset); }
            catch { break; }
            result.Add(new PackageIndex(value));
        }
        return result;
    }

    /// <summary>
    /// Reads a packed object-reference array only when its compact count consumes the complete
    /// property value. Use this for a field whose element identity will be exported: accepting a
    /// valid-looking prefix would silently turn an unknown action payload into a partial graph.
    /// </summary>
    public static bool TryAsReferenceArrayExact(UnrealProperty property, out IReadOnlyList<PackageIndex> values)
    {
        values = [];
        int offset = 0;
        try
        {
            int count = ReadCompactIndex(property.Value, ref offset);
            if (count < 0 || count > property.Value.Length) return false;

            var result = new List<PackageIndex>(count);
            for (int i = 0; i < count; i++)
                result.Add(new PackageIndex(ReadCompactIndex(property.Value, ref offset)));

            if (offset != property.Value.Length) return false;
            values = result;
            return true;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException
                                       or InvalidDataException)
        {
            return false;
        }
    }

    /// <summary>An exact array of tagged-property structs, each terminated by its own <c>None</c>.</summary>
    public static bool TryAsStructArrayExact(
        UnrealProperty property, BioShockPackage package,
        out IReadOnlyList<IReadOnlyList<UnrealProperty>> values)
    {
        values = [];
        int offset = 0;
        try
        {
            int count = ReadCompactIndex(property.Value, ref offset);
            if (count < 0 || count > property.Value.Length) return false;
            var result = new List<IReadOnlyList<UnrealProperty>>(count);
            for (int i = 0; i < count; i++)
            {
                int start = offset;
                var fields = UnrealPropertyReader.Read(property.Value, package.Names, out offset, start);
                if (offset <= start || offset > property.Value.Length) return false;
                result.Add(fields);
            }
            if (offset != property.Value.Length) return false;
            values = result;
            return true;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException
                                       or InvalidDataException)
        {
            return false;
        }
    }

    internal static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
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
