using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>A resolved <c>LightClass</c> reference's own defaults — a <c>DynamicLightEffect</c>
/// subclass, not an <c>Emitter</c>, so it carries plain light fields directly rather than a particle
/// template.</summary>
public sealed record WeaponEffectLight
{
    public required AssetReference Source { get; init; }
    public float? LightBrightness { get; init; }
    public LightColor? LightColor { get; init; }
    public float? LightRadius { get; init; }
    public float? LifeSpan { get; init; }
}

/// <summary>One element of a weapon class's <c>OnFiredEffects</c> or <c>TracerEffects</c> array.
/// <c>TracerEffects</c> elements carry a strict subset of the fields — everything here is optional
/// for exactly that reason, not because any one field failed to decode.</summary>
public sealed record WeaponFiredEffect
{
    public EmitterTemplateData? Emitter { get; init; }
    public WeaponEffectLight? Light { get; init; }
    public string? AttachmentBone { get; init; }
    public Vector3? LocationOffset { get; init; }
    public UnrealRotator? RotationOffset { get; init; }
    public string? AmmoType { get; init; }

    /// <summary>Raw byte value. Meaning UNKNOWN — not yet cross-referenced against anything.</summary>
    public int? UpgradeType { get; init; }

    /// <summary>Raw byte value. Meaning UNKNOWN — not yet cross-referenced against anything.</summary>
    public int? EmitterAction { get; init; }
}

public sealed record WeaponEffectsData
{
    public required string ClassName { get; init; }
    public required IReadOnlyList<WeaponFiredEffect> OnFiredEffects { get; init; }
    public required IReadOnlyList<WeaponFiredEffect> TracerEffects { get; init; }
}

/// <summary>
/// Decodes a weapon class's own "on fired" and "tracer" visual effects from its <b>class
/// defaults</b> — weapons are never placed level actors, so this reads a <c>Class</c> export
/// directly rather than an <see cref="Level.ActorPayload"/>.
/// <para>
/// Each array element names an <c>EmitterClass</c> (an <c>Emitter</c>-derived class, decoded with
/// the same <see cref="LevelAnalyzer.ReadEmitterTemplate"/> reader a placed level actor's own
/// <c>Emitters</c> array uses — it is the identical shape either way) and, on <c>OnFiredEffects</c>
/// elements only, an optional <c>LightClass</c> (a <c>DynamicLightEffect</c>-derived class, a
/// different shape read directly here rather than through the emitter reader).
/// </para>
/// </summary>
public static class WeaponEffects
{
    /// <summary>
    /// Reads <paramref name="className"/>'s own <c>OnFiredEffects</c>/<c>TracerEffects</c> class
    /// defaults from <paramref name="package"/>. Null when no <c>Class</c> export by that name
    /// exists — not when the arrays are merely absent or empty, which is a real, valid answer
    /// (<see cref="WeaponEffectsData"/> with two empty lists).
    /// </summary>
    public static WeaponEffectsData? For(BioShockPackage package, string className)
    {
        var export = package.Exports.FirstOrDefault(e =>
            package.GetClassName(e) == "Class" && string.Equals(e.ObjectName, className, StringComparison.OrdinalIgnoreCase));
        if (export is null) return null;

        var defaults = new ClassDefaults(package).For(export);

        return new WeaponEffectsData
        {
            ClassName = export.ObjectName,
            OnFiredEffects = ReadEffectArray(package, defaults, "OnFiredEffects"),
            TracerEffects = ReadEffectArray(package, defaults, "TracerEffects"),
        };
    }

    private static IReadOnlyList<WeaponFiredEffect> ReadEffectArray(
        BioShockPackage package, IReadOnlyList<UnrealProperty> defaults, string propertyName)
    {
        var property = defaults.FirstOrDefault(p => p.Name == propertyName && p.Type == UnrealPropertyType.Array);
        if (property is null) return [];

        if (LevelAnalyzer.ReadStructArrayElements(package, property) is not { } elements) return [];

        var result = new List<WeaponFiredEffect>(elements.Count);
        foreach (var fields in elements) result.Add(ReadEffect(package, fields));
        return result;
    }

    private static WeaponFiredEffect ReadEffect(BioShockPackage package, List<UnrealProperty> fields)
    {
        UnrealProperty? Find(string name) => fields.FirstOrDefault(f => f.Name == name);

        // A field's wire type (Str vs Name, Byte vs Int) hasn't been independently confirmed for
        // every element -- both text properties and both integer ones are dispatched by whichever
        // type actually shows up, rather than assuming one.
        string? Text(string name)
        {
            var field = Find(name);
            return field switch
            {
                { Type: UnrealPropertyType.Str } => PropertyValues.AsString(field),
                { Type: UnrealPropertyType.Name } => PropertyValues.AsName(field, package),
                _ => null,
            };
        }

        int? Number(string name)
        {
            var field = Find(name);
            return field switch
            {
                { Type: UnrealPropertyType.Byte } => field.AsByte(),
                { Type: UnrealPropertyType.Int } => field.AsInt(),
                _ => null,
            };
        }

        return new WeaponFiredEffect
        {
            Emitter = ResolveEmitter(package, Find("EmitterClass")),
            Light = ResolveLight(package, Find("LightClass")),
            AttachmentBone = Text("AttachmentBone"),
            LocationOffset = Find("LocationOffset") is { Type: UnrealPropertyType.Struct } location
                ? PropertyValues.AsVector(location) : null,
            RotationOffset = Find("RotationOffset") is { Type: UnrealPropertyType.Struct } rotation
                ? PropertyValues.AsRotator(rotation) : null,
            AmmoType = Text("AmmoType"),
            UpgradeType = Number("UpgradeType"),
            EmitterAction = Number("EmitterAction"),
        };
    }

    /// <summary>
    /// Resolves a <c>Class</c>-typed reference field to the export it names, only when that export
    /// is local to <paramref name="package"/>. A reference into another package (the FX class lives
    /// somewhere other than the weapon's own package) is left unresolved rather than chased —
    /// consistent with this project's existing convention of resolving only within the currently
    /// open package.
    /// </summary>
    private static AssetReference? ResolveClassReference(BioShockPackage package, UnrealProperty? field, string origin)
    {
        // A class-typed reference wire-encodes as an Object property here (confirmed by reading
        // the actual field, not assumed from the UnrealScript-source-level `Class'...'` syntax the
        // UELib decompiler renders it as) -- PropertyValues.AsReference already documents itself as
        // handling either.
        if (field is not { Type: UnrealPropertyType.Object or UnrealPropertyType.Class }) return null;
        if (PropertyValues.AsReference(field) is not { IsNull: false } index) return null;
        return LevelAnalyzer.Describe(package, index, origin, null);
    }

    private static EmitterTemplateData? ResolveEmitter(BioShockPackage package, UnrealProperty? field)
    {
        var reference = ResolveClassReference(package, field, "weapon effect");
        return reference?.Source is not null ? LevelAnalyzer.ReadEmitterTemplate(package, reference) : null;
    }

    private static WeaponEffectLight? ResolveLight(BioShockPackage package, UnrealProperty? field)
    {
        var reference = ResolveClassReference(package, field, "weapon effect light");
        if (reference?.Source is not { } local) return null;

        var lightDefaults = new ClassDefaults(package).For(package.Exports[local.ExportIndex]);

        float? Float(string name) =>
            lightDefaults.FirstOrDefault(f => f.Name == name && f.Type == UnrealPropertyType.Float)?.AsFloat();

        return new WeaponEffectLight
        {
            Source = reference,
            LightBrightness = Float("LightBrightness"),
            LightColor = lightDefaults.FirstOrDefault(
                    f => f.Name == "LightColor" && f is { Type: UnrealPropertyType.Struct, StructName: "Color" })
                is { } colorField ? PropertyValues.AsColor(colorField) : null,
            LightRadius = Float("LightRadius"),
            LifeSpan = Float("LifeSpan"),
        };
    }
}
