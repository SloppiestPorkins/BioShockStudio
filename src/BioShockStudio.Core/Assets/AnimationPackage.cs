using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Havok.Animation;
using BioShockStudio.Core.Havok.Animation.SplineCompression;
using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Havok.Skeleton;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;

namespace BioShockStudio.Core.Assets;

/// <summary>An animation that could not be decoded, kept so nothing is silently dropped.</summary>
public sealed record AnimationFailure
{
    public required string AnimationName { get; init; }
    public required string OwnerName { get; init; }
    public required string SectionTag { get; init; }
    public required int Offset { get; init; }
    public required string Reason { get; init; }

    public override string ToString() => $"{OwnerName}/{AnimationName} @{SectionTag}+{Offset}: {Reason}";
}

/// <summary>
/// A decoded <c>AnimationPackageWrapper</c>: the skeleton plus every named animation, with each
/// animation bound to the skeleton by Havok's own track-to-bone mapping.
/// </summary>
public sealed class AnimationPackage
{
    public required string ObjectName { get; init; }
    public required string PackageName { get; init; }
    public required BioShockSkeleton Skeleton { get; init; }
    public required IReadOnlyList<BioShockAnimation> Animations { get; init; }

    /// <summary>Animations that failed to decode, with the reason. Never silently discarded.</summary>
    public required IReadOnlyList<AnimationFailure> Failures { get; init; }

    /// <summary>Byte offset of the Havok packfile within the export payload.</summary>
    public required int HavokOffset { get; init; }

    /// <summary>The raw export payload, preserved for lossless research export.</summary>
    public required ReadOnlyMemory<byte> RawPayload { get; init; }

    /// <summary>Distinct owners, e.g. <c>Pistol</c>, <c>Shotgun</c>, <c>Default</c>.</summary>
    public IEnumerable<string> Owners => Animations.Select(a => a.Owner).Distinct().Order();

    public IEnumerable<BioShockAnimation> ForOwner(string owner) =>
        Animations.Where(a => string.Equals(a.Owner, owner, StringComparison.OrdinalIgnoreCase));

    public BioShockAnimation? Find(string animationName) =>
        Animations.FirstOrDefault(a => string.Equals(a.Name, animationName, StringComparison.OrdinalIgnoreCase));

    /// <summary>Havok packfile, kept so animations can be decoded on demand.</summary>
    public required HavokPackfile Packfile { get; init; }

    /// <summary>
    /// Decodes an animation's compressed track data and binds each track to its skeleton bone.
    /// </summary>
    public DecodedAnimation Decode(BioShockAnimation animation)
    {
        if (animation.Compression != CompressionKind.Spline)
            throw new NotSupportedException($"'{animation.Name}' uses {animation.Compression} compression.");

        var section = Packfile.ResolvedSections[animation.SectionIndex];
        var header = HkaSplineCompressedAnimationReader.Read(section, animation.Offset);

        if (header.DataOffset is null)
            throw new InvalidDataException($"'{animation.Name}' has no track data.");

        var data = section.Data.Span.Slice(header.DataOffset.Value, header.DataSize);

        // Channels a track omits fall back to the bound bone's reference pose, so the binding has to
        // be applied before decoding rather than after.
        var referencePose = new ReferenceTransform[header.TransformTrackCount];
        for (int track = 0; track < referencePose.Length; track++)
        {
            int bone = animation.Binding.BoneForTrack(track);
            // The skeleton is already in the studio's basis, but the spline data about to be decoded
            // is not, and the two are interleaved channel by channel. So the fallback goes back to
            // the game's basis here and the whole decoded result is converted once, below.
            referencePose[track] = bone >= 0 && bone < Skeleton.BoneCount
                ? GameBasis.ToGameBasis(new ReferenceTransform(
                    Skeleton.Bones[bone].LocalTranslation,
                    Skeleton.Bones[bone].LocalRotation,
                    Skeleton.Bones[bone].LocalScale))
                : ReferenceTransform.Identity;
        }

        var decoded = SplineDecompressor.Decode(
            data, header.BlockOffsets, header.TransformTrackCount, header.NumFrames,
            header.MaxFramesPerBlock, referencePose);

        // Carry Havok's own track-to-bone mapping onto the decoded tracks.
        foreach (var track in decoded.Tracks)
            track.TargetBoneIndex = animation.Binding.BoneForTrack(track.OriginalTrackIndex);

        // One conversion, over the whole animation, into the same basis the skeleton is already in.
        // There is deliberately no animation-specific adjustment here. See Coordinates/GameBasis.
        return GameBasis.Convert(decoded);
    }

    /// <summary>Loads an <c>AnimationPackageWrapper</c> export.</summary>
    public static AnimationPackage Load(BioShockPackage package, ObjectExport export)
    {
        byte[] payload = package.ReadExportData(export);

        var location = HavokDetector.FindFirst(payload)
            ?? throw new InvalidDataException(
                $"'{export.ObjectName}' contains no Havok packfile.");

        var packfile = HavokPackfile.Parse(payload, location.Offset);

        var rootObject = packfile.EnumerateObjects()
            .FirstOrDefault(o => o.ClassName == AnimationPackageRootReader.ClassName)
            ?? throw new InvalidDataException(
                $"'{export.ObjectName}' has no {AnimationPackageRootReader.ClassName}.");

        var rootSection = packfile.ResolvedSections[rootObject.SectionIndex];
        var root = AnimationPackageRootReader.Read(rootSection, rootObject.Offset);

        if (root.Skeleton is null)
            throw new InvalidDataException($"'{export.ObjectName}' root has no skeleton reference.");

        var skeleton = HkaSkeletonReader.Read(
            packfile.ResolvedSections[root.Skeleton.Value.DestinationSection],
            root.Skeleton.Value.DestinationOffset);

        var animations = new List<BioShockAnimation>(root.Entries.Count);
        var failures = new List<AnimationFailure>();

        foreach (var entry in root.Entries)
        {
            var bindingSection = packfile.ResolvedSections[entry.Binding.DestinationSection];
            try
            {
                animations.Add(ReadAnimation(packfile, bindingSection, entry));
            }
            catch (Exception ex)
            {
                // Rule 23: one unsupported animation must never take down the other 129.
                failures.Add(new AnimationFailure
                {
                    AnimationName = entry.AnimationName,
                    OwnerName = entry.OwnerName,
                    SectionTag = bindingSection.Tag,
                    Offset = entry.Binding.DestinationOffset,
                    Reason = ex.Message,
                });
            }
        }

        return new AnimationPackage
        {
            ObjectName = export.ObjectName,
            PackageName = Path.GetFileNameWithoutExtension(package.FilePath),
            Skeleton = skeleton,
            Animations = animations,
            Failures = failures,
            Packfile = packfile,
            HavokOffset = location.Offset,
            RawPayload = payload,
        };
    }

    private static BioShockAnimation ReadAnimation(
        HavokPackfile packfile, HavokSection bindingSection, AnimationPackageEntry entry)
    {
        int bindingOffset = entry.Binding.DestinationOffset;
        var binding = HkaAnimationBindingReader.Read(bindingSection, bindingOffset);

        var animationReference = HkaAnimationBindingReader.GetAnimationReference(bindingSection, bindingOffset)
            ?? throw new InvalidDataException("binding has no animation pointer");

        var animationSection = packfile.ResolvedSections[animationReference.DestinationSection];
        int animationOffset = animationReference.DestinationOffset;

        string className = packfile.EnumerateObjects()
            .FirstOrDefault(o => o.SectionIndex == animationReference.DestinationSection && o.Offset == animationOffset)
            ?.ClassName ?? "<unclassified>";

        if (className != HkaSplineCompressedAnimationReader.ClassName)
            throw new NotSupportedException($"unsupported animation class '{className}'");

        var header = HkaSplineCompressedAnimationReader.Read(animationSection, animationOffset);

        return new BioShockAnimation
        {
            Name = entry.AnimationName,
            Owner = entry.OwnerName,
            Duration = header.Duration,
            FrameCount = header.NumFrames,
            FrameDuration = header.FrameDuration,
            TransformTrackCount = header.TransformTrackCount,
            FloatTrackCount = header.FloatTrackCount,
            Compression = CompressionKind.Spline,
            HavokClassName = className,
            RawAnimationTypeValue = header.AnimationType,
            Binding = binding,
            SectionTag = animationSection.Tag,
            SectionIndex = animationReference.DestinationSection,
            Offset = animationOffset,
        };
    }
}
