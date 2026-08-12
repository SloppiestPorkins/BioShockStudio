using System.Buffers.Binary;
using System.Numerics;
using BioShockStudio.Core.Animation;

namespace BioShockStudio.Core.Havok.Animation.SplineCompression;

/// <summary>One channel of one track within one block: either absent, constant, or spline-encoded.</summary>
internal sealed class ChannelData
{
    public required Vector3 StaticValue { get; init; }
    public required Quaternion StaticRotation { get; init; }
    public NurbsBasis? Basis { get; init; }

    /// <summary>Per-control-point values, when spline-encoded.</summary>
    public Vector3[]? VectorControlPoints { get; init; }

    public Quaternion[]? RotationControlPoints { get; init; }

    public bool IsSpline => Basis is not null;
}

/// <summary>
/// Decodes <c>hkaSplineCompressedAnimation</c> track data into per-frame transforms.
/// <para>
/// Block layout, all CONFIRMED_BYTES against the shipped first-person hands package:
/// </para>
/// <code>
/// TransformMask[numTransformTracks]        // 4 bytes each
/// per track, in order:
///   translation channel                    // vector channel
///   rotation channel                       // quaternion channel
///   scale channel                          // vector channel
///
/// vector channel, spline form:
///   uint16 numItems, uint8 degree, uint8 knots[numItems + degree + 2]
///   align to 4
///   per axis: float min, float max   (spline axis)  |  float value (static axis)
///   (numItems + 1) * splineAxisCount quantized values, interleaved per control point
///   align to 4
/// vector channel, static form:
///   float per statically stored axis, then align to 4
///
/// rotation channel, spline form:
///   uint16 numItems, uint8 degree, uint8 knots[numItems + degree + 2]   // no alignment
///   (numItems + 1) packed quaternions
///   align to 4
/// rotation channel, static form:
///   one packed quaternion, then align to 4
/// </code>
/// <para>
/// The alignment asymmetry is real: vector channels align after the knot vector because they are
/// followed by floats, rotation channels do not because packed quaternions are byte-aligned.
/// Walking all 132 blocks with these rules consumes each one exactly, modulo 16-byte block padding.
/// </para>
/// </summary>
public static class SplineDecompressor
{
    /// <summary>
    /// Decodes every transform track of an animation into per-frame transforms.
    /// <para>
    /// <paramref name="referencePose"/> supplies the fallback for channels a track does not store.
    /// CONFIRMED_BYTES that this fallback is the skeleton's reference pose and not identity: across
    /// all 130 animations, 4,452 tracks omit at least one translation component, and filling from
    /// the reference pose keeps 4,442 of them at their rigid bone length, versus 4,160 when filling
    /// with zero. Filling with zero visibly detaches limbs whose parent offset is not axis-aligned.
    /// </para>
    /// </summary>
    public static DecodedAnimation Decode(
        ReadOnlySpan<byte> data,
        IReadOnlyList<uint> blockOffsets,
        int transformTrackCount,
        int frameCount,
        int maxFramesPerBlock,
        IReadOnlyList<ReferenceTransform> referencePose)
    {
        var translations = new Vector3[transformTrackCount][];
        var rotations = new Quaternion[transformTrackCount][];
        var scales = new Vector3[transformTrackCount][];
        for (int t = 0; t < transformTrackCount; t++)
        {
            translations[t] = new Vector3[frameCount];
            rotations[t] = new Quaternion[frameCount];
            scales[t] = new Vector3[frameCount];
        }

        for (int frame = 0; frame < frameCount; frame++)
        {
            int blockIndex = maxFramesPerBlock > 0 ? frame / maxFramesPerBlock : 0;
            if (blockIndex >= blockOffsets.Count) blockIndex = blockOffsets.Count - 1;

            float localFrame = frame - blockIndex * (long)maxFramesPerBlock;

            int start = (int)blockOffsets[blockIndex];
            int end = blockIndex + 1 < blockOffsets.Count ? (int)blockOffsets[blockIndex + 1] : data.Length;
            var block = data[start..end];

            var channels = ReadBlock(block, transformTrackCount, referencePose);

            for (int t = 0; t < transformTrackCount; t++)
            {
                translations[t][frame] = SampleVector(channels[t].Translation, localFrame);
                rotations[t][frame] = SampleRotation(channels[t].Rotation, localFrame);
                scales[t][frame] = SampleVector(channels[t].Scale, localFrame);
            }
        }

        var tracks = new DecodedTrack[transformTrackCount];
        for (int t = 0; t < transformTrackCount; t++)
        {
            tracks[t] = new DecodedTrack
            {
                OriginalTrackIndex = t,
                Translations = translations[t],
                Rotations = rotations[t],
                Scales = scales[t],
            };
        }

        return new DecodedAnimation { FrameCount = frameCount, Tracks = tracks };
    }

    private readonly record struct TrackChannels(ChannelData Translation, ChannelData Rotation, ChannelData Scale);

    private static TrackChannels[] ReadBlock(
        ReadOnlySpan<byte> block, int trackCount, IReadOnlyList<ReferenceTransform> referencePose)
    {
        var result = new TrackChannels[trackCount];
        int position = trackCount * TransformMask.Size;

        for (int t = 0; t < trackCount; t++)
        {
            var mask = TransformMask.Read(block.Slice(t * TransformMask.Size, TransformMask.Size));
            var fallback = t < referencePose.Count ? referencePose[t] : ReferenceTransform.Identity;

            var translation = ReadVectorChannel(block, ref position, mask.Translation, mask.TranslationQuantization, fallback.Translation);
            var rotation = ReadRotationChannel(block, ref position, mask.Rotation, mask.RotationQuantization, fallback.Rotation);
            var scale = ReadVectorChannel(block, ref position, mask.Scale, mask.ScaleQuantization, fallback.Scale);

            result[t] = new TrackChannels(translation, rotation, scale);
        }

        return result;
    }

    private static int Align(int value, int alignment) => (value + alignment - 1) / alignment * alignment;

    private static ChannelData ReadVectorChannel(
        ReadOnlySpan<byte> block, ref int position, TrackComponent mask, ScalarQuantization quantization, Vector3 fallback)
    {
        if ((mask & TrackComponent.SplineMask) != 0)
        {
            int numItems = BinaryPrimitives.ReadUInt16LittleEndian(block[position..]);
            int degree = block[position + 2];
            var knots = block.Slice(position + 3, NurbsBasis.KnotCount(numItems, degree)).ToArray();
            position = Align(position + 3 + knots.Length, 4);

            Span<float> min = stackalloc float[3];
            Span<float> max = stackalloc float[3];
            Span<bool> isSpline = stackalloc bool[3];
            var staticValue = fallback;

            for (int axis = 0; axis < 3; axis++)
            {
                if ((mask & (TrackComponent)(0x10 << axis)) != 0)
                {
                    isSpline[axis] = true;
                    min[axis] = BinaryPrimitives.ReadSingleLittleEndian(block[position..]);
                    max[axis] = BinaryPrimitives.ReadSingleLittleEndian(block[(position + 4)..]);
                    position += 8;
                }
                else if ((mask & (TrackComponent)(1 << axis)) != 0)
                {
                    SetAxis(ref staticValue, axis, BinaryPrimitives.ReadSingleLittleEndian(block[position..]));
                    position += 4;
                }
            }

            int controlPointCount = numItems + 1;
            int width = Quantization.ByteSize(quantization);
            var points = new Vector3[controlPointCount];

            for (int i = 0; i < controlPointCount; i++)
            {
                var point = staticValue;
                for (int axis = 0; axis < 3; axis++)
                {
                    if (!isSpline[axis]) continue;
                    uint raw = ReadQuantized(block, position, width);
                    position += width;
                    SetAxis(ref point, axis, Quantization.Dequantize(raw, quantization, min[axis], max[axis]));
                }
                points[i] = point;
            }

            position = Align(position, 4);

            return new ChannelData
            {
                StaticValue = staticValue,
                StaticRotation = Quaternion.Identity,
                Basis = new NurbsBasis(numItems, degree, knots),
                VectorControlPoints = points,
            };
        }

        if ((mask & TrackComponent.StaticMask) != 0)
        {
            var value = fallback;
            for (int axis = 0; axis < 3; axis++)
            {
                if ((mask & (TrackComponent)(1 << axis)) == 0) continue;
                SetAxis(ref value, axis, BinaryPrimitives.ReadSingleLittleEndian(block[position..]));
                position += 4;
            }
            position = Align(position, 4);
            return new ChannelData { StaticValue = value, StaticRotation = Quaternion.Identity };
        }

        return new ChannelData { StaticValue = fallback, StaticRotation = Quaternion.Identity };
    }

    private static ChannelData ReadRotationChannel(
        ReadOnlySpan<byte> block, ref int position, TrackComponent mask, RotationQuantization quantization,
        Quaternion fallback)
    {
        int width = Quantization.ByteSize(quantization);

        if ((mask & TrackComponent.SplineMask) != 0)
        {
            int numItems = BinaryPrimitives.ReadUInt16LittleEndian(block[position..]);
            int degree = block[position + 2];
            var knots = block.Slice(position + 3, NurbsBasis.KnotCount(numItems, degree)).ToArray();

            // No alignment here: packed quaternions follow the knots immediately.
            position += 3 + knots.Length;

            int controlPointCount = numItems + 1;
            var points = new Quaternion[controlPointCount];
            for (int i = 0; i < controlPointCount; i++)
            {
                points[i] = DecodeRotation(block.Slice(position, width), quantization);
                position += width;
            }

            position = Align(position, 4);

            return new ChannelData
            {
                StaticValue = Vector3.Zero,
                StaticRotation = fallback,
                Basis = new NurbsBasis(numItems, degree, knots),
                RotationControlPoints = points,
            };
        }

        if ((mask & TrackComponent.StaticMask) != 0)
        {
            var rotation = DecodeRotation(block.Slice(position, width), quantization);
            position = Align(position + width, 4);
            return new ChannelData { StaticValue = Vector3.Zero, StaticRotation = rotation };
        }

        return new ChannelData { StaticValue = Vector3.Zero, StaticRotation = fallback };
    }

    private static Quaternion DecodeRotation(ReadOnlySpan<byte> data, RotationQuantization quantization) =>
        quantization switch
        {
            RotationQuantization.ThreeComp40 => Quantization.DecodeThreeComp40(data),
            _ => throw new NotSupportedException(
                $"Rotation quantization {quantization} has not been observed in BioShock data and is not decoded."),
        };

    private static uint ReadQuantized(ReadOnlySpan<byte> block, int position, int width) => width switch
    {
        1 => block[position],
        2 => BinaryPrimitives.ReadUInt16LittleEndian(block[position..]),
        4 => BinaryPrimitives.ReadUInt32LittleEndian(block[position..]),
        _ => throw new NotSupportedException($"Unsupported quantized width {width}."),
    };

    private static void SetAxis(ref Vector3 vector, int axis, float value)
    {
        switch (axis)
        {
            case 0: vector.X = value; break;
            case 1: vector.Y = value; break;
            default: vector.Z = value; break;
        }
    }

    private static Vector3 SampleVector(ChannelData channel, float t)
    {
        if (!channel.IsSpline || channel.VectorControlPoints is null) return channel.StaticValue;

        var accumulated = Vector3.Zero;
        foreach (var (index, weight) in channel.Basis!.Weights(t))
            accumulated += channel.VectorControlPoints[index] * weight;
        return accumulated;
    }

    private static Quaternion SampleRotation(ChannelData channel, float t)
    {
        if (!channel.IsSpline || channel.RotationControlPoints is null) return channel.StaticRotation;

        // Havok blends the control points directly and renormalises rather than doing a chain of
        // slerps; matching that keeps playback identical to the game.
        var accumulated = new Quaternion(0f, 0f, 0f, 0f);
        var reference = channel.RotationControlPoints[0];

        foreach (var (index, weight) in channel.Basis!.Weights(t))
        {
            var point = channel.RotationControlPoints[index];
            // Keep control points on the same hemisphere before blending.
            if (Quaternion.Dot(point, reference) < 0f) point = -point;
            accumulated += point * weight;
        }

        return accumulated.LengthSquared() > 1e-12f ? Quaternion.Normalize(accumulated) : reference;
    }
}
