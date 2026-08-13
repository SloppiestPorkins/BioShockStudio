using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Havok.Animation;
using BioShockStudio.Core.Havok.Animation.SplineCompression;
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

    /// <summary>
    /// Largest number of bytes any of the animation's blocks left unread, or -1 if a block threw.
    /// <para>
    /// A block is padded to 16 bytes, so a correct walk ends within 15 bytes of its length. More
    /// slack than that means the walk lost alignment inside a channel, and every track after that
    /// point in the block is being read from the wrong offset — which yields confident, wrong
    /// rotations rather than an error. This is the check that distinguishes "decoded" from
    /// "decoded correctly".
    /// </para>
    /// </summary>
    public int WorstBlockSlack { get; init; }

    /// <summary>Whether every block's walk ended where a complete one would.</summary>
    public bool BlocksLookComplete { get; init; }

    /// <summary>
    /// Largest distance any bone travels between two consecutive frames, in centimetres.
    /// <para>
    /// Animation is continuous; a bone that jumps a long way in one frame is a decode fault, not a
    /// performance. Reported rather than judged, because a genuinely snappy animation can be large
    /// and only the distribution says where the line is.
    /// </para>
    /// </summary>
    public float WorstFrameStep { get; init; }

    public string WorstFrameStepBone { get; init; } = string.Empty;
    public int WorstFrameStepFrame { get; init; }

    /// <summary>The same jump as a multiple of the animation's own mean step — a scale-free measure.</summary>
    public float WorstFrameStepRatio { get; init; }

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

    /// <summary>Animations whose block walk did not consume the block.</summary>
    public int IncompleteBlocks => Rows.Count(r => !r.BlocksLookComplete);

    /// <summary>Animations carrying a bone jump of at least <paramref name="centimetres"/> in one frame.</summary>
    public int Discontinuous(float centimetres) => Rows.Count(r => r.WorstFrameStep >= centimetres);
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

            var (slack, complete) = BlockWalk(animationPackage, animation);
            var jump = WorstJump(animationPackage.Skeleton, decoded);

            yield return Row(animation.Owner, animation.Name,
                problem.Length == 0 ? AnimationStatus.Playable : AnimationStatus.Partial,
                problem, compression, decoded.FrameCount, animation.FrameRate,
                animation.Binding.TrackCount, bound, animation.Duration) with
            {
                WorstBlockSlack = slack,
                BlocksLookComplete = complete,
                WorstFrameStep = jump.Distance,
                WorstFrameStepBone = jump.Bone,
                WorstFrameStepFrame = jump.Frame,
                WorstFrameStepRatio = jump.Ratio,
            };
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

    /// <summary>
    /// Walks the animation's blocks and reports the worst slack. See
    /// <see cref="AnimationAuditRow.WorstBlockSlack"/> for why this is the check that separates
    /// "decoded" from "decoded correctly".
    /// </summary>
    private static (int Slack, bool Complete) BlockWalk(AnimationPackage package, BioShockAnimation animation)
    {
        try
        {
            var section = package.Packfile.ResolvedSections[animation.SectionIndex];
            var header = HkaSplineCompressedAnimationReader.Read(section, animation.Offset);
            if (header.DataOffset is null) return (-1, false);

            var data = section.Data.Span.Slice(header.DataOffset.Value, header.DataSize);

            // The walk must see the same reference-pose fallback the real decode does, or it will
            // consume a different number of bytes than the decode did and measure nothing.
            var referencePose = new ReferenceTransform[header.TransformTrackCount];
            for (int track = 0; track < referencePose.Length; track++)
            {
                int bone = animation.Binding.BoneForTrack(track);
                referencePose[track] = bone >= 0 && bone < package.Skeleton.BoneCount
                    ? Coordinates.GameBasis.ToGameBasis(new ReferenceTransform(
                        package.Skeleton.Bones[bone].LocalTranslation,
                        package.Skeleton.Bones[bone].LocalRotation,
                        package.Skeleton.Bones[bone].LocalScale))
                    : ReferenceTransform.Identity;
            }

            var blocks = SplineDecompressor.DescribeBlocks(
                data, header.BlockOffsets, header.TransformTrackCount, referencePose);

            int worst = 0;
            bool complete = true;
            foreach (var block in blocks)
            {
                if (!block.LooksComplete) complete = false;
                if (block.Consumed < 0) return (-1, false);
                if (block.Slack > worst) worst = block.Slack;
            }

            return (worst, complete);
        }
        catch
        {
            return (-1, false);
        }
    }

    /// <summary>
    /// The largest distance any bone moves between consecutive frames, with the mean step alongside
    /// it so the jump can be read as a ratio rather than an absolute the scale of the rig decides.
    /// </summary>
    private static (float Distance, string Bone, int Frame, float Ratio) WorstJump(
        Skeleton.BioShockSkeleton skeleton, DecodedAnimation animation)
    {
        int boneCount = skeleton.BoneCount;
        if (boneCount == 0 || animation.FrameCount < 2) return (0f, string.Empty, 0, 0f);

        var byBone = new DecodedTrack?[boneCount];
        foreach (var track in animation.Tracks)
            if (track.TargetBoneIndex >= 0 && track.TargetBoneIndex < boneCount)
                byBone[track.TargetBoneIndex] = track;

        var previous = new Vector3[boneCount];
        var current = new Vector3[boneCount];
        var globals = new Matrix4x4[boneCount];

        float worst = 0f, total = 0f;
        int steps = 0, worstBone = -1, worstFrame = 0;

        for (int frame = 0; frame < animation.FrameCount; frame++)
        {
            for (int b = 0; b < boneCount; b++)
            {
                var bone = skeleton.Bones[b];
                var track = byBone[b];

                var translation = track is not null && frame < track.Translations.Length
                    ? track.Translations[frame] : bone.LocalTranslation;
                var rotation = track is not null && frame < track.Rotations.Length
                    ? track.Rotations[frame] : bone.LocalRotation;
                var scale = track is not null && frame < track.Scales.Length
                    ? track.Scales[frame] : bone.LocalScale;

                var local = Matrix4x4.CreateScale(scale)
                            * Matrix4x4.CreateFromQuaternion(rotation)
                            * Matrix4x4.CreateTranslation(translation);

                // Havok stores skeletons parent-first, so one forward pass composes the chain.
                globals[b] = bone.ParentIndex >= 0 && bone.ParentIndex < b
                    ? local * globals[bone.ParentIndex]
                    : local;

                current[b] = globals[b].Translation;
            }

            if (frame > 0)
            {
                for (int b = 0; b < boneCount; b++)
                {
                    float distance = Vector3.Distance(current[b], previous[b]);
                    total += distance;
                    steps++;
                    if (distance > worst) (worst, worstBone, worstFrame) = (distance, b, frame);
                }
            }

            (previous, current) = (current, previous);
        }

        float mean = steps > 0 ? total / steps : 0f;
        return (worst,
                worstBone >= 0 ? skeleton.Bones[worstBone].Name : string.Empty,
                worstFrame,
                mean > 1e-6f ? worst / mean : 0f);
    }

    /// <summary>Every shipped package that can hold animation: the maps and the script packages.</summary>
    private static IEnumerable<string> EnumerateAllPackages(string gameRoot)
    {
        foreach (string path in GameLocator.EnumeratePackages(gameRoot)) yield return path;
        foreach (string path in GameLocator.EnumerateScriptPackages(gameRoot)) yield return path;
    }
}
