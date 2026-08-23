using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Audio;

/// <summary>Explicit per-sound overrides serialized on a shipped specification object.</summary>
public sealed record SoundEffectMetadata(
    string SoundName,
    float? OuterRadius,
    float? InnerRadius,
    int? Volume,
    float? Pitch,
    byte? VolumeCategory);

/// <summary>
/// Reads the concrete <c>SoundEffectSpecification</c> object paired by exact object name with a
/// native <c>Sound</c> export. Null fields mean "inherit the script-class default", not zero.
/// </summary>
public static class SoundEffectSpecificationReader
{
    public const string ClassName = "SoundEffectSpecification";

    public static IReadOnlyList<SoundEffectMetadata> Read(BioShockPackage package)
    {
        var result = new List<SoundEffectMetadata>();
        foreach (var export in package.Exports)
        {
            if (export.SerialSize <= 0 || package.GetClassName(export) != ClassName) continue;
            try
            {
                var properties = UnrealPropertyReader.Read(package.ReadExportData(export), package.Names, out _);
                UnrealProperty? Property(string name) => properties.FirstOrDefault(property => property.Name == name);
                result.Add(new SoundEffectMetadata(
                    export.ObjectName,
                    Float(Property("OuterRadius")),
                    Float(Property("InnerRadius")),
                    Int(Property("Volume")),
                    Float(Property("Pitch")),
                    Byte(Property("VolumeCategory"))));
            }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                           or ArgumentOutOfRangeException or IOException)
            {
                // A malformed object is not metadata evidence.
            }
        }
        return result;
    }

    private static float? Float(UnrealProperty? property) => property is
        { Type: UnrealPropertyType.Float, Value.Length: >= 4 } ? property.AsFloat() : null;

    private static int? Int(UnrealProperty? property) => property is
        { Type: UnrealPropertyType.Int, Value.Length: >= 4 } ? property.AsInt() : null;

    private static byte? Byte(UnrealProperty? property) => property is
        { Type: UnrealPropertyType.Byte, Value.Length: >= 1 } ? property.AsByte() : null;
}
