using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Diagnostics;

/// <summary>What the audit concluded about one animation. Ordered worst to best deliberately.</summary>
public enum AnimationStatus
{
    /// <summary>The wrapper itself would not load, so its animations were never enumerated.</summary>
    PackageFailed,

    /// <summary>Enumerated, but decoding threw.</summary>
    Failed,

    /// <summary>A compression form this project does not implement. Not a fault, but not usable.</summary>
    Unsupported,

    /// <summary>Decoded, but something about it is not fit to play — see the reason.</summary>
    Partial,

    /// <summary>Decoded, fully bound, finite throughout, and previewable.</summary>
    Playable,
}

/// <summary>One audited animation.</summary>
public sealed record AnimationAuditRow
{
    public required string Package { get; init; }
    public required string Wrapper { get; init; }
    public required string Owner { get; init; }
    public required string Name { get; init; }
    public required AnimationStatus Status { get; init; }

    /// <summary>Why it is not <see cref="AnimationStatus.Playable"/>. Empty when it is.</summary>
    public required string Reason { get; init; }

    public required string Compression { get; init; }
    public required string SkeletonName { get; init; }
    public required int BoneCount { get; init; }
    public required int FrameCount { get; init; }
    public required float FrameRate { get; init; }
    public required int TrackCount { get; init; }

    /// <summary>Tracks Havok's binding maps onto a bone that exists on the skeleton.</summary>
    public required int BoundTrackCount { get; init; }

    public required int EventCount { get; init; }

    public bool IsExportable => Status is AnimationStatus.Playable or AnimationStatus.Partial;
}

/// <summary>The whole-game result.</summary>
public sealed record AnimationAuditReport
{
    public required IReadOnlyList<AnimationAuditRow> Rows { get; init; }

    /// <summary>Wrappers that could not be loaded at all, with the reason.</summary>
    public required IReadOnlyList<(string Package, string Wrapper, string Reason)> PackageFailures { get; init; }

    public required int PackageCount { get; init; }
    public required int WrapperCount { get; init; }
    public required int SkeletonCount { get; init; }

    public int Total => Rows.Count;
    public int Count(AnimationStatus status) => Rows.Count(r => r.Status == status);
    public int Playable => Count(AnimationStatus.Playable);
    public int Decoded => Rows.Count(r => r.IsExportable);
    public int WithEvents => Rows.Count(r => r.EventCount > 0);
    public int TotalEvents => Rows.Sum(r => r.EventCount);
    public int UnboundTracks => Rows.Sum(r => r.TrackCount - r.BoundTrackCount);
}

/// <summary>
/// Decodes every animation the game ships and reports what came out.
/// <para>
/// The point is coverage rather than spot checks: "some animations work" is not a result this
/// project accepts. Every check here is objective — a decode that threw, a track bound to a bone
/// that does not exist, a non-finite value — so nothing depends on whether a result *looks* right.
/// </para>
/// <para>
/// Nothing is silently dropped. An animation that cannot be decoded is still a row, carrying the
/// reason, and a wrapper that will not load at all is recorded in
/// <see cref="AnimationAuditReport.PackageFailures"/>.
/// </para>
/// </summary>
public static class AnimationAudit
{
    /// <summary>Runs the sweep. <paramref name="progress"/> is called once per package.</summary>
    public static AnimationAuditReport Run(string gameRoot, Action<string>? progress = null)
    {
        var rows = new List<AnimationAuditRow>();
        var packageFailures = new List<(string, string, string)>();
        var skeletons = new HashSet<string>(StringComparer.Ordinal);
        int packageCount = 0, wrapperCount = 0;

        foreach (string path in EnumerateAllPackages(gameRoot))
        {
            string packageName = Path.GetFileNameWithoutExtension(path);
            packageCount++;

            BioShockPackage package;
            try { package = BioShockPackage.Open(path); }
            catch (Exception ex)
            {
                packageFailures.Add((packageName, "(package)", ex.Message));
                continue;
            }

            using (package)
            {
                var wrappers = package.Exports
                    .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                    .ToList();

                // The metadata objects that carry the event tracks are package-wide, so index them
                // once rather than per wrapper.
                var metadata = new Dictionary<string, ObjectExport>(StringComparer.OrdinalIgnoreCase);
                foreach (var export in package.Exports)
                {
                    if (package.GetClassName(export) == AnimationMetadataReader.ClassName)
                        metadata[export.ObjectName] = export;
                }

                foreach (var export in wrappers)
                {
                    wrapperCount++;
                    try
                    {
                        var animationPackage = AnimationPackage.Load(package, export);
                        skeletons.Add($"{packageName}/{animationPackage.Skeleton.Name}");
                        rows.AddRange(AuditWrapper(package, packageName, animationPackage, metadata));
                    }
                    catch (Exception ex)
                    {
                        packageFailures.Add((packageName, export.ObjectName, ex.Message));
                    }
                }

                progress?.Invoke($"{packageName}: {wrappers.Count} wrappers, {rows.Count} animations so far");
            }
        }

        return new AnimationAuditReport
        {
            Rows = rows,
            PackageFailures = packageFailures,
            PackageCount = packageCount,
            WrapperCount = wrapperCount,
            SkeletonCount = skeletons.Count,
        };
    }

    private static IEnumerable<AnimationAuditRow> AuditWrapper(
        BioShockPackage package, string packageName, AnimationPackage animationPackage,
        IReadOnlyDictionary<string, ObjectExport> metadata)
    {
        int boneCount = animationPackage.Skeleton.BoneCount;
        string skeletonName = animationPackage.Skeleton.Name;

        int EventCount(string name, float duration)
        {
            if (!metadata.TryGetValue(AnimationMetadataReader.ObjectPrefix + name, out var export))
                return 0;
            try { return AnimationMetadataReader.ReadEvents(package, export, duration).Count; }
            catch { return 0; }
        }

        AnimationAuditRow Row(
            string owner, string name, AnimationStatus status, string reason, string compression,
            int frames, float rate, int tracks, int bound, float duration = 0f) => new()
        {
            Package = packageName,
            Wrapper = animationPackage.ObjectName,
            Owner = owner,
            Name = name,
            Status = status,
            Reason = reason,
            Compression = compression,
            SkeletonName = skeletonName,
            BoneCount = boneCount,
            FrameCount = frames,
            FrameRate = rate,
            TrackCount = tracks,
            BoundTrackCount = bound,
            EventCount = EventCount(name, duration),
        };

        // Animations the wrapper itself could not read. These already carry their reason.
        foreach (var failure in animationPackage.Failures)
        {
            yield return Row(failure.OwnerName, failure.AnimationName, AnimationStatus.Failed,
                failure.Reason, "unknown", 0, 0f, 0, 0);
        }

        foreach (var animation in animationPackage.Animations)
        {
            string compression = animation.Compression.ToString();

            if (animation.Compression != CompressionKind.Spline)
            {
                yield return Row(animation.Owner, animation.Name, AnimationStatus.Unsupported,
                    $"{animation.HavokClassName} is not implemented", compression,
                    animation.FrameCount, animation.FrameRate, animation.TransformTrackCount, 0,
                    animation.Duration);
                continue;
            }

            int bound = 0;
            for (int track = 0; track < animation.Binding.TrackCount; track++)
            {
                int bone = animation.Binding.BoneForTrack(track);
                if (bone >= 0 && bone < boneCount) bound++;
            }

            DecodedAnimation? decoded = null;
            string? decodeError = null;
            try
            {
                decoded = animationPackage.Decode(animation);
            }
            catch (Exception ex)
            {
                decodeError = ex.Message;
            }

            if (decoded is null)
            {
                yield return Row(animation.Owner, animation.Name, AnimationStatus.Failed,
                    decodeError ?? "decode returned nothing", compression, animation.FrameCount,
                    animation.FrameRate, animation.TransformTrackCount, bound, animation.Duration);
                continue;
            }

            string problem = WhyNotPlayable(decoded, animation, bound);

            yield return Row(animation.Owner, animation.Name,
                problem.Length == 0 ? AnimationStatus.Playable : AnimationStatus.Partial,
                problem, compression, decoded.FrameCount, animation.FrameRate,
                animation.Binding.TrackCount, bound, animation.Duration);
        }
    }

    /// <summary>
    /// What is wrong with a decoded animation, or empty if nothing is. Every condition here can only
    /// be true of a broken result — none of them is a judgement about how the motion looks.
    /// <para>
    /// Public because a sweep that reports 100% is worth nothing unless its checks can be shown to
    /// fire; <c>AnimationAuditTests</c> feeds it each kind of breakage directly.
    /// </para>
    /// </summary>
    public static string WhyNotPlayable(
        DecodedAnimation decoded, BioShockAnimation animation, int bound)
    {
        if (decoded.FrameCount <= 0) return "decoded to zero frames";
        if (decoded.Tracks.Count == 0) return "decoded to zero tracks";

        if (bound < animation.Binding.TrackCount)
            return $"{animation.Binding.TrackCount - bound} of {animation.Binding.TrackCount} tracks bind to no bone";

        foreach (var track in decoded.Tracks)
        {
            if (track.Translations.Length != decoded.FrameCount ||
                track.Rotations.Length != decoded.FrameCount ||
                track.Scales.Length != decoded.FrameCount)
            {
                return "a track is not sampled over every frame";
            }

            for (int frame = 0; frame < decoded.FrameCount; frame++)
            {
                if (!IsFinite(track.Translations[frame])) return "a translation key is not finite";
                if (!IsFinite(track.Scales[frame])) return "a scale key is not finite";

                var rotation = track.Rotations[frame];
                if (!float.IsFinite(rotation.X) || !float.IsFinite(rotation.Y) ||
                    !float.IsFinite(rotation.Z) || !float.IsFinite(rotation.W))
                {
                    return "a rotation key is not finite";
                }

                // A quaternion that is not unit length is not a rotation, and would shear the mesh.
                float length = rotation.Length();
                if (MathF.Abs(length - 1f) > 0.01f)
                    return $"a rotation key has length {length:0.###}";
            }
        }

        return string.Empty;
    }

    private static bool IsFinite(Vector3 v) =>
        float.IsFinite(v.X) && float.IsFinite(v.Y) && float.IsFinite(v.Z);

    /// <summary>Every shipped package that can hold animation: the maps and the script packages.</summary>
    private static IEnumerable<string> EnumerateAllPackages(string gameRoot)
    {
        foreach (string path in GameLocator.EnumeratePackages(gameRoot)) yield return path;
        foreach (string path in GameLocator.EnumerateScriptPackages(gameRoot)) yield return path;
    }
}
