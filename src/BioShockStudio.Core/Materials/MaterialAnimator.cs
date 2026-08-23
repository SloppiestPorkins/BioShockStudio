using System.Text.Json.Serialization;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Materials;

/// <summary>
/// The kind of UV or colour animation a material hangs off one of its slots.
/// </summary>
/// <remarks>
/// <b>These are BioShock's own classes, not UE2's.</b> UModel documents `TexPanner`
/// (`PanDirection`, `PanRate`) and `TexRotator` (`TexRotationType`, `UOffset`, `VOffset`,
/// oscillation triple) — <b>this game ships neither name nor either layout</b>. It ships
/// `TexturePanner`, `TextureRotator`, `TextureScalar` and `ColorCycle` with different, simpler
/// fields, censused across all 33 packages. Reading the reference layout here would have produced
/// confident nonsense.
/// </remarks>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum MaterialAnimatorKind
{
    /// <summary>A class in the modifier position that this reader does not know.</summary>
    Unknown,

    /// <summary>`TexturePanner` — scrolls UVs. 2,823 in the game.</summary>
    Panner,

    /// <summary>`TextureRotator` — rotates UVs. 418.</summary>
    Rotator,

    /// <summary>`TextureScalar` — scales UVs. 691.</summary>
    Scalar,

    /// <summary>`ColorCycle` — animates a colour rather than UVs. 630.</summary>
    ColorCycle,
}

/// <summary>
/// A UV or colour animator bound to one of a material's slots.
/// </summary>
/// <remarks>
/// <para>
/// Gate 1 item 4's "panners/rotators". Before this, these were the largest group of object
/// properties a material carried that resolved to nothing: <c>MaterialReader</c> accepts a binding
/// only when it resolves to a <c>Texture</c>, which is correct — an animator is not a texture — but
/// it meant 4,562 animator bindings landed in <c>UnhandledProperties</c> and nothing said what a
/// scrolling or rotating surface was supposed to do.
/// </para>
/// <para>
/// <b>Every field here is carried, not interpreted.</b> The units of <c>PanTime</c>,
/// <c>Duration</c> and the <c>Waveform</c> byte are <c>UNKNOWN</c> — nothing observed so far pins
/// them, and this project does not have the game's renderer to compare against. What is
/// <c>CONFIRMED_BYTES</c> is which properties exist, on which classes, and how often.
/// </para>
/// </remarks>
public sealed record MaterialAnimator
{
    /// <summary>The material slot the animator hangs off, e.g. <c>DiffuseTextureAnimator</c>.</summary>
    public required string Slot { get; init; }

    public required MaterialAnimatorKind Kind { get; init; }

    /// <summary>The animator object's own class name, verbatim.</summary>
    public required string ClassName { get; init; }

    /// <summary>`TexturePanner`: scroll rate in U and V. Units UNKNOWN.</summary>
    public float? PanU { get; init; }

    public float? PanV { get; init; }

    /// <summary>`TextureScalar`: scale in U and V.</summary>
    public float? ScaleU { get; init; }

    public float? ScaleV { get; init; }

    /// <summary>`TextureScalar` / `TextureRotator`: the centre the transform is applied about.</summary>
    public float? CenterU { get; init; }

    public float? CenterV { get; init; }

    /// <summary>
    /// `TexturePanner`'s <c>PanTime</c>, or the <c>Duration</c> the other classes declare. UNKNOWN
    /// whether these are the same quantity, so the source property name is kept in
    /// <see cref="DurationProperty"/> rather than the two being silently merged.
    /// </summary>
    public float? Duration { get; init; }

    /// <summary>Which property <see cref="Duration"/> came from.</summary>
    public string? DurationProperty { get; init; }

    /// <summary>
    /// `TextureRotator`'s <c>Rotation</c>, as the three raw components it serialises.
    /// </summary>
    /// <remarks>
    /// Carried raw. Whether these are Unreal rotator units (65536 to a turn) is <c>PLAUSIBLE</c>
    /// from the struct's shape and <b>not</b> confirmed against anything this project can observe,
    /// so no conversion to degrees is applied — a wrong conversion would be invisible in the data
    /// and obvious only on screen.
    /// </remarks>
    public int[]? Rotation { get; init; }

    /// <summary>The `Waveform` byte, where one is declared. Values UNKNOWN.</summary>
    public byte? Waveform { get; init; }

    /// <summary>Property names on the animator this reader did not interpret.</summary>
    public required IReadOnlyList<string> Uninterpreted { get; init; }
}

/// <summary>Reads BioShock's UV and colour animator objects.</summary>
public static class MaterialAnimatorReader
{
    /// <summary>
    /// The classes that appear in a material's modifier position, with their counts across the
    /// game. Censused rather than taken from a reference project — see
    /// <see cref="MaterialAnimatorKind"/> for why that distinction mattered here.
    /// </summary>
    private static readonly Dictionary<string, MaterialAnimatorKind> Kinds = new(StringComparer.Ordinal)
    {
        ["TexturePanner"] = MaterialAnimatorKind.Panner,
        ["TextureRotator"] = MaterialAnimatorKind.Rotator,
        ["TextureScalar"] = MaterialAnimatorKind.Scalar,
        ["ColorCycle"] = MaterialAnimatorKind.ColorCycle,
    };

    /// <summary>True when this class is one of the animators.</summary>
    public static bool IsAnimatorClass(string className) => Kinds.ContainsKey(className);

    /// <summary>
    /// Reads the animator an object property points at. Null when it does not point at one.
    /// </summary>
    public static MaterialAnimator? Read(BioShockPackage package, string slot, UnrealProperty property)
    {
        if (property.Type != UnrealPropertyType.Object) return null;
        if (!property.TryAsObjectReference(out var reference)) return null;
        if (!reference.IsExport || reference.ExportIndex >= package.Exports.Count) return null;

        var export = package.Exports[reference.ExportIndex];
        string className = package.GetClassName(export);
        if (!Kinds.TryGetValue(className, out var kind)) return null;

        List<UnrealProperty> properties;
        try { properties = UnrealPropertyReader.Read(package.ReadExportData(export), package.Names, out _); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            // The binding is real even when the payload will not walk; report it rather than
            // dropping it back into the unhandled pile where it looks like an unknown property.
            return new MaterialAnimator
            {
                Slot = slot,
                Kind = kind,
                ClassName = className,
                Uninterpreted = ["<payload unreadable>"],
            };
        }

        float? panU = null, panV = null, scaleU = null, scaleV = null, centreU = null, centreV = null;
        float? duration = null;
        string? durationProperty = null;
        int[]? rotation = null;
        byte? waveform = null;
        var uninterpreted = new List<string>();

        foreach (var p in properties)
        {
            switch (p.Name)
            {
                case "UPan": panU = p.AsFloat(); continue;
                case "VPan": panV = p.AsFloat(); continue;
                case "ScaleU": scaleU = p.AsFloat(); continue;
                case "ScaleV": scaleV = p.AsFloat(); continue;
                case "CenterU" or "UCenter": centreU = p.AsFloat(); continue;
                case "CenterV" or "VCenter": centreV = p.AsFloat(); continue;

                // PanTime and Duration occupy the same role on different classes. Kept as one field
                // with the source name attached, because whether they are the same quantity is
                // UNKNOWN and merging them silently would assert that they are.
                case "PanTime" or "Duration":
                    duration = p.AsFloat();
                    durationProperty = p.Name;
                    continue;

                // Only the first byte of a Waveform matters; TextureScalar splits it per axis.
                case "Waveform" or "WaveformU": waveform ??= p.AsByte(); continue;

                case "Rotation": rotation = ReadRotation(p); continue;

                // Every export carries this tag; it is not part of the animator.
                case "CheckpointTypePadding": continue;
            }

            uninterpreted.Add(p.Name);
        }

        return new MaterialAnimator
        {
            Slot = slot,
            Kind = kind,
            ClassName = className,
            PanU = panU,
            PanV = panV,
            ScaleU = scaleU,
            ScaleV = scaleV,
            CenterU = centreU,
            CenterV = centreV,
            Duration = duration,
            DurationProperty = durationProperty,
            Rotation = rotation,
            Waveform = waveform,
            Uninterpreted = uninterpreted,
        };
    }

    /// <summary>
    /// Reads `Rotation`'s three components. Null unless the struct is exactly the expected size.
    /// </summary>
    /// <remarks>
    /// Three <c>int32</c>. Refuses anything shorter rather than reading what happens to be there —
    /// a partly-read rotation is worse than none, because it looks like data.
    /// </remarks>
    private static int[]? ReadRotation(UnrealProperty property)
    {
        if (property.Value.Length < 12) return null;

        var value = new int[3];
        for (int i = 0; i < 3; i++)
            value[i] = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(
                property.Value.AsSpan(i * 4, 4));

        return value;
    }
}
