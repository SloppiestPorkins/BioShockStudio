using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Skeleton;

namespace BioShockStudio.Core.Rendering;

/// <summary>A bone as the preview needs it: its rest transform in skeleton space, and its parent.</summary>
public sealed record PreviewBone(string Name, int Parent, Matrix4x4 RestGlobal, Matrix4x4 InverseRestGlobal);

/// <summary>A socket drawn as a marker on the bone it hangs off.</summary>
public sealed record PreviewSocket(string Name, int Bone);

/// <summary>
/// Everything needed to draw one asset: geometry, its skeleton, and optionally a base colour map.
/// </summary>
/// <remarks>
/// Built once when an asset is selected and reused for every frame, so orbiting and playback do not
/// re-read the package.
/// </remarks>
public sealed class PreviewModel
{
    public required IReadOnlyList<MeshVertex> Vertices { get; init; }
    public required IReadOnlyList<int> Indices { get; init; }
    public required IReadOnlyList<PreviewBone> Bones { get; init; }
    public required IReadOnlyList<PreviewSocket> Sockets { get; init; }

    /// <summary>Base colour map, already decoded. Null means the model draws untextured.</summary>
    public PreviewImage? Texture { get; init; }

    /// <summary>Tangent-space normal map, when the material binds one.</summary>
    public PreviewImage? NormalMap { get; init; }

    /// <summary>Specular colour map, when the material binds one.</summary>
    public PreviewImage? SpecularMap { get; init; }

    /// <summary>Centre of the geometry in its rest pose, used as the camera's orbit target.</summary>
    public required Vector3 Centre { get; init; }

    /// <summary>Radius of the geometry in its rest pose, used to frame the camera.</summary>
    public required float Radius { get; init; }

    public bool HasGeometry => Vertices.Count > 0 && Indices.Count >= 3;

    /// <summary>
    /// Builds a preview model from decoded geometry and a skeleton.
    /// </summary>
    /// <remarks>
    /// Either may be absent: a static mesh has no skeleton, and a skeleton with no readable geometry
    /// is still worth drawing as bones. Neither case is treated as an error.
    /// </remarks>
    public static PreviewModel Build(
        SkeletalMeshGeometry? geometry,
        BioShockSkeleton? skeleton,
        IReadOnlyList<MeshSocket>? sockets = null,
        PreviewImage? texture = null,
        PreviewImage? normalMap = null,
        PreviewImage? specularMap = null)
    {
        var bones = new List<PreviewBone>();

        if (skeleton is not null)
        {
            var globals = new Matrix4x4[skeleton.Bones.Count];
            for (int i = 0; i < skeleton.Bones.Count; i++)
            {
                var bone = skeleton.Bones[i];
                var local = Compose(bone.LocalTranslation, bone.LocalRotation, bone.LocalScale);
                globals[i] = bone.ParentIndex < 0 ? local : local * globals[bone.ParentIndex];

                Matrix4x4.Invert(globals[i], out var inverse);
                bones.Add(new PreviewBone(bone.Name, bone.ParentIndex, globals[i], inverse));
            }
        }

        var socketList = new List<PreviewSocket>();
        foreach (var socket in sockets ?? [])
        {
            // The mesh writes R_Grip where the skeleton writes R_grip.
            int index = bones.FindIndex(b => string.Equals(b.Name, socket.BoneName, StringComparison.OrdinalIgnoreCase));
            if (index >= 0) socketList.Add(new PreviewSocket(socket.Name, index));
        }

        var vertices = geometry?.Vertices ?? [];
        var (centre, radius) = Bounds(vertices, bones);

        return new PreviewModel
        {
            Vertices = vertices,
            Indices = geometry?.Indices ?? [],
            Bones = bones,
            Sockets = socketList,
            Texture = texture,
            NormalMap = normalMap,
            SpecularMap = specularMap,
            Centre = centre,
            Radius = radius,
        };
    }

    private static (Vector3 Centre, float Radius) Bounds(
        IReadOnlyList<MeshVertex> vertices, IReadOnlyList<PreviewBone> bones)
    {
        var points = new List<Vector3>(vertices.Count + bones.Count);
        foreach (var vertex in vertices) points.Add(vertex.Position);

        // A skeleton with no readable geometry still has to be framed by something.
        if (points.Count == 0)
            foreach (var bone in bones) points.Add(bone.RestGlobal.Translation);

        if (points.Count == 0) return (Vector3.Zero, 1f);

        var min = points[0];
        var max = points[0];
        foreach (var point in points)
        {
            min = Vector3.Min(min, point);
            max = Vector3.Max(max, point);
        }

        var centre = (min + max) * 0.5f;
        float radius = 0f;
        foreach (var point in points) radius = MathF.Max(radius, (point - centre).Length());

        return (centre, MathF.Max(radius, 0.001f));
    }

    /// <summary>
    /// Composes the bone matrices for one animation frame, in skeleton space.
    /// </summary>
    /// <remarks>
    /// A bone the animation does not drive keeps its reference pose rather than falling to identity,
    /// and animated children still hang off it, so the chain walks every bone whether it has a track
    /// or not. Getting this wrong detaches limbs on any animation with a partial track set — and
    /// most of them have one.
    /// </remarks>
    public Matrix4x4[] Pose(DecodedAnimation animation, int frame)
    {
        var globals = new Matrix4x4[Bones.Count];
        var tracks = new DecodedTrack?[Bones.Count];

        foreach (var track in animation.Tracks)
            if (track.TargetBoneIndex >= 0 && track.TargetBoneIndex < Bones.Count)
                tracks[track.TargetBoneIndex] = track;

        int index = Math.Clamp(frame, 0, Math.Max(0, animation.FrameCount - 1));

        for (int i = 0; i < Bones.Count; i++)
        {
            var bone = Bones[i];
            var track = tracks[i];

            Matrix4x4 local;
            if (track is null)
            {
                // Rest local = rest global relative to the parent's.
                local = bone.Parent < 0
                    ? bone.RestGlobal
                    : bone.RestGlobal * Bones[bone.Parent].InverseRestGlobal;
            }
            else
            {
                local = Compose(track.Translations[index], track.Rotations[index], track.Scales[index]);
            }

            globals[i] = bone.Parent < 0 ? local : local * globals[bone.Parent];
        }

        return globals;
    }

    /// <summary>
    /// Bounds over a set of poses, so a camera framed on an animation keeps its subject in view for
    /// the whole thing.
    /// </summary>
    /// <remarks>
    /// Framing on the rest pose alone is not enough: the hands travel far enough during a reload to
    /// leave the view entirely. Framing per frame instead would keep it centred but make the camera
    /// chase the model, so the union over sampled frames is used and the camera stays still.
    /// </remarks>
    public (Vector3 Centre, float Radius) BoundsOver(IEnumerable<Matrix4x4[]> poses)
    {
        var points = new List<Vector3>();

        foreach (var pose in poses)
        {
            var positions = SkinPositions(SkinningMatrices(pose));
            if (positions.Length > 0) points.AddRange(positions);
            else for (int i = 0; i < pose.Length; i++) points.Add(pose[i].Translation);
        }

        if (points.Count == 0) return (Centre, Radius);

        var min = points[0];
        var max = points[0];
        foreach (var point in points)
        {
            min = Vector3.Min(min, point);
            max = Vector3.Max(max, point);
        }

        var centre = (min + max) * 0.5f;
        float radius = 0f;
        foreach (var point in points) radius = MathF.Max(radius, (point - centre).Length());
        return (centre, MathF.Max(radius, 0.001f));
    }

    /// <summary>Poses sampled evenly across an animation, enough to bound its motion.</summary>
    public IEnumerable<Matrix4x4[]> SamplePoses(DecodedAnimation animation, int samples = 6)
    {
        int last = Math.Max(0, animation.FrameCount - 1);
        for (int i = 0; i < samples; i++)
            yield return Pose(animation, samples == 1 ? 0 : last * i / (samples - 1));
    }

    /// <summary>Rest-pose vertex positions moved by a set of skinning matrices.</summary>
    public Vector3[] SkinPositions(Matrix4x4[]? skinning)
    {
        var result = new Vector3[Vertices.Count];

        for (int i = 0; i < result.Length; i++)
        {
            var vertex = Vertices[i];
            if (skinning is null || vertex.Influences.Count == 0)
            {
                result[i] = vertex.Position;
                continue;
            }

            var accumulated = Vector3.Zero;
            float total = 0f;
            foreach (var influence in vertex.Influences)
            {
                if (influence.BoneIndex < 0 || influence.BoneIndex >= skinning.Length) continue;
                accumulated += Vector3.Transform(vertex.Position, skinning[influence.BoneIndex]) * influence.Weight;
                total += influence.Weight;
            }

            // Weights sum to one in this data, but a vertex whose influences all fell outside the
            // skeleton must not collapse to the origin.
            result[i] = total > 0.001f ? accumulated / total : vertex.Position;
        }

        return result;
    }

    /// <summary>Rest-pose tangents rotated by a set of skinning matrices.</summary>
    public Vector3[] SkinTangents(Matrix4x4[]? skinning) => SkinDirections(skinning, v => v.Tangent);

    /// <summary>Rest-pose binormals rotated by a set of skinning matrices.</summary>
    public Vector3[] SkinBinormals(Matrix4x4[]? skinning) => SkinDirections(skinning, v => v.Binormal);

    private Vector3[] SkinDirections(Matrix4x4[]? skinning, Func<MeshVertex, Vector3> select)
    {
        var result = new Vector3[Vertices.Count];

        for (int i = 0; i < result.Length; i++)
        {
            var vertex = Vertices[i];
            var source = select(vertex);

            if (skinning is null || vertex.Influences.Count == 0)
            {
                result[i] = source;
                continue;
            }

            var accumulated = Vector3.Zero;
            foreach (var influence in vertex.Influences)
            {
                if (influence.BoneIndex < 0 || influence.BoneIndex >= skinning.Length) continue;
                accumulated += Vector3.TransformNormal(source, skinning[influence.BoneIndex]) * influence.Weight;
            }

            result[i] = accumulated.LengthSquared() > 1e-8f ? Vector3.Normalize(accumulated) : source;
        }

        return result;
    }

    /// <summary>Rest-pose normals rotated by a set of skinning matrices.</summary>
    public Vector3[] SkinNormals(Matrix4x4[]? skinning)
    {
        var result = new Vector3[Vertices.Count];

        for (int i = 0; i < result.Length; i++)
        {
            var vertex = Vertices[i];
            if (skinning is null || vertex.Influences.Count == 0)
            {
                result[i] = vertex.Normal;
                continue;
            }

            var accumulated = Vector3.Zero;
            foreach (var influence in vertex.Influences)
            {
                if (influence.BoneIndex < 0 || influence.BoneIndex >= skinning.Length) continue;
                accumulated += Vector3.TransformNormal(vertex.Normal, skinning[influence.BoneIndex]) * influence.Weight;
            }

            result[i] = accumulated.LengthSquared() > 1e-8f ? Vector3.Normalize(accumulated) : vertex.Normal;
        }

        return result;
    }

    /// <summary>Skinning matrices: what to multiply a rest-pose vertex by.</summary>
    public Matrix4x4[] SkinningMatrices(Matrix4x4[] pose)
    {
        var result = new Matrix4x4[Bones.Count];
        for (int i = 0; i < Bones.Count; i++) result[i] = Bones[i].InverseRestGlobal * pose[i];
        return result;
    }

    private static Matrix4x4 Compose(Vector3 translation, Quaternion rotation, Vector3 scale) =>
        Matrix4x4.CreateScale(scale)
        * Matrix4x4.CreateFromQuaternion(rotation)
        * Matrix4x4.CreateTranslation(translation);
}
