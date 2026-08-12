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
    private const int BlendHintOffset = 52;

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
/// +24  hkaAnimatedReferenceFrame* m_extractedMotion
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
