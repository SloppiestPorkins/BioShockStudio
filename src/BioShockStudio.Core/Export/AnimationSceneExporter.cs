using System.Numerics;
using System.Text.Json;
using System.Text.Json.Serialization;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Mesh;

namespace BioShockStudio.Core.Export;

/// <summary>
/// Serialises a decoded animation package into the intermediate scene JSON that the Blender
/// importer consumes.
/// <para>
/// A JSON hand-off keeps the extraction side free of any Blender dependency and leaves a
/// human-readable artefact for research, which doubles as the lossless export required by the
/// project's raw-export rule.
/// </para>
/// </summary>
public static class AnimationSceneExporter
{
    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    /// <summary>
    /// Bones treated as attachment sockets rather than skeleton joints. Recognised from the shipped
    /// hand skeleton; anything not matched is still exported as a normal bone, never dropped.
    /// </summary>
    private static readonly string[] SocketBoneNames = ["R_grip", "IKbindLhandDummy"];

    public static AnimationScene Build(
        AnimationPackage package,
        string? ownerFilter = null,
        IReadOnlyList<MeshSocket>? sockets = null)
    {
        var skeleton = package.Skeleton;

        var bones = skeleton.Bones.Select(bone => new SceneBone
        {
            Index = bone.OriginalBoneIndex,
            Name = bone.Name,
            Parent = bone.ParentIndex,
            Translation = ToArray(bone.LocalTranslation),
            Rotation = ToArray(bone.LocalRotation),
            Scale = ToArray(bone.LocalScale),
            IsSocket = SocketBoneNames.Contains(bone.Name, StringComparer.Ordinal),
        }).ToList();

        var animations = new List<SceneAnimation>();
        var failures = package.Failures
            .Select(f => new SceneFailure { Name = f.AnimationName, Owner = f.OwnerName, Reason = f.Reason })
            .ToList();

        var selected = ownerFilter is null ? package.Animations : package.ForOwner(ownerFilter).ToList();

        foreach (var animation in selected)
        {
            try
            {
                var decoded = package.Decode(animation);

                animations.Add(new SceneAnimation
                {
                    Name = animation.Name,
                    Owner = animation.Owner,
                    Duration = animation.Duration,
                    FrameCount = animation.FrameCount,
                    FrameDuration = animation.FrameDuration,
                    Compression = animation.Compression.ToString(),
                    Tracks = decoded.Tracks.Select(track => new SceneTrack
                    {
                        TrackIndex = track.OriginalTrackIndex,
                        BoneIndex = track.TargetBoneIndex,
                        Translations = track.Translations.SelectMany(ToArray).ToArray(),
                        Rotations = track.Rotations.SelectMany(ToArray).ToArray(),
                        Scales = track.Scales.SelectMany(ToArray).ToArray(),
                    }).ToList(),
                });
            }
            catch (Exception ex)
            {
                // Never abort an export because one animation is undecodable.
                failures.Add(new SceneFailure { Name = animation.Name, Owner = animation.Owner, Reason = ex.Message });
            }
        }

        return new AnimationScene
        {
            SourcePackage = package.PackageName,
            SourceObject = package.ObjectName,
            SkeletonName = skeleton.Name,
            Bones = bones,
            Animations = animations,
            Failures = failures,
            Sockets = (sockets ?? [])
                .Select(s => new SceneSocket { Name = s.Name, BoneName = s.BoneName })
                .ToList(),
        };
    }

    public static void WriteJson(AnimationScene scene, string path)
    {
        using var stream = File.Create(path);
        JsonSerializer.Serialize(stream, scene, Options);
    }

    private static float[] ToArray(Vector3 value) => [value.X, value.Y, value.Z];
    private static float[] ToArray(Quaternion value) => [value.X, value.Y, value.Z, value.W];
}

public sealed record AnimationScene
{
    public required string SourcePackage { get; init; }
    public required string SourceObject { get; init; }
    public required string SkeletonName { get; init; }
    public required IReadOnlyList<SceneBone> Bones { get; init; }
    public required IReadOnlyList<SceneAnimation> Animations { get; init; }
    public required IReadOnlyList<SceneFailure> Failures { get; init; }

    /// <summary>Attachment points declared by the companion SkeletalMesh, if one was resolved.</summary>
    public required IReadOnlyList<SceneSocket> Sockets { get; init; }
}

/// <summary>A named attachment point and the bone it hangs off.</summary>
public sealed record SceneSocket
{
    public required string Name { get; init; }
    public required string BoneName { get; init; }
}

public sealed record SceneBone
{
    public required int Index { get; init; }
    public required string Name { get; init; }
    public required int Parent { get; init; }
    public required float[] Translation { get; init; }

    /// <summary>Quaternion as x, y, z, w.</summary>
    public required float[] Rotation { get; init; }

    public required float[] Scale { get; init; }

    /// <summary>Marks weapon grips and IK targets so Blender can flag them as attachment points.</summary>
    public required bool IsSocket { get; init; }
}

public sealed record SceneAnimation
{
    public required string Name { get; init; }
    public required string Owner { get; init; }
    public required float Duration { get; init; }
    public required int FrameCount { get; init; }
    public required float FrameDuration { get; init; }
    public required string Compression { get; init; }
    public required IReadOnlyList<SceneTrack> Tracks { get; init; }
}

public sealed record SceneTrack
{
    public required int TrackIndex { get; init; }
    public required int BoneIndex { get; init; }

    /// <summary>Flattened per-frame xyz.</summary>
    public required float[] Translations { get; init; }

    /// <summary>Flattened per-frame xyzw.</summary>
    public required float[] Rotations { get; init; }

    public required float[] Scales { get; init; }
}

public sealed record SceneFailure
{
    public required string Name { get; init; }
    public required string Owner { get; init; }
    public required string Reason { get; init; }
}
