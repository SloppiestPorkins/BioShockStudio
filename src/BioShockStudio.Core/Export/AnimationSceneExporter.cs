using System.Numerics;
using System.Text.Json;
using System.Text.Json.Serialization;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Textures;

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
    /// <summary>
    /// How a scene is written. Compact by default.
    /// </summary>
    /// <remarks>
    /// This file was indented for readability, on the reasoning that it doubles as a research
    /// artefact. Measured, that costs <b>60.5%</b> of its size — the hands' scene is 67.5 MB indented
    /// and 26.6 MB compact — because the content is almost entirely flat arrays of animation floats,
    /// which is exactly the part no one reads. A character with 457 animations writes 517 MB, and a
    /// bulk extraction of the 2,000 assets the browser shows by default came to roughly 350 GB.
    /// Nothing about the file is readable at that size, so the indentation bought nothing and cost
    /// more than half of every scene written.
    /// </remarks>
    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = false,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    /// <summary>The same scene, indented, for reading by eye. Only sane on a small asset.</summary>
    private static readonly JsonSerializerOptions ReadableOptions = new(Options) { WriteIndented = true };

    /// <summary>
    /// Bones treated as attachment sockets rather than skeleton joints. Recognised from the shipped
    /// hand skeleton; anything not matched is still exported as a normal bone, never dropped.
    /// </summary>
    private static readonly string[] SocketBoneNames = ["R_grip", "IKbindLhandDummy"];

    /// <summary>
    /// Builds a scene for a mesh that has no skeleton — a <c>StaticMesh</c> prop.
    /// </summary>
    /// <remarks>
    /// The same <see cref="AnimationScene"/>, with no bones, no animations and no sockets. Nothing
    /// downstream needs a special case: the writers already loop over the bone list, so an empty one
    /// simply yields a mesh. The alternative — inventing a single root bone so the file looks like
    /// the skinned ones — would put a joint in the export that the game does not have.
    /// </remarks>
    public static AnimationScene BuildStatic(
        string packageName,
        string objectName,
        MeshGeometry geometry,
        SceneMaterial? material = null,
        IReadOnlyList<SceneMaterial>? materials = null,
        int[]? triangleMaterials = null) =>
        new()
        {
            SourcePackage = packageName,
            SourceObject = objectName,
            SkeletonName = string.Empty,
            Bones = [],
            Animations = [],
            Failures = [],
            Sockets = [],
            Mesh = BuildMesh(geometry, triangleMaterials),
            Material = material ?? materials?.FirstOrDefault(),
            Materials = materials ?? (material is null ? [] : [material]),
        };

    public static AnimationScene Build(
        AnimationPackage package,
        string? ownerFilter = null,
        IReadOnlyList<MeshSocket>? sockets = null,
        MeshGeometry? geometry = null,
        IReadOnlyDictionary<string, IReadOnlyList<AnimationEvent>>? events = null,
        SceneMaterial? material = null,
        IReadOnlyList<SceneMaterial>? materials = null,
        int[]? triangleMaterials = null)
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
                .Select(ToSceneSocket)
                .ToList(),
            Mesh = geometry is null ? null : BuildMesh(geometry, triangleMaterials),
            Material = material ?? materials?.FirstOrDefault(),
            Materials = materials ?? (material is null ? [] : [material]),
        };
    }

    private static SceneMesh BuildMesh(MeshGeometry geometry, int[]? triangleMaterials = null)
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

            // Only carried when it says something: a mesh drawn entirely in one material would
            // otherwise ship an array of zeroes as long as its triangle list.
            TriangleMaterials = triangleMaterials is not null && triangleMaterials.Distinct().Count() > 1
                ? triangleMaterials
                : [],

            InfluenceCounts = influenceCounts,
            InfluenceBones = influenceBones.ToArray(),
            InfluenceWeights = influenceWeights.ToArray(),
        };
    }

    /// <param name="readable">
    /// Indent the output. Off by default — see <see cref="Options"/> for what it costs.
    /// </param>
    public static void WriteJson(AnimationScene scene, string path, bool readable = false)
    {
        using var stream = File.Create(path);
        JsonSerializer.Serialize(stream, scene, readable ? ReadableOptions : Options);
    }

    /// <summary>
    /// A socket with its own transform, decomposed the same way a bone's is.
    /// </summary>
    /// <remarks>
    /// A transform that will not decompose yields identity rather than a guess, and the socket then
    /// marks its bone — which is what every socket did before this and is honest about what is known.
    /// </remarks>
    private static SceneSocket ToSceneSocket(MeshSocket socket)
    {
        if (!Matrix4x4.Decompose(socket.Transform, out _, out var rotation, out var translation))
            return new SceneSocket { Name = socket.Name, BoneName = socket.BoneName };

        return new SceneSocket
        {
            Name = socket.Name,
            BoneName = socket.BoneName,
            Translation = [translation.X, translation.Y, translation.Z],
            Rotation = [rotation.X, rotation.Y, rotation.Z, rotation.W],
        };
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

    /// <summary>
    /// The mesh's first material, when it resolves. Null means the mesh exports untextured.
    /// </summary>
    /// <remarks>
    /// Kept for consumers that want one material for the whole mesh. A mesh naming more than one has
    /// no single material — see <see cref="Materials"/> and <see cref="SceneMesh.TriangleMaterials"/>.
    /// </remarks>
    public SceneMaterial? Material { get; init; }

    /// <summary>
    /// Every material the mesh uses, in slot order, indexed by <see cref="SceneMesh.TriangleMaterials"/>.
    /// </summary>
    public IReadOnlyList<SceneMaterial> Materials { get; init; } = [];

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

    /// <summary>
    /// Where the socket sits relative to its bone — the socket's own offset.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>The export used to drop this entirely</b>, parenting an attachment to the bone and nothing
    /// more, while the viewport applied the socket transform. So the two disagreed about where a
    /// prop goes, and the disagreement is not small: <c>FireballSocket</c> is 65.8 cm from its bone
    /// and <c>GathererAttach</c> 84.8 cm, and 200 of the game's 332 sockets carry a real offset.
    /// </para>
    /// <para>
    /// Written as translation and rotation in the same form as a bone's, so the consumer composes it
    /// with the same code path rather than needing a second matrix convention.
    /// </para>
    /// </remarks>
    public float[] SocketTranslation { get; init; } = [0f, 0f, 0f];

    /// <summary>The socket's rotation relative to its bone, <c>(x, y, z, w)</c> as a bone's is.</summary>
    /// <remarks>
    /// Not identity as often as the name suggests: on the first-person hands, <c>Wrench</c> carries
    /// 180° about Z, <c>Launcher</c> 30.5° and <c>TommyGun</c> 20.5°, while <c>Pistol</c> and
    /// <c>Chem</c> are identity. See <c>docs/HANDOFF.md</c> §4.
    /// </remarks>
    public float[] SocketRotation { get; init; } = [0f, 0f, 0f, 1f];

    public required AnimationScene Scene { get; init; }
}

/// <summary>Skinned geometry in flat arrays, ready for Blender's foreach_set fast paths.</summary>
public sealed record SceneMesh
{
    public required float[] Positions { get; init; }
    public required float[] Normals { get; init; }
    public required float[] Uvs { get; init; }
    public required int[] Triangles { get; init; }

    /// <summary>
    /// Index into the scene's <c>Materials</c> for each triangle, or <c>-1</c> for a triangle whose
    /// material slot resolves nothing. Empty when the mesh uses a single material throughout.
    /// </summary>
    /// <remarks>
    /// One entry per triangle, so <c>Triangles.Length / 3</c> long. This is what carries the section
    /// table out of the tool: without it a mesh naming three materials is drawn in one.
    /// </remarks>
    public int[] TriangleMaterials { get; init; } = [];

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

    /// <summary>Package file containing the authored material.</summary>
    public string? SourceFile { get; init; }

    /// <summary>Zero-based export-table identity in <see cref="SourceFile"/>.</summary>
    public required int SourceExportIndex { get; init; }

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
    public float? EmissiveBrightness { get; init; }

    /// <summary>RGBA, 0..1.</summary>
    public float[]? DiffuseColor { get; init; }

    public float[]? SpecularColor { get; init; }
    public float[]? EmissiveColor { get; init; }
    public bool TwoSided { get; init; }
    public bool Masked { get; init; }

    /// <summary>
    /// The material asks for a specular cubemap. <b>Which</b> one is not recoverable: no material in
    /// the game binds a <c>Cubemap</c> object — see <c>docs/research/materials.md</c>.
    /// </summary>
    public bool UsesSpecularCubemap { get; init; }

    /// <summary>Cubemap contribution strength, carried rather than interpreted.</summary>
    public float? SpecularCubemapBrightness { get; init; }

    /// <summary>
    /// Original <c>OutputBlending</c> byte when the material serialises one.
    /// </summary>
    /// <remarks>
    /// Its ordinal-to-blend-mode mapping has not been established from shipped bytes.  The export
    /// therefore preserves the byte for an Unreal importer to inspect, rather than silently
    /// treating (for example) value 2 as a particular UE5 blend mode.
    /// </remarks>
    public byte? OutputBlending { get; init; }

    /// <summary>
    /// Engine-facing intent for each texture this material binds, by slot.
    /// </summary>
    /// <remarks>
    /// Gate 1 item 3: an importer needs to know that a normal map is not colour and that a clamped
    /// texture must not wrap, neither of which is recoverable from the PNG. Keyed by slot rather
    /// than by file because the role belongs to the binding, not to the image — the same texture
    /// can be a base colour in one material and a mask in another.
    /// </remarks>
    public IReadOnlyDictionary<string, TextureIntent> TextureIntents { get; init; }
        = new Dictionary<string, TextureIntent>();

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

    /// <summary>
    /// The socket's own offset from its bone, as translation and an <c>(x, y, z, w)</c> rotation.
    /// </summary>
    /// <remarks>
    /// A socket marker placed on the bone alone marks the wrong place for 200 of the game's 332
    /// sockets — <c>GathererAttach</c> is 84.8 cm out and <c>FireballSocket</c> 65.8 cm. The export
    /// used to carry only the name and the bone, so every socket in a <c>.blend</c> sat on its bone
    /// head regardless of what the game says.
    /// </remarks>
    public float[] Translation { get; init; } = [0f, 0f, 0f];

    public float[] Rotation { get; init; } = [0f, 0f, 0f, 1f];
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
