using System.Numerics;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// A placed light, with the three parameters that describe it.
/// </summary>
/// <remarks>
/// <para>
/// <b>Status: <c>CONFIRMED_EXTERNAL</c> for the types, <c>CONFIRMED_BYTES</c> for the decode.</b>
/// BioShock writes its light parameters with <i>different types</i> from stock Unreal Engine 2.5,
/// which is exactly why all three sat unread in <c>UninterpretedProperties</c> — they are real
/// tagged properties and nothing was failing, the level layer simply did not know what they were.
/// Nyko's SDK, <c>bioshock1-bsm.md</c> §C.6, states the divergence:
/// </para>
/// <list type="table">
///   <item><term><c>LightBrightness</c></term><description>a <b>float</b> here, 0.0–3.1, median 1.0; a byte 0–255 in stock UE2.5.</description></item>
///   <item><term><c>LightColor</c></term><description>a <b>struct <c>Color</c></b> (BGRA) here; two bytes, <c>LightHue</c> + <c>LightSaturation</c>, in stock UE2.5.</description></item>
///   <item><term><c>LightRadius</c></term><description>a <b>float</b> in world units here, 0–120,000, median 2048; a byte in stock UE2.5, where the world radius is <c>25 × (b + 1)</c>.</description></item>
/// </list>
/// <para>
/// <b>No unit conversion is applied.</b> The stock-UE2.5 byte encodings are recorded above because
/// they explain the divergence, not because anything here converts to them — this reads what
/// BioShock wrote, in BioShock's units, and a consumer that wants some other engine's convention
/// applies it downstream.
/// </para>
/// </remarks>
public sealed record LevelLight
{
    public required SourceId Source { get; init; }

    /// <summary>Where the light is, in the studio's basis.</summary>
    public required Vector3 Location { get; init; }

    /// <summary>The light's colour. Null when the actor stores none, which is not an error.</summary>
    public required LightColor? Color { get; init; }

    /// <summary>
    /// <c>LightBrightness</c>. Null when absent — the class default applies and this layer does not
    /// know it, so it says so rather than substituting one.
    /// </summary>
    public required float? Brightness { get; init; }

    /// <summary><c>LightRadius</c>, in world units.</summary>
    public required float? Radius { get; init; }

    /// <summary>The actor's class — <c>Light</c>, <c>BathLight_8</c>, <c>DynamicLight_Camera</c>, …</summary>
    public string ClassName => Source.ClassName;

    public override string ToString() =>
        $"{ClassName} {Source.ObjectName} at {Location:0.#}"
        + (Color is { } c ? $" {c}" : "")
        + (Brightness is { } b ? $" ×{b:0.##}" : "")
        + (Radius is { } r ? $" r{r:0}" : "");
}

/// <summary>A light's colour, as the eight-bit BGRA the game stores.</summary>
/// <remarks>
/// Kept as bytes rather than converted to a float colour, because the alpha byte's meaning on a
/// light is <c>UNKNOWN</c> and rescaling would quietly assert it is opacity.
/// </remarks>
public readonly record struct LightColor(byte R, byte G, byte B, byte A)
{
    /// <summary>The colour as 0–1 RGB. Alpha is deliberately not included; see the type's remarks.</summary>
    public Vector3 ToVector() => new(R / 255f, G / 255f, B / 255f);

    public override string ToString() => $"#{R:X2}{G:X2}{B:X2}";
}

/// <summary>Reads the light parameters off an actor that carries them.</summary>
public static class LevelLightReader
{
    /// <summary>The property names this reads. Exposed so the analyzer stops counting them as uninterpreted.</summary>
    public static readonly IReadOnlySet<string> Properties = new HashSet<string>(StringComparer.Ordinal)
    {
        "LightColor", "LightBrightness", "LightRadius",
    };

    /// <summary>
    /// Builds a light from an actor, or null when the actor carries none of the three properties.
    /// </summary>
    /// <remarks>
    /// <b>Presence of a property, not the class name, decides.</b> The game ships many light classes
    /// — <c>Light</c>, <c>BathLight_8</c>, <c>DynamicLight_Camera</c> and more — and matching names
    /// would both miss some and catch actors that merely end in "Light". An actor that stores
    /// <c>LightBrightness</c> is a light; that is the game's own statement.
    /// </remarks>
    public static LevelLight? Read(LevelActor actor)
    {
        var color = actor.Properties.FirstOrDefault(p => p.Name == "LightColor");
        var brightness = actor.Properties.FirstOrDefault(p => p.Name == "LightBrightness");
        var radius = actor.Properties.FirstOrDefault(p => p.Name == "LightRadius");

        if (color is null && brightness is null && radius is null) return null;

        return new LevelLight
        {
            Source = actor.Source,
            Location = Coordinates.GameBasis.Convert(actor.Transform.Location),
            Color = color is not null ? ReadColor(color) : null,
            Brightness = brightness is not null ? ReadFloat(brightness) : null,
            Radius = radius is not null ? ReadFloat(radius) : null,
        };
    }

    /// <summary>
    /// An <c>FColor</c>: four bytes, <b>B G R A</b> in that order.
    /// </summary>
    /// <remarks>
    /// The byte order is Unreal's, and the same one <c>MaterialReader</c> already reads for a
    /// material's <c>Color</c> — HANDOFF §4 records that a <c>Color</c> struct is "a plain four-byte
    /// BGRA value, not a property list", established when the struct-size rule was derived. So this
    /// is not a new claim; it is the existing one applied to a light.
    /// </remarks>
    private static LightColor? ReadColor(UnrealProperty property)
    {
        if (property.Value.Length < 4) return null;
        return new LightColor(property.Value[2], property.Value[1], property.Value[0], property.Value[3]);
    }

    /// <summary>
    /// A float, and <b>only</b> a float.
    /// </summary>
    /// <remarks>
    /// A <c>Byte</c>-typed value here would mean this package writes the stock UE2.5 encoding rather
    /// than BioShock's, and silently reading its first byte as part of a float would produce a
    /// plausible wrong number. Returning null instead means the exporter reports the value as absent,
    /// which is honest. <c>LevelLightTests</c> counts how many are actually floats.
    /// </remarks>
    private static float? ReadFloat(UnrealProperty property) =>
        property.Type == UnrealPropertyType.Float && property.Value.Length >= 4 ? property.AsFloat() : null;
}
