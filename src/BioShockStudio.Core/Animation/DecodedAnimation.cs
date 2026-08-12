using System.Numerics;

namespace BioShockStudio.Core.Animation;

/// <summary>
/// One transform track sampled per frame.
/// <see cref="OriginalTrackIndex"/> is preserved so the binding stays authoritative.
/// </summary>
public sealed record DecodedTrack
{
    public required int OriginalTrackIndex { get; init; }
    public required Vector3[] Translations { get; init; }
    public required Quaternion[] Rotations { get; init; }
    public required Vector3[] Scales { get; init; }

    /// <summary>Bone this track drives, filled in when bound to a skeleton.</summary>
    public int TargetBoneIndex { get; set; } = -1;
}

/// <summary>
/// Track data decoded out of its compressed form and sampled at the animation's own frame rate.
/// <para>
/// This is the "sampled" representation. The compressed bytes it came from are still reachable
/// through the owning <see cref="BioShockAnimation"/> and its packfile, so nothing is destroyed by
/// decoding.
/// </para>
/// </summary>
public sealed record DecodedAnimation
{
    public required int FrameCount { get; init; }
    public required IReadOnlyList<DecodedTrack> Tracks { get; init; }
}

/// <summary>
/// The pose a track falls back to for channels it does not store: the bound bone's reference-pose
/// transform.
/// </summary>
public readonly record struct ReferenceTransform(Vector3 Translation, Quaternion Rotation, Vector3 Scale)
{
    public static ReferenceTransform Identity => new(Vector3.Zero, Quaternion.Identity, Vector3.One);
}
