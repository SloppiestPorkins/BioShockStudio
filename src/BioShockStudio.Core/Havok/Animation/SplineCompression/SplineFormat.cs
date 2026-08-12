using System.Numerics;

namespace BioShockStudio.Core.Havok.Animation.SplineCompression;

/// <summary>
/// Per-channel mask bits. The low nibble marks statically stored components, the high nibble marks
/// spline-encoded ones.
/// </summary>
[Flags]
public enum TrackComponent : byte
{
    None = 0,
    StaticX = 0x01,
    StaticY = 0x02,
    StaticZ = 0x04,
    StaticW = 0x08,
    SplineX = 0x10,
    SplineY = 0x20,
    SplineZ = 0x40,
    SplineW = 0x80,

    StaticMask = 0x0F,
    SplineMask = 0xF0,
}

/// <summary>
/// One transform track's mask: 4 bytes of quantization selectors and per-channel component flags.
/// CONFIRMED_BYTES: <see cref="QuantizationTypes"/> is <c>0x45</c> for every track in the
/// first-person hands package.
/// </summary>
public readonly record struct TransformMask(
    byte QuantizationTypes,
    TrackComponent Translation,
    TrackComponent Rotation,
    TrackComponent Scale)
{
    public const int Size = 4;

    /// <summary>Bits 0-1 select the scalar quantization used for spline translation control points.</summary>
    public ScalarQuantization TranslationQuantization => (ScalarQuantization)(QuantizationTypes & 0x03);

    /// <summary>Bits 2-5 select the rotation quantization.</summary>
    public RotationQuantization RotationQuantization => (RotationQuantization)((QuantizationTypes >> 2) & 0x0F);

    /// <summary>Bits 6-7 select the scalar quantization used for spline scale control points.</summary>
    public ScalarQuantization ScaleQuantization => (ScalarQuantization)((QuantizationTypes >> 6) & 0x03);

    public static TransformMask Read(ReadOnlySpan<byte> data) =>
        new(data[0], (TrackComponent)data[1], (TrackComponent)data[2], (TrackComponent)data[3]);
}

/// <summary>Scalar quantization widths, in bytes per value.</summary>
public enum ScalarQuantization
{
    Bits8 = 0,
    Bits16 = 1,
    Bits32 = 2,
    Bits40 = 3,
}

/// <summary>Rotation quantization selectors.</summary>
public enum RotationQuantization
{
    Polar32 = 0,
    ThreeComp40 = 1,
    ThreeComp48 = 2,
    ThreeComp24 = 3,
    Straight16 = 4,
    Uncompressed = 5,
}

/// <summary>Quantized value decoding.</summary>
public static class Quantization
{
    public static int ByteSize(ScalarQuantization quantization) => quantization switch
    {
        ScalarQuantization.Bits8 => 1,
        ScalarQuantization.Bits16 => 2,
        ScalarQuantization.Bits32 => 4,
        ScalarQuantization.Bits40 => 5,
        _ => throw new NotSupportedException($"Unsupported scalar quantization {quantization}."),
    };

    public static int ByteSize(RotationQuantization quantization) => quantization switch
    {
        RotationQuantization.Polar32 => 4,
        RotationQuantization.ThreeComp40 => 5,
        RotationQuantization.ThreeComp48 => 6,
        RotationQuantization.ThreeComp24 => 3,
        RotationQuantization.Straight16 => 2,
        RotationQuantization.Uncompressed => 16,
        _ => throw new NotSupportedException($"Unsupported rotation quantization {quantization}."),
    };

    /// <summary>Expands a quantized scalar back into its stored [min, max] range.</summary>
    public static float Dequantize(uint raw, ScalarQuantization quantization, float min, float max)
    {
        float scale = quantization switch
        {
            ScalarQuantization.Bits8 => raw / (float)byte.MaxValue,
            ScalarQuantization.Bits16 => raw / (float)ushort.MaxValue,
            ScalarQuantization.Bits32 => raw / (float)uint.MaxValue,
            _ => throw new NotSupportedException($"Unsupported scalar quantization {quantization}."),
        };
        return min + (max - min) * scale;
    }

    /// <summary>
    /// Decodes a 40-bit three-component quaternion.
    /// <para>
    /// Layout, derived from shipped bytes: three 12-bit components at bits 0/12/24, the index of the
    /// omitted (largest) component at bits 36-37, and a sign flag at bit 38. Components span
    /// ±1/√2, and the omitted one is recovered from the unit-length constraint.
    /// </para>
    /// <para>
    /// The bit positions are CONFIRMED_BYTES: decoding 67,528 shipped control points this way yields
    /// unit quaternions, and consecutive control points within a track differ by a mean of 0.0016,
    /// i.e. the tracks come out continuous. Alternative bit assignments produce discontinuous
    /// tracks. The exact rounding of the 12-bit midpoint (2047 vs 2048 vs 2047.5) cannot be
    /// distinguished by that test; the symmetric midpoint is used, and the resulting error is below
    /// 0.0005.
    /// </para>
    /// </summary>
    public static Quaternion DecodeThreeComp40(ReadOnlySpan<byte> data)
    {
        ulong value = 0;
        for (int i = 0; i < 5; i++) value |= (ulong)data[i] << (8 * i);

        const int mask = (1 << 12) - 1;
        const float midpoint = 2047.5f;
        const float range = 0.70710678f;

        Span<float> components = stackalloc float[3];
        for (int i = 0; i < 3; i++)
        {
            int raw = (int)((value >> (12 * i)) & mask);
            components[i] = (raw - midpoint) / midpoint * range;
        }

        int omitted = (int)((value >> 36) & 0x03);
        bool negate = ((value >> 38) & 0x01) != 0;

        float sumOfSquares = components[0] * components[0]
                             + components[1] * components[1]
                             + components[2] * components[2];
        float largest = MathF.Sqrt(MathF.Max(0f, 1f - sumOfSquares));
        if (negate) largest = -largest;

        Span<float> q = stackalloc float[4];
        for (int i = 0, source = 0; i < 4; i++)
            q[i] = i == omitted ? largest : components[source++];

        return Quaternion.Normalize(new Quaternion(q[0], q[1], q[2], q[3]));
    }
}
