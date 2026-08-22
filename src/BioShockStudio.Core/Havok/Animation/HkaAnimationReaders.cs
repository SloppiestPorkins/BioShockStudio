using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Animation;

/// <summary>
/// Reads <c>hkaAnimationBinding</c> (Havok 2012.2.0-r1, 4-byte pointers).
/// <para>
/// CONFIRMED_BYTES against the pistol section: <c>m_animation</c> is a cross-section pointer
/// resolved by a global fixup, and <c>m_transformTrackToBoneIndices</c> holds 47 entries, matching
/// the 47-bone hand skeleton exactly.
/// </para>
/// <code>
/// +0   hkReferencedObject
/// +8   const char*        m_originalSkeletonName
/// +12  hkaAnimation*      m_animation                      (global fixup)
/// +16  hkArray&lt;hkInt16&gt;   m_transformTrackToBoneIndices
/// +28  hkArray&lt;hkInt16&gt;   m_floatTrackToFloatSlotIndices
/// +40  hkArray&lt;hkInt16&gt;   m_partitionIndices
/// +52  hkInt8             m_blendHint
/// </code>
/// </summary>
public static class HkaAnimationBindingReader
{
    public const string ClassName = "hkaAnimationBinding";

    private const int SkeletonNameOffset = 8;
    private const int AnimationPointerOffset = 12;
    private const int TransformTrackMapOffset = 16;
    private const int FloatTrackMapOffset = 28;
    private const int PartitionIndicesOffset = 40;
    private const int BlendHintOffset = 52;

    /// <summary>
    /// The partitions this binding says the animation is sampled against, if any.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Havok's own words for <c>m_partitionIndices</c>: "(Optional) A list of the partitions used to
    /// sample the animation". A partition is a named contiguous bone range declared on the skeleton
    /// (<see cref="Skeleton.HkaSkeletonReader.ReadPartitions"/>).
    /// </para>
    /// <para>
    /// <b>Read and reported, not used.</b> The four fire animations in <c>docs/HANDOFF.md</c> §6.0c
    /// drive bones 3..56 of 73 — contiguous, ascending, a subset — which is the shape of a
    /// partial-body animation, and the field was documented in this file's own header comment and
    /// never read. Measuring it either opens a line of enquiry or eliminates one; it decides nothing
    /// on its own.
    /// </para>
    /// </remarks>
    public static short[] ReadPartitionIndices(HavokSection section, int objectOffset) =>
        ReadInt16Array(section, objectOffset + PartitionIndicesOffset);

    public static AnimationBinding Read(HavokSection section, int objectOffset) =>
        new()
        {
            OriginalSkeletonName = section.ReadStringPointer(objectOffset + SkeletonNameOffset) ?? string.Empty,
            TransformTrackToBoneIndex = ReadInt16Array(section, objectOffset + TransformTrackMapOffset),
            FloatTrackToFloatSlotIndex = ReadInt16Array(section, objectOffset + FloatTrackMapOffset),
            BlendHint = section.ReadByte(objectOffset + BlendHintOffset),
        };

    /// <summary>The animation this binding refers to, as a cross-section reference.</summary>
    public static GlobalFixup? GetAnimationReference(HavokSection section, int objectOffset) =>
        section.ResolveGlobalPointer(objectOffset + AnimationPointerOffset);

    private static short[] ReadInt16Array(HavokSection section, int arrayFieldOffset)
    {
        var array = section.ReadArray(arrayFieldOffset);
        if (array.IsEmpty) return [];

        var result = new short[array.Count];
        for (int i = 0; i < result.Length; i++)
            result[i] = section.ReadInt16(array.DataOffset!.Value + i * 2);
        return result;
    }
}

/// <summary>
/// Reads the <c>hkaAnimation</c> base fields and the <c>hkaSplineCompressedAnimation</c> header.
/// <para>
/// CONFIRMED_BYTES against <c>FireSinglePistol</c> and its siblings: <c>m_frameDuration</c> is
/// exactly 1/30 and <c>m_duration</c> equals <c>(numFrames - 1) * frameDuration</c>, which
/// cross-validates four independent fields at once.
/// </para>
/// <code>
/// hkaAnimation
/// +8   hkInt32   m_type
/// +12  hkReal    m_duration
/// +16  hkInt32   m_numberOfTransformTracks
/// +20  hkInt32   m_numberOfFloatTracks
/// +24  hkaAnimatedReferenceFrame* m_extractedMotion   (local or global fixup; see HasExtractedMotion)
/// +28  hkArray&lt;hkaAnnotationTrack&gt; m_annotationTracks
/// hkaSplineCompressedAnimation
/// +40  hkInt32   m_numFrames
/// +44  hkInt32   m_numBlocks
/// +48  hkInt32   m_maxFramesPerBlock
/// +52  hkInt32   m_maskAndQuantizationSize
/// +56  hkReal    m_blockDuration
/// +60  hkReal    m_blockInverseDuration
/// +64  hkReal    m_frameDuration
/// +68  hkArray&lt;hkUint32&gt; m_blockOffsets
/// +80  hkArray&lt;hkUint8&gt;  m_floatBlockOffsets
/// +92  hkArray&lt;hkUint8&gt;  m_transformOffsets
/// +104 hkArray&lt;hkUint8&gt;  m_floatOffsets
/// +116 hkArray&lt;hkUint8&gt;  m_data
/// +128 hkInt32   m_endian
/// </code>
/// </summary>
public static class HkaSplineCompressedAnimationReader
{
    public const string ClassName = "hkaSplineCompressedAnimation";

    public const int TypeOffset = 8;
    public const int DurationOffset = 12;
    public const int TransformTrackCountOffset = 16;
    public const int FloatTrackCountOffset = 20;
    public const int ExtractedMotionOffset = 24;
    public const int AnnotationTracksOffset = 28;
    public const int NumFramesOffset = 40;
    public const int NumBlocksOffset = 44;
    public const int MaxFramesPerBlockOffset = 48;
    public const int MaskAndQuantizationSizeOffset = 52;
    public const int BlockDurationOffset = 56;
    public const int BlockInverseDurationOffset = 60;
    public const int FrameDurationOffset = 64;
    public const int BlockOffsetsOffset = 68;
    public const int FloatBlockOffsetsOffset = 80;
    public const int TransformOffsetsOffset = 92;
    public const int FloatOffsetsOffset = 104;
    public const int DataOffset = 116;
    public const int EndianOffset = 128;

    public static SplineAnimationHeader Read(HavokSection section, int objectOffset)
    {
        var blockOffsets = section.ReadArray(objectOffset + BlockOffsetsOffset);
        var data = section.ReadArray(objectOffset + DataOffset);

        var blocks = new uint[blockOffsets.Count];
        for (int i = 0; i < blocks.Length; i++)
            blocks[i] = section.ReadUInt32(blockOffsets.DataOffset!.Value + i * 4);

        return new SplineAnimationHeader
        {
            AnimationType = section.ReadInt32(objectOffset + TypeOffset),
            Duration = section.ReadSingle(objectOffset + DurationOffset),
            TransformTrackCount = section.ReadInt32(objectOffset + TransformTrackCountOffset),
            FloatTrackCount = section.ReadInt32(objectOffset + FloatTrackCountOffset),
            HasExtractedMotion = section.ResolvePointer(objectOffset + ExtractedMotionOffset) is not null
                || section.ResolveGlobalPointer(objectOffset + ExtractedMotionOffset) is not null,
            AnnotationTrackCount = section.ReadArray(objectOffset + AnnotationTracksOffset).Count,
            NumFrames = section.ReadInt32(objectOffset + NumFramesOffset),
            NumBlocks = section.ReadInt32(objectOffset + NumBlocksOffset),
            MaxFramesPerBlock = section.ReadInt32(objectOffset + MaxFramesPerBlockOffset),
            MaskAndQuantizationSize = section.ReadInt32(objectOffset + MaskAndQuantizationSizeOffset),
            BlockDuration = section.ReadSingle(objectOffset + BlockDurationOffset),
            BlockInverseDuration = section.ReadSingle(objectOffset + BlockInverseDurationOffset),
            FrameDuration = section.ReadSingle(objectOffset + FrameDurationOffset),
            BlockOffsets = blocks,
            DataOffset = data.DataOffset,
            DataSize = data.Count,
            Endian = section.ReadInt32(objectOffset + EndianOffset),
        };
    }
}

/// <summary>Decoded <c>hkaSplineCompressedAnimation</c> header fields.</summary>
public sealed record SplineAnimationHeader
{
    public required int AnimationType { get; init; }
    public required float Duration { get; init; }
    public required int TransformTrackCount { get; init; }
    public required int FloatTrackCount { get; init; }

    /// <summary>
    /// Whether <c>m_extractedMotion</c> resolves to a real object (root motion) rather than null.
    /// Checked as both a within-section and a cross-section pointer, since Havok does not say which
    /// an <c>hkRefPtr</c> field will be and this project's own fixup tables are the ground truth.
    /// </summary>
    public required bool HasExtractedMotion { get; init; }

    public required int AnnotationTrackCount { get; init; }
    public required int NumFrames { get; init; }
    public required int NumBlocks { get; init; }
    public required int MaxFramesPerBlock { get; init; }
    public required int MaskAndQuantizationSize { get; init; }
    public required float BlockDuration { get; init; }
    public required float BlockInverseDuration { get; init; }
    public required float FrameDuration { get; init; }
    public required IReadOnlyList<uint> BlockOffsets { get; init; }

    /// <summary>Offset of the compressed track data within its section, if resolved.</summary>
    public required int? DataOffset { get; init; }

    public required int DataSize { get; init; }
    public required int Endian { get; init; }
}

/// <summary>
/// Resolves and reads an animation's <c>m_extractedMotion</c> field (Havok root motion), when
/// present. See <see cref="HkaSplineCompressedAnimationReader.HasExtractedMotion"/> for the
/// presence check alone.
/// <para>
/// <b>CONFIRMED_BYTES</b>, cross-validated on six of <c>AggressorBabyJane</c>'s animations: the
/// resolved object's class always names <c>hkaDefaultAnimatedReferenceFrame</c> (read from the
/// packfile's own virtual fixup table, not assumed); <c>m_referenceFrameSamples.Count</c> equals the
/// owning animation's own <c>NumFrames</c> exactly, every time; <c>m_duration</c> equals the
/// animation's own duration exactly, every time; <c>m_up</c>/<c>m_forward</c> decode to the class's
/// documented defaults, <c>(0,0,1)</c>/<c>(1,0,0)</c>, every time; and every sample curve's first
/// entry is the origin, matching "motion represents the absolute offset from the start of the
/// animation" in the SDK header. This is four independent cross-checks agreeing, not one lucky read.
/// </para>
/// <code>
/// hkaDefaultAnimatedReferenceFrame : hkaAnimatedReferenceFrame : hkReferencedObject
/// +0   hkReferencedObject                (vtable + refcount, zero on disk; m_frameType is +nosave
///                                          on the base class and is not written to the packfile)
/// +16  hkVector4          m_up           (padded from +8 to a 16-byte SIMD boundary)
/// +32  hkVector4          m_forward
/// +48  hkReal             m_duration
/// +52  hkArray&lt;hkVector4&gt; m_referenceFrameSamples
/// </code>
/// <para>
/// <b>CONFIRMED_EXTERNAL</b>, from the SDK's own field comment on <c>m_referenceFrameSamples</c>:
/// "we only need a translation and a rotational (w) component around the up direction" — X/Y/Z is a
/// 3D translation, W is yaw around <see cref="AnimatedReferenceFrame.Up"/>. <b>CONFIRMED_BYTES</b>
/// that both slots are actually live, not structurally dead: on three more skeleton families
/// (<c>GathererGirl</c>, both Big Daddy variants — 196 animations beyond the six checked above), Z
/// grows smoothly on `GathererGirl`'s vent-climb animations and W grows smoothly on all three,
/// ranging past ±π (an unwrapped "absolute offset from the start" angle, not a bug). Root motion's
/// units are the same centimetre-ish scale as this project's mesh/bone data, <b>not</b>
/// <see cref="BioShockStudio.Core.Havok.Physics.HkpCapsuleShapeReader"/>'s metre scale — two
/// different Havok subsystems, two different authored scales; see
/// <c>docs/research/root-motion.md</c> for the value ranges.
/// <b>PLAUSIBLE, not yet promoted</b>: which axis is "forward" vs "right" (X carries the largest
/// magnitude in most samples, the same axis <see cref="AnimatedReferenceFrame.Forward"/> defaults
/// to, which is suggestive but not cross-validated against an independent source). <b>Also open</b>:
/// the values have not been checked against this project's <c>C = diag(1,-1,1)</c> basis policy
/// (<c>docs/research/ANIMATION_COORDINATE_SYSTEM.md</c>) — do not apply them to an export without
/// checking that first. See <c>docs/research/root-motion.md</c> for the full record.
/// </para>
/// </summary>
public static class HkaDefaultAnimatedReferenceFrameReader
{
    public const string ClassName = "hkaDefaultAnimatedReferenceFrame";

    private const int UpOffset = 16;
    private const int ForwardOffset = 32;
    private const int DurationOffset = 48;
    private const int SamplesOffset = 52;

    /// <summary>
    /// Resolves <c>m_extractedMotion</c> at <paramref name="animationOffset"/> +
    /// <see cref="HkaSplineCompressedAnimationReader.ExtractedMotionOffset"/> to the section and
    /// offset it points at, or <c>null</c> if the pointer is unset (no root motion). Checks both a
    /// within-section and a cross-section fixup, since Havok's own headers do not say which an
    /// <c>hkRefPtr</c> will be.
    /// </summary>
    public static (HavokSection Section, int Offset)? ResolveTarget(
        HavokPackfile packfile, HavokSection section, int animationOffset)
    {
        int fieldOffset = animationOffset + HkaSplineCompressedAnimationReader.ExtractedMotionOffset;
        return packfile.ResolvePointerField(section, fieldOffset);
    }

    public static AnimatedReferenceFrame Read(HavokSection section, int objectOffset) => new()
    {
        Up = ReadVector4(section, objectOffset + UpOffset),
        Forward = ReadVector4(section, objectOffset + ForwardOffset),
        Duration = section.ReadSingle(objectOffset + DurationOffset),
        Samples = ReadSamples(section, objectOffset + SamplesOffset),
    };

    private static Vector4[] ReadSamples(HavokSection section, int arrayFieldOffset)
    {
        var array = section.ReadArray(arrayFieldOffset);
        if (array.IsEmpty) return [];

        var result = new Vector4[array.Count];
        for (int i = 0; i < result.Length; i++)
            result[i] = ReadVector4(section, array.DataOffset!.Value + i * 16);
        return result;
    }

    private static Vector4 ReadVector4(HavokSection section, int offset) => new(
        section.ReadSingle(offset), section.ReadSingle(offset + 4),
        section.ReadSingle(offset + 8), section.ReadSingle(offset + 12));
}

/// <summary>Decoded <c>hkaDefaultAnimatedReferenceFrame</c> — an animation's Havok root motion.</summary>
public sealed record AnimatedReferenceFrame
{
    public required Vector4 Up { get; init; }
    public required Vector4 Forward { get; init; }
    public required float Duration { get; init; }

    /// <summary>
    /// One raw sample per animation frame (count equals the owning animation's <c>NumFrames</c>,
    /// confirmed on every case checked). Component semantics are not yet promoted to a fact — see
    /// the reader's own doc comment.
    /// </summary>
    public required IReadOnlyList<Vector4> Samples { get; init; }
}
