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
        IReadOnlyList<MeshSocket>? sockets = null,
        SkeletalMeshGeometry? geometry = null,
        IReadOnlyDictionary<string, IReadOnlyList<AnimationEvent>>? events = null,
        SceneMaterial? material = null)
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
                    Events = (events is not null && events.TryGetValue(animation.Name, out var track)
                        ? track
                        : [])
                        .Select(e => new SceneEvent { Time = e.Time, Name = e.EventName, NotifyClass = e.NotifyClass })
                        .ToList(),
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
            Mesh = geometry is null ? null : BuildMesh(geometry),
            Material = material,
        };
    }

    private static SceneMesh BuildMesh(SkeletalMeshGeometry geometry)
    {
        var positions = new float[geometry.Vertices.Count * 3];
        var normals = new float[geometry.Vertices.Count * 3];
        var uvs = new float[geometry.Vertices.Count * 2];

        // Influences are variable length, so they travel as a flat list plus a per-vertex count
        // rather than being padded or truncated to a fixed four.
        var influenceCounts = new int[geometry.Vertices.Count];
        var influenceBones = new List<int>();
        var influenceWeights = new List<float>();

        for (int i = 0; i < geometry.Vertices.Count; i++)
        {
            var vertex = geometry.Vertices[i];
            positions[i * 3] = vertex.Position.X;
            positions[i * 3 + 1] = vertex.Position.Y;
            positions[i * 3 + 2] = vertex.Position.Z;
            normals[i * 3] = vertex.Normal.X;
            normals[i * 3 + 1] = vertex.Normal.Y;
            normals[i * 3 + 2] = vertex.Normal.Z;
            uvs[i * 2] = vertex.Uv.X;
            uvs[i * 2 + 1] = vertex.Uv.Y;

            influenceCounts[i] = vertex.Influences.Count;
            foreach (var influence in vertex.Influences)
            {
                influenceBones.Add(influence.BoneIndex);
                influenceWeights.Add(influence.Weight);
            }
        }

        return new SceneMesh
        {
            Positions = positions,
            Normals = normals,
            Uvs = uvs,
            Triangles = geometry.Indices.ToArray(),
            InfluenceCounts = influenceCounts,
            InfluenceBones = influenceBones.ToArray(),
            InfluenceWeights = influenceWeights.ToArray(),
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

    /// <summary>Skinned geometry, when a companion SkeletalMesh was resolved and decoded.</summary>
    public SceneMesh? Mesh { get; init; }

    /// <summary>The material the mesh names, when it resolves. Null means the mesh exports untextured.</summary>
    public SceneMaterial? Material { get; init; }

    /// <summary>
    /// Assets that attach to one of this scene's sockets and carry their own skeleton, mesh and
    /// animations — a first-person weapon, for instance.
    /// </summary>
    public IReadOnlyList<SceneAttachment> Attachments { get; init; } = [];
}

/// <summary>A complete asset parented to a socket of its host.</summary>
public sealed record SceneAttachment
{
    /// <summary>Socket on the host skeleton, e.g. <c>Pistol</c>.</summary>
    public required string SocketName { get; init; }

    /// <summary>Bone the socket hangs off, e.g. <c>R_Grip</c>.</summary>
    public required string SocketBone { get; init; }

    public required AnimationScene Scene { get; init; }
}

/// <summary>Skinned geometry in flat arrays, ready for Blender's foreach_set fast paths.</summary>
public sealed record SceneMesh
{
    public required float[] Positions { get; init; }
    public required float[] Normals { get; init; }
    public required float[] Uvs { get; init; }
    public required int[] Triangles { get; init; }

    /// <summary>Number of influences belonging to each vertex.</summary>
    public required int[] InfluenceCounts { get; init; }

    public required int[] InfluenceBones { get; init; }
    public required float[] InfluenceWeights { get; init; }
}

/// <summary>
/// The material a mesh uses, with its texture bindings already resolved to written image files.
/// </summary>
public sealed record SceneMaterial
{
    public required string Name { get; init; }

    /// <summary>Shader class — <c>Shader</c>, <c>FacingShader</c> and so on.</summary>
    public required string ClassName { get; init; }

    /// <summary>Texture slot to the image file written beside the scene, relative to it.</summary>
    public required IReadOnlyDictionary<string, string> Textures { get; init; }

    /// <summary>Base colour map, whichever slot this shader class puts it in.</summary>
    public string? Diffuse { get; init; }

    public string? NormalMap { get; init; }
    public string? Specular { get; init; }

    public float? Glossiness { get; init; }
    public float? SpecularBrightness { get; init; }

    /// <summary>RGBA, 0..1.</summary>
    public float[]? DiffuseColor { get; init; }

    public float[]? SpecularColor { get; init; }
    public bool TwoSided { get; init; }
    public bool Masked { get; init; }

    /// <summary>True when the shader's property list could not be walked to its end.</summary>
    public required bool Partial { get; init; }

    /// <summary>Properties present on the shader that this exporter does not interpret.</summary>
    public required IReadOnlyList<string> Uninterpreted { get; init; }
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

    /// <summary>Timed events the animation fires, from its SharedSkeletonAnimationMetadata.</summary>
    public required IReadOnlyList<SceneEvent> Events { get; init; }
}

/// <summary>A timed animation event, e.g. a reload beat.</summary>
public sealed record SceneEvent
{
    public required float Time { get; init; }
    public required string Name { get; init; }
    public required string NotifyClass { get; init; }
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
