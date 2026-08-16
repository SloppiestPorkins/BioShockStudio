using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Skeleton;

namespace BioShockStudio.Core.Rendering;

/// <summary>A bone as the preview needs it: its rest transform in skeleton space, and its parent.</summary>
public sealed record PreviewBone(string Name, int Parent, Matrix4x4 RestGlobal, Matrix4x4 InverseRestGlobal);

/// <summary>A socket drawn as a marker on the bone it hangs off.</summary>
/// <param name="Transform">
/// Where the socket sits relative to its bone. Identity for most sockets — every first-person
/// weapon socket has a zero origin — but <c>FireballSocket</c> is 65.8 cm from its bone and
/// <c>GathererAttach</c> 84.8 cm, and a prop placed on the bone alone is wrong by that much.
/// </param>
public sealed record PreviewSocket(string Name, int Bone, Matrix4x4 Transform)
{
    /// <summary>The socket's place in skeleton space, given its bone's current transform.</summary>
    public Matrix4x4 On(Matrix4x4 bone) => Transform * bone;
}

/// <summary>
/// One run of the index buffer drawn with one material's maps.
/// </summary>
/// <remarks>
/// A mesh naming several materials draws each of its sections with its own. Before this the whole
/// mesh took the first material, so the Bathysphere's windows were painted in hull metal and every
/// lamp lens took the shade around it. Which triangles belong to which comes from the section table
/// via <c>MeshSurfaceResolver</c>, and this is only its rendering form.
/// </remarks>
/// <param name="MaterialName">
/// For diagnostics and the details panel. Null when the slot resolves to no material, in which case
/// the run draws in flat grey rather than borrowing a neighbour's texture.
/// </param>
public sealed record PreviewSurface(
    int FirstIndex,
    int IndexCount,
    string? MaterialName = null,
    PreviewImage? Texture = null,
    PreviewImage? NormalMap = null,
    PreviewImage? SpecularMap = null)
{
    public int TriangleCount => IndexCount / 3;
}

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

    /// <summary>
    /// The mesh's runs and the maps each is drawn with, in section order. Empty means the whole mesh
    /// draws untextured.
    /// </summary>
    public IReadOnlyList<PreviewSurface> Surfaces { get; init; } = [];

    /// <summary>
    /// Surface index for each triangle, so the rasteriser does not search the run list per triangle.
    /// <c>-1</c> where no surface covers it, which draws untextured.
    /// </summary>
    public IReadOnlyList<int> TriangleSurface { get; init; } = [];

    /// <summary>Base colour map of the first surface that binds one. Null means nothing is textured.</summary>
    /// <remarks>
    /// A convenience for callers that only ask whether the mesh resolved any texture at all. It is
    /// <b>not</b> what the mesh is drawn with — see <see cref="Surfaces"/>.
    /// </remarks>
    public PreviewImage? Texture => Surfaces.FirstOrDefault(s => s.Texture is not null)?.Texture;

    /// <summary>Tangent-space normal map of the first surface that binds one.</summary>
    public PreviewImage? NormalMap => Surfaces.FirstOrDefault(s => s.NormalMap is not null)?.NormalMap;

    /// <summary>Specular colour map of the first surface that binds one.</summary>
    public PreviewImage? SpecularMap => Surfaces.FirstOrDefault(s => s.SpecularMap is not null)?.SpecularMap;

    /// <summary>
    /// Where an attachment sits, given the socket it names and the host's current pose.
    /// </summary>
    /// <param name="socketName">
    /// The socket the attachment declares — <c>AttachmentCandidate.Socket</c>. <b>Matched by name.</b>
    /// </param>
    /// <param name="socketBone">The bone that socket hangs off, used when the name resolves nothing.</param>
    /// <param name="pose">The host's current pose, or null for its rest pose.</param>
    /// <remarks>
    /// <para>
    /// <b>By name, never by bone.</b> Several sockets commonly share one bone: nine of the
    /// first-person hands' sockets sit on <c>R_grip</c> — <c>Pistol</c>, <c>Wrench</c>,
    /// <c>Crossbow</c>, <c>Chem</c>, <c>TommyGun</c>, <c>Launcher</c>, <c>IrritantBall</c>,
    /// <c>WrenchRibbonSocket</c> and <c>PlayerGathererGun</c>. Choosing by bone returns whichever was
    /// read first, which is <c>Wrench</c>, and <c>Wrench</c> carries a <b>180 degree turn about Z</b>
    /// while <c>Pistol</c> and <c>Chem</c> carry identity.
    /// </para>
    /// <para>
    /// That is exactly what happened: every first-person weapon in the game was drawn with the
    /// wrench's flip on it, barrel pointing back over the forearm at the player. It was reported by
    /// a user, not caught by a test, and <b>two geometric metrics written to catch it both passed
    /// the broken pistol</b> — the fault is a wrong lookup, so the check that finds it is a wrong
    /// lookup, not a direction.
    /// </para>
    /// <para>
    /// The handoff's note that "every first-person weapon socket is identity" is about the socket
    /// <i>origin</i> and is true of it. The rotations are not identity, and the code was never
    /// reading them off the right socket.
    /// </para>
    /// </remarks>
    public Matrix4x4 PlacementFor(string? socketName, int socketBone, Matrix4x4[]? pose = null)
    {
        if (socketBone < 0 || socketBone >= Bones.Count) return Matrix4x4.Identity;

        var boneMatrix = pose is null ? Bones[socketBone].RestGlobal : pose[socketBone];

        var socket = Sockets.FirstOrDefault(s =>
            string.Equals(s.Name, socketName, StringComparison.OrdinalIgnoreCase));

        // No socket of that name: the bone alone, which is honest rather than borrowing a
        // neighbouring socket's transform.
        return socket is null ? boneMatrix : socket.On(boneMatrix);
    }

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
        MeshGeometry? geometry,
        BioShockSkeleton? skeleton,
        IReadOnlyList<MeshSocket>? sockets = null,
        PreviewImage? texture = null,
        PreviewImage? normalMap = null,
        PreviewImage? specularMap = null) =>
        Build(geometry, skeleton, sockets,
            geometry is null || geometry.Indices.Count < 3
                ? []
                : [new PreviewSurface(0, geometry.Indices.Count, null, texture, normalMap, specularMap)]);

    /// <summary>
    /// Builds a preview model whose geometry is split into runs, each with its own material maps.
    /// </summary>
    /// <remarks>
    /// The runs come from <c>MeshSurfaceResolver</c>, which is the one place that pairs a section
    /// with a material. This method only turns them into what the rasteriser indexes.
    /// </remarks>
    public static PreviewModel Build(
        MeshGeometry? geometry,
        BioShockSkeleton? skeleton,
        IReadOnlyList<MeshSocket>? sockets,
        IReadOnlyList<PreviewSurface> surfaces)
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
            if (index >= 0) socketList.Add(new PreviewSocket(socket.Name, index, socket.Transform));
        }

        var vertices = geometry?.Vertices ?? [];
        var indices = geometry?.Indices ?? [];
        var (centre, radius) = Bounds(vertices, bones);

        return new PreviewModel
        {
            Vertices = vertices,
            Indices = indices,
            Bones = bones,
            Sockets = socketList,
            Surfaces = surfaces,
            TriangleSurface = MapTrianglesToSurfaces(indices.Count, surfaces),
            Centre = centre,
            Radius = radius,
        };
    }

    /// <summary>
    /// Which surface draws each triangle, resolved once so the rasteriser does not search per
    /// triangle. A triangle no surface covers gets <c>-1</c> and draws untextured.
    /// </summary>
    private static int[] MapTrianglesToSurfaces(int indexCount, IReadOnlyList<PreviewSurface> surfaces)
    {
        var map = new int[indexCount / 3];
        Array.Fill(map, -1);

        for (int s = 0; s < surfaces.Count; s++)
        {
            var surface = surfaces[s];
            int first = Math.Max(0, surface.FirstIndex / 3);
            int last = Math.Min(map.Length, (surface.FirstIndex + surface.IndexCount) / 3);
            for (int t = first; t < last; t++) map[t] = s;
        }

        return map;
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
