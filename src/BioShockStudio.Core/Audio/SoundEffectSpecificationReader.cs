using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Audio;

/// <summary>A shipped <c>Range</c> struct: two floats, always tagged <c>Min</c> and <c>Max</c>.</summary>
public sealed record SoundEffectRange(float Min, float Max);

/// <summary>A shipped <c>PolyLoopStruct</c>: a nested <c>Range</c> plus a concurrent-voice limit.</summary>
public sealed record SoundEffectPolyLoop(SoundEffectRange? Range, int? LoopSoundLimit);

/// <summary>
/// One entry of a specification's <c>SoundSpecs</c> array — the shipped link from a sound effect to
/// a named sample.
/// </summary>
/// <remarks>
/// <c>SoundUnit</c> is the logical audio unit the sample belongs to (<c>Weapons</c>,
/// <c>Footsteps</c>, <c>ambience_0_Lighthouse</c>); it is <b>not</b> an FSB bank filename and is not
/// treated as one. <c>SoundName</c> is the sample's exact name. Several entries on one
/// specification are the game's alternatives for the same effect.
/// </remarks>
public sealed record SoundSpecEntry(
    string? SoundUnit,
    string? SoundName,
    int? StreamingBlockIndexXenon,
    int? StreamingBlockIndexWindows,
    byte? Flag,
    PackageIndex? SoundToPlay,
    byte? PerSoundVolumeMod);

/// <summary>
/// Everything a shipped <c>SoundEffectSpecification</c> object serializes. Null fields mean
/// "inherit the script-class default", never zero.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is where BioShock keeps the per-sound attenuation, volume, pitch and variation data.</b>
/// The placed level actors carry none of it — see <c>docs/research/audio.md</c>. A specification
/// names its alternatives in <see cref="SoundSpecs"/> and modulates them with the range fields.
/// </para>
/// <para>
/// <see cref="SoundSpecsComplete"/> is false when the <c>SoundSpecs</c> array did not consume its
/// own value exactly. A partially-read array would silently drop alternatives, so it is reported
/// rather than trimmed.
/// </para>
/// </remarks>
public sealed record SoundEffectMetadata
{
    public required string SoundName { get; init; }

    // Attenuation.
    public float? OuterRadius { get; init; }
    public float? InnerRadius { get; init; }
    public bool? Is2DPositional { get; init; }
    public bool? AttachToSource { get; init; }
    public bool? Local { get; init; }

    // Level and pitch.
    public int? Volume { get; init; }
    public byte? VolumeCategory { get; init; }
    public SoundEffectRange? VolumeRange { get; init; }
    public float? Pitch { get; init; }
    public SoundEffectRange? PitchRange { get; init; }
    public SoundEffectRange? DynamicPitchInputRange { get; init; }
    public SoundEffectRange? DynamicPitchOutputRange { get; init; }

    // Timing, looping and repetition.
    public SoundEffectRange? DelayRange { get; init; }
    public float? FadeInTime { get; init; }
    public float? FadeOutTime { get; init; }
    public SoundEffectRange? Monoloop { get; init; }
    public SoundEffectPolyLoop? Polyloop { get; init; }
    public int? Monophonic { get; init; }
    public int? MonophonicPriority { get; init; }
    public bool? NeverRepeat { get; init; }
    public bool? NoRepeat { get; init; }
    public bool? Retriggerable { get; init; }
    public bool? PlayOnce { get; init; }
    public bool? JumpToFinalPart { get; init; }
    public bool? IsThreePartSound { get; init; }
    public SoundEffectRange? ThreePartLoopPoints { get; init; }

    // Playback plumbing.
    public bool? Precache { get; init; }
    public bool? ExemptFromPausing { get; init; }
    public bool? StreamingOnWindows { get; init; }
    public bool? StreamingOnXenon { get; init; }

    /// <summary>The shipped alternatives this effect can play.</summary>
    public IReadOnlyList<SoundSpecEntry> SoundSpecs { get; init; } = [];

    /// <summary>True when the object declared a <c>SoundSpecs</c> array at all.</summary>
    public bool SoundSpecsPresent { get; init; }

    /// <summary>True when the <c>SoundSpecs</c> array consumed its value exactly.</summary>
    public bool SoundSpecsComplete { get; init; }
}

/// <summary>
/// Reads the shipped <c>SoundEffectSpecification</c> objects. These carry the game's per-sound
/// attenuation, volume, pitch and variation settings, and name the samples each effect can play.
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
            var metadata = Read(package, export);
            if (metadata is not null) result.Add(metadata);
        }
        return result;
    }

    public static SoundEffectMetadata? Read(BioShockPackage package, ObjectExport export)
    {
        try
        {
            var properties = UnrealPropertyReader.Read(package.ReadExportData(export), package.Names, out _);
            UnrealProperty? Property(string name) => properties.FirstOrDefault(property => property.Name == name);

            var array = Property("SoundSpecs");
            bool complete = array is not null && PropertyValues.TryAsStructArrayExact(array, package, out _);

            return new SoundEffectMetadata
            {
                SoundName = export.ObjectName,
                OuterRadius = Float(Property("OuterRadius")),
                InnerRadius = Float(Property("InnerRadius")),
                Is2DPositional = Bool(Property("Is2DPositional")),
                AttachToSource = Bool(Property("AttachToSource")),
                Local = Bool(Property("Local")),
                Volume = Int(Property("Volume")),
                VolumeCategory = Byte(Property("VolumeCategory")),
                VolumeRange = Range(package, Property("VolumeRange")),
                Pitch = Float(Property("Pitch")),
                PitchRange = Range(package, Property("PitchRange")),
                DynamicPitchInputRange = Range(package, Property("DynamicPitchInputRange")),
                DynamicPitchOutputRange = Range(package, Property("DynamicPitchOutputRange")),
                DelayRange = Range(package, Property("DelayRange")),
                FadeInTime = Float(Property("FadeInTime")),
                FadeOutTime = Float(Property("FadeOutTime")),
                Monoloop = Range(package, Property("Monoloop")),
                Polyloop = PolyLoop(package, Property("Polyloop")),
                Monophonic = Int(Property("Monophonic")),
                MonophonicPriority = Int(Property("MonophonicPriority")),
                NeverRepeat = Bool(Property("NeverRepeat")),
                NoRepeat = Bool(Property("NoRepeat")),
                Retriggerable = Bool(Property("Retriggerable")),
                PlayOnce = Bool(Property("PlayOnce")),
                JumpToFinalPart = Bool(Property("JumpToFinalPart")),
                IsThreePartSound = Bool(Property("IsThreePartSound")),
                ThreePartLoopPoints = Range(package, Property("ThreePartLoopPoints")),
                Precache = Bool(Property("Precache")),
                ExemptFromPausing = Bool(Property("ExemptFromPausing")),
                StreamingOnWindows = Bool(Property("bStreamingOnWindows")),
                StreamingOnXenon = Bool(Property("bStreamingOnXenon")),
                SoundSpecs = complete ? ReadSpecs(package, array!) : [],
                SoundSpecsPresent = array is not null,
                SoundSpecsComplete = complete,
            };
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException or IOException)
        {
            // A malformed object is not metadata evidence.
            return null;
        }
    }

    private static IReadOnlyList<SoundSpecEntry> ReadSpecs(BioShockPackage package, UnrealProperty array)
    {
        if (!PropertyValues.TryAsStructArrayExact(array, package, out var elements)) return [];

        var result = new List<SoundSpecEntry>(elements.Count);
        foreach (var element in elements)
        {
            UnrealProperty? Field(string name) => element.FirstOrDefault(property => property.Name == name);
            var reference = Field("SoundToPlay");
            PackageIndex? target = reference is not null && reference.TryAsObjectReference(out var index)
                ? index
                : null;
            result.Add(new SoundSpecEntry(
                Str(Field("SoundUnit")),
                Str(Field("SoundName")),
                Int(Field("StreamingBlockIndexXenon")),
                Int(Field("StreamingBlockIndexWindows")),
                Byte(Field("Flag")),
                target,
                Byte(Field("PerSoundVolumeMod"))));
        }
        return result;
    }

    /// <summary>
    /// A <c>Range</c> value is its own tagged property list, so it is read as one rather than as a
    /// fixed pair of floats — and only accepted when both tagged fields are present.
    /// </summary>
    private static SoundEffectRange? Range(BioShockPackage package, UnrealProperty? property)
    {
        if (property is not { Type: UnrealPropertyType.Struct }) return null;
        try
        {
            var fields = UnrealPropertyReader.Read(property.Value, package.Names, out _, 0);
            float? min = Float(fields.FirstOrDefault(field => field.Name == "Min"));
            float? max = Float(fields.FirstOrDefault(field => field.Name == "Max"));
            return min is null || max is null ? null : new SoundEffectRange(min.Value, max.Value);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return null;
        }
    }

    private static SoundEffectPolyLoop? PolyLoop(BioShockPackage package, UnrealProperty? property)
    {
        if (property is not { Type: UnrealPropertyType.Struct }) return null;
        try
        {
            var fields = UnrealPropertyReader.Read(property.Value, package.Names, out _, 0);
            return new SoundEffectPolyLoop(
                Range(package, fields.FirstOrDefault(field => field.Name == "PolyLoopRange")),
                Int(fields.FirstOrDefault(field => field.Name == "LoopSoundLimit")));
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return null;
        }
    }

    private static string? Str(UnrealProperty? property) => property is { Type: UnrealPropertyType.Str }
        ? PropertyValues.AsString(property) : null;

    private static float? Float(UnrealProperty? property) => property is
        { Type: UnrealPropertyType.Float, Value.Length: >= 4 } ? property.AsFloat() : null;

    private static int? Int(UnrealProperty? property) => property is
        { Type: UnrealPropertyType.Int, Value.Length: >= 4 } ? property.AsInt() : null;

    private static byte? Byte(UnrealProperty? property) => property is
        { Type: UnrealPropertyType.Byte, Value.Length: >= 1 } ? property.AsByte() : null;

    /// <summary>A UE2 <c>Bool</c> carries its value in the tag, so presence is not the value.</summary>
    private static bool? Bool(UnrealProperty? property) => property is
        { Type: UnrealPropertyType.Bool } ? property.BoolValue : null;
}
