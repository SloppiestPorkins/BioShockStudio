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
/// <b>An omitted channel component is identity, not the bone's reference pose.</b>
/// <c>CONFIRMED_EXTERNAL</c> against Havok 2012.2.0-r1's own
/// <c>hkaSplineCompressedAnimation::recompose</c>:
/// </para>
/// <code>
/// int stat = mask &amp; 0x0F;                          // statically stored components
/// int iden = ~mask &amp; ( ~mask >> 4 ) &amp; 0x0F;         // neither static nor spline
/// if ( stat &amp; shift )      inOut(i) = S(i);        // S = static values
/// else if ( iden &amp; shift ) inOut(i) = I(i);        // I = "Identity values"
/// </code>
/// <para>
/// Identity is <c>0</c> for a translation, <c>1</c> for a scale and <c>(0,0,0,1)</c> for a rotation,
/// which is why Havok passes it as a parameter rather than hard-coding it. This reader used to fill
/// those components from the bound bone's reference pose instead, which is the same value for every
/// bone whose bind translation is axis-aligned along the stored component — so it agreed almost
/// everywhere and was wrong only where a bind translation had a second non-zero component. On the
/// first-person rig that is exactly <c>Bip01_L/R_UpperArm</c>: mask <c>0x01</c> stores X, and the
/// reference pose then injected the authoring pose's Y and Z into every animated frame, putting the
/// arm root 93 cm from the shoulder instead of 19 cm and throwing both arms across the body.
/// </para>
/// <para>
/// The evidence previously recorded for the reference-pose reading — that it "keeps 4,442 of 4,452
/// tracks at their rigid bone length, versus 4,160 when filling with zero" — is circular: filling a
/// component from the bind pose preserves the bind pose's bone length by construction. It measured
/// its own assumption.
/// </para>
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
    /// A component omitted from a channel that stores something falls back to identity, per Havok's
    /// <c>recompose</c>. <paramref name="referencePose"/> is used only for a channel that stores
    /// nothing at all, which Havok never reads. See the class remarks.
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

        // Consecutive blocks share a frame: the last frame a block covers is the first frame of the
        // next one, so a block of maxFramesPerBlock frames advances the animation by one less than
        // that. Advancing by the full count instead drifts the sample one frame further into the
        // curve per block — invisible in the first few, and by block nine it is sampling nine frames
        // early, which on Ryan's speech collapsed his chest into his legs.
        int framesPerBlock = Math.Max(1, maxFramesPerBlock - 1);

        TrackChannels[]? channels = null;
        int loadedBlock = -1;

        for (int frame = 0; frame < frameCount; frame++)
        {
            int blockIndex = frame / framesPerBlock;
            if (blockIndex >= blockOffsets.Count) blockIndex = blockOffsets.Count - 1;

            float localFrame = frame - blockIndex * (long)framesPerBlock;

            // Blocks are parsed once each rather than once per frame.
            if (blockIndex != loadedBlock)
            {
                int start = (int)blockOffsets[blockIndex];
                int end = blockIndex + 1 < blockOffsets.Count ? (int)blockOffsets[blockIndex + 1] : data.Length;
                channels = ReadBlock(data[start..end], transformTrackCount, referencePose);
                loadedBlock = blockIndex;
            }

            for (int t = 0; t < transformTrackCount; t++)
            {
                translations[t][frame] = SampleVector(channels![t].Translation, localFrame);
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

    /// <summary>How much of a block the parse actually consumed.</summary>
    /// <remarks>
    /// A block is padded to 16 bytes, so a correct walk ends within 15 bytes of the block's length.
    /// Ending anywhere else means the walk lost alignment inside a channel and every track after
    /// that point in the block is being read from the wrong offset — which produces confident,
    /// wrong animation rather than an error.
    /// </remarks>
    public readonly record struct BlockConsumption(int Index, int Length, int Consumed)
    {
        public int Slack => Length - Consumed;

        public bool LooksComplete => Slack is >= 0 and < 16;

        /// <summary>Largest knot value in the block, i.e. the last frame its splines describe.</summary>
        public int MaxKnot { get; init; }

        /// <summary>Largest control-point count of any channel in the block.</summary>
        public int MaxControlPoints { get; init; }

        public int SplineChannels { get; init; }
    }

    /// <summary>
    /// Walks each block and reports how much of it the parse consumed, for diagnosing a format
    /// variant without decoding a whole animation.
    /// </summary>
    public static IReadOnlyList<BlockConsumption> DescribeBlocks(
        ReadOnlySpan<byte> data,
        IReadOnlyList<uint> blockOffsets,
        int transformTrackCount,
        IReadOnlyList<ReferenceTransform> referencePose)
    {
        var result = new List<BlockConsumption>(blockOffsets.Count);

        for (int i = 0; i < blockOffsets.Count; i++)
        {
            int start = (int)blockOffsets[i];
            int end = i + 1 < blockOffsets.Count ? (int)blockOffsets[i + 1] : data.Length;
            var block = data[start..end];

            try
            {
                var channels = ReadBlock(block, transformTrackCount, referencePose, out int consumed);

                int maxKnot = 0, maxPoints = 0, splines = 0;
                foreach (var track in channels)
                {
                    foreach (var channel in new[] { track.Translation, track.Rotation, track.Scale })
                    {
                        if (channel.Basis is not { } basis) continue;
                        splines++;
                        maxKnot = Math.Max(maxKnot, basis.MaxKnot);
                        maxPoints = Math.Max(maxPoints, basis.ControlPointCount);
                    }
                }

                result.Add(new BlockConsumption(i, block.Length, consumed)
                {
                    MaxKnot = maxKnot,
                    MaxControlPoints = maxPoints,
                    SplineChannels = splines,
                });
            }
            catch (Exception ex) when (ex is ArgumentOutOfRangeException or IndexOutOfRangeException)
            {
                result.Add(new BlockConsumption(i, block.Length, -1));
            }
        }

        return result;
    }

    private readonly record struct TrackChannels(ChannelData Translation, ChannelData Rotation, ChannelData Scale);

    private static TrackChannels[] ReadBlock(
        ReadOnlySpan<byte> block, int trackCount, IReadOnlyList<ReferenceTransform> referencePose) =>
        ReadBlock(block, trackCount, referencePose, out _);

    private static TrackChannels[] ReadBlock(
        ReadOnlySpan<byte> block, int trackCount, IReadOnlyList<ReferenceTransform> referencePose, out int consumed)
    {
        var result = new TrackChannels[trackCount];
        int position = trackCount * TransformMask.Size;

        for (int t = 0; t < trackCount; t++)
        {
            var mask = TransformMask.Read(block.Slice(t * TransformMask.Size, TransformMask.Size));
            var reference = t < referencePose.Count ? referencePose[t] : ReferenceTransform.Identity;

            var translation = ReadVectorChannel(block, ref position, mask.Translation, mask.TranslationQuantization,
                Vector3.Zero, reference.Translation);
            var rotation = ReadRotationChannel(block, ref position, mask.Rotation, mask.RotationQuantization,
                reference.Rotation);
            var scale = ReadVectorChannel(block, ref position, mask.Scale, mask.ScaleQuantization,
                Vector3.One, reference.Scale);

            result[t] = new TrackChannels(translation, rotation, scale);
        }

        consumed = position;
        return result;
    }

    private static int Align(int value, int alignment) => (value + alignment - 1) / alignment * alignment;

    /// <param name="identity">
    /// Havok's identity for this channel — zero for a translation, one for a scale. It fills any
    /// component the channel does not store.
    /// </param>
    /// <param name="reference">
    /// The bound bone's reference pose, used ONLY when the channel stores nothing at all. Havok
    /// reaches <c>recompose</c> through <c>readNURBSCurve</c>, so a channel with no components is
    /// never read and the caller's existing value survives — and the caller's value, for a bone the
    /// animation is not driving in this respect, is the reference pose.
    /// </param>
    private static ChannelData ReadVectorChannel(
        ReadOnlySpan<byte> block, ref int position, TrackComponent mask, ScalarQuantization quantization,
        Vector3 identity, Vector3 reference)
    {
        var fallback = identity;

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

        // Nothing stored at all: the channel is never read, so the bone keeps its reference pose.
        return new ChannelData { StaticValue = reference, StaticRotation = Quaternion.Identity };
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

            // q and -q are the same rotation, and the packed form does not preserve which was
            // written, so neighbouring control points can arrive on opposite hemispheres. Blending
            // across such a pair takes the long way round.
            //
            // Aligning every point to the first one only works while the curve stays within a half
            // turn of where it started. Over a long spline it does not: Ryan's putter swings past
            // that, and one control point on the wrong side threw the club — and his arm with it —
            // a thousand units in a single frame. Each point is aligned to its predecessor instead,
            // so the chain stays continuous however far the curve travels.
            for (int i = 1; i < controlPointCount; i++)
            {
                if (Quaternion.Dot(points[i], points[i - 1]) < 0f) points[i] = -points[i];
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
        // slerps; matching that keeps playback identical to the game. The points were put on a
        // consistent hemisphere when the channel was read, so no sign fixing is needed here.
        var accumulated = new Quaternion(0f, 0f, 0f, 0f);

        foreach (var (index, weight) in channel.Basis!.Weights(t))
            accumulated += channel.RotationControlPoints[index] * weight;

        return accumulated.LengthSquared() > 1e-12f
            ? Quaternion.Normalize(accumulated)
            : channel.RotationControlPoints[0];
    }
}
