using System.Numerics;

namespace BioShockStudio.Core.Mesh;

/// <summary>One skin influence: a skeleton bone index and its weight in 0..1.</summary>
public readonly record struct SkinInfluence(int BoneIndex, float Weight);

/// <summary>A decoded mesh vertex, already resolved onto skeleton bone indices.</summary>
public sealed record MeshVertex
{
    public required Vector3 Position { get; init; }
    public required Vector3 Normal { get; init; }

    /// <summary>
    /// Tangent basis, as shipped. The game stores a tangent and a binormal per vertex alongside the
    /// normal; both are needed to apply a tangent-space normal map without inventing a basis.
    /// </summary>
    public Vector3 Tangent { get; init; }

    public Vector3 Binormal { get; init; }

    public required Vector2 Uv { get; init; }

    /// <summary>
    /// Optional second UV channel. Compiled BSP lightmaps address a 1024-square atlas independently
    /// of the material UV, so keeping it beside the primary channel lets a viewport bind both
    /// without changing the representation of ordinary static and skeletal meshes.
    /// </summary>
    public Vector2 LightMapUv { get; init; }

    /// <summary>
    /// Baked-light factor sampled from a BSP atlas. Ordinary meshes retain white, meaning their
    /// base material is unchanged. Kept per vertex for the Avalonia GL backend, whose API exposes
    /// one sampler but no integer sampler-uniform binding for a second texture unit.
    /// </summary>
    public Vector3 BakedLight { get; init; } = Vector3.One;

    /// <summary>Influences with a non-zero weight. Never truncated to satisfy an exporter limit.</summary>
    public required IReadOnlyList<SkinInfluence> Influences { get; init; }
}

/// <summary>
/// One run of a mesh's index buffer, drawn with one material.
/// </summary>
/// <remarks>
/// <c>CONFIRMED_BYTES</c>, 14 bytes on the wire, sitting before the vertex block. The Nth section
/// uses the Nth entry of the object's <c>Materials</c> array. See <c>docs/research/staticmesh.md</c>.
/// </remarks>
/// <param name="FirstIndex">Where this section starts in the index buffer.</param>
/// <param name="FirstVertex">Lowest vertex the section references.</param>
/// <param name="LastVertex">Highest vertex the section references.</param>
/// <param name="TriangleCount">Triangles in the section, so it covers <c>TriangleCount * 3</c> indices.</param>
public readonly record struct MeshSection(int FirstIndex, int FirstVertex, int LastVertex, int TriangleCount)
{
    /// <summary>Indices this section covers.</summary>
    public int IndexCount => TriangleCount * 3;
}

/// <summary>
/// Geometry of a mesh: one vertex pool plus a triangle list.
/// <para>
/// Both mesh classes decode into this. A <c>SkeletalMesh</c> fills the bone map and the influences;
/// a <c>StaticMesh</c> has neither, so <see cref="IsSkinned"/> is false and every vertex carries an
/// empty influence list. Nothing downstream needs to know which reader produced it.
/// </para>
/// </summary>
public sealed record MeshGeometry
{
    public required IReadOnlyList<MeshVertex> Vertices { get; init; }

    /// <summary>Triangle corner indices into <see cref="Vertices"/>, three per face.</summary>
    public required IReadOnlyList<int> Indices { get; init; }

    /// <summary>Mesh-local bone slot to skeleton bone index. Empty for a static mesh.</summary>
    public required IReadOnlyList<int> BoneMap { get; init; }

    /// <summary>Vertices carrying full skin influences. Zero for a static mesh.</summary>
    public required int SkinnedVertexCount { get; init; }

    /// <summary>Vertices bound rigidly to a single bone. Zero for a static mesh.</summary>
    public required int RigidVertexCount { get; init; }

    /// <summary>
    /// Extra UV streams the mesh ships beyond the first, which are read but not carried: a
    /// <see cref="MeshVertex"/> holds one UV. Non-zero means the export drops a lightmap or detail
    /// channel, and says so rather than pretending the mesh had one set.
    /// </summary>
    public int ExtraUvStreamCount { get; init; }

    /// <summary>
    /// Runs of the index buffer, one per material. Empty when the mesh does not declare them.
    /// </summary>
    /// <remarks>
    /// A section's ordinal indexes the mesh's <c>Materials</c> array, which is what says <b>which
    /// triangles use which material</b>. Without it a mesh naming two or three materials could only
    /// be textured from the first.
    /// </remarks>
    public IReadOnlyList<MeshSection> Sections { get; init; } = [];

    /// <summary>Whether the vertices are bound to a skeleton at all.</summary>
    public bool IsSkinned => BoneMap.Count > 0;

    public int TriangleCount => Indices.Count / 3;
}
