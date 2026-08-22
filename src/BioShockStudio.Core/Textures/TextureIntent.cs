using System.Text.Json.Serialization;

namespace BioShockStudio.Core.Textures;

/// <summary>What a texture is for, which is what decides how an engine must sample it.</summary>
/// <remarks>
/// Serialised by name. This is engine-facing metadata read by a separate importer, so an ordinal
/// would make the file's meaning depend on the declaration order of an enum the importer cannot see.
/// </remarks>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum TextureUsage
{
    /// <summary>Nothing identifies this texture's role.</summary>
    Unknown,

    /// <summary>Base colour — the only usage that is unambiguously colour.</summary>
    BaseColor,

    /// <summary>A tangent-space normal map.</summary>
    NormalMap,

    /// <summary>Specular colour or a specular/gloss mask.</summary>
    Specular,

    /// <summary>A single-channel control map: opacity, coverage, clip, subsurface, glossiness.</summary>
    Mask,

    /// <summary>Emissive colour or its mask.</summary>
    Emissive,

    /// <summary>A displacement or height map.</summary>
    Height,

    /// <summary>An environment cubemap.</summary>
    Cubemap,
}

/// <summary>
/// Whether a texture's values are colour or data.
/// </summary>
/// <remarks>
/// <b>This game declares no colour space anywhere.</b> Censused across all 33 packages: none of the
/// 30,831 shipped <c>Texture</c> exports carries an <c>sRGB</c>, <c>CompressionSettings</c> or
/// <c>MipGenSettings</c> property — the last two appear in Nyko's SDK property-name list but are
/// never serialised by the shipped game. So colour space is <b>inferred from usage</b> and is
/// labelled that way rather than presented as decoded fact.
/// </remarks>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum TextureColourSpace
{
    /// <summary>Colour, to be sampled with the sRGB transfer curve applied.</summary>
    Srgb,

    /// <summary>Data — normals, masks, heights — to be sampled without a transfer curve.</summary>
    Linear,
}

/// <summary>
/// A texture's engine-facing intent: what it is for, how to sample it, how to address it.
/// </summary>
/// <remarks>
/// <para>
/// Gate 1 item 3 asks for this as UE5-facing metadata "not just pixels". What the game actually
/// supplies, measured rather than assumed:
/// </para>
/// <list type="bullet">
/// <item><b>Usage</b> — from the material slot that binds the texture, which is the only
/// authoritative statement of role; corroborated by format for normal maps.</item>
/// <item><b>Addressing</b> — <c>UClampMode</c>/<c>VClampMode</c>, <c>CONFIRMED_EXTERNAL</c> against
/// UModel's <c>ETexClampMode</c> and present on ~3,500 textures, always as "clamp".</item>
/// <item><b>Alpha intent</b> — <c>bMasked</c>/<c>bAlphaTexture</c>, which matter because a diffuse's
/// alpha in this game is frequently a gloss mask rather than opacity (see
/// <c>docs/research/materials.md</c>).</item>
/// <item><b>Colour space</b> — <b>not declared at all</b>, therefore inferred. See
/// <see cref="TextureColourSpace"/>.</item>
/// </list>
/// </remarks>
public sealed record TextureIntent
{
    public required TextureUsage Usage { get; init; }

    /// <summary>Inferred from <see cref="Usage"/>, never read from the package. See the remarks.</summary>
    public required TextureColourSpace ColourSpace { get; init; }

    public required TextureAddress AddressU { get; init; }
    public required TextureAddress AddressV { get; init; }

    /// <summary>The texture declares its alpha to be a cutout.</summary>
    public required bool DeclaresMasked { get; init; }

    /// <summary>The texture declares its alpha to be for blending.</summary>
    public required bool DeclaresAlphaTexture { get; init; }

    /// <summary>
    /// The material slot the usage was taken from, so a consumer can audit the inference.
    /// </summary>
    public string? Slot { get; init; }

    /// <summary>
    /// Builds the intent for a texture bound under a given material slot.
    /// </summary>
    /// <param name="texture">The decoded texture, for its declared flags and addressing.</param>
    /// <param name="slot">
    /// The material slot binding it, or null when nothing binds it. The slot is what carries the
    /// role: the same image can legitimately be a base colour in one material and a mask in another.
    /// </param>
    public static TextureIntent For(BioShockTexture texture, string? slot)
    {
        var usage = UsageOf(slot, texture.Format);

        return new TextureIntent
        {
            Usage = usage,
            ColourSpace = ColourSpaceOf(usage),
            AddressU = texture.AddressU,
            AddressV = texture.AddressV,
            DeclaresMasked = texture.DeclaresMasked,
            DeclaresAlphaTexture = texture.DeclaresAlphaTexture,
            Slot = slot,
        };
    }

    /// <summary>
    /// Colour space follows usage: base colour and emissive are colour, everything else is data.
    /// </summary>
    /// <remarks>
    /// <b>Unknown resolves to sRGB deliberately.</b> An unidentified texture is far more often a
    /// base colour than a data map — base colour is the commonest binding by a wide margin — and
    /// the failure is asymmetric: showing a colour map linearly is an obvious, visible error,
    /// whereas the reverse subtly distorts a map most consumers will re-author anyway.
    /// <see cref="Slot"/> is carried alongside so this choice can be audited rather than trusted.
    /// </remarks>
    private static TextureColourSpace ColourSpaceOf(TextureUsage usage) => usage switch
    {
        TextureUsage.NormalMap => TextureColourSpace.Linear,
        TextureUsage.Mask => TextureColourSpace.Linear,
        TextureUsage.Height => TextureColourSpace.Linear,
        _ => TextureColourSpace.Srgb,
    };

    /// <summary>
    /// Usage from the binding slot's name, with format as corroboration for normal maps.
    /// </summary>
    /// <remarks>
    /// Matched on substrings rather than against a fixed slot list, for the same reason
    /// <c>MaterialReader</c> stopped keeping one: the shader classes name the same role differently
    /// (<c>AliveDiffuse</c>, <c>WaterDiffuseMap</c>, <c>FacingDiffuse</c>), and a list is a thing to
    /// go stale. Order matters — <c>SpecularMask</c> and <c>EmissiveMask</c> are masks first, and
    /// <c>NormalTextureAnimator</c>-style names are not slots and never reach here.
    /// </remarks>
    private static TextureUsage UsageOf(string? slot, BioShockTextureFormat format)
    {
        // 3Dc is a two-channel format this game uses for nothing but normal maps: all 273 exports
        // declaring it are normal maps (see BioShockTextureFormat.ThreeDc). That holds even when
        // no slot is known, so it is checked first.
        if (format == BioShockTextureFormat.ThreeDc) return TextureUsage.NormalMap;

        if (slot is not { Length: > 0 }) return TextureUsage.Unknown;

        if (Has(slot, "Cubemap")) return TextureUsage.Cubemap;
        if (Has(slot, "Normal")) return TextureUsage.NormalMap;
        if (Has(slot, "Height")) return TextureUsage.Height;

        // Mask before the colour roles it qualifies: SpecularMask is a mask, not a specular colour.
        if (Has(slot, "Mask") || Has(slot, "Opacity") || Has(slot, "Clip") || Has(slot, "Coverage"))
            return TextureUsage.Mask;

        if (Has(slot, "Specular") || Has(slot, "Gloss")) return TextureUsage.Specular;
        if (Has(slot, "Emissive") || Has(slot, "SelfIllumination")) return TextureUsage.Emissive;
        if (Has(slot, "Diffuse") || slot == Materials.MaterialReader.SelfSlot) return TextureUsage.BaseColor;

        return TextureUsage.Unknown;
    }

    private static bool Has(string slot, string token) =>
        slot.Contains(token, StringComparison.OrdinalIgnoreCase);
}
