namespace BioShockStudio.Core.Animation;

/// <summary>How an animation's track data is encoded.</summary>
public enum CompressionKind
{
    Unknown,
    Raw,
    Quantized,
    Spline,
}

/// <summary>
/// Maps animation transform tracks onto skeleton bones.
/// <para>
/// This is the binding subsystem the project treats as critical. The mapping comes from Havok's own
/// <c>m_transformTrackToBoneIndices</c> array — never from names, array position or filenames.
/// </para>
/// </summary>
public sealed record AnimationBinding
{
    /// <summary>Skeleton this animation was authored against, as recorded by Havok. May be empty.</summary>
    public required string OriginalSkeletonName { get; init; }

    /// <summary>
    /// Track index → original bone index. Element <c>i</c> is the bone that transform track
    /// <c>i</c> drives.
    /// </summary>
    public required IReadOnlyList<short> TransformTrackToBoneIndex { get; init; }

    public required IReadOnlyList<short> FloatTrackToFloatSlotIndex { get; init; }

    public required int BlendHint { get; init; }

    public int TrackCount => TransformTrackToBoneIndex.Count;

    /// <summary>The bone driven by a track, or -1 if the track is unbound.</summary>
    public int BoneForTrack(int trackIndex) =>
        trackIndex >= 0 && trackIndex < TransformTrackToBoneIndex.Count
            ? TransformTrackToBoneIndex[trackIndex]
            : -1;

    /// <summary>The track driving a bone, or -1 if the bone is not animated.</summary>
    public int TrackForBone(int boneIndex)
    {
        for (int i = 0; i < TransformTrackToBoneIndex.Count; i++)
            if (TransformTrackToBoneIndex[i] == boneIndex) return i;
        return -1;
    }
}

/// <summary>An animation as it exists in the game, before any decoding or resampling.</summary>
public sealed record BioShockAnimation
{
    /// <summary>Name from <c>AnimationPackageRoot</c>, e.g. <c>FireSinglePistol</c>.</summary>
    public required string Name { get; init; }

    /// <summary>Owner recorded alongside the name, e.g. <c>Pistol</c>, <c>Default</c>.</summary>
    public required string Owner { get; init; }

    public required float Duration { get; init; }
    public required int FrameCount { get; init; }

    /// <summary>Seconds per frame as authored. Preserved rather than assumed to be 1/30.</summary>
    public required float FrameDuration { get; init; }

    public required int TransformTrackCount { get; init; }
    public required int FloatTrackCount { get; init; }
    public required CompressionKind Compression { get; init; }

    /// <summary>Havok class the animation was stored as.</summary>
    public required string HavokClassName { get; init; }

    /// <summary>
    /// The raw <c>m_type</c> enum value. Recorded as observed rather than mapped through an enum
    /// table we have not verified for this Havok revision.
    /// </summary>
    public required int RawAnimationTypeValue { get; init; }

    public required AnimationBinding Binding { get; init; }

    /// <summary>Where this animation lives, for raw export and diagnostics.</summary>
    public required string SectionTag { get; init; }

    public required int SectionIndex { get; init; }
    public required int Offset { get; init; }

    /// <summary>Frames per second implied by <see cref="FrameDuration"/>.</summary>
    public float FrameRate => FrameDuration > 0f ? 1f / FrameDuration : 0f;

    public override string ToString() => $"{Name} ({Owner}, {Duration:0.###}s, {FrameCount} frames)";
}
